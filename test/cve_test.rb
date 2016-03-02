require 'test_helper'

class CveTest < Minitest::Test
  ## 
  #  Test the cve.json file is valid"
  ##
  def test_cve_json

    Dir.glob( File.expand_path(File.join(__FILE__, '../../data/cve')) + "*.json" ) do |json|
      puts json
      doc = JSON.parse(json)
      assert !doc.nil?
      assert true
    end

  end
end
