---
layout: post
title: A Unit Analysis of Eigenvectors, Matrix Diagonalization and PCA
tags:
- computing
- unit analysis
- linear algebra
- matrix
- vector
---
In this post I will develop a
[unit analysis](https://en.wikipedia.org/wiki/Dimensional_analysis)
for
[matrix diagonalization](https://en.wikipedia.org/wiki/Diagonalizable_matrix),
which is intimately connected with
[eigenvectors](https://en.wikipedia.org/wiki/Eigenvalues_and_eigenvectors)
and
[Principal Component Analysis](https://en.wikipedia.org/wiki/Principal_component_analysis)
(PCA).
I'll be building on results from some previous posts:

- [Unit Analysis for Linear Algebra](http://erikerlandson.github.io/blog/2020/05/01/unit-analysis-for-linear-algebra/)
- [A Unit Analysis of Linear Regression](http://erikerlandson.github.io/blog/2020/05/06/unit-analysis-for-linear-regression/)
- [Some Unit Signature Results for Matrix Inversions](http://erikerlandson.github.io/blog/2020/05/23/some-unit-signature-results-for-matrix-inversions/)

In general, a square matrix $$ A $$ is
[diagonalizable](https://en.wikipedia.org/wiki/Diagonalizable_matrix)
when we can find an invertable matrix
$$ P $$ and diagonal matrix $$ D $$ where $$ A = P D P^{-1} $$.

In this post I am going to focus on a particular form of diagonalizable matrix: $$ (X^T X) $$,
where $$ X $$ is a
[tabular matrix](http://erikerlandson.github.io/blog/2020/05/01/unit-analysis-for-linear-algebra/#tabular-data-matrices).
$$ X^T X $$ is real and symmetric, and so it can be diagonalized as $$ Q^T D Q $$,
where $$ Q $$ is an orthogonal matrix satisfying $$ Q^T = Q^{-1} $$.

We are interested in discovering the unit signatures for $$ Q $$ and $$ D $$.
In particular, we want to find signatures that satisfy
$$ \Upsilon X^T X = \Upsilon Q^T D Q $$.

Consider the product signatures
$$ \Upsilon (X^T X)(X^T X)^{-1} $$ and $$ \Upsilon (X^T X)^{-1}(X^T X) $$.
From the
[previous post](http://erikerlandson.github.io/blog/2020/05/23/some-unit-signature-results-for-matrix-inversions/#tabular-self-products)
we have:

$$
\large
\begin{aligned}
\Upsilon (X^T X)(X^T X)^{-1}
& =
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

These signatures are transposes of each other and so they are candidates for
$$ \Upsilon Q $$ and $$ \Upsilon Q^T $$.
Suppose we assign $$ \Upsilon Q = \Upsilon (X^T X)^{-1}(X^T X) $$
and $$ \Upsilon D = \Upsilon X^T X $$.
Then we would have the following:

$$
\begin{aligned}
\Upsilon Q^T D Q
& =
\begin{bmatrix}
  u_1 / u_1 & u_1 / u_2 & \dots & u_1 / u_n \\
  u_2 / u_1 & u_2 / u_2 & \dots & u_2 / u_n \\
  \vdots & & \ddots \\
  u_n / u_1 & u_n / u_2 & \dots & u_n / u_n \\
\end{bmatrix}
\begin{bmatrix}
u_1 u_1 & u_1 u_2 & \dots & u_1 u_n \\
u_2 u_1 & u_2 u_2 & \dots & u_2 u_n \\
\vdots & & \ddots \\
u_n u_1 & u_n u_2  & \dots & u_n u_n \\
\end{bmatrix}
\begin{bmatrix}
  u_1 / u_1 & u_2 / u_1 & \dots & u_n / u_1 \\
  u_1 / u_2 & u_2 / u_2 & \dots & u_n / u_2 \\
  \vdots & & \ddots \\
  u_1 / u_n & u_2 / u_n & \dots & u_n / u_n \\
\end{bmatrix}
\\
& =
\begin{bmatrix}
u_1 u_1 & u_1 u_2 & \dots & u_1 u_n \\
u_2 u_1 & u_2 u_2 & \dots & u_2 u_n \\
\vdots & & \ddots \\
u_n u_1 & u_n u_2  & \dots & u_n u_n \\
\end{bmatrix}
\begin{bmatrix}
  u_1 / u_1 & u_2 / u_1 & \dots & u_n / u_1 \\
  u_1 / u_2 & u_2 / u_2 & \dots & u_n / u_2 \\
  \vdots & & \ddots \\
  u_1 / u_n & u_2 / u_n & \dots & u_n / u_n \\
\end{bmatrix}
\\
& =
\begin{bmatrix}
u_1 u_1 & u_1 u_2 & \dots & u_1 u_n \\
u_2 u_1 & u_2 u_2 & \dots & u_2 u_n \\
\vdots & & \ddots \\
u_n u_1 & u_n u_2  & \dots & u_n u_n \\
\end{bmatrix}
\\
& =
\Upsilon X^T X
\end{aligned}
$$

There are some interesting things going on here.

Firstly, we see that these unit signatures for $$ Q $$ and $$ D $$ "work."
That is, they satisfy the
[laws](http://erikerlandson.github.io/blog/2020/05/01/unit-analysis-for-linear-algebra/#unit-signature-of-matrix-products)
of unit signatures for matrix algebra,
and they also satisfy our desired diagonalization relation
$$ \Upsilon Q^T D Q = \Upsilon X^T X $$.

It gets better.
The columns of $$ Q $$ are _also_ eigenvectors for $$ X^T X $$,
and so we now have unit signatures for eigenvectors of $$ X^T X $$!

Some implications of these signatures might seem a bit surprising.
Recall that we took
$$ \Upsilon Q $$ to be $$ \Upsilon (X^T X)^{-1}(X^T X) $$.
This is the signature of an identity matrix,
but Q is a matrix containing eigenvectors in its columns,
and while $$ Q $$ _might_ be diagonal it definitely will not be in general.
Therefore, Q is a matrix sharing its unit signature with an identity matrix,
but which in general has non-zero coefficients off its diagonal!

Furthermore, we took the signature $$ \Upsilon D $$ to be $$ \Upsilon X^T X $$.
Now, $$ D $$ _is_ diagonal, by definition, and so we have the curious
situation of a diagonal matrix $$ D $$ sharing its signature with a non-diagonal matrix,
and non-diagonal matrix $$ Q $$ sharing its signature with diagonal matrices!

These results seem a bit more intuitive if we recall
that one way to visualize diagonalization is to start with
$$ I (X^T X) I $$ and "rotate" it into $$ Q^T D Q $$.
This perspective makes it more clear why $$ Q $$ and $$ D $$ share their signatures with
$$ I $$ and $$ X^T X $$.

The unit analysis of the eigenvectors embedded in $$ Q $$ also checks out.
We saw
[previously](http://erikerlandson.github.io/blog/2020/05/23/some-unit-signature-results-for-matrix-inversions/#products-with-tabular-identity-matrices)
that the signature $$ \Upsilon (X^T X)^{-1}(X^T X) $$ preserves the rows of $$ X $$:

$$
\large
\begin{aligned}
\Upsilon \left( X \ (X^T X)^{-1}(X^T X) \right) & = \Upsilon X \\
\text{or:} \quad
\Upsilon X Q & = \Upsilon X \\
\end{aligned}
$$

This relation is important, since eigenvectors project into 
