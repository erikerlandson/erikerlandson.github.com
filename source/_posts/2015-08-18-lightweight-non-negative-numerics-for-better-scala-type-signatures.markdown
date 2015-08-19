---
layout: post
title: "Lightweight Non-Negative Numerics for Better Scala Type Signatures"
date: 2015-08-18 17:42
comments: true
categories: [ computing, scala, value class, type signature, functional programming ]
---
In this post I want to discuss several advantages of defining lightweight non-negative numeric types in Scala, whose primary benefit is that they allow improved type signatures for Scala functions and methods.  I'll first describe the simple class definition, and then demonstrate how it can be used in function signatures and the benefits of doing so.

#####A Non-Negative Integer Type
As a working example, I'll discuss a non-negative integer type `NonNegInt`.  My proposed definition is sufficiently lightweight to view as a single code block:

``` scala
object nonneg {
  import scala.language.implicitConversions

  class NonNegInt private (val value: Int) extends AnyVal
  
  object NonNegInt {
    def apply(v: Int) = {
      require(v >= 0, "NonNegInt forbids negative integer values")
      new NonNegInt(v)
    }
    
    implicit def toNonNegInt(v: Int) = NonNegInt(v)
  }

  implicit def toInt(nn: NonNegInt) = nn.value
}
```

The notable properties and features of `NonNegInt` are:

* `NonNegInt` is a value class around an `Int`, and so invokes no actual object construction or allocation
* Its constructor is private, and so is safe from directly constructing around a negative integer
* It supplies factory method `NonNegInt(v)` to construct a non negative integer value
* It supplies implicit conversion from `Int` values to `NonNegInt`
* Both factory method and implicit conversion check for negative values.  There is no way to construct a `NonNegInt` that contains a negative integer value.
* It also supplies implicit conversion from `NonNegInt` back to `Int`.  Moving back and forth between `Int` and `NonNegInt` is effectively transparent.

The above properties work to make `NonNegInt` very lightweight with respect to size and runtime properties, and semantically safe in the sense that it is impossible to construct one with a negative value inside it.

#####Application of `NonNegInt`

I primarily envision `NonNegInt` as an easy and informative way to declare function parameters that are only well defined for non-negative values, without the need to write any explicit checking code, and yet allowing the programmer to call the function with normal `Int` values, due to the implicit conversions:

``` scala
object example {
  import nonneg._

  def element[T](seq: Seq[T], j: NonNegInt) = seq(j)

  // call element function with a regular Int index
  val e = element(Vector(1,2,3), 1) // e is set to 2
}
```

This short example demonstrates some appealing properties of `NonNegInt`.  Firstly, the constraint that index `j >= 0` is enforced via the type definition, and so the programmer does not have to write the usual `require(j >= 0, ...)` check (or worry about forgetting it).  Secondly, the implicit conversion from `Int` to `NonNegInt` means the programmer can just provide a regular integer value for parameter `j`, instead of having to explicitly say `NonNegInt(1)`.  Third, the implicit conversion from `NonNegInt` to `Int` means that `j` can easily be used anywhere a regular `Int` is used.  Last, and very definitely not least, the fact that function `element` requires a non-negative integer is obvious __right in the function signature__.  There is no need for a programmer to guess whether `j` can be negative, and no need for the author of `element` to document that `j` cannot be negative.  Its type makes that completely clear.

#####Conclusions
In this post I've laid out some advantages of defining lightweight non-negative numeric types, in particular using `NonNegInt` as a working example.  Clearly, if you want to apply this idea, you'd want to also define `NonNegLong`, `NonNegDouble`, `NonNegFloat` and for that matter `PosInt`, `PosLong`, etc.  Happy computing!
