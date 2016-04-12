require 'openssl'
require 'socket'
require 'uri'

class Ssl < Checker
  Opto.register( self)

  attr_reader :hsts

  suite               'ssl' 
  description         'Checking your SSL setup'
  supported_protocols :https, :smtps

  def checks
    @result.info "Try running https://www.ssllabs.com/ssltest/analyze.html?d=#{@server.host}&latest"
    @result.info "Try running https://securityheaders.io/?q=https%3A%2F%2F#{@server.host}%2F"
    check_hsts            
    check_https_redirect  
    check_ssl_details
    check_protocols
  end

  ## 
  # TODO check for ALPN in addition to NPN
  ##
  def check_protocols
    # https://github.com/igrigorik/http-2/blob/master/example/client.rb

    uri = @server.url
    tcp = TCPSocket.new(uri.host, uri.port)
    sock = nil
    npn_server_protocols = alpn_server_protocols = nil

    ctx = OpenSSL::SSL::SSLContext.new
    ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    ctx.npn_protocols = ['h2', "spdy/3", "spdy/2", "http/1.1"]
    
    ctx.npn_select_cb = lambda do |protocols|
      #puts "NPN protocols supported by server: #{protocols}"
      #DRAFT if protocols.include? DRAFT
      npn_server_protocols = protocols
    end

    ctx.alpn_protocols = ['h2', "spdy/3", "spdy/2", "http/1.1"]
    ctx.alpn_select_cb = lambda do |protocols|
      alpn_server_protocols = protocols 
    end

    sock = OpenSSL::SSL::SSLSocket.new(tcp, ctx)
    sock.sync_close = true
    sock.hostname = uri.hostname
    begin
      sock.connect
    rescue => e
      #puts "Error : #{e.inspect}"
    end

    if npn_server_protocols
      @result.passed("SSL: Suports SPDY (#{npn_server_protocols.grep(/spdy/).join(', ')})") if npn_server_protocols.grep(/spdy/)
      @result.passed("SSL: Suports HTTP/2 (#{npn_server_protocols.grep(/h2/).join(', ')})") if npn_server_protocols.grep(/h2/)
      npn_server_protocols.select {|p| p =~ /^h2-/ }.each do |pr|
        @result.passed("SSL: Supports HTTP/2 Draft #{pr[/h2-(.*)/, 1]}")
      end                   
    else
      @result.warned("SSL: No support for SPDY or HTTP/2")
    end

    if alpn_server_protocols
      puts "Need to work with alpn_server_protocols: #{alpn_server_protocols}"
    end
    
    #sock.context.npn_protocols
    #puts "NPN: #{npn_server_protocols}"
    sock.close

  end

  def check_hsts
    ## HSTS https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security
    if age = @server.response.headers['strict-transport-security']
      hsts_expiry = age.split('=')[1]
      @result.passed( "SSL: HSTS Expiry: #{hsts_expiry}")
    else
      @result.failed('SSL: HSTS not enabled')
    end
  end

  def check_https_redirect

    # Check redirection to HTTPS
    plain = @server.url.dup     
    plain.scheme = 'http'
    plain.port = 80
    res =  Net::HTTP.get_response(plain)
    red = URI.parse(res.header['Location']) if res.header['Location']
    if (res.code == '301' || res.code == '302') && !red.nil? && red.scheme == 'https'
      @result.passed("SSL: Redirected to HTTPS")
    else
      @result.failed("SSL: Not redirected to HTTPS" )
    end

  end

  def check_ssl_details
    tcp = TCPSocket.new(@server.url.host, 443)

    sock = OpenSSL::SSL::SSLSocket.new(tcp)
    sock.sync_close = true
    sock.hostname = @server.url.host
    sock.connect

    if sock.peer_cert.not_after < ( DateTime.now >> 1 ).to_time
      @result.failed("SSL: Certificate expires in the next month (#{sock.peer_cert.not_after}) redirected to HTTPS" )
    else
      @result.passed("SSL: More than 1 month validity (#{sock.peer_cert.not_after})")
    end
    sock.close

    #check
    #http://security.stackexchange.com/questions/70733/how-do-i-use-openssl-s-client-to-test-for-absence-of-sslv3-support
    #openssl s_client -connect booko.com.au:443 -ssl2
    #openssl s_client -connect booko.com.au:443 -ssl3
    #openssl s_client -connect booko.com.au:443 -tls1
    #nmap --script ssl-enum-ciphers -p 443 example.com
    #
    #https://www.owasp.org/index.php/Testing_for_Weak_SSL/TLS_Ciphers,_Insufficient_Transport_Layer_Protection_(OTG-CRYPST-001)
    #nmap --script ssl-cert,ssl-enum-ciphers -p           com
    #
  end

  
end

