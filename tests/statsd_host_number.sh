test_pre () {
        ${config_backend}_change_var $config_sandbox statsd_host 123
}
test_post () {
        test_post_ok_but_no_statsd ""
}
