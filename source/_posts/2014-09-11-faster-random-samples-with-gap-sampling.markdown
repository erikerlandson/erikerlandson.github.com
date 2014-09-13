---
layout: post
title: "Faster Random Samples With Gap Sampling"
date: 2014-09-11 07:57
comments: true
categories: [ computing, scala, spark, sampling, random sampling ]
---
Generating a random sample of a collection is, logically, a O(np) operation, where (n) is the sample size and (p) is the sampling probability.  For example, extracting a random sample, without replacement, from an array might look like this in pseudocode:

    sample(data: array, p: real) {
        n = length(data)
        m = floor(p * n)
        for j = 0 to m-1 {
            k = random(j, n-1)
            swap(data[j], data[k])
        }
        emit the first m elements of 'data' to output
    }

We can see that this sampling algorithm is indeed O(np).  However, it makes some nontrivial assumptions about its input data:

* It is random access
* It is writable
* Its size is known
* It can be destructively modified

These assumptions can be violated in several ways.  The input data might not support random access, for example it might be a list, or stream, or an iterator over the same.  We might not know its size a priori.  It might be read-only.  It might be up-cast to some superclass where knowledge about these assumed properties is no longer available.

In cases such as this, there is another common sampling algorithm:

    sample(data: sequence, p: real) {
        while not end(data) {
            v = next(data)
            if random(0.0, 1.0) < p then emit v to output
        }
    }

The above algorithm enjoys all the advantage in flexibility.  It requires only linear access, does not require writable input, and makes no assumptions about input size.  However it comes at a price: this algorithm is no longer O(np), it is O(n).  Each element must be traversed directly, and worse yet the random number generagor (RNG) must be invoked on each element.  O(n) invocation of the RNG is a substantial cost -- random number generation is typically very expensive compared to the cost of iterating to the next element in a sequence.

But... does linear sampling truly require us to invoke our RNG on every element?   Consider the pattern of data access, divorced from code.   It looks like a sequence of choices: for each element we either (skip) or (sample):

    (skip) (skip) (sample) (skip) (sample) (skip) (sample) (sample) (skip) (skip) (sample) ...

The number of consecutive (skip) events between each (sample) -- the *sampling gap* -- can itself be modeled as a random variable.  Each (skip)/(sample) choice is an independent Bernoulli trial, where the probability of (skip) is (1-p).   The PMF of the sampling gap for gap of {0, 1, 2, ...} is therefore the geometric distribution parameterized by (p):  P(k) = p(1-p)^k

This suggests an alternative algorithm for sampling, where we only need to randomly choose sample gaps instead of randomly choosing whether we sample each individual element:

    // choose a random sampling gap 'k' from P(k) = p(1-p)^k
    // caution: this explodes for p = 0 or p = 1
    random_gap(p: real) {
        u = max(random(0.0, 1.0), epsilon)
        return floor(log(u) / log(1-p))
    }

    sample(data: sequence, p: real) {
        advance(data, random_gap(p))
        while not end(data) {
            emit next(data) to output
            advance(data, random_gap(p))
        }
    }

The above algorithm calls the RNG only once per actual collected sample, and so the cost of RNG calls is O(np).  Note that the algorithm is still O(n), but the cost of the RNG tends to dominate the cost of sequence traversal, and so the resulting efficiency improvement is substantial.  I measured the following performance improvements with gap sampling, compared to traditional linear sequence sampling, on a [Scala prototype testing rig](https://gist.github.com/erikerlandson/05db1f15c8d623448ff6):

<head><style>
table, th, td {
border: 1px solid black;
border-collapse: collapse;
}
th, td {
padding: 10px;
}
th {
text-align: center;
}
</style></head>

<table>
<tr> <th>Type</th> <th>p</th> <th>linear</th> <th>gap</th> </tr>
<tr> <td>Array</td> <td>0.001</td> <td>2833</td> <td>29</td> </tr>
<tr> <td>Array</td> <td>0.01</td> <td>2825</td> <td>76</td> </tr>
<tr> <td>Array</td> <td>0.1</td> <td>2985</td> <td>787</td> </tr>
<tr> <td>Array</td> <td>0.5</td> <td>3526</td> <td>3478</td> </tr>
<tr> <td>Array</td> <td>0.9</td> <td>3023</td> <td>6081</td> </tr>
<tr> <td>List</td> <td>0.001</td> <td>2213</td> <td>230</td> </tr>
<tr> <td>List</td> <td>0.01</td> <td>2220</td> <td>265</td> </tr>
<tr> <td>List</td> <td>0.1</td> <td>2337</td> <td>796</td> </tr>
<tr> <td>List</td> <td>0.5</td> <td>2794</td> <td>3151</td> </tr>
<tr> <td>List</td> <td>0.9</td> <td>2513</td> <td>4849</td> </tr>
</table>

<br>
In the results above, we see that the gap sampling times are essentially linear in (p), as expected.  In the case of the linear-access List type, there is a higher baseline time (230 vs 29) due to the constant cost of actual data traversal.  Efficiency improvements are substantial at small sampling probabilities.

We can also see that the cost of gap sampling begins to meet and then exceed the cost of traditinal linear sampling, in the vicinnity (p) = 0.5.  This is due to the fact that the gap sampling logic is about twice the cost (in my test environment) of simply calling the RNG once.  For example, the gap sampling invokes a call to the numeric logarithm code that isn't required in traditional sampling.  And so at (p) = 0.5 the time spent doing the gap sampling approximates the time spent invoking the RNG once per sample, and at higher values of (p) the cost is greater.

This suggests that one should in fact fall back to traditional linear sampling when the sampling probability (p) >= some threshold.  That threshold appears to be about 0.5 or 0.6 in my testing rig, but is likely to depend on underlying numeric libraries, the particular RNG being used, etc, and so I would expect it to benefit from customized tuning on a per-environment basis.  With this in mind, a sample algorithm as deployed would look like this:

    // threshold is a tuning parameter
    threshold = 0.5

    sample(data: sequence, p: real) {
        if (p < threshold) {
            gap_sample(data, p)
        } else {
            traditional_linear_sample(data, p)
        }
    }

The gap-sampling algorithm described above is for sampling *without* replacement.   However, the same approach can be modified to generate sampling *with* replacement.   

When sampling with replacement, it is useful to consider the *replication factor* of each element (where a replication factor of zero means the element wasn't sampled).  Pretend for the moment that the actual data size (n) is known.  The sample size (m) = (n)(p).  The probability that each element gets sampled, per trial, is 1/n, with (m) independent trials, and so the replication factor (r) for each element obeys a binomial distribution: Binomial(m, 1/n).  If we substitute (n)(p) for (m), we have Binomial(np, 1/n).  As the (n) grows, the Binomial is [well approximated by a Poisson distribution](http://en.wikipedia.org/wiki/Binomial_distribution#Poisson_approximation) Poisson(L), where (L) = (np)(1/n) = (p).  And so for our purposes we may sample from Poisson(p), where P(r) = (p^r / r!)e^(-p), for our sampling replication factors.  Note that we have now discarded any dependence on sample size (n), as we desire.

In our gap-sampling context, the sampling gaps are now elements whose replication factor is zero, which occurs with probability P(0) = e^(-p).  And so our sampling gaps are now drawn from geometric distribution P(k) = (1-q)(q)^k, where q = e^(-p).   When we *do* sample an element, its replication factor is drawn from Poisson(p), however *conditioned such that the value is >= 1.*  It is straightforward to adapt a [standard Poisson generator](http://en.wikipedia.org/wiki/Poisson_distribution#Generating_Poisson-distributed_random_variables), as shown below.

Given the above, gap sampling with replacement in pseudocode looks like:

    // sample 'k' from Poisson(p), conditioned to k >= 1
    poisson_ge1(p: real) {
        q = e^(-p)
        // simulate a poisson trial such that k >= 1
        t = q + (1-q)*random(0.0, 1.0)
        k = 1

        // continue standard poisson generation trials
        t = t * random(0.0, 1.0)
        while (t > q) {
            k = k + 1
            t = t * random(0.0, 1.0)
        }
        return k
    }

    // choose a random sampling gap 'k' from P(k) = p(1-p)^k
    // caution: this explodes for p = 0 or p = 1
    random_gap(p: real) {
        u = max(random(0.0, 1.0), epsilon)
        return floor(log(u) / -p)
    }

    sample(data: sequence, p: real) {
        advance(data, random_gap(p))
        while not end(data) {
            rf = poisson_ge1(p)
            v = next(data)
            emit (rf) copies of (v) to output
            advance(data, random_gap(p))
        }
    }

The efficiency improvements I have measured for gap sampling with replacement are shown here:

<table>
<tr> <th>Type</th> <th>p</th> <th>linear</th> <th>gap</th> </tr>
<tr> <td>Array</td> <td>0.001</td> <td>2604</td> <td>45</td> </tr>
<tr> <td>Array</td> <td>0.01</td> <td>3442</td> <td>117</td> </tr>
<tr> <td>Array</td> <td>0.1</td> <td>3653</td> <td>1044</td> </tr>
<tr> <td>Array</td> <td>0.5</td> <td>5643</td> <td>5073</td> </tr>
<tr> <td>Array</td> <td>0.9</td> <td>7668</td> <td>8388</td> </tr>
<tr> <td>List</td> <td>0.001</td> <td>2431</td> <td>233</td> </tr>
<tr> <td>List</td> <td>0.01</td> <td>2450</td> <td>299</td> </tr>
<tr> <td>List</td> <td>0.1</td> <td>2984</td> <td>1330</td> </tr>
<tr> <td>List</td> <td>0.5</td> <td>5331</td> <td>4752</td> </tr>
<tr> <td>List</td> <td>0.9</td> <td>6744</td> <td>7811</td> </tr>
</table>

<br>
As with the results for sampling without replacement, we see that gap sampling cost is linear with (p), which yields large cost savings at small sampling, but begins to exceed traditional linear sampling at higher sampling probabilities.
