# this default test demonstrates a working, sample configuration for a
# json-configured 3-process coffeescript-based daemon named $project.coffee listening on tcp:8080 and which speaks http on that port and also
# communicates to a backend openstack swift service over http
# * for testing other projects, modify this file as appropriate (preferrably in a different git branch named after the project)
# * other tests can override specific things to introduce different behavior and assert accordingly.

source lib/test-helpers.sh

# needed vars: $src, $test, $project
# test identifier, sandbox, config and i/o locations
test_id="$(cd "$src" && git describe --always --dirty)_test_${test}"
sandbox=$prefix-$test_id # mirror of src in which we can make config/source modifications
output=${sandbox}-output # per-testcase sbb probe files go here
log=$sandbox/log
uploads=$sandbox/uploads
config_backend=json
config_sandbox=$sandbox/node_modules/${project}conf.json

# probe / assertion parameters
process_num_up_vega=3
process_num_up_uploader=1
net_listen_addr=tcp:8080
# node cluster doesn't kill children properly yet https://github.com/joyent/node/pull/2908
# so until then, match both master and workers
# 'pgrep -f' compatible regex to capture all our "subject processes"
process_pattern_vega="^node /usr/.*/coffee ($sandbox/)?$project.coffee"
process_pattern_uploader="^node /usr/.*/coffee ($sandbox/)?uploader.coffee"
# command to start the program from inside the sandbox (don't consume stdout/stderr here, see later)
process_launch_vega="coffee $project.coffee"
process_launch_uploader="coffee uploader.coffee"
# assure no false results by program starting and dieing quickly after. allow the environment to "stabilize"
stabilize_sleep=50 # number of ds to max wait for the environment to stabilize after starting up

# callback functions
test_init () {
        mkdir -p $sandbox $output
        rsync -a --delete $src/ $sandbox/
        internal=1 assert_exitcode test -f $sandbox/$project.coffee
        rm -rf $log
        rm -rf uploads
        load_correct_params_from_config
}

# here you can alter the sandbox, modify config settings etc.
test_pre () {
        true
}

everything_is_up () {
    is_listening $net_listen_addr && desired_num_procs "$process_pattern_uploader" $process_num_up_uploader
}

test_start () {
        load_params_from_config
        set_http_probe swift "$http_pattern_swift"
        set_http_probe vega "$http_pattern_vega"
        set_udp_statsd_probe statsdev "$udp_statsd_pattern_statsdev"
        cd $sandbox
        $process_launch_vega > $output/stdout_vega 2> $output/stderr_vega &
        $process_launch_uploader > $output/stdout_uploader 2> $output/stderr_uploader &
        debug_begin "wait until environment came up successfully ( max $stabilize_sleep ds)...."
        wait_until everything_is_up $stabilize_sleep
        debug_end "ret $? after $timer ds"
        upload_file_curl
        cd - >/dev/null
}

# do assertions which are executed while the subject process should be up and running
test_while () {
        assert_num_procs "$process_pattern_vega" $process_num_up_vega
        assert_num_procs "$process_pattern_uploader" $process_num_up_uploader
        assert_listening "$net_listen_addr" 1
}

# returns true only when vega is def. done with its work (i.e. processing 1 upload)
vega_is_done () {
    ticket=$(awk '/completing upload/ {print $NF}' $log/* 2>/dev/null)
    [[ -n $ticket ]] || return 1
    [ -d $sandbox/uploads_done/$ticket ]
}

# returns true only when uploader is def. done.
uploader_is_done () {
    grep -q "uploads_done/$ticket processed" $output/stdout_uploader
}

test_stop () {
        # TODO: in testcases where want the processes to stop or something to break, this causes needlessly long waits
        debug_begin "waiting a bit for vega - if running - to do its job"
        wait_until vega_is_done 50
        debug_end "..ret $? after $timer ds"
        debug_begin "waiting a bit for uploader - if running - to do its job"
        wait_until uploader_is_done 1200
        debug_end "..ret $? after $timer ds"
        kill_graceful "$process_pattern_vega"
        kill_graceful "$process_pattern_uploader"
        assert_num_procs "$process_pattern_vega" 0
        assert_num_procs "$process_pattern_uploader" 0
        remove_http_probe "$http_pattern_swift"
        remove_http_probe "$http_pattern_vega"
        remove_udp_statsd_probe "$udp_statsd_pattern_statsdev"
        assert_listening "$net_listen_addr" 0
}

# perform operations which you don't want to be caught by the http probe and/or which are better suited when the subject process is down
test_post () {
        test_post_ok
        debug_all_errors
}
