# $@ greppable things to look in
assert_no_errors () {
        at_least_one_readable_file 'assert_no_errors() $@' $@
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
        [ -n "$error_match" ] || die_error "assert_only_error() \$1 must be a non-zero regex to match an error, not '$1'"
        shift
        at_least_one_readable_file 'assert_only_error() shift; $@' $@
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

# $1 regex to match
# $2 logged: 1/0 whether this pattern must be found or not
# shift 2; $@ greppable things to look in
assert_pattern () {
        local match=$1
        local logged=$2
        [ -n "$match" ] || die_error "assert_pattern() \$1 must be a non-zero regex to match an error, not '$1'"
        check_is_in $logged 0 1 || die_error "assert_pattern() needs the number 1 or 0 as \$2, not $2"
        shift 2
        at_least_one_readable_file 'assert_pattern() shift 2; $@' $@
        num_match=$(grep -iR "$match" "$@" 2>/dev/null | wc -l)
        if [ $num_match -gt 0 ]; then
                if ((logged)); then
                        win "$num_match string(s) matching '$match' in $*"
                else
                        fail "$num_match string(s) matching '$match' in $*"
                fi
        else
                if ((logged)); then
                        fail "no string matching '$match' in $*"
                else
                        win "no string matching '$match' in $*"
                fi
        fi
}
