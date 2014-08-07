module Processors
  class VarreCandidatos
    include Eleicoes::Formatter

    attr_accessor :uf, :cargo_id, :persist_raw, :logger

    def self.process(uf, cargo_id, options = {})
      executor = Processors::VarreCandidatos.new uf, cargo_id, options
      executor.process
    end

    def initialize(uf, cargo_id, options = {})
      @uf = uf
      @cargo_id = cargo_id
      @scraper = Scraper.new
      @logger = options.fetch :logger, Logger.new(STDOUT)
      @persist_raw = options.fetch :persist_raw, true

      @logger.info "Cargo: #{CARGOS[cargo_id]} UF: #{uf}"
    end

    def base_url
      "http://divulgacand2014.tse.jus.br"
    end

    def page_url
      "#{base_url}/divulga-cand-2014/eleicao/2014/UF/#{@uf}/candidatos/cargo/#{cargo_id}#"
    end

    def persist_raw(data)
      path = File.join Eleicoes::Application.root, 'data', CARGOS[cargo_id].downcase.parameterize
      FileUtils.mkpath(path, mode: 0766) unless Dir.exists?(path)

      File.open(File.join(path,"#{cargo_id}.txt"), "wb+") do |fs|
        fs.write data
      end
    end

    def process

      response = scraper.get page_url
      persist_raw response.body if @persist_raw

      lines = response.search '#tbl-candidatos tr'

      if lines
        logger.info "Resultado: #{lines.count} #{lines.count != 1 ? 'candidatos encontrados' : 'candidato encontrado'}"

        lines.each do |line|
          data = {}
          data[:id] = line.attr('id')
          next if data[:id].nil?

          data[:uf] = uf

          a = line.search('td:nth-of-type(1) a')
          data[:nome_completo] = clean! a.text
          data[:url_profile] = clean! a.attr('href').text

          data[:nome_urna] = clean! line.search('td:nth-of-type(2)').text
          data[:numero] = clean! line.search('td:nth-of-type(3)').text
          data[:situacao] = clean! line.search('td:nth-of-type(4)').text
          data[:partido_sigla] = clean! line.search('td:nth-of-type(5)').text
          data[:coligacao] = clean! line.search('td:nth-of-type(6)').attr('title').text

          candidato = Eleicao::Candidato.find_or_initialize_by id: data[:id]
          data.each_pair{ |k,v| candidato[k] = v }
          candidato.save

          candidato.cargo = Eleicao::Cargo.find_by(id: cargo_id)
          candidato.save
        end
      end
    end
  end
end