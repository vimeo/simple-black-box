# this default test demonstrates a working, sample configuration for a
# json-configured 3-process coffeescript-based daemon that listens on tcp:8080 and speaks http on that port, and also
# communicates to a backend openstack swift service over http
# * for testing other projects, modify this file as appropriate (preferrably in a different git branch named after the project)
# * other tests can override specific things to introduce different behavior and assert accordingly.

source lib/test-helpers.sh

# needed vars: $src, $test, $project
# test identifier, sandbox, config and i/o locations
test_id="$(cd "$src" && git describe --always --dirty)_test_${test}"
sandbox=$prefix-$test_id # mirror of src in which we can make config/source modifications
output=${sandbox}-output # per-testcase sbb probe files go here
log= # optional. if your app uses a logfile or directory, point to it here
config_backend=json
config_sandbox=$sandbox/node_modules/${project}conf.json

# probe / assertion parameters
num_procs_up=3
num_procs_down=0
listen_address=tcp:8080
# node cluster doesn't kill children properly yet https://github.com/joyent/node/pull/2908
# so until then, match both master and workers
# 'pgrep -f' compatible regex to capture all our "subject processes"
subject_process="^node /usr/.*/coffee ($sandbox/)?$project.coffee"
http_pattern_swift="port 8080 and host localhost"
udp_statsd_pattern_statsdev="port 8125 and host localhost"
# command to start the program from inside the sandbox (don't consume stdout/stderr here, see later)
process_launch="coffee $project.coffee"
# assure no false results by program starting and dieing quickly after. allow the environment to "stabilize"
stabilize_sleep=5 # any sleep-compatible NUMBER[SUFFIX] string

test_init () {
        mkdir -p $sandbox $output
        rsync -a --delete $src/ $sandbox/
        internal=1 assert_exitcode test -f $sandbox/$project.coffee
}

# here you can alter the sandbox, modify config settings etc.
test_pre () {
        true
}

test_start () {
        set_http_probe swift "$http_pattern_swift"
        set_udp_statsd_probe statsdev "$udp_statsd_pattern_statsdev"
        cd $sandbox
        $process_launch > $output/stdout_vega 2> $output/stderr_vega &
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
        remove_http_probe "$http_pattern_swift"
        remove_udp_statsd_probe "$udp_statsd_pattern_statsdev"
        assert_listening "$listen_address" 0
}

# perform operations which you don't want to be caught by the http probe and/or which are better suited when the subject process is down
test_post () {
        assert_no_errors $output/stdout_* $output/stderr_* $log
        debug_all_errors
}
