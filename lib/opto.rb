require 'open-uri'
require 'nokogiri'
require 'colorize'

$:.unshift File.join( File.dirname(__FILE__), "/opto")

module Opto
  @@subclasses = []

  def self.registered
    @@subclasses
  end
     
  def self.register(  klass )
    @@subclasses << klass
  end
end

class OptoExchange
  attr_reader :url, :data, :headers, :doc
  def initialize(url)
    @url     = URI.parse( url )
    @data    = open(url)
    @headers = @data.meta
    @doc     = Nokogiri::HTML(@data)
  end
end

#require 'favicon'
require 'cache'
require 'images'
require 'ssl'
require 'dns'

