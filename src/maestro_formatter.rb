# Copyright 2012 MaestroDev.  All rights reserved.
require 'cucumber/formatter/progress'

module Cucumber
  module Formatter

    # This class is to send test output to lucee using the worker's write_output method.
    # Messages are buffered until the flush method is invoked to reduce chatter.
    class WorkerIo

      @@worker = nil

      def WorkerIo.worker=(worker)
        @@worker=worker
      end

      def initialize
        @output_buffer = []
      end

      def puts(s="")
        s = "" if s.nil?
        print s + "\n"
      end

      def print(s="")
        s = "" if s.nil?
        @output_buffer << s
      end

      def flush()
        output = ""
        @output_buffer.each do |part|
          output += part
        end

        output = Iconv.new('US-ASCII//IGNORE', 'UTF-8').iconv(output)

        @@worker.write_output output
        @output_buffer = []
      end

    end

    # This class formats cucumber output using the Progress formatter and sends it to lucee.
    class MaestroFormatter < Cucumber::Formatter::Progress

      def initialize(step_mother, path_or_io, options)
        @step_mother, @options = step_mother, options
        @io = WorkerIo.new
      end

    end
  end
end
