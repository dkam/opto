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
    ip_address = Resolv.getaddress(@server.host)

    begin 
      rev_name = Resolv.getname(ip_address)
    rescue Resolv::ResolvError => e
      @result.warned("No reverse resolution for IP #{ip_address}")
    end

    if @server.host != rev_name
      @result.failed( "DNS: Your host doesn't have a matching reverse DNS entry")
      #puts "#{@server.host} ->  #{ip_address}"
      #puts "#{ip_address}   ->  #{rev_name}"
    else
      @result.passed( "DNS: Reverse resolution matches")
    end

  end
end
