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

