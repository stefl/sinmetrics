spec = Gem::Specification.new do |s|
  s.name = 'sinmetrics'
  s.version = '0.0.7'
  s.date = '2010-04-14'
  s.summary = 'simple sinatra metrics extension'
  s.description = 'A full-featured metrics extension for the sinatra webapp framework'

  s.homepage = "http://github.com/lpetre/sinmetrics"

  s.authors = ["Luke Petre"]
  s.email = "lpetre@gmail.com"

  s.add_dependency('dm-core',        '>= 0.10.2')
  s.add_dependency('dm-aggregates',  '>= 0.10.2')
  s.add_dependency('dm-observer',    '>= 0.10.2')
  s.add_dependency('dm-timestamps',  '>= 0.10.2')
  s.add_dependency('dm-adjust',      '>= 0.10.2')
  s.add_dependency('activesupport',  '~> 2.3.5')
  s.has_rdoc = false

  # ruby -rpp -e' pp `git ls-files | grep -v examples`.split("\n") '
  s.files = [".gitignore",
   "README",
   "Rakefile",
   "lib/sinmetrics.rb",
   "lib/sinmetrics/abingo.rb",
   "lib/sinmetrics/abingo/alternative.rb",
   "lib/sinmetrics/abingo/experiment.rb",
   "lib/sinmetrics/abingo/statistics.rb",
   "lib/sinmetrics/kontagent.rb",
   "lib/sinmetrics/mixpanel.rb",
   "spec/abingo_spec.rb",
   "spec/kontagent_spec.rb",
   "spec/mixpanel_spec.rb",
   "spec/spec_helper.rb"]
end
