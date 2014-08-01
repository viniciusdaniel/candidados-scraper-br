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
    app = Eleicoes::Application.new
    app.varre_candidatos
  end
end
