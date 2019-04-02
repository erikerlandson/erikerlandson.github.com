---
layout: post
title: "Equality Constraints for Cubic B-Splines"
date: 2018-09-08 14:32
comments: true
tags: [ computing, math, spline, splines, constraints, convex optimization, gradient, polynomial, polynomials ]
---

In my [previous post](http://erikerlandson.github.io/blog/2018/09/02/putting-cubic-b-splines-into-standard-polynomial-form/)
I derived the standard-form polynomial coefficients for cubic B-splines.
As part of the [same project](https://github.com/erikerlandson/snowball),
I also need to add a feature that allows the library user to declare equality constraints of the form <nobr>(x,y)</nobr>,
where <nobr>S(x) = y</nobr>. Under the hood, I am invoking a [convex optimization](https://github.com/erikerlandson/gibbous) library, and so I need to convert these
user inputs to a linear equation form that is consumable by the optimizer.

I expected this to be tricky, but it turns out I did most of the work [already](http://erikerlandson.github.io/blog/2018/09/02/putting-cubic-b-splines-into-standard-polynomial-form/).
I can take one of my previously-derived expressions for S(x) and put it into a form that gives me coefficients for the four contributing knot points <nobr>K<sub>j-3</sub> ... K<sub>j</sub></nobr>:

![eq](/assets/images/bspline/ybblhxfw.png)

Recall that by the convention from my previous post, <nobr>K<sub>j</sub></nobr> is the largest knot point that is <nobr><= x</nobr>.

My linear constraint equation is with respect to the vector I am solving for, in particular vector (τ), and so the
equation above yields the following:

![eq](/assets/images/bspline/y7jhvnmk.png)

In this form, it is easy to add into a [convex optimization](https://github.com/erikerlandson/gibbous) problem as a linear equality constraint.

Gradient constraints are another common equality constraint in convex optimization, and so I can apply very similar logic to get coefficient values corresponding to the gradient of S:

![eq](/assets/images/bspline/yd5fxmwk.png)

And so my linear equality constraint with respect to (τ) in this case is:

![eq](/assets/images/bspline/yalk3puu.png)

And that gives me the tools I need to let my users supply additional equality constraints as simple <nobr>(x,y)</nobr> pairs, and translate them into a form that can be consumed by convex optimization routines. Happy Computing!
