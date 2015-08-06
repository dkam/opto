require 'resolv'

class Dns
  Opto.register( self)

  def self.description
    "Check up on your DNS setup" 
  end

  def initialize(oe)
    @oe = oe
  end

  def check
    check_reverse_mapping
  end

  def check_reverse_mapping
    ip_address = Resolv.getaddress(@oe.url.host)
    rev_name = Resolv.getname(ip_address)

    if @oe.url.host != rev_name
      puts "✗  Your host doesn't have a correct reverse DNS entry".red
      puts "#{@oe.url.host} ->  #{ip_address}"
      puts "#{ip_address}   ->  #{rev_name}"
    else
      puts "✓  Reverse resolution matches".green
    end

  end
end
