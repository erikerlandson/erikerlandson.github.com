---
layout: post
title: "The Joy of Anonymized Data"
date: 2012-05-20 11:31
comments: true
tags: [computing, machine learning]
---
I've been fooling around with an [anonymized data set](https://github.com/erikerlandson/ratorade/tree/master/data) on the side.  Although this can be frustrating in its own way, it occurred to me that it _does_ have the advantage of forcing me to see the data in the same way my algorithms see it: that is, the data is just some anonymous strings, values and identifiers.  To the code, strings like "120 minute IPA" or "Dogfish Head Brewery" have no more significance than "Beer-12" or "Brewer-5317", and the anonymous identifiers remove any subconscious or conscious tendencies of mine to impart more meaning to an identifier string than is present to the algorithms.

On the other hand, having anonymous identifiers prevents me from drawing any actual inspirations for utilizing semantics that _might_ genuinely be leveragable by an algorithm.  However, my current goal is to produce tools that are generically useful across data domains.  In that respect, I think developing on anonymized data could actually be helping.  Time will tell.
