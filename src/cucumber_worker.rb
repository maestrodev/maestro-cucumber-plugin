# Copyright 2012© MaestroDev.  All rights reserved.
require 'rubygems'
require 'maestro_agent'
require 'cucumber/cli/main'
require 'maestro_formatter'

module MaestroDev

  # This class is worker used to run Cucumber tests within the agent process.
  class CucumberWorker < Maestro::MaestroWorker

    attr_reader :args

    def setup
      fields = workitem['fields']
      Cucumber::Formatter::WorkerIo.worker=self
      features = fields['features']
      tags = (fields['tags'] || [])
      strict = Boolean(fields['strict'])

      cucumber_opts = %w(--format Cucumber::Formatter::MaestroFormatter)

      tags.each { |tag| cucumber_opts.push("--tags", tag) unless tag.empty? }

      cucumber_opts.push("--strict") if strict

      @args = (cucumber_opts + feature_files(features)).flatten.compact

    end

    def validate_inputs
      write_output "Validating Inputs\n"
    end

    def execute

      begin

        Maestro.log.info "Starting Cucumber Tests..."
        validate_inputs
        write_output "Beginning Process For Cucumber Tests\n"

        setup


        failure = Cucumber::Cli::Main.execute(args)
        puts(failure.inspect)
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
