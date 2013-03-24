require "bundler/gem_tasks"
require "rake/testtask"

task :default => :spec
Rake::TestTask.new(:spec) do |t|
  t.libs << 'spec'
  if spec = ENV['spec']
    t.pattern = "spec/**/#{spec}*_spec.rb"
  else
    t.pattern = 'spec/**/*_spec.rb'
  end
  t.verbose = false
end