---
layout: post
title: "Putting Cubic B-Splines into Standard Polynomial Form"
date: 2018-09-02 11:07
comments: true
categories: [ computing, math, spline, splines, polynomial, polynomials ]
---
Lately I have been working on an [implementation](https://github.com/erikerlandson/snowball) of monotone smoothing splines, based on [[1]](#ref1). As the title suggests, this technique is based on a univariate cubic [B-spline](https://en.wikipedia.org/wiki/B-splines). The form of the spline function used in the paper is as follows:

![eq1](/assets/images/bspline/yd2guhxt.png)

The You can see that the constant α normalizes knot intervals to 1, and that the four <nobr>N<sub>i</sub>(t)</nobr> are defined in this transformed space of unit-separated knots.

I'm interested in providing an interpolated splines using the Apache Commons Math API, in particular the [PolynomialSplineFunction](https://commons.apache.org/proper/commons-math/javadocs/api-3.6/org/apache/commons/math3/analysis/polynomials/PolynomialSplineFunction.html) class. In principle the above is clearly such a polynomial, but there are a few hitches.

1. `PolynomialSplineFunction` wants its knot intervals in closed standard polynomial form <nobr>ax<sup>3</sup> + bx<sup>2</sup> + cx + d</nobr>
1. It wants each such polynomial expressed in transformed space <nobr>(x-K<sub>j</sub>)</nobr>, where K<sub>j</sub> is the greatest knot point that is <= x.
1. The actual domain of S(x) is <nobr>K<sub>0</sub> ... K<sub>m-1</sub></nobr>. The first 3 "negative" knots are there to make the summation for S(x) cleaner. `PolynomialSplineFunction` needs its functions to be defined purely on the actual domain.

If you study the definition of <nobr>B<sub>3</sub>(t)</nobr> above, you can see that if x lands in the interval <nobr>[K<sub>j</sub>, K<sub>j+1</sub>)</nobr> then it is the four knot points <nobr>K<sub>j-3</sub> ... K<sub>j</sub></nobr> that contribute to its value. This suggests a way to manipulate the equations into a standard form.

For a value x and its appropriate <nobr>K<sub>j</sub></nobr>, S(x) has four non-zero terms:

![eq2](/assets/images/bspline/y9tpgfqj.png)

Consider the first term for (j-3). Recalling that knots are equally spaced by 1/α:

![eq3](/assets/images/bspline/y79occ29.png)

We can apply similar logic for each term to get:

![eq4](/assets/images/bspline/ya6gsrjy.png)

and by plugging in the appropriate <nobr>N<sub>i</sub></nobr> for each term, we arrive at:

![eq5](/assets/images/bspline/yc6grwxe.png)

Now, `PolynomialSplineFunction` is going to automatically identify the appropriate <nobr>K<sub>j</sub></nobr> and subtract it, and so I can define that transform as <nobr>u = x -  K<sub>j</sub></nobr>, which gives:

![eq6](/assets/images/bspline/y9p3vgqt.png)

I substitute αu into the definitions of the four <nobr>N<sub>i</sub></nobr> to obtain:

![eq7](/assets/images/bspline/y8apdoqy.png)

Lastly, collecting like terms gives me the standard-form coefficients that I need for `PolynomialSplineFunction`:

![eq8](/assets/images/bspline/y7eon7kc.png)

Now I am equipped to return a `PolynomialSplineFunction` to my users, which implements the cubic B-spline that I fit to their data. Happy computing!

#### References
<a name="anchor1" id="ref1">[1] </a>H. Fujioka and H. Kano: [Monotone smoothing spline curves using normalized uniform cubic B-splines](https://github.com/erikerlandson/snowball/blob/master/monotone-cubic-B-splines-2013.pdf), Trans. Institute of Systems, Control and Information Engineers, Vol. 26, No. 11, pp. 389–397, 2013