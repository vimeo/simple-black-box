test_pre () {
        container=test_$RANDOM
        debug "deleting container $container, should it exist: $(swift $swift_args delete $container 2>&1)"
        internal=1 assert_container_exists "$swift_args" $container 0
        ${config_backend}_change_var $config_sandbox swift_container "\"$container\""
}

test_post () {
        assert_container_exists "$swift_args" $container
        assert_object_exists "$swift_args" $container $ticket 1 0
        assert_object_md5sum "$swift_args" $container $ticket $md5sum
        assert_http_response_to swift 'GET /auth/v1.0' 200
        assert_num_http_requests swift 'GET /auth/v1.0' 1 1
        assert_http_response_to swift "^PUT /v1/AUTH_system/$container HTTP" 201
        assert_http_response_to swift "^PUT /v1/AUTH_system/$container/$ticket HTTP" 201
        assert_num_http_requests swift "^PUT" 2 2
        assert_num_udp_statsd_requests statsdev 'error' 0 0
        assert_num_udp_statsd_requests statsdev 'upload.requests.put:1|c' 1 1
        assert_num_udp_statsd_requests statsdev 'upload.rx.*|g' 30 50
        assert_num_udp_statsd_requests statsdev 'upload.concurrent_uploads.*:1|g' 1 1
        assert_num_udp_statsd_requests statsdev 'upload.concurrent_uploads.*:0|g' 1 1
        assert_num_udp_statsd_requests statsdev 'upload.requests.get-upload_complete:1|c' 1 1
        assert_no_errors $output/stdout_* $output/stderr_* $log $js
        assert_pattern "container.*$container.*already existed" 0 $output/stdout_* $output/stderr_* $log
        assert_pattern "created.*$container" 1 $output/stdout_uploader $output/stderr_uploader $log
        debug "deleting container $container: $(swift $swift_args delete $container 2>&1)"
        internal=1 assert_container_exists "$swift_args" $container 0
        test_post_finish
}
