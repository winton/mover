# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'mover/gems'
require 'mover/version'

Gem::Specification.new do |s|
  s.name = "mover"
  s.version = Mover::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Winton Welsh"]
  s.email = ["mail@wintoni.us"]
  s.homepage = "http://github.com/winton/mover"
  s.summary = "Move ActiveRecord records across tables like it ain't no thang"
  s.description = "Move ActiveRecord records across tables like it ain't no thang"

  Mover::Gems::TYPES[:gemspec].each do |g|
    s.add_dependency g.to_s, Mover::Gems::VERSIONS[g]
  end
  
  Mover::Gems::TYPES[:gemspec_dev].each do |g|
    s.add_development_dependency g.to_s, Mover::Gems::VERSIONS[g]
  end

  s.files = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README.md)
  s.executables = Dir.glob("{bin}/*").collect { |f| File.basename(f) }
  s.require_path = 'lib'
end