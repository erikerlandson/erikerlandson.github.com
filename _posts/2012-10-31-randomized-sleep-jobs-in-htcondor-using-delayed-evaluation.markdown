---
layout: post
title: "Randomized Sleep Jobs in HTCondor Using Delayed Evaluation"
date: 2012-10-31 14:17
comments: true
tags: [ computing, htcondor, condor, condor_submit, delayed evaluation, job classad ]
---
In some cases, when testing or demonstrating the performance of an HTCondor pool, it is useful to submit a plug of jobs with randomized running times.  The standard technique for controlling run times is to submit a classic 'sleep' job.  However, randomizing the argument to sleep is another matter.  Luckily there is an easy way to do this with a single submit file, using delayed evaluation syntax.

A classad expression placed inside of a special enclosure, like this: `$$([ <expr> ])`, causes `<expr>` to be evaluated at the time the job ad is matched with a slot.  You can read more about delayed evaluation [here](http://research.cs.wisc.edu/condor/manual/v7.8/condor_submit.html#78367).  Consider the following example submit file:

    universe = vanilla
    executable = /bin/sleep
    
    # generate a random sleep duration when job is matched
    args = $$([25 + random(11)])
    
    # boilerplate to avoid file transfers and notifications
    transfer_executable = false
    should_transfer_files = no
    when_to_transfer_output = on_exit
    notification = never
    
    # generate 100 copies of this job - each will evaluate the
    # randomizing expression independently
    queue 100

As you can see in the example above, the value of `args` is set to the delayed evaluation expression `$$([25 + random(11)])`, which will evaluate the classad expression `25 + random(11)` when each job ad matches a slot to run.  The `queue 100` command generates 100 separate job ads, and so the net effect is 100 jobs, which will each run a sleep job with a duration _randomly chosen_ between 25 and 35.

If we submit this file to a condor pool, and let the jobs run to completion, we can check the pool history file to see how the `Args` attribute was set on the job ad using the special generative attribute `MATCH_EXP_Args`, and the [cchist tool](http://erikerlandson.github.com/blog/2012/06/29/easy-histograms-and-tables-from-condor-jobs-and-slots/):

    $ cchist condor_history 'MATCH_EXP_Args'
         11 25
          7 26
         10 27
          9 28
          7 29
         13 30
          8 31
          7 32
          8 33
          9 34
         11 35
        100 total


We can also sanity check our measure of actual run time, to see that those values are close to our values of `Args`:

    $ cchist condor_history 'CompletionDate-JobCurrentStartDate'
          1 25
         11 26
          9 27
          8 28
          9 29
          9 30
         12 31
          4 32
          8 33
         10 34
         12 35
          6 36
          1 37
        100 total

Have fun with easy random sleep jobs!
