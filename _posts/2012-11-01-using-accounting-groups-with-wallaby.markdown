---
layout: post
title: "Using Accounting Groups With Wallaby"
date: 2012-11-01 07:41
comments: true
categories: [ computing, htcondor, condor, accounting groups, wallaby ]
---
In this post I will describe how to use HTCondor accounting groups with [Wallaby](http://getwallaby.com).  I will begin by walking through an accounting group configuration on a pool managed by wallaby.  Following, I will demonstrate the configuration in action.

The gist of this demo will be to create a simple accounting group hierarchy:  A top-level group called `Demo`, and three child groups `Demo.A, Demo.B, Demo.C`.  `Demo` will be given a _static_ quota to simulate the behavior of a pool with a particular number of slots available.  The child groups will use _dynamic_ quotas to express their quota shares from the parent as ratios.

First, it is good practice to snapshot current wallaby configuration for reference:
```
    $ wallaby make-snapshot "pre demo state"
```

We will be constructing a wallaby feature called `AccountingGroups` to hold our accounting group configurations.  This creates the feature:
```
    $ wallaby add-feature AccountingGroups
```

Wallaby wants to know about features that are used in configurations, so begin by declaring them to the wallaby store:
```
    $ wallaby add-param GROUP_NAMES
    $ wallaby add-param GROUP_QUOTA_Demo
    $ wallaby add-param GROUP_QUOTA_DYNAMIC_Demo.A
    $ wallaby add-param GROUP_QUOTA_DYNAMIC_Demo.B
    $ wallaby add-param GROUP_QUOTA_DYNAMIC_Demo.C
    $ wallaby add-param GROUP_ACCEPT_SURPLUS_Demo
    $ wallaby add-param NEGOTIATOR_ALLOW_QUOTA_OVERSUBSCRIPTION
    $ wallaby add-param NEGOTIATOR_CONSIDER_PREEMPTION
    $ wallaby add-param CLAIM_WORKLIFE
```

Here we disable the "claim worklife" feature by setting claims to expire immediately.   This prevents jobs under one accounting group from acquiring surplus quota and holding on to it when new jobs arrive under a different group:
```
    $ wallaby add-params-to-feature ExecuteNode CLAIM_WORKLIFE=0
    $ wallaby add-params-to-subsystem startd CLAIM_WORKLIFE
    $ wallaby add-params-to-feature Scheduler CLAIM_WORKLIFE=0
    $ wallaby add-params-to-subsystem scheduler CLAIM_WORKLIFE
```

If you alter the configuration parameters, you will want the negotiator to reconfigure itself when you activate.  Here we declare the accounting group features as part of the negotiator subsystem:
```
    $ wallaby add-params-to-subsystem negotiator \
    GROUP_NAMES \
    GROUP_QUOTA_Demo \
    GROUP_QUOTA_DYNAMIC_Demo.A \
    GROUP_QUOTA_DYNAMIC_Demo.B \
    GROUP_QUOTA_DYNAMIC_Demo.C \
    NEGOTIATOR_ALLOW_QUOTA_OVERSUBSCRIPTION \
    NEGOTIATOR_CONSIDER_PREEMPTION
```

Activate the configuration so far to tell subsystems about new parameters for reconfig
```
    $ wallaby activate
```

Now we construct the actual configuration as the `AccountingGroups` wallaby feature.  Here we are constructing a group `Demo` with three subgroups `Demo.{A|B|C}`.  In a multi-node pool with several cores, it is often easiest to play with group behavior by creating a sub-hierarchy such as this `Demo` sub-hierarchy, and configuring `GROUP_ACCEPT_SURPLUS_Demo=False`, so that the sub-hierarchy behaves with a well-defined total slot quota (in this case 15).  The sub-groups A,B and C each take 1/3 of the parent's quota, so in this example each will receive 5 slots.
```
    $ wallaby add-params-to-feature AccountingGroups \
    NEGOTIATOR_ALLOW_QUOTA_OVERSUBSCRIPTION=False \
    NEGOTIATOR_CONSIDER_PREEMPTION=False \
    GROUP_NAMES='Demo, Demo.A, Demo.B, Demo.C' \
    GROUP_ACCEPT_SURPLUS=True \
    GROUP_QUOTA_Demo=15 \
    GROUP_ACCEPT_SURPLUS_Demo=False \
    GROUP_QUOTA_DYNAMIC_Demo.A=0.333 \
    GROUP_QUOTA_DYNAMIC_Demo.B=0.333 \
    GROUP_QUOTA_DYNAMIC_Demo.C=0.333
```

With our accounting group feature created, we can apply it to the machine our negotiator daemon is running on.  Then snapshot our configuration modifications for reference, and activate the new configuration:
```
    $ wallaby add-features-to-node negotiator.node.com AccountingGroups
    $ wallaby make-snapshot 'new acct group config'
    $ wallaby activate
```

Now we will demonstrate the new feature in action.  Submit the following file to your pool, which submits 100 jobs each to groups `Demo.A` with durations randomly chosen between 25 and 35 seconds:
```
    universe = vanilla
    cmd = /bin/sleep
    args = $$([25 + random(11)])
    transfer_executable = false
    should_transfer_files = if_needed
    when_to_transfer_output = on_exit
    +AccountingGroup="Demo.A.user1"
    queue 100
```

Once you make this submission, allow the jobs to negotiate, and you can check to see what accounting groups are running on slots by inspecting the value of `RemoteNegotiatingGroup` on slot ads.   You should see that subgroup `Demo.A` has acquired surplus and is running 15 jobs, as there are no jobs under groups `Demo.B` or `Demo.C` that need slots.  Note, due to jobs completing between negotiation cycles, these numbers can be less than the maximum possible at certain times.  If you have any other slots in the pool, they will show up in the output below as having either `undefined` negotiating group or possibly `<none>` if any other jobs are running.
```
    $ condor_status -format "%s\n" 'ifThenElse(RemoteNegotiatingGroup isnt undefined, string(RemoteNegotiatingGroup), "undefined")' -constraint 'True' | sort | uniq -c | awk '{ print $0; t += $1 } END { printf("%7d total\n",t) }'
     15 Demo.A
     50 <none>
     50 undefined
    115 total
```

Now submit some jobs against `Demo.B` and `Demo.C`, like so:
```
    universe = vanilla
    cmd = /bin/sleep
    args = $$([25 + random(11)])
    transfer_executable = false
    should_transfer_files = if_needed
    when_to_transfer_output = on_exit
    +AccountingGroup="Demo.B.user1"
    queue 100
    +AccountingGroup="Demo.C.user1"
    queue 100
```

Once these jobs begin to negotiate, we expect to see the jobs balanced between the three groups evenly, as we gave each group 1/3 of the quota:
```
    $ condor_status -format "%s\n" 'ifThenElse(RemoteNegotiatingGroup isnt undefined, string(RemoteNegotiatingGroup), "undefined")' -constraint 'True' | sort | uniq -c | awk '{ print $0; t += $1 } END { printf("%7d total\n",t) }'
      5 Demo.A
      5 Demo.B
      5 Demo.C
     50 <none>
     50 undefined
    115 total
```

Finally, we see what happens if we remove jobs under `Demo.B`:
```
    $ condor_rm -constraint 'AccountingGroup =?= "Demo.B.user1"'
```

Now we should see quota start to share between `Demo.A` and `Demo.C`:
```
    $ condor_status -format "%s\n" 'ifThenElse(RemoteNegotiatingGroup isnt undefined, string(RemoteNegotiatingGroup), "undefined")' -constraint 'True' | sort | uniq -c | awk '{ print $0; t += $1 } END { printf("%7d total\n",t) }'
      7 Demo.A
      8 Demo.C
     50 <none>
     50 undefined
    115 total
```

With this accounting group configuration in place, you can play with changing quotas for the accounting groups and observe the numbers of running jobs change in response.
