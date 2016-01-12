class SoftwareGuess
  Opto.register( self)

  def self.description
    "Guess Software"
  end

  def self.supports?(server)
    true
  end

  def initialize(server)
    @server = server
    @result = @server.result
  end

  def check
    guess_http_server        if [:http, :https].include?(@server.protocol)
    guess_application_server if [:http, :https].include?(@server.protocol)
    guess_site               if [:http, :https].include?(@server.protocol)
    guess_os                 if [:http, :https].include?(@server.protocol)
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
      @server.info[:server_name] = 'Nginx' if server =~ /nginx/i 
      @server.info[:server_version] = Version.new(server[/\/([\d\.]*)/, 1]) if server =~ /nginx/i

      @server.info[:server_name] = 'Ruby Thin' if server =~ /\Athin\z/i 

      #"server" => "Apache/2.2.15 (CentOS)",
      @server.info[:server_name] = 'Apache' if server =~ /Apache/
      @server.info[:server_version] = Version.new(server[/\/([\d\.]*)/, 1]) if server =~ /Apache/i
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
        @server.info[:app_server_name] = 'Phusion Passenger'
        @server.info[:app_server_version] =  Version.new(powered_by[/([\d\.]+)/, 1])
      end

      # "x-powered-by" => "PHP/5.5.9-1ubuntu4.14",
      if powered_by =~ /\APHP/ 
        @server.info[:app_server_name] = 'PHP'
        @server.info[:app_server_version] =  Version.new(powered_by[/([\d\.]+)/, 1])
      end
    end

    if @server.response.headers['x-rack-cache']
      @server.info[:app_server_name] = 'Ruby Rack'
    end

    if @server.info[:app_server_name]
      @result.info("Application Server is #{[@server.info[:app_server_name], @server.info[:app_server_version]].compact.join(' / ')}")
    end
  end

  def guess_os
    if powered_by = @server.response.headers['x-powered-by']
      if powered_by =~ /ubuntu/
        @server.info[:server_os] = 'Ubuntu'
      end
    end
    if server = @server.response.headers["server"]
      if server =~ /CentOS/
        @server.info[:server_os] = 'CentOS'
      end
    end

    @result.info("Server OS is #{@server.info[:server_os]}") if @server.info[:server_os]
  end

  def guess_site
    @server.info[:site] = "Shopify" if @server.response.headers['x-shopid']
  end
end
