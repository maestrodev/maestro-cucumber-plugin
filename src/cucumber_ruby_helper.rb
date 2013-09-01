# Copyright 2011 (c) MaestroDev.  All rights reserved.
require 'shell'

# Common methods for ruby/rvm management
module Maestro
  module Plugin
    module CucumberRubyHelper

      def script_prefix
        return '' unless @use_rvm

        # Note double quotes in error... that is so it doesn't trigger unit-test errors
        prefix = <<-SCRIPT
if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
  \# First try to load from a user install
  source "$HOME/.rvm/scripts/rvm"
elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
  \# Then try to load from a root install
  source "/usr/local/rvm/scripts/rvm"
else
  printf "ER""ROR: An RVM installation was not found.\n"
fi
#{@environment.empty? ? "": "#{Maestro::Util::Shell::ENV_EXPORT_COMMAND} #{@environment}" } 
SCRIPT
      end
    
      # Update ruby and rubygems if needed
      def update_ruby_rubygems
        return unless @use_rvm

        write_output "\nUsing RVM w/Ruby Version #{@ruby_version}"
      
        exit_code = update_ruby(@ruby_version)
        if exit_code.success?
          if !@rubygems_version.empty?
            write_output "\nUsing RubyGems Version #{@rubygems_version}\n"
            update_rubygems(@ruby_version, @rubygems_version)
          end
        end
      end

      def update_ruby(version)
        write_output("\nEnsuring ruby version #{version}\n", :buffer => true)
        use = Maestro::Util::Shell.new
        use.create_script("#{script_prefix}#{@rvm_executable} use #{version}")
        use.run_script_with_delegate(self, :on_output)

        Maestro.log.debug("RVM use: #{use.to_s} #{!use.exit_code.success? or use.to_s.include?("ERROR:")}")
        if !use.exit_code.success? or use.to_s.include?("ERROR:")
          write_output("\nInstalling ruby version #{version}\n", :buffer => true)
          install = Maestro::Util::Shell.new
          install.create_script("#{@rvm_executable} install #{version}")

          install.run_script_with_delegate(self, :on_output)

          if install.exit_code.success?
            @installed_ruby_verion = version
          end

          return install.exit_code
        else
          @installed_ruby_version = version
        end

        return use.exit_code
      end

      def is_using_rubygems_version?(version)
        rg = Maestro::Util::Shell.run_command("#{script_prefix} #{@rvm_executable} #{@ruby_version} do gem --version")

        return rg[0].success? && rg[1].include?(version)
      end
    
      def run_update_rubygems(ruby_version, rubygems_version)
        write_output("Installing rubygems version #{rubygems_version}", :buffer => true)
        script =  "#{script_prefix} #{@rvm_executable} #{ruby_version} do rvm rubygems #{rubygems_version}"
        shell = Maestro::Util::Shell.new      
        shell.create_script(script)
        shell.run_script_with_delegate(self, :on_output)
  
        return shell.exit_code
      end
    
      def update_rubygems(ruby_version, version)
        if !is_using_rubygems_version?(version)
          exit_code = run_update_rubygems(ruby_version, version)
          
          if exit_code.success?
            @installed_rubygems_version = version
          end
        else
          @installed_rubygems_version = version
        end
      end
    end
  end
end

