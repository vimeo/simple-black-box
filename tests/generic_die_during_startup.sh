# needed vars:
# $subject_process
# $num_procs_down
# $error
# $listen_address
# at least one out of $stdout $stderr $log

test_while () {
        assert_num_procs "$subject_process" $num_procs_down
        assert_listening "$listen_address" 0
}

test_post () {
        assert_num_http_requests 'GET /auth/v1.0' 0 0
        assert_num_http_requests '.*' 0 0
        assert_only_error "$error" $stdout $stderr $log
        debug_all_errors
}
