require File.expand_path("#{File.dirname(__FILE__)}/spec_helper")

describe MaestroDev::Plugin::CucumberWorker do

  before(:each) do
    Maestro::MaestroWorker.mock!
    @workitem = {'fields' => { 'features' => [], 'tags' => [], 'profile' => "", 'strict' => false }}
  end

  describe 'execute()' do

    it "should run cucumber" do
      subject.perform(:execute, @workitem)

      subject.args.should_not include("--strict")
      subject.args.should_not include("--profile")
      subject.args.should_not include("--tags")
      subject.workitem['fields']['__error__'].should be_nil
    end

    it "should run cucumber with tags" do
      @workitem['fields']['tags'] = ["@123", "~@skip", "@def,@ghi"]

      subject.perform(:execute, @workitem)
      subject.args.should include("--tags")
      subject.args.should include("@123")
      subject.args.should include("~@skip")
      subject.args.should include("@def,@ghi")

      subject.workitem['fields']['__error__'].should be_nil
    end

    it "should fail with bad tags" do
      @workitem['fields']['tags'] = ["123"]

      subject.perform(:execute, @workitem)

      subject.workitem['fields']['__error__'].should match(%r{Cucumber tests failed.* Bad tag: "123"})
    end

    it "should be strict when specified" do
      @workitem['fields']['strict'] = true

      subject.perform(:execute, @workitem)

      subject.args.should include("--strict")
      subject.workitem['fields']['__error__'].should be_nil
    end

  end
end
