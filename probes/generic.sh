# $@ command to execute
assert_exitcode () {
        if $@; then
                win "execution success: $(echo $@)"
        else
                fail "execution failed: $(echo $@)"
        fi
}
