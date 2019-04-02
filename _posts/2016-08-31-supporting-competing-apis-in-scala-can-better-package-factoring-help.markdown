---
layout: post
title: "Supporting Competing APIs in Scala -- Can Better Package Factoring Help?"
date: 2016-08-31 17:55
comments: true
tags: [ computing, API, packaging, scala ]
---

 On and off over the last year, I've been working on a [library](http://erikerlandson.github.io/blog/2015/09/26/a-library-of-binary-tree-algorithms-as-mixable-scala-traits/) of tree and map classes in Scala that happen to make use of some algebraic structures (mostly monoids or related concepts).
 In my initial implementations, I made use of the popular [algebird](https://github.com/twitter/algebird) variations on monoid and friends.
 In their incarnation as an [algebird PR](https://github.com/twitter/algebird/pull/496) this was uncontroversial to say the least, but lately I have been re-thinking them as a [third-party Scala package](https://github.com/isarn/isarn/pull/1).

This immediately raised some interesting and thorny questions:
in an ecosystem that contains not just [algebird](https://github.com/twitter/algebird), but other popular alternatives such as [cats](https://github.com/typelevel/cats) and [scalaz](https://github.com/scalaz/scalaz), what algebra API should I use in my code?
How best to allow the library user to interoperate with the algebra libray of their choice?
Can I accomplish these things while also avoiding any problematic package dependencies in my library code?

In Scala, the second question is relatively straightforward to answer.
I can write my interface using [implicit conversions](http://docs.scala-lang.org/tutorials/tour/implicit-conversions), and provide sub-packages that provide such conversions from popular algebra libraries into the library I actually use in my code.
A library user can import the predefined implicit conversions of their choice, or if necessary provide their own.

So far so good, but that leads immediately back to the first question -- what API should **_I_** choose to use internally in my own library?

One obvious approach is to just pick one of the popular options (I might favor `cats`, for example) and write my library code using that.
If a library user also prefers `cats`, great.
Otherwise, they can import the appropritate implicit conversions from their favorite alternative into `cats` and be on their way.

But this solution is not without drawbacks.
Anybody using my library will now be including `cats` as a transitive dependency in their project, even if they are already using some other alternative.
Although `cats` is not an enormous library, that represents a fair amount of code sucked into my users' projects, most of which isn't going to be used at all.
More insidiously, I have now introduced the possiblity that the `cats` version I package with is out of sync with the version my library users are building against.
Version misalignment in transitive dependencies is a land-mine in project builds and very difficult to resolve.

A second approach I might use is to define some abstract algebraic traits of my own.
I can write my libraries in terms of this new API, and then provide implicit conversions from popular APIs into mine.

This approach has some real advantages over the previous.  Being entirely abstract, my internal API will be lightweight.  I have the option of including only the algebraic concepts I need.  It does not introduce any possibly problematic 3rd-party dependencies that might cause code bloat or versioning problems for my library users.

Although this is an effective solution, I find it dissatisfying for a couple reasons.
Firstly, my new internal API effectively represents _yet another competing algebra API_, and so I am essentially contributing to the proliferating-standards antipattern.

![standards](https://imgs.xkcd.com/comics/standards.png)

Secondly, it means that I am not taking advantage of community knowledge.
The `cats` library embodies a great deal of cumulative human expertise in both category theory and Scala library design.
What does a good algebra library API look like?
Well, _it's likely to look a lot like `cats`_ of course!
The odds that I end up doing an inferior job designing my little internal vanity API are rather higher than the odds that I do as well or better.
The best I can hope for is to re-invent the wheel, with a real possibility that my wheel has corners.

Is there a way to resolve this unpalatable situation?
Can we design our projects to both remain flexible about interfacing with multiple 3rd-party alternatives, but avoid effectively writing _yet another alternative_ for our own internal use?

I hardly have any authoritative answers to this problem, but I have one idea that might move toward a solution.
As I alluded to above, when I write my libraries, I am most frequently _only_ interested in the API -- the abstract interface.
If I did go with writing my own algebra API, I would seek to define purely abstract traits.
Since my intention is that my library users would supply their own favorite library alternative, I would have no need or desire to instantiate any of my APIs.
That function would be provided by the separate sub-projects that provide implicit conversions from community alternatives into my API.

On the other hand, what if `cats` and `algebird` factored _their_ libraries in a similar way?
What if I could include a sub-package like `cats-kernel-api`, or `algebird-core-api`, which contained _only_ pure abstract traits for monoid, semigroup, etc?
Then I could choose my favorite community API, and code against it, with much less code bloat, and a much reduced vulnerability to any versioning drift.
I would still be free to provide implicit conversions and allow _my_ users to make their own choice of library in their projects.

Although I find this idea attractive, it is certainly not foolproof.
For example, there is never a way to _guarantee_ that versioning drift won't break an API.
APIs such as `cats` and `algebird` are likely to be unusually amenable to this kind of approach.
After all, their interfaces are primarily driven by underlying mathematical definitions, which are generally as stable as such things ever get.
However, APIs in general tend to be significantly more stable than underlying code.
And the most-stable subsets of APIs might be encoded as traits and exposed this way, allowing other more experimental API components to change at a higher frequency.
Perhaps library packages could even be factored in some way such as `library-stable-api` and `library-unstable-api`.
That would clearly add a bit of complication to library trait hierarchies, but the payoff in terms of increased 3rd-party usability might be worth it.
