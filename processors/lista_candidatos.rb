module Processors
  class ListaCandidatos
    attr_accessor :uf, :cargo_id

    def self.process(uf, cargo_id)
      puts "UF: #{uf} #{cargo_id}"
      lc = Processors::ListaCandidatos.new uf, cargo_id
      lc.process
    end

    def initialize(uf, cargo_id)
      @uf = uf
      @cargo_id = cargo_id
    end

    def base_url
      "http://divulgacand2014.tse.jus.br"
    end

    def page_url
      "#{base_url}/divulga-cand-2014/eleicao/2014/UF/#{@uf}/candidatos/cargo/#{cargo_id}#"
    end

    def persist_raw(data)
      path = File.join Application.root, 'data', CARGOS[cargo_id].downcase.parameterize
      Dir.mkdir(path, 0766) unless Dir.exists?(path)

      path = File.join path, "#{uf}.txt"

      File.open(path, "wb+") do |fs|
        fs.write data
      end
    end

    def clean!(text)
      text.strip
    end

    def process
      scraper = Scraper.new
      response = scraper.get page_url
      persist_raw response.body

      lines = response.search '#tbl-candidatos tr'

      if lines
        lines.each do |line|
          data = {}
          data[:id] = line.attr('id')
          next if data[:id].nil?

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
        end
      end
    end
  end
end