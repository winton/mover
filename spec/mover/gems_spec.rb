require 'spec_helper'

describe Mover::Gems do
  
  before(:each) do
    @old_config = Mover::Gems.config
    
    Mover::Gems.config.gemspec = "#{$root}/spec/fixtures/gemspec.yml"
    Mover::Gems.config.gemsets = [
      "#{$root}/spec/fixtures/gemsets.yml"
    ]
    Mover::Gems.config.warn = true
    
    Mover::Gems.gemspec true
    Mover::Gems.gemset = nil
  end
  
  after(:each) do
    Mover::Gems.config = @old_config
  end
  
  describe :activate do
    it "should activate gems" do
      Mover::Gems.stub!(:gem)
      Mover::Gems.should_receive(:gem).with('rspec', '=1.3.1')
      Mover::Gems.should_receive(:gem).with('rake', '=0.8.7')
      Mover::Gems.activate :rspec, 'rake'
    end
  end
  
  describe :gemset= do
    before(:each) do
      Mover::Gems.config.gemsets = [
        {
          :name => {
            :rake => '>0.8.6',
            :default => {
              :externals => '=1.0.2'
            }
          }
        },
        "#{$root}/spec/fixtures/gemsets.yml"
      ]
    end
    
    describe :default do
      before(:each) do
        Mover::Gems.gemset = :default
      end
      
      it "should set @gemset" do
        Mover::Gems.gemset.should == :default
      end
    
      it "should set @gemsets" do
        Mover::Gems.gemsets.should == {
          :name => {
            :rake => ">0.8.6",
            :default => {
              :externals => '=1.0.2',
              :mysql => "=2.8.1",
              :rspec => "=1.3.1"
            },
            :rspec2 => {
              :mysql2 => "=0.2.6",
              :rspec => "=2.3.0"
            },
            :solo => nil
          }
        }
      end
    
      it "should set Gems.versions" do
        Mover::Gems.versions.should == {
          :externals => "=1.0.2",
          :mysql => "=2.8.1",
          :rake => ">0.8.6",
          :rspec => "=1.3.1"
        }
      end
      
      it "should return proper values for Gems.dependencies" do
        Mover::Gems.dependencies.should == [ :rake, :mysql ]
        Mover::Gems.development_dependencies.should == []
      end
      
      it "should return proper values for Gems.gemset_names" do
        Mover::Gems.gemset_names.should == [ :default, :rspec2, :solo ]
      end
    end
    
    describe :rspec2 do
      before(:each) do
        Mover::Gems.gemset = "rspec2"
      end
      
      it "should set @gemset" do
        Mover::Gems.gemset.should == :rspec2
      end
    
      it "should set @gemsets" do
        Mover::Gems.gemsets.should == {
          :name => {
            :rake => ">0.8.6",
            :default => {
              :externals => '=1.0.2',
              :mysql => "=2.8.1",
              :rspec => "=1.3.1"
            },
            :rspec2 => {
              :mysql2=>"=0.2.6",
              :rspec => "=2.3.0"
            },
            :solo => nil
          }
        }
      end
    
      it "should set Gems.versions" do
        Mover::Gems.versions.should == {
          :mysql2 => "=0.2.6",
          :rake => ">0.8.6",
          :rspec => "=2.3.0"
        }
      end
      
      it "should return proper values for Gems.dependencies" do
        Mover::Gems.dependencies.should == [ :rake, :mysql2 ]
        Mover::Gems.development_dependencies.should == []
      end
      
      it "should return proper values for Gems.gemset_names" do
        Mover::Gems.gemset_names.should == [ :default, :rspec2, :solo ]
      end
    end
    
    describe :solo do
      before(:each) do
        Mover::Gems.gemset = :solo
      end
      
      it "should set @gemset" do
        Mover::Gems.gemset.should == :solo
      end
    
      it "should set @gemsets" do
        Mover::Gems.gemsets.should == {
          :name => {
            :rake => ">0.8.6",
            :default => {
              :externals => '=1.0.2',
              :mysql => "=2.8.1",
              :rspec => "=1.3.1"
            },
            :rspec2 => {
              :mysql2=>"=0.2.6",
              :rspec => "=2.3.0"
            },
            :solo => nil
          }
        }
      end
    
      it "should set Gems.versions" do
        Mover::Gems.versions.should == {:rake=>">0.8.6"}
      end
      
      it "should return proper values for Gems.dependencies" do
        Mover::Gems.dependencies.should == [:rake]
        Mover::Gems.development_dependencies.should == []
      end
      
      it "should return proper values for Gems.gemset_names" do
        Mover::Gems.gemset_names.should == [ :default, :rspec2, :solo ]
      end
    end
    
    describe :nil do
      before(:each) do
        Mover::Gems.gemset = nil
      end
      
      it "should set everything to nil" do
        Mover::Gems.gemset.should == nil
        Mover::Gems.gemsets.should == nil
        Mover::Gems.versions.should == nil
      end
    end
  end
  
  describe :gemset_from_loaded_specs do
    before(:each) do
      Gem.stub!(:loaded_specs)
    end
    
    it "should return the correct gemset for name gem" do
      Gem.should_receive(:loaded_specs).and_return({ "name" => nil })
      Mover::Gems.send(:gemset_from_loaded_specs).should == :default
    end
    
    it "should return the correct gemset for name-rspec gem" do
      Gem.should_receive(:loaded_specs).and_return({ "name-rspec2" => nil })
      Mover::Gems.send(:gemset_from_loaded_specs).should == :rspec2
    end
  end
  
  describe :reload_gemspec do
    it "should populate @gemspec" do
      Mover::Gems.gemspec.hash.should == {
        "name" => "name",
        "version" => "0.1.0",
        "authors" => ["Author"],
        "email" => "email@email.com",
        "homepage" => "http://github.com/author/name",
        "summary" => "Summary",
        "description" => "Description",
        "dependencies" => [
          "rake",
          { "default" => [ "mysql" ] },
          { "rspec2" => [ "mysql2" ] }
        ],
        "development_dependencies" => nil
       }
    end
  
    it "should create methods from keys of @gemspec" do
      Mover::Gems.gemspec.name.should == "name"
      Mover::Gems.gemspec.version.should == "0.1.0"
      Mover::Gems.gemspec.authors.should == ["Author"]
      Mover::Gems.gemspec.email.should == "email@email.com"
      Mover::Gems.gemspec.homepage.should == "http://github.com/author/name"
      Mover::Gems.gemspec.summary.should == "Summary"
      Mover::Gems.gemspec.description.should == "Description"
      Mover::Gems.gemspec.dependencies.should == [
        "rake",
        { "default" => ["mysql"] },
        { "rspec2" => [ "mysql2" ] }
      ]
      Mover::Gems.gemspec.development_dependencies.should == nil
    end
  
    it "should produce a valid gemspec" do
      Mover::Gems.gemset = :default
      gemspec = File.expand_path("../../../mover.gemspec", __FILE__)
      gemspec = eval(File.read(gemspec), binding, gemspec)
      gemspec.validate.should == true
    end
  end
end
