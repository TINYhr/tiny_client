Gem::Specification.new do |s|
  s.name    = "tiny-client"
  s.authors = ["SWAT"]
  s.version = '0.1.0'
  s.date    = '2017-02-22'
  s.description = %q{TINYclient, an HTTP/JSON crud client toolkit.}
  s.email   = 'swat@tinypulse.com'
  s.extra_rdoc_files = ['LICENSE', 'README.md']

  s.files = ["LICENSE", "README.md", "Rakefile", "doc.rb", "lib/*.rb"]
  #### Load-time details
  s.require_paths = ['lib','ext']
  s.rubyforge_project = 'tiny-client'
  s.summary = %q{TINYclient, an HTTP/JSON crud client toolkit.}
  s.test_files = ['test/tiny_client/*']

 s.extensions << 'ext/extconf.rb'


#### Documentation and testing.
 s.has_rdoc = true
 s.homepage = 'http://'
 s.rdoc_options = ['--main', 'README.md']

 s.platform = Gem::Platform::RUBY

 s.licenses = ['TINYpulse all right reserved.']
end
