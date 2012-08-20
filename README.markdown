# A simple black-box behavior testing framework #

* probably mostly useful for people who implement/deploy daemons (sysadmins and back-end programmers)
* differs from most testing tools by treating the thing you're testing as a black box, and interfacing with it by inputs and probes (see below),
  not by interacting with your API, i.e. this is programming language agnostic.
* written because I couldn't find anything that [suits my needs](http://stackoverflow.com/questions/11136464/black-box-behavior-testing-a-daemon-in-various-configurations)

## workflow ##

* executes the program in a sandbox with a specific configuration, arguments and environment variables.
* captures logs, stderr and stdout streams, http/udp statsd traffic, etc
* programmatically interact with the app while it's running through various interfaces (commands, http, ...)
* use probes to validate behavior

## inputs ##

* manipulate config files and values. reconfigure with missing, empty and various types of (in)correct config values
* mimic webpage interaction (which can cause more http requests in the background) TODO (phantomjs?)
* any command you want (just put it in your test case), for example to invoke http requests programatically

## probes ##

* assert (non-)occurence of patterns in log files, stdout and sterr streams (errors, warnings, etc)
* trace http traffic matching certain conditions, allowing you to inspect all headers (very useful for http response codes)
* check whether $num of processes are (still) running
* check wether processes are listening on specified sockets
* assert exit code of commands, useful for arbitrary commands/scripts
* check checksums of files on the filesystem or blobs in a swift cluster
* assert on statsd traffic
* logstash: grabs events from all other probes and uses logstash to make it easier to search/browse them

note: they get all variables as arguments to functions, no global vars, with the exception of $sandbox and $output
some assert functions of probes allow a wait time expressed in deciseconds.  they will give your environment time
to get in the right state until the timeout expires, retrying every decisecond

## configuration and customisation ##

* clone this project (potentially as submodule within the project you want to test)
* create a new branch named after this project.
* use config.sh for per-developer settings (like `$src`), see config-example.sh.  Run with `-c <config_file>`. You'll probably want to put config.sh in .gitignore.
* `tests/default.sh` is the standard testcase containing all default settings.  Modify as needed and populate the tests directory.
* other testing/external apps are typically self-contained and tell you to just create a directory with all your customisations in your project directory. but that makes it harder to benefit from upstream changes,
  (which with this approach can just be merged in your tree) and doesn't give you nearly as much customisation options (with this approach, you can basically change *anything*). as stuff stabilizes over time,
  we might switch approaches.
* you can of course do commonly applicable changes in your master branch or in topic branches, for which you can do pull requests.

## tests ##

* tests/default.sh gets sourced before every real test, it defines default behavior and demonstrates config options
* test cases may not have whitespace in their names.

## extra features ##

* allows you to pause at each fail to allow for manual inspection
* tries to be simple, not forcing you into paradigms (i.e. more like a library than a framework) and self-documenting
* colors !!!


## dependencies ##

* bash
* sed
* grep
* procps-ng
* [libui-sh](https://github.com/Dieterbe/libui-sh), this is just 2 files that go in /usr/lib

## optional dependencies ##

* python-swiftclient for swift tasks
* ngrep, sudo for http probe
* tcpdump, sudo for udp_statsd probe
* java and http://semicomplete.com/files/logstash/logstash-1.1.1-monolithic.jar this file, in your current dir, for logstash support

## extra notes ##

* you can use assert statements not only when probing the black-boxed app,
  but also to verify that other steps (like environment setup) are being
  done properly. prefix with `internal=1` to suppress win messages and abort the program
  if the internal assertion fails
* assumes that the state of your code directory is your desired starting point.
* for http probe, allow passwordless use of ngrep in /etc/sudoers:
```
%wheel ALL=(ALL) NOPASSWD: /usr/bin/ngrep
%wheel ALL=(ALL) NOPASSWD: /usr/bin/pkill -f ^ngrep*
```
* for udp_statsd probe:
```
%wheel ALL=(ALL) NOPASSWD: /usr/sbin/tcpdump
%wheel ALL=(ALL) NOPASSWD: /usr/bin/pkill -f ^tcpdump*
```


## Examples ##

* see the `vega` branch, which is a real-life case we use to test an upload server named vega.
[see how it compares to master](https://github.com/Vimeo/simple-black-box/compare/master...vega) to get a better understanding.

## Screenshot ##

![Screenshot](http://i.imgur.com/wACnn.png)
