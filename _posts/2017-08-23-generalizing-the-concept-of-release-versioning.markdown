---
layout: post
title: "Rethinking the Concept of Release Versioning"
date: 2017-08-23 17:22
comments: true
categories: [ computing, versioning, semantic versioning, release, software builds ]
---
Recently I've been thinking about a few related problems with our current concepts of software release versioning, release dependencies and release building.
These problems apply to software releases in all languages and build systems that I've experienced,
but in the interest of keeping this post as simple as possible I'm going to limit myself to talking about the Maven ecosystem of release management and build tooling.

Consider how we annotate and refer to release builds for a Scala project:
The _version_ of Scala -- 2.10, 2.11, etc -- that was used to build the project is a _qualifier_ for the release.
For example, if I am building a project using Scala 2.11, and package P is one of my project dependencies, then the maven build tooling (or sbt, etc) looks for a version of P that was _also_ built using Scala 2.11;
the build will fail if no such incarnation of P can be located.
This build constraint propagates recursively throughout the entire dependency tree for a project.

Now consider how we treat the version for the package P dependency itself:
Our build tooling forces us to specify one exact release version x.y.z for P.
This is superficially similar to the constraint for building with Scala 2.11, but _unlike_ the Scala constraint, the knowledge about using P x.y.z is not propagated down the tree.

If the dependency for P appears only once in the depenency tree, everything is fine.
However, as anybody who has ever worked with a large dependency tree for a project knows, package P might very well appear in multiple locations of the dep-tree, as a transitive dependency of different packages.
Worse, these deps may be specified as _different versions_ of P, which may be mutually incompatible.

Transitive dep incompatibilities are a particularly thorny problem to solve, but there are other annoyances related to release versioning.
Often a user would like a "major" package dependency built against a particular version of that dep.
For example, packages that use Apache Spark may need to work with a particular build version of Spark (2.1, 2.2, etc).
If I am the package purveyor, I have no very convenient way to build my package against multiple versions of spark, and then annotate those builds in Maven Central.
At best I can bake the spark version into the name.
But what if I want to specify other package dep verions?
Do I create package names with increasingly-long lists of (package,version) pairs hacked into the name?

Finally, there is simply the annoyance of revving my own package purely for the purpose of building it against the latest versions of my dependencies.
None of my code has changed, but I am cutting a new release just to pick up current dependency releases.
And then hoping that my package users will want those particular releases, and that these won't break _their_ builds with incompatible transitive deps!

I have been toying with a release and build methodology for avoiding these headaches. What follows is full of vigorous hand-waving,
but I believe something like it could be formalized in a useful way.

The key idea is that a release _build_ is defined by a _build signature_ which is the union of all `(dep, ver)` pairs.
This includes:

1. The actual release version of the package code, e.g. `(mypackage, 1.2.3)`
1. The `(dep, ver)` for all dependencies (taken over all transitive deps, recursively)
1. The `(tool, ver)` for all impactful build tooling, e.g. `(scala, 2.11)`, `(python, 3.5)`, etc

For example, if I maintain a package `P`, whose latest code release is `1.2.3`,
built with dependencies `(A, 0.5)`, `(B, 2.5.1)` and `(C, 1.7.8)`, and dependency `B` built against `(Q, 6.7)` and `(R, 3.3)`,
and `C` built against `(Q, 6.7)`
and all compiled with `(scala, 2.11)`, then the build signature will be:

`{ (P, 1.2.3), (A, 0.5), (B, 2.5.1), (C, 1.7.8), (Q, 6.7), (R, 3.3), (scala, 2.11) }`

Identifying a release build in this way makes several interesting things possible.
First, it can identify a build with a transitive dependency problem.
For example, if `C` had been built against `(Q, 7.0)`,
then the resulting build signature would have _two_ pairs for `Q`; `(Q, 6.7)` and `(Q, 7.0)`,
which is an immediate red flag for a potential problem.

More intriguingly, it could provide a foundation for _avoiding_ builds with incompatible dependencies.
Suppose that I redefine my build logic so that I only specify dependency package names, and not specific versions.
Whenever I build a project, the build system automatically searches for the most-recent version of each dependency.
This already addresses some of the release headaches above.
As a project builder, I can get the latest versions of packages when I build.
As a package maintainer, I do not have to rev a release just to update my package deps;
projects using my package will get the latest by default.
Moreover, because the latest package release is always pulled, I never get multiple incompatible dependency releases
in a build.

Suppose that for some reason I _need_ a particular release of some dependency.
From the example above, imagine that I must use `(Q, 6.7)`.
We can imagine augmenting the build specification to allow overriding the default behavior of pulling the most recent release.
We might either specify a specific version as we do currently, or possibly specify a range of releases, as systems like brew or ruby gemfiles allow.
In the case where some constraint is placed on releases, this constraint would be propagaged down the tree (or possibly up from the leaves),
in essentially the same way that the constraint of scala version is already.
In the event that the total set of constraints over the whole dependency tree is not satisfiable, then the build will fail.

With a build annotation system like the one I just described, one could imagine a new role for registries like Maven Central,
where different builds are automatically cached.
The registry could maybe even automatically run CI testing to identify the most-recent versions of package dependencies that satisfy
any given package build,
or perhaps valid dependency release ranges.

To conclude, I believe that re-thinking how we describe the dependencies used to build and annotate package releases,
by generalizing release version to include the release version of all transitive deps (including build tooling as deps),
may enable more flexible ways to both build software releases and specify them for pulling.

Happy Computing!
