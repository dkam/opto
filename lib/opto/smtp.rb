require 'net/smtp'
require 'benchmark'

class Smtp < Checker
  Opto.register( self)


  def initialize(server)
    self.supported_protocols = :smtp, :smtps
    @description = 'Check various SMTP settings'
    @short_name  = 'smtp'
    @server      = server
    @result      = @server.result
  end

  def checks
    ctime = Benchmark.realtime do 
      Net::SMTP.start(@server.host, 587) do |conn|

        if conn.capable_starttls?
          @result.passed( 'SMTP: TLS Supported') 
        else
          @result.failed( 'SMTP: TLS Not Supported' )
        end

        resp = conn.ehlo('localhost')

        banner_host = resp.message.gsub(/\d\d\d-/,'').strip

        @result.passed('SMTP: Banner matches host') if     banner_host == @server.host
        @result.passed('SMTP: Banner matches host') unless banner_host == @server.host

      end
    end
    @result.passed( "SMTP: Connection time: #{ctime} ") 

  rescue Errno::ECONNREFUSED => e
    @result.failed('SMTP: Connection refused')
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
      @result.passed("SMTP: Relay Access Denied" )
    else
      @result.failed("SMTP: Relay Access Allowed" )
    end
    @result.passed("SMTP: Transaction time #{ttime}")
  end

  def check_spf
    #https://github.com/trailofbits/spf-query
  end
end

