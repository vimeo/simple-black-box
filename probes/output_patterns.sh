assert_no_errors () {
        num_errors=$(grep -iR error $stdout $stderr $log 2>/dev/null | wc -l)
        if [ $num_errors -eq 0 ]; then
                win "no errors!"
        else
                fail "$num_errors errors!"
        fi
}
assert_only_error () {
        num_errors=$(grep -iR "$1" $stdout $stderr $log 2>/dev/null | wc -l)
        if [ $num_errors -gt 0 ]; then
                win "got the error(s) we're looking for ($num_errors of them)"
                all_errors=$(grep -iR error $stdout $stderr $log 2>/dev/null| grep -iv "$1" | wc -l)
                if [ $all_errors -gt 0 ]; then
                        fail "...but got $all_errors errors in total"
                fi
        else
                fail "didn't find the error we're looking for ($1)"
        fi
}
