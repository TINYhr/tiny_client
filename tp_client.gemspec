Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name     = 'tp_client'
  s.version  = '0.2.3'
  s.authors  = ['TINYpulse Devops']
  s.email    = 'devops@tinypulse.com'

  s.license = 'MIT'

  s.summary     = 'TINYclient, an HTTP/JSON crud client toolkit.'
  s.description = 'TINYclient is an HTTP/JSON crud toolkit inspired by ActiveRecord and based on Curb.'
  s.homepage    = 'https://github.com/TINYhr/tiny_client'

  if s.respond_to?(:metadata)
    s.metadata['allowed_push_host'] = 'https://rubygems.org'
    s.metadata['homepage_uri']      = s.homepage
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  #### Load-time details
  s.files             = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  s.require_paths     = %w[lib ext]
  s.rubyforge_project = 'tiny_client'
  s.test_files        = ['test/tiny_client/']

  #### Documentation
  s.rdoc_options     = ['--main', 'README.md']
  s.extra_rdoc_files = ['LICENSE', 'README.md']

  s.add_runtime_dependency 'curb',          '> 0.7.0', '< 1.0.0'
  s.add_runtime_dependency 'activesupport', '>= 4.0',  '< 7.0'

  s.add_development_dependency 'appraisal', '~> 2.2', '>= 2.2.0'
end
