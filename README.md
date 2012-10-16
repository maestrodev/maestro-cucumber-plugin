# maestro-cucumber-plugin
Maestro plugin providing a "task" to run cucumber tests. This
plugin is a Ruby-based deployable that gets delivered as a Zip file. It also contains the capybara and capybara
webkit gems.

<http://cukes.info/>

Manifest:

* src/cucumber_worker.rb
* src/forked_cucumber_worker.rb
* src/maestro_formatter.rb
* images/cucumber.png
* manifest.json
* LICENSE
* README.md (this file)

## The Task
This Cucumber plugin allows a few inputs:

* **feature** The directory or file containing the features.
* **tags** Only execute the features or scenarios with matching tags
* **profile** the cucumber profile to use as defined in cucumber.yml
* **strict** enable/disable strict mode


## License
Apache 2.0 License: <http://www.apache.org/licenses/LICENSE-2.0.html>
