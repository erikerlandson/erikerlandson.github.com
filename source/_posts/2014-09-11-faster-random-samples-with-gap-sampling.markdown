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
            if p < random(0.0, 1.0) then emit v to output
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
<tr> <td>Array</td> <td>0.001</td> <td>2784</td> <td>8</td> </tr>
<tr> <td>Array</td> <td>0.01</td> <td>2817</td> <td>77</td> </tr>
<tr> <td>Array</td> <td>0.1</td> <td>3075</td> <td>686</td> </tr>
<tr> <td>Array</td> <td>0.5</td> <td>4221</td> <td>3756</td> </tr>
<tr> <td>List</td> <td>0.001</td> <td>2662</td> <td>238</td> </tr>
<tr> <td>List</td> <td>0.01</td> <td>2662</td> <td>298</td> </tr>
<tr> <td>List</td> <td>0.1</td> <td>2936</td> <td>301</td> </tr>
<tr> <td>List</td> <td>0.5</td> <td>3995</td> <td>305</td> </tr>
</table>

<br>
In the results above, we see that for the Array data the gap sampling times are linear in (p) -- Arrays are random access, and the operation of skipping sample-gaps is constant time.   Gap sampling on random access data allows marked improvement with small sampling probabities, where there are large sampling gaps that can be skipped in constant time.  The List data timings reflect that the sampling traverses all elements in either case.  The time savings here is due to reduced calls to the RNG.

Note that while the gap sampling numbers for Array are better than linear sampling, they show signs of gaining on the linear sampling times.  I will touch on this again at the end of the post.

The gap-sampling algorithm described above is for sampling *without* replacement.   However, the same approach can be modified to generate sampling *with* replacement.   

When sampling with replacement, it is useful to consider the *replication factor* of each element (where a replication factor of zero means the element wasn't sampled).  Pretend for the moment that the actual data size (n) is known.  The sample size (m) = (n)(p).  The probability that each element gets sampled, per trial, is 1/n, with (m) independent trials, and so the replication factor (r) for each element obeys a binomial distribution: Binomial(m, 1/n).  If we substitute (n)(p) for (m), we have Binomial(np, 1/n).  As the (n) grows, the Binomial is [well approximated by a Poisson distribution](http://en.wikipedia.org/wiki/Binomial_distribution#Poisson_approximation) Poisson(L), where (L) = (np)(1/n) = (p).  And so for our purposes we may sample from Poisson(p), where P(r) = (p^k / k!)e^(-p), for our sampling replication factors.  Note that we have now discarded any dependence on sample size (n), as we desire.

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
<tr> <td>Array</td> <td>0.001</td> <td>1635</td> <td>12</td> </tr>
<tr> <td>Array</td> <td>0.01</td> <td>1807</td> <td>130</td> </tr>
<tr> <td>Array</td> <td>0.1</td> <td>2087</td> <td>1101</td> </tr>
<tr> <td>Array</td> <td>0.5</td> <td>3258</td> <td>4733</td> </tr>
<tr> <td>List</td> <td>0.001</td> <td>1341</td> <td>233</td> </tr>
<tr> <td>List</td> <td>0.01</td> <td>1400</td> <td>411</td> </tr>
<tr> <td>List</td> <td>0.1</td> <td>1729</td> <td>472</td> </tr>
<tr> <td>List</td> <td>0.5</td> <td>3342</td> <td>361</td> </tr>
</table>

<br>
The table above shows that there is a crossover point in the Array timings where gap sampling costs more time than linear sampling.  Although the random access in Scala Array allows for increasing improvements as sampling probability grows small, there appears to be an increased cost factor that allows for the crossover point.  This is a subject for further investigation, but may have to do with allocation cost of Array iterator data structures in Scala.
