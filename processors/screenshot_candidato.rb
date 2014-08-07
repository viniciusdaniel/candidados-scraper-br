module Processors
  class ScreenshotCandidato
    include Eleicoes::Formatter

    attr_accessor :id, :candidato, :logger

    def self.process(id, options = {})
      executor = Processors::PerfilCandidato.new id, options
      executor.process
    end

    def initialize(id, options = {})
      @id = id
      @candidato = Eleicao::Candidato.find_or_initialize_by id: @id
      @logger = options.fetch :logger, Logger.new(STDOUT)
    end

    def base_url(path='')
      "http://divulgacand2014.tse.jus.br#{path}"
    end

    def process
      if candidato.nil?
        logger.warn "Candidato não encontrado pelo ID #{id}"
      else
        logger.info "Screenshot: #{candidato.id} - #{candidato.nome_completo}"

        begin
          path = File.join(Eleicoes::Application.root, 'data', 'anexos', id, 'screenshot')
          FileUtils.mkpath(path, mode: 0766) unless Dir.exists?(path)

          final_path = File.join path, "#{id}.png"
  
          logger.info "Screenshot #{base_url candidato.url_profile} #{final_path}"
          params = %W(
            /usr/bin/xvfb-run
              --auto-servernum
              --server-num=1
              --server-args="-screen 0, 1024x768x24"

            /usr/bin/cutycapt
              --url="#{base_url(candidato.url_profile)}"
              --out="#{final_path}"
              --out-format=png
              --max-wait=360000
              --app-name="Mozilla"
              --app-version="5.0"
              --user-agent="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0"
          ).join ' '

          %x(#{params})

        rescue Exception => e
          logger.error "SCREENSHOT ERROR: Candidato ID :#{candidato.id} #{e.backtrace.join("\n")}"
          candidato.scraped_at = nil
          candidato.save
        end
      end
    end
  end
end