---
layout: post
title: Decision Making Considered Harmful - The Branch Prediction Incident of August 2020
date: 2020-08-22 11:23 -0700
tags: [ computing, java, branch prediction, performance, optimization  ]
---

As a programmer who periodically puts on a numeric computing and algorithms hat,
I try to keep one foot in the world of low-level performance concerns,
such as compiler optimizations and hardware performance features.
On a recent algorithm adventure, I discovered that I had been underestimating the effects of branch prediction on software performance,
and was reminded that I can still be surprised by such low-level artifacts!

To set the scene at a very high level, I was benchmarking an
[experimental algorithm](https://github.com/erikerlandson/isarn-sketches/blob/blog-2020-08/isarn-sketches-java/src/main/java/org/isarnproject/sketches/java/QCDF.java#L84)
using a random sampling of ten million values from a Gaussian distribution.
I also wished to stress-test my algorithm and so I ran my benchmark with the same ten million values, except in sorted order.

The process of adapting to monotonically increasing values incurs extra work at my logical algorithmic level,
and so I expected the benchmarks on sorted data to take longer.
However, to my surprise my benchmark _ran twice as fast_.

The benchmarks looked like this in my REPL,
where the numbers in the result are in units of seconds:
```scala
scala> Benchmark.sample(10) { (new QCDF(10)).update(data1) }
res11: Array[(Double, Unit)] = Array((0.278,()), (0.271,()), (0.269,()), (0.268,()), (0.275,()), (0.271,()), (0.272,()), (0.279,()), (0.276,()), (0.285,()))

scala> Benchmark.sample(10) { (new QCDF(10)).update(sort1) }
res12: Array[(Double, Unit)] = Array((0.132,()), (0.128,()), (0.13,()), (0.13,()), (0.131,()), (0.132,()), (0.132,()), (0.13,()), (0.131,()), (0.129,()))
```

I spent a couple days puzzling over these weird benchmark results and convincing myself it simply couldn't be explained at the algorithmic level in my code.
By process of elimination, I began thinking about lower-level effects.

The core of my larger algorithm, and the component that dominated its computational cost,
is binary search against an array of ordered floating point values.
In particular, I was using
[java.util.Arrays.binarySearch](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/Arrays.html#binarySearch%28double%5B%5D,int,int,double%29).
A bit of internet code diving shows that its implementation looks like this:

```java
private static int binarySearch0(double[] a, int fromIndex, int toIndex, double key) {
    int low = fromIndex;
    int high = toIndex - 1;
    while (low <= high) {
        int mid = (low + high) >>> 1;
        double midVal = a[mid];
        if (midVal < key)
            low = mid + 1;
        else if (midVal > key)
            high = mid - 1;
        else {
            long midBits = Double.doubleToLongBits(midVal);
            long keyBits = Double.doubleToLongBits(key);
            if (midBits == keyBits)
                return mid;
            else if (midBits < keyBits)
                low = mid + 1;
            else
                high = mid - 1;
        }
    }
    return -(low + 1);
}
```

A few takeaways from this code:
- It is a classic binary search (excepting a bit of additional logic for distinguishing the cases of search key present versus absent).
- It has no optimization for search keys landing outside the min/max array values,
nor (unsurprisingly) is its code taking advantage of "remembering" anything about
previous inputs.
- As with any binary search, it is mostly just value comparisons.

So nothing about java's `binarySearch` is taking advantage of monotonically increasing inputs.
Now what?

Even so, thinking about "memory" and "ordered inputs" and "comparisons" stimulated my rusty memories of
[hardware branch prediction](https://en.wikipedia.org/wiki/Branch_predictor).
If nothing at the code level explained my performance measurements,
there appeared to be a good circumstantial case for ordered versus unordered data to be affecting my CPU's branch prediction performance.
Tribal knowledge out on the internet also
[supported](https://stackoverflow.com/questions/11227809/why-is-processing-a-sorted-array-faster-than-processing-an-unsorted-array)
a branch prediction explaination.

Cache hit vs miss rates are also a plausible performance consideration.
In this case it seems unlikely, since the data being searched against is the same in all cases, and quite small (a 10 element array).
Furthermore, the input data, while much larger (10 million elements), is also the same except for ordering,
and is accessed in a simple linear traversal which should be both very amenable for caching prediction and consistent across benchmarking runs.

Regardless, I wanted to see if I could collect more direct evidence to confirm that what I was seeing was a branch prediction effect.
My friend
[Will Benton](https://mu.willb.io/),
who has forgotten more about branch prediction and the jvm than I ever learned, suggested the
[perf](https://en.wikipedia.org/wiki/Perf_%28Linux%29)
profiling tools.

One nice thing about `perf` is that it can operate in a variety of modes, including attaching to an already-running process.
This was a useful option for me, since I was running my benchmarks in an sbt REPL,
and also because it allowed me to set up my benchmark data and environment in the REPL,
and only collect my branch prediction profiles while my target code was running.
This results in cleaner profiling data, although at the cost of making the experiment a bit "manual".
I had to:
- que up a benchmark run
- attach `perf` to the REPL
- kick off the benchmark
- halt the `perf` collection when I saw the benchmark finish

The code I used to benchmark `binarySearch` in a manner representative of how it's being used in my experiments looks like so:

```scala
// some representative data I used in my REPL
val sorted = Array(-2.37, -1.62, -1.10, -0.66, -0.28, 0.08, 0.45, 0.88, 1.42, 2.19)

def binarySearchBenchmark(keys: Array[Double], sorted: Array[Double]): Unit = {
    val nk = keys.length
    val ns = sorted.length
    var j = 0
    while (j < nk) {
        binarySearch(sorted, 0, ns, keys(j))
        j += 1
    }
}
```

An example command line invocation for `perf` that attaches to my REPL process looks like:

```bash
$ perf stat -p 4092
```

When I ran my benchmarks with `perf` profiling, I got the following results:

```
# unsorted random gaussian data
    66,076,243,390      cycles:u                  #    3.749 GHz                    
    68,615,186,772      instructions:u            #    1.04  insn per cycle         
    17,985,664,021      branches:u                # 1020.467 M/sec                  
     1,380,895,267      branch-misses:u           #    7.68% of all branches

# sorted gaussian data
    23,855,995,248      cycles:u                  #    3.621 GHz                    
    68,279,906,528      instructions:u            #    2.86  insn per cycle         
    17,911,246,687      branches:u                # 2718.850 M/sec                  
        13,684,874      branch-misses:u           #    0.08% of all branches        
```

You can see that the total number of instructions and branches are substantially the same,
which is to be expected, as the exact same values were run for both benchmarks, just in sorted versus unsorted order.
But the branch prediction error rate ("branch-misses") is _very_ different:
the error rate on unsorted input data is a **hundred times** the error rate for sorted data!

The effect on run-times is correspondingly obvious.
The timing numbers below show that the sorted input data (`sort1`) runs about 3 times faster:
```scala
scala> Benchmark.sample(10) { binarySearchBenchmark(data1, sorted) }
res0: Array[(Double, Unit)] = Array((0.166,()), (0.163,()), (0.165,()), (0.164,()), (0.164,()), (0.165,()), (0.164,()), (0.164,()), (0.164,()), (0.166,()))

scala> Benchmark.sample(10) { binarySearchBenchmark(sort1, sorted) }
res1: Array[(Double, Unit)] = Array((0.057,()), (0.054,()), (0.059,()), (0.054,()), (0.054,()), (0.054,()), (0.054,()), (0.054,()), (0.056,()), (0.054,()))
```

I found these results fascinating, and not just because they provided some hard evidence that what I'm seeing is an effect of branch prediction rates on ordered versus unordered data.
Although the error rate is 100x larger for unsorted data, in absolute terms _it is not very large_.
Even on unordered inputs, the branch predictors are guessing right well over 90% of the time!
While discussing these results with Will, he mentioned that the cost of a branch prediction error is quite high:
the CPU's instruction pipeline must be flushed, and the total delay will end up being 100 cycles or worse.
I had never really thought through the math on branch prediction costs,
and this experiment was a concrete lesson in how critical good branch prediction is for modern hardware performance.

It has also caused me to reconsider how I think about the "cost" of if/then tests in code.
I habitually think about how much a boolean clause costs to compute at the logical level,
but this experience has made it clear that the performance hit from branch prediction errors can easily dominate any "real" computation costs.
In this sense, the cost of an if/then test should arguably be measured in terms of how hard it is to predict,
instead of what it costs to compute the actual test value.

An equally interesting implication is that _any_ if/then statement in our code might be viewed as an opportunity for branch prediction failures.
My title for this post - "branch prediction considered harmful" - is tongue in cheek,
but when considering different possible algorithm optimizations and variations,
completely _avoiding_ if/then tests in performance critical code can clearly have a high payoff:
You can't take a branch-prediction performance hit if you aren't branching!

A final observation: this episode is reminiscent of some other situations I've encountered over my career,
where lower-level automatic optimizations can actually make algorithm development _harder_.
From a user perspective, performance features like hardware branch prediction are nothing but up-side:
if these features can take advantage of certain execution or data patterns to make your code run faster,
then life is good!
On the other hand, when you are _developing_ an algorithm, these kinds of pattern-dependent optimization can
skew your intuitions about what is really happening in your code, and what kinds of algorithmic choices you are making.
My benchmark results _might_ have caused me to draw incorrect conclusions about the behavior of my algorithm,
had I taken them at face value, without drilling down to fully understand how the hardware was
influencing my performance.

In the future I will definitely have increased respect for the importance of branch prediction, and
I'll be keeping `perf` in mind for testing the impacts of my algorithm micro optimizations!

### Appendix: REPL Session

Example REPL session I used while collecting the profiling data described in this post.

```scala
[info] Starting scala interpreter...
Welcome to Scala 2.12.8 (OpenJDK 64-Bit Server VM, Java 1.8.0_232).
Type in expressions for evaluation. Or try :help.

scala> import org.isarnproject.sketches.java._, org.apache.commons.math3.distribution._, java.util.Arrays
import org.isarnproject.sketches.java._
import org.apache.commons.math3.distribution._
import java.util.Arrays

scala> import Benchmark.binarySearchBenchmark, Benchmark.sorted
import Benchmark.binarySearchBenchmark
import Benchmark.sorted

scala> val dist = new NormalDistribution()
dist: org.apache.commons.math3.distribution.NormalDistribution = org.apache.commons.math3.distribution.NormalDistribution@2e4cab3

scala> val data1 = (Array.fill(10000000) { dist.sample })
data1: Array[Double] = Array(-0.4212043116313411, -0.08710946554151702, -0.8715699258940406, 0.18258993603751858, 1.6202520461169774, -1.0829132672235064, -0.10183053159274344, -1.7704471931083408, 0.06537721809664918, 0.4489025103455295, 1.451825799021764, 0.2539605776791365, 0.3144704891701215, -0.915937134358965, 1.1287538773134418, -1.5224783574089704, 0.20364567021356444, -0.05358925557797462, 1.7791123474673352, -1.02002549760057, -0.3186447688601013, -0.29900901035274124, -1.1364830460150654, 0.808126490299925, -0.18770051609181915, -1.8960508749530325, -0.4401736833702351, 1.2504457636261428, -0.3227823655320975, -0.23985606314007366, -1.0958686785628784, 0.765483097060797, 1.0558189751769567, -0.24442120924877686, -1.4069853663904506, -0.49414981345363...

scala> val sort1 = data1.sorted
sort1: Array[Double] = Array(-5.183000320009156, -4.963410845587395, -4.849957411514204, -4.773363802342855, -4.766727332884228, -4.763541482030958, -4.737617255946851, -4.733388405880019, -4.729197149737186, -4.725054967357706, -4.715725426893964, -4.713825891210208, -4.688676193805154, -4.679822229926074, -4.67675842259188, -4.664080520133231, -4.658765896497175, -4.646101496645823, -4.64405239484001, -4.636466832162827, -4.620863751279545, -4.609421490678068, -4.607022762150717, -4.596841931248354, -4.581339497590358, -4.579320172011298, -4.579016409552816, -4.577887574619456, -4.572114335473153, -4.571272051862831, -4.5689829552036505, -4.564198970696653, -4.537409853374507, -4.52673280716509, -4.520181249697995, -4.505261541887607, -4.500796838691936, -4.4...

scala> Benchmark.sample(10) { binarySearchBenchmark(data1, sorted) }
res0: Array[(Double, Unit)] = Array((0.166,()), (0.163,()), (0.165,()), (0.164,()), (0.164,()), (0.165,()), (0.164,()), (0.164,()), (0.164,()), (0.166,()))

scala> Benchmark.sample(10) { binarySearchBenchmark(sort1, sorted) }
res1: Array[(Double, Unit)] = Array((0.057,()), (0.054,()), (0.059,()), (0.054,()), (0.054,()), (0.054,()), (0.054,()), (0.054,()), (0.056,()), (0.054,()))

scala> Benchmark.sample(100) { binarySearchBenchmark(data1, sorted) }
res2: Array[(Double, Unit)] = Array((0.206,()), (0.166,()), (0.166,()), (0.169,()), (0.185,()), (0.176,()), (0.166,()), (0.167,()), (0.165,()), (0.166,()), (0.167,()), (0.166,()), (0.164,()), (0.167,()), (0.165,()), (0.165,()), (0.166,()), (0.167,()), (0.164,()), (0.167,()), (0.165,()), (0.165,()), (0.166,()), (0.165,()), (0.164,()), (0.166,()), (0.165,()), (0.165,()), (0.166,()), (0.18,()), (0.175,()), (0.173,()), (0.167,()), (0.166,()), (0.167,()), (0.164,()), (0.174,()), (0.177,()), (0.175,()), (0.178,()), (0.176,()), (0.168,()), (0.169,()), (0.166,()), (0.166,()), (0.165,()), (0.167,()), (0.164,()), (0.165,()), (0.165,()), (0.166,()), (0.165,()), (0.166,()), (0.165,()), (0.165,()), (0.164,()), (0.165,()), (0.165,()), (0.166,()), (0.165,()), (0.164,()), (0.1...

scala> Benchmark.sample(100) { binarySearchBenchmark(sort1, sorted) }
res3: Array[(Double, Unit)] = Array((0.063,()), (0.056,()), (0.054,()), (0.056,()), (0.055,()), (0.056,()), (0.056,()), (0.057,()), (0.06,()), (0.055,()), (0.055,()), (0.054,()), (0.061,()), (0.079,()), (0.06,()), (0.065,()), (0.071,()), (0.069,()), (0.063,()), (0.059,()), (0.057,()), (0.056,()), (0.057,()), (0.054,()), (0.056,()), (0.054,()), (0.055,()), (0.054,()), (0.055,()), (0.054,()), (0.055,()), (0.055,()), (0.056,()), (0.056,()), (0.054,()), (0.054,()), (0.054,()), (0.054,()), (0.054,()), (0.054,()), (0.054,()), (0.056,()), (0.054,()), (0.055,()), (0.054,()), (0.054,()), (0.053,()), (0.054,()), (0.054,()), (0.054,()), (0.053,()), (0.056,()), (0.054,()), (0.054,()), (0.054,()), (0.054,()), (0.055,()), (0.054,()), (0.054,()), (0.055,()), (0.054,()), (0.05...

```
