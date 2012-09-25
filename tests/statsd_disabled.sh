# we want to be able to disable statsd without any impact on the app.
# a way to do that is by pointing to an adress where no statsd is listening. like localhost
test_pre () {
        internal=1 assert_listening udp:$statsd_port 0 0
        ${config_backend}_change_var $config_sandbox statsd_host '"127.0.0.1"'
}
test_post () {
        test_post_ok_but_no_statsd ""
        test_post_finish
}
