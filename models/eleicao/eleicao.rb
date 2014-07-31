module Eleicao
  class Eleicao
    include Mongoid::Document

    field :ano, type: Integer
    field :url, type: String

    include Mongoid::Timestamps

    belongs_to :candidato, class_name: "Eleicao::Candidato"
  end
end