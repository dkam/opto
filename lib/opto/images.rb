class Images < Checker
  Opto.register( self)
  attr_reader :images 

  suite               'images'
  description         'Checks Your Images'
  supported_protocols :http, :https


  def checks
    @images = @server.response.doc.xpath("//img").collect {|e| Image.new(e, @server.url) }
    count
    optimise
  end

  def count
    alt_count        = 0
    jpg_srcset_count = 0
    png_srcset_count = 0
    other_count      = 0
    size_count       = 0

    @images.each do |img|
      alt_count        += 1 unless img.alt.nil?
      size_count       += 1 unless img.width.nil?  && img.height.nil?
      jpg_srcset_count += 1 if !img.srcset.nil? && img.format?( 'jpg' )
      png_srcset_count += 1 if !img.srcset.nil? && img.format?( 'png' )
    end

    puts "Found #{@images.length} images.  "
    puts "   SVG:   #{@images.select {|i| i.format? 'svg'}.length}"
    puts "   PNG:   #{@images.select {|i| i.format? 'png'}.length}, #{png_srcset_count} of which use SRCSET"
    puts "   JPG:   #{@images.select {|i| i.format? 'jpg'}.length}, #{jpg_srcset_count} of which use SRCSET"
    puts "   Other: #{other_count}"



    missing_size = @images.length - size_count
    if missing_size == 0
      @result.passed("Images: #{missing_size} with missing size attributes" ) 
    else
      @result.failed("Images: #{missing_size} with missing size attributes" )
    end

    missing_alts = @images.length - alt_count
    ma = "Images: #{missing_alts} with no alt tags"
    @result.passed( ma ) if missing_alts == 0
    @result.failed( ma ) if missing_alts > 0
  end

  def optimise
    #@oe.doc.xpath('//img[ends_with(@src, "jpg")]', MyFilter.new).each do |node|
    #

    @images.select {|i| i.format? 'jpg'}.each do |image|
      #puts "#{image.src.to_s} : #{image.content_length}"
    end
  end

end

class Image
  attr_reader :element, :src, :srcset, :srcset_src, :width, :height, :alt, :ext

  def initialize(element, url)
    @element= element

    host   = url.host
    scheme = url.scheme

    
    @src          = URI.parse( element.at_xpath("@src").value  )
    @src.host   ||= host
    @src.scheme ||= scheme

    @ext = @src.path.to_s[/\.([a-z]*)$/, 1]&.downcase

    # Srcset would only be used with JPG or PNG right?
    @srcset         = element.at_xpath("@srcset")
    @srcset_src     = @srcset.nil? ? [] : srcset.value.scan(/http.*?[^ ]*.[jpg|png]/)
    @width          = element.attributes["width"].try(:value)
    @height         = element.attributes["height"].try(:value)
    @alt            = element.attributes["alt"].try(:value)
  end

  def format
    @format ||= @src.to_s[/\.(.{3})$/, 1] || to_ext(FastImage.type(@src.to_s))
  rescue => e
    puts "Error caught #{e.message}"
  end

  def content_length
    @content_length ||= FastImage.new(@src).content_length
  end

  def format?(arg)
    return true if format == arg
    return false
  end

  def to_ext(type)
    ext = case type
          when :jpeg then 'jpg'
          when :png  then 'png'
          when :svg  then 'svg'
          else nil
          end
    return ext 
  end

end

class MyFilter
  def ends_with set, ends
    set.map { |x| x.to_s }.join.end_with? ends
  end
end


