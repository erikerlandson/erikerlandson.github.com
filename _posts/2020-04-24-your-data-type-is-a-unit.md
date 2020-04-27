---
layout: post
title: Your Data Type is a Unit
date: 2020-04-26 07:09 -0700
tags: [ computing, unit analysis, scala, data types ]
---

In my various experiences with socializing the idea that our software should make more use of unit analysis,
I'm often met with some skepticism. The most common form of "unit analysis skepticism" goes something like this:

> "I can see how this might be useful for data involved with science or engineering,
but the data most software applications use doesn't really have units."

It's understandable why people think this way.

If we're taught unit analysis at all, we're almost always taught it in science class.
We learn to associate unit analysis with measures like meters, kilograms, liters and moles.
I'm as guilty as anyone in promoting this stereotype!
The examples I use in my own unit analysis
[tutorials](https://github.com/erikerlandson/coulomb#tutorial)
often look like something lifted from a physics-101 text:

```scala
val acceleration = (9.8).withUnit[Meter %/ (Second %^ 2)]
val ohms = (0.01).withUnit[(Kilogram %* (Meter %^ 2)) %/ ((Second %^ 3) %* (Ampere %^ 2))]
```

To the extent that software tooling **_does_** make use of units, it is almost exclusively units
like "megabytes" or "seconds" - that is, units of information and time.
If you work in sofware, you've likely seen values resembling `"100Mi"` or `"30s"`.

The way that most software represents even simple time or information units isn't as safe as people think.
I have a couple
[favorite stories](https://www.youtube.com/watch?v=qrQmB2KFKE8)
that illustrate the kind of problems that happen when we rely on
unaided humans to get units correct across multiple software components.

However, today's post is about something different.
I believe that we software developers are ignoring a whole universe of units that are all around us,
like fish in water:

**_All our data types are units in disguise!_**

Before I continue with my story, a brief aside:
The examples I'll be using are written in Scala, using the
[coulomb](https://github.com/erikerlandson/coulomb)
package for unit aware data types, and
[pureconfig](https://pureconfig.github.io/)
for statically typed i/o.
I annotated the scala imports I used, and other demo specifics, in the
[appendix](#appendix-scala-demo-notes).

I'll begin by defining a couple of collections, representing books and their authors.
Classes like these are the sort of structured data type one might see returning from a
[doobie](https://tpolecat.github.io/doobie/)
database query or Apache Spark
[dataset](https://spark.apache.org/docs/latest/sql-getting-started.html#creating-datasets):

```scala
scala> import coulomb.pureconfig.CaseClassTest.{ Book, Author }
import coulomb.pureconfig.CaseClassTest.{Book, Author}

scala> val books = List(
     | Book("Schild's Ladder", "Greg Egan"),
     | Book("Starfish", "Peter Watts"),
     | Book("The Integral Trees", "Larry Niven"),
     | Book("Incandescance", "Greg Egan"),
     | Book("The Freeze Frame Revolution", "Peter Watts"))
val books: List[Book] = List(Book(Schild's Ladder,Greg Egan), Book(Starfish,Peter Watts), Book(The Integral Trees,Larry Niven), Book(Incandescance,Greg Egan), Book(The Freeze Frame Revolution,Peter Watts))

scala> val authors = List(
     | Author("Greg Egan"),
     | Author("Peter Watts"),
     | Author("Larry Niven"))
val authors: List[Author] = List(Author(Greg Egan), Author(Peter Watts), Author(Larry Niven))
```

Consider counting these objects.
The standard `length` gives us an integer that represents the number of each object we have.

```scala
scala> (books.length, authors.length)
val res0: (Int, Int) = (5,3)
```

Imagine we have some function that takes these numbers as a parameter.
It's easy to call correctly, but on the other hand it's equally easy to make a mistake and pass the parameters
in the wrong order:

```scala
scala> def someFunction(nBooks: Int, nAuthors: Int) = s"$nAuthors authors wrote $nBooks books."
def someFunction(nBooks: Int, nAuthors: Int): String

scala> someFunction(authors.length, books.length) // mistake!
val res1: String = 5 authors wrote 3 books.
```

Pause to note that while there is obviously information about how to call this function correctly in the
definition of its parameter names, _the compiler is no help at all detecting this error._
As developers we learn to be careful about this sort of thing,
but anyone who has been in the business long enough has seen a bug like this make its way into production.

The problem extends into the realm of i/o.
Writing these values as raw integers gives neither us nor the compiler a way to prevent either
writing or reading values in the wrong order.
```scala
scala> val data = (books.length, authors.length).toConfig
val data: com.typesafe.config.ConfigValue = SimpleConfigList([5,3])

scala> val (nAuthors, nBooks) = data.toOrThrow[(Int, Int)]  // switched!
val nAuthors: Int = 5
val nBooks: Int = 3
```

But what are we _really_ counting, with `length`?
In the case of the collection `books`, we're counting objects of type `Book`.
In the case of `authors`, we're counting objects of type `Author`.
In other words the `Int` value returned by `length` has an **_implied unit_**,
and that unit **_is the data type of the collection!_**

Imagine a world where `length` returned not just an integer,
but an integer annotated with a unit that is the data type associated with the collection.
Here's an example of what that might look like, using coulomb `Quantity` to associate values
with units:

```scala
scala> implicit class UnitLengthSyntax[A](seq: Seq[A]) {
     | def unitLength: Quantity[Int, A] = seq.length.withUnit[A]
     | }
class UnitLengthSyntax

scala> books.unitLength
val res5: coulomb.Quantity[Int,coulomb.pureconfig.CaseClassTest.Book] = Quantity(5)

scala> books.unitLength.show
val res6: String = 5 Book

scala> authors.unitLength
val res7: coulomb.Quantity[Int,coulomb.pureconfig.CaseClassTest.Author] = Quantity(3)

scala> authors.unitLength.show
val res8: String = 3 Author
```

When we do this, something interesting happens to our software APIs.
Let's re-write our earlier function to make use of units for improved type safety:

```scala
scala> def safeFunction(nBooks: Quantity[Int, Book], nAuthors: Quantity[Int, Author]) =
     | s"${nAuthors.value} authors wrote ${nBooks.value} books."
def safeFunction(nBooks: coulomb.Quantity[Int,coulomb.pureconfig.CaseClassTest.Book], nAuthors: coulomb.Quantity[Int,coulomb.pureconfig.CaseClassTest.Author]): String

scala> safeFunction(books.unitLength, authors.unitLength)
val res3: String = 3 authors wrote 5 books.

scala> safeFunction(authors.unitLength, books.unitLength)  // switched!
                            ^
       error: type mismatch;
        found   : coulomb.Quantity[Int,coulomb.pureconfig.CaseClassTest.Author]
        required: coulomb.Quantity[Int,coulomb.pureconfig.CaseClassTest.Book]
```

With the additional unit information attached to collection length,
the compiler is now quite helpful catching our human error!
As programmers, we're suddenly a bit less dependent on unreliable humans to properly interpret our
documentation or our API parameter names, and get the order right.

Unit information has similar implications for I/O.
Let's re-run our earlier pureconfig i/o example with unit awareness:

```scala
scala> val data = (books.unitLength, authors.unitLength).toConfig
val data: com.typesafe.config.ConfigValue = SimpleConfigList([{"unit":"Book","value":5},{"unit":"Author","value":3}])
```

Now, our data is written with unit information, where our unit is the data type we're working with.
Likewise, we can load data with unit awareness
(note that we have to provide the loader with a parser that knows how to unpack unit expressions):

```scala
scala> implicit val qp = QuantityParser.withImports[Book :: Author :: HNil]("coulomb.policy.undeclaredBaseUnits._")

val qp: coulomb.parser.QuantityParser = coulomb.parser.QuantityParser@3c057034

scala> val (nBooks, nAuthors) =
     | data.toOrThrow[(Quantity[Int, Book], Quantity[Int, Author])]
val nBooks: coulomb.Quantity[Int,coulomb.pureconfig.CaseClassTest.Book] = Quantity(5)
val nAuthors: coulomb.Quantity[Int,coulomb.pureconfig.CaseClassTest.Author] = Quantity(3)

scala> nBooks.show
val res9: String = 5 Book

scala> nAuthors.show
val res10: String = 3 Author
```

With unit awareness, our earlier error of trying to read data in the wrong order is no longer possible:

```scala
scala> val (nAuthors, nBooks) =
     | data.toOrThrow[(Quantity[Int, Author], Quantity[Int, Book])]
pureconfig.error.ConfigReaderException: Cannot convert configuration to a scala.Tuple2. Failures are:
  at '0':
    - Cannot convert '{
          # hardcoded value
          "unit" : "Book",
          # hardcoded value
          "value" : 5
      }
      ' to coulomb.Quantity[Int,coulomb.pureconfig.CaseClassTest.Author]: Failed to parse (5, Book) ==> coulomb.pureconfig.CaseClassTest.Author.
```

What I've just demonstrated isn't revolutionary -
the point of data types has always been to
["make illegal states unrepresentable."](https://fsharpforfunandprofit.com/posts/designing-with-types-making-illegal-states-unrepresentable/)
Using types as units is one more way of leveraging types to make new categories of error impossible.
Even the traditional science-oriented unit analysis has always been essentially a type-checking operation.
If my units aren't what I was expecting, I've got a problem with my math!

Backing this basic idea with a true unit analysis offers many possibilities.
Suppose I'm interested in how many books, on average, the authors in my database have written.
I can get this ratio easily, and the resulting data type reflects the proper unit `Book/Author`:

```scala
scala> val ratio =
     | books.unitLength.toValue[Float] / authors.unitLength.toValue[Float]
val ratio: coulomb.Quantity[Float,coulomb.pureconfig.CaseClassTest.Book %/ coulomb.pureconfig.CaseClassTest.Author] = Quantity(1.6666666)

scala> ratio.show
val res22: String = 1.6666666 Book/Author
```

If I wanted to estimate the number of books for 1000 authors, it looks like this:
```scala
scala> val estimate = 1000f.withUnit[Author] * ratio
val estimate: coulomb.Quantity[Float,coulomb.pureconfig.CaseClassTest.Book] = Quantity(1666.6666)

scala> estimate.show
val res24: String = 1666.6666 Book
```

Suppose I am serving my book objects over a microservice.
I might like to predict how many book queries I can serve per second over my network.
The following stanza sets up this problem with unit type safety,
and gives an answer in the units I choose (thousand books per second).

```scala
scala> val bandwidth = 100f.withUnit[Mega %* Byte %/ Second]
val bandwidth: coulomb.Quantity[Float,coulomb.siprefix.Mega %* Byte %/ coulomb.si.Second] = Quantity(100.0)

scala> val bookmem =
     | books.map{b => b.title.size + b.author.size}.sum.
     | toFloat.withUnit[Byte] / books.unitLength
val bookmem: coulomb.Quantity[Float,Byte %/ coulomb.pureconfig.CaseClassTest.Book] = Quantity(26.4)

scala> val bookrate = (bandwidth / bookmem).toUnit[Kilo %* Book %/ Second]
val bookrate: coulomb.Quantity[Float,coulomb.siprefix.Kilo %* coulomb.pureconfig.CaseClassTest.Book %/ coulomb.si.Second] = Quantity(3787.8787)

scala> bookrate.showFull
val res34: String = 3787.8787 kiloBook/second
```

Unit checking helped me write this post.
While doing the above example, I used the wrong ratio, but the compiler caught my error!

```scala
scala> val bookrate = (bookmem / bandwidth).toUnit[Kilo %* Book %/ Second]
                                                  ^
       error: could not find implicit value for parameter uc ...
```

In the example above, I had to attach units to several of my numbers "by hand",
using the `.toUnit` method.
Imagine a world where our software APIs came with unit information out of the box.
An expression like `book.title.size` could, by default, return a value like `Quantity[Int, Byte]`,
instead of the less informative `Int`.
Our platform APIs could return properties like network bandwidth limits in `Quantity[Float, Mega %* Byte %/ Second]` automatically.

Once you start thinking this way, you begin to see opportunities all around.
Perusing the standard `struct stat`
[unix file attributes](http://www.gnu.org/software/libc/manual/html_node/Attribute-Meanings.html)
immediately turns up multiple examples of implied units:

<table style="width:50%">
<tr><th>attribute</th><th>implied unit</th></tr>
<tr><td>st_nlink</td><td>hard links</td></tr>
<tr><td>st_size</td><td>bytes</td></tr>
<tr><td>st_blocks</td><td>filesystem blocks</td></tr>
<tr><td>st_blksize</td><td>bytes</td></tr>
<tr><td>st_atime</td><td>seconds (from epoch)</td></tr>
</table>

The widely-used
[Kubernetes](https://kubernetes.io/)
container orchestration platform is another source of examples.
[Resources requests](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-types)
are all specified using implied units such as "cpus" or "bytes".
Kubernetes supports a concept of units for some of these values
(for example memory: "Mi", "Gi" etc.)
but it has no tooling to support units as first class data types.
The Kubernetes API has a variety of opportunities for treating object types such as
`Pod`, `Container`, or `Node` as first-class units, instead of just implied units.

This kind of
[algorithmic unit analysis](http://erikerlandson.github.io/blog/2019/05/03/algorithmic-unit-analysis/)
on types is powerful (and fun),
but the bigger point I want to make is that vanilla data types like `Book` and `Author`
_fold into a unit analysis with no friction_.
This gets at a deeper relation:
It is useful to treat units as data types, but the converse also holds:
**_all data types are latent units._**
If we take full advantage of this idea,
we can increase the positive impact of unit types on software quality by an of magnitude.

#### Explore

* [coulomb](https://github.com/erikerlandson/coulomb) - Unit Analysis for Scala
* [algorithmic unit analysis](http://erikerlandson.github.io/blog/2019/05/03/algorithmic-unit-analysis/)
* ["Why Your Data Schema Should Include Units"](https://www.youtube.com/watch?v=qrQmB2KFKE8) at Berlin Buzzwords 2019

#### Appendix: Scala Demo Notes

I ran the examples in this blog using Scala 2.13.2, and coulomb 0.4.6.

I ran the REPL using the following command,
in order to pick up the definitions of `Book` and `Author`.
(Defining case classes in the REPL session itself causes
problems with resolving types inside `QuantityParser`)

```bash
$ cd /path/to/coulomb
$ sbt coulomb_tests/test:console
```

The Scala REPL session in this blog used the following imports.

```scala
import spire.std.any._
import _root_.pureconfig._
import _root_.pureconfig.generic.auto._
import _root_.pureconfig.syntax._
import eu.timepit.refined._
import eu.timepit.refined.api._
import eu.timepit.refined.numeric._
import coulomb._
import coulomb.pureconfig._
import coulomb.parser.QuantityParser
import shapeless.{ ::, HNil}
import coulomb.refined._
import coulomb.pureconfig.refined._
import coulomb.si.{Kilogram, Meter, Second}
import coulomb.info.Byte
import coulomb.us.Foot
import coulomb.policy.undeclaredBaseUnits._
import coulomb.pureconfig.CaseClassTest._
```
