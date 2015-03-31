---
layout: post
title: "Hygienic Closures for Scala Function Serialization"
date: 2015-03-31 06:06
comments: true
categories: [ computing, scala, closures, functional programming, serialization, spark ]
---
In most use cases of Scala closures, what you see is what you get, but there are exceptions where looks can be deceiving and this can have a big impact on closure serialization.  Closure serialization is of more than academic interest.  Tools like Apache Spark cannot operate without serializing functions over the network.  In this post I'll describe some scenarios where closures include more than what is evident in the code, and then a technique for preventing unwanted inclusions.

To establish a bit of context, consider this simple example that obtains a function and serializes it to disk, and which _does_ behave as expected:

    object Demo extends App {
      def write[A](obj: A, fname: String) {
        import java.io._
        new ObjectOutputStream(new FileOutputStream(fname)).writeObject(obj)
      }

      object foo {
        val v = 42
        // The returned function includes 'v' in its closure
        def f() = (x: Int) => v * x
      }

      // The function 'f' will serialize as expected
      val f = foo.f
      write(f, "/tmp/demo.f")
    }

When this app is compiled and run, it will serialize `f` to "/tmp/demo.f1", which of course includes the value of `v` as part of the closure for `f`.

    $ scalac -d /tmp closures.scala
    $ scala -cp /tmp Demo
    $ ls /tmp/demo*
    /tmp/demo.f

Now, imagine you wanted to make a straightforward change, where `object foo` becomes `class foo`:

    object Demo extends App {
      def write[A](obj: A, fname: String) {
        import java.io._
        new ObjectOutputStream(new FileOutputStream(fname)).writeObject(obj)
      }

      // foo is a class instead of an object
      class foo() {
        val v = 42
        // The returned function includes 'v' in its closure, but also a secret surprise
        def f() = (x: Int) => v * x
      }

      // This will throw an exception!
      val f = new foo().f
      write(f, "/tmp/demo.f")
    }

It would be reasonable to expect that this minor variation behaves exactly as the previous one, but instead it throws an exception!

    $ scalac -d /tmp closures.scala
    $ scala -cp /tmp Demo
    java.io.NotSerializableException: Demo$foo

If we look at the exception message, we see that it's complaining about not knowing how to serialize objects of class `foo`.  But we weren't including any values of `foo` in the closure for `f`, only a particular member 'v'!  What gives?  Scala is not very helpful with diagnosing this problem, but when a class member value shows up in an enclosure that is defined _inside_ the class body, the _entire instance_, including any and all other member values, is included in the enclosure.  Presumably this is because a class may have any number of instances, and the compiler is including the entire instance in the closure to properly resolve the correct member value.

One straightforward way to fix this is to simply make class `foo` serializable:

    class foo() extends Serializable {
      // ...
    }

If you make this change to the above code, the example with `class foo` now works correctly, but it is working by serializing the entire `foo` instance, not just the value of `v`.   

In many cases, this is not a problem and will work fine.  Serializing a few additional members may be inexpensive.  In other cases, however, it can be an impractical or impossible option.  For example, `foo` might include other very large members, which will be expensive or outright impossible to serialize:

    class foo() extends Serializable {
      val v = 42    // easy to serialize
      val w = 4.5   // easy to serialize
      val data = (1 to 1000000000).toList  // serialization landmine hiding in your closure

      // The returned function includes all of 'foo' instance in its closure
      def f() = (x: Int) => v * x
    }

A variation on the above problem is class members that are small or moderate in size, but serialized many times.  In this case, the serialization cost can become intractable via repetition of unwanted inclusions.

Another potential problem is class members that are not serializable, and perhaps not under your control:

    class foo() extends Serializable {
      import some.class.NotSerializable

      val v = 42                      // easy to serialize
      val x = new NotSerializable     // I'll hide in your closure and fail to serialize

      // The returned function includes all of 'foo' instance in its closure
      def f() = (x: Int) => v * x
    }

There is a relatively painless way to decouple values from their parent instance, so that only desired values are included in a closure.  Passing desired values as parameters to a shim function whose job is to assemble the enclosure will prevent the parent instance from being pulled into the closure.  In the following example, a shim function named `closureFunction` is defined for this purpose:

    object Demo extends App {
      def write[A](obj: A, fname: String) {
        import java.io._
        new ObjectOutputStream(new FileOutputStream(fname)).writeObject(obj)
      }

      // apply a generator to create a function with safe decoupled enclosures
      def closureFunction[E,D,R](enclosed: E)(gen: E => (D => R)) = gen(enclosed)

      class NotSerializable {}

      class foo() {
        val v1 = 42
        val v2 = 73
        val n = new NotSerializable

        // use shim function to enclose *only* the values of 'v1' and 'v2'
        def f() = closureFunction((v1, v2)) { enclosed =>
          val (v1, v2) = enclosed
          (x: Int) => (v1 + v2) * x   // Desired function, with 'v1' and 'v2' enclosed
        }
      }

      // This will work!
      val f = new foo().f
      write(f, "/tmp/demo.f")
    }

Being aware of the scenarios where parent instances are pulled into enclosures, and how to keep your enclosures clean, can save some frustration and wasted time.  Happy programming!
