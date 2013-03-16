---
layout: post
title: "Examining the Modulus of Random Variables"
date: 2013-03-15 12:03
comments: true
categories: [ computing, htcondor, math, random variable, modulus, mean, standard deviation, distribution, uniform distribution, normal distribution, log-normal distribution, exponential distribution ]
---

###Motivation
The original motivation for these experiments was consideration of the impact of negotiator cycle cadence (i.e. the time between the start of one cycle and the start of the next) on HTCondor pool loading.  Specifically, any HTCondor job that completes and vacates its resource may leave that resource unloaded until it can be re-matched on the next cycle.  Therefore, the duration of resource vacancies (and hence, pool loading) can be thought of as a function of job durations _modulo_ the cadence of the negotiator cycle.  In general, the aggregate behavior of job durations on a pool is useful to model as a random variable.  And so, it seemed worthwhile to build up a little intuition about the behavior of a random variable when you take its modulus.

###Methodology
I took a Monte Carlo approach to this study because a tractable theoretical framework eluded me, and you do not have to dive very deep to show that [even trivial random variable behavior under a modulus is dependent on the distribution](http://erikerlandson.github.com/blog/2013/01/02/the-mean-of-the-modulus-does-not-equal-the-modulus-of-the-mean/).   A Monte Carlo framework for the study also allows for other underlying distributions to be easily studied, by altering the random variable being sampled.   In the interest of getting right into results, I'll briefly discuss the tools I used at the end of this post.

###Modulus and Variance
Consider what happens to a random variable's modulus as its variance increases.  This sequence of plots shows that the modulus of a normal distribution tends toward a uniform distribution over the modulus interval, as the underlying variance increases:

|  |  |
| :---: | :---: |
|  {% img /assets/images/rv_mod_study/normal_0.20.png 375 375 %}  |  {% img /assets/images/rv_mod_study/normal_0.30.png 375 375 %}  |
|  {% img /assets/images/rv_mod_study/normal_0.40.png 375 375 %}  |  {% img /assets/images/rv_mod_study/normal_0.50.png 375 375 %}  |
<br>


From the above plots, we can see that in the case of a normal distribution, its modulus tends toward uniform rather quickly - by the time the underlying variance is half of the modulus interval.


The following plots demonstrate the same effect with a one-tailed distribution (the exponential) -- it requires a larger variance for the effect to manifest.


|  |  |
| :---: | :---: |
|  {% img /assets/images/rv_mod_study/exponential_01.png 375 375 %}  |  {% img /assets/images/rv_mod_study/exponential_04.png 375 375 %}  |
|  {% img /assets/images/rv_mod_study/exponential_10.png 375 375 %}  |  {% img /assets/images/rv_mod_study/exponential_20.png 375 375 %}  |
<br>


A third example, using a log-normal distribution.   The variance of the log-normal increases as a function of both \\( \\mu \\) and \\( \\sigma \\).  In this example \\( \\mu \\) is increased systematically, holding \\( \\sigma \\) constant at 1:


|  |  |
| :---: | :---: |
|  {% img /assets/images/rv_mod_study/lognormal_0.0_1.0.png 375 375 %}  |  {% img /assets/images/rv_mod_study/lognormal_0.5_1.0.png 375 375 %}  |
|  {% img /assets/images/rv_mod_study/lognormal_1.0_1.0.png 375 375 %}  |  {% img /assets/images/rv_mod_study/lognormal_2.0_1.0.png 375 375 %}  |
<br>


For a final examination of variance, I will again use log-normals and this time vary \\( \\sigma \\), while holding \\( \\mu \\) constant at 0.  Here we see that the effect of increasing the log-normal variance via \\( \\sigma \\) does _not_ follow the pattern in previous examples -- the distribution does not 'spread' and its modulus does not evolve toward a uniform distribution!

|  |  |
| :---: | :---: |
|  {% img /assets/images/rv_mod_study/lognormal_0.0_0.5.png 375 375 %}  |  {% img /assets/images/rv_mod_study/lognormal_0.0_1.0.png 375 375 %}  |
|  {% img /assets/images/rv_mod_study/lognormal_0.0_1.5.png 375 375 %}  |  {% img /assets/images/rv_mod_study/lognormal_0.0_2.0.png 375 375 %}  |
<br>


###Modulus and Mean
The following table of plots demonstrates the decreasing effect that a distribution's location (mean) has, as its spread increases and its modulus approaches uniformity.   In fact, we see that _any_ distribution in the 'uniform modulus' parameter region is indistinguishable from any other, with respect to its modulus -- all changes to mean or variance _within_ this region have no affect on the distribution's modulus!

|  |  |  |
| :---: | :---: | :---: |
|  {% img /assets/images/rv_mod_study/normal_0.0_0.3.png 260 260 %}  |  {% img /assets/images/rv_mod_study/normal_0.5_0.3.png 260 260 %}  |  {% img /assets/images/rv_mod_study/normal_1.0_0.3.png 260 260 %}  |
|  {% img /assets/images/rv_mod_study/normal_0.0_0.4.png 260 260 %}  |  {% img /assets/images/rv_mod_study/normal_0.5_0.4.png 260 260 %}  |  {% img /assets/images/rv_mod_study/normal_1.0_0.4.png 260 260 %}  |
|  {% img /assets/images/rv_mod_study/normal_0.0_0.5.png 260 260 %}  |  {% img /assets/images/rv_mod_study/normal_0.5_0.5.png 260 260 %}  |  {% img /assets/images/rv_mod_study/normal_1.0_0.5.png 260 260 %}  |
<br>


###Conclusions
Generally, as the spread of a distribution increases, its modulus tends toward a uniform distribution on the modulus interval.   Although it was tempting to state this in terms of increasing variance, we see from the 2nd log-normal experiment that variance can increase without increasing 'spread' in a way that causes the trend toward uniform modulus.   Currently, I'm not sure what the true invariant is, that properly distinguishes the 2nd log-normal scenario from the others.

For any distribution that _does_ reside in the 'uniform-modulus' parameter space, we see that neither changes to location nor spread (nor even category of distribution) can be distinguished by the distribution modulus.


###Tools
I used the following software widgets:

* [rv_modulus_study](https://github.com/erikerlandson/condor_tools/blob/cad8773da36fa7f3c60c93895a428d6f1fae6752/bin/rv_modulus_study) -- the jig for Monte Carlo sampling of underlying distributions and their corresponding modulus
* [dplot](https://github.com/erikerlandson/dtools/wiki/dplot) -- a simple cli wrapper around `matplotlib.pyplot` functionality
* [Capricious](https://github.com/willb/capricious/) -- a library for random sampling of various distribution types
* [Capricious::SplineDistribution](https://github.com/erikerlandson/capricious/blob/c8ec13f1f49880bb3573034de59971f84d15f7c1/lib/capricious/spline_distribution.rb) -- a ruby class for estimating PDF and CDF of a distribution from sampled data, using cubic Hermite splines (note, at the time of this writing, I'm using an experimental variation on my personal repo fork, at the link)
