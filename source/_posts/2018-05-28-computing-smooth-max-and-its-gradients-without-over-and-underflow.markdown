---
layout: post
title: "Computing Smooth Max and its Gradients Without Over- and Underflow"
date: 2018-05-28 08:13
comments: true
categories: [ computing, convex optimization, gradient descent, optimization, math, smooth max, soft max, gradient, hessian ]
---
In my [previous post](http://erikerlandson.github.io/blog/2018/05/27/the-gradient-and-hessian-of-the-smooth-max-over-functions/) I derived the gradient and Hessian for the smooth max function.
The [Notorious JDC](https://www.johndcook.com/blog/) wrote a helpful companion post that describes [computational issues](https://www.johndcook.com/blog/2010/01/20/how-to-compute-the-soft-maximum/) of overflow and underflow with smooth max;
values of f<sub>k</sub> don't have to grow very large (or small) before floating point limitations start to force their exponentials to +inf or zero.
In JDC's post he discusses this topic in terms of a two-valued smooth max.
However it isn't hard to generalize the idea to a collection of f<sub>k</sub>.
Start by taking the maximum value over our collection of functions, which I'll define as (z):

![eq1](/assets/images/smoothmax/eq1b.png)

As JDC described in his post, this alternative expression for smooth max (m) is computationally stable.
Individual exponential terms may underflow to zero, but they are the ones which are dominated by the other terms, and so approximating them by zero is numerically accurate.
In the limit where one value dominates all others, it will be exactly the value given by (z).

It turns out that we can play a similar trick with computing the gradient:

![eq2](/assets/images/smoothmax/eq2b.png)

Without showing the derivation, we can apply exactly the same manipulation to the terms of the Hessian:

![eq3](/assets/images/smoothmax/eq3b.png)

And so we now have a computationally stable form of the equations for smooth max, its gradient and its Hessian. Enjoy!
