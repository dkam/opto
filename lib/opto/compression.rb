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
    no_compression = @server.response.data.size ##

    ## Check Javascript
    js  = @server.response.doc.xpath("//script/@src").first&.value
    js_url  = @server.url.dup
    js_url.path = js

    msg, uncompressed_size, compressed_size = comp_test(js_url, 'JS')
    @result.passed(msg) unless uncompressed_size.nil?
    @result.failed(msg) if     uncompressed_size.nil?

    ## Check CSS
    css = @server.response.doc.xpath("//link/@href").select {|e| e.value =~ /css$/ }.first&.value
    css_url = @server.url.dup
    css_url.path = css

    msg, uncompressed_size, compressed_size = comp_test(css_url, 'CSS')
    @result.passed(msg) unless uncompressed_size.nil?
    @result.failed(msg) if     uncompressed_size.nil?

    ## Check HTML
    msg, uncompressed_size, compressed_size = comp_test(@server.url, 'HTML')

    @result.passed(msg) unless uncompressed_size.nil?
    @result.failed(msg) if     uncompressed_size.nil?
    
    ## Check SVG
    svg  = @server.response.doc.xpath("//img/@src").select {|e| e.value =~ /svg/ }.first&.value
    svg_url = @server.url.dup
    svg_url.path = svg
    msg, uncompressed_size, compressed_size = comp_test(svg_url, 'SVG')

    @result.passed(msg) unless uncompressed_size.nil?
    @result.failed(msg) if     uncompressed_size.nil?
    
    # TODO: test other compression schemes, deflate and sdch
    # TODO: test for compression of JS and CSS


  end

  private 
  def comp_test(url, tag=nil)
    uncompressed    = open(url).size
    compressed_request = open(url, 'Accept-Encoding' => 'gzip')
    compressed      = compressed_request.size

    encoding = compressed_request.meta["content-encoding"]
    if encoding
      msg = "Compression: #{tag} GZip supported.  #{(uncompressed - compressed).to_human} (#{(100 - compressed.to_f / uncompressed * 100).to_i}%) saved"
      return([msg, uncompressed, compressed])
    else
      msg = "Compression: #{tag} GZip not supported"
      return([msg,nil,nil])
    end
  rescue => e
    byebug
    puts e.message
    puts e.backtrace
  end
end


