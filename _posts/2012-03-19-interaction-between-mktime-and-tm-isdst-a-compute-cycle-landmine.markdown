---
layout: post
title: "Interaction between mktime() and tm_isdst - a compute cycle landmine"
date: 2012-03-19 13:18
comments: true
categories: [condor, computing]
---
I was recently profiling the [Condor](http://research.cs.wisc.edu/condor/) collector, and was a bit stunned to discover that the standard C library function [mktime](http://www.cplusplus.com/reference/clibrary/ctime/mktime/)() was burning _60% of the collector's cycles_.

[Matt](http://spinningmatt.wordpress.com/) helpfully attempted to reproduce, but his profile showed `mktime()` using almost none of the cycles, which is exactly the sane result one would expect.

In the code, I noticed that `tm_isdst` was set to 1, in other words "assert that DST is in effect."  This made my eye twitch, because I live in Arizona, where we boldy do not observe DST.  I created a little test rig to help confirm my suspicion that time zone might have something to do with it:

    #include <stdlib.h>
    #include <time.h>
    #include <iostream>
    
    using std::cout;
    
    time_t mktA(struct tm* tmp) {
        tmp->tm_isdst = -1;
        return mktime(tmp);
    }
    
    time_t mktB(struct tm* tmp) {
        tmp->tm_isdst = 0;
        return mktime(tmp);
    }
    
    time_t mktC(struct tm* tmp) {
        tmp->tm_isdst = 1;
        return mktime(tmp);
    }
    
    int main(int argc, char** argv) {
        struct tm stm;
        stm.tm_year = 2012 - 1900;
        stm.tm_mon = 3-1;
        stm.tm_mday = 17-1;
        stm.tm_hour = 0;
        stm.tm_min = 0;
        stm.tm_sec = 0;

        // this gets altered for each testing function:
        stm.tm_isdst = 0;

        cout << mktA(&stm) << "\n";
        cout << mktB(&stm) << "\n";
        cout << mktC(&stm) << "\n";
    
        return 0;
    }

Then I built the test rig, which I expertly named `test_mktime`, and profiled it using valgrind/callgrind:


    # build the test rig
    $ make test_mktime
    g++     test_mktime.cpp   -o test_mktime

    # profile using valgrind/callgrind:
    $ valgrind --tool=callgrind ./test_mktime
    ==2671== Callgrind, a call-graph generating cache profiler
    ==2671== Copyright (C) 2002-2009, and GNU GPL'd, by Josef Weidendorfer et al.
    ==2671== Using Valgrind-3.5.0 and LibVEX; rerun with -h for copyright info
    ==2671== Command: ./test_mktime
    ==2671== 
    ==2671== For interactive control, run 'callgrind_control -h'.
    1331881200
    1331881200
    1331881200
    ==2671== 
    ==2671== Events    : Ir
    ==2671== Collected : 4125723
    ==2671== 
    ==2671== I   refs:      4,125,723

    # massage the raw output into something (more or less) human readable:
    $ callgrind_annotate --inclusive=yes --tree=calling callgrind.out.2671 > mktprof.txt

Examining the massaged output in `mktprof.txt`, I observed that calling `mktime()` with `tm_isdst = {-1|0}` (`mktA()` and `mktB()`) takes the small amount of time one would expect, calling with `tm_isdst = 1` (`mktC()`) uses a completely insane number of cycles, and clearly nearly all of the cycles burned by the test rig:


    2,749,933  *  ???:main [/home/eje/mktime/test_mktime]
    2,655,457  >   ???:mktC(tm*) (1x) [/home/eje/mktime/test_mktime]
        4,428  >   ???:std::basic_ostream<char, std::char_traits<char> >& std::operator<< <std::char_traits<char> >(std::basic_ostream<char, std::char_traits<char> >&, char const*) (3x) [/usr/lib64/libstdc++.so.6.0.13]
       11,260  >   ???:std::ostream::operator<<(long) (3x) [/usr/lib64/libstdc++.so.6.0.13]
        4,064  >   ???:mktB(tm*) (1x) [/home/eje/mktime/test_mktime]
        3,989  >   ???:_dl_runtime_resolve (2x) [/lib64/ld-2.11.2.so]
       74,212  >   ???:mktA(tm*) (1x) [/home/eje/mktime/test_mktime]


Again, Matt verified that he could reproduce the weird behavior if he set _his_ timezone to "Arizona".  

The bottom line appears to be that invoking `mktime()` with `tm_isdst = 1`, in a time zone that does not observe DST, can set off a nuclear cycle-stealing land mine of inefficiency and horror.
