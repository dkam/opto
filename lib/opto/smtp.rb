require 'net/smtp'
require 'benchmark'

class Smtp
  Opto.register( self)

  def self.description
    "Check various SMTP settings"
  end

  def self.supports?(protocol)
    [:smtp, :smtps].include?(protocol)
  end

  def initialize(data)
    @data = data
  end

  def check
    ttime = Benchmark.realtime do 
      Net::SMTP.start('mailma.nmilne.com', 587) do |conn|

        if conn.capable_starttls?
          @data.passed( 'SMTP: TLS Supported') 
        else
          @data.failed( 'SMTP: TLS Not Supported' )
        end
      end
    end
    @data.passed( "SMTP: EHLO Transaction time: #{ttime} ") 

  end

  def check_relay_access

    msgstr = <<END_OF_MESSAGE
    From: Your Name <test@mail.address>
    To: Destination Address <someone@example.com>
    Subject: test message
    Date: Sat, 23 Jun 2001 16:26:43 +0900
    Message-Id: <unique.message.id.string@example.com>

    This is a test message.
END_OF_MESSAGE


    begin
        z.send_message msgstr, 'your@mail.address', 'their@mail.address'
    rescue Net::SMTPFatalError => e
        puts "Relay Access Denied"
    else
        puts "Relay Access Allowed"
    end
  end
end

