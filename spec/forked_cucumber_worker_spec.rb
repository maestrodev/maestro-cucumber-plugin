# Copyright 2011 MaestroDev.  All rights reserved.

require 'spec_helper'

describe MaestroDev::Plugin::ForkedCucumberWorker do
  BAD_RUBY_VERSION = "x.y.z"
  BAD_RUBYGEMS_VERSION = "a.b.c"
  FAKE_EXECUTABLE_FAIL = 'echo "if [ \"\$1\" == \"--version\" ]; then echo "cucumber, version 1.2.1" && exit 0; else echo Fail && exit 1; fi" > /tmp/fake_cucumber; sh /tmp/fake_cucumber'
  FAKE_EXECUTABLE_SUCCEED = 'echo "if [ \"\$1\" == \"--version\" ]; then echo "cucumber, version 1.2.1" && exit 0; else echo Success && exit 0; fi" > /tmp/fake_cucumber; sh /tmp/fake_cucumber'

  let(:ruby_version) { ENV['RUBY_VERSION'] }
  let(:rubygems_version) do
    rg = Maestro::Util::Shell.run_command("rvm #{@ruby_version} do gem --version")
    rg[0].success? ? rg[1].chomp : ''
  end

  before(:each) do
    Maestro::MaestroWorker.mock!
  end

  after(:each) do
    FileUtils.rm '/tmp/shell.sh' if File.exists? '/tmp/shell.sh'
    File.exists?('/tmp/shell.sh').should_not be_true
  end
    
  describe 'valid_workitem?' do
      
    it "should validate fields" do
      workitem = {'fields' => {
        'cucumber_executable' => '/dev/nul',
        'use_rvm' => true,
        'rvm_executable' => '/dev/nul',
        'use_bundle' => true,
        'bundle_executable' => '/dev/nul',
        'ruby_version' => BAD_RUBY_VERSION,
        'rubygems_version' => BAD_RUBYGEMS_VERSION}}
      subject.perform(:execute, workitem)

      workitem['fields']['__error__'].should include("cucumber not installed")
      workitem['fields']['__error__'].should include("rvm not installed")
      workitem['fields']['__error__'].should include("bundle not installed")
      workitem['fields']['__error__'].should include("missing field path")
      workitem['fields']['__error__'].should include("Requested Ruby version #{BAD_RUBY_VERSION} not available")
      workitem['fields']['__error__'].should include("Requested RubyGems version #{BAD_RUBYGEMS_VERSION} not available")
    end
      
    it "should detect cucumber" do
      workitem = {'fields' => {
        'cucumber_executable' => FAKE_EXECUTABLE_SUCCEED,
        'use_rvm' => false,
        'use_bundle' => false}}
      subject.perform(:execute, workitem)

      workitem['fields']['__error__'].should_not include("cucumber not installed")
    end

    it "should not error if everthing is ok" do
      workitem = {'fields' => {
        'cucumber_executable' => FAKE_EXECUTABLE_SUCCEED,
        'use_rvm' => false,
        'path' => '/tmp',
        'use_bundle' => false}}
      subject.perform(:execute, workitem)
  
      workitem['fields']['__error__'].should be_nil
    end

  end

  describe 'create_command' do
    before :each do
      @path = File.join(File.dirname(__FILE__), '..', '..')
      @workitem =  {'fields' => {
        'tasks' => '',
        'cucumber_executable' => FAKE_EXECUTABLE_SUCCEED,
        'path' => @path,
        'use_rvm' => false,
        'use_bundler' => false}}
    end

    it 'should create a simple command when no cucumber params are specified' do
      subject.perform(:execute, @workitem)
      @workitem['fields']['command'].should end_with("cucumber")
    end

    it 'should contain the features when specified' do
      features = "features"
      @workitem['fields']['features'] = features
      subject.perform(:execute, @workitem)
      @workitem['fields']['command'].should end_with("cucumber #{features}")
    end

    it 'should contain the profile when specified' do
      profile = "testprofile"
      @workitem['fields']['profile'] = profile
      subject.perform(:execute, @workitem)
      @workitem['fields']['command'].should end_with("cucumber --profile #{profile}")
    end

    it 'should contain the --strict flag when specified' do
      @workitem['fields']['strict'] = true
      subject.perform(:execute, @workitem)
      @workitem['fields']['command'].should end_with("cucumber --strict")
    end

    it 'should contain the tags when specified' do
      tags = [ "@abc", "@123,@def" ]
      @workitem['fields']['tags'] = tags
      subject.perform(:execute, @workitem)
      @workitem['fields']['command'].should end_with("cucumber --tags @abc --tags @123,@def")
    end
  end

  describe 'execute' do
    before :each do
      @path = File.join(File.dirname(__FILE__), '..', '..')
      @workitem =  {'fields' => {
        'tasks' => '--version',
        'cucumber_executable' => FAKE_EXECUTABLE_SUCCEED,
        'path' => @path,
        'use_rvm' => false,
        'ruby_version' => ruby_version,
        'rubygems_version' => rubygems_version,
        'environment' => 'CC=/usr/bin/gcc-4.2',
        'use_bundler' => false}}
    end

    # Problem in that it tries to run bundler outside of rvm
#    it 'should run cucumber with bundler' do
#      @workitem['fields']['use_bundler'] = true
#      subject.perform(:execute, @workitem)
#
#      @workitem['fields']['__error__'].should be_nil
#      @workitem['__output__'].should include("cucumber, version")
#      @workitem['__output__'].should_not include("ERROR")
#    end

    it 'should run cucumber with rvm' do
      @workitem['fields']['use_rvm'] = true
      subject.perform(:execute, @workitem)

      @workitem['fields']['__error__'].should be_nil
      @workitem['__output__'].should include("cucumber, version")
      @workitem['__output__'].should_not include("ERROR")
    end

#      it 'should run cucumber with rvm using non mri ruby' do
#        workitem = {'fields' => {'tasks' => '--version',
#           'path' => @path,
#           'use_rvm' => true,
#           'environment' => 'CC=/usr/bin/gcc-4.2',
#           'ruby_version' => 'jruby-1.6.4',
#           'rubygems_version' => '1.8.6',
#           'use_bundler' => false }}
#
#        @test_worker.stub(:create_command => "echo hello")
#
#        @test_worker.stub(:run)
#        @test_worker.stub(:valid_executable? => true)
#        @test_worker.stub(:update_ruby => [Maestro::Shell::ExitCode.new(0), "all clear"])
#        @test_worker.stub(:update_rubygems => true)
#        @test_worker.stub(:is_using_rubygems_version? => true)
#        @test_worker.stub(:validate_output => 'using /some/path/jruby-1.6.4  cucumber, version 1.2.1')
#        @test_worker.should_receive(:workitem).at_least(1).and_return(workitem)
#        @test_worker.execute
#
#        workitem['fields']['__error__'].should eql("")
#        workitem['fields']['output'].should include("cucumber, version")
#        workitem['fields']['output'].should include("jruby-1.6.4")
#        workitem['fields']['output'].should_not include("ERROR")
#      end

    it 'should run cucumber with rvm and bundler' do
      @workitem['fields']['use_rvm'] = true
      @workitem['fields']['use_bundle'] = true
      subject.perform(:execute, @workitem)

      @workitem['fields']['__error__'].should be_nil
      @workitem['__output__'].should include("cucumber, version")
      @workitem['__output__'].should_not include("ERROR")
    end

    it 'should run cucumber without rvm and bundler' do
      subject.perform(:execute, @workitem)

      @workitem['fields']['__error__'].should be_nil
      @workitem['__output__'].should include("cucumber, version")
      @workitem['__output__'].should_not include("ERROR")
    end
  end
end
