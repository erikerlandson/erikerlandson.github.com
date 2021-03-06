---
layout: post
title: "A Demonstration of Negotiator-Side Resource Consumption"
date: 2012-12-03 08:25
comments: true
tags: [ computing, htcondor, negotiator, matchmaking, resources, partitionable slot ]
---
HTCondor supports a notion of aggregate compute resources known as partitionable slots (p-slots), which may be consumed by multiple jobs.   Historically, at most one job could be matched against such a slot in a single negotiation cycle, which limited the rate at which partitionable slot resources could be utilized.  More recently, the scheduler has been enhanced with logic to allow it to acquire multiple claims against a partitionable slot, which increases the p-slot utilization rate. However, as this potentially bypasses the negotiator's accounting of global pool resources such as accounting group quotas and concurrency limits, it places some contraints on what jobs can can safely acquire multiple claims against any particular p-slot: for example, only other jobs on the same scheduler can be considered.  Additionally, candidate job requirements must match the requirements of the job that originally matched in the negotiator.  Another significant impact is that the negotiator is still forced to match an entire p-slot, which may have a large match cost (weight): these large match costs cause [accounting difficulties](https://htcondor-wiki.cs.wisc.edu/index.cgi/tktview?tn=3013) when submitter shares and/or group quotas drop below the cost of a slot.  This particular problem is growing steadily larger, as machines with ever-larger numbers of cores and other resources appear in HTCondor pools.

An alternative approach to scheduler-side resource consumption is to enhance the negotiator with the ability to match multiple jobs against a resource (p-slot) -- negotiator-side resource consumption.   The advantages of negotiator-side consumption are that it places fewer limitations on what jobs can consume a given resource.  The negotiator already handles global resource accounting, and so jobs are not required to adhere to the same requirements expression to safely consume assets from the same resource.  Furthermore, jobs from any scheduler may be considered.  Each match is only charged the cost of resources consumed, and so p-slots with large amounts of resources do not cause difficulties with large match costs.   Another considerable benefit of this approach is that it facilitates the support of [configurable resource consumption policies](http://spinningmatt.wordpress.com/2012/11/13/no-longer-thinking-in-slots-thinking-in-aggregate-resources-and-consumption-policies/)

I have developed a working draft of negotiator-side resource consumption on my HTCondor github fork, topic branch [V7_9-prototype-negside-pslot-splits](https://github.com/erikerlandson/htcondor/tree/V7_9-prototype-negside-pslot-splits) which also implements support for configurable resource consumption policies.   I will briefly demonstrate this implementation and some of its advantages below.

First I will demonstrate an example with a consumption policy that is essentially equivalent to HTCondor's current default policies.  Consider this configuration:

    # spoof some cores
    NUM_CPUS = 10

    # configure an aggregate resource (p-slot) to consume
    SLOT_TYPE_1 = 100%
    SLOT_TYPE_1_PARTITIONABLE = True
    # declare multiple claims for negotiator to use
    # may also use global: NUM_CLAIMS
    SLOT_TYPE_1_NUM_CLAIMS = 20
    NUM_SLOTS_TYPE_1 = 1

    # turn off schedd-side resource splitting since we're demonstrating neg-side alternative
    CLAIM_PARTITIONABLE_LEFTOVERS = False

    # turn this off to demonstrate that consumption policy will handle this kind of logic
    MUST_MODIFY_REQUEST_EXPRS = False

    # configure a consumption policy.   This policy is modeled on
    # current 'modify-request-exprs' defaults:
    # "my" is resource ad, "target" is job ad
    STARTD_EXPRS = ConsumptionCpus, ConsumptionMemory, ConsumptionDisk
    ConsumptionCpus = quantize(target.RequestCpus, {1})
    ConsumptionMemory = quantize(target.RequestMemory, {128})
    ConsumptionDisk = quantize(target.RequestDisk, {1024})
    # swap doesn't seem to be actually supported in resource accounting

    # keep slot weights enabled for match costing
    NEGOTIATOR_USE_SLOT_WEIGHTS = True

    # weight used to derive match cost: W(before-consumption) - W(after-consumption)
    SlotWeight = Cpus

    # for simplicity, turn off preemption, caching, worklife
    CLAIM_WORKLIFE=0
    MAXJOBRETIREMENTTIME = 3600
    PREEMPT = False
    RANK = 0
    PREEMPTION_REQUIREMENTS = False
    NEGOTIATOR_CONSIDER_PREEMPTION = False
    NEGOTIATOR_MATCHLIST_CACHING = False

    # verbose logging
    ALL_DEBUG = D_FULLDEBUG

    # reduce daemon update latencies
    NEGOTIATOR_INTERVAL = 30
    SCHEDD_INTERVAL	= 15

In the above configuration, we declare a typical aggregate (that is, partitionable) resource `SLOT_TYPE_1`, but then we also configure a _consumption policy_, by advertising `ConsumptionCpus`, `ConsumptionMemory` and `ConsumptionDisk`.  Note that these are defined with quantizing expressions currently used as default values for the `MODIFY_REQUEST_EXPRS` behavior.  The startd and the negotiatior will _both_ use these expressions by examining the slot ads.

Next, we submit 15 jobs.  Note that this more than the 10 cores advertised by the p-slot:

    universe = vanilla
    cmd = /bin/sleep
    args = 60
    should_transfer_files = if_needed
    when_to_transfer_output = on_exit
    queue 15

If we watch the negotiator log, we will see that negotiator matches the 10 jobs supported by the p-slot on the next cycle (note that it uses slot1 each time):

    $ tail -f NegotiatorLog | grep -e '\-\-\-\-\-'  -e 'matched
    12/03/12 11:53:10 ---------- Finished Negotiation Cycle ----------
    12/03/12 11:53:25 ---------- Started Negotiation Cycle ----------
    12/03/12 11:53:25       Successfully matched with slot1@rorschach
    12/03/12 11:53:25       Successfully matched with slot1@rorschach
    12/03/12 11:53:25       Successfully matched with slot1@rorschach
    12/03/12 11:53:25       Successfully matched with slot1@rorschach
    12/03/12 11:53:25       Successfully matched with slot1@rorschach
    12/03/12 11:53:25       Successfully matched with slot1@rorschach
    12/03/12 11:53:25       Successfully matched with slot1@rorschach
    12/03/12 11:53:25       Successfully matched with slot1@rorschach
    12/03/12 11:53:25       Successfully matched with slot1@rorschach
    12/03/12 11:53:25       Successfully matched with slot1@rorschach
    12/03/12 11:53:25 ---------- Finished Negotiation Cycle ----------

You can use `condor_q` to verify that the 10 jobs subsequently run.   The jobs run against 10 dynamic slots (d-slots) in the standard way:

    $ ccdump condor_status Name TotalSlotCpus
    slot1@rorschach | 10
    slot1_10@rorschach | 1
    slot1_1@rorschach | 1
    slot1_2@rorschach | 1
    slot1_3@rorschach | 1
    slot1_4@rorschach | 1
    slot1_5@rorschach | 1
    slot1_6@rorschach | 1
    slot1_7@rorschach | 1
    slot1_8@rorschach | 1
    slot1_9@rorschach | 1

Next we consider altering the resource consumption policy.  As a simple example, suppose we wish to allocate memory more coarsely.  We could alter the configuration above by changing `ConsumptionMemory` to:

    ConsumptionMemory = quantize(target.RequestMemory, {512})

Perhaps we then also want to express match cost in a memory-centric way, instead of the usual cpu-centric way:

    SlotWeight = floor(Memory / 512)

Here it is worth noting that in this implementation of negotiator-side consumption, the cost of a match is defined as W(S) - W(S'), where W(S) is the weight of the slot _prior_ to consuming resources from the match and consumption policy, and W(S`) is the weight evaluated for the slot _after_ those resources are subtracted.  This modification enables multiple matches to be made against a single p-slot, and furthermore it paves the way to possible avenues for a [better unit analysis of slot weights and accounting groups](http://erikerlandson.github.com/blog/2012/11/26/rethinking-the-semantics-of-group-quotas-and-slot-weights-computing-claim-capacity-from-consumption-policy/).

Continuing the example, if we re-run the example with this new consumption policy, we should see that memory limits reduce the number of jobs matched against `slot1` to 3:

    $ tail -f NegotiatorLog | grep -e '\-\-\-\-\-'  -e 'matched'
    12/03/12 12:58:22 ---------- Finished Negotiation Cycle ----------
    12/03/12 12:58:37 ---------- Started Negotiation Cycle ----------
    12/03/12 12:58:37       Successfully matched with slot1@rorschach
    12/03/12 12:58:37       Successfully matched with slot1@rorschach
    12/03/12 12:58:37       Successfully matched with slot1@rorschach
    12/03/12 12:58:37 ---------- Finished Negotiation Cycle ----------

Examining the slot memory assets, we see that there is insufficient memory for a fourth match when our consumption policy sets the minimum at 512:

    $ ccdump condor_status Name TotalSlotMemory
    slot1@rorschach | 1903
    slot1_1@rorschach | 512
    slot1_2@rorschach | 512
    slot1_3@rorschach | 512

As a final example, I'll demonstrate the positive impact of negotiator side matching on interactions with accounting groups (or submitter shares).  Again returning to my original example, modify the configuration with a simple accounting group policy:

    GROUP_NAMES = a
    GROUP_QUOTA_a = 1
    GROUP_ACCEPT_SURPLUS = False
    GROUP_AUTOREGROUP = False

Now submit 2 jobs against accounting group `a`:

    universe = vanilla
    cmd = /bin/sleep
    args = 60
    should_transfer_files = if_needed
    when_to_transfer_output = on_exit
    +AccountingGroup="a.u"
    queue 2

We see that accounting groups are respected: one job runs, and it does not suffer from insufficient share to acquire resources from `slot1` [(GT3013)](https://htcondor-wiki.cs.wisc.edu/index.cgi/tktview?tn=3013), because match cost is computed using only the individual job's impact on slot weight, instead of being required to match the entire p-slot:

    $ tail -f ~/condor/local/log/NegotiatorLog | grep -e '\-\-\-\-\-' -e matched
    12/03/12 14:57:50 ---------- Finished Negotiation Cycle ----------
    12/03/12 14:58:08 ---------- Started Negotiation Cycle ----------
    12/03/12 14:58:08       Successfully matched with slot1@rorschach
    12/03/12 14:58:09 ---------- Finished Negotiation Cycle ----------
    
    $ ccdump condor_status Name TotalSlotCpus
    slot1@rorschach | 10
    slot1_1@rorschach | 1

