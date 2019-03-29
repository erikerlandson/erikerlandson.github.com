---
layout: post
title: "Approximating a PDF of Distances With a Gamma Distribution"
date: 2016-07-09 11:25
comments: true
published: true
categories: [ computing, math, probability, density, PDF, dimensionality, gamma distribution ]
---
In a [previous post](http://erikerlandson.github.io/blog/2016/06/08/exploring-the-effects-of-dimensionality-on-a-pdf-of-distances/) I discussed some unintuitive aspects of the distribution of distances as spatial dimension changes.  To help explain this to myself I derived a formula for this distribution, assuming a unit multivariate Gaussian.  For distance (aka radius) r, and spatial dimension d, the PDF of distances is:

![Figure 1](/assets/images/dist_dist/gwwv5a5.png)

Recall that the form of this PDF is the [generalized gamma distribution](https://en.wikipedia.org/wiki/Generalized_gamma_distribution), with scale parameter <nobr>a=sqrt(2),</nobr> shape parameter p=2, and free shape parameter (d) representing the dimensionality.

I was interested in fitting parameters to such a distribution, using some distance data from a clustering algorithm.  [SciPy](https://www.scipy.org/) comes with a predefined method for fitting generalized gamma parameters, however I wished to implement something similar using [Apache Commons Math](http://commons.apache.org/proper/commons-math/), which does not have native support for fitting a generalized gamma PDF.  I even went so far as to start working out [some of the math](http://erikerlandson.github.io/blog/2016/06/15/computing-derivatives-of-the-gamma-function/) needed to augment the Commons Math [Automatic Differentiation libraries](http://commons.apache.org/proper/commons-math/apidocs/org/apache/commons/math3/analysis/differentiation/package-summary.html) with Gamma function differentiation needed to numerically fit my parameters.

Meanwhile, I have been fitting a _non generalized_ [gamma distribution](https://en.wikipedia.org/wiki/Gamma_distribution) to the distance data, as a sort of rough cut, using a fast [non-iterative approximation](https://en.wikipedia.org/wiki/Gamma_distribution#Maximum_likelihood_estimation) to the parameter optimization.  Consistent with my habit of asking the obvious question last, I tried plotting this gamma approximation against distance data, to see how well it compared against the PDF that I derived.

Surprisingly (at least to me), my approximation using the gamma distribution is a very effective fit for spatial dimensionalities <nobr> >= 2 </nobr>:

![Figure 2](/assets/images/gamma_approx/approx_plot.png)

As the plot shows, only for the 1-dimension case is the gamma approximation substiantially deviating.  In fact, the fit appears to get better as dimensionality increases.  To address the 1D case, I can easily test the fit of a half-gaussian as a possible model.
