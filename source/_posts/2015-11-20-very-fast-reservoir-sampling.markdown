---
layout: post
title: "Very Fast Reservoir Sampling"
date: 2015-11-20 11:27
comments: true
categories: [ computing, math, scala, sampling, random sampling, reservoir sampling, gap sampling ]
---

> The code I used to collect the data for this post can be viewed [here](https://github.com/erikerlandson/silex/blob/blog/reservoir/src/main/scala/com/redhat/et/silex/sample/reservoir/reservoir.scala).  I generated the plots using the [quantifind WISP](https://github.com/quantifind/wisp) project.

In a [previous post](http://erikerlandson.github.io/blog/2014/09/11/faster-random-samples-with-gap-sampling/), I showed that random Bernoulli and Poisson sampling could be made much faster by modeling the _sampling gap distribution_ for the corresponding smapling distributions.  More recently, I also began exploring whether [reservoir sampling](https://en.wikipedia.org/wiki/Reservoir_sampling) might also be optimized using the gap sampling technique, by deriving the [reservoir sampling gap distribution](http://erikerlandson.github.io/blog/2015/08/17/the-reservoir-sampling-gap-distribution/).  For a sampling reservoir of size (R), starting at data element (j), the probability distribution of the sampling gap is:

![Figure 1](/assets/images/reservoir1/figure6.png "Figure 1")

Modeling a sampling gap distribution is a powerful tool for optimizing a sampling algorithm, but it presupposes that you can actually draw values from that distribution substantially faster than just applying a random process to drawing each data element.  I was unable to come up with a "direct" algorithm for drawing samples from P(k) above (I suspect none exists), however I also know the CDF F(k), so it _is_ possible to apply [inversion sampling](https://en.wikipedia.org/wiki/Inverse_transform_sampling), which runs in logarithmic time w.r.t the desired accuracy.  Although its logarithmic cost effectively guarantees that it will be a net efficiency win for sufficiently large (j), it still involves a substantial number of computations to yield its samples, and it seems unlikely to be competitive with straight "naive" reservoir sampling over many real-world data sizes, where (j) may never grow very large.

Well, if exact computations are too expensive, we can always look for a fast approximation.  Consider the original "first principles" formula for the sampling gap P(k):

![Figure 2](/assets/images/reservoir2/figure2.png "Figure 2")

As the figure above alludes to, if (j) is relatively large compared to (k), then values (j+1),(j+2)...(j+k) are all going to be effectively "close" to (j), and so we can replace them all with (j) as an approximation.  Note that the resulting approximation is just the PMF of the [geometric distribution](https://en.wikipedia.org/wiki/Geometric_distribution), with probability of success p=(R/j), and we already saw how to efficiently draw values from a geometric distribution from our experience with Bernoulli sampling.

Do we have any reason to hope that this approximation will be useful?  For reasons that are similar to those for Bernoulli gap sampling, it will only be efficient to employ gap sampling when the probability (R/j) becomes small enough.  From our experiences with Bernoulli sampling that is _at least_ j>=2R.  So, we have some assurance that (j) itself will be never be _very_ small.  What about (k)?  Note that a geometric distribution "favors" smaller values of (k) -- that is, small values of (k) have the highest probabilities.  In fact, the smaller that (j) is, the larger the probability (R/j) is, and so the more likely that (k) values that are small relative to (j) will be the frequent ones.  It is also promising that the true distribution for P(k) _also_ favors smaller values of (k) (in fact it favors them even a bit more strongly than the approximation).

Although it is encouraging, it is also clear that my argument above is limited to heuristic hand-waving.  What does this approximation really _look_ like, compared to the true distribution?  Fortunately, it is easy to plot both distributions numerically, since we now know the formulas for both:

![Figure 3](/assets/images/reservoir2/CDFs_R=10.png "Figure 3")

The plot above shows that, in fact, the geometric approximation is a _surprisingly good_ approximation to the true distribution!  Furthermore, the approximation remains good as both (j) and (k) grow larger.

Our numeric eye-balling looks quite promising.  Is there an effective way to _measure_ how good this approximation is?  One useful measure is the [Kolmogorov-Smirnov D statistic](https://en.wikipedia.org/wiki/Kolmogorov%E2%80%93Smirnov_test), which is just the maximum absolute error between two cumulative distributions.  Here is a plot of the D statistic for reservoir size R=10, as (j) varies across several magnitudes:

![Figure 4](/assets/images/reservoir2/R=10.png "Figure 4")

This plot is also good news: we can see that deviation, as measured by D, remains bounded at a small value (less than 0.0262).  As this is for the specific value R=10, we also want to know how things change as reservoir size changes:

![Figure 5](/assets/images/reservoir2/R=all.png "Figure 5")

The news is still good!  As reservoir size grows, the approximation only gets better: the D values get smaller as R increases, and remain asymtotically bounded as (j) increases.

Now we have some numeric assurance that the geometric approximation is a good one, and stays good as reservoir size grows and sampling runs get longer.  However, we should also verify that an actual implementation of the approximation works as expected.  Following is a plot that shows two-sample D statistics, comparing the distribution in sample gaps between runs of the exact "naive" reservoir sampling with the fast geometric approximation:

![Figure 6](/assets/images/reservoir2/D_naive_vs_fast.png "Figure 6")

As expected, the measured difference in sampling characteristics between naive and fast approximation are small, confirming the numeric predictions.

Since the point of this exercise was to achieve faster random sampling, it remains to measure what kind of speed improvements the fast approximation provides.  As a point of reference, here is a plot of run times for reservoir sampling over 10^8 integers:

![Figure 7](/assets/images/reservoir2/naive_sample_time_vs_R.png "Figure 7")

As expected, sample time remains constant at around 1.5 seconds, regardless of reservoir size, since the naive algorithm always samples from its RNG per each sample.

Compare this to the corresponding plot for the fast geometric approximation:

![Figure 8](/assets/images/reservoir2/gap_sample_times_vs_R.png "Figure 8")

Firstly, we see that the sampling times are _much faster_, as originally anticipated in my [previous post](http://erikerlandson.github.io/blog/2015/08/17/the-reservoir-sampling-gap-distribution/) -- in the neighborhood of 3 orders of magnitude faster.  Secondly, we see that the sampling times do increase as a linear function of reservoir size.  Based on our experience with Bernoulli gap sampling, this is expected; the sampling probabilities are given by (R/j), and therefore the amount of sampling is proportional to R.

Another property anticipated in my previous post was that the efficiency of gap sampling should continue to increase as the amount of data sampled grows; the sampling probability being (R/j), the probability of sampling decreases as j gets larger, and so the corresponding gap sizes grow.  The following plot verifies this property, holding reservoir size R constant, and increasing the data size:

![Figure 9](/assets/images/reservoir2/gap_sampling_efficiency.png "Figure 9")

The sampling time (per million elements) decreases as the sample size grows, as predicted by the formula.

In conclusion, I have demonstrated that a geometric distribution can be used as a high quality approximation to the true sampling gap distribution for reservoir sampling, which allows reservoir sampling to be performed much faster than the naive algorithm while still retaining sampling quality.
 