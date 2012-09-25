test_pre () {
        container=test_$RANDOM
        debug "creating container $container: $(swift $swift_args post $container 2>&1)"
        internal=1 assert_container_exists "$swift_args" $container
        ${config_backend}_change_var $config_sandbox swift_container "\"$container\""
}

test_post () {
        test_post_ok
        assert_pattern "container.*$container.*already existed" 1 $output/stdout_uploader $output/stderr_uploader $log
        assert_pattern "created.*$container" 0 $output/stdout_* $output/stderr_* $log
        debug "deleting container $container: $(swift $swift_args delete $container 2>&1)"
        internal=1 assert_container_exists "$swift_args" $container 0
        test_post_finish
}
