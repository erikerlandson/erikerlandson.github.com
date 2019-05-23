---
layout: post
title: 'Unit Types for Avro Schema: Integrating Avro with Coulomb'
date: 2019-05-22 17:18 -0700
tags: [ computing, unit analysis, avro, schema ]
---

In a
[previous post](http://erikerlandson.github.io/blog/2019/05/09/preventing-configuration-errors-with-unit-types/)
I showed how software configuration errors could be prevented by supporting values with unit types.
Configuration systems are an important use case for unit types, but they are far from the only one.
In this post I will show a similar integration of the [coulomb](https://github.com/erikerlandson/coulomb)
project with [Apache Avro](https://avro.apache.org/) schema.

The Avro data seralization library is a useful integration point for
[coulomb unit types](https://github.com/erikerlandson/coulomb#quantity-and-unit-expressions).
Avro serialization is schema-driven, and supports user supplied metadata, which allows unit type information
to be added to a schema.
Since the schema is decoupled from the data, the unit type information does not add to the cost of the
actual data, only the schema.
Even more importantly, Avro itself is used in a variety of other ecosystem projects, for example
[Apache Kafka](https://kafka.apache.org/).

The following examples are based on the `coulomb-avro` package.
You can learn more about how to use this project
[here](https://github.com/erikerlandson/coulomb#how-to-include-coulomb-in-your-project)
and
[here](https://erikerlandson.github.io/coulomb/latest/api/coulomb/avro/package$$EnhanceGenericRecord.html).

Consider this small Avro schema:
```
{
    "type": "record",
    "name": "smol",
    "fields": [
        { "name": "latency", "type": "double", "unit": "second" },
        { "name": "bandwidth", "type": "double", "unit": "gigabyte / second" }
    ]
}
```
As you can see, the fields in this schema have been augmented with a `"unit"` metadata field,
that contains a unit expression.

What can we do with this additional metadata?
The following example begins to demonstrate how the `"unit"` information is used by `avro-coulomb`:

```scala
scala> val schema = new Schema.Parser().parse(new java.io.File("smol.avsc"))
schema: org.apache.avro.Schema = {"type":"record","name":"smol","fields":[{"name":"latency","type":"double","unit":"second"},{"name":"bandwidth","type":"double","unit":"gigabyte / second"}]}

scala> val rec = new GenericData.Record(schema)
rec: org.apache.avro.generic.GenericData.Record = {"latency": null, "bandwidth": null}

scala> val qp = QuantityParser[Second :: Byte :: Hour :: Giga :: HNil]
qp: coulomb.parser.QuantityParser = coulomb.parser.QuantityParser@79f0045

scala> rec.putQuantity(qp)("latency", 100.withUnit[Milli %* Second])

scala> rec.putQuantity(qp)("bandwidth", 1.withUnit[Tera %* Bit %/ Minute])

scala> rec
res8: org.apache.avro.generic.GenericData.Record = {"latency": 0.1, "bandwidth": 2.083333}
```

What is happening here?
Firstly, the loading of an Avro schema, and creating a record from it, is standard to Avro.
Notice that the custom `"unit"` meta-data is preserved by Avro's standard methods.
Next, I am declaring a
[`QuantityParser`](https://github.com/erikerlandson/coulomb#quantity-parsing).
The quantity parser allows the unit expresions in the schema to be reconciled with the unit types
appearing in Scala.
You can see the quantity parser being used by the
[`putQuantity`](https://erikerlandson.github.io/coulomb/latest/api/coulomb/avro/package$$EnhanceGenericRecord.html)
method, which accepts a coulomb
[`Quantity`](https://github.com/erikerlandson/coulomb#quantity-and-unit-expressions)
instead of a raw data value of type Double, Int, etc.

What are these coulomb extensions buying us?
Notice that I can set the "latency" field with a value in _milliseconds_ (`Milli %* Second`)
even though my schema denotes a unit of "seconds".
Furthermore, the parser correctly determined that milliseconds are convertable to seconds,
and did this conversion automatically.
The coulomb library can perform these kind of computations on unit expressions of
[arbitrary complexity](https://github.com/erikerlandson/coulomb#quantity-and-unit-expressions),
which you can see in operation while setting the "bandwidth" field,
which correctly converts terabits/minute into gigabytes/second.

Equally important, this tool understands when units are _not_ compatible.
The following attempt to set a field with units that are not convertable is also detected by the
parser and fails:
```scala
scala> rec.putQuantity(qp)("latency", 100.withUnit[Milli %* Meter])
java.lang.Exception: unit metadata "second" incompatible with "coulomb.%*[coulomb.siprefix.Milli, coulomb.si.Meter]"
```

Coulomb quantities are also supported on the field reading side
Here we use the
[`getQuantity`](https://erikerlandson.github.io/coulomb/latest/api/coulomb/avro/package$$EnhanceGenericRecord.html)
extension to extract field values into type safe units:
```scala
scala> rec.getQuantity[Double, Micro %* Second](qp)("latency")
res12: coulomb.Quantity[Double,coulomb.siprefix.Micro %* coulomb.si.Second] = Quantity(100000.0)

scala> rec.getQuantity[Double, Giga %* Bit %/ Minute](qp)("bandwidth")
res13: coulomb.Quantity[Double,coulomb.siprefix.Giga %* coulomb.info.Bit %/ coulomb.time.Minute] = Quantity(1000.0)
```
As with `putQuantity`, unit types and expressions are reconciled by the compiler and properly converted.
As before, unit incompatibilities result in parse error:
```scala
scala> rec.getQuantity[Double, Byte](qp)("latency")
java.lang.Exception: unit metadata "second" incompatible with "coulomb.info.Byte"
```

Another important consequence of using
[coulomb](https://github.com/erikerlandson/coulomb)
with Avro is that in your Scala code you can use coulomb
[Quantity](https://github.com/erikerlandson/coulomb#quantity-and-unit-expressions)
values, for compile-time unit type checking.

I hope this post has demonstrated how unit type expressions for Avro schema can make your
data schema safer and more expressive!
