# $@ greppable things to look in
assert_no_errors () {
        num_errors=$(grep -iR error "$@" 2>/dev/null | wc -l)
        if [ $num_errors -eq 0 ]; then
                win "no errors in $*!"
        else
                fail "$num_errors errors in $*!"
        fi
}

# $1 regex
# shift; $@ greppable things to look in
assert_only_error () {
        local regex=$1
        shift
        num_errors=$(grep -iR "$regex" "$@" 2>/dev/null | wc -l)
        if [ $num_errors -gt 0 ]; then
                win "got $num_errors error(s) matching '$regex' in $*"
                all_errors=$(grep -iR error "$@" 2>/dev/null | grep -iv "$regex" | wc -l)
                if [ $all_errors -gt 0 ]; then
                        fail "...but got $all_errors total errors in $*"
                fi
        else
                fail "didn't find any error matching '$regex' in $*"
        fi
}
