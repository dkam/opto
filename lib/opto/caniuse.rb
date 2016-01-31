class CanIUse < Checker
  Opto.register( self)


  def initialize(server)
    self.supported_protocols  :http, :https
    @description = "Check up on CSS features with CanIUse data" 
    @short_name  = 'can_i_use'
    @server      = server
    @result      = @server.result
  end

  def checks
    'flexbox': 'https://raw.githubusercontent.com/Fyrd/caniuse/master/features-json/flexbox.json'
  end

end
