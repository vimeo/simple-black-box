# $@ command to execute
assert_exitcode () {
        [ -n "$1" ] || die_error "assert_exitcode () needs a command as arguments, not $(echo $@)"
        if $@; then
                win "execution success: $(echo $@)"
        else
                fail "execution failed: $(echo $@)"
        fi
}
