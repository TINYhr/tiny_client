Gem::Specification.new do |s|
  s.name    = 'tiny-client'
  s.authors = ['TINYpulse swat team']
  s.version = '0.2.1'
  s.date    = '2017-02-22'
  s.description = 'TINYclient, an HTTP/JSON crud client toolkit.'
  s.email = 'jonathan@tinypulse.com'
  s.extra_rdoc_files = ['LICENSE', 'README.md']

  s.files = ['LICENSE', 'README.md', 'Rakefile', 'lib/tiny_client.rb']
  #### Load-time details
  s.require_paths = %w(lib ext)
  s.rubyforge_project = 'tiny-client'
  s.summary = 'TINYclient, an HTTP/JSON crud client toolkit.'
  s.test_files = ['test/tiny_client/']

  #### Documentation and testing.
  s.has_rdoc = 'yard'
  s.homepage = 'https://github.com/TINYhr/tiny-client'
  s.rdoc_options = ['--main', 'README.md']

  s.platform = Gem::Platform::RUBY

  s.license = 'Nonstandard'

  s.add_runtime_dependency 'curb', '> 0.7.0'
  s.add_runtime_dependency 'activesupport', '>= 4.0', '< 6.0'
end
