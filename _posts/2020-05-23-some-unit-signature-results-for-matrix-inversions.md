---
layout: post
title: Some Unit Signature Results for Matrix Inversions
date: 2020-05-23 13:11 -0700
tags: [ computing, unit analysis, linear algebra, matrix, vector ]
---

I recently began developing some laws for
[unit analysis with linear algebra](http://erikerlandson.github.io/blog/2020/05/01/unit-analysis-for-linear-algebra/),
and used them to construct a
[unit analysis for linear regression](http://erikerlandson.github.io/blog/2020/05/06/unit-analysis-for-linear-regression/)
as an initial demonstration that they can be applied to a real world algorithm.

I've been working to build on these results, and along the way I've happened on some additional
unit signature relations having to do with matrix inversions.
The purpose of this post is to present those for future reference.

#### A Tabular Product Multiplied By Its Inverse

Recall the
[tabular product](http://erikerlandson.github.io/blog/2020/05/01/unit-analysis-for-linear-algebra/#generalized-tabular-product)
$$ X^T Y $$.
If it is square, then the unit signature of this product and its inverse are:

$$
\large
\begin{aligned}
\text{given } \quad \Upsilon X^T &=
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
  u_1 v_1 & u_1 v_2 & \dots & u_1 v_n \\
  u_2 v_1 & u_2 v_2 & \dots & u_2 v_n \\
  \vdots & & \ddots \\
  u_n v_1 & u_n v_2 & \dots & u_n v_n \\
\end{bmatrix} \\
\Upsilon (X^T Y)^{-1} &=
\begin{bmatrix}
  (u_1 v_1)^{-1} & (u_2 v_1)^{-1} & \dots  & (u_n v_1)^{-1} \\
  (u_1 v_2)^{-1} & (u_2 v_2)^{-1} & \dots  & (u_n v_2)^{-1} \\
  \vdots         &                & \ddots & \\
  (u_1 v_n)^{-1} & (u_2 v_n)^{-1} & \dots  & (u_n v_n)^{-1} \\  
\end{bmatrix}
\end{aligned}
$$

Clearly,
$$ (X^T Y)(X^T Y)^{-1} = (X^T Y)^{-1}(X^T Y) = I_n $$,
but what does the unit signature of $$ I_n $$ look like?

Something interesting happens when we multiply out the unit signatures resulting from
right and left multiplication by the inverse:

$$
\large
\begin{aligned}
\Upsilon (X^T Y)(X^T Y)^{-1} &=
\begin{bmatrix}
  u_1 / u_1 & u_1 / u_2 & \dots & u_1 / u_n \\
  u_2 / u_1 & u_2 / u_2 & \dots & u_2 / u_n \\
  \vdots & & \ddots \\
  u_n / u_1 & u_n / u_2 & \dots & u_n / u_n \\
\end{bmatrix} \\
\Upsilon (X^T Y)^{-1}(X^T Y) &=
\begin{bmatrix}
  v_1 / v_1 & v_2 / v_1 & \dots & v_n / v_1 \\
  v_1 / v_2 & v_2 / v_2 & \dots & v_n / v_2 \\
  \vdots & & \ddots \\
  v_1 / v_n & v_2 / v_n & \dots & v_n / v_n \\
\end{bmatrix}
\end{aligned}
$$

Some interesting things are evident in these unit signatures.
Only the units from the columns of $$ X $$ are present in the first product,
and similarly only units from $$ Y $$ appear in the second.
So, while in traditional matrix algebra these products are both equal (to $$ I_n $$)
their unit signatures are completely different!
In the realm of unit analysis, $$ I_n $$ may have differing unit signatures!

The signatures along the diagonals of both products are equivalent to $$ \breve 1 $$:
their diagonals are unitless.
This is intuitively pleasing, since these are signatures for identity matrices.

However, the signatures off the diagonals are clearly _not_ unitless.
Numerically, these elements are all zero, since these represent some identity matrix.
Yet in general $$ I_n $$ has a defined and non-unitless signature!

#### Products with Tabular Identity Matrices

The identity matrix products above have the appealing property that they preserve vector signatures of the form
$$ [ u_1, u_2, \dots u_n ] $$ and $$ [v_1, v_2, \dots v_n ] $$.

$$
\large
\begin{aligned}
\text{given} \quad
\Upsilon q^T = [ u_1, u_2 \dots u_n ] &
\quad \text{and} \quad
\Upsilon r^T = [ v_1, v_2 \dots v_n ] \\
\Upsilon \left( (X^T Y)(X^T Y)^{-1} \ q \right) & =
\begin{bmatrix}
u_1 \\
u_2 \\
\vdots \\
u_n \\
\end{bmatrix} \\
\Upsilon \left( r^T \ (X^T Y)^{-1}(X^T Y) \right) & =
[v_1, v_2 \dots v_n ] \\
\end{aligned}
$$

Furthermore, due to the tabular data signatures of matrices $$ X $$ and $$ Y $$,
we can also conclude:

$$
\large
\begin{aligned}
\Upsilon \left( (X^T Y)(X^T Y)^{-1} \ X^T \right) & = \Upsilon X^T \\
\Upsilon \left( Y \ (X^T Y)^{-1}(X^T Y) \right) & = \Upsilon Y \\
\end{aligned}
$$

#### Products with a Tabular Inverse

The laws for unit signatures of matrix products also imply:

$$
\large
\begin{aligned}
\text{given} \quad
\Upsilon q^T = [ u_1, u_2 \dots u_n ] &
\quad \text{and} \quad
\Upsilon r^T = [ v_1, v_2 \dots v_n ] \\
\Upsilon \left( (X^T Y)^{-1} \ q \right) & =
\begin{bmatrix}
v_1^{-1} \\
v_2^{-1} \\
\vdots \\
v_n^{-1} \\
\end{bmatrix} \\
\Upsilon \left( r^T \ (X^T Y)^{-1} \right) & =
[u_1^{-1}, u_2^{-1} \dots u_n^{-1} ] \\
\end{aligned}
$$

And similarly:

$$
\large
\begin{aligned}
\Upsilon \left( (X^T Y)^{-1} \ X^T \right) & =
\begin{bmatrix}
v_1^{-1} & v_1^{-1} & \dots & v_1^{-1} \\
v_2^{-1} & v_2^{-1} & \dots & v_2^{-1} \\
\vdots & \\
v_n^{-1} & v_n^{-1} & \dots & v_n^{-1} \\
\end{bmatrix} \\
\Upsilon \left( Y \ (X^T Y)^{-1} \right) & = 
\begin{bmatrix}
  u_1^{-1} & u_2^{-1} & \dots & u_n^{-1} \\
  u_1^{-1} & u_2^{-1} & \dots & u_n^{-1} \\
  \vdots & \\
  u_1^{-1} & u_2^{-1} & \dots & u_n^{-1} \\
\end{bmatrix}
\end{aligned}
$$

#### Quadratic Forms

From the above, we see that the matrix quadratic form
$$ r^T (X^T Y)^{-1} q $$ has unit signature

$$
\large
\begin{aligned}
\Upsilon \left( r^T (X^T Y)^{-1} q \right)
\quad = \quad
[u_1^{-1}, u_2^{-1} \dots u_n^{-1} ]
\begin{bmatrix}
u_1 \\
u_2 \\
\vdots \\
u_n \\
\end{bmatrix}
\quad = \quad
\breve 1
\end{aligned}
$$

And so this standard quadratic form is unitless.

#### Tabular Self Products

All of the above unit signature results can be specialized for the tabular self product
$$ X^T X $$,
by substituting $$ v_1 \rightarrow u_1 $$, $$ v_2 \rightarrow u_2 $$, etc.
For example the product of a tabular self product and its inverse has the following signature:

$$
\large
\begin{aligned}
\Upsilon (X^T X)(X^T X)^{-1} &=
\begin{bmatrix}
  u_1 / u_1 & u_1 / u_2 & \dots & u_1 / u_n \\
  u_2 / u_1 & u_2 / u_2 & \dots & u_2 / u_n \\
  \vdots & & \ddots \\
  u_n / u_1 & u_n / u_2 & \dots & u_n / u_n \\
\end{bmatrix} \\
\Upsilon (X^T X)^{-1}(X^T X) &=
\begin{bmatrix}
  u_1 / u_1 & u_2 / u_1 & \dots & u_n / u_1 \\
  u_1 / u_2 & u_2 / u_2 & \dots & u_n / u_2 \\
  \vdots & & \ddots \\
  u_1 / u_n & u_2 / u_n & \dots & u_n / u_n \\
\end{bmatrix}
\end{aligned}
$$

And so in the special case of self product $$ X^T X $$, the left and right inverse products above
are transposes of each other.

Specializing the other results in this post for $$ X^T X $$ is similar.
