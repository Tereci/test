# encoding: UTF-8

require 'pathname'
require_relative 'base_backend.rb'

base = Pathname(__FILE__).dirname.expand_path

require_relative 'base_backend'

Dir.glob(base + '*.rb').each do |file|
  require_relative file
end
