Gem::Specification.new do |s|
  s.name        = 'htcc'
  s.version     = '0.1.0'
  s.summary     = "A Ruby client for the Honeywell Total Connect Comfort API"
  s.description = "This gem can be used to control Honeywell thermostats that use the Total Connect Comfort platform."
  s.author      = 'Lee Folkman'
  s.email       = 'lee.folkman@gmail.com'
  s.files       = Dir['README.md', 'LICENSE', 'CHANGELOG.md', 'lib/**/*.rb', 'htcc.gemspec']
  s.homepage    = 'https://github.com/Folkman/htcc'
  s.license     = 'MIT'
  s.platform    = Gem::Platform::RUBY
end
