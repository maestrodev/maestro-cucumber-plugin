# Copyright 2011 MaestroDev.  All rights reserved.

require 'spec_helper'

describe MaestroDev::ForkedCucumberWorker do

    before(:each) do
      @test_worker = MaestroDev::ForkedCucumberWorker.new
      @test_worker.stub(:write_output)
    end

    after(:each) do
      FileUtils.rm '/tmp/shell.sh' if File.exists? '/tmp/shell.sh'
      File.exists?('/tmp/shell.sh').should_not be_true
    end
    
    describe 'valid_workitem?' do
      
      it "should validate fields" do
        workitem = {'fields' => {}}
        @test_worker.stub(:create_command => "echo hello")
        @test_worker.stub(:run)
        @test_worker.stub(:valid_executable? => true)
        @test_worker.stub(:update_ruby => true)
        @test_worker.stub(:update_rubygems => true)
        @test_worker.stub(:is_using_rubygems_version? => true)
        @test_worker.stub(:validate_output => 'cucumber, version 1.2.1')
        @test_worker.should_receive(:workitem).at_least(1).and_return(workitem)
        @test_worker.valid_workitem?

        workitem['fields']['__error__'].should include("[missing path]")
        workitem['fields']['__error__'].should_not include("[missing tasks]")
      end
      
      it "should detect cucumber" do
        workitem = {'fields' => {'tasks' => '', 'path' => '/tmp'}}
        @test_worker.stub(:create_command => "echo hello")
        @test_worker.stub(:run)
        @test_worker.stub(:valid_executable? => false)
        @test_worker.stub(:update_ruby => true)
        @test_worker.stub(:update_rubygems => true)
        @test_worker.stub(:is_using_rubygems_version? => true)
        @test_worker.stub(:validate_output => 'cucumber, version 1.2.1')
        @test_worker.stub(:valid_executable? => false)
        @test_worker.should_receive(:workitem).at_least(1).and_return(workitem)
        @test_worker.valid_workitem?

        workitem['fields']['__error__'].should include("[cucumber not installed]")
      end

      it "should validate rvm fields" do
        workitem = {'fields' => {'tasks' => '','path' => '/tmp', 'use_rvm' => true}}
        @test_worker.stub(:create_command => "echo hello")
        @test_worker.stub(:run)
        @test_worker.stub(:valid_executable? => false)
        @test_worker.stub(:update_ruby => true)
        @test_worker.stub(:update_rubygems => true)
        @test_worker.stub(:is_using_rubygems_version? => true)
        @test_worker.stub(:validate_output => 'cucumber, version 1.2.1')
        @test_worker.stub(:valid_executable? => false)
        @test_worker.should_receive(:workitem).at_least(1).and_return(workitem)
        @test_worker.valid_workitem?

        workitem['fields']['__error__'].should include("[rvm not installed]")
        workitem['fields']['__error__'].should include("[missing ruby_version]")
        workitem['fields']['__error__'].should include("[missing rubygems_version]")
      end
    
      it "should validate bundler" do
        workitem = {'fields' => {'tasks' => '','path' => '/tmp', 'use_bundler' => true}}
        @test_worker.stub(:create_command => "echo hello")
        @test_worker.stub(:run)
        @test_worker.stub(:valid_executable? => false)
        @test_worker.stub(:update_ruby => true)
        @test_worker.stub(:update_rubygems => true)
        @test_worker.stub(:is_using_rubygems_version? => true)
        @test_worker.stub(:validate_output => 'cucumber, version 1.2.1')
        @test_worker.stub(:valid_executable? => false)
        @test_worker.should_receive(:workitem).at_least(1).and_return(workitem)
        @test_worker.valid_workitem?
    
        workitem['fields']['__error__'].should include("[bundler not installed]")
      end

      it "should not error if everthing is ok" do
        workitem = {'fields' => {
           'use_rvm' => true,
           'path' => '/tmp',
           'ruby_version' => '1.8.7',
           'rubygems_version' => '1.8.11',
           'use_bundler' => true}}

        @test_worker.stub(:valid_executable? => true)

        @test_worker.should_receive(:workitem).at_least(1).and_return(workitem)
        @test_worker.valid_workitem?

        workitem['fields']['__error__'].should be_nil
      end

    end

    describe 'create_command' do
      before :each do
        @path = File.join(File.dirname(__FILE__), '..', '..')
        @workitem =  {'fields' => {'tasks' => '',
                                   'path' => @path,
                                   'use_rvm' => false,
                                   'ruby_version' => "",
                                   'rubygems_version' => "",
                                   'use_bundler' => false}}
        @test_worker.stub(:workitem => @workitem)

      end

      it 'should create a simple command when no cucumber params are specified' do
        @test_worker.valid_workitem?
        @test_worker.create_command.should end_with "cucumber\n"
      end


      it 'should contain the features when specified' do
        features = "features"
        @workitem['fields']['features'] = features
        @test_worker.valid_workitem?
        @test_worker.create_command.should end_with "cucumber #{features}\n"
      end

      it 'should contain the profile when specified' do
        profile = "testprofile"
        @workitem['fields']['profile'] = profile
        @test_worker.valid_workitem?
        @test_worker.create_command.should end_with "cucumber --profile #{profile}\n"
      end

      it 'should contain the --strict flag when specified' do
        @workitem['fields']['strict'] = true
        @test_worker.valid_workitem?
        @test_worker.create_command.should end_with "cucumber --strict\n"
      end

      it 'should contain the tags when specified' do
        tags = [ "@abc", "@123,@def" ]
        @workitem['fields']['tags'] = tags
        @test_worker.valid_workitem?
        @test_worker.create_command.should end_with "cucumber --tags @abc --tags @123,@def\n"
      end
    end


    describe 'execute' do
      before :all do
        @path = File.join(File.dirname(__FILE__), '..', '..')
        @workitem =  {'fields' => {'tasks' => '',
           'path' => @path,
           'use_rvm' => true,
           'ruby_version' => '9.9.9',
           'rubygems_version' => '1.8.11',
           'use_bundler' => true}}
      end


      it 'should error if ruby_version is invalid' do
           @test_worker.stub(:create_command => "echo hello")

           @test_worker.stub(:valid_executable? => true)
           @test_worker.stub(:update_ruby => [Maestro::Shell::ExitCode.new(127), "Unknown ruby interpreter version: '9.9.9'"])
           @test_worker.stub(:is_using_rubygems_version? => true)
           @test_worker.stub(:validate_output => 'cucumber, version 1.2.1')
           @test_worker.stub(:workitem => @workitem)
           @test_worker.execute

           @workitem['fields']['__error__'].should include("Unknown ruby interpreter version: '9.9.9'")
      end

      it 'should error if rubygems_version is invalid' do
        workitem = {'fields' => {'tasks' => '',
           'path' => @path,
           'use_rvm' => true,
           'environment' => 'CC=/usr/bin/gcc-4.2',
           'ruby_version' => '1.8.7',
           'rubygems_version' => '999',
           'use_bundle' => true}}

           @test_worker.stub(:create_command => "echo hello")
           @test_worker.stub(:run)
           @test_worker.stub(:valid_executable? => true)
           @test_worker.stub(:update_ruby => [Maestro::Shell::ExitCode.new(0), "all clear"])
           @test_worker.stub(:run_update_rubygems => [Maestro::Shell::ExitCode.new(127), "Invalid rubygems versions"])
           @test_worker.stub(:is_using_rubygems_version? => false)
           @test_worker.stub(:validate_output => 'cucumber, version 1.2.1')
        @test_worker.stub(:workitem => workitem)
        @test_worker.execute

        workitem['fields']['__error__'].should eql("Invalid rubygems versions")
      end



      it 'should run cucumber with bundler' do
        workitem = {'fields' => {'tasks' => '--version',
           'path' => @path,
           'use_rvm' => false,
           'environment' => 'CC=/usr/bin/gcc-4.2',
           'use_bundler' => true }}
        @test_worker.stub(:create_command => "echo hello")

        @test_worker.stub(:run)
        @test_worker.stub(:valid_executable? => true)
        @test_worker.stub(:update_ruby => [Maestro::Shell::ExitCode.new(0), "all clear"])
        @test_worker.stub(:update_rubygems => true)
        @test_worker.stub(:is_using_rubygems_version? => true)
        @test_worker.stub(:validate_output => 'cucumber, version 1.2.1')
        @test_worker.should_receive(:workitem).at_least(1).and_return(workitem)
        @test_worker.execute

        workitem['fields']['__error__'].should eql("")
        workitem['fields']['output'].should include("cucumber, version")
        workitem['fields']['output'].should_not include("ERROR")
      end

      it 'should run cucumber with rvm' do
        workitem = {'fields' => {'tasks' => '--version',
           'path' => @path,
           'use_rvm' => true,
           'environment' => 'CC=/usr/bin/gcc-4.2',
           'ruby_version' => '1.8.7',
           'rubygems_version' => '1.8.6',
           'use_bundler' => false }}
        @test_worker.stub(:create_command => "echo hello")
        @test_worker.stub(:valid_workitem? => true)
        @test_worker.stub(:run)
        @test_worker.stub(:valid_executable? => true)
        @test_worker.stub(:update_ruby => [Maestro::Shell::ExitCode.new(0), "all clear"])
        @test_worker.stub(:update_rubygems => true)
        @test_worker.stub(:validate_output => 'cucumber, version 1.2.1')
        @test_worker.stub(:is_using_rubygems_version? => true)

        @test_worker.should_receive(:workitem).at_least(1).and_return(workitem)
        @test_worker.execute

        workitem['fields']['__error__'].should eql("")
        workitem['fields']['output'].should include("cucumber, version")
        workitem['fields']['output'].should_not include("ERROR")
      end

      it 'should run cucumber with rvm using non mri ruby' do
        workitem = {'fields' => {'tasks' => '--version',
           'path' => @path,
           'use_rvm' => true,
           'environment' => 'CC=/usr/bin/gcc-4.2',
           'ruby_version' => 'jruby-1.6.4',
           'rubygems_version' => '1.8.6',
           'use_bundler' => false }}

        @test_worker.stub(:create_command => "echo hello")

        @test_worker.stub(:run)
        @test_worker.stub(:valid_executable? => true)
        @test_worker.stub(:update_ruby => [Maestro::Shell::ExitCode.new(0), "all clear"])
        @test_worker.stub(:update_rubygems => true)
        @test_worker.stub(:is_using_rubygems_version? => true)
        @test_worker.stub(:validate_output => 'using /some/path/jruby-1.6.4  cucumber, version 1.2.1')
        @test_worker.should_receive(:workitem).at_least(1).and_return(workitem)
        @test_worker.execute

        workitem['fields']['__error__'].should eql("")
        workitem['fields']['output'].should include("cucumber, version")
        workitem['fields']['output'].should include("jruby-1.6.4")
        workitem['fields']['output'].should_not include("ERROR")
      end

      it 'should run cucumber with rvm and bundler' do
        workitem = {'fields' => {'tasks' => '--version',
             'path' => @path,
             'use_rvm' => true,
             'environment' => 'CC=/usr/bin/gcc-4.2',
             'ruby_version' => '1.8.7',
             'rubygems_version' => '1.8.6',
             'use_bundler' => true }}
        @test_worker.stub(:create_command => "echo hello")

        @test_worker.stub(:valid_executable? => true)
        @test_worker.stub(:update_ruby => [Maestro::Shell::ExitCode.new(0), "all clear"])
        @test_worker.stub(:update_rubygems => true)
        @test_worker.stub(:run)
        @test_worker.stub(:is_using_rubygems_version? => true)
        @test_worker.stub(:validate_output => 'cucumber, version 1.2.1')
        @test_worker.should_receive(:workitem).at_least(1).and_return(workitem)
        @test_worker.execute

        workitem['fields']['__error__'].should eql("")
        workitem['fields']['output'].should include("cucumber, version")
        workitem['fields']['output'].should_not include("ERROR")
      end

      it 'should run cucumber without rvm and bundler' do
        workitem = {'fields' => {'tasks' => '--version',
            'path' => @path,
            'use_rvm' => false,
            'environment' => 'CC=/usr/bin/gcc-4.2',
            'use_bundler' => false }}

        @test_worker.stub(:create_command => "echo hello")

        @test_worker.stub(:valid_executable? => true)
        @test_worker.stub(:run)
        @test_worker.stub(:update_ruby => [Maestro::Shell::ExitCode.new(0), "all clear"])
        @test_worker.stub(:update_rubygems => true)
        @test_worker.stub(:is_using_rubygems_version? => true)
        @test_worker.stub(:validate_output => 'cucumber, version 1.2.1')
        @test_worker.should_receive(:workitem).at_least(1).and_return(workitem)
        @test_worker.execute

        workitem['fields']['__error__'].should eql("")
        workitem['fields']['output'].should include("cucumber, version")
        workitem['fields']['output'].should_not include("ERROR")
       end
    end
end