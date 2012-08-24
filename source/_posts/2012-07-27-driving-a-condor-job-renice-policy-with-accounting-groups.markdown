---
layout: post
title: "Driving a Condor Job Renice Policy with Accounting Groups"
date: 2012-07-27 13:50
comments: true
categories: [ computing, condor, renice, accounting groups, grid computing, MRG Grid, Red Hat ]
---

Condor can run its jobs with a renice priority level specified by `JOB_RENICE_INCREMENT`, which defaults simply to 10, but can in fact be any ClassAd expression, and is evaluated in the context of the job ad corresponding to the job being run.

This opens up an opportunity to create a renice _policy_, driven by accounting groups.  Consider a [scenario I discussed previously](http://erikerlandson.github.com/blog/2012/07/10/configuring-minimum-and-maximum-resources-for-mission-critical-jobs-in-a-condor-pool/), where a condor pool caters to mission critical (MC) jobs and regular (R) jobs.

An additional configuration trick we could apply is to add a renice policy that gives a higher renice value (that is, a lower priority) to any jobs that aren't run under the mission-critical (MC) rubric, as in this example configuration:

    # A convenience expression that extracts group, e.g. "mc.user@domain.com" --> "mc"
    SUBMIT_EXPRS = AcctGroupName
    AcctGroupName = ifThenElse(my.AccountingGroup =!= undefined, \
                               regexps("^([^@]+)\.[^.]+", my.AccountingGroup, "\1"), "<none>")

    NUM_CPUS = 3

    # Groups representing mission critical and regular jobs:
    GROUP_NAMES = MC, R
    GROUP_QUOTA_MC = 2
    GROUP_QUOTA_R = 1

    # Any group not MC gets a renice increment of 10:
    JOB_RENICE_INCREMENT = 10 * (AcctGroupName =!= "MC")


To demonstrate this policy in action, I wrote a little shell script I called `burn`, whose only function is to burn cycles for a given number of seconds:

    #!/bin/sh

    # usage: burn [n]
    # where n is number of seconds to burn cycles
    s="$1"
    if [ -z "$s" ]; then s=60; fi

    t0=`date +%s`
    while [ 1 ]; do
        x=0
        # burn some cycles:
        while [ $x -lt 10000 ]; do let x=$x+1; done
        t=`date +%s`
        let e=$t-$t0
        # halt when the requested time is up:
        if [ $e -gt $s ]; then exit ; fi
    done


Begin by standing up a condor pool including the configuration above.   Make sure the `burn` script is readable.  Also, it is preferable to make sure your system is unloaded (load average should be as close to zero as reasonably possible).  Then submit the following, which instantiates two `burn` jobs running under accounting group `MC` and a third under group `R`:

    universe = vanilla
    cmd = /path/to/burn
    args = 600
    should_transfer_files = if_needed
    when_to_transfer_output = on_exit
    +AccountingGroup = "MC.user"
    queue 2
    +AccountingGroup = "R.user"
    queue 1

Allow the jobs to negotiate and then run for a couple minutes.  You should then see something similar to the following load-average information from the slot ads:

    $ condor_status -format "%s" SlotID -format " | %.2f" LoadAvg -format " | %.2f" CondorLoadAvg -format " | %.2f" TotalLoadAvg -format " | %.2f" TotalCondorLoadAvg -format " | %s\n" AccountingGroup | sort
    1 | 1.33 | 1.33 | 2.75 | 2.70 | MC.user@localdomain
    2 | 1.28 | 1.24 | 2.75 | 2.70 | MC.user@localdomain
    3 | 0.13 | 0.13 | 2.77 | 2.72 | R.user@localdomain

Note, which particular `SlotID` runs which job may vary.  However, we expect to see that the load averages for the slot running group `R` are much lower than the load averages for slots running jobs under group `MC`, as seen above.

We can explicitly verify the renice numbers from our policy to see that our one `R` job has a nice value of 10 (and is using only a fraction of the cpu):
    # tell 'ps' to give us (pid, %cpu, nice, cmd+args):
    $ ps -eo "%p %C %n %a" | grep 'burn 600'
    22403 10.2  10 /bin/sh /home/eje/bin/burn 600
    22406 93.2   0 /bin/sh /home/eje/bin/burn 600
    22411 90.6   0 /bin/sh /home/eje/bin/burn 600
