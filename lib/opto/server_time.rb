class ServerTime
  Opto.register( self)

  def self.description
    "Checking Server Time"
  end

  def self.supports?(server)
    [:http, :https, :smtp, :smtps].include?(server.protocol)
  end

  def initialize(server)
    @server = server
    @result = @server.result
  end

  def check
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
