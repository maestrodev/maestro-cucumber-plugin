require 'rake/clean'
require 'rspec/core/rake_task'
require 'zippy'
require 'git'
require 'nokogiri'
require 'json'

$:.push File.expand_path("../src", __FILE__)

CLEAN.include("manifest.json", "*-plugin-*.zip", "vendor", "package", "tmp", ".bundle")

task :default => :all
task :all => [:clean, :bundle, :spec, :package]

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  t.rspec_opts = "--format p --color"
  # Put spec opts in a file named .rspec in root
end

desc "Get dependencies with Bundler"
task :bundle do
  sh %{bundle package} do |ok, res|
    raise "Error bundling" if ! ok
  end
end

def add_file( zippyfile, dst_dir, f )
  puts "Writing #{f} at #{dst_dir}"
  zippyfile["#{dst_dir}/#{f}"] = File.open(f)
end

def add_dir( zippyfile, dst_dir, d )
  glob = "#{d}/**/*"
  FileList.new( glob ).each { |f|
    if (File.file?(f))
      add_file zippyfile, dst_dir, f
    end
  }
end

desc "Package plugin zip"
task :package do
  f = File.open("pom.xml")
  doc = Nokogiri::XML(f.read)
  f.close
  artifactId = doc.at_xpath('/xmlns:project/xmlns:artifactId').text
  version = doc.at_xpath('/xmlns:project/xmlns:version').text
  zip_file = "#{artifactId}-#{version}.zip"

  if File.exists?(".git")
    git = Git.open(".")
    # check if there are modified files
    if git.status.select {|s| s.type == "M"}.empty?
      commit = git.log.first.sha[0..5]
      version = "#{version}-#{commit}"
    else
      puts "WARNING: There are modified files, not using commit hash in version"
    end
  end

  # update manifest
  manifest = JSON.parse(IO.read("manifest.template.json"))
  manifest.each { |m| m['version'] = version }
  File.open("manifest.json",'w'){ |f| f.write(JSON.pretty_generate(manifest)) }

  Zippy.create zip_file do |z|
    add_dir z, '.', 'src'
    add_dir z, '.', 'vendor'
    add_dir z, '.', 'images'
    add_file z, '.', 'manifest.json'
    add_file z, '.', 'README.md'
    add_file z, '.', 'LICENSE'
  end
end
