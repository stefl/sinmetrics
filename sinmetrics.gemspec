spec = Gem::Specification.new do |s|
  s.name = 'sinmetrics'
  s.version = '0.0.1'
  s.date = '2010-04-05'
  s.summary = ''
  s.description = ''

  s.homepage = "http://github.com/lpetre/sinmetrics"

  s.authors = ["Luke Petre"]
  s.email = "lpetre@gmail.com"

  s.add_dependency('yajl-ruby')
  s.has_rdoc = false

  # ruby -rpp -e' pp `git ls-files | grep -v examples`.split("\n") '
  s.files = ["README",
   "lib/sinmetrics.rb",
   "lib/sinmetrics/kontagent.rb",
   "lib/sinmetrics/mixpanel.rb",
   "sinmetrics.gemspec"]
end
