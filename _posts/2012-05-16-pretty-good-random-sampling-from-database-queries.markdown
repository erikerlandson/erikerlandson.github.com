---
layout: post
title: "Pretty Good Random Sampling from Database Queries"
date: 2012-05-16 07:05
comments: true
tags: [databases, mongodb, computing, pymongo, machine learning, random sampling]
---
Suppose you want to add random sampling to a database query, but your database does not support it.  One known technique is to add a field, say "rk", that contains a random key value in [0,1), index on that field, and add a clause to the query:  `("rk" >= x  &&  "rk" < x+p)`, where p is your desired random sampling probability and x is randomly chosen from [0,1-p).

This is not bad, but we can see it is not _truly_ randomized, as the sliding window [x,x+p) over the "rk" random key field generates overlap in the samplings.  The larger the value of p, the more significant the overlapping effect will be.

Eliminating this effect absolutely (and maintaining query efficiency) is difficult without direct database support, however we can take steps to significantly reduce it.  Suppose we generated _two_ independently randomized keys "rk0" and "rk1".  We could sample using a slightly more complex clause: `(("rk0" >= x0  && "rk0" < x0+d) || ("rk1" >= x1  &&  "rk1" < x1+d))`, where x0 and x1 are randomly selected from [0,1-d).

What value do we use for d to maintain a random sampling factor of p?  As "rk0" and "rk1" are independent random variables, the effective sampling factor p is given by p = d + d - d^2, where the d^2 accounts for query results present in both the "rk0" and "rk1" subqueries.  Applying the quadratic formula to solve for d gives us: d = 1-sqrt(1-p).

This approach should be useable with any database.  Here is example code I wrote for generating the random sampling portion of a mongodb query in pymongo:

    def random_sampling_query(p, rk0="rk0", rk1="rk1", pad = 0):
        d = (1.0 - sqrt(1.0-p)) * (1.0 + pad)
        if d > 1.0: d = 1.0
        if d < 0.0: d = 0.0
        s0 = random.random()*(1.0 - d)
        s1 = random.random()*(1.0 - d)
        return {"$or":[{rk0:{"$gte":s0, "$lt":s0+d}}, {rk1:{"$gte":s1, "$lt":s1+d}}]}

I included an optional 'pad' parameter to support a case where one might want a particular (integer) sample size s, and so set p = s/(db-table-size), and use padding to mitigate the probability of getting less than s records due to random sampling jitter.  In mongodb one could then append `limit(s)` to the query return, and get exactly s returns in most cases, with the correct padding.

Here is a pymongo example of using the `random_sampling_query()` above:

    # get a query that does random sampling of 1% of the results:
    query = random_sampling_query(0.01)
    # other query clauses can be added if desired:
    query[user] = "eje"
    # issue the final query to get results with random sampling:
    qres = data.find(query)

One could extend the logic above by using 3 independent random fields rk0,rk1,rk2 and applying the cubic formula, or four fields and the quartic formula, but I suspect that is passing the point of diminishing returns on storage cost, query cost and algebra.
