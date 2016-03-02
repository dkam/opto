require 'open-uri'
require 'JSON'

class Cve < Checker
  Opto.register( self)

  suite               'cve'
  description         'Check for CVE'
  supported_protocols true

  DATA_BASE = File.expand_path("~/.opto/data")


  ##
  #  Currently only checking server
  ##
  def checks
    return if  @server.info[:server_version].nil? && @server.info[:app_server_version].nil? 

    cve_data = update_cve_files(@server.info[:server_name])

    if cve_data.nil?
      @result.warned("CVE Data not available for #{@server.info[:server_name]}.")
      return
    end

    server_version = @server.info[:server_version] 

    short_name = "#{@server.info[:server_name]}/#{@server.info[:server_version]}"

    cve_data["cves"].each do |cve|
      from_v  = Version.new cve['from']
      to_v    = cve['to'].nil?    ? nil : Version.new(cve['to']) 
      prior_v = cve['prior'].nil? ? nil : Version.new(cve['prior']) 

      # If the server version is 
      if server_version >= from_v 
        
        #  if there are no to_ / prior_v or  to_v is present and we're in the range     or  prior is present and we're in the range, then...
        if ( to_v.nil? && prior_v.nil? ) || ( !to_v.nil? && server_version <= to_v ) || ( !prior_v.nil? && server < prior_v )
          @result.failed("CVE: #{short_name} CVE-#{cve['cve']}: #{cve['title']}: #{cve['url']}")
        end
      end

    end

  end

  private
  def cve_data(server)
    JSON.parse( File.read( File.join( DATA_BASE, "#{server}.json") ) )
  rescue JSON::ParserError => e
    puts "Parse error for CVE data for #{server}"
    return nil
  rescue
    nil
  end

  def cve_etag(server)
    File.read( File.join( DATA_BASE, "#{server}.etag") )
  rescue
    nil
  end

  def store_cve(server, data, etag)
    File.write(File.join( DATA_BASE, "#{server}.json"), data)
    File.write(File.join( DATA_BASE, "#{server}.etag"), etag)
  end

  def update_cve_files(server)

    FileUtils.mkdir_p(DATA_BASE) unless Dir.exist?( DATA_BASE )

    data_url = "https://raw.githubusercontent.com/dkam/opto/master/data/cve/#{server}.json"

    etag = cve_etag(server)
    json_data = cve_data(server)

    # Set the eTag header if we have an etag file.  
    # Don't set the header if we don't have the data file - we need to download it anyway
    
    headers = {}
    headers["If-None-Match"] = etag if !etag.nil? && !json_data.nil?

    begin 
      data = open(data_url, headers)
      store_cve(server, data.read, data.meta['etag'])
    rescue OpenURI::HTTPError => e
      puts  e.io.status[0] 
      if  e.io.status[0] == "404"
        puts "CVE data for #{server} not found"
      elsif  e.io.status[0] == "304"
        puts "CVE Data already up-to-date"
        puts "#{e.message}"
      end
    end

    return cve_data(server) 
  end

end
