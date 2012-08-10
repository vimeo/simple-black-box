test_pre () {
        ${config_backend}_change_var $config_sandbox statsd_host '"foobar.notexist.dietertest.ny.vimeo.com"'
}
test_post () {
        test_post_ok_but_no_statsd getaddrinfo
}
