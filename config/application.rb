require 'mongoid'
require 'mechanize'
require 'pry'

dependencies = [
  File.expand_path('../initializers/**/*.rb', __FILE__),
  File.expand_path('../../models/**/*.rb', __FILE__),
  File.expand_path('../../processors/**/*.rb', __FILE__),
]

Dir.glob(dependencies).each { |file| load file }

I18n.enforce_available_locales = true

class Application
  def self.root
    File.expand_path('../../', __FILE__)
  end

  def atualiza_cargos
    CARGOS.each_pair do |cargo_id,_|
      ESTADOS.each do |uf|
        Processors::ListaCandidatos.process uf, cargo_id
      end
    end
  end

  def self.run
    app = Application.new
    app.atualiza_cargos

  end
end