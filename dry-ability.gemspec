# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'dry/ability/version'

Gem::Specification.new do |s|
  s.name        = 'dry-ability'
  s.version     = Dry::Ability::VERSION
  s.authors     = ['Anton Semenov', 'Alessandro Rodi (Renuo AG)', 'Bryan Rite', 'Ryan Bates', 'Richard Wilson']
  s.email       = 'anton.estum@gmail.com'
  s.homepage    = 'https://github.com/estum/dry-ability'
  s.summary     = 'Dried authorization solution for Rails.'
  s.description = 'Dried authorization solution for Rails. All permissions are stored in a single location.'
  s.platform    = Gem::Platform::RUBY
  s.license     = 'MIT'

  s.files       = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  s.test_files  = `git ls-files -- Appraisals {spec,features,gemfiles}/*`.split($INPUT_RECORD_SEPARATOR)
  s.executables = `git ls-files -- bin/*`.split($INPUT_RECORD_SEPARATOR).map { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.6.0'

  s.add_dependency 'activesupport', '>= 5.2'
  s.add_dependency 'dry-types', '>= 1.5.0'
  s.add_dependency 'dry-initializer', '>= 3.0.4'
  s.add_dependency 'dry-container', '>= 0.7.2'
  s.add_dependency 'concurrent-ruby', '>= 1.1.8'

  s.add_development_dependency 'bundler', '~> 2.2.15'
  s.add_development_dependency 'rubocop', '~> 0.46'
  s.add_development_dependency 'rake', '~> 13.0.3'
  s.add_development_dependency 'rspec', '~> 3.2.0'
  s.add_development_dependency 'appraisal', '>= 2.0.0'
end
