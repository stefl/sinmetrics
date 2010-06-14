$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'spec'
require 'sinmetrics'
require 'dm-migrations'

# establish in-memory database for testing
#DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite3::memory:")

Spec::Runner.configure do |config|
  # reset database before each example is run
  config.before(:each) { DataMapper.auto_migrate! }
end
