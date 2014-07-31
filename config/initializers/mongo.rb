config =  File.expand_path('../../mongoid.yml', __FILE__)
env = ENV['RACK_ENV'] || 'development'

Mongoid.load! config, env

#Mongoid.logger.level = Logger::DEBUG
#Moped.logger.level = Logger::DEBUG
