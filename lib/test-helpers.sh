# useful functions which testcases can refer to

debug_all_errors () {
        grep -Ri --color=never error $output/stdout_* $output/stderr_* $log 2>/dev/null | debug_stream "all errors:"
}

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
        http_pattern_vega="-d lo host localhost and port 8080"
}

upload_file_curl () {
        # expect statsd get/put increments and data counter increments
        ticket=up-$(date +%s)000
        test_file=$(mktemp --tmpdir $project-$test_id.XXXX)
        debug_begin "creating testfile $test_file. "
        debug_end "$(dd if=/dev/urandom of=$test_file bs=1M count=2 2>&1 | grep -v records)"
        debug_begin 'checksumming testfile. '
        md5sum=$(md5sum $test_file | cut -d' ' -f1)
        debug_end $md5sum
        debug_begin 'uploading testfile to http://localhost:8080. '
        debug_end "$(curl -s -S -X PUT --data-binary @$test_file "http://localhost:8080/upload?ticket_id=$ticket" 2>&1)"
        debug_begin 'completing upload. '
        debug_end "$(curl -s -S "http://localhost:8080/upload_complete?ticket_id=$ticket" 2>&1)"
}

# some snippets to refer to from callback functions
test_post_ok () {
        assert_container_exists "$swift_args" $container
        assert_object_exists "$swift_args" $container $ticket # node app needs about 30s to push the 2MB file
        assert_object_md5sum "$swift_args" $container $ticket $md5sum
        assert_http_response_to swift 'GET /auth/v1.0' 200
        assert_num_http_requests swift 'GET /auth/v1.0' 1 1
        assert_http_response_to swift "^PUT /v1/AUTH_system/$container HTTP" 202
        assert_http_response_to swift "^PUT /v1/AUTH_system/$container/$ticket HTTP" 201
        assert_num_http_requests swift "^PUT" 2 2
        assert_num_udp_statsd_requests statsdev 'error' 0 0
        assert_num_udp_statsd_requests statsdev 'upload.requests.put:1|c' 1 1
        assert_num_udp_statsd_requests statsdev 'upload.rx.*|g' 30 50 # emperically
        assert_num_udp_statsd_requests statsdev 'upload.concurrent_uploads.*:1|g' 1 1
        assert_num_udp_statsd_requests statsdev 'upload.concurrent_uploads.*:0|g' 1 1
        assert_num_udp_statsd_requests statsdev 'upload.requests.get-upload_complete:1|c' 1 1
        assert_no_errors $output/stdout_* $output/stderr_* $log $js
}

# $1 error msg
test_post_ok_but_no_statsd () {
        local error=$1
        assert_container_exists "$swift_args" $container
        assert_object_exists "$swift_args" $container $ticket # node app needs about 30s to push the 2MB file
        assert_object_md5sum "$swift_args" $container $ticket $md5sum
        assert_http_response_to swift 'GET /auth/v1.0' 200
        assert_num_http_requests swift 'GET /auth/v1.0' 1 1
        assert_http_response_to swift "^PUT /v1/AUTH_system/$container HTTP" 202
        assert_http_response_to swift "^PUT /v1/AUTH_system/$container/$ticket HTTP" 201
        assert_num_http_requests swift "^PUT" 2 2
        assert_num_udp_statsd_requests statsdev '.*' 0 0
        [ -n "$error" ] && assert_only_error "$error" $output/stdout_* $output/stderr_* $log
        [ -z "$error" ] && assert_no_errors $output/stdout_* $output/stderr_* $log $js
}

# $1 error msg
test_post_vega_dies_during_startup () {
        local error=$1
        assert_num_http_requests swift '.*' 3 3
        assert_only_error "$error" $output/stdout_* $output/stderr_* $log
}

# $1 error msg
test_post_uploader_dies_during_startup () {
        local error=$1
        assert_num_http_requests swift '.*' 0 0
        assert_only_error "$error" $output/stdout_* $output/stderr_* $log
}

# $1 error msg
test_post_vega_and_uploader_die_during_startup () {
        local error=$1
        assert_num_http_requests swift '.*' 0 0
        assert_only_error "$error" $output/stdout_* $output/stderr_* $log
}

# $1 error msg
# $2 match_auth_response
test_post_uploader_dies_at_auth () {
        local error=$1
        local match_auth_response=$2
        assert_http_response_to swift 'GET /auth/v1.0' "$match_auth_response"
        assert_num_http_requests swift 'GET /auth/v1.0' 1 1
        assert_num_http_requests swift '.*' 1 1
        assert_only_error "$error" $output/stdout_* $output/stderr_* $log
}

# $1 error msg
test_post_ok_but_no_swift () {
        local error=$1
        assert_num_http_requests swift '.*' 0 0
        assert_only_error "$error" $output/stdout_* $output/stderr_* $log
}
