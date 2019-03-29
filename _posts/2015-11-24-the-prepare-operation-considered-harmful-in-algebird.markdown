---
layout: post
title: "The 'prepare' operation considered harmful in Algebird aggregation"
date: 2015-11-24 16:32
comments: true
categories: [ computing, scala, algebird, monoid, performance, algebra ]
---
I want to make an argument that the Algebird [Aggregator](http://twitter.github.io/algebird/#com.twitter.algebird.Aggregator) design, in particular its use of the `prepare` operation in a map-reduce context, has substantial inefficiencies, compared to an equivalent formulation that is more directly suited to taking advantage of Scala's [aggregate method on collections](http://www.scala-lang.org/api/current/index.html#scala.collection.Seq) method.

Consider the definition of aggregation in the Aggregator class:

```scala
def apply(inputs: TraversableOnce[A]): C = present(reduce(inputs.map(prepare)))
```

You can see that it is a standard map/reduce operation, where `reduce` is defined as a monoidal (or semigroup -- more on this later) operation. Under the hood, it boils down to an invocation of Scala's `reduceLeft` method.  The key thing to notice is that the role of `prepare` is to map a collection of data elements into the required monoids, which are then aggregated using that monoid's `plus` operation.  In other words, `prepare` converts data elements into "singleton" monoids each representing a data element.

Now, if the monoid in question is simple, say some numeric type, this conversion is free, or nearly so.  For example, the conversion of an integer into the "integer monoid" is a no-op.  However, there are other kinds of "non-trivial" monoids, for which the conversion of a data element into its corresponding monoid may be costly.  In this post, I will be using the monoid defined by Scala Set[Int], where the monoid `plus` operation is set union, and of course the `zero` element is the empty set.

Consider the process of defining an Algebird aggregator for the task of generating the set of unique elements in a data set.  The corresponding `prepare` operation is: `prepare(e: Int) = Set(e)`.  A monoid trait that encodes this idea might look like the following.  (the code I used in this post can be found [here](https://gist.github.com/erikerlandson/d96dc553bc51e0eb5e4b))

```scala
// an algebird-like monoid with the 'prepare' operation
trait PreparedMonoid[M, E] {
  val zero: M
  def plus(m1: M, m2: M): M
  def prepare(e: E): M
}

// a PreparedMonoid for a set of integers.  monoid operator is set union.
object intSetPrepared extends PreparedMonoid[Set[Int], Int] {
  val zero = Set.empty[Int]
  def plus(m1: Set[Int], m2: Set[Int]) = m1 ++ m2
  def prepare(e: Int) = Set(e)
}

implicit class SeqWithMapReduce[E](seq: Seq[E]) {
  // algebird map/reduce Aggregator model
  def mrPrepared[M](mon: PreparedMonoid[M, E]): M = {
    seq.map(mon.prepare).reduceLeft(mon.plus)
  }
}
```

If we unpack the above code, as applied to `intSetPrepared`, we are instantiating a new Set object, containing a single value, for every single input data element.

But there is a potentially better model of aggregation, exemplified by the Scala `aggregate` method.  This method does not use a `prepare` operation.  It uses a zero value and a monoidal operator, which the Scala docs refer to as `combop`, but it also uses an "update" operation, that defines how to update the monoid object, directly, with a single element, referred to as `seqop` in Scala's documentation.  This idea can also be encoded as a flavor of monoid, enhanced with an `update` method:

```scala
// an algebird-like monoid with 'update' operation
trait UpdatedMonoid[M, E] {
  val zero: M
  def plus(m1: M, m2: M): M
  def update(m: M, e: E): M
}

// an equivalent UpdatedMonoid for a set of integers
object intSetUpdated extends UpdatedMonoid[Set[Int], Int] {
  val zero = Set.empty[Int]
  def plus(m1: Set[Int], m2: Set[Int]) = m1 ++ m2
  def update(m: Set[Int], e: Int) = m + e
}

implicit class SeqWithMapReduceUpdated[E](seq: Seq[E]) {
  // map/reduce logic, taking advantage of scala 'aggregate'
  def mrUpdatedAggregate[M](mon: UpdatedMonoid[M, E]): M = {
    seq.aggregate(mon.zero)(mon.update, mon.plus)
  }
}
```

This arrangement promises more efficiency when aggregating w.r.t. nontrivial monoids, by avoiding the construction of "singleton" monoids for each data element.  The following demo confirms that for the Set-based monoid, it is over 10 times faster:

```scala
scala> :load /home/eje/scala/prepare.scala
Loading /home/eje/scala/prepare.scala...
defined module prepare

scala> import prepare._
import prepare._

scala> val data = Vector.fill(1000000) { scala.util.Random.nextInt(10) }
data: scala.collection.immutable.Vector[Int] = Vector(7, 9, 4, 2, 7,...

// Verify that output is the same for both implementations:
scala> data.mrPrepared(intSetPrepared)
res0: Set[Int] = Set(0, 5, 1, 6, 9, 2, 7, 3, 8, 4)

// results are the same
scala> data.mrUpdatedAggregate(intSetUpdated)
res1: Set[Int] = Set(0, 5, 1, 6, 9, 2, 7, 3, 8, 4)

// Compare timings of prepare-based versus update-based aggregation
// (benchmark values are returned in seconds)
scala> benchmark(10) { data.mrPrepared(intSetPrepared) }
res2: Double = 0.2957673056

// update-based aggregation is 10 times faster
scala> benchmark(10) { data.mrUpdatedAggregate(intSetUpdated) }
res3: Double = 0.027041249300000004
```

It is also possible to apply Scala's `aggregate` to a monoid enhanced with `prepare`:

```scala
implicit class SeqWithMapReducePrepared[E](seq: Seq[E]) {
  // using 'aggregate' with prepared op
  def mrPreparedAggregate[M](mon: PreparedMonoid[M, E]): M = {
    seq.aggregate(mon.zero)((m, e) => mon.plus(m, mon.prepare(e)), mon.plus)
  }
}
```

Although this turns out to be measurably faster than the literal map-reduce implementation, it is still not nearly as fast as the variation using `update`:

```scala
scala> benchmark(10) { data.mrPreparedAggregate(intSetPrepared) }
res2: Double = 0.1754636707
```

Readers familiar with Algebird may be wondering about my use of monoids above, when the `Aggregator` interface is actually based on semigroups.  This is important, since building on Scala's `aggregate` function requires a zero element that semigroups do not have.  Although I believe it might be worth considering changing `Aggregator` to use monoids, another sensible option is to change the internal logic for the subclass `AggregatorMonoid`, which does require a monoid, or possibly just define a new `AggregatorMonoidUpdated` subclass.

A final note on compatability: note that any monoid enhanced with `prepare` can be converted into an equivalent monoid enhanced with `update`, as demonstrated by this factory function:

```scala
object UpdatedMonoid {
  // create an UpdatedMonoid from a PreparedMonoid
  def apply[M, E](mon: PreparedMonoid[M, E]) = new UpdatedMonoid[M, E] {
    val zero = mon.zero
    def plus(m1: M, m2: M) = mon.plus(m1, m2)
    def update(m: M, e: E) = mon.plus(m, mon.prepare(e))
  }
}
```
