require 'open-uri'
require 'nokogiri'
require 'colorize'
require 'fastimage'
require 'addressable/uri'

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

class Object
  #http://ozmm.org/posts/try.html
  def try(method)
    send method if respond_to? method
  end
end

class OptoBase

  def initialize(url)
    @passed = [] 
    @warned = [] 
    @failed = []
  end

  def passed(description)
    @passed << description
  end
  def warned(description)
    @warned << description
  end
  def failed(description)
    @failed << description
  end

  def report
    @passed.each {|r|  puts "✓ #{r}".green }
    @warned.each {|r|  puts "! #{r}".yellow }
    @failed.each {|r|  puts "✗ #{r}".red }
  end

end

class OptoSmtp < OptoBase
  attr_reader :host

  def initialize(url)
    @host = url[/smtps?:\/\/([a-zA-Z0-9\.]*)\//,1]
    @checks = []
    super
  end

end

class OptoHttp < OptoBase
  attr_reader :url, :data, :headers, :doc, :host

  def initialize(url)
    @url     = Addressable::URI.heuristic_parse( url )
    @data    = open(@url)
    @headers = @data.meta
    @doc     = Nokogiri::HTML(@data)
    @host    = @url.host
    super
  end


end

#require 'favicon'
require 'cache'
require 'images'
require 'ssl'
require 'dns'

