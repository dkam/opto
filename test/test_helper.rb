require 'bundler'
Bundler.require(:default, :development, :test)
require 'test/unit'
require 'minitest/reporters'

Minitest::Reporters.use!


require 'webmock/test_unit'
# By default, let requests out.
WebMock.allow_net_connect!

ENV['RACK_ENV'] = 'test'

## 
# Webserver based testing flogged from : 
# https://github.com/ruby/ruby/blob/trunk/test/open-uri/test_open-uri.rb
#
# Webrick doco: 
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick.html
##
NullLog = Object.new
def NullLog.<<(arg)
end

def with_http
  WebMock.allow_net_connect!
  Dir.mktmpdir {|dr|
    srv = WEBrick::HTTPServer.new({
      :DocumentRoot => dr,
      :ServerType => Thread,
      :Logger => WEBrick::Log.new(NullLog),
      :AccessLog => [[NullLog, ""]],
      :BindAddress => '127.0.0.1',
      :Port => 0})
    _, port, _, host = srv.listeners[0].addr
    begin
      srv.start
      yield srv, dr, "http://#{host}:#{port}"
    ensure
      srv.shutdown
      until srv.status == :Stop
        sleep 0.1
      end
    end
  }
end

