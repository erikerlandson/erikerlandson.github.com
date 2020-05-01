---
layout: post
title: Algorithmic Unit Analysis
date: 2019-05-03 08:50 -0700
tags: [ computing, unit analysis, algorithms ]
---

In many computing situations, we might like to associate a unit expression with a number, for example

$$
9.8 \ meter / (second ^ 2)
$$

As humans, we'd also like it if our computing tools could understand that many unit expressions are _equivalent_.

$$
\begin{aligned}
& 9.8 \ meter / (second ^ 2) \\
= \ & 9.8 \ meter / second / second \\
= \ & 9.8 \ meter \times second ^ {-2}
\end{aligned}
$$

Better yet, it would be very useful for our tools to know that some unit expressions are _convertable_.

$$
\begin{aligned}
9.8 \ meter / (second ^ 2) & = 32 \ foot / second / second \\
1 \ meter ^ 3 & = 1000 \ liter
\end{aligned}
$$

Equally important, we wish to define the idea that units may _not_ be compatible.

$$
\begin{aligned}
1 \ meter / second ^ 2  & \neq 1 \ foot / second \\
1 \ liter & \neq 1 \ meter ^ 2
\end{aligned}
$$

It turns out that there is a straightforward and efficient way to define such an algorithmic unit analysis.
Start with the following definition:

$$
\text{For some atom 'u', } base(u) \text { declares 'u' to be a "base unit" } \\
$$

For example, $$ base(meter) $$ declares the atom _meter_ to be a base unit.
Every base unit also implicitly defines an
[_abstract quantity_](https://en.wikipedia.org/wiki/International_System_of_Quantities).
The term $$ base(meter) $$ defines the abstract quantity of Length;
$$ base(second) $$ defines an abstract quantity of Duration, and so on.

Unit expressions may be constructed from these atomic base units, inductively:

$$
\begin{aligned}
& \bullet \text{The atom } \breve 1 \text{ (unitless) is a unit expression. } \\
& \bullet \text{An atom } u \text{ is a unit expression whenever } base(u) \text{ is declared. } \\
& \bullet \text{An atom } d \text{ is a unit expresion whenever } derived(d, e, c) \text{ is declared and } \\
& \quad e \text{ is a unit expression and } c \text{ is a numeric value > 0.} \\
& \bullet \text{For unit expressions } u, v \text { and exponent } p \text{, the following} \\
& \quad \text{are all unit expressions: } \\
& \quad \quad uv \text{  or  } u \times v \\
& \quad \quad u / v \\
& \quad \quad u ^ p
\end{aligned}
$$

In our constructions above, we introduced a special atom $$ \breve 1 $$ that represents a _unitless_ expression where all units have canceled.
For example $$ meter / meter $$ is equivalent to $$ \breve 1 $$.
We also introduced the idea of a _derived unit_, where a named unit _d_ is declared as equivalent to $$ c e $$.
For example we can use a derived unit to define a _liter_ as a unit of volume:
$$ derived(liter, meter^3, 1/1000) $$.

Next, I will define the notion of the _canonical form_ of a unit expression.
Intuitively, an expression's canonical form is an equivalent representation expressed purely as a product
of a numeric value with base units raised to non-zero powers.
For example, the canonical form of $$ meter / (second^2) $$ is $$ 1 \ meter^1 second^{-2} $$,
and the canonical form of $$ liter / second $$ is $$ (1/1000) \ meter^3 second^{-1} $$.

The canonical form of a unit expression $$ e \triangleq canonical(e) $$ is recursively defined, as follows.

$$
\begin{aligned}
canonical(\breve 1) & = 1 \times \breve 1 \\
\text{given } base(u) \text{, } canonical(u) & = 1 \times u ^ 1 \\
\text{given } derived(d, e, c) \text{, } canonical(d) & = c \times canonical(e) \\
canonical(u \times v) & = canonical(u) \times canonical(v) \\
canonical(u / v) &= canonical(u) / canonical(v) \\
canonical(u ^ p) &= (canonical(u))^p
\end{aligned}
$$

By convention, a canonical form of $$ c \times \breve 1 $$ represents the unitless state where all other
powers of unit atoms have canceled out to zero, and so for example
$$ canonical(meter / meter) = 1 \ \breve 1 $$, and $$ canonical(\breve 1 \times second) = 1 \ second^1 $$

We are now in a position to define some algorithmic unit analysis!
A fundamental question of unit analysis is whether two unit expressions are _convertable_,
and if so, what is the conversion factor between them.
Using the above definition of _canonical forms_, it is straightforward to capture this idea mathematically:

$$
\begin{aligned}
& \text{Unit expressions } u \text{ and } v \text{ are convertable if and only if } \\
& \frac{canonical(u)}{canonical(v)} = c \times \breve 1 \text{, and if so then: } \\
& 1 \ u = c \ v \ \ \text{ and } \ \ 1 \ v = u / c \\
\end{aligned}
$$

Consider this example: Is $$ foot / second / second $$ convertable to $$ meter / (second^2) $$ ?
Allowing that we've declared $$ base(meter) $$, $$ base(second) $$ and $$ derived(foot, meter, 0.3048) $$, then:

$$
\frac{canonical(foot / second / second)}{canonical(meter / second^2)}
= \frac{0.3048 \ meter^1 second^{-2}}{1 \ meter^1 second^{-2}} = 0.3048 \ \breve 1
$$

and so the answer is yes!
These unit expressions _are_ convertable, and 0.3048 is the coefficient of conversion.

Likewise, this algorithm can conclude when units are _not_ compatible:

$$
\frac{canonical(foot / second)}{canonical(meter / second^2)}
= \frac{0.3048 \ meter^1 second^{-1}}{1 \ meter^1 second^{-2}} = 0.3048 \ second \text{ (incompatible!)}
$$

This approach to the question of unit convertability is very amenable for use in computing.
The canonical form of a unit expression is easily representable in various data structures.
For example, the canonical form $$ 1 \ meter^1 second^{-2} $$ can be represented as the sequence
`[(meter, 1), (second, -2)]`.
It might also be represented as a mapping, such that `map[meter] -> 1` and `map[second] -> -2`.
The inductive definition of unit expressions is straightforward to implement in most modern
computing languages, as is the recursive definition of the _canonical_ function itself.

I have been experimenting with an implementation of these algorithmic definitions for defining
unit analysis as a [static typing system for Scala](https://github.com/erikerlandson/coulomb).
However, by defining these concepts mathematically, my hope is that it may make applying computational unit analysis
more amenable for any programming language that can support it.
