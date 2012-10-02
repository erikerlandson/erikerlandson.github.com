require 'rubygems'
require 'open-uri'
require 'pp'
require 'ostruct'
require 'yaml'
require 'jekyll'
require 'date'
require 'digest/md5'
require 'net/http'
require 'net/https'
require 'uri'
require 'feedzirra'

module Jekyll
  class RSSFeedTag < Liquid::Block

    include Liquid::StandardFilters
    Syntax = /(#{Liquid::QuotedFragment}+)?/ 


    def initialize(tag_name, markup, tokens)
      @attributes = { 'title' => 'Blog Feed' }
      
      # Parse parameters
      if markup =~ Syntax
        markup.scan(Liquid::TagAttributes) do |key, value|
          #p key + ":" + value
          @attributes[key] = value
        end
      else
        raise SyntaxError.new("Syntax Error in 'rssfeed' - Valid syntax: rssfeed uid:x count:x]")
      end

      @url = @attributes['url']
      @count = @attributes['count'].to_i
      @title = @attributes['title'].gsub(/\A[']+|[']+\Z/, "")

      super
    end


    def render(context)
      context.registers[:rssfeed] ||= Hash.new(0)
    
      feed = Feedzirra::Feed.fetch_and_parse(@url)
      collection = feed.entries.first(@count)

      length = collection.length
      result = []

      rr = "<article>\n<header>\n <h1 align=\"center\", class=\"entry-title\"><u>%s</u></h1> </header>\n <div class=\"entry-content\">\n%s</div>\n</article>\n" % [@title,"\n"]
      result << rr

      # loop through found items and render results
      context.stack do
        collection.each_with_index do |item, index|
          attrs = item.instance_variables.inject({}) { |hash,var| hash[var[1..-1].to_sym] = item.instance_variable_get(var); hash }
          rr = "<article>\n<header>\n <h1 class=\"entry-title\"> <a href=\"%s\">%s</a>\n</h1>\n  </header>\n <div class=\"entry-content\">\n%s</div>\n</article>\n" % [attrs[:links].first, attrs[:title], attrs[:content]]
          #print "\n rr=\n%s\n" % [rr]
          result << rr
        end
      end

      result
    end

  end
end

Liquid::Template.register_tag('rssfeed', Jekyll::RSSFeedTag)
