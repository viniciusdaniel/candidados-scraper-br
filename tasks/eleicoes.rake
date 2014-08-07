namespace :eleicoes do
  desc "Carrega dados dos cargos"
  task :carrega_cargos  do
    CARGOS.each_pair do |id, nome|
      cargo = Eleicao::Cargo.find_or_initialize_by id: id
      cargo.nome = nome
      cargo.save
    end
  end

  desc "Varre o site a procura de candidatos"
  task :varre_candidados do
    CARGOS.each_pair do |cargo_id,_|
      ESTADOS.each do |uf|
        Processors::VarreCandidatos.process uf, cargo_id
      end
    end
  end

  desc "Varre os perfis encontrados previamente e completa as informações do candidato"
  task :varre_perfis, :max_threads do |_, args|
    max_threads = (args[:max_threads] || 20).to_i
    threads = []
    logger = Logger.new File.join(Eleicoes::Application.root, 'logs', 'varre_perfis.log')
    semaphore = Mutex.new
    candidato_ids = Eleicao::Candidato.pluck(:id)
    should_parse = {
        bens: true,
        certidoes: true,
        propostas: true,
        suplentes: true,
        eleicoes: true,
        screenshot: true,
    }

    0.upto(max_threads) do |thread_count|
      threads << Thread.new(thread_count) do |_|
        begin
          candidato_id = semaphore.synchronize { candidato_ids.pop }
          break if candidato_id.nil?

          processor = Processors::PerfilCandidato.new candidato_id, logger: logger, should_parse: should_parse
          processor.process
        end while true
      end
    end

    threads.each{ |t| t.join }
  end
end
