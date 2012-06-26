# $1 'pgrep -f'-compatible regex
# $2 number of procs
assert_num_procs () {
        local regex="$1"
        local num_procs="$2"
        [ -n "$regex" ] || die_error "assert_num_procs() needs a non-zero pgrep-f compatible regex as \$1"
        [[ "$num_procs" =~ ^[0-9]+$ ]] || die_error "assert_num_procs() \$2 must be a number! not $num_procs"
        num_procs_real=$(pgrep -fc "$1")
        if [ $num_procs_real -eq $num_procs ]; then
                win "$num_procs procs running matching $regex"
        else
                fail "$num_procs_real procs running - instead of desired $num_procs - matching: $regex"
        fi
}
