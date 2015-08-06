class Images
  Opto.register( self)

  def self.description
    "Check up on your Images" 
  end

  def initialize(oe)
    @oe = oe
  end

  def check
    img_count   = 0
    alt_count   = 0
    svg_count   = 0
    png_count   = 0
    jpg_count   = 0
    srcset_count= 0
    other_count = 0

    @oe.doc.xpath("//img").each do |img|
      img_count += 1
      alt_count += 1 unless img.attributes["alt"].nil?
      case img.attributes["src"]
        when /.jpg$/ 
          jpg_count += 1 
          srcset_count +=1 unless img.attributes["srcset"].nil?
        when /.png$/ 
          png_count += 1 
        when /.svg$/ 
          svg_count += 1 
      end
    end

    puts "Found #{img_count} images.  #{svg_count} SVGs #{png_count} PNGS and #{jpg_count} JPGs, #{srcset_count} of which use SRCSET"

    missing_alts = img_count - alt_count
    puts "Found #{missing_alts} with no alt tags".green if missing_alts == 0
    puts "Found #{missing_alts} with no alt tags".red if missing_alts > 0
  end
end

class Image
end

