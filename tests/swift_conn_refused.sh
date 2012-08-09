test_pre () {
        # todo doublecheck with netstat, or automatically figure out non-used one.
        ${config_backend}_change_var $config_sandbox swift_host '"127.0.0.1"'
        ${config_backend}_change_var $config_sandbox swift_port 8585
}
test_while () {
        assert_num_procs "$subject_process" $num_procs_down
        assert_listening "$listen_address" 0
}

test_post () {
        test_post_die_during_startup "ECONNREFUSED"
        debug_all_errors
}
