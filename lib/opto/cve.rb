require 'open-uri'
require 'JSON'

class Cve < Checker
  Opto.register( self)

  suite               'cve'
  description         'Check for CVE'
  supported_protocols true


  def checks
    return if  @server.info[:server_version].nil? && @server.info[:app_server_version].nil? 

    cve_data = update_cve_files

    if cve_data.nil?
      @result.warned("CVE Data not available.")
      return
    end

    server_version = @server.info[:server_version] 

    cve_data.dig(@server.info[:server_name], "cves").each do |cve|
      from_v  = Version.new cve['from']
      to_v    = cve['to'].nil?    ? nil : Version.new(cve['to']) 
      prior_v = cve['prior'].nil? ? nil : Version.new(cve['prior']) 

      # If the server version is 
      if server_version >= from_v 
        
        #  if there are no to_ / prior_v or  to_v is present and we're in the range     or  prior is present and we're in the range, then...
        if ( to_v.nil? && prior_v.nil? ) || ( !to_v.nil? && server_version <= to_v ) || ( !prior_v.nil? && server < prior_v )
          @result.failed("CVE-#{cve['cve']}: #{cve['title']}: #{cve['url']}")
        end
      end

    end

  end



  def update_cve_files
    base = File.expand_path("~/.opto")
    etag_file = File.join( base, 'cve.etag')
    data_file = File.join( base, 'cve.json')
    data_url = "https://raw.githubusercontent.com/dkam/opto/master/cve.json"

    Dir.mkdir(base) unless Dir.exist?( base )

    etag = File.exist?(etag_file) ? File.read(etag_file) : nil

    # Set the eTag header if we have an etag file.  
    # Don't set the header if we don't have the data file - we need to download it anyway
    
    headers = {}
    headers["If-None-Match"] = etag if ! etag.nil? && File.exist?(data_file)

    begin 
      data = open(data_url, headers)

      File.write(etag_file, data.meta['etag'])
      File.write(data_file, data.read)

    rescue OpenURI::HTTPError => e
      puts "CVE Data up-to-date"
    end

    begin 
      doc  = JSON.parse(File.read(data_file))

    rescue JSON::ParserError => e
      puts "Parse error for CVE data ~/.opto/cve.json"
      return nil
    end
    return doc 
  end

end
