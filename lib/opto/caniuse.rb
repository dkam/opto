class CanIUse < Checker
  Opto.register( self)

  name                'can_i_use'
  description         'Check up on CSS features with CanIUse data'
  supported_protocols :http, :https

  def checks
    'flexbox': 'https://raw.githubusercontent.com/Fyrd/caniuse/master/features-json/flexbox.json'
  end

end
