---
layout: post
title: "Hosting a Blog Feed Aggregator With Octopress"
date: 2012-10-05 12:52
comments: true
categories: [ computing, octopress, feed aggregator ]
---

I have written an Octopress plugin to allow turnkey support for hosting a blog feed aggregator, in Octopress idiomatic style.  I will describe the steps to install it and use it below.  Some of its current features are:

* Easy configuration and deployment, providing all feed aggregator parameters as yaml front-matter
* Turn-key generation of feed aggregator pages, in the configured site style
* Automatic removal of duplicate feed list urls, and automatic removal of duplicate posts (e.g. if multiple category feeds from the same author are listed)
* Automatic generation of feed author list as an Octopress 'aside'


###Install the feed_aggregator.rb plugin
Currently, you can obtain a copy of "feed_aggregator.rb" here:

[https://github.com/erikerlandson/erikerlandson.github.com/blob/source/plugins/feed_aggregator.rb](https://github.com/erikerlandson/erikerlandson.github.com/blob/source/plugins/feed_aggregator.rb)

Simply copy this file into the plugins directory for your octopress repo:

    $ cp feed_aggregator.rb /path/to/your/octopress/repo/plugins


###Install the feed_aggregator.html layout
You can obtain a copy of the layout file "feed_aggregator.html" here:

[https://github.com/erikerlandson/erikerlandson.github.com/blob/source/source/_layouts/feed_aggregator.html](https://github.com/erikerlandson/erikerlandson.github.com/blob/source/source/_layouts/feed_aggregator.html)

    $ cp feed_aggregator.html /path/to/your/octopress/repo/source/_layouts


###Add feedzirra dependency to the Octopress Gemfile
Octopress wants its dependencies bundled, so you will want to add this dependency to /path/to/your/octopress/repo/Gemfile:

    gem 'feedzirra', '~> 0.1.3'

Then update the bundles:

    $ bundle update


###Create a page for your feed aggregator
Here is an example feed aggregator:

    ---
    layout: feed_aggregator
    title: My Blog Feed Aggregator
    post_limit: 5
    feed_list:
      - http://blog_site_1.com/atom.xml
      - http://blog_site_2.com/atom.xml
      - http://blog_site_3.com/atom.xml
    ---

As you can see, you only need to supply some yaml front-matter.  Page formatting/rendering is performed automatically from the information in the header.  You must use `layout: feed_aggregator`, and include the standard `title` to use for the aggregator title.  `post_limit: 5` Indicates that at most 5 posts from each feed will be included.  Finally, the `feed_list` parameter allows you to list each feed url you wish to aggregate.

Once you've created the page, you can publish as usual:

    $ rake generate
    $ rake deploy

If you want to update your feed automatically, you can set up a cron job:

    cd /path/to/octopress/repo
    rake generate
    rake deploy


###Screen Shot

Here is a screen shot of a feed aggregator.  It respects whatever style theme is configured for the site.  The aggregator title is at the top, and a list of contributing authors is automatically generated as an 'aside'.  Each author name links to the parent blog of the author's feed.  In addition to the standard date, the author's name is also included.  Post titles link back to the original post url.

![Aggregator Screen Shot](/assets/feed_aggregator/screen1.png)


###To Do

* I'd like to have a 'meta feed' from the feed aggregator generated automatically, if requested
* The current version of feedzirra does not appear to fail gracefully when it is given a bad url
* It might be nice to support the display of an avatar/icon for authors
* Issue a pull request, so the feed aggregator can be included as a standard octopress feature
