# this default test demonstrates a working, sample configuration for a
# json-configured 3-process coffeescript-based daemon that listens on tcp:8080 and speaks http on that port, and also
# communicates to a backend openstack swift service over http
# * for testing other projects, modify this file as appropriate (preferrably in a different git branch named after the project)
# * other tests can override specific things to introduce different behavior and assert accordingly.

# callback, triggered at least from inside the main app
debug_all_errors () {
        grep -Ri --color=never error $output/stdout $output/stderr $log 2>/dev/null | debug_stream "all errors:"
}

# needed vars: $src, $test, $project
# test identifier, sandbox, config and i/o locations
test_id="$(cd "$src" && git describe --always --dirty)_test_${test}"
sandbox=/tmp/$project-$test_id # mirror of src in which we can make config/source modifications
output=${sandbox}-output # sbb logfiles (stdin, stdout, probe output - as <type>-key - , etc) go here
log=$sandbox/log
uploads=$sandbox/uploads
config_backend=json
config_sandbox=$sandbox/node_modules/${project}conf.json

load_params_from_config () {
        # get the latest values from the config
        ${config_backend}_get_var_string $config_sandbox swift_user; swift_user=$return
        ${config_backend}_get_var_string $config_sandbox swift_pass; swift_pass=$return
        ${config_backend}_get_var_string $config_sandbox swift_host; swift_host=$return
        ${config_backend}_get_var_number $config_sandbox swift_port; swift_port=$return
        ${config_backend}_get_var_string $config_sandbox swift_container; container=$return
        ${config_backend}_get_var_number $config_sandbox statsd_port; statsd_port=$return
        ${config_backend}_get_var_string $config_sandbox statsd_host; statsd_host=$return
}

load_correct_params_from_config () {
        load_params_from_config
        # sometimes we want purposely bad params to test our app, but when we know the params
        # are correct, set the values that SBB uses to assert correctness:
        swift_args="-A http://$swift_host:$swift_port/auth/v1.0 -U $swift_user -K $swift_pass"

        # try to capture the traffic the daemon could potentially send out, but be careful not to capture too much
        # i.e. if no port specified, we capture all traffic towards the host.
        # if host is not specified, maybe the daemon will start sending to another host, but we can't just capture all
        # traffic because than we would have traffic from other stuff.
        # ideally we would capture _all_ traffic (to assert that no other unknown traffic is being sent)
        # and run this test on an isolated machine. (vagrant?). stuff to think about...
        # this assumes that the standard config always has {swift,statsd}_host set, so that the probe
        # can always listen for something, even for the default destination if you later empty the vars and rerun this.
        if [[ -n $swift_host ]]; then
                if [[ $swift_port =~ ^[0-9]+$ ]]; then
                        http_pattern_swift="-d tun0 port $swift_port and host $swift_host"
                else
                        http_pattern_swift="-d tun0 host $swift_host"
                fi
        fi
        if [[ -n $statsd_host ]]; then
                if [[ $statsd_port =~ ^[0-9]+$ ]]; then
                        udp_statsd_pattern_statsdev="-i any dst $statsd_host and port $statsd_port"
                else
                        udp_statsd_pattern_statsdev="-i any dst $statsd_host"
                fi
        fi
}

# probe / assertion parameters
num_procs_up=3
num_procs_down=0
listen_address=tcp:8080
# node cluster doesn't kill children properly yet https://github.com/joyent/node/pull/2908
# so until then, match both master and workers
# 'pgrep -f' compatible regex to capture all our "subject processes"
subject_process="^node /usr/.*/coffee ($sandbox/)?$project.coffee"
# command to start the program from inside the sandbox (don't consume stdout/stderr here, see later)
process_launch="coffee $project.coffee"
# assure no false results by program starting and dieing quickly after. allow the environment to "stabilize"
stabilize_sleep=5 # any sleep-compatible NUMBER[SUFFIX] string

upload_file_curl () {
        # expect statsd get/put increments and data counter increments
        ticket=up-$(date +%s)000
        test_file=$(mktemp --tmpdir $project-$test_id.XXXX)
        debug "creating testfile. $(dd if=/dev/urandom of=$test_file bs=1M count=2 2>&1 | grep -v records)"
        md5sum=$(md5sum $test_file | cut -d' ' -f1)
        debug "uploading testfile. $(curl -s -S -X PUT --data-binary @$test_file "http://localhost:8080/upload?ticket_id=$ticket" 2>&1)"
        debug "comleting upload.   $(curl -s -S "http://localhost:8080/upload_complete?ticket_id=$ticket" 2>&1)"
}

# some snippets to refer to from callback functions
test_post_ok () {
        assert_container_exists "$swift_args" $container
        assert_object_exists "$swift_args" $container $ticket # node app needs about 30s to push the 2MB file
        assert_object_md5sum "$swift_args" $container $ticket $md5sum
        assert_http_response_to swift 'GET /auth/v1.0' 200
        assert_num_http_requests swift 'GET /auth/v1.0' $num_procs_up $num_procs_up # every process will do an auth
        assert_http_response_to swift "^PUT /v1/AUTH_system/$container HTTP" 202
        assert_http_response_to swift "^PUT /v1/AUTH_system/$container/$ticket HTTP" 201
        assert_num_http_requests swift "^PUT" 2 2
        assert_num_udp_statsd_requests statsdev 'error' 0 0
        assert_num_udp_statsd_requests statsdev 'upload.requests.put:1|c' 1 1
        assert_num_udp_statsd_requests statsdev 'upload.rx.*|g' 30 50 # emperically
        assert_num_udp_statsd_requests statsdev 'upload.concurrent_uploads.*:1|g' 1 1
        assert_num_udp_statsd_requests statsdev 'upload.concurrent_uploads.*:0|g' 1 1
        assert_num_udp_statsd_requests statsdev 'upload.requests.get-upload_complete:1|c' 1 1
        assert_no_errors $output/stdout $output/stderr $log $js
}

# $1 error msg
test_post_ok_but_no_statsd () {
        local error=$1
        assert_container_exists "$swift_args" $container
        assert_object_exists "$swift_args" $container $ticket # node app needs about 30s to push the 2MB file
        assert_object_md5sum "$swift_args" $container $ticket $md5sum
        assert_http_response_to swift 'GET /auth/v1.0' 200
        assert_num_http_requests swift 'GET /auth/v1.0' $num_procs_up $num_procs_up # every process will do an auth
        assert_http_response_to swift "^PUT /v1/AUTH_system/$container HTTP" 202
        assert_http_response_to swift "^PUT /v1/AUTH_system/$container/$ticket HTTP" 201
        assert_num_http_requests swift "^PUT" 2 2
        assert_num_udp_statsd_requests statsdev '.*' 0 0
        [ -n "$error" ] && assert_only_error "$error" $output/stdout $output/stderr $log
        [ -z "$error" ] && assert_no_errors $output/stdout $output/stderr $log $js
}

# $1 error msg
test_post_die_during_startup () {
        local error=$1
        assert_num_http_requests swift '.*' 0 0
        assert_only_error "$error" $output/stdout $output/stderr $log
}

# $1 error msg
# $2 match_auth_response
test_post_die_at_auth () {
        local error=$1
        local match_auth_response=$2
        assert_http_response_to swift 'GET /auth/v1.0' "$match_auth_response"
        assert_num_http_requests swift 'GET /auth/v1.0' 1 1
        assert_num_http_requests swift '.*' 1 1
        assert_only_error "$error" $output/stdout $output/stderr $log
}


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

test_start () {
        load_params_from_config
        set_http_probe swift "$http_pattern_swift"
        set_udp_statsd_probe statsdev "$udp_statsd_pattern_statsdev"
        cd $sandbox
        $process_launch > $output/stdout 2> $output/stderr &
        debug "sleep $stabilize_sleep to let the environment 'stabilize'"
        sleep $stabilize_sleep
        upload_file_curl
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
        test_post_ok
        debug_all_errors
}
