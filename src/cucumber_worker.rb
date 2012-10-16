require 'rubygems'
require 'maestro_agent'
require 'cucumber/cli/main'
require 'maestro_formatter'

module MaestroDev
  class CucumberWorker < Maestro::MaestroWorker

    attr_reader :args

    def setup
      Cucumber::Formatter::WorkerIo.worker=self
      features = workitem['fields']['features']
      tags = (workitem['fields']['tags'] || [])
      profile = (workitem['fields']['profile'] || "")
      strict = workitem['fields']['strict']

      cucumber_opts = ["--format", "Cucumber::Formatter::MaestroFormatter"]

      tags.each do |tag|
        cucumber_opts.push("--tags", tag) unless tag.empty?
      end

      cucumber_opts.push("--profile", profile) unless profile.empty?
      cucumber_opts.push("--strict") if strict

      @args = (cucumber_opts + feature_files(features)).flatten.compact

    end

    def validate_inputs
      write_output "Validating Inputs\n"
      #if workitem['fields']['port'].nil? or workitem['fields']['port'] == 0
      #  workitem['fields']['port'] = workitem['fields']['use_ssl'] ? 443 : 80
      #end
      #
      #raise "Missing Field Host" if workitem['fields']['host'].nil? or workitem['fields']['host'].empty?
      #raise "Missing Field Job" if workitem['fields']['job'].nil? or workitem['fields']['job'].empty?
    end

    def run

      begin

        Maestro.log.info "Starting Cucumber Tests..."
        validate_inputs
        write_output "Beginning Process For Cucumber Tests\n"

        setup


        failure = Cucumber::Cli::Main.execute(args)
        if failure
          workitem['fields']['__error__'] = "Cucumber tests failed"
          return
        end

        console = ""

        write_output "Cucumber Tests Completed #{failure ? "Uns" : "S"}uccessfully\n"
        
        workitem['fields']['__error__'] = "Cucumber tests failed" if failure
        workitem['fields']['output'] = Iconv.new('US-ASCII//IGNORE', 'UTF-8').iconv(console)

      rescue Exception => e
        Maestro.log.error "#{e}\n #{e.backtrace.join("\n")}"
        workitem['fields']['__error__'] = "Cucumber tests failed " + e.message
        return
      end
      Maestro.log.debug "Finished Processing Cucumber Tests"

      Maestro.log.info "***********************Completed Cucumber***************************"

    end

    private

    def feature_files(features) #:nodoc:
      make_command_line_safe((features || []))
    end

    def make_command_line_safe(list)
      list.map{|string| string.gsub(' ', '\ ')}
    end

  end
end
