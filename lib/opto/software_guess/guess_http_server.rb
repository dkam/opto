class SoftwareGuess
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

end

module GuessHttpServer
  def nginx(server)
    if server_report =~ /nginx/i 
      confidence = 1
      return([confidence, 'nginx', server_report[/\/([\d\.]*)/, 1] ]) 
    end
  end
end

