# interestingly, ngrep doesn't seem to be able to show us plaintext udp packets
# so we must use tcpdump.

# $1 key (a string you'll use to refer to this particular probe instance)
# $2 pattern, to be fed to tcpdump.
set_udp_statsd_probe () {
	local key=$1
        local pattern="$2"
        [ -n "$key" ] || die_error "set_udp_statsd_probe () needs a non-zero reference key"
        [ -n "$pattern" ] || die_error "set_udp_statsd_probe () needs a non-zero pattern to match the traffic"
        debug "set_udp_statsd_probe $key '$pattern'"
        sudo tcpdump -tttt -n -A $pattern 2>&1 | egrep -v '^(tcpdump|listening on|$|[^ ]+ packets)' > $output/udp_statsd_$key &
        internal=1 assert_num_procs "^tcpdump.*$pattern" 1
}

# $1 key (a string you'll use to refer to this particular probe instance)
# $2 regex to match request
# $3 min expected number of matching requests (0-...)
# $4 max expected number of matching requests (0-I where I means Infinity, i.e. disable this check)
assert_num_udp_statsd_requests () {
	local key=$1
        local match_req="$2"
        local match_req_min=$3
        local match_req_max=$4
        [ -n "$key" ] || die_error "assert_num_udp_statsd_requests () needs a non-zero reference key"
        [ -n "$match_req" ] || die_error "assert_num_udp_statsd_requests () needs a non-zero egrep regex to match the udp_statsd request"
        [[ $match_req_min =~ ^[0-9]+$ ]] || die_error "assert_num_udp_statsd_requests() \$2 must be a number! not $2"
        [[ $match_req_max =~ ^[0-9]+$ ]] || [ "$match_req_max" == "I" ] || die_error "assert_num_udp_statsd_requests() \$3 must be a number or I(nfinity)! not $3"
        [ $match_req_max != "I" ] && [ $match_req_max -ge $match_req_min ] || die_error "assert_num_udp_statsd_requests() match_req_min ($match_req_min) must be lower or equal to match_req_max ($match_req_max)"
        num_match_req=$(grep -c "$match_req" $output/udp_statsd_$key)
        grep "$match_req" $output/udp_statsd_$key | debug_stream "udp_statsd requests matching '$match_req'"
        if [ $num_match_req -ge $match_req_min ]; then
                if [ "$match_req_max" == "I" ] || [ $num_match_req -le $match_req_max ]; then
                        win "$num_match_req udp_statsd request(s) matching '$match_req', which is between $match_req_min (min) and $match_req_max (max)"
                        return
                fi
        fi
        fail "$num_match_req udp_statsd request(s) matching '$match_req' which is not between $match_req_min (min) and $match_req_max (max)"
}

# $1 udp_statsd pattern (as specified to set_udp_statsd_probe)
remove_udp_statsd_probe () {
        local pattern="$1"
        [ -n "$pattern" ] || die_error "remove_udp_statsd_probe () needs a non-zero tcpdump pattern that was used to match udp_statsd traffic"
        debug "remove_udp_statsd_probe '$pattern'"
        sudo pkill -f "^tcpdump -tttt -n -A $pattern"
        internal=1 assert_num_procs "^tcpdump.*$pattern" 0
}
