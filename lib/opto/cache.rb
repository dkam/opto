require 'cgi'

class Cache
  Opto.register( self)

  def self.description
    "Check up on your cache setup" 
  end

  def initialize(oe)
    @oe = oe
  end

  def check
    puts "Try https://redbot.org/?uri=#{CGI.escape(@oe.url.to_s)}".yellow

    no_compression = @oe.data.size

    gzip_data = open(@oe.url, 'Accept-Encoding' => 'gzip')
    if gzip_data.meta["content-encoding"] 
      gzs = gzip_data.size
      puts "#{no_compression} / #{gzs}"
      puts "✓ GZip supported.  #{no_compression - gzs} Bytes or #{(100 - gzs.to_f / no_compression * 100).to_i}% saved".green
    else
      puts "✗ GZIP Compression not supported".red
    end

    #Accept-Encoding: gzip, deflate
    #Accept-Encoding: gzip
    #Accept-Encoding: sdch
  end
end

