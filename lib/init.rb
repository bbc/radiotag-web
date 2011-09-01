require 'rubygems'
require 'load_path'
LoadPath.base_path = File.expand_path(File.join(File.dirname(__FILE__), '..'))

require 'bundler'

# add require_relative
unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require_relative 'config_helper'

Bundler.require

require_relative 'app'
require_relative 'model_ext'

config = ConfigHelper.load_config("config/database.yml")
service_config = ConfigHelper.load_config("config/services.yml")
admin_config = ConfigHelper.load_config("config/admin.yml")

def mysql_connect_string(config, environment)
  db_config = config[environment]
  port_string = db_config[:port]
  if port_string
    port_string = ":#{port_string}"
  end
  # user:password@host[:port]/database
  "#{db_config[:user]}:#{db_config[:password]}@#{db_config[:host]}#{port_string}/#{db_config[:database]}"
end

configure :test do
  puts 'Test configuration in use'
  DataMapper.setup(:default, "sqlite::memory:")
  DataMapper.auto_migrate!

  AdminUsers = admin_config[:test][:admin_users]
  AuthService = RestClient::Resource.new(service_config[:test][:authservice])
end

configure :development do
  puts 'Development configuration in use'
  DataMapper.setup(:default, "mysql://#{mysql_connect_string(config, :development)}?encoding=UTF-8")
  DataMapper.auto_upgrade!

  AuthService = RestClient::Resource.new(service_config[:development][:authservice])
  AdminUsers = admin_config[:development][:admin_users]
  RestClient.log = 'stdout'
end

configure :production do
  puts 'Production configuration in use'
  DataMapper.setup(:default, "mysql://#{mysql_connect_string(config, :production)}?encoding=UTF-8")
  DataMapper.auto_upgrade!

  AdminUsers = admin_config[:production][:admin_users]
  AuthService = RestClient::Resource.new(service_config[:production][:authservice])
end
