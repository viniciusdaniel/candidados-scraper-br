module Eleicao
  class Cargo
    include Mongoid::Document

    field :id, type: Integer
    field :nome, type: String

    include Mongoid::Timestamps

    belongs_to :candidato, class_name: "Eleicao::Candidato"

    index({ id: 1 }, { unique: true, background: true })
    index({ nome: 1 }, { unique: true, background: true })

  end
end
