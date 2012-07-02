test_pre () {
        # TODO assure that it doesn't exist yet
        random_container="test_$RANDOM"
        ${config_backend}_change_var $config_sandbox swift_container "\"$random_container\""
}

test_post () {
        swift $swift_args delete $random_container
        assert_http_response_to 'GET /auth/v1.0' 200
        assert_num_http_requests 'GET /auth/v1.0' $num_procs_up $num_procs_up # every process will do an auth
        assert_no_errors $stdout $stderr $log
        debug_all_errors
}
