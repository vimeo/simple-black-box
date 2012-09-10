container=test_$RANDOM
test_pre () {
        debug "creating container $container: $(swift $swift_args post $container 2>&1)"
        internal=1 assert_container_exists "$swift_args" $container
        ${config_backend}_change_var $config_sandbox swift_container "\"$container\""
}

test_post () {
        echo "Error: failed to check for existence of container $container" >> $output/stderr_vega
        assert_container_exists "$swift_args" $container
        debug "deleting container $container: $(swift $swift_args delete $container 2>&1)"
        internal=1 assert_container_exists "$swift_args" $container 0
        assert_http_response_to swift "^PUT" 202 1
        assert_num_http_requests swift "^PUT" 1 1
        assert_http_response_to swift 'GET /auth/v1.0' 200
        assert_num_http_requests swift 'GET /auth/v1.0' 1 1
        assert_num_udp_statsd_requests statsdev 'upload.requests.put:1|c' 0 0
        assert_no_errors $output/stdout_* $output/stderr_* $log
       # assert_pattern "container.*$container.*already existing" 1 $output/stdout_* $output/stderr_* $log
        assert_pattern "created.*$container" 0 $output/stdout_* $output/stderr_* $log
        assert_object_md5sum "$swift_args" myfiles file1.dat b6d81b360a5672d80c27430f39153e2c
        debug_all_errors
}
