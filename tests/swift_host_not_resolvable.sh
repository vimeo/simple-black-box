test_pre () {
        ${config_backend}_change_var $config_sandbox swift_host '"foobar.notexist.dietertest.ny.vimeo.com"'
}

test_while () {
        assert_num_procs "$process_pattern" 0
        assert_listening "$net_listen_addr" 0
}

test_post () {
        test_post_die_during_startup "getaddrinfo"
        debug_all_errors
}
