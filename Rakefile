require 'rake/clean'
require 'rspec/core/rake_task'
require 'maestro/plugin/rake_tasks'

$:.push File.expand_path("../src", __FILE__)

CLEAN.include("manifest.json", "*-plugin-*.zip", "vendor", "package", "tmp", ".bundle")

task :default => :all
task :all => [:clean, :bundle, :spec, :package]

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = "--format p --color"
end

Maestro::Plugin::RakeTasks::BundleTask.new

Maestro::Plugin::RakeTasks::PackageTask.new
