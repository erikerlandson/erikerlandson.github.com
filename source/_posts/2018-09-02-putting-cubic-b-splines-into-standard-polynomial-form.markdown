---
layout: post
title: "Putting Cubic B-Splines into Standard Polynomial Form"
date: 2018-09-02 11:07
comments: true
categories: [ computing, math, spline, splines, polynomial, polynomials ]
---
Lately I have been working on an [implementation](https://github.com/erikerlandson/snowball) of monotone smoothing splines, based on [[1]](#ref1). As the title suggests, this technique is based on a univariate cubic [B-spline](https://en.wikipedia.org/wiki/B-splines). The form of the spline function used in the paper is as follows:

![eq1](/assets/images/bspline/yd2guhxt.png)

The knot points <nobr>K<sub>j</sub></nobr> are all equally spaced by 1/α, and so α normalizes knot intervals to 1. The function <nobr>B<sub>3</sub>(t)</nobr> and the four <nobr>N<sub>i</sub>(t)</nobr> are defined in this transformed space, t, of unit-separated knots.

I'm interested in providing an interpolated splines using the Apache Commons Math API, in particular the [PolynomialSplineFunction](https://commons.apache.org/proper/commons-math/javadocs/api-3.6/org/apache/commons/math3/analysis/polynomials/PolynomialSplineFunction.html) class. In principle the above is clearly such a polynomial, but there are a few hitches.

1. `PolynomialSplineFunction` wants its knot intervals in closed standard polynomial form <nobr>ax<sup>3</sup> + bx<sup>2</sup> + cx + d</nobr>
1. It wants each such polynomial expressed in the translated space <nobr>(x-K<sub>j</sub>)</nobr>, where <nobr>K<sub>j</sub></nobr> is the greatest knot point that is <= x.
1. The actual domain of S(x) is <nobr>K<sub>0</sub> ... K<sub>m-1</sub></nobr>. The first 3 "negative" knots are there to make the summation for S(x) cleaner. `PolynomialSplineFunction` needs its functions to be defined purely on the actual domain.

Consider the arguments to <nobr>B<sub>3</sub></nobr>, for two adjacent knots <nobr>K<sub>j-1</sub></nobr> and <nobr>K<sub>j</sub></nobr>, where <nobr>K<sub>j</sub></nobr> is greatest knot point that is <= x. Recalling that knot points are all equally spaced by 1/α, we have the following relationship in the transformed space t:

![eq](/assets/images/bspline/ydcb2ao3.png)

We can apply this same manipulation to show that the arguments to <nobr>B<sub>3</sub></nobr>, as centered around knot <nobr>K<sub>j</sub></nobr>, are simply <nobr>{... t+2, t+1, t, t-1, t-2 ...}</nobr>.

By the definition of <nobr>B<sub>3</sub></nobr> above, you can see that <nobr>B<sub>3</sub>(t)</nobr> is non-zero only for t in <nobr>[0,4)</nobr>, and so the four corresponding knot points <nobr>K<sub>j-3</sub> ... K<sub>j</sub></nobr> contribute to its value:

![eq2](/assets/images/bspline/y9tpgfqj.png)

This suggests a way to manipulate the equations into a standard form. In the transformed space t, the four nonzero terms are:

![eq4](/assets/images/bspline/ya6gsrjy.png)

and by plugging in the appropriate <nobr>N<sub>i</sub></nobr> for each term, we arrive at:

![eq5](/assets/images/bspline/yc6grwxe.png)

Now, `PolynomialSplineFunction` is going to automatically identify the appropriate <nobr>K<sub>j</sub></nobr> and subtract it, and so I can define _that_ transform as <nobr>u = x -  K<sub>j</sub></nobr>, which gives:

![eq6](/assets/images/bspline/y9p3vgqt.png)

I substitute the value (αu) into the definitions of the four <nobr>N<sub>i</sub></nobr> to obtain:

![eq7](/assets/images/bspline/y8apdoqy.png)

Lastly, collecting like terms gives me the standard-form coefficients that I need for `PolynomialSplineFunction`:

![eq8](/assets/images/bspline/ya74mlsf.png)

Now I am equipped to return a `PolynomialSplineFunction` to my users, which implements the cubic B-spline that I fit to their data. Happy computing!

#### References
<a name="anchor1" id="ref1">[1] </a>H. Fujioka and H. Kano: [Monotone smoothing spline curves using normalized uniform cubic B-splines](https://github.com/erikerlandson/snowball/blob/master/monotone-cubic-B-splines-2013.pdf), Trans. Institute of Systems, Control and Information Engineers, Vol. 26, No. 11, pp. 389–397, 2013