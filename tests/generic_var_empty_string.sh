# needed vars:
# $config_sandbox
# $key
# $subject_process # 'pgrep -f'-compatible regex to find processes
# $num_procs # expected number of processes
# $error # error to look for (empty: assert no errors)
# $config_backend

test_pre () {
        ${config_backend}_change_var $config_sandbox $key '""'
}

test_while () {
        assert_num_procs "$subject_process" $num_procs
}

test_post () {
        if [ -z "$error" ]; then
                assert_no_errors $stdout $stderr $log
        else
                assert_only_error "$error" $stdout $stderr $log
        fi
}
