# -*- encoding: utf-8 -*-
root = File.expand_path('../', __FILE__)
lib = "#{root}/lib"
$:.unshift lib unless $:.include?(lib)
 
require 'mover/gems'
Mover::Gems.gemset ||= ENV['GEMSET'] || :default

Gem::Specification.new do |s|
  Mover::Gems.gemspec.hash.each do |key, value|
    if key == 'name' && Mover::Gems.gemset != :default
      s.name = "#{value}-#{Mover::Gems.gemset}"
    elsif key == 'summary' && Mover::Gems.gemset == :solo
      s.summary = value + " (no dependencies)"
    elsif !%w(dependencies development_dependencies).include?(key)
      s.send "#{key}=", value
    end
  end

  Mover::Gems.dependencies.each do |g|
    s.add_dependency g.to_s, Mover::Gems.versions[g]
  end
  
  Mover::Gems.development_dependencies.each do |g|
    s.add_development_dependency g.to_s, Mover::Gems.versions[g]
  end

  s.executables = `cd #{root} && git ls-files -- {bin}/*`.split("\n").collect { |f| File.basename(f) }
  s.files = `cd #{root} && git ls-files`.split("\n")
  s.require_paths = %w(lib)
  s.test_files = `cd #{root} && git ls-files -- {features,test,spec}/*`.split("\n")
end