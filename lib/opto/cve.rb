class Cve
  Opto.register( self)

  def self.description
    "Check for CVE"
  end

  def self.supports?(server)
    true
  end

  def initialize(server)
    @server = server
    @result = @server.result
  end

  def check
    return if  @server.info[:server_version].nil? && @server.info[:app_server_version].nil? 


    if @server.info[:server_name] == 'Nginx' 
      nginx_link = 'http://nginx.org/en/security_advisories.html'
      live_version = @server.info[:server_version] 

      if live_version > Version.new('0.5.6') && live_version < Version.new('1.7.5') 
        @result.failed("CVE-2014-3616: SSL session reuse vulnerability (Severity: medium) may be relevant. #{nginx_link}")
      end

      if live_version >= Version.new('1.5.6') && live_version <= Version.new('1.7.3') 
        @result.failed("CVE-2014-3556: STARTTLS command injection (Severity: medium) may be relevant. #{nginx_link}")
      end

      if live_version >= Version.new('1.3.15') && live_version <= Version.new('1.5.11') 
        @result.failed("CVE-2014-0133: SPDY heap buffer overflow (Severity: major) may be relevant.  #{nginx_link}")
      end

      if live_version == Version.new('1.5.10')
        @result.failed("CVE-2014-0088: SPDY memory corruption (Severity: major) may be relevant.  #{nginx_link}")
      end
    end
  end
end
