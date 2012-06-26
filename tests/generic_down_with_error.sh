# needed vars:
# $subject_process
# $num_procs_down
# $error
# $listen_address
# at least one out of $stdout $stderr $log

test_while () {
        assert_num_procs "$subject_process" $num_procs_down
        assert_listening "$listen_address" 0
}

test_post () {
       assert_only_error "$error" $stdout $stderr $log
}
