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
    check_size
  end


  ##
  # If the page has a canonical URL, check it's the same as the page we were given
  ##
  def check_canonical
    canonical_element = @data.doc.at_xpath("//link[@rel = 'canonical']/@href")

    return if canonical_element.nil?

    canonical_url = canonical_element.value

    if  canonical_url.nil?
      @data.warned("HTML: No Canonical URL") 
    elsif URI.parse(canonical_url) == URI.parse(@data.raw_url)
    #elsif  @data.raw_url ==  canonical_url
      #if canonical_url != @data.raw_url
      #if URI.parse(canonical_url) != URI.parse(@data.raw_url)
      @data.passed("HTML: Canonical URL matches URL") 
    else
      @data.failed("HTML: Canonical URL (#{canonical_url}) doesn't match given URL (#{@data.raw_url})") 
    end
  end

  ## 
  # Search Search Box
  #
  # http://schema.org/SearchAction
  # https://developers.google.com/structured-data/slsb-overview
  ##
  def check_ssb

    ssb = @data.doc.xpath("//script[@type='application/ld+json']")

    return if ssb.length == 0

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

  ##
  # Check page size
  # Note: Currently does not take compression into account
  ##
  def check_size
    c = HTTPClient.new
    ##
    # The downloaded page size
    ##
    #comp_get = c.head(@data.url)
    #byebug
    #compressed_page = comp_get.headers["Content-Length"].to_i if comp_get.status == 200
    @data.passed("HTML: Page size #{@data.data.length.to_human} ") # (#{compressed_page.to_human} compressed)")

    ##
    # Use this base
    ##
    base = URI.parse("#{@data.url.scheme}://#{@data.url.host}")

    ## 
    #  Sum the Javascript scripts
    #  Note: Need to take into account Google Analytics building a script tag that
    #        this static analysis doesn't consider
    ##
    js_length = @data.doc.xpath('//script/@src').inject(0) do |sum, src|  
      res = base.merge(URI.parse(src))
      sum + c.head(res.to_s).headers["Content-Length"].to_i
    end

    ## This will produce incorrect results if the server doesn't support gz
    cjs_length = @data.doc.xpath('//script/@src').inject(0) do |sum, src|  
      res = base.merge(URI.parse(src))
      sum + c.head(res.to_s + ".gz").headers["Content-Length"].to_i
    end
    @data.passed("HTML: Javascript size #{js_length.to_human} (Compressed: #{cjs_length.to_human})")

    ##
    # Sum the CSS
    ##
    cs_length = @data.doc.xpath('//link/@href').select{|s| s.value[/css$/]}.inject(0) do |sum, src|  
      res = base.merge(URI.parse(src))
      sum + c.head(res.to_s).headers["Content-Length"].to_i
    end
    ccs_length = @data.doc.xpath('//link/@href').select{|s| s.value[/css$/]}.inject(0) do |sum, src|  
      res = base.merge(URI.parse(src))
      sum + c.head(res.to_s + ".gz").headers["Content-Length"].to_i
    end
    @data.passed("HTML: Style size #{cs_length.to_human}")
  end
end
