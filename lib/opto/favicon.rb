class Favicon
  Opto.register( self)

  def self.description
    "Check up on your Favicons" 
  end

  def self.supports?(protocol)
    [:http, :https].include?(protocol)
  end

  def initialize(url, doc)
  end

end
