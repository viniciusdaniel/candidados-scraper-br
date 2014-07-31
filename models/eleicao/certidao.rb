module Eleicao
  class Certidao
    include Mongoid::Document

    field :descricao, type: String
    field :url, type: String

    include Mongoid::Timestamps

    belongs_to :candidato, class_name: "Eleicao::Candidato"
  end
end