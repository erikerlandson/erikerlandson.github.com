---
layout: post
title: "Computing Derivatives of the Gamma Function"
date: 2016-06-15 16:37
comments: true
published: false
categories: [ computing, math, gamma function, digamma function, trigamma function, polygamma function, derivative ]
---

In this post I'll describe a simple algorithm to compute the kth derivatives of the [Gamma function](https://en.wikipedia.org/wiki/Gamma_function).

I'll start by showing a simple recursion relation for these derivatives, and then gives its derivation.  The kth derivative of Gamma(x) can be computed as follows:

![Equation 1](/assets/images/dgamma/hvqtl52.png)

The recursive formula for the D<sub>k</sub> functions has an easy inductive proof:

![Equation 2](/assets/images/dgamma/h79ued9.png)

Computing the next value D<sub>k</sub> requires knowledge of D<sub>k-1</sub> but also derivative D'<sub>k-1</sub>.  If we start expanding terms, we see the following:

![Equation 3](/assets/images/dgamma/hhvonpa.png)

Continuing the process above it is not hard to see that we can continue expanding until we are left only with terms of <nobr>D<sub>1</sub><sup>(*)</sup>(x);</nobr> that is, various derivatives of <nobr>D<sub>1</sub>(x)</nobr>.  Furthermore, each layer of substitutions adds an order to the derivatives, so that we will eventually be left with terms involving the derivatives of <nobr>D<sub>1</sub>(x)</nobr> up to the (k-1)th derivative. Note that these will all be successive orders of the [polygamma function](https://en.wikipedia.org/wiki/Polygamma_function).

What we want, to do these computations systematically, is a formula for computing the nth derivative of a term <nobr>D<sub>k</sub>(x)</nobr>.  Examining the first few such derivatives suggests a pattern:

![Equation 4](/assets/images/dgamma/jqwqpzy.png)

Generalizing from the above, we see that the formula for the nth derivative is:

![Equation 5](/assets/images/dgamma/jamccnh.png)

We are now in a position to fill in the triangular table of values, culminating in the value of <nobr>D<sub>k</sub>(x):</nobr>

![Equation 6](/assets/images/dgamma/jj9ph5l.png)

As previously mentioned, the basis row of values <nobr>D<sub>1</sub><sup>(*)</sup>(x)</nobr> are the [polygamma functions](https://en.wikipedia.org/wiki/Polygamma_function) where <nobr>D<sub>1</sub><sup>(n)</sup>(x) = polygamma<sup>(n)</sup>(x)</nobr>.  The first two polygammas, order 0 and 1, are simply the digamma and trigamma functions, respectively, and are available with most numeric libraries.  Computing the general polygamma is a project, and blog post, for another time, but the standard polynomial approximation for the digamma function can of course be differentiated...  Happy Computing!
