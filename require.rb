require 'rubygems'
gem 'require'
require 'require'

Require do
  gem(:active_wrapper, '=0.2.3') { require 'active_wrapper' }
  gem :require, '=0.2.6'
  gem(:rake, '=0.8.7') { require 'rake' }
  gem :rspec, '=1.3.0'
  
  gemspec do
    author 'Winton Welsh'
    dependencies do
      gem :require
    end
    email 'mail@wintoni.us'
    name 'mover'
    homepage "http://github.com/winton/#{name}"
    summary "Move ActiveRecord records across tables like it ain't no thang"
    version '0.1.0'
  end
  
  bin { require 'lib/mover' }
  
  lib do
    require 'lib/mover/create_table'
    require 'lib/mover/move_record'
    require 'lib/mover/restore_record'
  end
  
  rakefile do
    gem(:active_wrapper)
    gem(:rake) { require 'rake/gempackagetask' }
    gem(:rspec) { require 'spec/rake/spectask' }
    require 'require/tasks'
  end
  
  rails_init { require 'lib/mover' }
  
  spec_helper do
    require 'require/spec_helper'
    require 'rails/init'
    require 'pp'
  end
end
