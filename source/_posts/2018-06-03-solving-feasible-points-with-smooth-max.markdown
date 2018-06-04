---
layout: post
title: "Solving Feasible Points With Smooth-Max"
date: 2018-06-03 14:21
comments: true
categories: [ computing, optimization, feasible point, convex optimization ]
---

### Overture
Lately I have been fooling around with an [implementation](https://github.com/erikerlandson/gibbous) of the [Barrier Method](#cite1) for convex optimization with constraints.
One of the characteristics of the Barrier Method is that it requires an initial-guess from inside the
_feasible region_: that is, a point which is known to satisfy all of the inequality constraints provided
by the user.
For some optimization problems, it is straightforward to find such a point by using knowledge about the problem
domain, but in many situations it is not at all obvious how to identify such a point, or even if a
feasible point exists. The feasible region might be empty!

Boyd and Vandenberghe discuss a couple approaches to finding feasible points in §11.4 of [[1]](#cite1).
These methods require you to set up an "augmented" minimization problem:
![eq1](/assets/images/feasible/y9czf8u7.png)

As you can see from the above, you have to set up an "augmented" space x+s, where (s) represents an additional
dimension, and constraint functions are augmented to f<sub>k</sub>-s

### The Problem

I experimented a little with these, and while I am confident they work for most problems having multiple
inequality constraints, my unit testing tripped over an ironic deficiency:
when I attempted to solve a feasible point for a single planar constraint, the numerics went a bit haywire.
Specifically, a linear constraint function happens to have a singular Hessian of all zeroes.
The final Hessian, coming out of the log barrier function, could be consumed by SVD to get a search direction
but the resulting gradients behaved poorly.

Part of the problem seems to be that the nature of this augmented minimization problem forces the algorithms
to push (s) ever downward, but letting (s) transitively push the f<sub>k</sub> with the augmented constraint
functions f<sub>k</sub>-s. When only a single linear constraint function is in play, the resulting gradient
caused augmented dimension (s) to converge _against_ the movement of the remaining (unaugmented) sub-space.
The minimization did not converge to a feasible point, even though literally half of the space on one side
of the planar surface is feasible!

### Smooth Max

Thinking about these issues made me wonder if a more direct approach was possible.
Another way to think about this problem is to minimize the maximum f<sub>k</sub>;
If there is a minimum < 0 at a point x, then x is a feasible point satisfying all f<sub>k</sub>.
If the minimum is > 0, then we have definitive proof that no feasible point exists, and
our constraints can't be met.

Taking a maximum preserves convexity, which is a good start, but maximum isn't differentiable everywhere.
The boundaries between regions where different functions are the maximum are not smooth, and along
those boundaries there is no gradient, and therefore no Hessian either.

However, there is a variation on this idea, known as smooth-max, defined like so:

![eq2](/assets/images/feasible/y8cgykuc.png)

Smooth-max has a well defined [gradient and Hessian](http://erikerlandson.github.io/blog/2018/05/27/the-gradient-and-hessian-of-the-smooth-max-over-functions/), and furthermore can be computed in a [numerically stable](http://erikerlandson.github.io/blog/2018/05/28/computing-smooth-max-and-its-gradients-without-over-and-underflow/) way.
The sum inside the logarithm above is a sum of exponentials of convex functions.
This is good news; exponentials of convex functions are log-convex, and a sum of log-convex functions is also
log-convex.

That means I have the necessary tools to set up the my mini-max problem:
For a given set of convex constraint functions f<sub>k</sub>, I create a functions which is the soft-max of
these, and I minimize it.

### Go Directly to Jail

I set about implementing my smooth-max idea, and immediately ran into almost the same problem as before.
If I try to solve for a single planar constraint, my Hessian degenerates to all-zeros!
When I unpacked the smoothmax-formula for a single constraint f<sub>k</sub>, it indeed is just f<sub>k</sub>,
zero Hessian and all!

### More is More

What to do?
Well you know what form of constraint _always_ has a well behaved Hessian? A circle, that's what.
More technically, an n-dimensional ball, or n-ball.
What if I add a new constraint of the form:

![eq3](/assets/images/feasible/yd8xg64k.png)

This constraint equation is quadratic, and its Hessian is I<sub>n</sub>.
If I include this in my set of constraints, my smooth-max Hessian will be non-singular!

Since I do not know a priori where my feasible point might lie, I start with my n-ball centered at
my initial guess, and minimize. The result might look something like this:

![fig1](/assets/images/feasible/fig1.png)

Because the optimization is minimizing the maximum f<sub>k</sub>, the optimal point may not be feasible,
but if not it _will_ end up closer to the feasible region than before.
This suggests an iterative algorithm, where I update the location of the n-ball at each iteration,
until the resulting optimized point lies on the intersection of my original constraints and my
additional n-ball constraint:

![fig2](/assets/images/feasible/fig2.png)



### References

<a name="cite1"</a>
[1] §11.3 of _Convex Optimization_, Boyd and Vandenberghe, Cambridge University Press, 2008
