= A simple black-box behavior testing framework =

* probably mostly useful for people who implement/deploy daemons (sysadmins and back-end programmers)
* differs from most testing tools by treating the thing you're testing as a black box, and interfacing with it by inputs and probes (see below),
  not by interacting with your API, i.e. this is programming language agnostic.
* written because I couldn't find anything that suits my needs:
  http://stackoverflow.com/questions/11136464/black-box-behavior-testing-a-daemon-in-various-configurations

== workflow ==

* executes the program with different arguments and environment variables, capturing logs, stderr and stdout streams
* use input plugins that set up the environment before starting the app, or interact with it while it's running.
* use probes to validate behavior

== inputs ==

* manipulate config files and values. reconfigure with missing, empty and various types of (in)correct config values
* mimic webpage interaction (which can cause more http requests in the background) TODO (phantomjs?)
* any command you want (just put it in your test case), for example to invoke http requests programatically

== probes ==

* assert (non-)occurence of patterns in log files, stdout and sterr streams (errors, warnings, etc)
* trace http traffic matching certain conditions, allowing you to inspect all headers (very useful for http response codes)
* check whether $num of processes are (still) running
* check wether processes are listening on specified sockets
* assert exit code of commands, useful for arbitrary commands/scripts
* check checksums of files on the filesystem or blobs in a swift cluster

note: they get all variables as arguments to functions, no global vars, with the exception of $sandbox

== config ==

* use -c <config_file> for per-developer (workspace) settings, tests/default.sh sets up all the rest dynamically based on the currently running test
  see config-example.sh.

== tests ==

* tests/default.sh get sourced before every real test, it defines default behavior and demonstrates config options
* generic_ tests are tests which you can reuse for multiple occasions,
  for example a test that checks the effect of making a given config parameter
  value unset, each of these will document which parameters they accept
* specifically, the default generic_var* tests allow you to assert (absence of) errors and number of processes running
* by default, runs all tests that don't start with generic_ found in the test folder.
  your tests can just set the needed vars and source a generic test
* test cases may not have whitespace in their names.

== extra features ==

* allows you to pause at each fail to allow for manual inspection
* tries to be simple, not forcing you into paradigms (i.e. more like a library than a framework) and self-documenting
* colors !!!

== customisation ==

clone this project (potentially as submodule within the project you want to test), create a new branch, and populate the tests directory.
to customize the main app, libraries, inputs or probes, this app won't do stuff like looking into "default" and "user" dirs, preferring files with the same name in the latter dir over the former, and expecting you to only modify certain files.
stuff like that is often a maintenance pain.  instead, just modify the project itself wherever seems the best place to you.  (in a branch named after and tailored towards testing the specific app).
If appropriate, try to get your changes merged upstream.
Consider putting config.sh in .gitignore to ignore some per-developer specific settings like $src

== dependencies ==

* bash
* sed
* grep
* procps-ng
* libui-sh (https://github.com/Dieterbe/libui-sh -- this is just 2 files that go in /usr/lib)

== optional dependencies ==

* python-swiftclient for swift tasks
* ngrep, sudo for http probe

== extra notes ==

* you can use assert statements not only when probing the black-boxed app,
  but also to verify that other steps (like environment setup) are being
  done properly.
* assumes that the state of your code directory is your desired starting point.
* for http probe, allow passwordless use of ngrep in /etc/sudoers:
```
%wheel ALL=(ALL) NOPASSWD: /usr/bin/ngrep
```
