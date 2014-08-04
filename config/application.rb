require 'mongoid'
require 'mechanize'
require 'pry'

dependencies = [
  File.expand_path('../initializers/**/*.rb', __FILE__),
  File.expand_path('../../libs/**/*.rb', __FILE__),
  File.expand_path('../../models/**/*.rb', __FILE__),
  File.expand_path('../../processors/**/*.rb', __FILE__),
]

Dir.glob(dependencies).each { |file| load file }

module Eleicoes
  class Application
    attr_accessor :logger

    def initialize
      @logger = Logger.new STDOUT
    end

    def self.root
      File.expand_path('../../', __FILE__)
    end

    def varre_candidatos
      CARGOS.each_pair do |cargo_id,_|
        ESTADOS.each do |uf|
          Processors::VarreCandidatos.process uf, cargo_id
        end
      end
    end

    def varre_perfis_candidatos
      Processors::PerfilCandidato.process '280000000085', debug: false
    end

    def self.run
      app = Eleicoes::Application.new
      app.varre_perfis_candidatos
    end
  end
end

I18n.enforce_available_locales = true
