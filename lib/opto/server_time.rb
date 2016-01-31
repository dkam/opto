class ServerTime < Checker
  Opto.register( self)


  def initialize(server)
    self.supported_protocols = :http, :https
    @description = "Check Server Time"
    @short_name  = 'time'
    @server      = server
    @result      = @server.result
  end

  def checks
    check_server_time
  end

  def check_server_time
    if s_date =  @server.response.headers["date"]
      s_time = DateTime.parse(s_date).to_time
      n_time = Time.now

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
