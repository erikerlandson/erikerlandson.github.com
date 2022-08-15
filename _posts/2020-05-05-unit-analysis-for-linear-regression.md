---
layout: post
title: A Unit Analysis of Linear Regression
date: 2020-05-05 17:41 -0700
tags: [ computing, unit analysis, linear algebra, matrix, vector, linear regression, machine learning ]
---

In my
[previous post](http://erikerlandson.github.io/blog/2020/05/01/unit-analysis-for-linear-algebra/)
I developed some basic laws for doing
[unit analysis](https://en.wikipedia.org/wiki/Dimensional_analysis)
with linear algebra.
My goal has been to build up a capability for applying proper unit analysis to numeric computing,
in particular machine learning and data science.

The key test of success for a unit analysis of linear algebra is whether it can be applied to real methods in data science.
As an initial demonstration, in this post I will use the ideas from my previous post to do a unit analysis of
one of the oldest methods in data science - Linear Regression.

To review, the linear regression model predicts some dependent scalar variable $$ y $$ from a vector of independent variables
$$ x = [ x_1 \dots x_m ] $$.
The parameters of the model are a vector $$ \beta = [ b_1 \dots b_m ] $$ such that the model estimates
$$ \hat y = \beta \cdot x $$.

There are many variations on the algorithms for fitting parameters $$ \beta $$ to training data.
In this post I'll be working with the classic
[least squares estimation](https://en.wikipedia.org/wiki/Linear_regression#Least-squares_estimation_and_related_techniques),
which is given by the matrix formula:

$$
\large
\hat \beta = \left( X^T X \right) ^ {-1} X^T Y
$$

Recall that in this formula, $$ X $$ is a table of $$ n $$ data samples,
and $$ Y $$ is a column of corresponding dependent value measurements:

$$
\large
X =
\begin{bmatrix}
x_{11} & x_{12} & \dots & x_{1m} \\
x_{21} & x_{22} & \dots & x_{2m} \\
\vdots & & \ddots \\
x_{n1} & x_{n2} & \dots & x_{nm} \\
\end{bmatrix}
\quad \quad
Y =
\begin{bmatrix}
y_1 \\
y_2 \\
\vdots \\
y_n \\
\end{bmatrix}
$$

Consider the structure of $$ X $$ and $$ Y $$.
Each of its columns holds $$ n $$ samples of the values of one kind of measurement, or feature.
All the values in this column, therefore, can be described as having some particular
[unit](https://en.wikipedia.org/wiki/Unit_of_measurement).
The same is true of our dependent values in $$ Y $$.
For example, if we were trying to learn a crude model for predicting a person's
weight from their height and age, our data might look like so:

$$
\large
X =
\begin{bmatrix}
190\ cm & 21\ yr \\
175\ cm & 35\ yr \\
\vdots \\
200\ cm & 51\ yr \\
\end{bmatrix}
\quad \quad
Y =
\begin{bmatrix}
80\ kg \\
55\ kg \\
\vdots \\
91\ kg \\
\end{bmatrix}
$$

If we apply the concept of a
[unit signature](http://erikerlandson.github.io/blog/2020/05/01/unit-analysis-for-linear-algebra/#the-unit-signature-operator-upsilon)
to the example above, then we have:

$$
\large
\Upsilon X =
\begin{bmatrix}
cm &  yr \\
cm &  yr \\
\vdots \\
cm &  yr \\
\end{bmatrix}
\quad \quad
\Upsilon Y =
\begin{bmatrix}
kg \\
kg \\
\vdots \\
kg \\
\end{bmatrix}
$$

Both $$ X $$ and $$ Y $$ are examples of
[tabular matrices](http://erikerlandson.github.io/blog/2020/05/01/unit-analysis-for-linear-algebra/#tabular-data-matrices).
In other words, their unit signatures are of the general form:

$$
\large
\Upsilon X =
\begin{bmatrix}
u_{1} & u_{2} & \dots & u_{m} \\
u_{1} & u_{2} & \dots & u_{m} \\
\vdots & & \ddots \\
u_{1} & u_{2} & \dots & u_{m} \\
\end{bmatrix}
\quad \quad
\Upsilon Y =
\begin{bmatrix}
v \\
v \\
\vdots \\
v \\
\end{bmatrix}
$$

In my previous post, I developed the formula for the unit signature of
[tabular products](http://erikerlandson.github.io/blog/2020/05/01/unit-analysis-for-linear-algebra/#generalized-tabular-product)
and we can apply that directly to get:

$$
\large
\Upsilon X^T X =
\begin{bmatrix}
u_1 ^ 2 & u_1 u_2 & \dots & u_1 u_m \\
u_1 u_2 & u_2 ^ 2 & \dots & u_2 u_m \\
\vdots & & \ddots \\
u_1 u_m & u_2 u_m  & \dots & u_m ^ 2 \\
\end{bmatrix}
\quad \quad
\Upsilon X^T Y =
\begin{bmatrix}
u_1 v \\
u_2 v \\
\vdots \\
u_m v \\
\end{bmatrix}
$$

Furthermore, we have the formula for the unit signature of a
[tabular inverse](http://erikerlandson.github.io/blog/2020/05/01/unit-analysis-for-linear-algebra/#unit-signature-of-a-tabular-inverse-x-t-y-1):

$$
\large
\Upsilon (X^T X)^{-1}
=
\begin{bmatrix}
  (u_1 u_1)^{-1} & (u_2 u_1)^{-1} & \dots  & (u_m u_1)^{-1} \\
  (u_1 u_2)^{-1} & (u_2 u_2)^{-1} & \dots  & (u_m u_2)^{-1} \\
  \vdots         &                & \ddots & \\
  (u_1 u_m)^{-1} & (u_2 u_m)^{-1} & \dots  & (u_m u_m)^{-1} \\  
\end{bmatrix}
$$

Putting it all together, we arrive at the unit signature for $$ \hat \beta $$:

$$
\large
\begin{aligned}
\Upsilon \hat \beta
& =
\Upsilon \left( \left( X^T X \right) ^ {-1} X^T Y \right) \\
& =
\Upsilon \left( X^T X \right) ^ {-1} \quad \Upsilon X^T Y \\
& = 
\begin{bmatrix}
  (u_1 u_1)^{-1} & (u_2 u_1)^{-1} & \dots  & (u_m u_1)^{-1} \\
  (u_1 u_2)^{-1} & (u_2 u_2)^{-1} & \dots  & (u_m u_2)^{-1} \\
  \vdots         &                & \ddots & \\
  (u_1 u_m)^{-1} & (u_2 u_m)^{-1} & \dots  & (u_m u_m)^{-1} \\  
\end{bmatrix}
\begin{bmatrix}
u_1 v \\
u_2 v \\
\vdots \\
u_m v \\
\end{bmatrix} \\
&=
\begin{bmatrix}
v / u_1 \\
v / u_2 \\
\vdots \\
v / u_m \\
\end{bmatrix}
\end{aligned}
$$

To help make this concrete, applying these forms to our earlier example looks like this:

$$
\large
\Upsilon \hat \beta
=
\begin{bmatrix}
(cm\ cm)^{-1} & (yr\ cm)^{-1} \\
(cm\ yr)^{-1} & (yr\ yr)^{-1} \\
\end{bmatrix}
\begin{bmatrix}
cm\ kg \\
yr\ kg \\
\end{bmatrix}
=
\begin{bmatrix}
kg / cm \\
kg / yr \\
\end{bmatrix}
$$

The point of a unit analysis is to sanity check whether our units make sense.
Recall that we apply our model like so: $$ \hat y = \hat \beta \cdot x $$.
We can check the corresponding unit signatures to see if they are consistent,
and the law for unit signatures of
[inner products](http://erikerlandson.github.io/blog/2020/05/01/unit-analysis-for-linear-algebra/#unit-signature-of-vector-products)
shows that they are:

$$
\large
\begin{aligned}
\Upsilon \hat y & = \Upsilon \hat \beta \cdot x \\
v & = [ v / u_1, v / u_2 \dots v / u_m ] \cdot [ u_1, u_2 \dots u_m ] \\
v & = v \\
\end{aligned}
$$

Going back to our example, we would have:

$$
\large
kg = [ kg / cm, kg / yr] \cdot [cm, yr]
$$

There is a lot of work to do, to discover how widely these unit analysis techniques can be applied in data science mathematics.
However, I'm encouraged that they yield a proper unit analysis on a real world algorithm like Linear Regression.

