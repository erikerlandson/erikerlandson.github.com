require 'jekyll'
require 'feedzirra'


# octopress atom entries don't include author, but I can get it from the feed header,
# so add another sax parsing rule:
class Feedzirra::Parser::Atom
  element :name, :as => :author
end


module Jekyll
  class FeedAggregatorEntries < Liquid::Tag

    include Liquid::StandardFilters
    Syntax = /(#{Liquid::QuotedFragment}+)?/ 

    def initialize(tag_name, markup, tokens)
      # This tag is designed to grab its parameters from the yaml front-matter,
      # so it doesn't expect any params in-line from the markup.  So the constructor
      # has nothing to do.
      super
    end


    # extract parameters from yaml front-matter, which is available via liquid context
    def extract_params(context)
      defaults = { 'title' => 'Blog Feed', 'post_limit' => 5, 'feed_list' => [] }
      @params = defaults.merge(context['page'])

      # title to use for the blog feed
      @title = @params['title']
      # quoted strings from tag argument list have this weird quirk that the quotes are left in
      @title.gsub!(/\A['"]+|['"]+\Z/, "")

      # max number of posts to take from each feed url
      @post_limit = @params['post_limit'].to_i

      # get the list of feed urls
      @urls = @params['feed_list']
      @urls.uniq!
    end

    # render feed entries
    def render(context)
      # context['page'] includes any attributes set via yaml front-matter,
      # which we expect to include feed aggregator settings if we are being invoked
      extract_params(context)

      # aggregate all feed urls into a single list of entries
      entries = []
      authors = []
      @urls.each do |url|
        begin
          feed = Feedzirra::Feed.fetch_and_parse(url)
        rescue
          feed = nil
        end
        if not feed then
          print "failed to acquire feed url %s\n" % [url]
          next
        end

        # take entries, up to the given post limit
        ef = feed.entries.first(@post_limit)
        # if no entries, skip this feed
        next if ef.length < 1

        # if there was no feed author, try to get it from a feed entry
        if not feed.author then
          if ef.first.author then
            feed.author = ef.first.author
          else
            # if we found neither, cest la vie
            feed.author = "Author Unavailable"
          end
        end
        # grab author from feed header if it isn't in the entry itself:
        ef.each { |e| e.author = feed.author unless e.author }
        entries += ef
        # member info is per-feed:
        auth = feed.author.split(' ')
        authors << { 'first' => auth[0], 'last' => auth[1..-1].join(' '), 'url' => feed.url }
      end

      # store member list information - will be used to generate an aside with members
      context['feed_member_info'] = { 'title' => @title, 'authors' => authors }

      # eliminate any duplicate blog entries, by post id
      # (appears to be using entry url for id, which seems reasonable)
      entries.uniq! { |e| e.entry_id }

      # sort by pub date, most-recent first
      entries.sort! { |a,b| b.published <=> a.published }

      # collect html for each entry here:
      result = []

      # Inserts a blogroll title at the top
      # So far, what looked best was just doing this as an 'empty article', with underlining added
      rr = "<article>\n<header>\n <h1 align=\"center\", class=\"entry-title\"><u>%s</u></h1> </header>\n <div class=\"entry-content\">\n%s</div>\n</article>\n" % [@title,"\n"]
      result << rr

      # render the html tagging for each post in the feed
      entries.each do |e|
        pt = e.published
        ts = "<time datetime=\"%s\" pubdate data-updated=\"true\">%s %s<span>%s</span>, %s &nbsp; &mdash; &nbsp;  %s</time>" % [pt.strftime("%FT%T%:z"), pt.strftime("%b"), pt.strftime("%-d"), self.class._th(pt.day), pt.strftime("%Y"), e.author]
        rr = "<article>\n<header>\n <h1 class=\"entry-title\"> <a href=\"%s\">%s</a>\n</h1>\n  <p class=\"meta\">\n%s\n</p>\n</header>\n <div class=\"entry-content\">\n%s</div>\n</article>\n" % [e.url, e.title, ts, e.content]
        result << rr
      end

      result
    end

    def self._th(day)
      return "th" if [11,12,13].include?(day)
      d = day % 10
      return "st" if d == 1
      return "nd" if d == 2
      return "rd" if d == 3
      return "th"
    end

  end
end

module FeedAggregatorFilters
  def feed_member_aside(member_info)
    member_list = member_info['authors']
    member_list.sort! { |a,b| [a['last'],a['first']] <=> [b['last'],b['first']] }
    r = "<section>\n"
    r += "<h1>#{member_info['title']} Members</h1>\n"
    member_list.each do |e|
      r += "<a href=\"#{e['url']}\">#{e['first']} #{e['last']}</a><br>\n"
    end
    r += "</section>\n"
    r
  end
end

Liquid::Template.register_tag('feed_aggregator_entries', Jekyll::FeedAggregatorEntries)
Liquid::Template.register_filter(FeedAggregatorFilters)
