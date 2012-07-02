# seems like swift accept many different characters. nice!
# should probably keep extending the string until something breaks
test_pre () {
        ${config_backend}_change_var $config_sandbox swift_container "\"$fu_string\""
}
test_post () {
        swift $swift_args delete "$fu_string"
        assert_http_response_to 'GET /auth/v1.0' 200
        assert_num_http_requests 'GET /auth/v1.0' $num_procs_up $num_procs_up # every process will do an auth
        assert_no_errors $stdout $stderr $log
        debug_all_errors
}
