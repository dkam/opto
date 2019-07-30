require 'openssl'
require 'socket'
require 'uri'

class Compression < Checker
  Opto.register( self)

  suite               'compression' 
  description         'Checking your Compression setup'
  supported_protocols :http, :https

  def checks
    check_text  
    check_images            
  end

  def check_text
    # Check HTML / JS / CSS is compressed
  end

  def check_images
    # Check SVG is compressed
    # Ensure PNG / JPG are not compressed
  end

  def check_text
    no_compression = @server.response.data.size

    ## Check Javascript
    @server.response.doc.xpath('//script/@src').each do |src|

      unless src.nil?
        js_url = URI.parse(src)

        js_url = normalise(js_url, @server.url)

        if js_url.host != @server.url.host
          @result.warned("Skipping URL #{js_url}")
          next
        end
        msg, uncompressed_size, compressed_size = comp_test(js_url, 'JS')
        @result.passed(msg) unless uncompressed_size.nil?
        @result.failed(msg) if     uncompressed_size.nil?
      end
    end

    ## Check CSS
    # rel='stylesheet'
    css = @server.response.doc.xpath("//link/@href").select {|e| e.value =~ /css$/ }.first&.value
    unless css.nil?
      css_url = URI.parse(css)
      css_url = normalise(css_url, @server.url)

      if css_url.host != @server.url.host
        @result.warned("Skipping URL #{js_url}")
        return
      end

      msg, uncompressed_size, compressed_size = comp_test(css_url, 'CSS')
      @result.passed(msg) unless uncompressed_size.nil?
      @result.failed(msg) if     uncompressed_size.nil?
    end

    ## Check HTML
    msg, uncompressed_size, compressed_size = comp_test(@server.url, 'HTML')

    @result.passed(msg) unless uncompressed_size.nil?
    @result.failed(msg) if     uncompressed_size.nil?
    
    ## Check SVG
    svg  = @server.response.doc.xpath("//img/@src").select {|e| e.value =~ /svg/ }.first&.value
    unless svg.nil?
      svg_url = URI.parse(svg)
      svg_url = normalise(svg_url, @server.url)
      
      if svg_url.host != @server.url.host
        @result.warned("Skipping URL #{js_url}")
        return
      end

      msg, uncompressed_size, compressed_size = comp_test(svg_url, 'SVG') 

      @result.passed(msg) unless uncompressed_size.nil?
      @result.failed(msg) if     uncompressed_size.nil?
    end
    
    # TODO: test other compression schemes, deflate and sdch
    # TODO: test for compression of JS and CSS


  end

  private 

  def normalise(url, root)
    t = root.dup
    url.path = url.path.gsub("../", '/')            # For relative resources, we'll just look at the root.  
    url.scheme = root.scheme if url.scheme.nil?     # Used for resources beginning with //

    if url.host.nil?
      t.path = url.path
      return t
    end
    return url
  end
  def comp_test(url, tag=nil)
    uncompressed       = open(url.to_s).size
    compressed_request = open(url.to_s, 'Accept-Encoding' => 'gzip')
    compressed         = compressed_request.size

    encoding = compressed_request.meta["content-encoding"]
    if encoding
      msg = "Compression: #{tag} GZip supported.  #{(uncompressed - compressed).to_human} (#{(100 - compressed.to_f / uncompressed * 100).to_i}%) saved"
      return([msg, uncompressed, compressed])
    else
      msg = "Compression: #{tag} GZip not supported"
      return([msg,nil,nil])
    end
  rescue => e
    puts e.message
    puts e.backtrace
  end
end


