error="ECONNREFUSED"
source tests/generic_down_with_error.sh
test_pre () {
        # todo doublecheck with netstat, or automatically figure out non-used one.
        ${config_backend}_change_var $config_sandbox swift_host '"127.0.0.1"'
        ${config_backend}_change_var $config_sandbox swift_port 8585
}
