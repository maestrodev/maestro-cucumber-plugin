# maestro-cucumber-plugin
Maestro plugin providing "tasks" to run cucumber tests. This plugin is a Ruby-based deployable that gets delivered as a
Zip file. It also contains the capybara gem to be used by the in-process cucumber task.

This plugin provides two tasks:

  * **In-process cucumber** runs cucumber within the agent process.
  * **Forked cucmber** runs cucumber as a forked process.

<http://cukes.info/>

Manifest:

* src/cucumber_worker.rb
* src/forked_cucumber_worker.rb
* src/maestro_formatter.rb
* images/cucumber.png
* manifest.json
* LICENSE
* README.md (this file)

## The Tasks
The in-process cucumber task allows the following inputs:

* **feature** The directory or file containing the features.
* **tags** Only execute the features or scenarios with matching tags
* **strict** enable/disable strict mode

The forked cucumber task allows the following inputs:

* **feature** The directory or file containing the features.
* **tags** Only execute the features or scenarios with matching tags
* **profile** the cucumber profile to use, as defined in cucumber.yml
* **strict** enable/disable strict mode
* **path** the path from which to run cucumber.
* **use_rvm** tell the agent to use rvm.
* **ruby_version** the version of ruby to use.
* **rubygems_version** the version of rubygems to use.
* **use_bundler** tell the agent to use bundler (bundle exec).
* **environment** environment variables


## License
Apache 2.0 License: <http://www.apache.org/licenses/LICENSE-2.0.html>
