test_pre () {
        # TODO assure that it doesn't exist yet
        random_container="test_$RANDOM"
        ${config_backend}_change_var $config_sandbox swift_container "\"$random_container\""
}

test_post () {
        swift $swift_args delete $random_container
}
