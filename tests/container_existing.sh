test_pre () {
        # TODO assure that it exists already
        ${config_backend}_change_var $config_sandbox swift_container '\"myfiles\"'
}
