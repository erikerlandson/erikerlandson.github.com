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
      super
    end


    def extract_params(context)
      defaults = { 'title' => 'Blog Feed', 'post_limit' => 5, 'feed_list' => [] }
      # context['page'] includes any attributes set via yaml front-matter,
      # which we expect to include feed aggregator settings if we are being invoked
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


    def render(context)
      extract_params(context)

      # aggregate all feed urls into a single list of entries
      entries = []
      authors = []
      @urls.each do |url|
        feed = Feedzirra::Feed.fetch_and_parse(url)
        # take entries, up to the given post limit
        ef = feed.entries.first(@post_limit)
        # grab author from feed header if it isn't in the entry itself:
        ef.each do |e|
          e.author = feed.author unless e.author
          authors << e.author
        end
        entries += ef
      end

      # store unique author list
      authors.uniq!
      context['feed_member_list'] = authors

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
  def feed_member_aside(member_list)
    r = "<section>\n"
    r += "<h1>Members</h1>\n"
    member_list.each do |name|
      r += "#{name}<br>\n"
    end
    r += "</section>\n"
    r
  end
end

Liquid::Template.register_tag('feed_aggregator_entries', Jekyll::FeedAggregatorEntries)
Liquid::Template.register_filter(FeedAggregatorFilters)
