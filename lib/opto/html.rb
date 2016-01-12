require 'json'

class Html
  Opto.register( self)

  attr_reader :body 

  def self.description
    "Check up on your HTML" 
  end

  def self.supports?(server)
    [:http, :https].include?(server.protocol)
  end

  def initialize(server)
    @server = server
    @result = @server.result
  end

  def check
    return unless @server.response.content_type == :html
    check_canonical
    check_ssb
    check_size
  end


  ##
  # If the page has a canonical URL, check it's the same as the page we were given
  ##
  def check_canonical
    canonical_element = @server.response.doc.at_xpath("//link[@rel = 'canonical']/@href")

    return if canonical_element.nil?

    canonical_url = canonical_element.value

    if  canonical_url.nil?
      @result.warned("HTML: No Canonical URL") 
    elsif URI.parse(canonical_url) == URI.parse(@server.uri)
    #elsif  @server.uri ==  canonical_url
      #if canonical_url != @server.uri
      #if URI.parse(canonical_url) != URI.parse(@server.uri)
      @result.passed("HTML: Canonical URL matches URL") 
    else
      @result.failed("HTML: Canonical URL (#{canonical_url}) doesn't match given URL (#{@server.uri})") 
    end
  end

  ## 
  # Search Search Box
  #
  # http://schema.org/SearchAction
  # https://developers.google.com/structured-data/slsb-overview
  ##
  def check_ssb

    ssb = @server.response.doc.xpath("//script[@type='application/ld+json']")

    return if ssb.length == 0

    @result.warned("HTML: Multiple 'applicaiton/ld+json' sections") if ssb.length > 1
    begin
      ssb_json = JSON.parse( ssb.first.text )
    rescue JSON::ParserError => e
      @result.failed("HTML: JSON Parse error for 'applicaiton/ld+json' sections")
      return
    end

    # Check all the appropriate keys are present
    begin 
      raise("'@context' should be 'http://schema.org'") unless ssb_json["@context"] == "http://schema.org"
      raise("'@type' should be 'WebSite', not #{ssb_json['@type']}")              unless ssb_json["@type"] == "WebSite"
      raise("'url' is missing")                         if ssb_json["url"].nil?
      raise("'potentialAction' should be a hash")       unless ssb_json["potentialAction"].is_a?(Hash)

      raise("'potentialAction,@type' should be 'SearchAction'") unless ssb_json["potentialAction"]["@type"] == "SearchAction"
      raise("'potentialAction,target' should be set")     if ssb_json["potentialAction"]["target"].nil?
      raise("'potentialAction,query-input' should contain 'required name='") unless ssb_json["potentialAction"]["query-input"] =~ /required name=/

    rescue Exception => e 
      @result.failed("HTML: SSB parameters missing: #{e.message}")
    else
      @result.passed("HTML: SSB parameters all present")
    end

    ## Check that the query parameters match
    if ssb_json["potentialAction"]
      query_param   = ssb_json["potentialAction"]["query-input"].split('=')[1]
      target_param  = ssb_json["potentialAction"]["target"][/{(.*)}/,1]
    end

    @result.passed("HTML: SSB params match") if query_param == target_param
    @result.failed("HTML: SSB params do not match") unless  query_param == target_param


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
    #comp_get = c.head(@server.url)
    #byebug
    #compressed_page = comp_get.headers["Content-Length"].to_i if comp_get.status == 200
    @result.passed("HTML: Page size #{@server.response.data.length.to_human} ") # (#{compressed_page.to_human} compressed)")

    ##
    # Use this base
    ##
    base = URI.parse("#{@server.url.scheme}://#{@server.url.host}")

    ## 
    #  Sum the Javascript scripts
    #  Note: Need to take into account Google Analytics building a script tag that
    #        this static analysis doesn't consider
    ##
    js_length = @server.response.doc.xpath('//script/@src').inject(0) do |sum, src|  
      res = base.merge(URI.parse(src))
      sum + c.head(res.to_s).headers["Content-Length"].to_i
    end

    ## This will produce incorrect results if the server doesn't support gz
    cjs_length = @server.response.doc.xpath('//script/@src').inject(0) do |sum, src|  
      res = base.merge(URI.parse(src))
      sum + c.head(res.to_s + ".gz").headers["Content-Length"].to_i
    end
    @result.passed("HTML: Javascript size #{js_length.to_human} (Compressed: #{cjs_length.to_human})")

    ##
    # Sum the CSS
    ##
    cs_length = @server.response.doc.xpath('//link/@href').select{|s| s.value[/css$/]}.inject(0) do |sum, src|  
      res = base.merge(URI.parse(src))
      sum + c.head(res.to_s).headers["Content-Length"].to_i
    end
    ccs_length = @server.response.doc.xpath('//link/@href').select{|s| s.value[/css$/]}.inject(0) do |sum, src|  
      res = base.merge(URI.parse(src))
      sum + c.head(res.to_s + ".gz").headers["Content-Length"].to_i
    end
    @result.passed("HTML: Style size #{cs_length.to_human}")
  end
end
