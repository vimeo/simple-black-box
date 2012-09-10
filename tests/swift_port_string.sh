test_pre () {
        ${config_backend}_change_var $config_sandbox swift_port '"teststring"'
}

test_while () {
        assert_num_procs "$process_pattern_vega" $process_num_up_vega
        assert_num_procs "$process_pattern_uploader" 0
        assert_listening "$net_listen_addr" 1
}

test_post () {
        test_post_uploader_dies_during_startup "error.*not set to an integer"
        debug_all_errors
}
