class ServerTime < Checker
  Opto.register( self)

  suite                 'time'
  description           'Check Server Time'
  supported_protocols   :http, :https

  def checks
    check_server_time
  end

  def check_server_time
    if s_date =  @server.response.headers["date"]
      s_time = DateTime.parse(s_date).to_time
      n_time = Time.now

      # Give ourselves +/- a few (t_range) seconds
      t_range = 5

      if ((s_time - t_range)...(s_time + t_range)) === n_time
        @result.passed("ServerTime: Correct +/- #{t_range} seconds")
      else
        @result.failed("ServerTime: More than #{t_range} seconds out (#{s_time} vs #{n_time}")
      end
    else
      @result.failed("ServerTime: None given")
    end
  end


end
