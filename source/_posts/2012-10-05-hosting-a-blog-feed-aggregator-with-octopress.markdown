---
layout: post
title: "Hosting a Blog Feed Aggregator With Octopress"
date: 2012-10-05 12:52
comments: true
categories: [ computing, octopress, feed aggregator, blog, blog feed ]
---

I have written an Octopress plugin to allow turnkey support for hosting a blog feed aggregator, in Octopress idiomatic style.  I will describe the steps to install it and use it below.  Some of its current features are:

* Easy configuration and deployment, providing all feed aggregator parameters as yaml front-matter
* Turn-key generation of feed aggregator pages, in the configured site style
* Optional generation of a 'meta-feed' in atom.xml format, from aggregated feed entries
* Automatic removal of duplicate feed list urls, and automatic removal of duplicate posts (e.g. if multiple category feeds from the same author are listed)
* Automatic generation of feed author list as an Octopress 'aside'
* Inclusion/exclusion of posts based on number of posts and/or post age
* Display of full or summary content based on number of posts and/or post age


###Install the feed_aggregator.rb plugin
Currently, you can obtain a copy of "feed_aggregator.rb" here:

[feed_aggregator.rb](https://github.com/erikerlandson/octopress/blob/feed_aggregator/plugins/feed_aggregator.rb)

Simply copy this file into the plugins directory for your octopress repo:

    $ cp feed_aggregator.rb /path/to/your/octopress/repo/plugins


###Install feed aggregator layout files
You can obtain a copy of the layout files here:

* [feed_aggregator.html](https://github.com/erikerlandson/octopress/blob/feed_aggregator/.themes/classic/source/_layouts/feed_aggregator.html)
* [feed_aggregator_page.html](https://github.com/erikerlandson/octopress/blob/feed_aggregator/.themes/classic/source/_layouts/feed_aggregator_page.html)
* [feed_aggregator_meta.xml](https://github.com/erikerlandson/octopress/blob/feed_aggregator/.themes/classic/source/_layouts/feed_aggregator_meta.xml)    

Copy the layouts files to your '_layouts' directory:

    $ cp feed_aggregator.html /path/to/your/octopress/repo/source/_layouts
    $ cp feed_aggregator_page.html /path/to/your/octopress/repo/source/_layouts
    $ cp feed_aggregator_meta.xml /path/to/your/octopress/repo/source/_layouts


###Add feedzirra dependency to the Octopress Gemfile
Octopress wants its dependencies bundled, so you will want to add this dependency to /path/to/your/octopress/repo/Gemfile:

    gem 'feedzirra', '~> 0.1.3'

Then update the bundles:

    $ bundle update


###Create a page for your feed aggregator
Here is an example feed aggregator:

    ---
    # use the 'feed_aggregator' layout to generate a feed aggregator page
    layout: feed_aggregator
    
    # Title to display for the feed
    title: My Blog Feed Aggregator
    
    # maximum number of entries from each feed url to display (defaults to 5)
    # use '0' for 'no limit'
    post_limit: 5
    
    # limit on total posts for feed (defaults to 100)
    # use 0 for 'no limit'
    post_total_limit: 50
    
    # maximum post age to include: <N> { seconds | minutes | hours | days | weeks | months | years }
    # abbreviations and plurals are supported, e.g.  w, week, weeks
    # defaults to '1 year'
    # use '0 <any-unit>' for 'no limit'
    post_age_limit: 6 months
    
    # only render full content for the first <N> posts 
    # (default is 'full content for all posts')
    # use a limit of 0 to use all summaries
    full_post_limit: 10
    
    # use summaries for all posts older than this 
    # (default is 'no maximum age')
    # works like post_age_limit
    full_post_age_limit: 1 month
    
    # generate a 'meta-feed' atom file, with the given name 'atom.xml' (meta feeds are optional)
    # (with no directory, generates in same directory as the feed aggregator page)
    meta_feed: atom.xml
    
    # list all urls to aggregate here
    # You can either specify a single feed url, or explicitly specify 'url', 'author' 
    # and/or 'author_url' params for the feed aggregator to use.
    # feed_aggregator does its best to supply these values automatically otherwise.
    feed_list:
      - http://blog_site_1.com/atom.xml
      - http://blog_site_2.com/atom.xml
      - url: http://www.john_doe.com/feed/feed.rss
        author: John Doe
        author_url: http://www.john_doe.com
    ---

As you can see, you only need to supply some yaml front-matter.  Page formatting/rendering is performed automatically from the information in the header.  You must use `layout: feed_aggregator`, and include the standard `title` to use for the aggregator title, and the `feed_list` to supply the individual feeds to aggregate.  Other parameters have default values and behaviors, which are described above.  Various `meta_feed` path behaviors are described in their own section below.

Once you've created the page, you can publish as usual:

    $ rake generate
    $ rake deploy

If you want to update your feed automatically, you can set up a cron job:

    cd /path/to/octopress/repo
    rake generate
    rake deploy


###Screen Shot

Here is a screen shot of a feed aggregator.  It respects whatever style theme is configured for the site.  The aggregator title is at the top, and a list of contributing authors is automatically generated as an 'aside'.  Each author name links to the parent blog of the author's feed.  In addition to the standard date, the author's name is also included.  Post titles link back to the original post url.

![Aggregator Screen Shot]({{ root_url }}/assets/feed_aggregator/screen1.png)

###Meta feed generation

You may optionally request that a meta feed, created from the aggregated posts, be generated.  The meta feed is created in atom format.  Following are some examples of specifying meta feed files

    # Generate a meta feed called 'atom.xml' in the same directory as the feed aggregator page
    # e.g. if the url for the feed aggregator page is  http://blog.site.com/aggregator/index.html, 
    # then the path to the meta-feed will be: http://blog.site.com/aggregator/atom.xml
    meta_feed: atom.xml

    # Generate a meta feed called 'wilma.xml' in subdirectory 'flintstones' of the website.
    # the url for this file will be:   http://blog.site.com/flintstones/wilma.xml
    meta_feed: /flintstones/wilma.xml

    # url for this will be http://blog.site.com/metafeed.xml
    meta_feed: /metafeed.xml

    # Supplying no file name is equivalent to 'meta_feed: atom.xml'
    meta_feed:

###To Do

* It might be nice to support the display of an avatar/icon for authors
