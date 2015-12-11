require 'openssl'
require 'socket'
require 'uri'

class Ssl
  Opto.register( self)

  attr_reader :hsts

  def self.description
    "Checking your SSL setup" 
  end

  def self.supports?(protocol)
    [:http, :https, :smtp, :smtps].include?(protocol)
  end


  def initialize(data)
    @data = data
  end

  def check
    if @data.is_a?(OptoHttp)
      puts "Try running https://www.ssllabs.com/ssltest/analyze.html?d=#{@data.url.host}&latest"
      check_hsts            
      check_https_redirect  
    end
    check_ssl_details
    check_protocols
  end

  def check_protocols
    # https://github.com/igrigorik/http-2/blob/master/example/client.rb

    uri = @data.url
    tcp = TCPSocket.new(uri.host, uri.port)
    sock = nil
    server_protocols = nil

    ctx = OpenSSL::SSL::SSLContext.new
    ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    ctx.npn_protocols = ['h2', "spdy/3", "spdy/2", "http/1.1"]
    
    ctx.npn_select_cb = lambda do |protocols|
      #puts "NPN protocols supported by server: #{protocols}"
      #DRAFT if protocols.include? DRAFT
      server_protocols = protocols
    end

    sock = OpenSSL::SSL::SSLSocket.new(tcp, ctx)
    sock.sync_close = true
    sock.hostname = uri.hostname
    begin
      sock.connect
    rescue => e
      #puts "Error : #{e.inspect}"
    end

    @data.passed("Suports SPDY (#{server_protocols.grep(/spdy/).join(', ')})") if server_protocols.grep(/spdy/)
    #@data.passed("Suports HTTP/2 (#{server_protocols.grep(/h2/).join(', ')})") if server_protocols.grep(/h2/)
    server_protocols.select {|p| p =~ /^h2-/ }.each do |pr|
      @data.passed("Supports HTTP/2 Draft #{pr[/h2-(.*)/, 1]}")
    end                   
    
    #sock.context.npn_protocols
    #puts server_protocols
    sock.close

  end

  def check_hsts
    ## HSTS https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security
    if age = @data.headers['strict-transport-security']
      hsts_expiry = age.split('=')[1]
      @data.passed( "SSL: HSTS Expiry: #{hsts_expiry}")
    else
      @data.failed('SSL: HSTS not enabled')
    end
  end

  def check_https_redirect

    # Check redirection to HTTPS
    plain = @data.url.dup     
    plain.scheme = 'http'
    plain.port = 80
    res =  Net::HTTP.get_response(plain)
    red = URI.parse(res.header['Location']) if res.header['Location']
    if (res.code == '301' || res.code == '302') && !red.nil? && red.scheme == 'https'
      @data.passed("SSL: Redirected to HTTPS")
    else
      @data.failed("SSL: Not redirected to HTTPS" )
    end

  end

  def check_ssl_details
    tcp = TCPSocket.new(@data.url.host, 443)

    sock = OpenSSL::SSL::SSLSocket.new(tcp)
    sock.sync_close = true
    sock.hostname = @data.url.host
    sock.connect

    if sock.peer_cert.not_after < ( DateTime.now >> 1 ).to_time
      @data.failed("SSL: Certificate expires in the next month (#{sock.peer_cert.not_after}) redirected to HTTPS" )
    else
      @data.passed("SSL: More than 1 month validity (#{sock.peer_cert.not_after})")
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

