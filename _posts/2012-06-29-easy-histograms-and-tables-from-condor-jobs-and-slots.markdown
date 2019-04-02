---
layout: post
title: "Easy Histograms and Tables from Condor Jobs and Slots"
date: 2012-06-29 09:46
comments: true
tags: [ computing, condor, condor jobs, condor slots, condor_q, condor_status, condor_history, classads, histogram, grid computing, MRG Grid, Red Hat ]
---

Several [Condor](http://research.cs.wisc.edu/condor/) commands, including condor_status, condor_q and condor_history, provide a nice feature for outputting formatted subsets of classad attributes: the `-format <format> <attr>` option.  In this post, I assume basic familiarity with `-format`.  You can read more [here](http://research.cs.wisc.edu/condor/manual/v7.8/condor_status.html#SECTION0011453000000000000000)

The `-format` option can be used to generate tables and histograms of attributes, in a classic 'unix one-liner' fashion.  For example, supposing I wanted to use condor_status to create a nice histogram of the values for slot type, state, activity and accounting group.  I might issue a one-liner like this:

    $ condor_status -format "%s" 'ifThenElse(SlotType =!= undefined, string(SlotType), "undefined")' \
    > -format " | %s" 'ifThenElse(State =!= undefined, string(State), "undefined")' \
    > -format " | %s" 'ifThenElse(Activity =!= undefined, string(Activity), "undefined")' \
    > -format " | %s\n" 'ifThenElse(AccountingGroup =!= undefined, string(AccountingGroup), "undefined")' \
    > | sort | uniq -c | awk '{ print $0; t += $1 } END { printf("%7d total\n",t) }'
          3 Static | Claimed | Busy | A.user@localdomain
          2 Static | Claimed | Busy | B.user@localdomain
         10 Static | Unclaimed | Idle | undefined
         15 total

Note that in this command I was extra pedantic and careful about converting expressions to strings, and using the ClassAd ifThenElse to trap and handle possible undefined values (which do indeed occur for AccountingGroup, when a slot is not in use).

We can see that a lot of this would benefit from some programmatic automation.  To that end I wrote some [convenience bash functions](https://github.com/erikerlandson/bash_condor_tools) for automating the tedious portions of this process: `cchist`, `ccsort` and `ccdump`.  For example I could use `cchist` to generate the histogram from the example above much more cleanly:

    $ cchist condor_status SlotType State Activity AccountingGroup
          3 Static | Claimed | Busy | A.user@localdomain
          2 Static | Claimed | Busy | B.user@localdomain
         10 Static | Unclaimed | Idle | undefined
         15 total

The `ccdump` command simply dumps the table of values, uncollated, while `ccsort` outputs the table of values, but sorted:

    $ ccdump condor_status SlotType State Activity AccountingGroup
    Static | Claimed | Busy | A.user@localdomain
    Static | Claimed | Busy | A.user@localdomain
    Static | Claimed | Busy | B.user@localdomain
    Static | Unclaimed | Idle | undefined
    Static | Claimed | Busy | A.user@localdomain
    Static | Unclaimed | Idle | undefined
    Static | Unclaimed | Idle | undefined
    Static | Claimed | Busy | B.user@localdomain
    Static | Unclaimed | Idle | undefined
    Static | Unclaimed | Idle | undefined
    Static | Unclaimed | Idle | undefined
    Static | Unclaimed | Idle | undefined
    Static | Unclaimed | Idle | undefined
    Static | Unclaimed | Idle | undefined
    Static | Unclaimed | Idle | undefined
    $ ccsort condor_status SlotType State Activity AccountingGroup
    Static | Claimed | Busy | A.user@localdomain
    Static | Claimed | Busy | A.user@localdomain
    Static | Claimed | Busy | A.user@localdomain
    Static | Claimed | Busy | B.user@localdomain
    Static | Claimed | Busy | B.user@localdomain
    Static | Unclaimed | Idle | undefined
    Static | Unclaimed | Idle | undefined
    Static | Unclaimed | Idle | undefined
    Static | Unclaimed | Idle | undefined
    Static | Unclaimed | Idle | undefined
    Static | Unclaimed | Idle | undefined
    Static | Unclaimed | Idle | undefined
    Static | Unclaimed | Idle | undefined
    Static | Unclaimed | Idle | undefined
    Static | Unclaimed | Idle | undefined

If you are interested in providing the actual raw unix command that was executed, you can use the `-cmd` option (note, this currently must appear _first_)

    $ cchist -cmd condor_status SlotType State Activity AccountingGroup
    condor_status -format "%s" 'ifThenElse(SlotType isnt undefined, string(SlotType), "undefined")' -format " | %s" 'ifThenElse(State isnt undefined, string(State), "undefined")' -format " | %s" 'ifThenElse(Activity isnt undefined, string(Activity), "undefined")' -format " | %s\n" 'ifThenElse(AccountingGroup isnt undefined, string(AccountingGroup), "undefined")' -constraint 'True' | sort | uniq -c | awk '{ print $0; t += $1 } END { printf("%7d total\n",t) }'

As you can see, the command condor_status is a parameter.  You can also use the same commands with condor_q and condor_history:

    $ cchist condor_q AccountingGroup LastJobStatus
          3 A.user | 1
          2 B.user | 1
          5 total
    $ cchist condor_history AccountingGroup LastJobStatus
         18 A.user | 2
         26 B.user | 2
         20 C.user | 2
         64 total

You can obtain cchist and friends at the [bash_condor_tools github repo](https://github.com/erikerlandson/bash_condor_tools)

