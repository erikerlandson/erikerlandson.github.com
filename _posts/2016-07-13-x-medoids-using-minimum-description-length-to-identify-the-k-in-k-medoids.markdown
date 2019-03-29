---
layout: post
title: "Using Minimum Description Length to Optimize the 'K' in K-Medoids"
date: 2016-08-03 20:00
comments: true
published: true
categories: [ computing, k-medoids, minimum description length, MDL, optimization, clustering, k-means, compression ]
---

Applying many popular clustering models, for example [K-Means](https://en.wikipedia.org/wiki/K-means_clustering), [K-Medoids](https://en.wikipedia.org/wiki/K-medoids) and [Gaussian Mixtures](https://en.wikipedia.org/wiki/Expectation%E2%80%93maximization_algorithm#Gaussian_mixture), requires an up-front choice of the number of clusters -- the 'K' in K-Means, as it were.
Anybody who has ever applied these models is familiar with the inconvenient task of guessing what an appropriate value for K might actually be.
As the size and dimensionality of data grows, estimating a good value for K rapidly becomes an exercise in wild guessing and multiple iterations through the free-parameter space of possible K values.

There are some varied approaches in the community for addressing the task of identifying a good number of clusters in a data set.  In this post I want to focus on an approach that I think deserves more attention than it gets: [Minimum Description Length](https://en.wikipedia.org/wiki/Minimum_description_length).

Many years ago I ran across a [superb paper](#cite1) by Stephen J. Roberts on anomaly detection that described a method for _automatically_ choosing a good value for the number of clusters based on the principle of Minimum Description Length.
Minimum Description Length (MDL) is an elegant framework for evaluating the parsimony of a model.
The Description Length of a model is defined as the amount of information needed to encode that model, plus the encoding-length of some data, _given_ that model.
Therefore, in an MDL framework, a good model is one that allows an efficient (i.e. short) encoding of the data, but whose _own_ description is _also_ efficient
(This suggests connections between MDL and the idea of [learning as a form of data compression](https://en.wikipedia.org/wiki/Data_compression#Machine_learning)).

For example, a model that directly memorizes all the data may allow for a very short description of the data, but the model itself will cleary require at least the size of the raw data to encode, and so direct memorization models generaly stack up poorly with respect to MDL.
On the other hand, consider a model of some Gaussian data.  We can describe these data in a length proportional to their log-likelihood under the Gaussian density.  Furthermore, the description length of the Gaussian model itself is very short; just the encoding of its mean and standard deviation.  And so in this case a Gaussian distribution represents an efficient model with respect to MDL.

**In summary, an MDL framework allows us to mathematically capture the idea that we only wish to consider increasing the complexity of our models if that buys us a corresponding increase in descriptive power on our data.**

In the case of [Roberts' paper](#cite1), the clustering model in question is a [Gaussian Mixture Model](https://en.wikipedia.org/wiki/Expectation%E2%80%93maximization_algorithm#Gaussian_mixture) (GMM), and the description length expression to be optimized can be written as:

![EQ-1](/assets/images/xmedoids/mdl_gm_eq.png)

In this expression, X represents the vector of data elements.
The first term is the (negative) log-likelihood of the data, with respect to a candidate GMM having some number (K) of Gaussians; p(x) is the GMM density at point (x).
This term represents the cost of encoding the data, given that GMM.
The second term is the cost of encoding the GMM itself.
The value P is the number of free parameters needed to describe that GMM.
Assuming a dimensionality D for the data, then <nobr>P = K(D + D(D+1)/2):</nobr> D values for each mean vector, and <nobr>D(D+1)/2</nobr> values for each covariance matrix.

I wanted to apply this same MDL principle to identifying a good value for K, in the case of a [K-Medoids](https://en.wikipedia.org/wiki/K-medoids) model.
How best to adapt MDL to K-Medoids poses some problems.
In the case of K-Medoids, the _only_ structure given to the data is a distance metric.
There is no vector algebra defined on data elements, much less any ability to model the points as a Gaussian Mixture.

However, any candidate clustering of my data _does_ give me a corresponding distribution of distances from each data element to it's closest medoid.
I can evaluate an MDL measure on these distance values.
If adding more clusters (i.e. increasing K) does not sufficiently tighten this distribution, then its description length will start to increase at larger values of K, thus indicating that more clusters are not improving our model of the data.
Expressing this idea as an MDL formulation produces the following description length formula:

![EQ-2](/assets/images/xmedoids/mdl_km_eq.png)

Note that the first two terms are similar to the equation above; however, the underlying distribution <nobr>p(||x-c<sub>x</sub>||)</nobr> is now a distribution over the distances of each data element (x) to its closest medoid <nobr>c<sub>x</sub></nobr>, and P is the corresponding number of free parameters for this distribution (more on this below).
There is now an additional third term, representing the cost of encoding the K medoids.
Each medoid is a data element, and specifying each data element requires log|X| bits (or [nats](http://mathworld.wolfram.com/Nat.html), since I generally use natural logarithms), yielding an additional <nobr>(K)log|X|</nobr> in description length cost.

And so, an MDL-based algorithm for automatically identifying a good number of clusters (K) in a K-Medoids model is to run a K-Medoids clustering on my data, for some set of potential K values, and evaluate the MDL measure above for each, and choose the model whose description length L(X) is the smallest!

As I mentioned above, there is also an implied task of choosing a form (or a set of forms) for the distance distribution <nobr>p(||x-c<sub>x</sub>||)</nobr>.
At the time of this writing, I am fitting a [gamma distribution](https://en.wikipedia.org/wiki/Gamma_distribution) to the distance data, and [using this gamma distribution](https://github.com/erikerlandson/silex/blob/blog/xmedoids/src/main/scala/com/redhat/et/silex/cluster/KMedoids.scala#L578) to compute log-likelihood values.
A gamma distribution has two free parameters -- a shape parameter and a location parameter -- and so currently the value of P is always 2 in my implementations.
I elaborated on some back-story about how I arrived at the decision to use a gamma distribution [here](http://erikerlandson.github.io/blog/2016/07/09/approximating-a-pdf-of-distances-with-a-gamma-distribution/) and [here](http://erikerlandson.github.io/blog/2016/06/08/exploring-the-effects-of-dimensionality-on-a-pdf-of-distances/).
An additional reason for my choice is that the gamma distribution does have a fairly good shape coverage, including two-tailed, single-tailed, and/or exponential-like shapes.

Another observation (based on my blog posts mentioned above) is that my use of the gamma distribution implies a bias toward cluster distributions that behave (more or less) like Gaussian clusters, and so in this respect its current behavior is probably somewhat analogous to the [G-Means algorithm](#cite2), which identifies clusterings that yield Gaussian disributions in each cluster.
Adding other candidates for distance distributions is a useful subject for future work, since there is no compelling reason to either favor or assume Gaussian-like cluster distributions over _all_ kinds of metric spaces.
That said, I am seeing reasonable results even on data with clusters that I suspect are not well modeled as Gaussian distributions.
Perhaps the shape-coverage of the gamma distribution is helping to add some robustness.

To demonstrate the MDL-enhanced K-Medoids in action, I will illustrate its performance on some data sets that are amenable to graphic representation.  The code I used to generate these results is [here](https://github.com/erikerlandson/silex/blob/blog/xmedoids/src/main/scala/com/redhat/et/silex/cluster/KMedoids.scala#L629).

Consider this synthetic data set of points in 2D space.  You can see that I've generated the data to have two latent clusters:

![K2-Raw](/assets/images/xmedoids/k2_raw.png)

I collected the description-length values for candidate K-Medoids models having 1 up to 10 clusters, and plotted them.  This plot shows that the clustering with minimal description length had 2 clusters:

![K2-MDL](/assets/images/xmedoids/k2_mdl.png)

When I plot that optimal clustering at K=2 (with cluster medoids marked in black-and-yellow), the clustering looks good:

![K2-Clusters](/assets/images/xmedoids/k2_clusters.png)

To show the behavior for a different optimal value, the following plots demonstrate the MDL K-Medoids results on data where the number of latent clusters is 4:

![K4-Raw](/assets/images/xmedoids/k4_raw.png)
![K4-MDL](/assets/images/xmedoids/k4_mdl.png)
![K4-Clusters](/assets/images/xmedoids/k4_clusters.png)

A final comment on Minimum Description Length approaches to clustering -- although I focused on K-Medoids models in this post, the basic approach (and I suspect even the same description length formulation) would apply equally well to K-Means, and possibly other clustering models.
Any clustering model that involves a distance function from elements to some kind of cluster center should be a good candidate.
I intend to keep an eye out for applications of MDL to _other_ learning models, as well.

##### References

<a name="cite1"</a>
[1] ["Novelty Detection Using Extreme Value Statistics"](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.49.1338&rep=rep1&type=pdf); Stephen J. Roberts; Feb 23, 1999
<a name="cite2"</a>
[2] ["Learning the k in k-means. Advances in neural information processing systems"](http://papers.nips.cc/paper/2526-learning-the-k-in-k-means.pdf); Hamerly, G., & Elkan, C.; 2004
