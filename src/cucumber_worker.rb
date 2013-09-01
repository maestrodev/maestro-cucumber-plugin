# Copyright 2012 MaestroDev.  All rights reserved.
#require 'rubygems'
require 'maestro_plugin'
require 'cucumber/cli/main'
require 'maestro_formatter'
require 'iconv'

module MaestroDev
  module Plugin
    # This class is worker used to run Cucumber tests within the agent process.
    class CucumberWorker < Maestro::MaestroWorker
      # for tests
      attr_reader :args

      # Execute Cucumber Tests
      def execute
        validate_inputs
        setup

        write_output "\nBeginning Process For Cucumber Tests\n"

        begin
          # Cucumber messes with the incoming array, so since we seem to need it for unit testing,
          # we dup it
          failure = Cucumber::Cli::Main.execute(@args.dup)
        rescue Exception => e
          puts e.backtrace.join("\n")
          raise PluginError, "Cucumber tests failed: #{e.message}"
          failure = true
        end

        write_output "Cucumber Tests Completed #{failure ? "Uns" : "S"}uccessfully\n"
        
        raise PluginError, "Cucumber tests failed" if failure
      end

      ###########
      # PRIVATE #
      ###########
      private

      def feature_files(features) #:nodoc:
        make_command_line_safe((features || []))
      end

      def make_command_line_safe(list)
        list.map{|string| string.gsub(' ', '\ ')}
      end
  
      def setup
        Cucumber::Formatter::WorkerIo.worker=self

        cucumber_opts = %w(--format Cucumber::Formatter::MaestroFormatter)
        @tags.each { |tag| cucumber_opts.push("--tags", tag) unless tag.empty? }
        cucumber_opts.push("--strict") if @strict
        @args = (cucumber_opts + feature_files(@features)).flatten.compact
      end

      def validate_inputs
        @features = get_field('features', [])
        @tags = get_field('tags', [])
        @strict = get_boolean_field('strict')
      end

    end
  end
end
