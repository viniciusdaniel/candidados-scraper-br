module Processors
  class PerfilCandidato
    include Eleicoes::Formatter

    attr_accessor :id, :candidato, :scraper, :persist_raw, :logger

    def self.process(id, options = {})
      executor = Processors::PerfilCandidato.new id, options
      executor.process
    end

    def initialize(id, options = {})
      @id = id
      @scraper = Scraper.new options
      @logger = options.fetch :logger, Logger.new(STDOUT)
      @persist_raw = options.fetch :persist_raw, true
    end

    def base_url(path='')
      "http://divulgacand2014.tse.jus.br#{path}"
    end

    def persist_raw(data)
      path = File.join(Eleicoes::Application.root, 'data', 'candidatos')
      FileUtils.mkpath(path, mode: 0766) unless Dir.exists?(path)

      File.open(File.join(path,"#{id}.txt"), "wb+") do |fs|
        fs.write data
      end
    end

    def parse_perfil(response)
      data = {}
      m = response.search('.breadcrumb li:last-child a').text.match Regexp.new('(?<ultima_atualizacao>\d+/\d+/\d+\s+\d+:\d+:\d+)')
      data[:ultima_atualizacao] = time_from_string(clean!(m[:ultima_atualizacao])) if m

      table = response.search('.col-md-10 .table.table-condensed.table-striped tbody')
      data[:nome_urna] = clean! table.search('tr:nth-of-type(1) td:nth-of-type(1)').text
      data[:numero] = clean! table.search('tr:nth-of-type(1) td:nth-of-type(2)').text

      data[:nome_completo] = clean! table.search('tr:nth-of-type(2) td:nth-of-type(1)').text
      data[:sexo] = clean! table.search('tr:nth-of-type(2) td:nth-of-type(2)').text

      data[:cor] = clean! table.search('tr:nth-of-type(4) td:nth-of-type(1)').text

      data[:nacionalidade] = clean! table.search('tr:nth-of-type(5) td:nth-of-type(1)').text
      data[:naturalidade] = clean! table.search('tr:nth-of-type(5) td:nth-of-type(2)').text

      data[:grau_instrucao] = clean! table.search('tr:nth-of-type(6) td:nth-of-type(1)').text
      data[:ocupacao] = clean! table.search('tr:nth-of-type(6) td:nth-of-type(2)').text

      data[:site] = clean! table.search('tr:nth-of-type(7) td:nth-of-type(1)').text

      data[:partido] = clean! table.search('tr:nth-of-type(8) td:nth-of-type(1)').text

      data[:coligacao] = clean! table.search('tr:nth-of-type(9) td:nth-of-type(1)').text

      data[:composicao_coligacao] = clean! table.search('tr:nth-of-type(10) td:nth-of-type(1)').text

      data[:numero_processo] = clean! table.search('tr:nth-of-type(11) td:nth-of-type(1)').text
      data[:numero_protocolo] = clean! table.search('tr:nth-of-type(11) td:nth-of-type(2)').text

      data[:cnpj] = clean! table.search('tr:nth-of-type(12) td:nth-of-type(1)').text
      data[:limite_gastos] = clean! table.search('tr:nth-of-type(12) td:nth-of-type(2)').text

      data[:url_foto] = clean! response.search('img.pull-left.foto-candidato').attr('src').text
      data[:situacao] = clean!(response.search('.col-md-2 p:nth-of-type(4)').text).gsub(/[()]/,'')
      data[:total_bens] = clean! response.search('#tab-bens tfoot th:last-child').text

      iframe = response.search('#tab-sit-procss iframe')
      data[:acompanhamento_processual_url] = clean! iframe.attr('src').text unless iframe

      c = Eleicao::Candidato.find_or_initialize_by id: id
      data.each_pair{ |k,v| c[k] = v }
      c.save

      download_attachments data[:url_foto], "#{id}#{fileext(data[:url_foto])}", 'perfil'

      @candidato = c
    end

    def parse_bens(response)
      @candidato.bens.destroy_all
      response.search('#tab-bens tbody tr').each do |bem|
        descricao = clean! bem.search('td:nth-of-type(1)').text
        valor = clean! bem.search('td:nth-of-type(2)').text
        Eleicao::Bem.find_or_create_by(descricao: descricao, valor: valor, candidato:  @candidato)
      end
    end

    def parse_certidoes(response)
      @candidato.certidoes.destroy_all
      response.search('#tab-docs tbody tr').each do |cert|
        a = cert.search('td a')
        next if a.count.equal?(0)

        url = clean! a.attr('href').text
        descricao = clean! a.text

        Eleicao::Certidao.create(descricao: descricao, url: url, candidato:  @candidato)

        download_attachments url, descricao, 'cerditoes'
      end
    end

    def parse_propostas(response)
      @candidato.propostas.destroy_all
      response.search('#tab-propostas tbody tr').each do |cert|
        a = cert.search('td a')
        next if a.count.equal?(0)

        url = clean! a.attr('href').text
        descricao = clean! a.text
        Eleicao::Proposta.create(descricao: descricao, url: url, candidato:  @candidato)

        download_attachments url, descricao, 'propostas'
      end
    end

    def parse_suplentes(response)
      list = response.search('#tab-corr tbody tr')
      list = response.search('#tab-titular tbody tr') unless list

      @candidato.candidatos_relacionados = []

      list.each do |bem|
        id = clean! bem.search('td:nth-of-type(1)').text
        nome = clean! bem.search('td:nth-of-type(2)').text
        url_profile = clean! bem.search('td:nth-of-type(3) a').attr('href').text

        c = Eleicao::Candidato.find_or_initialize_by id: id
        c.nome_completo = nome
        c.url_profile = url_profile
        c.save

        @candidato.candidatos_relacionados << c
      end
    end

    def parse_eleicoes(response)
      @candidato.eleicoes.destroy_all
      response.search('#tab-el-anteriores tbody tr').each do |bem|
        ano = clean! bem.search('td:nth-of-type(1)').text
        url = clean! bem.search('td:nth-of-type(2) a').attr('href').text
        Eleicao::Eleicao.create(ano: ano, url: url, candidato:  @candidato)
      end
    end

    def download_attachments(url, filename, dir)
      path = File.join(Eleicoes::Application.root, 'data', 'anexos', id, dir)
      FileUtils.mkpath(path, mode: 0766) unless Dir.exists?(path)

      final_path = File.join path, filename_format(filename)

      @logger.info "Download #{base_url url}"
      @scraper.download base_url(url), final_path
    end

    def process
      @candidato = Eleicao::Candidato.find_by id: id
      if @candidato.nil?
        logger.warn "Candidato não encontrado pelo ID #{id}"
      else
        logger.info "Candidato: #{@candidato.id} - #{@candidato.nome_completo}"

        begin
          response = @scraper.get base_url(@candidato.url_profile)
          persist_raw response.body if @persist_raw

          @candidato = parse_perfil response
          parse_bens response
          parse_certidoes response
          parse_propostas response
          parse_suplentes response
          parse_eleicoes response

          @candidato.scraped_at = Time.now
          @candidato.save
        rescue Exception => e
          logger.error "SCRAPER ERROR: Candidato ID :#{@candidato.id} #{e.backtrace.join("\n")}"
          @candidato.scraped_at = nil
          @candidato.save
        end
      end
    end
  end
end