# seems like swift accept many different characters. nice!
# should probably keep extending the string until something breaks
test_pre () {
        ${config_backend}_change_var $config_sandbox swift_container "\"$fu_string\""
}
test_post () {
        swift $swift_args delete "$fu_string"
        debug_all_errors
}
