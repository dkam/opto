class Cache
  Opto.register( self)

  def self.description
    "Check up on CSS features with CanIUse data" 
  end

  def self.supports?(protocol)
    [:http, :https].include?(protocol)
  end

  def initialize(data)
    @data = data
  end

  def check
    'flexbox': 'https://raw.githubusercontent.com/Fyrd/caniuse/master/features-json/flexbox.json'
  end

end
