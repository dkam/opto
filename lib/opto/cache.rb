require 'cgi'

class Cache < Checker
  Opto.register( self)

  suite                'cache'
  description         'Check server cache setup'
  supported_protocols :http, :https

  def checks
    puts "Try https://redbot.org/?uri=#{CGI.escape(@server.url.to_s)}".yellow

    check_compression
  end

  def check_compression
    no_compression = @server.response.data.size ##

    gzip_data = open(@server.url, 'Accept-Encoding' => 'gzip')
    if gzip_data.meta["content-encoding"] 
      gzs = gzip_data.size
      @result.passed("Caching: GZip supported.  #{no_compression - gzs} Bytes or #{(100 - gzs.to_f / no_compression * 100).to_i}% saved")
    else
      @result.failed("Caching: GZIP Compression not supported")
    end
    
    # TODO: test other compression schemes, deflate and sdch
    # TODO: test for compression of JS and CSS


  end
end

