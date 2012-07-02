# needed vars:
# $config_sandbox
# $key
# $subject_process # 'pgrep -f'-compatible regex to find processes
# $num_procs # expected number of processes
# $error # error to look for (empty: assert no errors)
# $config_backend

test_pre () {
        ${config_backend}_change_var $config_sandbox $key '""'
}

test_while () {
        assert_num_procs "$subject_process" $num_procs
        assert_listening "$listen_address" $listening
}

test_post () {
        if [ -z "$error" ]; then
                assert_http_response_to 'GET /auth/v1.0' 200
                assert_num_http_requests 'GET /auth/v1.0' $num_procs_up $num_procs_up # every process will do an auth
                assert_no_errors $stdout $stderr $log
        else
                assert_num_http_requests '.*' 0 0
                assert_only_error "$error" $stdout $stderr $log
        fi
        debug_all_errors
}
