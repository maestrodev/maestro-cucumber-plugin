# Copyright 2012© MaestroDev.  All rights reserved.

require 'maestro_agent/workers/shell/shell_participant'

module MaestroDev
  class ForkedCucumberWorker < Maestro::ShellParticipant

    attr_accessor :shell
    
    def script_prefix
      prefix = <<-SCRIPT
      if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then

        \# First try to load from a user install
        echo "Sourcing rvm From HOME"
        source "$HOME/.rvm/scripts/rvm"

      elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
        echo "Sourcing rvm From /usr/local/rvm"
        \# Then try to load from a root install
        source "/usr/local/rvm/scripts/rvm"

      else

        echo "ERROR: An RVM installation was not found."

      fi
      SCRIPT

      prefix
    end
    
    # because we want to be able to string stuff together with &&
    # can't really test the executable.
    def valid_executable?(command)
      find_command = Maestro::Shell.new
      find_command.create_script("#{script_prefix} #{command} --version")
      find_command.run_script
      unless find_command.exit_code.success?
        workitem['fields']['__error__'] = "ERROR #{command} - No such executable found"
        return false
      end
      true
    end
    
    def update_ruby(version)
      use = Maestro::Shell.new
      use.create_script("#{script_prefix}rvm use #{version}")
      use.run_script

      Maestro.log.debug("RVM use : #{use.to_s} #{!use.exit_code.success? or use.to_s.include?("ERROR:")}")
      if !use.exit_code.success? or use.to_s.include?("ERROR:")
        install = Maestro::Shell.new
        install.create_script("rvm install #{version}")

        install.run_script
        Maestro.log.debug("RVM install : #{install.to_s}")

        return install.exit_code, install.output
      end
      write_output "#{use.to_s}\n#{install.to_s}"
      return use.exit_code, use.to_s
    end

    def is_using_rubygems_version?(version)
      return (workitem['fields']['ruby_version'].include?('jruby') or `#{script_prefix} rvm use #{workitem['fields']['ruby_version']} gem --version`.include?(version))
    end
    
    def run_update_rubygems(ruby_version, rubygems_version)
      script =  "#{script_prefix} rvm use #{ruby_version} ; rvm rubygems #{rubygems_version}"
      shell = Maestro::Shell.new      
      shell.create_script(script)
      shell.run_script

      return shell.exit_code, shell.to_s
    end

    def update_rubygems(ruby_version, version)

      return true if is_using_rubygems_version?(version)
      exit_code, result = run_update_rubygems(ruby_version, version)

      unless exit_code.success?
        workitem['fields']['__error__'] = result
        return false
      end
      workitem['fields']['output'] += result
      return true
    end

    def valid_workitem?
      fields = workitem['fields']

      missing = ''
      
      missing += '[cucumber not installed] ' if !valid_executable?('cucumber')
      missing += '[missing path] ' if fields['path'].nil? or !File.exists? fields['path']
      @use_rvm = Boolean(fields['use_rvm'])
      if @use_rvm
        missing += '[rvm not installed] ' if !valid_executable?('rvm')
        missing += '[missing ruby_version] ' if fields['ruby_version'].nil? or fields['ruby_version'].empty?
        missing += '[missing rubygems_version]' if fields['rubygems_version'].nil? or fields['rubygems_version'].empty?
      end
      
      @use_bundler = Boolean(fields['use_bundler'])
      if @use_bundler
        missing += '[bundler not installed] ' if !valid_executable?('bundle')
      end
      
      @gems = nil
      @gems = process_gems_field unless fields['gems'].nil? or fields['gems'].empty?

      @features = (fields['features'] || "")
      @tags = (fields['tags'] || [])
      @profile = (fields['profile'] || "")
      @strict = Boolean(fields['strict'])


      if missing.empty?
        return true
      else
        workitem['fields']['__error__'] = "ERROR missing require field(s) - #{missing}"
        return false
      end
    end
    
    def run
      @shell.run_script_with_delegate(self, :write_output)
    end
    
    def validate_output
      output = @shell.to_s
      workitem['fields']['__error__'] = output unless @shell.exit_code.success?
      workitem['fields']['output'] += output
    end
    
    def process_gems_field
      gems = workitem['fields']['gems']
      if is_json(gems)
        gems = JSON.parse(gems) if gems.is_a? String
      end
      
      if gems.class == Array
        return gems
      end
      Maestro.log.warn "Invalid Format For gems Field #{gems}"
      return nil
    end

    def create_command      
      fields = workitem["fields"]
      path = fields["path"]
      if @use_rvm
        Maestro
        rvm = "#{script_prefix} rvm use #{fields['ruby_version']} ; "
        rvm += "rvm rubygems #{fields['rubygems_version']} ; " unless is_using_rubygems_version?(workitem['fields']['rubygems_version'])
      end
      
      if @use_bundler
        bundle = "#{Maestro::Shell.environment_export_command} BUNDLE_GEMFILE=#{path}/Gemfile && #{Maestro::Shell.environment_export_command} BUNDLE_WITHOUT="" && bundle update && bundle exec"
      end
      
      if @gems
        Maestro.log.debug "Install Gems #{@gems.join(', ')}"
        gems_script = ''
        @gems.each do |gem_name|
          gems_script += "gem install #{gem_name} --no-ri --no-rdoc ; "
        end
      end
      

      cucumber_opts = []

      @tags.each do |tag|
        cucumber_opts.push("--tags", tag) unless tag.empty?
      end

      cucumber_opts.push("--profile", @profile) unless @profile.empty?
      cucumber_opts.push("--strict") if @strict

      cucumber_opts = (cucumber_opts + feature_files(@features)).flatten.compact
      cucumber_args = ""

      cucumber_opts.each do |opt|
        cucumber_args << opt + " "
      end
      cucumber_args = cucumber_args.rstrip

      Maestro.log.debug "Creating Script"
      shell_command = <<-Cucumber
      #{Maestro::Shell.environment_export_command} RUBYOPT=
      #{(workitem['fields']['environment'].nil? or workitem['fields']['environment'].empty?) ? "": "#{Maestro::Shell.environment_export_command} #{workitem['fields']['environment']}" }
      #{@use_rvm ? rvm : ''} type rvm | head -1 && cd #{path} &&  #{@gems ? gems_script : ''} #{@use_bundler ? bundle : ''} cucumber#{(cucumber_args.empty? ? "" : " " + cucumber_args)}
      Cucumber


      workitem['fields']['command'] = shell_command

      write_output("\nRunning #{shell_command}")
      Maestro.log.debug("Running #{shell_command}")
      shell_command
    end
    
    def execute
      Maestro.log.info "Starting Cucumber participant..."
      Maestro.log.info "Executing Cucumber."
      begin
        workitem['fields']['__error__'] = ''
        workitem['fields']['output'] = ''
        Maestro.log.debug "Validating Inputs"
        
        raise if !valid_workitem?
        
        if @use_rvm
          Maestro.log.debug "Using Ruby Version Manager"
          write_output "Using Ruby Version Manager"
          Maestro.log.debug "Using Ruby Version #{workitem['fields']['ruby_version']}"
          write_output "\nUsing Ruby Version #{workitem['fields']['ruby_version']}"
          
          exit_code, result = update_ruby(workitem['fields']['ruby_version'])
          raise result unless exit_code.success?
          
          Maestro.log.debug "Using RubyGems Version #{workitem['fields']['rubygems_version']}"
          write_output "\nUsing RubyGems Version #{workitem['fields']['rubygems_version']}"
          raise unless update_rubygems(workitem['fields']['ruby_version'], workitem['fields']['rubygems_version'])
                    
        end
        
        fields = workitem["fields"]
        path = fields["path"]
      
        #Dir.chdir(path)
        @shell = Maestro::Shell.new("tmp/cucumber.sh")
        
        command = create_command
        if command.nil?
          workitem['fields']['__error__'] = "Error executing cucumber failed to build script"
          return
        end
                
        @shell.create_script(command)
              
        run
              
        workitem['fields']['output'] = validate_output
        
      rescue Exception => e
        workitem['fields']['__error__'] = "Cucumber Task Failed With Error #{e}" if workitem['fields']['__error__'].empty?
        Maestro.log.error workitem['fields']['__error__']
      end
      Maestro.log.info "Rake output: #{workitem['fields']['output']}"
      Maestro.log.info "***********************Completed Cucumber***************************"
    end

    def feature_files(features) #:nodoc:
      make_command_line_safe((features || []))
    end

    def make_command_line_safe(list)
      list.map{|string| string.gsub(' ', '\ ')}
    end

  end


end
