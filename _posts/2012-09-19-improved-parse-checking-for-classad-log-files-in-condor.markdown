---
layout: post
title: "Improved Parse Checking for ClassAd Log Files in Condor"
date: 2012-09-26 10:06
comments: true
tags: [ computing, grid computing, condor, MRG Grid, Red Hat, classad, classad log ]
published: true
---

Condor maintains certain key transactional information using the ClassAd Log system.  For example, both the negotiator's accountant log ("Accountantnew.log") and the scheduler's job queue log ("job_queue.log") are maintained in ClassAd Log format.

As of [Red Hat Grid 2.2](http://www.redhat.com/products/mrg/grid/) (upstream: [condor 7.9.0](http://research.cs.wisc.edu/condor/)), the ClassAd Log system provides significantly improved parse checking.  This upgraded format checking allows a much wider variety of log corruptions to be detected, and also provides detailed information on the location of corruptions encountered.

### ClassAd Log Format ###

A bit of familiarity with ClassAd Log format will aid in understanding subsequent discussion.  The ClassAd Log system serializes a ClassAd collection history as a sequence of tuples:  `opcode, [key, [args]]`.  For example, here is an annotated ClassAd log excerpt (NOTE: annotations or comments are illegal in an actual file):

    105                               <- open a transaction
    103 1.0 LastSuspensionTime 0      <- for classad '1.0', set LastSuspentionTime to 0
    103 1.0 CurrentHosts 1            <- for classad '1.0', set CurrentHosts to 1
    106                               <- close the transaction

ClassAd Log parse checking works by detecting any occurrence of an invalid op-code, or any invalid ClassAd expression in the RHS of an attribute update operation (opcode 103, as in the example above)

### Examples of Parse Failure Detection ###

Consider a ClassAd Log with a corrupted op-code 'ZMG' (in this case, not even a proper integer):

    107 1 CreationTimestamp 1334245749
    101 0.0 Job Machine
    103 0.0 NextClusterNum 1
    105
    ZMG 1.0 JobStatus 2                        <- Oh no, a bad opcode!
    103 1.0 EnteredCurrentStatus 1334245771
    103 1.0 LastSuspensionTime 0
    103 1.0 CurrentHosts 1
    106
    105
    103 1.1 LastJobStatus 1
    103 1.1 JobStatus 2

Parse checking will result in the following log message in the scheduler, which provides its assessment of what operation line/tuple it found the corruption, and the following 3 lines for additional context:

    09/12/12 15:30:35 WARNING: Encountered corrupt log record 5 (byte offset 89)
    09/12/12 15:30:35 Lines following corrupt log record 5 (up to 3):
    09/12/12 15:30:35     103 1.0 EnteredCurrentStatus 1334245771
    09/12/12 15:30:35     103 1.0 LastSuspensionTime 0
    09/12/12 15:30:35     103 1.0 CurrentHosts 1
    09/12/12 15:30:35 ERROR "Error: corrupt log record 5 (byte offset 89) occurred inside closed transaction, recovery failed" at line 1136 in file /home/eje/git/grid/src/condor_utils/classad_log.cpp

Note that here the scheduler halted with an exception, as strict parsing was enabled, and the error was inside a completed transaction.

Here is a second example that contains a badly-formed ClassAd expression:

    107 1 CreationTimestamp 1334245749
    101 0.0 Job Machine
    103 0.0 NextClusterNum 1
    105
    103 1.0 JobStatus 2
    103 1.0 EnteredCurrentStatus 1334245749
    103 1.0 LastSuspensionTime 0
    103 1.0 CurrentHosts 1
    106
    105
    103 1.1 LastJobStatus 1 + eek!             <- bad ClassAd expr!
    103 1.1 JobStatus 2

Note that parse errors detected in unterminated transactions (the last transaction in a file may be uncompleted) are considered non-fatal:

    09/12/12 15:43:29 WARNING: Encountered corrupt log record 11 (byte offset 211)
    09/12/12 15:43:29 Lines following corrupt log record 11 (up to 3):
    09/12/12 15:43:29     103 1.1 JobStatus 2
    09/12/12 15:43:29 Detected unterminated log entry in ClassAd Log /home/eje/condor/local/spool/job_queue.log. Forcing rotation.

### Disabling Strict Parse Checking ###

Strict parse checking means that detected errors are fatal (unless in an unterminated transaction).  One consequence of the former lax error checking for Classad Log files is that some log file output was generated that was not properly formed.  Most such instances have been identified and corrected.  However, in order to accomodate legacy ClassAd Log files and any hidden bugs in log output generation, a condor configuration variable has been provided to disable strict checking:

    # Disable strict parsing: parse errors will not be fatal
    CLASSAD_LOG_STRICT_PARSING = False

In Red Hat Grid 2.2, `CLASSAD_LOG_STRICT_PARSING` defaults to `False`.  In the upstream condor repository, the default value has been set to `True`, in order to allow strict parsing failures to capture any remaining infrequent bugs in ClassAd log generation.

Note that strict checking can also be disabled or enabled _selectively_.  For example, this configuration disables strict checking only on the negotiator:

    CLASSAD_LOG_STRICT_PARSING = True
    NEGOTIATOR.CLASSAD_LOG_STRICT_PARSING = False

### Categories of Undetectable Corruption ###

In the ClassAd Log format, the key is considered an arbitrary string.  Therefore, any corruption that alters a key value is not detectable:

    103 1.rats! LastSuspensionTime 0   <- weird key '1.rats!' will go undetected

Similarly, ClassAd attribute names are by nature arbitrary, and so corruptions to a name can go undetected:

    103 1.0 LastOopsie 0   <- LastOopsie is a valid attribute name
