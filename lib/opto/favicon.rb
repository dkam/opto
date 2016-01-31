class Favicon < Checker
  Opto.register( self)

  suite               'favicon'
  description         'Check Favicons'
  supported_protocols :http, :https

  def checks
    return true
  end
end
