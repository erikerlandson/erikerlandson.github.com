---
layout: post
title: "Computing Derivatives of the Gamma Function"
date: 2016-06-15 16:37
comments: true
categories: [ computing, gamma function, math ]
---

In this post I'll describe a simple algorithm to compute the kth derivatives of the [Gamma function](https://en.wikipedia.org/wiki/Gamma_function).

I'll start by showing a simple recursion relation that makes it easy to compute these derivatives, and then gives its derivation.  The kth derivative of Gamma(x) can be computed as follows:

![Equation 1](/assets/images/dgamma/hvqtl52.png)

The recursive formula for the D<sub>k</sub> functions has an easy inductive proof:

![Equation 2](/assets/images/dgamma/h79ued9.png)

Computing the next value D<sub>k</sub> requires knowledge of D<sub>k-1</sub> but also derivative D'<sub>k-1</sub>.  Fortunately we can derive a corresponding formula for D'<sub>k</sub> as a function of D<sub>k-1</sub> and D'<sub>k-1</sub>:

![Equation 3](/assets/images/dgamma/gqk2lex.png)

This gives us the means to compute the kth derivative of the Gamma function.
