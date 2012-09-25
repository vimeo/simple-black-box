test_pre () {
        ${config_backend}_change_var $config_sandbox swift_pass '"badpassword"'
}

test_while () {
        assert_num_procs "$process_pattern_vega" $process_num_up_vega
        assert_num_procs "$process_pattern_uploader" 0
        assert_listening "$net_listen_addr" 1
}

test_post () {
        test_post_uploader_dies_at_auth "Trouble connecting to openstack: Error: request unsuccessful, statusCode: 401" 'HTTP/1.1 401 Unauthorized'
        test_post_finish
}
