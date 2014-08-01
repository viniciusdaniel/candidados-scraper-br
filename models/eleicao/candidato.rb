module Eleicao
  class Candidato
    include Mongoid::Document

    field :url_profile, type: String
    field :uf, type: String
    field :ultima_atualizacao, type: DateTime

    field :id, type: String
    field :nome_urna, type: String
    field :nome_completo, type: String
    field :data_nascimento, type: Date
    field :cor, type: String
    field :nacionalidade, type: String
    field :grau_instrucao, type: String
    field :site, type: String
    field :partido, type: String
    field :partido_sigla, type: String
    field :coligacao, type: String
    field :composicao_coligacao, type: String
    field :numero_processo, type: String
    field :cnpj, type: String

    field :numero, type: String
    field :sexo, type: String
    field :estado_civil, type: String
    field :naturalidade, type: String
    field :ocupacao, type: String

    field :numero_protocolo, type: String
    field :limite_gastos, type: String

    field :url_foto, type: String
    field :situacao, type: String
    field :total_bens, type: String
    field :acompanhamento_processual_url, type: String

    include Mongoid::Timestamps

    has_one :cargo, class_name: "Eleicao::Cargo"
    has_many :bens, class_name: "Eleicao::Bem"
    has_many :certidoes, class_name: "Eleicao::Certidao"
    has_many :propostas, class_name: "Eleicao::Proposta"
    has_many :eleicoes, class_name: "Eleicao::Eleicao"

    has_and_belongs_to_many :candidatos_relacionados, class_name: "Eleicao::Candidato"

    index({ id: 1 }, { unique: true, background: true })
  end
end
