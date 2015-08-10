require 'resolv'

class Dns
  Opto.register( self)

  def self.description
    "Check up on your DNS setup" 
  end

  def self.supports?(protocol)
    [:http, :https, :smtp, :smtps].include?(protocol)
  end

  def initialize(data)
    @data = data
  end

  def check
    check_reverse_mapping
  end

  def check_reverse_mapping
    ip_address = Resolv.getaddress(@data.host)

    rev_name = Resolv.getname(ip_address)

    if @data.host != rev_name
      @data.failed( "DNS: Your host doesn't have a matching reverse DNS entry")
      #puts "#{@data.host} ->  #{ip_address}"
      #puts "#{ip_address}   ->  #{rev_name}"
    else
      @data.passed( "DNS: Reverse resolution matches")
    end

  end
end
