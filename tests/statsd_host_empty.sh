test_pre () {
        ${config_backend}_change_var $config_sandbox statsd_host '""'
}

test_while () {
        assert_num_procs "$process_pattern_vega" 0
        assert_num_procs "$process_pattern_uploader" $process_num_up_uploader
        assert_listening "$net_listen_addr" 0
}

test_post () {
        test_post_vega_dies_during_startup "ERROR:.*missing.*statsd_host"
        debug_all_errors
}
