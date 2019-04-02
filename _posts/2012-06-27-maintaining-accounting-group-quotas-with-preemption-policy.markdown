---
layout: post
title: "Maintaining Accounting Group Quotas With Preemption Policy"
date: 2012-06-27 20:33
comments: true
tags: [ condor, computing, preemption policy, accounting groups, grid computing, MRG Grid, Red Hat ]
---

There is a straightforward technique to leverage a Condor [preemption policy](http://research.cs.wisc.edu/condor/manual/v7.8/3_3Configuration.html#20480) to direct preemptions in a way that helps maintain resource usages as close as possible to the defined [accounting group quotas](http://research.cs.wisc.edu/condor/manual/v7.8/3_4User_Priorities.html#SECTION00447000000000000000).

I will begin by simply giving the configuration and then describe how it works, with a short demonstration.  The actual configuration is simply a clause that can be added to the preemption policy defined by `PREEMPTION_REQUIREMENTS`:

    PREEMPTION_REQUIREMENTS = $(PREEMPTION_REQUIREMENTS) && (((SubmitterGroupResourcesInUse < SubmitterGroupQuota) && (RemoteGroupResourcesInUse > RemoteGroupQuota)) || (SubmitterGroup =?= RemoteGroup))

Unpacking the above logic: the term `(SubmitterGroupResourcesInUse < SubmitterGroupQuota)` captures the idea that to best maintain quota-driven resource usage, we only want to allow preemption if the submitting accounting group has not yet reached its quota, as acquiring more resources moves the usage closer to the group's quota.  Conversely, if the accounting group's resource usage is _already_ at or above its quota, acquiring more resources via preemption will only drive the usage _farther_ from the configured quota.

The term `(RemoteGroupResourcesInUse > RemoteGroupQuota)` captures a similar idea from the 'remote' side (the candidate for preemption).  Provided the remote's resource usage is greater than its quota, allowing preemption will move its usage closer to the configured quota.

The last term `(SubmitterGroup =?= RemoteGroup)` (a disjunction) ensures that with an accounting group preemption may always occur, deferring to any other clauses in the expression.

A brief aside: in the following example, I use the 'svhist' bash function for ease and clarity.  For example, the command `svhist AccountingGroup State Activity` is shorthand for: `condor_status -format "%s" 'AccountingGroup' -format " | %s" 'State' -format " | %s\n" 'Activity' -constraint 'True' | sort | uniq -c | awk '{ print $0; t += $1 } END { printf("%7d total\n",t) }'`  The svhist command is available [here](https://github.com/erikerlandson/bash_condor_tools).


To demonstrate this preemption policy, consider the following example configuration:

    # turn off scheduler optimizations, as they can sometimes obscure the
    # negotiator/matchmaker behavior
    CLAIM_WORKLIFE = 0
    
    # for demonstration purposes, make sure basic preemption knobs are 'on'
    MAXJOBRETIREMENTTIME = 0
    PREEMPTION_REQUIREMENTS = True
    NEGOTIATOR_CONSIDER_PREEMPTION = True
    
    NUM_CPUS = 15
    
    # 3 accounting groups, each with equal quota
    GROUP_NAMES = A, B, C
    GROUP_QUOTA_A = 5
    GROUP_QUOTA_B = 5
    GROUP_QUOTA_C = 5
    
    # groups may use each others' surplus
    GROUP_ACCEPT_SURPLUS = TRUE
    # (an alternative way for groups to acquire surplus is to enable GROUP_AUTOREGROUP)
    # GROUP_AUTOREGROUP = TRUE
    
    # A preepmption policy clause that only allows preemptions that move usages closer to configured quotas
    PREEMPTION_REQUIREMENTS = $(PREEMPTION_REQUIREMENTS) && (((SubmitterGroupResourcesInUse < SubmitterGroupQuota) && (RemoteGroupResourcesInUse > RemoteGroupQuota)) || (SubmitterGroup =?= RemoteGroup))


Begin by submitting 5 jobs to accounting group A, and 10 jobs to group B:

    universe = vanilla
    cmd = /bin/sleep
    args = 3600
    should_transfer_files = if_needed
    when_to_transfer_output = on_exit
    +AccountingGroup="A.user"
    queue 5
    +AccountingGroup="B.user"
    queue 10

Confirm that group B's resource usage is 10 (note, this is over its quota of 5):

    $ svhist AccountingGroup State Activity
          5 A.user@localdomain | Claimed | Busy
         10 B.user@localdomain | Claimed | Busy
         15 total

Now set submitter priorities to allow preemption, provided preemption policy supports it

    $ condor_userprio -setprio A.user@localdomain 10
    The priority of A.user@localdomain was set to 10.000000
    $ condor_userprio -setprio B.user@localdomain 10
    The priority of B.user@localdomain was set to 10.000000

Now submit 10 jobs to group C.

    universe = vanilla
    cmd = /bin/sleep
    args = 3600
    should_transfer_files = if_needed
    when_to_transfer_output = on_exit
    +AccountingGroup="C.user"
    queue 10

Finally, we verify that our preemption policy drove the resource usages to quota:

    $ svhist AccountingGroup State Activity
          5 A.user@localdomain | Claimed | Busy
          5 B.user@localdomain | Claimed | Busy
          5 C.user@localdomain | Claimed | Busy
         15 total
