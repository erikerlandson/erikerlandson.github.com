require 'rubygems'
require 'open-uri'
require 'pp'
require 'ostruct'
require 'yaml'
require 'jekyll'
require 'date'
require 'digest/md5'
#require 'action_view'
require 'net/http'
require 'net/https'
require 'uri'
#require 'feedparser'
require 'feedzirra'

#include ActionView::Helpers::DateHelper

# From http://api.rubyonrails.org/classes/ActiveSupport/CoreExtensions/Hash/Keys.html
class Hash
  def stringify_keys!
    keys.each do |key|
      self[key.to_s] = delete(key)
    end
    self
  end
end


module Jekyll
  class RSSFeedTag < Liquid::Block

    include Liquid::StandardFilters
    Syntax = /(#{Liquid::QuotedFragment}+)?/ 

    def initialize(tag_name, markup, tokens)
      @variable_name = 'item'
      @attributes = {}
      
      # Parse parameters
      if markup =~ Syntax
        markup.scan(Liquid::TagAttributes) do |key, value|
          #p key + ":" + value
          @attributes[key] = value
        end
      else
        raise SyntaxError.new("Syntax Error in 'rssfeed' - Valid syntax: rssfeed uid:x count:x]")
      end

      @ttl = @attributes.has_key?('ttl') ? @attributes['ttl'].to_i : nil
      @url = @attributes['url']
      @count = @attributes['count']
      @name = 'item'

      super
    end

    def render(context)
      context.registers[:rssfeed] ||= Hash.new(0)
    
      #collection = RSSFeed.tag(@url, @count)
      feed = Feedzirra::Feed.fetch_and_parse(@url)
      collection = feed.entries

      length = collection.length
      result = []
              
      # loop through found items and render results
      context.stack do
        collection.each_with_index do |item, index|
          attrs = item.instance_variables.inject({}) { |hash,var| hash[var[1..-1].to_sym] = item.instance_variable_get(var); hash }
          attrs[:link] = attrs[:links].first
          attrs[:description] = attrs[:content]
          p attrs
          #p attrs
          #p item
          #next
          #attrs = item.send('table')
          context[@variable_name] = attrs.stringify_keys! if attrs.size > 0
          context['forloop'] = {
            'name' => @name,
            'length' => length,
            'index' => index + 1,
            'index0' => index,
            'rindex' => length - index,
            'rindex0' => length - index -1,
            'first' => (index == 0),
            'last' => (index == length - 1) }

          result << render_all(@nodelist, context)
        end
      end
      result
    end
  end
end

Liquid::Template.register_tag('rssfeed', Jekyll::RSSFeedTag)

