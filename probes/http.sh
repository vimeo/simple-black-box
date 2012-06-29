# $1 http pattern, to be fed to ngrep. something like 'port 80 and host foo'
set_http_probe () {
        local http_pattern="$1" # to be fed to ngrep.  something like 'port 80 and host foo'
        [ -n "$http_pattern" ] || die_error "set_http_probe () needs a non-zero ngrep pattern to match http traffic"
        debug "set_http_probe '$http_pattern'"
        sudo ngrep -W byline $http_pattern > $sandbox/sbb-http &
        internal=1 assert_num_procs "^ngrep.*$http_pattern" 1
}

# $1 accepted_codes: egrep-compatible expression of http status codes, example: '(200|201)'
assert_all_responses () {
        local accepted_codes="$1" # egrep-compatible expression of http status codes, example: '(200|201)'
        [ -n "$accepted_codes" ] || die_error "assert_all_responses () needs a non-zero egrep regex to match http codes"
        local num_match=$(egrep -c "^HTTP/1\.. $accepted_codes" $sandbox/sbb-http)
        num_all=$(egrep -c "^HTTP/1\.. " $sandbox/sbb-http)
        if [ $num_match -ne $num_all ]; then
                fail "only $num_match $accepted_codes http response status codes, out of $num_all total"
                egrep "^HTTP/1\.. " $sandbox/sbb-http | debug_stream "all http response codes:"
        else
                win "all $num_match http response codes were $accepted_codes"
        fi
}

# $1 http pattern (as specified to set_http_probe)
remove_http_probe () {
        local http_pattern="$1"
        [ -n "$http_pattern" ] || die_error "remote_http_probe () needs a non-zero ngrep pattern that was used to match http traffic"
        debug "remove_http_probe '$http_pattern'"
        #FIXME https://sourceforge.net/tracker/?func=detail&aid=3537747&group_id=10752&atid=110752
        # should not require root here.
        sudo pkill -f "^ngrep -W byline $http_pattern"
        internal=1 assert_num_procs "^ngrep.*$http_pattern" 0
}
