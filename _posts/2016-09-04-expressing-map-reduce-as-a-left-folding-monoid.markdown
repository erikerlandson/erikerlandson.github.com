---
layout: post
title: "Encoding Map-Reduce As A Monoid With Left Folding"
date: 2016-09-05 10:31
comments: true
categories: [ computing, map-reduce, mapreduce, algebra, monoid, fold, left-fold, parallel, scala ]
---

In a [previous post](http://erikerlandson.github.io/blog/2015/11/24/the-prepare-operation-considered-harmful-in-algebird/) I discussed some scenarios where traditional map-reduce (directly applying a map function, followed by some monoidal reduction) could be inefficient.
To review, the source of inefficiency is in situations where the `map` operation is creating some non-trivial monoid that represents a single element of the input type.
For example, if the monoidal type is `Set[Int]`, then the mapping function ('prepare' in algebird) maps every input integer `k` into `Set(k)`, which is somewhat expensive.

In that discussion, I was focusing on map-reduce as embodied by the algebird `Aggregator` type, where `map` appears as the `prepare` function.
However, it is easy to see that _any_ map-reduce implementation may be vulnerable to the same inefficiency.

I wondered if there were a way to represent map-reduce using some alternative formulation that avoids this vulnerability.
There is such a formulation, which I will talk about in this post.

I'll begin by reviewing a standard map-reduce implementation.
The following scala code sketches out the definition of a monoid over a type `B` and a map-reduce interface.
As this code suggests, the `map` function maps input data of some type `A` into some _monoidal_ type `B`, which can be reduced (aka "aggregated") in a way that is amenable to parallelization:

``` scala
trait Monoid[B] {
  // aka 'combine' aka '++'
  def plus: (B, B) => B

  // aka 'empty' aka 'identity'
  def e: B
}

trait MapReduce[A, B] {
  // monoid embodies the reducible type
  def monoid: Monoid[B]

  // mapping function from input type A to reducible type B
  def map: A => B

  // the basic map-reduce operation
  def apply(data: Seq[A]): B = data.map(map).fold(monoid.e)(monoid.plus)

  // map-reduce parallelized over data partitions
  def apply(data: ParSeq[Seq[A]]): B =
    data.map { part =>
      part.map(map).fold(monoid.e)(monoid.plus)
    }
    .fold(monoid.e)(monoid.plus)
}
```

In the parallel version of map-reduce above, you can see that map and reduce are executed on each data partition (which may occur in parallel) to produce a monoidal `B` value, followed by a final reduction of those intermediate results.
This is the classic form of map-reduce popularized by tools such as Hadoop and Apache Spark, where inidividual data partitions may reside across highly parallel commodity clusters.

Next I will present an alternative definition of map-reduce.
In this implementation, the `map` function is replaced by a `foldL` function, which executes a single "left-fold" of an input object with type `A` into the monoid object with type `B`:

``` scala
// a map reduce operation based on a monoid with left folding
trait MapReduceLF[A, B] extends MapReduce[A, B] {
  def monoid: Monoid[B]

  // left-fold an object with type A into the monoid B
  // obeys type law: foldL(b, a) = b ++ foldL(e, a)
  def foldL: (B, A) => B

  // foldL(e, a) embodies the role of map(a) in standard map-reduce
  def map = (a: A) => foldL(monoid.e, a)

  // map-reduce operation is now a single fold-left operation
  override def apply(data: Seq[A]): B = data.foldLeft(monoid.e)(foldL)

  // map-reduce parallelized over data partitions
  override def apply(data: ParSeq[Seq[A]]): B =
    data.map { part =>
      part.foldLeft(monoid.e)(foldL)
    }
    .fold(monoid.e)(monoid.plus)
}
```

As the comments above indicate, the left-folding function `foldL` is assumed to obey the law `foldL(b, a) = b ++ foldL(e, a)`.
This law captures the idea that folding `a` into `b` should be the analog of reducing `b` with a monoid corresponding to the single element `a`.
Referring to my earlier example, if type `A` is `Int` and `B` is `Set[Int]`, then `foldL(b, a) => b + a`.
Note that `b + a` is directly inserting single element `a` into `b`, which is significantly more efficient than `b ++ Set(a)`, which is how a typical map-reduce implementation would be required to operate.

This law also gives us the corresponding definition of `map(a)`, which is `foldL(e, a)`, or in my example: `Set.empty[Int] ++ a` or just: `Set(a)`

In this formulation, the basic map-reduce operation is now a single `foldLeft` operation, instead of a mapping followed by a monoidal reduction.
The parallel version is analoglous.
Each partition uses the new `foldLeft` operation, and the final reduction of intermediate monoidal results remains the same as before.

The `foldLeft` function is potentially a much more general operation, and it raises the question of whether this new encoding is indeed parallelizable as before.
I will conclude with a proof that this encoding is also parallelizable;
Note that the law `foldL(b, a) = b ++ foldL(e, a)` is a significant component of this proof, as it represents the constraint that `foldL` behaves like an analog of reducing `b` with a monoidal representation of element `a`.

In the following proof I used a scala-like pseudo code, described in the introduction:

```
// given an object mr of type MapReduceFL[A, B]
// and using notation:
// f <==> mr.foldL
// for b1,b2 of type B: b1 ++ b2 <==> mr.plus(b1, b2)
// e <==> mr.e
// [...] <==> Seq(...)
// d1, d2 are of type Seq[A]

// Proof that map-reduce with left-folding is parallelizable
// i.e. mr(d1 ++ d2) == mr(d1) ++ mr(d2)
mr(d1 ++ d2)
== (d1 ++ d2).foldLeft(e)(f)  // definition of map-reduce operation
== d1.foldLeft(e)(f) ++ d2.foldLeft(e)(f)  // Lemma A
== mr(d1) ++ mr(d2)  // definition of map-reduce (QED)

// Proof of Lemma A
// i.e. (d1 ++ d2).foldLeft(e)(f) == d1.foldLeft(e)(f) ++ d2.foldLeft(e)(f)

// proof is by induction on the length of data sequence d2

// case d2 where length is zero, i.e. d2 == []
(d1 ++ []).foldLeft(e)(f)
== d1.foldLeft(e)(f)  // definition of empty sequence []
== d1.foldLeft(e)(f) ++ e  // definition of identity e
== d1.foldLeft(e)(f) ++ [].foldLeft(e)(f)  // definition of foldLeft

// case d2 where length is 1, i.e. d2 == [a] for some a of type A
(d1 ++ [a]).foldLeft(e)(f)
== f(d1.foldLeft(e)(f), a)  // definition of foldLeft and f
== d1.foldLeft(e)(f) ++ f(e, a)  // the type-law f(b, a) == b ++ f(e, a)
== d1.foldLeft(e)(f) ++ [a].foldLeft(e)(f)  // definition of foldLeft

// inductive step, assuming proof for d2' of length <= n
// consider d2 of length n+1, i.e. d2 == d2' ++ [a], where d2' has length n
(d1 ++ d2).foldLeft(e)(f)
== (d1 ++ d2' ++ [a]).foldLeft(e)(f)  // definition of d2, d2', [a]
== f((d1 ++ d2').foldLeft(e)(f), a)  // definition of foldLeft and f
== (d1 ++ d2').foldLeft(e)(f) ++ f(e, a)  // type-law f(b, a) == b ++ f(e, a)
== d1.foldLeft(e)(f) ++ d2'.foldLeft(e)(f) ++ f(e, a)  // induction
== d1.foldLeft(e)(f) ++ d2'.foldLeft(e)(f) ++ [a].foldLeft(e)(f)  // def'n of foldLeft
== d1.foldLeft(e)(f) ++ (d2' ++ [a]).foldLeft(e)(f)  // induction
== d1.foldLeft(e)(f) ++ d2.foldLeft(e)(f)  // definition of d2 (QED)
```
