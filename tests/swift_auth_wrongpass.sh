source tests/generic_die_at_auth.sh
error="Trouble connecting to openstack: Error: request unsuccessful, statusCode: 401"
match_auth_response='HTTP/1.1 401 Unauthorized'
test_pre () {
        ${config_backend}_change_var $config_sandbox swift_pass '"badpassword"'
}
