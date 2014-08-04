class Scraper
  attr_accessor :agent, :retries, :logger

  def initialize(options = {})
    @agent = Mechanize.new do |agent|
      agent.max_history = 1
      agent.user_agent_alias = 'Linux Firefox'
      agent.follow_meta_refresh = true
      agent.keep_alive = true
      agent.read_timeout = 120
      agent.open_timeout = 60
      agent.idle_timeout = 30
    end

    @retries = options.fetch :retries, 3
    @logger = options.fetch :logger, Logger.new(STDOUT)

    debug! if options[:debug]
  end

  def get(*args)
    request! :get, *args
  end

  def post(*args)
    request! :post, *args
  end

  def download(*args)
    request! :download, *args
  end

  def debug!
    agent.log = logger
    agent.agent.http.debug_output = logger
  end

  private
  def request!(method, *args)
    retries = 0
    begin
      agent.send method, *args
    rescue SocketError => sk_er
      retries += 1
      if retries <= @retries
        logger.info "Retry #{retries} of #{@retries} for #{method.to_s.upcase}: #{args.inspect} "
        retry
      end
      raise sk_er
    rescue Timeout::Error => to_er
      retries += 1
      if retries <= @retries
        logger.info "Retry #{retries} of #{@retries} for #{method.to_s.upcase}: #{args.inspect} "
        retry
      end
      raise to_er
    end
  end
end
