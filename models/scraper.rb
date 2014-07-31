class Scraper
  attr_accessor :agent

  delegate :get, :post, to: :agent

  def initialize(options: {})
    @agent = Mechanize.new do |agent|
      agent.max_history = 0
      agent.user_agent_alias = 'Linux Firefox'
      agent.follow_meta_refresh = true
      agent.keep_alive = true
    end

    debug! if options[:debug]
  end

  def debug!
    agent.log = Logger.new $stderr
    agent.agent.http.debug_output = $stderr
  end


end
