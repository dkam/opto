require 'test_helper'

class SoftwareGuessTest < Minitest::Test
  def test_http_server
    WebMock.disable_net_connect!

    get_fixture_names('http_server').each do |name|
      f = get_fixture('http_server', name)
      stub_request(:get, f[:request]).to_return(f[:response])
      s = Opto::Server.new(f[:request])
      SoftwareGuess.new(s).check

      f[:data].each do |k,v|
        assert_equal v, s.info[k].to_s, "Looking for #{k}"
      end
    end

    WebMock.allow_net_connect!
  end
end
