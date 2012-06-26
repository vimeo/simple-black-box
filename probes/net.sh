# $1 'lsof -i' compatible address specification, example: tcp:8080
# $2 1 for listening, 0 for not listening
assert_listening () {
        address=$1
        listening=$2
        [ -n "$address" ] || die_error "assert_listening needs a non-zero 'lsof -i' compatible address specification as \$1"
        check_is_in $2 0 1 || die_error "assert_listening needs the number 1 or 0 as \$2, not $2"
        if lsof -i $address >/dev/null; then
                ((listening)) && win "something is listening on $address" || fail "something is listening on $address"
        else
                ((listening)) && fail "nothing is listening on $address" || win "nothing is listening on $address"
        fi
}
