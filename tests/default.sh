# this default test demonstrates a working, sample configuration for a
# json-configured 3-process coffeescript-based daemon that listens on tcp:8080 and speaks http on that port.
# * for testing other projects, modify this file as appropriate (preferrably in a different git branch named after the project)
# * other tests can override specific things to introduce different behavior and assert accordingly.

# callback, triggered at least from inside the main app
debug_all_errors () {
        grep -Ri --color=never error $stdout $stderr $log 2>/dev/null | debug_stream "all errors:"
}

# needed vars: $src, $test, $project
# test identifier, sandbox, config and i/o locations
test_id="$(cd "$src" && git describe --always --dirty)_test_${test}"
sandbox=/tmp/$project-$test_id # mirror of src which we can pollute with logfiles and modifications
# filenames for log directory, stdout, stderr, http, ...
# leave default unless it would conflict with existing files
stdout=$sandbox/stdout
stderr=$sandbox/stderr
log=$sandbox/log
http=$sandbox/http # location of sniffed http traffic. only used when you set up the http probe
uploads=$sandbox/uploads
config_backend=json
config_sandbox=$sandbox/node_modules/${project}conf.json
config_src=$src/node_modules/${project}conf.json

# swift
${config_backend}_get_var_string $config_src swift_user; swift_user=$return
${config_backend}_get_var_string $config_src swift_pass; swift_pass=$return
${config_backend}_get_var_string $config_src swift_host; swift_host=$return
${config_backend}_get_var_number $config_src swift_port; swift_port=$return
swift_args="-A http://$swift_host:$swift_port/auth/v1.0 -U $swift_user -K $swift_pass"

# probe / assertion parameters
num_procs_up=3
num_procs_down=0
listen_address=tcp:8080
# node cluster doesn't kill children properly yet https://github.com/joyent/node/pull/2908
# so until then, match both master and workers
# 'pgrep -f' compatible regex to capture all our "subject processes"
subject_process="^node /usr/.*/coffee ($sandbox/)?$project.coffee"
http_pattern="-d tun0 port $swift_port and host $swift_host"
# command to start the program from inside the sandbox (don't consume stdout/stderr here, see later)
process_launch="coffee $project.coffee"
# assure no false results by program starting and dieing quickly after. allow the environment to "stabilize"
stabilize_sleep=5 # any sleep-compatible NUMBER[SUFFIX] string

test_init () {
        mkdir -p $sandbox
        rsync -au --delete $src/ $sandbox/
        internal=1 assert_exitcode test -f $sandbox/$project.coffee
        rm -rf $log
        rm -rf uploads
}

# here you can alter the sandbox, modify config settings etc.
test_pre () {
        true
}

test_start () {
        set_http_probe "$http_pattern"
        cd $sandbox
        $process_launch > $stdout 2> $stderr &
        debug "sleep $stabilize_sleep to let the environment 'stabilize'"
        sleep $stabilize_sleep
        cd - >/dev/null
}

# do assertions which are executed while the subject process should be up and running
test_while () {
        assert_num_procs "$subject_process" $num_procs_up
        assert_listening "$listen_address" 1
}

test_stop () {
        kill_graceful "$subject_process"
        assert_num_procs "$subject_process" $num_procs_down
        remove_http_probe "$http_pattern"
        assert_listening "$listen_address" 0
}

# perform operations which you don't want to be catched by the http probe and/or which are better suited when the subject process is down
test_post () {
        assert_http_response_to 'GET /auth/v1.0' 200
        assert_num_http_requests 'GET /auth/v1.0' $num_procs_up $num_procs_up # every process will do an auth
        assert_no_errors $stdout $stderr $log
        debug_all_errors
}
