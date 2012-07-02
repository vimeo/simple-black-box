# needed vars:
# $subject_process
# $num_procs_down
# $error
# $listen_address
# $match_auth_response
# at least one out of $stdout $stderr $log

test_while () {
        assert_num_procs "$subject_process" $num_procs_down
        assert_listening "$listen_address" 0
}

test_post () {
        assert_http_response_to 'GET /auth/v1.0' "$match_auth_response"
        assert_num_http_requests 'GET /auth/v1.0' 1 1
        assert_num_http_requests '.*' 1 1
        assert_only_error "$error" $stdout $stderr $log
        debug_all_errors
}
