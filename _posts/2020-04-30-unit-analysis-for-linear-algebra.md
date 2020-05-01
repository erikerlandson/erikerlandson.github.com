---
layout: post
title: Unit Analysis for Linear Algebra
date: 2020-04-30 17:27 -0700
tags: [ computing, unit analysis, linear algebra, matrix, vector ]
---

#### The Unit Signature Operator $$ \Upsilon $$

The goal of this post is to introduce a kind of calculus for doing unit analysis on linear algebra.
That is, unit analysis for expressions involving vector and matrix operations.

To try and make these ideas rigorous, I need to define a couple of concepts.
The first is the concept of a "unit signature."
Intuitively, a unit signature is what you have left if you discard everything except your unit factors.
For example, the unit signature of the expression $$ (a x + b)meter $$ is just $$ meter $$.
The unit signature of $$ (x\ meter) / (y^2\ second) $$ is $$ meter / second $$.

To work with unit signatures mathematically,
I will define an operator $$ \Upsilon $$ that takes any expression and yields its unit signature.
The examples above can be written using $$ \Upsilon $$:

$$
\large
\begin{aligned}
\Upsilon (a x + b)meter &= meter \\
\Upsilon \frac{x\ meter}{y^2\ second} &= \frac{meter}{second} \\
\end{aligned}
$$

In the following sections, I will develop properties of the $$ \Upsilon $$ operator and use them
to derive formulas for the unit signatures of basic vector and matrix operations.

#### Basic Unit Analysis Identities

A word on notation.
To help make it clear when I'm talking about units,
versus when I'm talking about other parts of an expression,
I will be using the symbols such as $$ u, v $$ to signify units.
Other non-unit expressions will be represented by symbols such as $$ x, y $$ or $$ a, b $$. 

Before getting into linear algebra proper, we need to start with some basic identities.
The following table defines the unit signature $$ \Upsilon $$ for simple terms and operations,
along with examples:

$$
\large
\begin{aligned}
           \Upsilon xu &= u    &&  \text{unit of a term}  &  \Upsilon x\ meter &= meter \\
    \Upsilon (xu + yu) &= u    &&  \text{sum of terms}    &  \Upsilon (x\ second + y\ second) &= second \\
    \Upsilon (xu \ yv) &= uv   &&  \text{unit product}    &  \Upsilon (x\ meter \ y\ meter) &= meter^2 \\
\Upsilon \frac{xu}{yv} &= u/v  &&  \text{unit ratio}      &  \Upsilon \frac{x\ meter}{y\ second} &= meter/second \\
       \Upsilon (xu)^p &= u^p  &&  \text{unit power}      &  \Upsilon (x\ meter)^3 &= meter^3 \\
\end{aligned}
$$

The key property of $$ \Upsilon $$ is that it discards everything from a term except the unit signature.

It is worth paying special attention to the identity $$ \Upsilon (xu + yu) = u $$.
The unit signature of a sum of terms is _only_ defined if each term has the same signature.
Furthermore, the signature of such a sum, if defined, collapses the terms:

$$
\large
\begin{aligned}
  & \Upsilon (x_1 u + x_2 u + \dots + x_n u) \\
= & \Upsilon x_1 u = \Upsilon x_2 u = \dots = \Upsilon x_n u \\
= & u
\end{aligned}
$$

Now is a good time to introduce a special unit signature symbol.
As discussed above, the unit signature of a sum of terms is not always defined.
If the terms in the sum do not all share the same unit signature, then the
signature of the sum _does not exist._
The symbol $$ \breve \emptyset $$ represents this condition.
The following example illustrates its use on a sum with mismatched units:

$$
\large
\Upsilon (x\ meter + y\ second) = \breve \emptyset \quad \text{no unit signature exists} \\
$$

The symbol $$ \breve 1 $$ represents a "unitless signature" - for example, when units cancel:

$$
\large
\Upsilon \frac{x\ meter}{ y\ meter} = \breve 1 \quad \text{unitless ratio} \\
$$

A final basic law before moving on to linear algebra signatures.
If two expressions are equal, then their unit signatures are also equal:

$$
\large
xu = yv \implies \Upsilon xu = \Upsilon yv \implies u = v
$$

This law is useful for proving some theorems about unit signatures.
Notice that the converse is definitely not true -
two expressions can have the same units, but otherwise be completely different!

#### Unit Analysis of Vector Products

The unit signature of a vector is just the vector of the signatures of its components:

$$
\large
\Upsilon [ x_1 u_1, x_2 u_2, \dots , x_n u_n ] = [ u_1, u_2, \dots , u_n ]
$$

What about the unit signature of an inner product?
As we saw above, not all sums have a defined unit signature.
The signature of the following inner product doesn't exist:

$$
\large
\begin{aligned}
& \Upsilon([x\ meter, y\ second] \cdot [z\ meter, w\ second]) \\
= & \Upsilon(x z\ meter^2 + y w\ second^2) \\
= & \breve \emptyset \\
\end{aligned}
$$

However, we can define conditions that describe when the inner product _does_ exist.
When the unit signatures of each individual element product are all the same,
then we can add them up to get a defined inner product signature:

$$
\large
\begin{aligned}
\text{given } \Upsilon x & = [u_1, u_2, \dots , u_n] \\
\text{ and } \Upsilon y & = [\frac{v}{u_1}, \frac{v}{u_2}, \dots , \frac{v}{u_n}] \text{, then:} \\
\Upsilon x \cdot y & = v \\
\end{aligned}
$$

A useful special case of the above is the inner product of two vectors each having the same signature
in all of their elements, again yielding a well defined inner product:

$$
\large
\begin{aligned}
\text{given } \Upsilon x & = [u, u, \dots , u] \\
\text{ and } \Upsilon y & = [v, v, \dots , v] \text{, then:} \\
\Upsilon x \cdot y & = uv \\
\end{aligned}
$$

The outer product of two vectors always has a well defined signature,
since no sums of terms are involved.

$$
\large
\begin{aligned}
\text{given } \Upsilon x & = [u_1, u_2, \dots , u_n] \\
\text{ and }  \Upsilon y & = [v_1, v_2, \dots , v_n] \text{, then:} \\
\Upsilon(x \times y)     & = 
\begin{bmatrix}
u_1 v_1 & u_1 v_2 & \dots & u_1 v_n \\
u_2 v_1 & u_2 v_2 & \dots & u_2 v_n \\
\vdots & & \ddots \\
u_n v_1 & u_n v_2 & \dots & u_n v_n \\
\end{bmatrix} \\
\end{aligned}
$$


#### Unit Analysis of Matrix Product

to-do

#### Tabular Data Matrices

Consider tabular data.
Each column has a unit type.

$$
\large
\Upsilon X = 
\begin{bmatrix}
u_1 & u_2 & \dots & u_m \\
u_1 & u_2 & \dots & u_m \\
\vdots & & \ddots \\
u_1 & u_2 & \dots & u_m \\
\end{bmatrix}
$$

$$
\large
\Upsilon X^TX =
\begin{bmatrix}
u_1 ^ 2 & u_1 u_2 & \dots & u_1 u_m \\
u_1 u_2 & u_2 ^ 2 & \dots & u_2 u_m \\
\vdots & & \ddots \\
u_1 u_m & u_2 u_m  & \dots & u_m ^ 2 \\
\end{bmatrix}
$$

#### Unit Analysis of Matrix Inverse

to-do

#### Unit Analysis of $$ (X^T X)^{-1} $$

to-do
