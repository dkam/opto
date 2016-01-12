class Favicon
  Opto.register( self)

  def self.description
    "Check Favicons" 
  end

  def self.supports?(server)
    [:http, :https].include?(server.protocol)
  end

  def initialize(server)
    @server = server
    @result = @server.result
  end
end
