test_pre () {
        ${config_backend}_change_var $config_sandbox swift_port '""'
}

test_while () {
        assert_num_procs "$process_pattern" $process_num_up
        assert_listening "$net_listen_addr" 1
}

test_post () {
        test_post_ok
        debug_all_errors
}
