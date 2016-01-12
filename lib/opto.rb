require 'open-uri'
require 'nokogiri'
require 'colorize'
require 'fastimage'
require 'addressable/uri'
require 'httpclient'

$:.unshift File.join( File.dirname(__FILE__), "/opto")

module Opto
  @@subclasses = []

  def self.registered
    @@subclasses
  end
     
  def self.register(  klass )
    @@subclasses << klass
  end

  class Server
    attr_reader :uri, :url, :host, :responses, :protocol, :result

    def initialize(uri)
      @responses = []
      @protocol = case uri
        when /^smtp/ then :smtp
        when /^imap/ then :imap
        when /^http/ then :http
        else :http
      end
      @uri = uri
      #@url = Addressable::URI.heuristic_parse( uri )
      @url = URI.parse( uri )
      @host    = @url.host
      #if @url.port.nil? 
      #  @url.port = 80
      #  @url.port = 443 if @url.scheme == 'https'
      #end

      if @protocol == :http
        resp =  ServerResponse.new( open(@url) )
        @responses << resp
      end
      @result = Opto::Result.new(self)
    end

    def response
      @responses.first
    end
  end

  class ServerResponse
    attr_reader :headers, :data, :doc, :content_type
    def initialize(data)
      @data = data
      @headers = @data.meta 
      @content_type = @headers["Content-Type"] 

      if @content_type =~ /text\/html/
        @doc = Nokogiri::HTML(@data)
        @content_type = :html
      elsif @content_type =~ /application\/json/
        @doc = JSON.parse(@data)
        @content_type = :json
      elsif @content_type =~ /^image/
        puts "Image" 
      end
    end
  end

  class Result
    def initialize(server)
      @server = server
      @url = server.url
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
      puts
      puts "Report for #{@url}"
      @passed.each {|r|  puts "✓ #{r}".green }
      @warned.each {|r|  puts "! #{r}".yellow }
      @failed.each {|r|  puts "✗ #{r}".red }
    end
  end
end

class Object
  #http://ozmm.org/posts/try.html
  # Deprecate this with &. ?
  def try(method)
    send method if respond_to? method
  end
end


class Numeric
  def to_human
    units = %w{B KB MB GB TB}
    return 0 if self == 0
    e = (Math.log(self)/Math.log(1024)).floor
    s = "%.3f" % (to_f / 1024**e)
    s.sub(/\.?0*$/, units[e])
  end
end


#class OptoSmtp < OptoBase
#  attr_reader :host
#
#  def initialize(url)
#    @host = url[/smtps?:\/\/([a-zA-Z0-9\.]*)\//,1]
#    @checks = []
#    super
#  end
#
#end

#require 'favicon'
require 'server_time'
require 'cache'
require 'images'
require 'ssl'
require 'dns'
require 'smtp'
require 'html'
