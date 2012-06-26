error="Trouble connecting to openstack: Error: request unsuccessful, statusCode: 401"
source tests/generic_down_with_error.sh
test_pre () {
        ${config_backend}_change_var $config_sandbox swift_user '"system:foobardoesnotexist"'
}
