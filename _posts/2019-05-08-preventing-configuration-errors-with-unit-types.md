---
layout: post
title: Preventing Configuration Errors With Unit Types
date: 2019-05-09 12:16 -0700
tags: [ computing, coulomb, units, unit analysis ]
---

Anyone who has worked with software
has almost certainly had the experience of tracking down a software or systems problem to
discover that it was caused by an incorrectly configured parameter.
Settings get misconfigured for a variety of reasons, but one recurring pattern of error is a
value that was set assuming a _unit_ that wasn't expected.

What do I mean by "unit"? Consider this snippet of an Apache Kafka configuration file:

```
log.flush.interval.messages=1000
log.flush.interval.ms=10000
log.flush.scheduler.interval.ms=1000
log.retention.hours=24
log.segment.bytes=1000000
log.retention.check.interval.ms=30000
log.roll.hours=24
```

Just in these few Kafka configuration parameters, we can see four units in play:
two units of time (milliseconds and hours), a unit of information (bytes) and the unit (messages).

A _unit_, in this context, is a _standard of measurement_ to denote some particular kind of quantity.
We define units for quantities such as information (bytes, bits), time (seconds, hours, days),
length (feet, meters), and so on.
The physical sciences define seven such kinds of quantity, each having their own standard unit;
these are the Standard International (SI)
[Base Units](https://simple.wikipedia.org/wiki/International_System_of_Units#Base_units).

Let's return to our Kafka configuration.
We can see that information about the expected units is encoded in the parameter names,
_not_ in the values themselves.
For example, the parameter `log.retention.hours` tells us that it is expecting a time in units of hours.

This is helpful information for a user, and yet it provides relatively little in the way of
_actively protecting_ against accidents.
Suppose this value is somehow configured assuming _seconds_, and so set to 86400;
now the configured log retention time is off by a _factor of 3600_ from its intended value!

Pause to note that this is all the same to the configuration system: 86400 is just another number, like 24.
It will happily set the log retention time 3600 times too large,
quite likely causing some disk volume to fill up a couple weeks later.
The result will be data loss, possibly a software crash, and almost certainly unplanned
overtime for an unlucky ops team.

I can hear some readers thinking:
"That would be bad, but what are the odds? It says hours right in the name!"
Nevertheless, Murphy's Law rules our world.
Perhaps the person who set up the configuration was in a hurry and rushing the job.
They could have been awake for 36 hours, and not thinking clearly.
They might not speak English, and weren't 100% clear on what the word "hour" even means.
Quite possibly, the configuration file was generated by some _other_ piece of software,
and that software had a unit bug in it.
Furthermore, not all configuration naming systems are as thoughtfully composed as Kafka's.
There are plenty of configuration parameters out in the wild that don't have any helpful unit information baked
into the parameter names.

So far, I've been examining the configuration process from the point of view of setting parameter values.
There are some similar issues on the software side, where these values are read.
Here is some pseudo-code that loads a value from a configuration
(as you might guess, it looks pretty similar in most common languages):
```
secondsPerHour = 3600
// my system calls are going to expect seconds
logRetentionSeconds = conf.getInt("log.retention.hours") * secondsPerHour
```
Firstly, note that the variable `logRetentionSeconds` is loaded as an integer value.
It's unit (seconds) is being baked into its name, the same way that configuration parameter
names have units baked into theirs.
As with configuration file values, there are a variety of things that might go wrong here.
The programmer might not be so consciencious, and just name it `logRetentionTime` or `logRetention`,
and elsewhere in the code noone will be quite sure what the units are.
Worse yet, they might compute the value incorrectly, and future maintainers will wonder
why they have a bug, not realizing that the variable `logRetentionHours` is lying to them.
Case in point: while writing this, I accidentally divided instead of multiplied in the example code above,
before I caught my error!
Lastly, doing the conversion from hours to seconds itself is tedious (and prone to error), requiring
either a magic number or referring to the right constant value.

We are all acquainted with the pitfalls of working this way, but what is to be done?

I'll start by pointing out that units, like hours, bytes, milliseconds, etc, are _annotations_ that convey
information about a numeric value; in particular they _constrain_ the interpretation of that value.
A value of 10 seconds is representing a quantity of time, and with the same measure, as a value of 30 seconds,
but is _different_ than a value of 10 bytes, or even 10 minutes.

These kinds of constraints might sound familiar to programmers: they are acting like _data types_!
Programmers are intuitively used to working with types such as "string", "int" or "boolean".
We know, whether we have thought about it consciously or not, that values with the type "string" are
constrained in different ways than, for example, an "int".
They support different kinds of operations.
They can't be used interchangeably; if you try, either a compiler error or a run-time error will result.

What if _units_ could be represented as data types?

In a world where units could be applied to numeric values as first-class data types, a mistake in unit
assignment would show up immediately as a compile error.
Units that _can_ be converted (such as hours and seconds) might be automatically converted by the compiler,
eliminating the need for tedious and error-prone conversions in the code.

What would programming in such a world look like?

To explore these possibilities, I have been working on an
[algorithmic unit analysis](http://erikerlandson.github.io/blog/2019/05/03/algorithmic-unit-analysis/)
implemented as a type system for Scala.
The project itself is called
[coulomb](https://github.com/erikerlandson/coulomb#coulomb);
it supports many unit analysis
[features](https://github.com/erikerlandson/coulomb#features),
including compile-time unit checking, unit conversions, and easily-extensible unit definitions.

What happens when a tool such as coulomb is used to apply unit analysis to the task of configuation?
In the following demonstration I'll show what configuration with units looks like,
and also how they appear when they are loaded in Scala code.

I'll begin by spinning up a scala REPL from the coulomb repo, and importing some definitions.
Here you can see I'm importing coulomb "core" definitions plus SI units, time units and information units.
I'm also importing the coulomb
[QuantityParser](https://erikerlandson.github.io/coulomb/latest/api/coulomb/parser/QuantityParser.html)
and its
[integration package](https://erikerlandson.github.io/coulomb/latest/api/coulomb/typesafeconfig/index.html)
for the
[Typesafe](https://github.com/lightbend/config)
configuration library.
```
$ cd /path/to/coulomb

$ sbt coulomb_tests/console
Welcome to Scala 2.13.0-M5 (OpenJDK 64-Bit Server VM, Java 1.8.0_201).
Type in expressions for evaluation. Or try :help.

scala> import coulomb._, coulomb.si._, coulomb.siprefix._, coulomb.time._, coulomb.info._, coulomb.typesafeconfig._, coulomb.parser._, com.typesafe.config._, shapeless._
```

Next I'll construct a typesafe style configuration.
Here I'm creating it directly in the REPL, but this would typically reside in a separate file.
```scala
scala> val confTS = ConfigFactory.parseString("""
     |   "log-retention-time" = "24 hour"
     |   "log-segment-size" = "1 megabyte"
     |   "log-flush-interval" = "10 second"
     |   "log-demo-bandwidth" = "10 megabyte / second"
     | """)
confTS: com.typesafe.config.Config = Config(SimpleConfigObject({"log-demo-bandwidth":"10 megabyte / second","log-flush-interval":"10 second","log-retention-time":"24 hour","log-segment-size":"1 megabyte"}))
```
Let's pause to compare this with with our example configuration up above.
First, you can see that the unit annotation now resides in the actual configuration _values_.
Already, this offers some advantages.
The values are no longer just anonymous numbers; since the units are directly applied as annotations
(and constraints), the opportunities for unit errors are reduced.
If the configuration for "log-retention-time" was configured by an admin using seconds instead of hours,
that would no longer be an error, as value itself would be "86400 seconds".

Some additional features of coulomb appear here.
Prefixes such as "mega" are supported as
[first-class units](https://github.com/erikerlandson/coulomb#unit-prefixes).
If you look at the configuration of "log-demo-bandwidth", it is defined as a compound unit expression:
"megabyte / second".
Arbitrary
[unit expressions](https://github.com/erikerlandson/coulomb#quantity-and-unit-expressions)
are constructable in coulomb.

Now let's examine what it looks like to load these values in Scala code.
Continuing in our REPL, I will define a unit quantity parser and associate it with our configuration.
Here I am creating a parser that knows exactly the units I need to read my example config.
An application parser might include additional units and prefixes, as necessary.
```scala
scala> val qp = QuantityParser[Second :: Byte :: Hour :: Mega :: HNil]
qp: coulomb.parser.QuantityParser = coulomb.parser.QuantityParser@741f1957

scala> val conf = confTS.withQuantityParser(qp)
conf: coulomb.typesafeconfig.CoulombConfig = CoulombConfig(Config(SimpleConfigObject({"log-demo-bandwidth":"10 megabyte / second","log-flush-interval":"10 second","log-retention-time":"24 hour","log-segment-size":"1 megabyte"})),coulomb.parser.QuantityParser@741f1957)
```

With our unit parsing ready to go, we are now in a position to load some values:
```scala
scala> val logRetentionTime = conf.getQuantity[Int, Second]("log-retention-time")
logRetentionTime: scala.util.Try[coulomb.Quantity[Int,coulomb.si.Second]] = Success(Quantity(86400))

scala> logRetentionTime.get.showFull
res1: String = 86400 second
```
As the above example shows, if we load this value in our code using seconds instead of hours, then the coulomb
type system automatically does the right thing.
It gives us the correct integer value, coupled with the unit `Second` instead of `Hour`.

Equally importantly, if we attempt to load log retention time using an _incompatible_ unit, such as bytes,
it will not allow it!
That is a type error:
```scala
scala> val unitMistake = conf.getQuantity[Int, Byte]("log-retention-time")
unitMistake: scala.util.Try[coulomb.Quantity[Int,coulomb.info.Byte]] =
Failure(scala.tools.reflect.ToolBoxError: reflective compilation has failed:
```

The coulomb type system gives us the same unit type protection with our values _after_ we load them.
Imagine a system call that supported values with units, for example this hypothetical
system function that expects milliseconds, a common time unit at the system level:
```scala
scala> def fakeSysCall(ms: Quantity[Int, Milli %* Second]): String = ms.showFull
fakeSysCall: (ms: coulomb.Quantity[Int,coulomb.siprefix.Milli %* coulomb.si.Second])String

scala> fakeSysCall(logRetentionTime.get)
res2: String = 86400000 millisecond

scala> fakeSysCall(60.withUnit[Byte])
                              ^
       error: type mismatch;
        found   : coulomb.Quantity[Int,coulomb.info.Byte]
        required: coulomb.Quantity[Int,coulomb.siprefix.Milli %* coulomb.si.Second]
```
As with configuration loading, the type system will automatically convert units that are convertable,
but will fail to compile an attemp to use _incompatible_ units.

The same conversion and unit checking capabilities are supported for arbitrary unit expressions.
Here I'll load a bandwidth using gigabits per minute, when it's configured value was set using
megabytes / second.
If I try to load it using gigabits per meter, that fails, since it is not a compatible unit.
```scala
scala> val bandwidth = conf.getQuantity[Double, Giga %* Bit %/ Minute]("log-demo-bandwidth").get
bandwidth: coulomb.Quantity[Double,coulomb.siprefix.Giga %* coulomb.info.Bit %/ coulomb.time.Minute] = Quantity(4.8)

scala> bandwidth.showFull
res8: String = 4.8 gigabit/minute

scala> val oopsie = conf.getQuantity[Double, Giga %* Bit %/ Meter]("log-demo-bandwidth").get
scala.tools.reflect.ToolBoxError: reflective compilation has failed:

could not find implicit value for parameter uc: coulomb.unitops.UnitConverter[spire.math.Rational,coulomb.siprefix.Mega %* coulomb.info.Byte %/ coulomb.si.Second,spire.math.Rational,coulomb.siprefix.Giga %* coulomb.info.Bit %/ coulomb.si.Meter]
```

I hope this discussion has made a case that supporting unit analysis as a programming language type system
can make it easier and safer to configure our software systems.
Several modern programming languages in addition to Scala have advanced type systems with the potential
to support the kinds of capabilities demonstrated by coulomb, for example Haskell and Rust.
If these ideas inspire the exploration of unit analysis type systems in other communities, that would be
very exciting!