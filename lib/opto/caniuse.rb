class Cache
  Opto.register( self)

  def self.description
    "Check up on CSS features with CanIUse data" 
  end

  def self.supports?(server)
    [:http, :https].include?(server.protocol)
  end

  def initialize(server)
    @server = server
    @result = @server.result
  end

  def check
    'flexbox': 'https://raw.githubusercontent.com/Fyrd/caniuse/master/features-json/flexbox.json'
  end

end
