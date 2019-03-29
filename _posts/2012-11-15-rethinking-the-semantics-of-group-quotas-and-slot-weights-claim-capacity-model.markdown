---
layout: post
title: "Rethinking the Semantics of Group Quotas and Slot Weights: Claim Capacity Model"
date: 2012-11-15 17:22
comments: true
categories: [ computing, htcondor, accounting groups, group quotas, slot weights ]
---
In my previous post about [Rethinking the Semantics of Group Quotas and Slot Weights](http://erikerlandson.github.com/blog/2012/11/13/rethinking-the-semantics-of-group-quotas-and-slot-weights-for-heterogeneous-and-multidimensional-compute-resources), I proposed a concept for unifying the semantics of accounting group quotas and slot weights across arbitrary resource allocation strategies.

My initial terminology was that the weight of a slot (i.e. resource ad) is a measure of the *maximum* number of jobs that might match against that ad, given the currently available resource quantities and the allocation policy.  The cost of a match becomes the amount by which that measure is reduced, after the match's resources are removed from the ad.

In the HTCondor vocabulary, a job acquires a *claim* on resources to actually run after it has been matched.  It has been proposed that it may be beneficial for HTCondor to evolve toward a model where there are (aggregate) resource ads, and claims against those ads, as a simplification of the current model which involves static, partitionable and dynamic slots, with claims.  With this in mind, a preferable terminology for group quota and weight semantics might be that a resource ad (or slot) has a measure of the maximum number of claims it could dispense: a *claim capacity* measure.  The cost of a claim (or match) is the corresponding reduction of the resource's claim capacity.

So, this semantic model could be referred to as the Claim Capacity Model of group quotas and slot weights.  With this terminology, the shared 'unit' for group quotas and slot weights would be *claims* instead of *jobs*.
