test_pre () {
        ${config_backend}_change_var $config_sandbox statsd_host '""'
}

test_while () {
        assert_num_procs "$process_pattern_vega" 0
        assert_num_procs "$process_pattern_uploader" 0
        assert_listening "$net_listen_addr" 0
}

test_post () {
        test_post_vega_and_uploader_die_during_startup "ERROR:.*missing.*statsd_host"
        debug_all_errors
}
