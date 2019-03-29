---
layout: post
title: "A Library of Binary Tree Algorithms as Mixable Scala Traits"
date: 2015-09-26 12:43
comments: true
categories: [ computing, scala, binary tree, algorithms, prefix sum, nearest entry, t-digest ]
---
In this post I am going to describe some work I've done recently on a system of Scala traits that support tree-based collection algorithms prefix-sum, nearest key query and value increment in a mixable format, all backed by Red-Black balanced tree logic, which is also a fully inheritable trait.

> (update) Since I wrote this post, the code has evolved into a [library on the isarn project](https://github.com/isarn/isarn-collections). The original source files, containing the exact code fragments discussed in the remainder of this post, are preserved for posterity [here](https://github.com/erikerlandson/silex/tree/blog/rbtraits/src/main/scala/com/redhat/et/silex/maps).

This post eventually became a bit more sprawling and "tl/dr" than I was expecting, so by way of apology, here is a table of contents with links:

1. [Motivating Use Case](#motivation)
1. [Library Overview](#overview)
1. [A Red-Black Tree Base Class](#redblack)
1. [Node Inheritance Example: NodeMap[K,V]](#nodemap)
1. [Collection Trait Example: OrderedMapLike[K,V,IN,M]](#orderedmaplike)
1. [Collection Example: OrderedMap[K,V]](#orderedmap)
1. [Finale: Trait Mixing](#mixing)

<a name="motivation"></a>
##### A Motivating Use Case
The skeptical programmer may be wondering what the point of Yet Another Map Collection really is, much less an entire class hierarchy.  The use case that inspired this work was [my project](https://github.com/twitter/algebird/pull/495) of implementing the [t-digest algorithm](https://github.com/tdunning/t-digest/blob/master/docs/t-digest-paper/histo.pdf).  Discussion of t-digest is beyond the scope of this post, but suffice it to say that constructing a t-digest requires the maintenance of a collection of "cluster" objects, that needs to satisfy the following several properties:

1. an entry contains one **or more** cluster objects at a given numeric location
1. entries are maintained in a numeric key order
1. entries will be frequently inserted and deleted, in arbitrary order
1. given a numeric key value, be able to find the entry nearest to that value
1. given a key, compute a [prefix-sum](https://en.wikipedia.org/wiki/Prefix_sum) for that value
1. all of the above should be bounded by logarithmic time complexity

Propreties 2,3 and 6 are commonly satisfied by a map structure backed by some variety of balanced tree representation, of which the best-known is the [Red-Black tree](https://en.wikipedia.org/wiki/Red%E2%80%93black_tree).

Properties 1, 4 and 5 are more interesting.  Property 1 -- representing a collection of multiple objects at each entry -- can be accomplished in a generalizable way by noting that a collection is representable as a monoid, and so supporting values that can be incremented with respect to a [user-supplied monoid relation](http://twitter.github.io/algebird/index.html#com.twitter.algebird.Monoid) can satisfy property-1, but also can support many other kinds of update, including but not limited to classical numeric incrementing operations.

Properties 4 and 5 -- nearest-entry queries and prefix-sum queries -- are also both supportable in logarithmic time using a tree data structure, provided that tree is balanced.  Again, the details of the algorithms are out of the current scope, however they are not extremely complex, and their implementations are available in the code.

A reader with their software engineering hat on will notice that these properties are _orthogonal_.  A programmer might be interested in a data structure supporting any one of them, or in some mixed combination.   This kind of situation fairly shouts "Scala traits" (or, alternatively, interfaces in Java, etc).  With that idea in mind, I designed a system of Scala collection traits that support all of the above properties, in a pure trait form that is fully "mixable" by the programmer, so that one can use exactly the properties needed, but not pay for anything else.

<a name="overview"></a>
##### Library Overview
The library consists broadly of 3 kinds of traits:

* tree node traits -- implement core tree support for some functionality
* collection traits -- provide additional collection API methods the user
* collections -- instantiate a usable incarnation of a collection

For the programmer who wishes to either create a trait mixture, or add new mixable traits, the collections also function as reference implementations.

The three tables that follow summarize the currently available traits of each kind listed above.  They are (at the time of this posting) all under the package namespace `com.redhat.et.silex.maps`:

<head><style>
table, th, td {
border: 1px solid black;
border-collapse: collapse;
}
th, td {
padding: 10px;
}
th {
text-align: center;
}
</style></head>

<table>
<caption>Tree Node Traits</caption>
<tr><td>trait</td><td>sub-package</td><td>description</td></tr>
<tr><td>Node[K]</td> <td>redblack.tree</td><td>Fundamental Red-Black tree functionality</td></tr>
<tr><td>NodeMap[K,V]</td><td>ordered.tree</td><td>Support a mapping from keys to values</td></tr>
<tr><td>NodeNear[K]</td><td>nearest.tree</td><td>Nearest-entry query (key-only)</td></tr>
<tr><td>NodeNearMap[K,V]</td><td>nearest.tree</td><td>Nearest-entry query for key/value maps</td></tr>
<tr><td>NodeInc[K,V]</td><td>increment.tree</td><td>Increment values w.r.t. a monoid</td></tr>
<tr><td>NodePS[K,V,P]</td><td>prefixsum.tree</td><td>Prefix sum queries by key (w.r.t. a monoid)</td></tr>
</table>

<br>
<table>
<caption>Collection Traits</caption>
<tr><td>trait</td><td>sub-package</td><td>description</td></tr>
<tr><td>OrderedSetLike[K,IN,M]</td><td>ordered</td><td>ordered set of keys</td></tr>
<tr><td>OrderedMapLike[K,V,IN,M]</td><td>ordered</td><td>ordered key/value map</td></tr>
<tr><td>NearestSetLike[K,IN,M]</td><td>nearest</td><td>nearest entry query on keys</td></tr>
<tr><td>NearestMapLike[K,V,IN,M]</td><td>nearest</td><td>nearest entry query on key/value map</td></tr>
<tr><td>IncrementMapLike[K,V,IN,M]</td><td>increment</td><td>increment values w.r.t a monoid</td></tr>
<tr><td>PrefixSumMapLike[K,V,P,IN,M]</td><td>prefixsum</td><td>prefix sum queries w.r.t. a monoid</td></tr>
</table>

<br>
<table>
<caption>Concrete Collections</caption>
<tr><td>trait</td><td>sub-package</td><td>description</td></tr>
<tr><td>OrderedSet[K]</td><td>ordered</td><td>ordered set</td></tr>
<tr><td>OrderedMap[K,V]</td><td>ordered</td><td>ordered key/value map</td></tr>
<tr><td>NearestSet[K]</td><td>nearest</td><td>ordered set with nearest-entry query</td></tr>
<tr><td>NearestMap[K,V]</td><td>nearest</td><td>ordred map with nearest-entry query</td></tr>
<tr><td>IncrementMap[K,V]</td><td>increment</td><td>ordered map with value increment w.r.t. a monoid</td></tr>
<tr><td>PrefixSumMap[K,V,P]</td><td>prefixsum</td><td>ordered map with prefix sum query w.r.t. a monoid</td></tr>
</table>

<br>
The following diagram summarizes the organization and inheritance relationships of the classes.

![diagram](/assets/images/rbtraits/rbtraits.png)

<a name="redblack"></a>
##### A Red/Black Tree Base Class
The most fundamental trait in this hierarchy is the trait that embodies Red-Black balancing; a "red-black-ness" trait, as it were.  This trait supplies the axiomatic tree operations of insertion, deletion and key lookup, where the Red-Black balancing operations are encapsulated for insertion (due to [Chris Okasaki](http://journals.cambridge.org/action/displayAbstract?fromPage=online&aid=44273)) and deletion (due to [Stefan Kahrs](http://www.cs.kent.ac.uk/people/staff/smk/redblack/rb.html))  Note that Red-Black trees do not assume a separate value, as in a map, but require only keys (thus implementing an ordered set over the key type):

``` scala
object tree {
  /** The color (red or black) of a node in a Red/Black tree */
  sealed trait Color
  case object R extends Color
  case object B extends Color

  /** Defines the data payload of a tree node */
  trait Data[K] {
    /** The axiomatic unit of data for R/B trees is a key */
    val key: K
  }

  /** Base class of a Red/Black tree node
    * @tparam K The key type
    */
  trait Node[K] {

    /** The ordering that is applied to key values */
    val keyOrdering: Ordering[K]

    /** Instantiate an internal node. */
    protected def iNode(color: Color, d: Data[K], lsub: Node[K], rsub: Node[K]): INode[K]

    // ... declarations for insertion, deletion and key lookup ...

    // ... red-black balancing rules ...
  }
  
   /** Represents a leaf node in the Red Black tree system */
  trait LNode[K] extends Node[K] {
    // ... basis case insertion, deletion, lookup ...
  }

  /** Represents an internal node (Red or Black) in the Red Black tree system */
  trait INode[K] extends Node[K] {
    /** The Red/Black color of this node */
    val color: Color
    /** Including, but not limited to, the key */
    val data: Data[K]
    /** The left sub-tree */
    val lsub: Node[K]
    /** The right sub-tree */
    val rsub: Node[K]

    // ... implementations for insertion, deletion, lookup ...
  }
}
```
I will assume most readers are familiar with basic binary tree operations, and the Red-Black rules are described elsewhere (I adapted them from the Scala red-black implementation).  For the purposes of this discussion, the most interesting feature is that this is a _pure Scala trait_.  All `val` declarations are abstract.  This trait, by itself, cannot function without a subclass to eventually perform dependency injection.   However, this abstraction allows the trait to be inherited freely -- any programmer can inherit from this trait and get a basic Red-Black balanced tree for (nearly) free, as long as a few basic principles are adhered to for proper dependency injection.

Another detail to call out is the abstraction of the usual `key` with a `Data` element.  This element represents any node payload that is moved around as a unit during tree structure manipulations, such as balancing pivots.  In the case of a map-like subclass, `Data` is extended to include a `value` field as well as a `key` field.

The other noteworthy detail is the abstract definition `def iNode(color: Color, d: Data[K], lsub: Node[K], rsub: Node[K]): INode[K]` - this is the function called to create any new tree node.  In fact, this function, when eventually instantiated, is what performs dependency injection of other tree node fields.

<a name="nodemap"></a>
##### Node Inheritance Example: NodeMap[K,V]
A relatively simple example of node inheritance is hopefully instructive.  Here is the definition for tree nodes supporting a key/value map:

``` scala
object tree {
  /** Trees that back a map-like object have a value as well as a key */
  trait DataMap[K, V] extends Data[K] {
    val value: V
  }

  /** Base class of ordered K/V tree node
    * @tparam K The key type
    * @tparam V The value type
    */
  trait NodeMap[K, V] extends Node[K]

  trait LNodeMap[K, V] extends NodeMap[K, V] with LNode[K]

  trait INodeMap[K, V] extends NodeMap[K, V] with INode[K] {
    val data: DataMap[K, V]
  }
}
```

Note that in this case very little is added to the red/black functionality already provided by `Node[K]`.  A `DataMap[K,V]` trait is defined to add a `value` field in addition to the `key`, and the internal node `INodeMap[K,V]` refines the type of its `data` field to be `DataMap[K,V]`.  The semantics is little more than "tree nodes now carry a value in addition to a key."

A tree node trait inherits from its own parent class _and_ the corresponding traits for any mixed-in functionality.  So for example `INodeMap[K,V]` inherits from `NodeMap[K,V]` but also `INode[K]`.

<a name="orderedmaplike"></a>
##### Collection Trait Example: OrderedMapLike[K,V,IN,M]
Continuing with the ordered map example, here is the definition of the collection trait for an ordered map:

``` scala
trait OrderedMapLike[K, V, IN <: INodeMap[K, V], M <: OrderedMapLike[K, V, IN, M]]
    extends NodeMap[K, V] with OrderedLike[K, IN, M] {

  /** Obtain a new map with a (key, val) pair inserted */
  def +(kv: (K, V)) = this.insert(
    new DataMap[K, V] {
      val key = kv._1
      val value = kv._2
    }).asInstanceOf[M]

  /** Get the value stored at a key, or None if key is not present */
  def get(k: K) = this.getNode(k).map(_.data.value)

  /** Iterator over (key,val) pairs, in key order */
  def iterator = nodesIterator.map(n => ((n.data.key, n.data.value)))

  /** Container of values, in key order */
  def values = valuesIterator.toIterable

  /** Iterator over values, in key order */
  def valuesIterator = nodesIterator.map(_.data.value)
}
```
You can see that this trait supplies collection API methods that a Scala programmer will recognize as being standard for any map-like collection.  Note that this trait also inherits other standard methods from `OrderedLike[K,IN,M]` (common to both sets and maps) and _also_ inherits from `NodeMap[K,V]`: In other words, a collection is effectively yet another kind of tree node, with additional collection API methods mixed in.   Note also the use of "self types" (the type parameter `M`), which allows the collection to return objects of its own kind.  This is crucial for allowing operations like data insertion to return an object that also supports node insertion, and to maintain consistency of type across operations.  The collection type is properly "closed" with respect to its own operations.

<a name="orderedmap"></a>
##### Collection Example: OrderedMap[K,V]
To conclude the ordered map example, consider the task of defining a concrete instantiation of an ordered map:
``` scala
sealed trait OrderedMap[K, V] extends OrderedMapLike[K, V, INodeMap[K, V], OrderedMap[K, V]] {
  override def toString =
    "OrderedMap(" +
      nodesIterator.map(n => s"${n.data.key} -> ${n.data.value}").mkString(", ") +
    ")"
}
```
You can see that (aside from a convenience override of `toString`) the trait `OrderedMap[K,V]` is nothing more than a vehicle for instantiating a particular concrete `OrderedMapLike[K,V,IN,M]` subtype, with particular concrete types for internal node (`INodeMap[K,V]`) and its own self-type.

Things become a little more interesting inside the companion object `OrderedMap`: 
``` scala
object OrderedMap {
  def key[K](implicit ord: Ordering[K]) = new AnyRef {
    def value[V]: OrderedMap[K, V] =
      new InjectMap[K, V](ord) with LNodeMap[K, V] with OrderedMap[K, V]
  }
}
```
Note that the object returned by the factory method is upcast to `OrderedMap[K,V]`, but in fact has the more complicated type: `InjectMap[K,V] with LNodeMap[K,V] with OrderedMap[K,V]`.  There are a couple things going on here.  The trait `LNodeMap[K,V]` ensures that the new object is in particular a leaf node, which embodies a new empty tree in the Red-Black tree system.

The type `InjectMap[K,V]` has an even more interesting purpose.  Here is its definition:
``` scala
class InjectMap[K, V](val keyOrdering: Ordering[K]) {
  def iNode(clr: Color, dat: Data[K], ls: Node[K], rs: Node[K]) =
    new InjectMap[K, V](keyOrdering) with INodeMap[K, V] with OrderedMap[K, V] {
      // INode
      val color = clr
      val lsub = ls
      val rsub = rs
      val data = dat.asInstanceOf[DataMap[K, V]]
    }
}
```
Firstly, note that it is a bona fide _class_, as opposed to a trait.  This class is where, finally, all things abstract are made real -- "dependency injection" in the parlance of Scala idioms.  You can see that it defines the implementation of abstract method `iNode`, and that it does this by returning yet _another_ `InjectMap[K,V]` object, mixed with both `INodeMap[K,V]` and `OrderedMap[K,V]`, thus maintaining closure with respect to all three slices of functionality: dependency injection, the proper type of internal node, and map collection methods.

The various abstract `val` fields `color`, `data`, `lsub` and `rsub` are all given concrete values inside of `iNode`.  Here is where the value of concrete "reference" implementations manifests.  Any fields in the relevant internal-node type must be instantiated here, and the logic of instantiation cannot be inherited while still preserving the ability to mix abstract traits.  Therefore, any programmer wishing to create a new concrete sub-class must replicate the logic for instantiating all inherited in an internal node.

Another example makes the implications more clear.  Here is the definition of injection for a [collection that mixes in all three traits](https://github.com/erikerlandson/silex/blob/blog/rbtraits/src/test/scala/com/redhat/et/silex/maps/mixed.scala) for incrementable values, nearest-key queries, and prefix-sum queries:

``` scala
  class Inject[K, V, P](
    val keyOrdering: Numeric[K],
    val valueMonoid: Monoid[V],
    val prefixMonoid: IncrementingMonoid[P, V]) {
      def iNode(clr: Color, dat: Data[K], ls: Node[K], rs: Node[K]) =
      new Inject[K, V, P](keyOrdering, valueMonoid, prefixMonoid)
          with INodeTD[K, V, P] with TDigestMap[K, V, P] {
        // INode[K]
        val color = clr
        val lsub = ls.asInstanceOf[NodeTD[K, V, P]]
        val rsub = rs.asInstanceOf[NodeTD[K, V, P]]
        val data = dat.asInstanceOf[DataMap[K, V]]
        // INodePS[K, V, P]
        val prefix = prefixMonoid.inc(prefixMonoid.plus(lsub.pfs, rsub.pfs), data.value)
        // INodeNear[K, V]
        val kmin = lsub match {
          case n: INodeTD[K, V, P] => n.kmin
          case _ => data.key
        }
        val kmax = rsub match {
          case n: INodeTD[K, V, P] => n.kmax
          case _ => data.key
        }
      }
  }
```
Here you can see that all logic for both "basic" internal nodes and also for maintaining prefix sums, and key min/max information for nearest-entry queries, must be supplied.  If there is a singularity in this design here is where it is.  The saving grace is that it is localized into a single well defined place, and any logic can be transcribed from a proper reference implementation of whatever traits are being mixed.

<a name="mixing"></a>
##### Finale: Trait Mixing
I will conclude by showing the code for mixing tree node traits and collection traits, which is elegant.  Here are type definitions for tree nodes and collection traits that inherit from incrementable values, nearest-key queries, and prefix-sum queries, and there is almost no code except the proper inheritances:

``` scala
object tree {
  import com.redhat.et.silex.maps.increment.tree._
  import com.redhat.et.silex.maps.prefixsum.tree._
  import com.redhat.et.silex.maps.nearest.tree._

  trait NodeTD[K, V, P] extends NodePS[K, V, P] with NodeInc[K, V] with NodeNearMap[K, V]

  trait LNodeTD[K, V, P] extends NodeTD[K, V, P]
      with LNodePS[K, V, P] with LNodeInc[K, V] with LNodeNearMap[K, V]

  trait INodeTD[K, V, P] extends NodeTD[K, V, P]
      with INodePS[K, V, P] with INodeInc[K, V] with INodeNearMap[K, V] {
    val lsub: NodeTD[K, V, P]
    val rsub: NodeTD[K, V, P]
  }
}

// ...

sealed trait TDigestMap[K, V, P]
  extends IncrementMapLike[K, V, INodeTD[K, V, P], TDigestMap[K, V, P]]
  with PrefixSumMapLike[K, V, P, INodeTD[K, V, P], TDigestMap[K, V, P]]
  with NearestMapLike[K, V, INodeTD[K, V, P], TDigestMap[K, V, P]] {

  override def toString = // ...
}
```
