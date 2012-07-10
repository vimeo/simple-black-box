# $1 'lsof -i' compatible address specification, example: tcp:8080
# $2 1 for listening, 0 for not listening
# $3 deciseconds to wait, in case it takes a while before your process starts/stops listening) (default: 50)
# TODO: this does not work for privileged ports (<1024), because lsof doesn't list them unless you run it as root
# netstat always lists privileged ports even when running as normal user, but that tool is less handy
assert_listening () {
        address=$1
        listening=$2
        local timeout=${3:-50}
        [ -n "$address" ] || die_error "assert_listening needs a non-zero 'lsof -i' compatible address specification as \$1"
        check_is_in $2 0 1 || die_error "assert_listening needs the number 1 or 0 as \$2, not $2"
        [[ $timeout =~ ^[0-9]+$ ]] || die_error "kill_graceful() \$3 must be a number! not $timeout"
        timer=0
        debug "assert_listening on address $address (listening: $listening) -> lsof -sTCP:LISTEN -i $address"
        while [ $timer -ne $timeout ]; do
                if ((listening)) && lsof -sTCP:LISTEN -i $address >/dev/null; then
                        win "something is listening on $address (after $timer ds)"
                        return
                elif ((!listening)) && ! lsof -sTCP:LISTEN -i $address >/dev/null; then
                        win "nothing is listening on $address (after $timer ds)"
                        return
                fi
                sleep 0.1s
                timer=$((timer+1))
        done
        if ((listening)); then
                fail "nothing is listening on $address (after $timer ds)"
        else
                fail "something is listening on $address (after $timer ds)"
        fi
}
