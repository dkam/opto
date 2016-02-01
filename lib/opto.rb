require 'open-uri'
require 'nokogiri'
require 'colorize'
require 'fastimage'
require 'addressable/uri'
require 'httpclient'

$:.unshift File.join( File.dirname(__FILE__), "/opto")

require 'version'

module Opto
  @@subclasses = []

  def self.registered
    @@subclasses
  end
     
  def self.register(  klass )
    @@subclasses << klass
  end

  class Server
    attr_reader :uri, :url, :host, :responses, :protocol, :result, :info

    def initialize(uri)
      @protocol  = case uri
        when /^smtp/ then :smtp
        when /^imap/ then :imap
        when /^https/ then :https
        when /^http/ then :http
        else :http
      end
      @uri       = uri
      @url       = URI.parse( uri )
      @host      = @url.host
      @responses = []

      if @protocol == :http  || @protocol == :https
        resp =  ServerResponse.new( open(@url) )
        @responses << resp
      end
      @result = Opto::Result.new(self)
      @info = {}
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
      @content_type = @headers["content-type"] 

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
      @info   = []
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
    def info(description)
      @info << description
    end

    def report
      puts
      puts "Report for #{@url}"
      @info.each   {|r|  puts "#{r}" }
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

module ClassInstanceVariableAccessor
  attr_accessor :short_name, :desc, :protocols

  def suite(_name)
    @short_name = _name
  end

  def description(_desc)
    @desc = _desc
  end
  
  def supported_protocols(*proto)
    @protocols = Array(proto).flatten
  end
    
end

class Checker
  extend ClassInstanceVariableAccessor
  
  def initialize(server)
    @server = server
    @result = @server.result
  end

  def supports?(proto)
    # Check the class instance variables
    return true if self.class.protocols == true
    return self.class.protocols.include?(proto)
  end

  def check
    return unless supports?(@server.protocol)
    checks
  end
end


require 'server_time'
require 'html'
require 'favicon'
require 'cache'
require 'images'
require 'ssl'
require 'dns'
require 'smtp'
require 'software_guess'
require 'cve'
