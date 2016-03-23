class SoftwareGuess
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
end

