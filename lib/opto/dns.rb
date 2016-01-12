require 'resolv'

class Dns
  Opto.register( self)

  def self.description
    "Check up on your DNS setup" 
  end

  def self.supports?(server)
    [:http, :https, :smtp, :smtps].include?(server.protocol)
  end

  def initialize(server)
    @server = server
    @result = @server.result
  end

  def check
    check_reverse_mapping
  end

  def check_reverse_mapping
    Resolv::DNS.open do |dns|
      res = dns.getresources @server.host, Resolv::DNS::Resource::IN::ANY

      # Does the host resolve to an CNAME?
      if !res.select {|r| r.is_a? Resolv::DNS::Resource::IN::CNAME}.empty?
        cname = res.first.name.to_s
      end

      ip_address = Resolv.getaddress(@server.host)

      begin 
        rev_name = Resolv.getname(ip_address)
      rescue Resolv::ResolvError => e
        @result.warned("No reverse resolution for IP #{ip_address}")
      end

      if @server.host != rev_name && rev_name != cname
        @result.failed( "DNS: Your host doesn't have a matching reverse DNS entry (#{@server.host} != #{rev_name}")
      elsif @server.host != rev_name && rev_name == cname
        @result.passed( "DNS: Given host is a CName for which reverse resolution matches")
      else
        @result.passed( "DNS: Reverse resolution matches")
      end
    end
  end
end
