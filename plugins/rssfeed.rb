require 'jekyll'
require 'feedzirra'


# octopress atom entries don't include author, but I can get it from the feed header,
# so add another sax parsing rule:
class Feedzirra::Parser::Atom
  element :name, :as => :author
end


module Jekyll
  class RSSFeedTag < Liquid::Block

    include Liquid::StandardFilters
    Syntax = /(#{Liquid::QuotedFragment}+)?/ 

    def initialize(tag_name, markup, tokens)
      @attributes = { 'title' => 'Blog Feed', 'post_limit' => 5 }

      # Parse parameters
      if markup =~ Syntax
        markup.scan(Liquid::TagAttributes) do |key, value|
          @attributes[key] = value
        end
      else
        raise SyntaxError.new("Syntax Error in 'rssfeed' - Valid syntax: rssfeed url:<url>")
      end

      # title to use for the blog feed
      @title = @attributes['title']
      # quoted strings from tag argument list have this weird quirk that the quotes are left in
      @title.gsub!(/\A['"]+|['"]+\Z/, "")

      # max number of posts to take from each feed url
      @post_limit = @attributes['post_limit'].to_i

      # get the list of feed urls
      @urls = []
      @urls << @attributes['url'] if @attributes.has_key?('url')
      @urls += load_url_file(@attributes['url_file']) if @attributes.has_key?('url_file')
      # helpfully remove any duplicate urls
      @urls.uniq!

      super
    end


    def render(context)
      # aggregate all feed urls into a single list of entries
      entries = []
      @urls.each do |url|
        feed = Feedzirra::Feed.fetch_and_parse(url)
        # take entries, up to the given post limit
        ef = feed.entries.first(@post_limit)
        # grab author from feed header if it isn't in the entry itself:
        ef.each do |e|
          e.author = feed.author unless e.author
        end
        entries += ef
      end

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
        ts = "<time datetime=\"%s\" pubdate data-updated=\"true\">%s %s<span>%s</span>, %s &nbsp; &mdash; &nbsp;  %s</time>" % [pt.strftime("%FT%T%:z"), pt.strftime("%b"), pt.strftime("%-d"), _th(pt.day), pt.strftime("%Y"), e.author]
        rr = "<article>\n<header>\n <h1 class=\"entry-title\"> <a href=\"%s\">%s</a>\n</h1>\n  <p class=\"meta\">\n%s\n</p>\n</header>\n <div class=\"entry-content\">\n%s</div>\n</article>\n" % [e.url, e.title, ts, e.content]
        result << rr
      end

      result
    end


    # read in a url list from a file
    def load_url_file(fname)
      # A predefined 'repo root dir' variable would be a better answer
      # however, this appears to work OK, as you have to invoke jekyll from 
      # the top repo dir anyway:
      fqn = Dir.pwd + "/source/" + fname
      urls = []
      File.open(fqn).each do |url|
        # get rid of any trailing nl or cr
        url.gsub!(/[\n\r]+\Z/, "")
        urls << url
      end
      urls
    end


    def _th(day)
      return "th" if [11,12,13].include?(day)
      d = day % 10
      return "st" if d == 1
      return "nd" if d == 2
      return "rd" if d == 3
      return "th"
    end

  end
end


Liquid::Template.register_tag('rssfeed', Jekyll::RSSFeedTag)
