class SoftwareGuess < Checker
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

  def guess_http_server
    if server = @server.response.headers["server"]
      ##
      # Start with the generic header value
      ##
      @server.info[:server_name] = server

      ##
      # Now see if we recognise it
      ## 
      if server =~ /nginx/i 
        @server.info[:server_name] = 'nginx' 
        server_version = server[/\/([\d\.]*)/, 1]
        @server.info[:server_version] = Version.new(server_version) if server_version
      end

      @server.info[:server_name] = 'ruby thin' if server =~ /\Athin\z/i 

      #"server" => "Apache/2.2.15 (CentOS)",
      if server =~ /Apache/i
        @server.info[:server_name] = 'apache' 
        server_version = server[/\/([\d\.]*)/, 1]
        @server.info[:server_version] = Version.new(server_version) if server_version
      end

      # "server" => "Microsoft-IIS/8.5"
      if server =~ /Microsoft-IIS/i
        @server.info[:server_name] = 'microsoft-iis' 
        server_version = server[/\/([\d\.]*)/, 1]
        @server.info[:server_version] = Version.new(server_version) if server_version
      end
    end

    if @server.info[:server_name]
      @result.info("Server is #{[@server.info[:server_name], @server.info[:server_version]].compact.join('/')}")
    end
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

  def guess_os
    if powered_by = @server.response.headers['x-powered-by']
      if powered_by =~ /ubuntu/
        @server.info[:server_os] = 'ubuntu'
        @server.info[:server_os_version] = powered_by[/ubuntu(\d*\.\d*)/,1]
      end
    end
    if server = @server.response.headers["server"]
      if server =~ /CentOS/
        @server.info[:server_os] = 'centos'
      end
    end

    @result.info("Server OS is #{@server.info[:server_os]} / #{@server.info[:server_os_version]||'(unknown version)'}") if @server.info[:server_os]
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
    @result.info("Application is #{@server.info[:application]}") if @server.info[:application]
  end 
end
