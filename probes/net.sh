# $1 'lsof -i' compatible address specification, example: tcp:8080
# $2 1 for listening, 0 for not listening
assert_listening () {
        address=$1
        listening=$2
        if lsof -i $address >/dev/null; then
                ((listening)) && win "something is listening on $address" || fail "something is listening on $address"
        else
                ((listening)) && fail "nothing is listening on $address" || win "nothing is listening on $address"
        fi
}
