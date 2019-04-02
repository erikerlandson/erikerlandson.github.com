---
layout: post
title: "A Bi-directional Variation of the O(NP) Edit Distance Algorithm"
date: 2014-02-20 19:51
comments: true
tags: [ computing, edit distance, string distance, string difference, sequence comparison, myers algorithm, optimization, bidirectional, divide and conquer ]
---
The O(ND) edit distance algorithm [[1]](#ref1) is a standard for efficient computation of the edit distance between two sequences, appearing in applications such as the GNU diff tool.  There is also a variation [[2]](#ref2) that operates in O(NP) time, where P is the number of deletions in the shortest edit path, and which has lower computational complexity, since P <= D (and may be << D in some circumstances).  In order to apply these algorithms to obtain an _edit script_ in linear space, they must be adapted into a bidirectional form that enables recursive divide-and-conquer.   The basic principles of a bidirectional adaptation of the O(ND) algorithm are described in [[1]](#ref1).   However, no such discussion of a bidirectional O(NP) algorithm is provided in [[2]](#ref2).  Understanding this adaptation involves some observations that aren't immediately obvious.  In this post, I will describe these key observations.

### Notation
My code segments are written as C/C++, however written in a simplified style I hope will be clear regardless of what languages the reader is familiar with.  If you wish to port this (pseudo-ish)code, it may be worth keeping in mind that indexing is zero-based in C/C++.

### Sequence Lengths
A brief note on the O(NP) algorithm and sequence lengths: the algorithm assumes that the length of its second sequence argument is >= its first (that is, N >= M).   In the following discussions, I will be making the same assumption, however the modification to address N < M is relatively easy, and can be seen in the references to actual source code below.

### Indexing
A note on naming:  In [[2]](#ref2), the authors use 'fp' for the name of the array holding path endpoints.  I will use 'Vf' for the array holding forward endpoints, and 'Vr' for the corresponding array holding reverse endpoints.

The O(ND) and O(NP) algorithms operate by iteratively extending the frontier of edit paths through the implicit graph of possible paths, where each iteration is computed as a function of the previous.  In the O(NP) algorithm, this computation has to proceed from the outside in, as described in the paper:

    for (k = -P;  k < delta;  k += 1) {
        y = max(Vf[k-1] + 1, Vf[k+1]);
        Vf[k] = snake(y-k, y);
    }
    for (k = P + delta;  k >= delta;  k -= 1) {
        y = max(Vf[k-1] + 1, Vf[k+1]);
        Vf[k] = snake(y-k, y);
    }

In order to implement a bi-directional algorithm, we must also run the algorithm in reverse, beginning at the "lower right corner" of the graph (M,N) and working backward to the origin (0,0).  The indexing is the mirror image of the above:

    for (k = P+delta;  k > 0;  k -= 1) {
        y = min(Vr[k-1], Vr[k+1] - 1);
        Vr[k] = rsnake(y-k, y);
    }
    for (k = -P;  k <= 0;  k += 1) {
        y = min(Vr[k-1], Vr[k+1] - 1);
        Vr[k] = rsnake(y-k, y);
    }

In the above, 'rsnake' is the reverse-direction snake function.  A note on initialization:  whereas the forward algorithm initializes its Vf array to (-1), the symmetric initial value for the reverse algorithm Vr array is (N+1) (In the general case, 1 plus the length of the longest sequence).

### Detecting Path Overlap
The uni-directional O(NP) algorithm halts when Vf[delta] == N.  However, the bi-directional algorithms halt when shortest opposing paths meet -- or overlap -- each other, as described in the O(ND) paper [[1]](#ref1).  The semantics of storing paths in working arrays is the same in both algorithms, with the exception that in the O(NP) algorithm it is the (y) values that are stored.  Myers describes the predicate for detecting meeting paths in O(ND) as: (x >= u)  &&  (x-y == u-v), where (x,y) are forward endpoints and (u,v) are reverse endpoints.  Observe that since y = x-k, then (x-y == u-v) is equivalent to "forward-k == reverse-k".  However, in operation one always checks the opposing path with the _same_ k index, and so this clause is redundant.  It is sufficient to check that (x >= u), or in the case of O(NP), that (y >= v).  In the code, this looks something like:

    y = max(Vf[k-1] + 1, Vf[k+1]);
    if (y >= Vr[k]) {
        // overlapping paths detected 
    }

The other checks for forward and reverse are similar.  Note that these checks happen at the _beginning_ of each 'snake', that is prior to invoking the snake extension logic.  The semantic is that the opposing path overlaps the run (snake) one is about to start.

### Computing Distance
When two overlapping paths are detected, we must compute the path distance associated with their union.  In the O(ND) algorithm, we know that distance implicitly, as the paths are extended over successive iterations of D.  In the O(NP) algorithm, however, the current path endpoints are associated with a particular value of P, and so we must consider how to obtain the actual distance.

A little algebra comes to the rescue.  At iteration P, consider the number of deletions along the forward-path at the kth endpoint, which I will denote as 'vf' (the authors refer to it as V(x,y)).  In [[2]](#ref2), the authors show that P == vf when k < delta, and P == vf+k-delta, when k > delta (note that either formula applies for k == delta).  Solving for vf, we have:   vf == P for k < delta and vf == P+delta-k for k > delta.  The authors also show that: vf = (df-k)/2, where df is the total edit distance along the path up to the current endpoint (the authors refer to df as D(x,y)).   Therefore, we have: df = 2(vf)+k, where we can obtain vf from the expression we just derived.

It remains to derive the expressions for the reverse direction, where we want 'vr' and 'dr'.  Here, I note that the mirror-image indexing of the reverse algorithm implies that the expressions above work if we transform k --> delta-k.  Making that transform gives us:   vr == P for k > 0 and vr == P+k for k < 0 (again, either applies for k == 0).  And dr = 2(vr)+delta-k.

And so the actual edit distance covered by our overlapping paths is:  d == (df+dr) == 2(vf+vr)+delta.  Note now pleasing this is, as vf+vr is the number of deletions of the combined paths, and so this corresponds to the original formula D == 2P+delta, where P is the number of deletions over the entire pathway.  We also see from the above that at a given Pth iteration, P does _not_ equal the number of deletions in all paths with endpoints at the current iteration.  The true number of deletions for a given endpoint is a function of P, k and delta.

A note on implementation: when one is advancing forward paths, an overlapping reverse-path will be from previous iteration (P-1), as the reverse paths for (P) have not happened yet.  That will show up in the distance formula for (vr) by using (P-1) in place of P, as in this example code:

    y = max(Vf[k-1] + 1, Vf[k+1]);
    if (y >= Vr[k]) {
        // we found overlapping path, so compute corresponding edit distance
        vf = (k>delta) ? (P + delta - k) : P;
        // use (P-1) for reverse paths:
        vr = (k<0) ? (P-1 + k) : P-1;
        d = 2*(vf+vr)+delta;
    }

    // ....

    y = min(Vr[k-1], Vr[k+1] - 1);
    if (y <= Vf[k]) {
        // we can use P for both since forward-paths have been advanced:
        vf = (k>delta) ? (P + delta - k) : P;
        vr = (k<0) ? (P + k) : P;
        d = 2*(vf+vr)+delta;
    }

### Shortest Path
With respect to halting conditions, the O(NP) algorithm differs in one imporant way from the O(ND) algorithm: The O(ND) algorithm maintains path endpoints corresponding to increasing _distance_ (D) values.  Therefore, when two paths meet, they form a shortest-distance path by definition, and the algorithm can halt on the first such overlap it detects.  

The same is _not true_ for the O(NP) algorithm.  It stores endpoints at a particular P value.  However, at a given value of P, actual _distances_ may vary considerably.  On a given iteration over P, actual path distances may vary from 2(P-1)+delta up to 4P+delta.  

This problem is dealt with by maintaining a best-known distance, 'Dbest', which is initialized to its maximum possible value of N+M, the sum of both sequence lengths.  Whenever two overlapping paths are detected, their corresponding distance 'd' is computed as described earlier, and the running minimum is maintainted:  Dbest = min(Dbest,d).  As mentioned above, we know that the mimimum possible distance at a given iteration is Dmin = 2(P-1)+delta, and so when Dmin >= Dbest, we halt and return Dbest as our result.

### Loop Bounding
Some important computational efficiency can be obtained by reorganizing the looping over the endpoints.   As mentioned above, conceptually the looping proceeds from the outside, inward.  Suppose we organize the looping over k values such that we explore k = {-P, P+delta, -P+1, P+delta-1, -P+2, P+delta-2 ... }  Note that the symmetry breaks a bit when we get to k==delta, as here we stop iterating backward, but continue iterating forward until we hit delta from below.  In the code, this looping pattern looks something like:

    // advance forward paths: reverse path looping is similar
    for (ku = -P, kd = P+delta;  ku <= delta;  ku += 1) {
        // advance diagonals from -P, upwards:
        y = max(1+Vf[ku-1], Vf[ku+1]);

        // check for overlapping path

        Vf[ku] = snake(y-ku, y);

        // stop searching backward past here:
        if (kd <= delta) continue;

        // advance diagonals from P+delta, downwards:
        y = max(1+Vf[kd-1], Vf[kd+1]);

        // check for overlapping path

        Vf[kd] = snake(y-kd, y);
        kd -= 1;
    }

There is method to this madness.  Observe that for any particular P value, the smallest edit distances are at the outside, and get larger as one moves inward.  The minimum distance 2P+delta is always when k == -P, and k == P+delta.  As we proceed inward, the corresponding edit distance increases towards its maximum of 4P+delta.   This allows _two_ optimizations.  The first is that if we hit an overlapping path, we can now exit the loop immediately, as we know that any other such overlapping paths to our inside will have a larger edit distance, and so do not need to be considered.

The second optimization is to recall that path distances are a function of P, k and delta.  We can use this information to solve for k and obtain a useful adaptive bound on how far we loop.  From previous sections, also recall we are keeping a best-known distance Dbest.  We know that we do not have to explore any paths whose distance is >= Dbest.  So, we can set up the following inequality: 2(vf+vr)+delta < Dbest, where vf = P, and vr = (P-1)+k, where k < 0, which is the region where distance is growing.  Therefore, we have 2(P+(P-1)+k)+delta < Dbest.  Solving for k, we have:  k < ((Dbest-delta)/2)-2P+1.  The looping wants to use '<=', so we can rewrite as: k <= ((Dbest-delta-1)/2)-2P+1.  For the reverse-path looping, we can set up a similar inequality:  2(P+P+delta-k)+delta < Dbest, which yields:  k >= ((1+delta-Dbest)/2)+delta+2P.

Note that if these bound expressions evaluate to a value past the nominal bound, then the nominal bound remains in effect: e.g. the operative forward looping bound = min(delta, ((Dbest-delta)/2)-2P).   Also note that these constraints do not break the computation of the endpoints, because when the bounds move, they always retreat toward the outside by 2 on each iteration of P.  Since computation proceeds outside in, that means the necessary values are always correctly populated from the previous iteration.

In the code, the forward path looping looks like this:

    // compute our adaptive loop bound (using P-1 for reverse)
    bound = min(delta, ((Dbest-delta-1)/2)-(2*P)+1);

    // constrain our search by bound:
    for (ku = -P, kd = P+delta;  ku <= bound;  ku += 1) {
        y = max(1+Vf[ku-1], Vf[ku+1]);
        if (y >= Vr[k]) {
            vf = (k>delta) ? (P + delta - k) : P;
            vr = (k<0) ? (P-1 + k) : P-1;

            // maintain minimum distance:
            Dbest = min(Dbest, 2*(vf+vr)+delta);

            // we can now halt this loop immediately:
            break;
        }

        Vf[ku] = snake(y-ku, y);

        if (kd <= delta) continue;

        y = max(1+Vf[kd-1], Vf[kd+1]);
        if (y >= Vr[k]) {
            vf = (k>delta) ? (P + delta - k) : P;
            vr = (k<0) ? (P-1 + k) : P-1;

            // maintain minimum distance:
            Dbest = min(Dbest, 2*(vf+vr)+delta);

            // we can now halt this loop immediately:
            break;
        }

        Vf[kd] = snake(y-kd, y);
        kd -= 1;
    }

### Implementation
In conclusion, I will display a code segment with all of the ideas presented above, coming together.  This segment was taken from my [working prototype code](https://github.com/erikerlandson/algorithm/blob/order_np_alg/include/boost/algorithm/sequence/detail/edit_distance.hpp#L342), with some syntactic clutter removed and variable names changed to conform a bit more closely to [[2]](#ref2).  The implementation of O(NP) below is performing about 25% faster than the corresponding O(ND) algorithm in my benchmarking tests, and also uses substantially less memory.

    // initialize this with the maximum possible distance:
    Dbest = M+N;

    P = 0;
    while (true) {
        // the minimum possible distance for the current P value
        Dmin = 2*(P-1) + delta;

        // if the minimum possible distance is >= our best-known distance, we can halt
        if (Dmin >= Dbest) return Dbest;

        // adaptive bound for the forward looping
        bound = min(delta, ((Dbest-delta-1)/2)-(2*P)+1);

        // advance forward diagonals
        for (ku = -P, kd = P+delta;  ku <= bound;  ku += 1) {
            y = max(1+Vf[ku-1], Vf[ku+1]);
            x = y-ku;

            // path overlap detected
            if (y >= Vr[ku]) {
                vf = (ku>delta) ? (P + delta - ku) : P;
                vr = (ku<0) ? (P-1 + ku) : P-1;
                Dbest = min(Dbest, 2*(vf+vr)+delta);
                break;
            }

            // extend forward snake
            if (N >= M) {
                while (x < M  &&  y < N  &&  equal(S1[x], S2[y])) { x += 1;  y += 1; }
            } else {
                while (x < N  &&  y < M  &&  equal(S1[y], S2[x])) { x += 1;  y += 1; }
            }

            Vf[ku] = y;

            if (kd <= delta) continue;

            y = max(1+Vf[kd-1], Vf[kd+1]);
            x = y-kd;

            // path overlap detected
            if (y >= Vr[kd]) {
                vf = (kd>delta) ? (P + delta - kd) : P;
                vr = (kd<0) ? (P-1 + kd) : P-1;
                Dbest = min(Dbest, 2*(vf+vr)+delta);
                break;
            }

            // extend forward snake
            if (N >= M) {
                while (x < M  &&  y < N  &&  equal(S1[x], S2[y])) { x += 1;  y += 1; }
            } else {
                while (x < N  &&  y < M  &&  equal(S1[y], S2[x])) { x += 1;  y += 1; }
            }

            Vf[kd] = y;
            kd -= 1;
        }

        // adaptive bound for the reverse looping
        bound = max(0, ((1+delta-Dbest)/2)+delta+(2*P));

        // advance reverse-path diagonals:
        for (kd=P+delta, ku=-P;  kd >= bound;  kd -= 1) {
            y = min(Vr[kd-1], Vr[kd+1]-1);
            x = y-kd;

            // path overlap detected
            if (y <= Vf[kd]) {
                vf = (kd>delta) ? (P + delta - kd) : P;
                vr = (kd<0) ? (P + kd) : P;
                Dbest = min(Dbest, 2*(vf+vr)+delta);
                break;
            }

            // extend reverse snake
            if (N >= M) {
                while (x > 0  &&  y > 0  &&  equal(S1[x-1], S2[y-1])) { x -= 1;  y -= 1; }
            } else {
                while (x > 0  &&  y > 0  &&  equal(S1[y-1], S2[x-1])) { x -= 1;  y -= 1; }
            }

            Vr[kd] = y;

            if (ku >= 0) continue;

            y = min(Vr[ku-1], Vr[ku+1]-1);
            x = y-ku;

            // path overlap detected
            if (y <= Vf[ku]) {
                vf = (ku>delta) ? (P + delta - ku) : P;
                vr = (ku<0) ? (P + ku) : P;
                Dbest = min(Dbest, 2*(vf+vr)+delta);
                break;
            }

            // extend reverse snake
            if (N >= M) {
                while (x > 0  &&  y > 0  &&  equal(S1[x-1], S2[y-1])) { x -= 1;  y -= 1; }
            } else {
                while (x > 0  &&  y > 0  &&  equal(S1[y-1], S2[x-1])) { x -= 1;  y -= 1; }
            }

            Vr[ku] = y;
            ku += 1;
        }
    }


### References
<a name="anchor1" id="ref1">[1] </a>[An O(ND) Difference Algorithm and its Variations](http://www.xmailserver.org/diff2.pdf), Eugene W. Myers<br>
<a name="anchor2" id="ref2">[2] </a>[An O(NP) Sequence Comparison Algorithm](http://www.itu.dk/stud/speciale/bepjea/xwebtex/litt/an-onp-sequence-comparison-algorithm.pdf), Sun Wu, Udi Manber, Gene Myers
