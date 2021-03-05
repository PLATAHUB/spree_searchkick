# encoding: UTF-8
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'spree_searchkick/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_searchkick'
  s.version     = SpreeSearchkick::VERSION
  s.summary     = 'Add searchkick to spree'
  s.description = 'Filters, suggests, autocompletes, sortings, searches'
  s.required_ruby_version = '>= 2.5.0'

  s.author    = 'Gonzalo Moreno'
  s.email     = 'gonzalo.moreno@pm.me'
  s.homepage  = 'https://gonzalomoreno.me'

  # s.files       = `git ls-files`.split("\n")
  # s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'searchkick'
  s.add_dependency 'spree_core', '>= 3.7.0', '< 5.0'
  s.add_dependency 'deface'
  s.add_dependency 'spree_extension'

  s.add_development_dependency 'elasticsearch-extensions'
  s.add_development_dependency 'spree_dev_tools'
end
