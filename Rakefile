require 'bundler/gem_tasks'
require 'rake/testtask'
require 'yard'

task default: [:test]
task gem: [:test, :build]

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/tiny_client/*_test.rb', 'test/tiny_client_test.rb']
end

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
  t.options = ['-o docs']
end
