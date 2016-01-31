class Favicon < Checker
  Opto.register( self)


  def initialize(server)
    self.supported_protocols = :http, :https

    @description = 'Check Favicons'
    @short_name  = 'favicon'
    @server      = server
    @result      = @server.result
  end

  def checks
    return true
  end
end
