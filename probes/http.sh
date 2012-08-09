regex_client_socket='[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}:[[:digit:]]+' #'<ip address>:<port>'
regex_socket_info="^T $regex_client_socket -> $regex_client_socket( |$)"

# $1 key: a string you'll use to refer to this particular probe instance
#  pick a name that corresponds to the app/service your app is talking to
# $2 http pattern, to be fed to ngrep. something like 'port 80 and host foo'
set_http_probe () {
        local key=$1
        local http_pattern="$2" # to be fed to ngrep.  something like 'port 80 and host foo'
        [ -n "$key" ] || die_error "set_http_probe () needs a non-zero reference key"
        [ -n "$http_pattern" ] || die_error "set_http_probe () needs a non-zero ngrep pattern to match http traffic"
        debug "set_http_probe $key '$http_pattern'"
        sudo ngrep -W byline $http_pattern > $output/http_$key &
        internal=1 assert_num_procs "^ngrep.*$http_pattern" 1
}

# $1 key (a string you'll use to refer to this particular probe instance)
# $2 res_match: egrep-compatible expression to match http responses codes, example: '(200|201)'
assert_all_http_responses () {
        local key=$1
        local res_match="$2"
        [ -n "$key" ] || die_error "assert_all_http_responses () needs a non-zero reference key"
        [ -n "$res_match" ] || die_error "assert_all_responses () needs a non-zero egrep regex to match http response codes"
        local num_match=$(egrep -c "^HTTP/1\.. $res_match" $output/http_$key)
        num_all=$(egrep -c "^HTTP/1\.. " $output/http_$key)
        if [ $num_match -ne $num_all ]; then
                fail "only $num_match http response code(s) matching '$res_match' out of $num_all total"
                egrep "^HTTP/1\.. " $output/http_$key | debug_stream "all http response codes:"
        else
                win "all $num_match http response code(s) match '$res_match'"
        fi
}

# $1 key (a string you'll use to refer to this particular probe instance)
# $2 regex to match request
# $3 min expected number of matching requests (0-...)
# $4 max expected number of matching requests (0-I where I means Infinity, i.e. disable this check)
assert_num_http_requests () {
        local key=$1
        local match_req="$2"
        local match_req_min=$3
        local match_req_max=$4
        [ -n "$key" ] || die_error "assert_num_http_requests () needs a non-zero reference key"
        [ -n "$match_req" ] || die_error "assert_num_http_requests () needs a non-zero egrep regex to match the http request"
        [[ $match_req_min =~ ^[0-9]+$ ]] || die_error "assert_num_http_requests() \$2 must be a number! not $2"
        [[ $match_req_max =~ ^[0-9]+$ ]] || [ "$match_req_max" == "I" ] || die_error "assert_num_http_requests() \$3 must be a number or I(nfinity)! not $3"
        [ $match_req_max != "I" ] && [ $match_req_max -ge $match_req_min ] || die_error "assert_num_http_requests() match_req_min ($match_req_min) must be lower or equal to match_req_max ($match_req_max)"
        # in the ngrep output, you always first see the socket info and on the line below, either a http request or response
        num_match_req=$(egrep -A 1 "$regex_socket_info" $output/http_$key | egrep -v "$regex_socket_info" | grep -v ^HTTP | grep -v '^\-\-' | egrep -c "$match_req")
        egrep -A 1 "$regex_socket_info" $output/http_$key | egrep -v "$regex_socket_info" | grep -v ^HTTP | grep -v '^\-\-' | egrep "$match_req" | debug_stream "http requests matching '$match_req'"
        if [ $num_match_req -ge $match_req_min ]; then
                if [ "$match_req_max" == "I" ] || [ $num_match_req -le $match_req_max ]; then
                        win "$num_match_req http request(s) matching '$match_req', which is between $match_req_min (min) and $match_req_max (max)"
                        return
                fi
        fi
        fail "$num_match_req http request(s) matching '$match_req' which is not between $match_req_min (min) and $match_req_max (max)"
}

# $1 key (a string you'll use to refer to this particular probe instance)
# $2 regex to match request
# $3 regex to match response
# assert that all responses to any requests matching $match_req match $match_res
# note that you can sometimes see several http requests (matching and/or not matching) before seeing their responses.
# so for every matching request, we track the client socket, and then, the first time we see a particular client socket we were
# looking for, we can safely assume it's the corresponding response, so we process it and then stop looking for that client socket.
assert_http_response_to () {
        local key="$1"
        local match_req="$2"
        local match_res="$3"
        [ -n "$key" ] || die_error "assert_http_response_to () needs a non-zero reference key"
        [ -n "$match_req" ] || die_error "assert_http_response_to () needs a non-zero egrep regex to match the http request"
        [ -n "$match_res" ] || die_error "assert_http_response_to () needs a non-zero egrep regex to match the http response"
        responses_good=()
        responses_bad=()
        # internal check to be sure we find 1 response for each found request
        num_match_req=0
        num_res=0
        client_sockets=() # list of 'client ip:port' used to do matching requests, this allows us to find the responses
        while read line; do
                if [[ $line =~ $regex_socket_info ]]; then
                        socket_info=$line
                        read line
                        if ! [[ $line =~ ^HTTP ]]; then
                                # $line is a request
                                if [[ $line =~ $match_req ]]; then
                                        client_sockets+=($(awk "/$regex_socket_info/ {print \$2}" <<< "$socket_info"))
                                        num_match_req=$((num_match_req+1))
                                fi
                        else
                                # $line is a response
                                if [ ${#client_sockets[@]} -gt 0 ]; then
                                        client_sockets_still_notfound=()
                                        for client_socket in ${client_sockets[@]}; do
                                                regex="T $regex_client_socket -> $client_socket( |$)"
                                                if [[ $socket_info =~ $regex ]]; then
                                                        num_res=$((num_res+1))
                                                        [[ $line =~ $match_res ]] && responses_good+=("$line") || responses_bad+=("$line")
                                                else
                                                        client_sockets_still_notfound+=($client_socket)
                                                fi
                                        done
                                        client_sockets=(${client_sockets_still_notfound[@]})
                                fi
                        fi
                fi
        done < $output/http_$key
        debug "responses_good: ${responses_good[@]}"
        debug "responses_bad: ${responses_bad[@]}"
        internal=1 assert_http_req_resp_found $key $num_match_req $num_res
        if [ ${#responses_bad[@]} -eq 0 ]; then
                win "all $num_match_req http request(s) matching '$match_req' have a response matching '$match_res'"
        else
                fail "$num_match_req http request(s) matching '$match_req' yielded ${#responses_good[@]} responses matching '$match_res', and ${#responses_bad[@]} that do not match (${responses_bad[@]})"
        fi
}

# $1 key (a string you'll use to refer to this particular probe instance)
# $2 number of requests
# $3 number of corresponding responses
# for internal use
assert_http_req_resp_found () {
        [ -n "$1" ] || die_error "assert_http_req_resp_found (): \$1 must be a non-zero reference key, not '$1'"
        [[ $2 =~ ^[0-9]+$ ]] || die_error "assert_http_req_resp_found(): \$2 must be a number to denote number of requests, not '$2'"
        [[ $3 =~ ^[0-9]+$ ]] || die_error "assert_http_req_resp_found(): \$3 must be a number to denote number of responses, not '$3'"
        [ $2 -ne $3 ] && fail "internal error. found $2 http request(s) but $3 response(s). this number should match"
}

# $1 http pattern (as specified to set_http_probe)
remove_http_probe () {
        local http_pattern="$1"
        [ -n "$http_pattern" ] || die_error "remove_http_probe () needs a non-zero ngrep pattern that was used to match http traffic"
        debug "remove_http_probe '$http_pattern'"
        #FIXME https://sourceforge.net/tracker/?func=detail&aid=3537747&group_id=10752&atid=110752
        # should not require root here.
        sudo pkill -f "^ngrep -W byline $http_pattern"
        internal=1 assert_num_procs "^ngrep.*$http_pattern" 0
}
