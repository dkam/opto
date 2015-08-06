require 'open-uri'
require 'nokogiri'

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


require 'favicon'
require 'images'
require 'cache'
require 'ssl'

url = URI.parse( ARGV[0] )
doc = Nokogiri::HTML(open(url))

Opto.registered.each do |op|
  puts op.description

  suite = op.new(url, doc)
  
  suite.check

end
