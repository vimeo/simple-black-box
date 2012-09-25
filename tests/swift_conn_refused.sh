test_pre () {
        # todo doublecheck with netstat, or automatically figure out non-used one.
        ${config_backend}_change_var $config_sandbox swift_host '"127.0.0.1"'
        ${config_backend}_change_var $config_sandbox swift_port 8585
}
test_while () {
        assert_num_procs "$process_pattern_vega" $process_num_up_vega
        assert_num_procs "$process_pattern_uploader" $process_num_up_uploader
        assert_listening "$net_listen_addr" 1
}

test_post () {
        test_post_ok_but_no_swift "ECONNREFUSED"
        test_post_finish
}
