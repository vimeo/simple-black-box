# $@ greppable things to look in
assert_no_errors () {
        num_errors=$(grep -iR error "$@" 2>/dev/null | wc -l)
        if [ $num_errors -eq 0 ]; then
                win "no errors in $*!"
        else
                fail "$num_errors errors in $*!"
        fi
}

# $1 regex to match error
# shift; $@ greppable things to look in
assert_only_error () {
        local error_match=$1
        shift
        num_errors_match=$(grep -iR "$error_match" "$@" 2>/dev/null | wc -l)
        if [ $num_errors_match -gt 0 ]; then
                win "$num_errors_match error(s) matching '$error_match' in $*"
                num_errors_all=$(grep -iR error "$@" 2>/dev/null | grep -iv "$error_match" | wc -l)
                if [ $num_errors_all -gt 0 ]; then
                        fail "$num_errors_all total errors in $*"
                fi
        else
                fail "no error matching '$error_match' in $*"
        fi
}
