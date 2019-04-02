---
layout: post
title: "Monadic 'break' and 'continue' for Scala Sequence Comprehensions"
date: 2015-01-24 11:54
comments: true
tags: [ computing, scala, monads, break, continue ]
---

**Author's note 0:** I have come up with better, more correct designs for monadic objects that implement
`break` and `continue` in Scala for-comprehensions.  I'm leaving this blog post up for posterity, but I
recommend using [the 'breakable' project](https://github.com/erikerlandson/breakable)
if you are interested in break and continue in a Scala framework.

Author's note: I've since received some excellent feedback from the Scala community, which I included in some [end notes](#notes).

Author's note the 2nd: I later realized I could apply an implicit conversion and mediator class to preserve the traditional ordering: the code has been updated with that approach.

Author's note the 3rd: This concept has been submitted to the Scala project as JIRA [SI-9120](https://issues.scala-lang.org/browse/SI-9120) (PR [#4275](https://github.com/scala/scala/pull/4275))

Scala [sequence comprehensions](http://docs.scala-lang.org/tutorials/tour/sequence-comprehensions.html) are an excellent functional programming idiom for looping in Scala.  However, sequence comprehensions encompass much more than just looping -- they represent a powerful syntax for manipulating _all_ monadic structures[[1]](#ref1).

The `break` and `continue` looping constructs are a popular framework for cleanly representing multiple loop halting and continuation conditions at differing stages in the execution flow.  Although there is no native support for `break` or `continue` in Scala control constructs, it is possible to implement them in a clean and idiomatic way for sequence comprehensions.

In this post I will describe a lightweight and easy-to-use implementation of `break` and `continue` for use in Scala sequence comprehensions (aka `for` statements).  The entire implementation is as follows:

    object BreakableGenerators {
      import scala.language.implicitConversions

      type Generator[+A] = Iterator[A]
      type BreakableGenerator[+A] = BreakableIterator[A]

      // Generates a new breakable generator from any traversable object.
      def breakable[A](t1: TraversableOnce[A]): Generator[BreakableGenerator[A]] =
        List(new BreakableIterator(t1.toIterator)).iterator

      // Mediates boolean expression with 'break' and 'continue' invocations
      case class BreakableGuardCondition(cond: Boolean) {
        // Break the looping over one or more breakable generators, if 'cond' 
        // evaluates to true.
        def break(b: BreakableGenerator[_], bRest: BreakableGenerator[_]*): Boolean = {
          if (cond) {
            b.break
            for (x <- bRest) { x.break }
          }
          !cond
        }

        // Continue to next iteration of enclosing generator if 'cond' 
        // evaluates to true.
        def continue: Boolean = !cond
      }

      // implicit conversion of boolean values to breakable guard condition mediary
      implicit def toBreakableGuardCondition(cond: Boolean) =
        BreakableGuardCondition(cond)

      // An iterator that can be halted via its 'break' method.  Not invoked directly
      class BreakableIterator[+A](itr: Iterator[A]) extends Iterator[A] {
        private var broken = false
        private[BreakableGenerators] def break { broken = true }

        def hasNext = !broken && itr.hasNext
        def next = itr.next
      }
    }

The approach is based on a simple subclass of `Iterator` -- `BreakableIterator` -- that can be halted by 'breaking' it.  The function `breakable(<traversable-object>)` returns an Iterator over a single `BreakableIterator` object.  Iterators are monad-like structures in that they implement `map` and `flatMap`, and so its output can be used with `<-` at the start of a `for` construct in the usual way.  Note that this means the result of the `for` statement will also be an Iterator.

Whenever the boolean expression for an `if` guard is followed by either `break` or `continue`, it is implicitly converted to a "breakable guard condition" that supports those methods.  The function `break` accepts one or more instances of `BreakableIterator`.  If it evaluates to `true`, the loops embodied by the given iterators are immediately halted via the associated `if` guard, and the iterators are halted via their `break` method.  The `continue` function is mostly syntactic sugar for a standard `if` guard, simply with the condition inverted.


Here is a simple example of `break` and `continue` in use:

    object Main {
      import BreakableGenerators._

      def main(args: Array[String]) {

        val r = for (
          // generate a breakable sequence from some sequential input
          loop <- breakable(1 to 1000);
          // iterate over the breakable sequence
          j <- loop;
          // print out at each iteration
          _ = { println(s"iteration j= $j") };
          // continue to next iteration when 'j' is even
          if { j % 2 == 0 } continue;
          // break out of the loop when 'j' exceeds 5
          if { j > 5 } break(loop)
        ) yield {
          j
        }
        println(s"result= ${r.toList}")
      }
    }

We can see from the resulting output that `break` and `continue` function in the usual way.  The `continue` clause ignores all subsequent code when `j` is even.  The `break` clause halts the loop when it sees its first value > 5, which is 7.  Only odd values <= 5 are output from the `yield` statement:

    $ scalac -d /home/eje/class monadic_break.scala
    $ scala -classpath /home/eje/class Main
    iteration j= 1
    iteration j= 2
    iteration j= 3
    iteration j= 4
    iteration j= 5
    iteration j= 6
    iteration j= 7
    result= List(1, 3, 5)

Breakable iterators can be nested in the way one would expect.  The following example shows an inner breakable loop nested inside an outer one:

    object Main {
      import BreakableGenerators._

      def main(args: Array[String]) {
        val r = for (
          outer <- breakable(1 to 7);
          j <- outer;
          _ = { println(s"outer  j= $j") };
          if { j % 2 == 0 } continue;
          inner <- breakable(List("a", "b", "c", "d", "e"));
          k <- inner;
          _ = { println(s"    inner  j= $j  k= $k") };
          if { k == "d" } break(inner);
          if { j == 5  &&  k == "c" } break(inner, outer)
        ) yield {
          (j, k)
        }
        println(s"result= ${r.toList}")
      }
    }

The output demonstrates that the inner loop breaks whenever `k=="d"`, and so `"e"` is never present in the `yield` result.  When `j==5` and `k=="c"`, both the inner and outer loops are broken, and so we see that there is no `(5,"c")` pair in the result, nor does the outer loop ever iterate over 6 or 7:

    $ scalac -d /home/eje/class monadic_break.scala
    $ scala -classpath /home/eje/class Main
    outer  j= 1
        inner  j= 1  k= a
        inner  j= 1  k= b
        inner  j= 1  k= c
        inner  j= 1  k= d
    outer  j= 2
    outer  j= 3
        inner  j= 3  k= a
        inner  j= 3  k= b
        inner  j= 3  k= c
        inner  j= 3  k= d
    outer  j= 4
    outer  j= 5
        inner  j= 5  k= a
        inner  j= 5  k= b
        inner  j= 5  k= c
    result= List((1,a), (1,b), (1,c), (3,a), (3,b), (3,c), (5,a), (5,b))

Using `break` and `continue` with `BreakableIterator` for sequence comprehensions is that easy.  Enjoy!

<a name="notesname" id="notes"></a>
##### Notes
The helpful community on freenode #scala made some excellent observations:

1: Iterators in Scala are not strictly monadic -- it would be more accurate to say they're "things with a flatMap and map method, also they can use filter or withFilter sometimes."  However, I personally still prefer to think of them as "monadic in spirit if not law."

2: The `break` function, as described in this post, is not truly functional in the sense of referential transparency, as the invocation `if break(loop) { condition }` involves a side-effect on the variable `loop`.  I would say that it does maintain "scoped functionality."  That is, the break in non-referential transparency is scoped by the variables in question.  The `for` statement containing them is referentially transparent with respect to its inputs (provided no other code is breaking referential transparency, of course).


##### References
<a name="ref1name" id="ref1">[1] </a>_[Functional Programming in Scala](http://www.manning.com/bjarnason/)_, Paul Chiusano and Runar Bjarnason, (section 6.6)
