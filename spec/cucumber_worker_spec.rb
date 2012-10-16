require File.expand_path("#{File.dirname(__FILE__)}/spec_helper")

describe MaestroDev::CucumberWorker do

  before(:all) do
    @worker = MaestroDev::CucumberWorker.new
  end


  before(:each) do
    @workitem = {'fields' => { 'features' => [], 'tags' => [], 'profile' => "", 'strict' => false }}
    @worker.stub(:workitem => @workitem)
    @worker.stub(:write_output) { }
  end

  describe 'run()' do

    it "should run cucumber" do
      @worker.should_receive(:write_output).exactly(8).times

      @worker.run

      @worker.args.should_not include "--strict"
      @worker.args.should_not include "--profile"
      @worker.args.should_not include "--tags"
      @worker.workitem['fields']['__error__'].should be_nil


    end

    it "should run cucumber with tags" do
      @workitem['fields']['tags'] = ["@123", "~@skip", "@def,@ghi"]

      @worker.setup
      @worker.args.should include "--tags"
      @worker.args.should include "@123"
      @worker.args.should include "~@skip"
      @worker.args.should include "@def,@ghi"

      @worker.run
      @worker.workitem['fields']['__error__'].should be_nil
    end

    it "should fail with bad tags" do
      @workitem['fields']['tags'] = "123"
      @worker.should_receive(:write_output).twice

      @worker.run

      @worker.workitem['fields']['__error__'].should == "Cucumber tests failed gherkin.TagExpression$BadTagException: Bad tag: \"123\""
    end

    it "should use the specified profile" do
      # Even though the profile may specify another formatter, it should also send output to the worker
      @worker.should_receive(:write_output).exactly(8).times

      testprofile = "testprofile"
      @workitem['fields']['profile'] = testprofile

      @worker.setup
      @worker.args.should include "--profile"
      @worker.args.should include testprofile

      @worker.run
      @worker.workitem['fields']['__error__'].should be_nil

    end

    it "should be strict when specified" do
      @workitem['fields']['strict'] = true

      @worker.setup
      @worker.args.should include "--strict"

      @worker.run
      @worker.workitem['fields']['__error__'].should be_nil

    end


  end


end