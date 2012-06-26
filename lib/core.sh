# for internal (to the framework) assertions, set variable internal=1
# $1 message
fail () {
        local message=$1
        [ -n "$1" ] || die_error "fail() \$1 must be a non-zero message"
        ((internal)) && die_error "internal assertion failed: $1"
        echo -e "${Red}[FAIL]${Color_Off}: $message"
        if((pause)); then
                debug_all_errors
                echo "Pausing as requested.  Go fix it cowboy! Hit any key to continue (pro-tip: ctrl-Z to background and fg to resume again)"
                read
        fi
}

# $1 message
win () {
        local message=$1
        [ -n "$1" ] || die_error "win() \$1 must be a non-zero message"
        ((!internal)) && echo -e "${Green}[WIN!]${Color_Off}: $message"
}

# $1 message
debug () {
        local message=$1
        [ -n "$1" ] || die_error "debug() \$1 must be a non-zero message"
        if((debug)); then
                echo -e "${BBlack}debug: $message$Color_Off"
        fi
}

# $1 message
# stdin: all lines to go into debug output
debug_stream () {
        local message=$1
        [ -n "$1" ] || die_error "debug_stream() \$1 must be a non-zero message"
        debug "$message"
        while read line; do
                debug "$line"
        done
}

# $1 test case
# $2..n extra args to be passed to individual functions
run_test () {
        local test=$1
        [ -n "$1" -a -f "tests/$test.sh" ] || die_error "run_test() \$1 must be the name of an existing testcase, not '$1'"
        [[ "$test" =~ [\ ] ]] && die_error "testcase may not have whitespace in the name (no specific reason, just makes everybodies life a bit easier)."
        shift
        source tests/default.sh
        source tests/$test.sh
        test_setvars "$@"
        echo -e "${BBlue}Running test $test $@$Color_Off"
        echo -e "${BBlack}sandbox is $sandbox$Color_Off"
        test_prepare_sandbox "$@"
        test_pre "$@"
        test_run "$@"
        test_while "$@"
        test_teardown "$@"
        test_post "$@"
        echo
}

# $1 'pgrep -f'-compatible regex (be very careful about specifying and passing this correctly!)
# $2 deciseconds to wait for processes to exit after receiving TERM before issuing KILL
kill_graceful () {
        local regex="$1"
        local timeout=$2
        [ -n "$1" ] || die_error "kill_graceful() \$1 must be a non-zero regex"
        [[ $timeout =~ ^[0-9]+$ ]] || die_error "kill_graceful() \$2 must be a number! not $2"
        debug "kill_graceful '$regex' $timeout"
        pkill -f "$regex" 2>/dev/null
        timer=0
        while [ $timer -ne $timeout ] && pgrep -f "$regex" >/dev/null; do
                sleep 0.1s
                timer=$((timer+1))
        done
        pkill -9 -f "$regex" 2>/dev/null
}
