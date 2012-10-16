# maestro-jenkins-plugin
Maestro plugin providing a "task" to run cucumber tests. This
plugin is a Ruby-based deployable that gets delivered as a Zip file.

<http://cukes.info/>

Manifest:

* src/cucumber_worker.rb
* src/maestro_formatter.rb
* images/cucumber.png
* manifest.json
* LICENSE
* README.md (this file)

## The Task
This Jenkins plugin requires a few inputs:



* **host** (hostname of the jenkins server)
* **port** (port jenkins is bound to)
* **use_ssl** (to https or not)
* **web_path** (context path of jenkins app)
* **scm_url** (where do we get some code?)
* **steps** (what do we do to the code?)


## License
Apache 2.0 License: <http://www.apache.org/licenses/LICENSE-2.0.html>
