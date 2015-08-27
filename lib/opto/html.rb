require 'json'

class Html
  Opto.register( self)

  attr_reader :body 

  def self.description
    "Check up on your HTML" 
  end

  def self.supports?(protocol)
    [:http, :https].include?(protocol)
  end

  def initialize(data)
    @data = data
  end

  def check
    check_canonical
    check_ssb
  end


  def check_canonical
    canonical_url = @data.doc.at_xpath("//link[@rel = 'canonical']/@href").value
    
    @data.passed("HTML: Canonical URL matches URL") if  @data.raw_url ==  canonical_url
    @data.warned("HTML: No Canonical URL") if  canonical_url.nil?
    @data.failed("HTML: Canonical URL (#{canonical_url}) doesn't match given URL (#{@data.url.to_s})") if canonical_url != @data.raw_url
  end

  def check_ssb
    ## 
    # Search Search Box
    #
    # http://schema.org/SearchAction
    # https://developers.google.com/structured-data/slsb-overview
    ##

    ssb = @data.doc.xpath("//script[@type='application/ld+json']")

    @data.warned("HTML: Multiple 'applicaiton/ld+json' sections") if ssb.length > 1
    begin
      ssb_json = JSON.parse( ssb.first.text )
    rescue JSON::ParserError => e
      @data.failed("HTML: JSON Parse error for 'applicaiton/ld+json' sections")
      return
    end

    # Check all the appropriate keys are present
    begin 
      raise("'@context' should be 'http://schema.org'") unless ssb_json["@context"] == "http://schema.org"
      raise("'@type' should be 'WebSite'")              unless ssb_json["@type"] == "WebSite"
      raise("'url' is missing")                         if ssb_json["url"].nil?
      raise("'potentialAction' should be a hash")       unless ssb_json["potentialAction"].is_a?(Hash)

      raise("'potentialAction,@type' should be 'SearchAction'") unless ssb_json["potentialAction"]["@type"] == "SearchAction"
      raise("'potentialAction,target' should be set")     if ssb_json["potentialAction"]["target"].nil?
      raise("'potentialAction,query-input' should contain 'required name='") unless ssb_json["potentialAction"]["query-input"] =~ /required name=/

    rescue Exception => e 
      @data.failed("HTML: SSB parameters missing: #{e.message}")
    else
      @data.passed("HTML: SSB parameters all present")
    end

    ## Check that the query parameters match
    query_param   = ssb_json["potentialAction"]["query-input"].split('=')[1]
    target_param  = ssb_json["potentialAction"]["target"][/{(.*)}/,1]

    @data.passed("HTML: SSB params match") if query_param == target_param
    @data.failed("HTML: SSB params do not match") unless  query_param == target_param


  end
end
