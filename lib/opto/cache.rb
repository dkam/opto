require 'cgi'

class Cache
  Opto.register( self)

  def self.description
    "Check up on your cache setup" 
  end

  def self.supports?(protocol)
    [:http, :https].include?(protocol)
  end

  def initialize(data)
    @data = data
  end

  def check
    puts "Try https://redbot.org/?uri=#{CGI.escape(@data.url.to_s)}".yellow

    check_compression
  end

  def check_compression
    no_compression = @data.data.size

    gzip_data = open(@data.url, 'Accept-Encoding' => 'gzip')
    if gzip_data.meta["content-encoding"] 
      gzs = gzip_data.size
      puts "#{no_compression} / #{gzs}"
      @data.passed("Caching: GZip supported.  #{no_compression - gzs} Bytes or #{(100 - gzs.to_f / no_compression * 100).to_i}% saved")
    else
      @data.failed("Caching: GZIP Compression not supported")
    end
    
    # TODO: test other compression schemes, deflate and sdch
    # TODO: test for compression of JS and CSS


  end
end

