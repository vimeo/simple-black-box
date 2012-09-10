test_pre () {
        ${config_backend}_remove_var $config_sandbox swift_port
}

test_while () {
        assert_num_procs "$process_pattern_vega" $process_num_up_vega
        assert_num_procs "$process_pattern_uploader" $process_num_up_uploader
        assert_listening "$net_listen_addr" 1
}

test_post () {
        test_post_ok
        debug_all_errors
}
