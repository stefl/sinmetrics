# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{sinmetrics}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Luke Petre"]
  s.date = %q{2010-04-05}
  s.description = %q{Some metrics helpers for the Sinatra web framework}
  s.email = %q{lpetre@gmail.com}
  s.files = ["README", "Rakefile", "lib/sinmetrics.rb", "lib/sinmetrics/kontagent.rb", "lib/sinmetrics/mixpanel.rb", "sinmetrics.gemspec", "Manifest"]
  s.homepage = %q{http://github.com/lpetre/sinmetrics}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Sinmetrics", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{sinmetrics}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Some metrics helpers for the Sinatra web framework}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
