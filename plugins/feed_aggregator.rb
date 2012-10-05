require 'jekyll'
require 'feedzirra'
require './plugins/date'

# octopress atom entries don't include author, but I can get it from the feed header,
# so add another sax parsing rule:
class Feedzirra::Parser::Atom
  element :name, :as => :author
end


class FeedAggregator < Liquid::Tag

  include Liquid::StandardFilters
  Syntax = /(#{Liquid::QuotedFragment}+)?/ 

  include Octopress::Date

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

    # make sure author entries are unique with respect to name and url
    authors.uniq! { |e| [e['last'], e['first'], e['url']] }

    # sort authors by lastname, firstname
    authors.sort! { |a,b| [a['last'],a['first']] <=> [b['last'],b['first']] }

    # eliminate any duplicate blog entries, by post id
    # (appears to be using entry url for id, which seems reasonable)
    entries.uniq! { |e| e.entry_id }

    # sort by pub date, most-recent first
    entries.sort! { |a,b| b.published <=> a.published }

    posts = []
    entries.each do |e|
      posts << {
        'url' => e.url,
        'title' => e.title,
        'author' => e.author,
        'content' => e.content,
        'date' => e.published,
        'date_formatted' => format_date(e.published, context['site']['date_format']),
        'comments' => 'false'
      }
    end

    # load our feed aggregator structure back into the context so jekyll/liquid can consume it
    context['feed_aggregator'] = { 
      'title' => @title,
      'authors' => authors,
      'posts' => posts
    }    

    # This tag is for creating the side effect of entering 'feed_aggregator'
    # into the liquid context, so it's render 'result' can be empty
    " "
  end
end


Liquid::Template.register_tag('feed_aggregator', FeedAggregator)
