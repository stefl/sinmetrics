require 'rubygems'
require 'rake'

task :default => :spec

begin
  require 'spec/rake/spectask'
  desc "Run all examples"
  Spec::Rake::SpecTask.new('spec') do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.spec_opts = ['-cfs']
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
