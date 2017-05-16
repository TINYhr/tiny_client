Gem::Specification.new do |s|
  s.name    = 'tiny_client'
  s.authors = ['TINYpulse swat team']
  s.version = '0.4.0'
  s.description = 'TINYclient, an HTTP/JSON crud client toolkit.'
  s.email = 'jonathan@tinypulse.com'
  s.extra_rdoc_files = ['LICENSE', 'README.md']
  s.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }

  #### Load-time details
  s.require_paths = %w(lib ext)
  s.rubyforge_project = 'tiny_client'
  s.summary = 'TINYclient is an HTTP/JSON crud toolkit inspired by ActiveRecord and based on Curb.'
  s.test_files = ['test/tiny_client/']

  #### Documentation and testing.
  s.has_rdoc = 'yard'
  s.homepage = 'https://github.com/TINYhr/tiny_client'
  s.rdoc_options = ['--main', 'README.md']

  s.platform = Gem::Platform::RUBY

  s.license = 'MIT'

  s.add_runtime_dependency 'curb', '> 0.7.0', '< 1.0.0'
  s.add_runtime_dependency 'activesupport', '>= 4.0', '< 6.0'
end
