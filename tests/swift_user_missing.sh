test_pre () {
        ${config_backend}_remove_var $config_sandbox swift_user
}

test_while () {
        assert_num_procs "$process_pattern" 0
        assert_listening "$net_listen_addr" 0
}

test_post () {
        test_post_die_during_startup "ERROR:.*missing.*swift_user"
        debug_all_errors
}
