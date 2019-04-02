---
layout: post
title: "Deriving an Incremental Form of the Polynomial Regression Equations"
date: 2012-07-05 19:46
comments: true
tags: [ computing, machine learning, math, incremental, on-line learning, linear regression, polynomial regression ]
---

Incremental, or on-line, algorithms are increasingly popular as data set sizes explode and web enabled applications create environments where new data arrive continuously (that is, incrementally) from clients out on the internet.

Recently I have been doing some [experiments](https://github.com/erikerlandson/ratorade) with applying one of the _oldest_ incremental algorithms to the task of rating predictions: computing a linear regression with a coefficient of correlation.  The incremental formulae look like this:

To find coefficients $$ a_0, a_1 $$ of the linear predictor $$ y = a_0 + a_1 x $$ :

$$
a_1 = \frac {n \Sigma x y - \Sigma x \Sigma y} {n \Sigma x^2 - \left( \Sigma x \right) ^2 }
\hspace{1 cm}
a_0 = \frac { \Sigma y - a_1 \Sigma x } {n}
$$

The correlation coefficient of this predictor is given by:

$$
\rho (x,y) = \frac {n \Sigma x y - \Sigma x \Sigma y} {\sqrt {n \Sigma x^2 - \left( \Sigma x \right) ^ 2 } \sqrt {n \Sigma y^2 - \left( \Sigma y \right) ^ 2 } }
$$

As you can see from the formulae above, it is sufficient to maintain running sums 

$$
n, \Sigma x, \Sigma y, \Sigma x^2, \Sigma y^2, \Sigma x y
$$

and so any new data can be included incrementally - that is, the model can be updated without revisiting any previous data.

Working with these models caused me to wonder if there was a way to generalize them to obtain incremental formulae for a quadratic predictor, or generalized polynomials.  As it happens, there is.  To show how, I'll derive an incremental formula for the coefficients of the quadratic predictor:

$$
y = a_0 + a_1 x + a_2 x^2
$$

Recall the [matrix formula](http://en.wikipedia.org/wiki/Polynomial_regression#Matrix_form_and_calculation_of_estimates) for polynomial regression:

$$ \vec{a} = \left( X^T X \right) ^ {-1} X^T \vec{y} $$

where, in the quadratic case:

$$
\vec{a} = \left( \begin{array} {c}
a_0 \\
a_1 \\
a_2 \\
\end{array} \right)
\hspace{1 cm}
X = \left( \begin{array} {ccc}
1 & x_1 & x_1^2 \\
1 & x_2 & x_2^2 \\
  &  \vdots  & \\
1 & x_n & x_n^2 \\
\end{array} \right)
\hspace{1 cm}
\vec{y} = \left( \begin{array} {c}
y_1 \\
y_2 \\
\vdots \\
y_n \\
\end{array} \right)
$$

Note that we can apply the definition of matrix multiplication and express the two products $$ X^T X $$ and $$ X^T \vec{y} $$ from the above formula like so:

$$
X^T X = 
\left( \begin{array} {ccc}
n & \Sigma x & \Sigma x^2 \\
\Sigma x & \Sigma x^2 & \Sigma x^3 \\
\Sigma x^2 & \Sigma x^3 & \Sigma x^4 \\
\end{array} \right)
\hspace{1 cm}
X^T \vec{y} =
\left( \begin{array} {c}
\Sigma y \\
\Sigma x y \\
\Sigma x^2 y \\
\end{array} \right)
$$

And so now we can express the formula for our quadratic coefficients in this way:

$$
\left( \begin{array} {c}
a_0 \\
a_1 \\
a_2 \\
\end{array} \right)
=
\left( \begin{array} {ccc}
n & \Sigma x & \Sigma x^2 \\
\Sigma x & \Sigma x^2 & \Sigma x^3 \\
\Sigma x^2 & \Sigma x^3 & \Sigma x^4 \\
\end{array} \right)
^ {-1}
\left( \begin{array} {c}
\Sigma y \\
\Sigma x y \\
\Sigma x^2 y \\
\end{array} \right)
$$

Note that we now have a matrix formula that is expressed entirely in sums of various terms in x and y, which means that it can be maintained incrementally, as we desired.  If you have access to a matrix math package, you might very well declare victory right here, as you can easily construct these matrices and do the matrix arithmetic at will to obtain the model coefficients.  However, as an additional step I applied [sage](http://www.sagemath.org/) to do the symbolic matrix inversion and multiplication to give:

$$
\small
a_0 =
\frac {1} {Z}
\left( 
- \left( \Sigma x^3 \Sigma x - \left( \Sigma x^2 \right)^2 \right) \Sigma x^2 y  +  \left( \Sigma x^4  \Sigma x - \Sigma x^3 \Sigma x^2 \right) \Sigma x y  -  \left( \Sigma x^4 \Sigma x^2 - \left( \Sigma x^3 \right)^2 \right) \Sigma y 
\right)
\normalsize
$$

$$
\small
a_1 =
\frac {1} {Z}
\left( 
\left( n \Sigma x^3  - \Sigma x^2 \Sigma x \right) \Sigma x^2 y  -  \left( n \Sigma x^4 - \left( \Sigma x^2 \right) ^2 \right) \Sigma x y  +  \left( \Sigma x^4 \Sigma x - \Sigma x^3 \Sigma x^2 \right) \Sigma y
\right)
\normalsize
$$

$$
\small
a_2 =
\frac {1} {Z}
\left( 
- \left( n \Sigma x^2 - \left( \Sigma x \right) ^2 \right) \Sigma x^2 y  +  \left( n \Sigma x^3 - \Sigma x^2 \Sigma x \right) \Sigma x y  -  \left( \Sigma x^3 \Sigma x - \left( \Sigma x^2 \right) ^2 \right) \Sigma y 
\right)
\normalsize
$$

where:

$$
Z = n \left( \Sigma x^3 \right) ^ 2 - 2 \Sigma x^3 \Sigma x^2 \Sigma x + \left( \Sigma x^2 \right) ^3 - \left( n \Sigma x^2 - \left( \Sigma x \right) ^2  \right) \Sigma x^4
$$

Inspecting the quadratic derivation above, it is now fairly easy to see that the general form of the incremental matrix formula for the coefficients of a degree-m polynomial looks like this:

$$
\left( \begin{array} {c}
a_0 \\
a_1 \\
\vdots \\
a_m \\
\end{array} \right)
=
\left( \begin{array} {cccc}
n & \Sigma x & \cdots & \Sigma x^m \\
\Sigma x & \Sigma x^2 & \cdots & \Sigma x^{m+1} \\
\vdots & & \ddots & \vdots \\
\Sigma x^m & \Sigma x^{m+1} & \cdots & \Sigma x^{2 m} \\
\end{array} \right)
^ {-1}
\left( \begin{array} {c}
\Sigma y \\
\Sigma x y \\
\vdots \\
\Sigma x^m y \\
\end{array} \right)
$$

Having an incremental formula for generalized polynomial regression leaves open the question of how one might generalize the correlation coefficient.  There is such a generalization, called the [coefficient of multiple determination](http://en.wikipedia.org/wiki/Multiple_correlation), which is defined:

$$
r = \sqrt { \vec{c} ^ T  R^{-1}  \vec{c} }
$$

Where

$$
\vec{c} = 
\left ( \begin{array} {c}
\rho (x,y) \\
\rho (x^2,y) \\
\vdots \\
\rho (x^m,y) \\
\end{array} \right)
\hspace{1 cm}
R =
\left( \begin{array} {cccc}
1 & \rho (x,x^2) & \cdots & \rho(x,x^m) \\
\rho (x^2,x) & 1 & \cdots & \rho(x^2,x^m) \\
\vdots & & \ddots & \vdots \\
\rho (x^m,x) & \rho (x^m,x^2) & \cdots & 1 \\
\end{array} \right)
$$

and $$ \rho (x,y) $$ is the traditional pairwise correlation coefficient.

But we already have an incremental formula for any pairwise correlation coefficient, which is defined above.  And so we can maintain the running sums needed to fill the matrix entries, and compute the coefficient of multiple determination for our polynomial model at any time.

So we now have incremental formulae to maintain any polynomial model in an on-line environment where we either can't or prefer not to store the data history, and also incrementally evaluate the 'generalized correlation coefficient' for that model.

Readers familiar with linear regression may notice that there is also nothing special about polynomial regression, in the sense that powers of x may also be replaced with arbitrary functions of x, and the same regression equations hold.  And so we might generalize the incremental matrix formulae further to replace products of powers of x with products of functions of x:

for a linear regression model $$ y = a_1 f_1 (x) + a_2 f_2 (x) + \cdots + a_m f_m(x) $$ :

$$
\left( \begin{array} {c}
a_1 \\
a_2 \\
\vdots \\
a_m \\
\end{array} \right)
=
\left( \begin{array} {cccc}
\Sigma f_1 (x) f_1 (x) & \Sigma f_1 (x) f_2 (x) & \cdots & \Sigma f_1 (x) f_m (x) \\
\Sigma f_2 (x) f_1 (x) & \Sigma f_2 (x) f_2 (x) & \cdots & \Sigma f_2 (x) f_m (x) \\
\vdots & & \ddots & \vdots \\
\Sigma f_m (x) f_1 (x) & \Sigma f_m (x) f_2 (x) & \cdots & \Sigma f_m (x) f_m (x) \\
\end{array} \right)
^ {-1}
\left( \begin{array} {c}
\Sigma y f_1 (x) \\
\Sigma y f_2 (x) \\
\vdots \\
\Sigma y f_m (x) \\
\end{array} \right)
$$

The coefficient of multiple determination generalizes in the analogous way.
