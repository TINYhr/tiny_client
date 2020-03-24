require 'bundler/gem_tasks'
require 'rake/testtask'
require 'yard'

task default: [:test]

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/tiny_client/*_test.rb', 'test/tiny_client_test.rb']
end

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
  t.options = ['-o docs']
end

desc 'Build the gem'
task gem: [:test] do
  sh 'gem build tp_client.gemspec'
end

desc 'Clean up'
task :clean do
  sh 'rm -rf docs'
  sh 'rm -f tp_client*.gem'
end
