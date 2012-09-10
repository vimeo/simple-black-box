# useful functions which testcases can refer to

debug_all_errors () {
        grep -Ri --color=never error $output/stdout_* $output/stderr_* $log 2>/dev/null | debug_stream "all errors:"
}
