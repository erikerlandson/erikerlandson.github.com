---
layout: post
title: "Configuring Minimum and Maximum Resources for Mission Critical Jobs in a Condor Pool"
date: 2012-07-10 15:49
comments: true
categories: [ computing, condor, resources, preemption policy, accounting groups, concurrency limits, slot types, condor negotiator, grid computing, MRG Grid, Red Hat ]
---

Suppose you are administering a Condor pool for a company or organization where you want to support both "mission critical" (MC) jobs and "regular" (R) jobs.  Mission critical jobs might include IT functions such as backups, or payroll, or experiment submissions from high profile internal customers.  Regular jobs encompass any jobs that can be delayed, or preempted, with little or no consequence.

As part of your Condor policy for supporting MC jobs, you may want to ensure that these jobs always have access to a minimum set of resources on the pool.  In order to maintain the peace, you may also wish to set a pool-wide maximum on MC jobs, to leave some number of resources available for R jobs as well.  The following configuration, which I will discuss and demonstrate below, configures a pool-wide minimum _and maximum_ for resources allocated to MC jobs.  Additionally, it shows how to dedicate MC resources on specific nodes in the pool.

    # turn off scheduler optimizations, as they can sometimes obscure the
    # negotiator/matchmaker behavior
    CLAIM_WORKLIFE = 0
    
    # turn off adaptive loops in negotiation - these give a single
    # 'traditional' one-pass negotiation cycle
    GROUP_QUOTA_MAX_ALLOCATION_ROUNDS = 1
    GROUP_QUOTA_ROUND_ROBIN_RATE = 1e100
    
    # for demonstration purposes, make sure basic preemption knobs are 'on'
    MAXJOBRETIREMENTTIME = 0
    PREEMPTION_REQUIREMENTS = True
    NEGOTIATOR_CONSIDER_PREEMPTION = True
    RANK = 0.0
    
    # extracts the acct group name, e.g. "MC.user@localdomain" --> "MC"
    SUBMIT_EXPRS = AcctGroupName CCLimits
    AcctGroupName = ifThenElse(my.AccountingGroup =!= undefined, \
                               regexps("^([^@]+)\.[^.]+", my.AccountingGroup, "\1"), "<none>")
    CCLimits = ifThenElse(my.ConcurrencyLimits isnt undefined, \
                          my.ConcurrencyLimits, "***")
    # note - the "my." scoping in the above is important - 
    # these attribute names may also occur in a machine ad
    
    # oversubscribe the machine to simulate 20 nodes on a single box
    NUM_CPUS = 20
    
    # accounting groups, each with equal quota
    # Mission Critical jobs are associated with group 'MC'
    # Regular jobs are associated with group 'R'
    GROUP_NAMES = MC, R
    GROUP_QUOTA_MC = 10
    GROUP_QUOTA_R = 10
    
    # enable 'autoregroup' for groups, which gives all grps
    # a chance to compete for resources above their quota
    GROUP_AUTOREGROUP = TRUE
    GROUP_ACCEPT_SURPLUS = FALSE
    
    # a pool-wide limit on MC job resources
    # note this is a "hard" limit - with this example config, MC jobs cannot exceed this
    # limit even if there are free resources
    MC_JOB_LIMIT = 15
    
    # special slot for MC jobs, effectively reserves
    # specific resources for MC jobs on a particular node.
    SLOT_TYPE_1 = cpus=1
    SLOT_TYPE_1_PARTITIONABLE = FALSE
    NUM_SLOTS_TYPE_1 = 5
    
    # Allocate any "non-MC" remainders here:
    SLOT_TYPE_2 = cpus=1
    SLOT_TYPE_2_PARTITIONABLE = FALSE
    NUM_SLOTS_TYPE_2 = 15
    
    # note - in the above, I declared static slots for the purposes of 
    # demonstration, because partitionable slots interfere with clarity of
    # APPEND_RANK expr behavior, due to being peeled off 1 slot at a time
    # in the negotiation cycle
    
    # A job counts against MC_JOB_LIMIT if and only if it is of the "MC" 
    # accounting group, otherwise it won't be run
    START = ($(START)) && (((AcctGroupName =?= "MC") && (stringListIMember("mc_job", CCLimits))) \
                  || ((AcctGroupName =!= "MC") && !stringListIMember("mc_job", CCLimits)))
    
    # rank from the slot's POV:
    # "MC-reserved" slots (slot type 1) prefer MC jobs,
    # while other slots have no preference
    RANK = ($(RANK)) + 10.0*ifThenElse((SlotTypeID=?=1) || (SlotTypeID=?=-1), \
                                       1.0 * (AcctGroupName =?= "MC"), 0.0)
    
    # rank from the job's POV:
    # "MC" jobs prefer any specially allocated per-node resources
    # any other jobs prefer other jobs
    APPEND_RANK = 10.0*ifThenElse(AcctGroupName =?= "MC", \
                  1.0*((SlotTypeID=?=1) || (SlotTypeID=?=-1)), \
                  1.0*((SlotTypeID=!=1) && (SlotTypeID=!=-1)))
    
    # If a job negotiated under "MC", it may not be preempted by a job that did not.
    PREEMPTION_REQUIREMENTS = ($(PREEMPTION_REQUIREMENTS)) && \
                              ((SubmitterNegotiatingGroup =?= "MC") || \
                               (RemoteNegotiatingGroup =!= "MC"))


Next I will discuss some of the components from this configuration and their purpose.  The first goal of a pool-wide resource minimum is accomplished by declaring accounting groups for MC and R jobs to run against:

    GROUP_NAMES = MC, R
    GROUP_QUOTA_MC = 10
    GROUP_QUOTA_R = 10

We will enable the autoregroup feature, which allows jobs to also compete for any unused resources _without_ regard for accounting groups, after all jobs have had an opportunity to match under their group.  This is a good way to allow opportunistic resource usage, and also will facilitate demonstration.

    GROUP_AUTOREGROUP = TRUE

A pool-wide maximum on resource usage by MC jobs can be accomplished with a concurrency limit.  Note that this limit is larger than the group quota for MC jobs:

    MC_JOB_LIMIT = 15

It is also desirable to enforce the semantic that MC jobs _must_ 'charge' against the MC_JOB concurrency limit, and conversely that any non-MC jobs are not allowed to charge against that limit.   Adding the following clause to the START expression enforces this semantic by preventing any jobs not following this rule from running:

    START = ($(START)) && (((AcctGroupName =?= "MC") && (stringListIMember("mc_job", CCLimits))) \
                        || ((AcctGroupName =!= "MC") && !stringListIMember("mc_job", CCLimits)))

The final resource related goal for MC jobs is to reserve a certain number of resources on specific machines in the pool.  In the configuration above that is accomplished by declaring a special slot type, as here where we declare 5 slots of slot type 1 (the remaining 15 slots are declared via slot type 2, above):

    SLOT_TYPE_1 = cpus=1
    SLOT_TYPE_1_PARTITIONABLE = FALSE
    NUM_SLOTS_TYPE_1 = 5

Then we add a term to the slot rank expression that will cause any slot of type 1 to preempt a non-MC job in favor of an MC job (the factor of 10.0 is an optional tuning factor to allow this term to either take priority over other terms, or cede priority):

    RANK = ($(RANK)) + 10.0*ifThenElse((SlotTypeID=?=1) || (SlotTypeID=?=-1), \
                                       1.0 * (AcctGroupName =?= "MC"), 0.0)

(Note, slot type -1 would represent a dynamic slot derived from a partitionable slot of type 1.  In this example, all slots are static)

An additional "job side" rank term can also be helpful, to allow MC jobs to try and match special MC reserved slots first, and to allow non-MC jobs to avoid reserved slots if possible:

    APPEND_RANK = 10.0*ifThenElse(AcctGroupName =?= "MC", \
                  1.0*((SlotTypeID=?=1) || (SlotTypeID=?=-1)), \
                  1.0*((SlotTypeID=!=1) && (SlotTypeID=!=-1)))

Lastly, preemption policy can be configured to help enforce resource allocations for MC jobs.  Here, a preemption clause is added to prevent any non-MC job from preempting a MC job, and specifically one that _negotiated_ under its group quota (that is, it refers to RemoteNegotiatingGroup):

    PREEMPTION_REQUIREMENTS = ($(PREEMPTION_REQUIREMENTS)) && \
                              ((SubmitterNegotiatingGroup =?= "MC") || \
                               (RemoteNegotiatingGroup =!= "MC"))

With the example policy configuration unpacked, we can demonstrate its behavior.  Begin by spinning up a pool with the above configuration.  Verify that we have the expected slots (You can refer [here to learn more about cchist](http://erikerlandson.github.com/blog/2012/06/29/easy-histograms-and-tables-from-condor-jobs-and-slots/)):

    $ cchist condor_status RemoteGroup RemoteNegotiatingGroup SlotTypeID
          5 undefined | undefined | 1
         15 undefined | undefined | 2
         20 total

Next, submit 20 Mission Critical jobs (getting enough sleep is critical):

    universe = vanilla
    cmd = /bin/sleep
    args = 600
    should_transfer_files = if_needed
    when_to_transfer_output = on_exit
    concurrency_limits = mc_job
    +AccountingGroup="MC.user"
    queue 20

Since we configured a pool-wide maximum of 15 cores, we want to verify that we did not exceed that limit.  Note that 5 slots were negotiated under "\<none\>", via the autoregroup feature (denoted by the value in RemoteNegotiatingGroup), as the group quota for MC is 10, and the MC jobs were able to match their pool limit of 15:

    $ cchist condor_status RemoteGroup RemoteNegotiatingGroup SlotTypeID
          5 MC | MC | 1
          5 MC | MC | 2
          5 MC | <none> | 2
          5 undefined | undefined | 2
         20 total

Next we set the MC submitter to a lower priority (i.e. higher prio value):

    $ condor_userprio -setprio MC.user@localdomain 10
    The priority of MC.user@localdomain was set to 10.000000

Now we submit 15 "regular" R jobs:

    universe = vanilla
    cmd = /bin/sleep
    args = 600
    should_transfer_files = if_needed
    when_to_transfer_output = on_exit
    +AccountingGroup="R.user"
    queue 15

The submitter "R.user" currently has higher priority than "MC.user", however our preemption policy will only allow preemption of MC jobs that negotiated under "\<none\>", as those were matched outside the accounting group's quota.  So we see that jobs with RemoteNegotiatingGroup == "MC" remain un-preempted:

    $ cchist condor_status RemoteGroup RemoteNegotiatingGroup SlotTypeID
          5 MC | MC | 1
          5 MC | MC | 2
         10 R | R | 2
         20 total

The above demonstrates the pool-wide quota and concurrentcy limits for MC jobs.  To demonstrate per-machine resources, we start by clearing all jobs:

    $ condor_rm -all

Submit 20 "R" jobs (similar to above), and verify that they occupy all slots, including the slots with SlotTypeID == 1, which are reserved for MC jobs (but not currently being used):

    $ cchist condor_status RemoteGroup RemoteNegotiatingGroup SlotTypeID
          5 R | <none> | 1
          5 R | <none> | 2
         10 R | R | 2
         20 total

Submit 10 MC jobs.  "MC.user" does not have sufficient priority to preempt "R.user", however the slot rank expression _will_ preempt non-MC jobs for an MC job on slots of type 1, and so we see that MC jobs _do_ acquire the 5 type-1 slots reserved on this node:

    $ cchist condor_status RemoteGroup RemoteNegotiatingGroup SlotTypeID
          5 MC | MC | 1
          5 R | <none> | 2
         10 R | R | 2
         20 total

Finally, as an encore you can verify that jobs run against the MC accounting group must also charge against the MC_JOB concurrency limit, and non-MC jobs may not charge against it.  Again, start with an empty queue:

    $ condor_rm -all

Now, submit 'bad' jobs that use accounting group "MC" but does not use the "mc_job" concurrency limits:

    universe = vanilla
    cmd = /bin/sleep
    args = 600
    should_transfer_files = if_needed
    when_to_transfer_output = on_exit
    +AccountingGroup="MC.user"
    queue 10

And likewise some 'bad' regular jobs that attempt to use the "mc_job" concurrency limits:

    universe = vanilla
    cmd = /bin/sleep
    args = 600
    should_transfer_files = if_needed
    when_to_transfer_output = on_exit
    concurrency_limits = mc_job
    +AccountingGroup="R.user"
    queue 10

You should see that *none* of these jobs are allowed to run:

    $ cchist condor_status RemoteGroup RemoteNegotiatingGroup SlotTypeID
          5 undefined | undefined | 1
         15 undefined | undefined | 2
         20 total
    $ cchist condor_q JobStatus
         20 1
         20 total
