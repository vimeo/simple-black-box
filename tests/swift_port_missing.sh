test_pre () {
        ${config_backend}_remove_var $config_sandbox swift_port
}

test_while () {
        assert_num_procs "$subject_process" $num_procs_up
        assert_listening "$listen_address" 1
}

test_post () {
        test_post_ok
        debug_all_errors
}
