test_pre () {
        ${config_backend}_change_var $config_sandbox statsd_port '"teststring"'
}

test_while () {
        assert_num_procs "$subject_process" $num_procs_down
        assert_listening "$listen_address" 0
}

test_post () {
        test_post_die_during_startup "error.*not set to an integer"
        debug_all_errors
}
