source tests/swift_auth_user_non_exist.sh
test_pre () {
        ${config_backend}_change_var $config_sandbox swift_user "\"$fu_string\""
}
