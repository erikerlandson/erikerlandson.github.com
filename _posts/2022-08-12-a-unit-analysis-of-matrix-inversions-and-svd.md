---
layout: post
title: A Unit Analysis of Matrix Inversions and SVD
date: 2022-08-12 08:31 -0700
tags: [ computing, unit analysis, linear algebra, matrix, vector, SVD, matrix inversion ]
---

In previous posts, I developed some basic laws for doing unit analysis with
[linear algebra](https://erikerlandson.github.io/blog/2020/05/01/unit-analysis-for-linear-algebra/),
and then applied that to
[linear regression](https://erikerlandson.github.io/blog/2020/05/06/unit-analysis-for-linear-regression/).

In this post I will develop unit analysis for
[Singular Value Decomposition](https://en.wikipedia.org/wiki/Singular_value_decomposition)
(SVD) and also some variations on
[matrix inversion](https://en.wikipedia.org/wiki/Invertible_matrix).

#### Unit factorization of a tabular matrix

In my
[previous post](https://erikerlandson.github.io/blog/2020/05/01/unit-analysis-for-linear-algebra/)
I developed the concept of a "unit signature" $$ \Upsilon $$ for matrixes and vectors.
In this post I will use an alternative representation of unit signatures that I will call the
"unit factorization" of a matrix or vector.
Given a
[tabular matrix](https://erikerlandson.github.io/blog/2020/05/01/unit-analysis-for-linear-algebra/#tabular-data-matrices)
$$ X $$, we can write $$ X $$ as a "unit factorization" of a unitless matrix
$$ \overset{1}{X} $$ and a signature matrix $$ \overset{\Upsilon}{X} $$:

$$
\text{Given a tabular matrix X where} \\
\text{ } \\
\begin{aligned}
\Upsilon X & =
\begin{bmatrix}
u_1 & u_2 & \dots & u_m \\
u_1 & u_2 & \dots & u_m \\
\vdots & & \ddots \\
u_1 & u_2 & \dots & u_m \\
\end{bmatrix}
\end{aligned}
\\
\text{ } \\
\text{The unit factorization of X is defined as} \\
\text{ } \\
\begin{aligned}
X & = \overset{1}{X} \overset{\Upsilon}{X} \quad \text{where:} \\
\end{aligned}
\\
\text{ } \\
\begin{aligned}
\overset{1}{X} & =
\begin{bmatrix}
x_{11} & x_{12} & \dots & x_{1m} \\
x_{21} & x_{22} & \dots & x_{2m} \\
\vdots & & \ddots \\
x_{n1} & x_{n2} & \dots & x_{nm} \\
\end{bmatrix}
\quad
\Upsilon \overset{1}{X} =
\begin{bmatrix}
\breve 1 & \breve 1 & \dots & \breve 1 \\
\breve 1 & \breve 1 & \dots & \breve 1 \\
\vdots & & \ddots \\
\breve 1 & \breve 1 & \dots & \breve 1 \\
\end{bmatrix}
\\
\text{} \\
\overset{\Upsilon}{X} & = diag(u_1, u_2 \dots u_m) = 
\begin{bmatrix}
u_1 & 0 & \dots & 0 \\
0 & u_2 & \dots & 0 \\
\vdots & & \ddots \\
0 & 0 & \dots & u_m \\
\end{bmatrix}

\end{aligned}
$$


Given a unit factorization $$ X = \overset{1}{X} \overset{\Upsilon}{X} $$,
the signature matrix $$ \overset{\Upsilon}{X} $$ is by definition diagonal,
and so the transpose $$ {\overset{\Upsilon}{X}}^T = \overset{\Upsilon}{X} $$.
It is also easy to see that inverse $$ {\overset{\Upsilon}{X}}^{-1} = diag(1/u_1 \dots 1/u_m) $$.

Unit factorizations make it relatively easy to describe the unit analysis of
various forms of matrix inverses, pseudo-inverses and SVD matrix factorizations.
In the following sections I will derive unit signatures for some interesting cases.

#### Inverse of a tabular square matrix

Consider a square $$ m \times m $$ tabular matrix $$ X $$ with unit factorization
$$ X = \overset{1}{X} \overset{\Upsilon}{X} $$.
Provided that inverse $$ {\overset{1}{X}}^{-1} $$ exists, then we may write:

$$
\text{Let} \quad {\overset{1}{X}}^{-1} \quad \text{exist and have elements} \quad
\begin{bmatrix}
z_{11} & z_{12} & \dots & z_{1m} \\
z_{21} & z_{22} & \dots & z_{2m} \\
\vdots & & \ddots \\
z_{m1} & z_{m2} & \dots & z_{mm} \\
\end{bmatrix}
\\
\text{} \\
\begin{aligned}
X^{-1} & = {\overset{\Upsilon}{X}}^{-1} {\overset{1}{X}}^{-1} \\
& =
\begin{bmatrix}
z_{11} {u_1}^{-1} & z_{12} {u_1}^{-1} & \dots & z_{1m} {u_1}^{-1} \\
z_{21} {u_2}^{-1} & z_{22} {u_2}^{-1} & \dots & z_{2m} {u_2}^{-1} \\
\vdots & & \ddots \\
z_{m1} {u_m}^{-1} & z_{m2} {u_m}^{-1} & \dots & z_{mm} {u_m}^{-1} \\
\end{bmatrix}
\end{aligned}
\\
\text{} \\
\text{and so the unit signature} \quad \Upsilon X^{-1} =
\begin{bmatrix}
{u_1}^{-1} & {u_1}^{-1} & \dots & {u_1}^{-1} \\
{u_2}^{-1} & {u_2}^{-1} & \dots & {u_2}^{-1} \\
\vdots & & \ddots \\
{u_m}^{-1} & {u_m}^{-1} & \dots & {u_m}^{-1} \\
\end{bmatrix}
$$

From the above derivation I will also note that in general when we multiply by a signature matrix
$$ \overset{\Upsilon}{X} $$
on the right, we obtain a standard tabular matrix with homogeneous column units,
and if we multiply on the left, we obtain a matrix with homogeneous row units:

$$
\begin{aligned}
\Upsilon \overset{1}{X} \overset{\Upsilon}{X} &=
\begin{bmatrix}
\vdots & \vdots & & \vdots \\
u_1 & u_2 & \dots & u_m \\
\vdots & \vdots & & \vdots \\
\end{bmatrix}
\\
\Upsilon \overset{\Upsilon}{X} \overset{1}{X} &=
\begin{bmatrix}
\dots & u_1 & \dots \\
\dots & u_2 & \dots \\
 & \vdots & \\
\dots & u_m & \dots \\
\end{bmatrix}
\\
\end{aligned}
$$

