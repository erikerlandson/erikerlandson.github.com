---
layout: post
title: "Rethinking the Semantics of Group Quotas and Slot Weights: Computing Claim Capacity from Consumption Policy"
date: 2012-11-26 13:52
comments: true
tags: [ computing, htcondor, accounting groups, group quotas, slot weights, claim capacity, consumption policy ]
---
In two previous posts, I made a case to motivate the need for a better definition of slot weights and group quotas that could accommodate use cases involving aggregate resources (partitionable slots) with heterogeneous consumption policies and also provide a principled unit analysis for weights and quotas.  These previous posts can be viewed here:

* [Rethinking the Semantics of Group Quotas and Slot Weights for Heterogeneous and Multidimensional Compute Resources](http://erikerlandson.github.com/blog/2012/11/13/rethinking-the-semantics-of-group-quotas-and-slot-weights-for-heterogeneous-and-multidimensional-compute-resources/)
* [Rethinking the Semantics of Group Quotas and Slot Weights: Claim Capacity Model](http://erikerlandson.github.com/blog/2012/11/15/rethinking-the-semantics-of-group-quotas-and-slot-weights-claim-capacity-model/)

As previously mentioned, a Claim Capacity Model of accounting group quotas and slot weights (or "resource consumption costs") requires a resource claiming model that assigns a well defined finite value for the maximum number of claims that each resource and its consumption policy can support.  It must also be re-evaluatable on a resource as its assets are consumed, so that the cost of a proposed claim (or match, in negotiation-speak) can be defined as W(R) - W(R'), were R' embodies the amounts of all assets remaining after the claim has taken its share.  (Here, I will be using the term 'assets' to refer to quantities such as cpus, memory, disk, swap or any [extensible resources](http://spinningmatt.wordpress.com/2012/11/19/extensible-machine-resources/) defined, to clarify the difference between an aggregate resource (i.e. a partitionable slot) versus a single resource dimension such as cpus, memory, etc).

This almost immediately raises the question of how best to define such a resource claiming model.  In this post I will briefly describe a few possible approaches, focusing on models which are easy reason about, easy to configure and additionally allow claim capacity for a resource - W(R) - to be computed automatically for the user, thus making a sane relationship between consumption policies and consumption costs possible to enforce.

### Approach 1: fixed claim consumption model
The simplest-possible approach is arguably to just directly configure a fixed number, M, of claims attached to a resource.  In this model, each match of a job against a resource consumes one of the M claims.   Here, match cost W(R) - W(R') = 1 in all cases, and is independent of the 'size' of assets consumed from a resource.

A possible use case for such a model is that one might wish to declare that a resource can run up to a certain number of jobs, without assigning any particular cost to consuming individual assets.  If the pool users' workload consists of large numbers of resource-cheap jobs that can effectively share cpu, memory, etc, then such a model might be a good fit.

### Approach 2: configure asset quantization levels
Another approach that makes the relation between consumption policy and claim capacity easy to think about is to configure a quantization level for each resource asset.  For example, here we might quantize memory into 20 levels, i.e. Q(memory) = 20.  Similarly we might define Q(cpus) = 10 (note that HTCondor does not currently handle fractional cpus on resources, but this kind of model would benefit if floating point asset fractions were supported).  At any time, a resource R has some number q(a) left of the original Q(a).  A job requests an amount r(a) for asset (a).   Here, a claim gets a quantized approximation of any requested asset = V(a)(n(a)/Q(a)), where V(a) is the total original value available for asset (a), and n(a) = ceiling(r(a)Q(a)/V(a)).   Here there are two possible sub-policies.  If we demand that each claim consume >= 1 quantum of every asset (i.e. n(a) >= 1), then the claim capacity W(R) is the minimum of q(a), for (a) over all assets.  However, if a claim is allowed to consume a zero quantity of some individual assets (n(a)=0), then the claim capacity is the *maximum* of the q(a).   In this case, one must address the corner case of a claim attempting to consume (n(a)=0) over all assets.  The resulting resource R' has q'(a) = q(a)-n(a), and W(R') is the minium (or maximum) over the new q'(a).

### Approach 3: configure minimum asset charges
A third approach is to configure a *minimum* amount of each asset that any claim must be charged.   For example, we might define a minimum amount of memory C(memory) to charge any claim.   If a job requests an amount r(a), it will always receive max(r(a), C(a)).  As above, q(a) is the number of quanta currently available for asset (a).  Let v(a) be the amount of (a) currently available.  Here we define q(a) for an asset (a) to be floor(v(a)/C(a)).   If we adhere to a reasonable restriction that C(a) must be strictly > 0 for all (a), we are guaranteed a well defined W(R) = min over the q(a).

It is an open question which of these models (or some other completely different options) should be supported.  Conceivably all of them could be provided as options.  

Currently my personal preference leans toward Approach 3.  It is easy to reason about and configure.  It yields a well defined W(R) in all circumstances, with no corner cases, that is straightforward to compute and enforce automatically.  It is easy to configure heterogeneous consumption policies that cost different resource assets in different ways, simply by tuning minimum charge C(a) appropriately for each asset.  This includes claim capacity models where jobs are assumed to use very small amounts of any resource, including fractional shares of cpu assets.
