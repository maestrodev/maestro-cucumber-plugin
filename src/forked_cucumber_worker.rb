# Copyright 2012 MaestroDev.  All rights reserved.
require 'maestro_plugin'
require 'maestro_shell'
require 'cucumber_ruby_helper'

module MaestroDev
  module Plugin

    class ForkedCucumberWorker < Maestro::MaestroWorker
      include Maestro::Plugin::CucumberRubyHelper

      def execute
        validate_parameters

        shell = Maestro::Util::Shell.new
        command = create_command
        shell.create_script(command)
              
        write_output("\nRunning command:\n----------\n#{command.chomp}\n----------\n")
        exit_code = shell.run_script_with_delegate(self, :on_output)
        output = shell.output
              
        raise PluginError, "Error running cucumber" unless exit_code.success?
      end

      def on_output(text)
        write_output(text, :buffer => true)
      end
  
      ###########
      # PRIVATE #
      ###########
      private

      # because we want to be able to string stuff together with &&
      # can't really test the executable.
      def valid_executable?(executable)
        Maestro::Util::Shell.run_command("#{executable} --version")[0].success?
      end
    
      def validate_parameters
        errors = []
        @ruby_version = ''
        @rubygems_version = ''
        @cucumber_executable = get_field('cucumber_executable', 'cucumber')
        @use_rvm = get_boolean_field('use_rvm')
        @rvm_executable = get_field('rvm_executable', 'rvm')  
        @ruby_version = get_field('ruby_version', '')
        @rubygems_version = get_field('rubygems_version', '')
        # Seems that though this was forked from rake, it uses 'bundler' instead of bundle.
        # So lets support both
        @use_bundle = get_boolean_field('use_bundle') || get_field('use_bundler')
        @bundle_executable = get_field('bundle_executable', 'bundle')
        @environment = get_field('environment', '')
        @env = @environment.empty? ? "" : "#{Maestro::Util::Shell::ENV_EXPORT_COMMAND} #{@environment.gsub(/(&&|[;&])\s*$/, '')} && "
        @gems = get_field('gems', [])  
        @path = get_field('path') || get_field('scm_path')

        errors << 'rvm not installed' if @use_rvm && !valid_executable?(@rvm_executable)
        errors << 'missing ruby_version' if @use_rvm && @ruby_version.empty?
        errors << 'bundle not installed' if @use_bundle && !valid_executable?("#{rvm_prefix} #{@bundle_executable}")
        errors << 'cucumber not installed' unless valid_executable?("#{rvm_prefix} #{@cucumber_executable}")
        errors << 'missing field path' if @path.nil?
        errors << "not found path '#{@path}'" if !@path.nil? && !File.exist?(@path)

        update_ruby_rubygems

        if @use_rvm
          errors << "Requested Ruby version #{@ruby_version} not available" unless @installed_ruby_version && @ruby_version == @installed_ruby_version
          errors << "Requested RubyGems version #{@rubygems_version} not available" unless @rubygems_version.empty? || (@installed_rubygems_version && @rubygems_version == @installed_rubygems_version)
        end

        process_gems_field

        @features = get_field('features', "")
        @tags = get_field('tags', [])
        @profile = get_field('profile', "")
        @strict = get_boolean_field('strict')

        raise ConfigError, "Configuration errors: #{errors.join(', ')}" unless errors.empty?
      end

      def process_gems_field
        if !@gems.empty? && is_json(@gems)
          @gems = JSON.parse(@gems) if @gems.is_a? String
        end
      
        if !@gems.is_a?(Array)
          Maestro.log.warn "Invalid Format For gems Field #{@gems} - ignoring [#{@gems.class.name}] #{@gems}"
          @gems = nil
        end
      end

      def rvm_prefix
        "#{Maestro::Util::Shell::ENV_EXPORT_COMMAND} RUBYOPT=\n#{@env}#{@use_rvm ? "#{script_prefix} rvm use #{@ruby_version} && " : ''}"
      end

      def create_command      
        if @use_bundle
          # ensure we are not overriding a BUNDLE_WITHOUT variable set in the fields
          if @environment.include?("BUNDLE_WITHOUT=")
            bundle_without = ""
          else
            # ENV Var is just one way to get bundle to do without... if you 'bundle config without....' it is stickier and is in
            # the .bundle dir.
            # rake seems to use this more official way of setting... and even though it does clear the .bundle dir on a clean
            # that doesn't help if rake isn't installed!
            bundle_without = "&& #{@bundle_executable} config --delete without && #{Maestro::Util::Shell::ENV_EXPORT_COMMAND} BUNDLE_WITHOUT='' "
          end
          bundle = "#{Maestro::Util::Shell::ENV_EXPORT_COMMAND} BUNDLE_GEMFILE=#{@path}/Gemfile #{bundle_without}&& #{@bundle_executable} install && #{@bundle_executable} exec"
        end
      
        if @gems
          Maestro.log.debug "Install Gems #{@gems.join(', ')}"
          gems_script = ''
          @gems.each do |gem_name|
            gems_script += "gem install #{gem_name} --no-ri --no-rdoc && "
          end
        end
      
        cucumber_opts = []

        @tags.each do |tag|
          cucumber_opts.push("--tags", tag) unless tag.empty?
        end

        cucumber_opts.push("--profile", @profile) unless @profile.empty?
        cucumber_opts.push("--strict") if @strict

        cucumber_opts.push(feature_files(@features))
        cucumber_opts = cucumber_opts.flatten.compact
        cucumber_args = cucumber_opts.join(' ')

        shell_command = "#{rvm_prefix} cd #{@path} && " +
          "#{@gems ? gems_script : ''} #{@use_bundle ? bundle : ''} " +
          "#{@cucumber_executable} #{cucumber_args}".strip

        set_field('command', shell_command)

        Maestro.log.debug("Running #{shell_command}")
        shell_command
      end
    
      def feature_files(features) #:nodoc:
        features ? make_command_line_safe(features) : ""
      end

      def make_command_line_safe(features)
        features.gsub(' ', '\ ')
      end

    end
  end

end
