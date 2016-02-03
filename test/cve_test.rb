require 'test_helper'

class CveTest < Minitest::Test
  ## 
  #  Test the cve.json file is valid"
  ##
  def test_cve_json
    doc = JSON.parse(File.read(File.expand_path(File.join(__FILE__, '../../', 'cve.json'))))
    assert !doc.nil?
  end
end
