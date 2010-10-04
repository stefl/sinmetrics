require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "stefl-sinmetrics"
    gemspec.summary = "simple sinatra metrics extension"
    gemspec.description = "A full-featured metrics extension for the sinatra webapp framework"
    gemspec.email = "lpetre@gmail.com"
    gemspec.homepage = "http://github.com/stefl/sinmetrics"
    gemspec.authors = ["Luke Petre"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

task :default => :spec

begin
  require 'spec/rake/spectask'
  desc "Run all examples"
  Spec::Rake::SpecTask.new('spec') do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.spec_opts = ['-cubfs']
  end

  Spec::Rake::SpecTask.new('spec:rcov') do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.spec_opts = ['-cfs']
    t.rcov = true
    t.rcov_opts = ['--exclude', 'gems,spec/,examples/']
  end
  
  require 'spec/rake/verify_rcov'
  RCov::VerifyTask.new(:verify_rcov => 'spec:rcov') do |t|
    t.threshold = 77.0
    t.require_exact_threshold = false
  end
  
rescue LoadError
  puts "spec targets require RSpec"
end
