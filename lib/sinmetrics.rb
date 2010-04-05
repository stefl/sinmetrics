begin
  require 'sinatra/base'
rescue LoadError
  retry if require 'rubygems'
  raise
end

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/sinmetrics')

require 'kontagent'
require 'mixpanel'
