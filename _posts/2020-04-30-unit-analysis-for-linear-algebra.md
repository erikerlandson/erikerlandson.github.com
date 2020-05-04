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

#### Basic Unit Signature Identities

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

#### Unit Signature of Vector Products

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
u_1 v_1 & \dots & u_1 v_n \\
\vdots & \ddots \\
u_n v_1 & \dots & u_n v_n \\
\end{bmatrix} \\
\end{aligned}
$$

#### Unit Signature of Matrix Products

The unit signature of a matrix is the matrix of the signatures of its elements.

$$
\large
\Upsilon
\begin{bmatrix}
x_{11} u_{11} & \dots & x_{1m} u_{1m} \\
\vdots & \ddots \\
x_{n1} u_{n1} & \dots & x_{nm} u_{nm} \\
\end{bmatrix}
= 
\begin{bmatrix}
u_{11} & \dots & u_{1m} \\
\vdots & \ddots \\
u_{n1} & \dots & u_{nm} \\
\end{bmatrix}
$$

It is relatively easy to define the unit signature of a matrix product, _if it exists_.
For a matrix $$ X $$ described by its row vectors,
and a matrix $$ Y $$ described by its column vectors,
$$ \Upsilon XY $$ can be defined as follows:

$$
\large
\begin{aligned}
\text{given } X &=
\begin{bmatrix}
r_1 \\
\vdots \\
r_n \\
\end{bmatrix}
\quad \text{ and } \quad Y =
\begin{bmatrix}
c_1 \dots c_m \\
\end{bmatrix} \\
\Upsilon XY &=
\begin{bmatrix}
\Upsilon r_1 \cdot c_1 & \dots & \Upsilon r_1 \cdot c_m \\
\vdots & \ddots \\
\Upsilon r_n \cdot c_1 & \dots & \Upsilon r_n \cdot c_m \\
\end{bmatrix} \\
\text{iff } & \Upsilon r_i \cdot c_j \neq \breve \emptyset \ \forall r_i,r_j
\end{aligned}
$$

This unit signature only exists when _every_ pairwise inner product in the result also has a defined unit signature.
If there exists any $$ i,j $$ where $$ \Upsilon r_i \cdot c_j = \breve \emptyset $$,
then $$ \Upsilon XY = \breve \emptyset $$ as well.
In the section above we saw that many pairs of vectors do not have a defined unit signature for their inner products.
As with the inner product, we cannot assume that the unit signature of a matrix product exists:
we have to show it for any pair of matrices we're interested in.

#### Tabular Data Matrices

In the previous section we saw that $$ \Upsilon XY $$ is not guaranteed to exist.
Can we characterize interesting sets of matrices whose product _does_ have a unit signature?

Consider a matrix that represents tabular data.
Matrices like this are widely used in computing.
In a tabular data matrix, each row represents a data vector, and each vector component may have its own unit.
The unit signature of a tabular data matrix looks like this:

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

Each matrix column represents one kind of data element with its own unit.
As we can see above, the column vectors of this matrix have homogeneous units:
the unit signature of the jth column looks like $$ [ u_j, u_j, \dots u_j] $$.

One very common matrix operation in data science is to take a tabular matrix
and multiply it by its transpose: $$ X^T X $$.
This product is given by the pairwise inner products of the column vectors of X.
But each column vector has homogeneous units,
and so we know that all of these inner products have a unit signature, and that
in turn gives us the product signature:

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

So tabular data matrices and their "self-products" of the form $$ X^T X $$
are one useful class of matrix product that has a well defined unit signature.

#### Generalized Tabular Product

We can generalize the unit signature of $$ X^T X $$ a little bit,
to get a unit signature for a left matrix with rows having homogeneous units and
a right matrix with columns having homogeneous units:

$$
\large
\begin{aligned}
\text{given } \Upsilon X^T &=
\begin{bmatrix}
  u_1 & \dots & u_1 \\
  \vdots & \ddots \\
  u_n & \dots & u_n \\
\end{bmatrix}
\quad \text{ and } \quad \Upsilon Y =
\begin{bmatrix}
  v_1 & \dots & v_m \\
  \vdots & \ddots \\
  v_1 & \dots & v_m \\
\end{bmatrix} \\
\Upsilon X^T Y &=
\begin{bmatrix}
  u_1 v_1 & \dots & u_1 v_m \\
  \vdots & \ddots \\
  u_n v_1 & \dots & u_n v_m \\
\end{bmatrix}
\end{aligned}
$$

The matrices X and Y above are tabular matrices, as in the previous section,
each having the same number of rows, but X has been transposed, and has
different units in its columns than Y.
For lack of a better term, I'll refer to this kind of product as a "generalized tabular product."
The product $$ X^T X $$ from the previous section just a special case of the tabular product.

#### Unit Signature of Matrix Determinant

As we have seen with other vector and matrix operations,
the unit sigature of a matrix determinant isn't guaranteed to exist.
For example, the determinant of the following matrix has no unit signature:

$$
\begin{aligned}
\Upsilon \det
\begin{bmatrix}
a\ meter & b\ kilogram \\
c\ second & d\ mole \\
\end{bmatrix}
= \Upsilon (a\ meter\ d\ mole - b\ kilogram\ c\ second)
= \breve \emptyset
\end{aligned}
$$

However, there are concrete things we can say about when a matrix determinant does exist,
and some consequences.

Recall the
[Laplace formula](https://en.wikipedia.org/wiki/Minor_(linear_algebra)#Cofactor_expansion_of_the_determinant)
(aka the minors / cofactors rule) for a matrix determinant.
We can expand this formula along any row or column.
Here is the formula for $$ \det X $$ expanded about some row i:

$$
\begin{aligned}
\det X &= x_{i1} C_{i1} + \dots + x_{in} C_{in} \\
       &= x_{i1} (-1)^{i+1} M_{i1} + \dots + x_{in} (-1)^{i+n} M_{in}
\end{aligned}
$$

$$ M_{i,j} $$ is the "minor of X" about row i and column j:
the determinant of the $$ (n-1)\times(n-1) $$ matrix resulting from removing the ith row and jth column
from X.

We can apply the laws of unit signatures to the formula for $$ \det X $$,
and conclude the following useful and possibly surprising facts about $$ \Upsilon \det X $$:

$$
\begin{aligned}
& \text{If } \ \Upsilon \det X \ \text{ exists, then by definition:} \\
& \text{For any row i of X: } \ 
  \Upsilon \det X = \Upsilon (x_{i1} (-1)^{i+1} M_{i1} + \dots + x_{in} (-1)^{i+n} M_{in}) \\
& \text{and therefore the following must all hold:} \\
& \text{(1)} \quad
  \forall i,j \quad \Upsilon M_{ij} \neq \breve \emptyset \\
& \text{(2)} \quad
  \forall i \quad
  \Upsilon \det X \ = \ u_{i1} \Upsilon M_{i1} \ = \ \dots \ = \ u_{in} \Upsilon M_{in} \\
& \text{(3)} \quad
  \forall i,j \quad \Upsilon M_{ij} = \frac{\Upsilon \det X}{u_{ij}}
\end{aligned}
$$

We know that (1) must be true since it is a necessary condition for the signature to be defined.
The equalities in (2) are a consequence of the law for the sum of signatures,
and (3) is simply solving each equation from (2) for $$ \Upsilon M_{ij} \ \ \square $$

One immediate consequence of the equations in (3) is that whenever $$ \Upsilon \det X $$ exists,
we can apply them to get all of the elements of the adjoint $$ \Upsilon \text{adj}X $$.

Another important consequence of the relations above is that we can use them to prove the following
formula:

$$
\begin{aligned}
& \text{If } \ \Upsilon \det X \ \text{ exists, then it is the product of the diagonal units of } \Upsilon X:\\
& \Upsilon \det X = u_{11} u_{22} ... u_{nn} \\
\end{aligned}
$$

We can prove this by induction.
The 1x1 basis case is simply:

$$
\Upsilon \det [x_{11} u_{11}] = \Upsilon x_{11} u_{11} = u_{11}
$$

Now consider an $$ n \times n $$ matrix X, where we know $$ \Upsilon \det X $$ exists.
From equation (2) above, we know we may write:

$$
\begin{aligned}
\Upsilon \det X &= u_{nn} \Upsilon M_{nn} \text{ (eqn (2) about n,n)} \\
                &= u_{nn} (u_{11} u_{22} \dots u_{n-1 n-1}) \text{ (defn of minor & inductive step) } \\
                &= u_{11} u_{22} \dots u_{nn} \ \ \square \\
\end{aligned}
$$

#### The Determinant of a Tabular Product

The results from the previous section mostly assume that $$ \Upsilon \det X $$ exists.
We've seen that this unit signature is not guaranteed to exist.
Are there any interesting classes of matrix whose determinant has a unit signature?

Recall the [tabular product](#generalized-tabular-product) from earlier.
We are interested in square matrices of this form, as square matrices have determinants.
Such a matrix has a unit signature that looks like:

$$
\large
\Upsilon X^T Y =
\begin{bmatrix}
  u_1 v_1 & \dots & u_1 v_n \\
  \vdots & \ddots \\
  u_n v_1 & \dots & u_n v_n \\
\end{bmatrix}
$$

Its unit signature can also be written as the outer product
$$ [u_1 \dots u_n] \times [v_1 \dots v_n] $$.

We wish to show that $$ \Upsilon \det X^T Y $$ exists,
and therefore that

$$
\large
\begin{aligned}
\Upsilon \det X^T Y &= u_1 v_1 \ u_2 v_2 \dots u_n v_n \\
                    &= u_1 u_2 \dots u_n \ v_1 v_2 \dots v_n \\
\end{aligned}
$$

We can prove this by induction.
The basis 1x1 basis case is

$$
\large
\Upsilon \det [x_{11} u_{11} y_{11} v_{11}]
= \Upsilon x_{11} y_{11} u_{11} v_{11}
= u_{11} v_{11}
$$

Now consider the case of an $$ n \times n $$ matrix, and any one of its minors $$ M_{ij} $$.
By the definition of a minor, its corresponding matrix is $$ X^T Y $$ with the ith row and jth column removed.
Considering this, we can see that its unit signature looks like the outer product

$$
[u_1 \dots u_{i-1}, u_{i+1} \dots u_n ] \times [v_1 \dots v_{j-1}, v_{j+1} \dots v_n ]
$$

However, this is equivalent, up to variable renaming, with

$$
[u_1 \dots u_{n-1} ] \times [v_1 \dots v_{n-1} ]
$$

and so by induction we know that $$ \Upsilon M_{i,j} $$ exists,
and furthermore from our earlier theorem we know its value:

$$
\large
\begin{aligned}
\Upsilon M_{i,j}
&= u_1 u_2 \dots u_{i-1} u_{i+1} \dots u_n \ v_1 v_2 \dots v_{j-1} v_{j+1} \dots v_n \\
&= \frac{u_1 \dots u_n \ v_1 \dots v_n}{u_i v_j} \\
\end{aligned}
$$

We have now shown that $$ \Upsilon M_{i,j} $$ exists for all $$ i,j $$ and satisfies
equations (2) from our theorem in the previous section.
Therefore,

$$
\large
\begin{aligned}
& \Upsilon \det X^T Y = u_1 v_1 \ u_2 v_2 \dots u_n v_n \quad \text{and} \\
& \forall i,j \quad \Upsilon M_{i,j} = \frac{\Upsilon \det X^T Y}{u_i v_j} \quad \square \\
\end{aligned}
$$

#### Unit Signature of a Tabular Inverse $$ (X^T Y)^{-1} $$

Equipped with the forms of $$ \Upsilon \det X^T Y $$ and $$ \Upsilon M_{i,j} $$,
we are in a position to formulate the unit signature of the inverse.

Recall that the inverse of a matrix A is given by:

$$
\large
A^{-1}_{ij} = \frac{(-1)^{i+j}M_{ji}}{\det A}
$$

Applying our formulas for unit signatures gives us:

$$
\large
\begin{aligned}
\Upsilon (X^T Y)^{-1}
&= \left[ \frac{\Upsilon M_{ji}}{\Upsilon \det X^T Y} \right] \quad \forall i,j \\
&= \left[ \frac{\left( \frac{\Upsilon \det X^T Y}{u_j v_i} \right) }{\Upsilon \det X^T Y} \right] \quad \forall i,j \\
&= \left[ u_j^{-1} v_i^{-1} \right]  \quad \forall i,j
\end{aligned}
$$

We can write this out in expanded form:

$$
\large
\Upsilon (X^T Y)^{-1}
=
\begin{bmatrix}
  u_1^{-1}v_1^{-1} & u_2^{-1} v_1^{-1} & \dots  & u_n^{-1} v_1^{-1} \\
  u_1^{-1}v_2^{-1} & u_2^{-1} v_2^{-1} & \dots  & u_n^{-1} v_2^{-1} \\
  \vdots           &                   & \ddots & \\
  u_1^{-1}v_n^{-1} & u_2^{-1} v_n^{-1} & \dots  & u_n^{-1} v_n^{-1} \\  
\end{bmatrix}
$$

#### Conclusions

In this post I've attempted to build up some rigorous principles for applying unit analysis
to matrix and vector operations.
By deriving laws that cover the unit signatures of vector products, matrix products and matrix inversion,
I hope that this can serve as a foundation for applying unit analysis to real world numeric computing.
