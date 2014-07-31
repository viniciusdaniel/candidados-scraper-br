module Eleicao
  class Bem
    include Mongoid::Document

    field :descricao, type: String
    field :valor, type: String

    include Mongoid::Timestamps

    belongs_to :candidato, class_name: "Eleicao::Candidato"
  end
end