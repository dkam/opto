class SoftwareGuess < Checker
  require 'software_guess/guess_http_server'
  require 'software_guess/guess_os'

  Opto.register( self)
  attr_accessor :server, :response, :result

  suite               'guess'
  description         'Guess Software'
  supported_protocols true

  def initialize(server)
    super
    @response    = server.response
  end

  def checks
    guess_http_server        if [:http, :https].include?(@server.protocol)
    guess_application_server if [:http, :https].include?(@server.protocol)
    guess_site               if [:http, :https].include?(@server.protocol)
    guess_os                 if [:http, :https].include?(@server.protocol)
    guess_application        if [:http, :https].include?(@server.protocol)
  end


  def guess_application_server
    if powered_by = @server.response.headers['x-powered-by']
      ##
      # Start with the genertic header value
      ##
      #
      @server.info[:app_server_name] = powered_by

      if powered_by =~ /Phusion Passenger/ 
        @server.info[:app_server_name] = 'phusion passenger'
        @server.info[:app_server_version] =  Version.new(powered_by[/([\d\.]+)/, 1])
      end

      # "x-powered-by" => "PHP/5.5.9-1ubuntu4.14",
      if powered_by =~ /\APHP/ 
        @server.info[:app_server_name] = 'php'
        @server.info[:app_server_version] =  Version.new(powered_by[/([\d\.]+)/, 1])
      end
    end

    if @server.response.headers['x-rack-cache']
      @server.info[:app_server_name] = 'ruby rack'
    end

    #"x-generator" => "Drupal 7 (http://drupal.org)",
    if generator = @server.response.headers["x-generator"] 
      if generator =~ /Drupal/
        @server.info[:app_server_name] = 'drupal'
        @server.info[:app_server_version] =  Version.new(generator[/([\d\.]+)/, 1])
      end
    end

    if @server.info[:app_server_name]
      @result.info("Application Server is #{[@server.info[:app_server_name], @server.info[:app_server_version]].compact.join(' / ')}")
    end
  end

  def guess_site
    @server.info[:site] = "shopify" if @server.response.headers['x-shopid']
    @server.info[:site] = "github" if @server.response.headers['server'] == "GitHub.com"
  end

  def guess_application
    if element = @server.response.doc.at_xpath("//div[@class='site-info']")
      if element.text.strip =~ /Proudly powered by WordPress/
        @server.info[:application] = 'wordpress'
      end
    end

    if generator =  @server.response.doc.at_xpath("//meta[@name='generator']/@content")&.value
      if generator =~ /wordpress/i
        @server.info[:application] = 'wordpress'
        @server.info[:application_version] = Version.new( Version.guess(generator) )
      end
    end

    @result.info("Application is #{@server.info[:application]} / #{@server.info[:application_version]||'unknown version'}") if @server.info[:application]
  end 
end
