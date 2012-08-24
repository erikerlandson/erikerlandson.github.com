---
layout: post
title: "LIFO and FIFO Preemption Policies for a Condor Pool"
date: 2012-07-19 13:57
comments: true
categories: [ computing, condor, preemption policy, condor negotiator, grid computing, MRG Grid, Red Hat ]
---

On a Condor pool, a Last In First Out (LIFO) preemption policy favors choosing the longest-running job from the available preemption options.  Correspondingly, a First In First Out (FIFO) policy favors the most-recent job for preemption.  

Configuring a LIFO or FIFO policy is easy, using the `PREEMPTION_RANK` configuration variable.  `PREEMPTION_RANK` defines a ClassAd expression that is evaluated for all slots that are candidates for claim preemption, and causes those candidates to be sorted so that the candidates with the highest rank value are considered first.   Therefore, to implement a LIFO (or FIFO) preemption policy, one needs reference an expression that represents the claiming job's running time:

    # LIFO preemption: favor preempting jobs that have been running the longest
    PREEMPTION_RANK = TotalJobRunTime
    # turn this into FIFO by using (-TotalJobRunTime)

The attribute `TotalJobRunTime` represents the amount of time a job has been running on its claim (generally, this is effectively equivalent to total running time, unless your job supports some form of checkpointing), and so ranking preemption candidates by this attribute results in LIFO preemption, and ranking by its negative provides FIFO preemption.

Note that `PREEMPTION_RANK` applies _only_ to candidates that have already met the requirements defined on `PREEMPTION_REQUIREMENTS`, or the slot-centric preemption policy defined by `RANK`.  `PREEMPTION_RANK` does not itself determine what claimed slots are considered by a job for preemption.

To demonstrate LIFO and FIFO preemption in action, consider the following configuration:

    # turn off scheduler optimizations, as they can sometimes obscure the
    # negotiator/matchmaker behavior
    CLAIM_WORKLIFE = 0
    CLAIM_PARTITIONABLE_LEFTOVERS = False
    
    # reduce update latencies for faster testing response
    UPDATE_INTERVAL = 15
    NEGOTIATOR_INTERVAL = 20
    SCHEDD_INTERVAL = 15
    
    # for demonstration purposes, make sure basic preemption knobs are 'on'
    MAXJOBRETIREMENTTIME = 0
    PREEMPTION_REQUIREMENTS = True
    NEGOTIATOR_CONSIDER_PREEMPTION = True
    RANK = 0.0
    
    # LIFO preemption: favor preempting jobs that have been running the longest
    PREEMPTION_RANK = TotalJobRunTime
    # turn this into FIFO by using (-TotalJobRunTime)
    
    # define 3 cpus to provide fodder for preemption
    NUM_CPUS = 3

Begin by spinning up a condor pool with the configuration above.  When the pool is operating, fill the three slots with jobs for 'user1', with a delay to ensure that jobs have easily distinguishable values for `TotalJobRunTime`:

    $ cat /tmp/user1.jsub 
    universe = vanilla
    cmd = /bin/sleep
    args = 600
    should_transfer_files = if_needed
    when_to_transfer_output = on_exit
    +AccountingGroup="user1"
    queue 1
    
    $ condor_submit /tmp/user1.jsub ; sleep 30 ; condor_submit /tmp/user1.jsub ; sleep 30 ; condor_submit /tmp/user1.jsub

Once these jobs have all started running, verify their run times using [ccsort](http://erikerlandson.github.com/blog/2012/06/29/easy-histograms-and-tables-from-condor-jobs-and-slots/):

    $ ccsort condor_status JobID TotalJobRunTime AccountingGroup
    1.0 | 78 | user1@localdomain
    2.0 | 36 | user1@localdomain
    3.0 | 16 | user1@localdomain

to make preemption easy, give user1 a low priority:

    $ condor_userprio -setprio user1@localdomain 10

Now, we will submit some jobs for 'user2': which will be allowed to preempt jobs for 'user1'.  We should see that the longest-running job for user1 is chosen each time:
 
    $ condor_submit /tmp/user2.jsub
    Submitting job(s).
    1 job(s) submitted to cluster 4.
    
    $ ccsort condor_status JobID TotalJobRunTime AccountingGroup
    2.0 | 81 | user1@localdomain
    3.0 | 61 | user1@localdomain
    4.0 | 2 | user2@localdomain
    
    $ condor_submit /tmp/user2.jsub
    Submitting job(s).
    1 job(s) submitted to cluster 5.
    
    $ ccsort condor_status JobID TotalJobRunTime AccountingGroup
    3.0 | 91 | user1@localdomain
    4.0 | 32 | user2@localdomain
    5.0 | 3 | user2@localdomain


Now we change LIFO to FIFO and demonstrate.  Switch the sign of `TotalJobRunTime`:

    # Now I am FIFO!
    PREEMPTION_RANK = -TotalJobRunTime

And restart the negotiator, and check on our currently running jobs:

    $ condor_restart -negotiator
    
    $ ccsort condor_status JobID TotalJobRunTime AccountingGroup
    3.0 | 151 | user1@localdomain
    4.0 | 92 | user2@localdomain
    5.0 | 49 | user2@localdomain

Now, set up 'user2' for easy preemption like user1:

    $ condor_userprio -setprio user2@localdomain 10

And submit some jobs for user3.  Since we reconfigured for FIFO preemption, we should now see the _most recent_ job preempted each time (in this case, these should both be the 'user2' jobs):

    $ condor_submit /tmp/user3.jsub
    Submitting job(s).
    1 job(s) submitted to cluster 6.
    
    $ ccsort condor_status JobID TotalJobRunTime AccountingGroup
    3.0 | 241 | user1@localdomain
    4.0 | 182 | user2@localdomain
    6.0 | 15 | user3@localdomain
    
    $ condor_submit /tmp/user3.jsub
    Submitting job(s).
    1 job(s) submitted to cluster 7.
    
    $ ccsort condor_status JobID TotalJobRunTime AccountingGroup
    3.0 | 301 | user1@localdomain
    6.0 | 75 | user3@localdomain
    7.0 | 17 | user3@localdomain
