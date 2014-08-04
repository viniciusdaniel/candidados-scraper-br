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
    thread_count = 0
    threads = []

    cadidato_ids = Eleicao::Candidato.pluck(:id)
    cadidato_ids.each do |candidato_id|
      threads << Thread.new(thread_count+=1) do |_|
        processor = Processors::PerfilCandidato.new(candidato_id)
        processor.process
      end

       threads.each{ |t| t.join } and threads = [] if thread_count >= max_threads
    end
    threads.each{ |t| t.join } if thread_count > 0
  end
end
