error="getaddrinfo"
source tests/generic_die_during_startup.sh
test_pre () {
        ${config_backend}_change_var $config_sandbox swift_host '"foobar.notexist.dietertest.ny.vimeo.com"'
}
