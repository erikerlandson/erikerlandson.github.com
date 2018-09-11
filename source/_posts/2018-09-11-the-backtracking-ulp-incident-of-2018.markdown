---
layout: post
title: "The Backtracking ULP Incident of 2018"
date: 2018-09-11 07:01
comments: true
categories: [ computing, math, floating point, ULP, unit in last place, numeric methods, error ]
---

This week I finally started applying my new [convex optimization](https://github.com/erikerlandson/gibbous/) library to solve for interpolating splines with [monotonic constraints](https://github.com/erikerlandson/snowball). Things seemed to be going well. My convex optimization was passing unit tests. My monotone splines were passing their unit tests too. I cut an initial release, and announced it to the world.

Because Murphy rules my world, it was barely an hour later that I was playing around with my new toys in a REPL, and when I tried splining an example data set my library call went into an infinite loop:

```java
// It looks mostly harmless:
double[] x = { 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0 };
double[] y = { 0.0, 0.15, 0.05, 0.3, 0.5, 0.7, 0.95, 0.98, 1.0 };
MonotonicSplineInterpolator interpolator = new MonotonicSplineInterpolator();
PolynomialSplineFunction s = interpolator.interpolate(x, y);
```

In addition to being a bit embarrassing, it was also a real head-scratcher. There was nothing odd about the data I had just given it. In fact it was a small variation of a problem it had just solved a few seconds prior.

There was nothing to do but put my code back up on blocks and break out the print statements. I ran my problem data set and watched it spin. Fast forward a half hour or so, and I localized the problem to a bit of code that does the ["backtracking" phase](https://en.wikipedia.org/wiki/Backtracking_line_search) of a convex optimization:

```java
for (double t = 1.0 ; t >= epsilon ; t *= beta) {
    tx = x.add(xDelta.mapMultiply(t));
    tv = convexObjective.value(tx);
    if (tv == Double.POSITIVE_INFINITY) continue;
    if (tv <= v + t*alpha*gdd) {
        foundStep = true;
        break;
    }
}
```

My infinite loop was happening because my backtracking loop above was "succeeding" -- that is, reporting it had found a forward step -- but not actually moving foward along its vector. And the reason turned out to be that my test `tv <= v + t*alpha*gdd` was succeding because `v + t*alpha*gdd` was evaluating to just `v`, and I effectively had `tv == v`.

I had been bitten by one of the oldest floating-point fallacies: forgetting that `x + y` can equal `x` if `y` gets smaller than the Unit in the Last Place (ULP) of `x`.

This was an especially evil bug, as it very frequently _doesn't_ manifest. My unit testing in _two libraries_ failed to trigger it. I have since added the offending data set to my splining unit tests, in case the code ever regresses somehow.

Now that I understood my problem, it turns out that I could use this to my advantage, as an effective test for local convergence. If I can't find a step size that reduces my local objective function by an amount measurable to floating point resolution, then I am as good as converged at this stage of the algorithm. I re-wrote my code to reflect this insight, and added some annotations so I don't forget what I learned:

```java
for (double t = 1.0; t > 0.0; t *= beta) {
    tx = x.add(xDelta.mapMultiply(t));
    tv = convexObjective.value(tx);
    if (Double.isInfinite(tv)) {
        // this is barrier convention for "outside the feasible domain",
        // so try a smaller step
        continue;
    }
    double vtt = v + (t * alpha * gdd);
    if (vtt == v) {
        // (t)(alpha)(gdd) is less than ULP(v)
        // Further tests for improvement are going to fail
        break;
    }
    if (tv <= vtt) {
        // This step resulted in an improvement, so halt with success
        foundStep = true;
        break;
    }
}
```

I tend to pride myself on being aware that floating point numerics are a leaky abstraction, and the various ways these leaks can show up in computations, but pride goeth before a fall, and after all these years I can still burn myself! It never hurts to be reminded that you can never let your guard down with floating point numbers, and unit testing can never _guarantee_ correctness. That goes double for numeric methods!
