require 'mongoid'
require 'mechanize'
require 'pry'

dependencies = [
  File.expand_path('../initializers/**/*.rb', __FILE__),
  File.expand_path('../../models/**/*.rb', __FILE__)
]

Dir.glob(dependencies).each { |file| load file }

class Application
  def initialize

  end
end
