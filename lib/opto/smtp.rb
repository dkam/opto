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
    ctime = Benchmark.realtime do 
      Net::SMTP.start('mailma.nmilne.com', 587) do |conn|

        if conn.capable_starttls?
          @data.passed( 'SMTP: TLS Supported') 
        else
          @data.failed( 'SMTP: TLS Not Supported' )
        end

        resp = conn.ehlo('localhost')

        banner_host = resp.message.gsub(/\d\d\d-/,'').strip

        @data.passed('SMTP: Banner matches host') if     banner_host == @data.host
        @data.passed('SMTP: Banner matches host') unless banner_host == @data.host

      end
    end
    @data.passed( "SMTP: Connection time: #{ctime} ") 

  end

  def check_relay_access

    msgstr = <<-END_OF_MESSAGE
    From: Your Name <test@mail.address>
    To: Destination Address <someone@example.com>
    Subject: test message
    Date: Sat, 23 Jun 2001 16:26:43 +0900
    Message-Id: <unique.message.id.string@example.com>

    This is a test message.
END_OF_MESSAGE


    begin
      ttime = Benchmark.realtime do
        Net::SMTP.start('mailma.nmilne.com', 587) do |conn|
          conn.send_message msgstr, 'your@mail.address', 'their@mail.address'
        end
      end
    rescue Net::SMTPFatalError => e
      @data.passed("SMTP: Relay Access Denied" )
    else
      @data.failed("SMTP: Relay Access Allowed" )
    end
    @data.passed("SMTP: Transaction time #{ttime}")
  end

  def check_spf
    #https://github.com/trailofbits/spf-query
  end
end

