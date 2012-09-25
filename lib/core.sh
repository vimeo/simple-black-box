wins=0
fails=0
testcases=0
color_debug=$BBlack
color_fail=$Red
color_win=$Green
color_header=$BBlue

# looks for global var $sbb_section
print_section () {
        printf "%5s " $sbb_section
}

# for internal (to the framework) assertions, set variable internal=1
# $1 message
fail () {
        local message=$1
        [ -n "$1" ] || die_error "fail() \$1 must be a non-zero message"
        ((internal)) && die_error "internal assertion failed: $1"
        print_section
        echo -e "${color_fail}[FAIL]${Color_Off} $message"
        debug "$(print_stacktrace)"
        fails=$((fails+1))
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
        ((internal)) && return
        print_section
        echo -e "${color_win}[WIN!]${Color_Off} $message"
        wins=$((wins+1))
}

# $1 message (mandatory)
debug () {
        local message=$1
        [ -n "$1" ] || die_error "debug() \$1 must be a non-zero message"
        if((debug)); then
                print_section
                echo -e "${color_debug}debug: $message$Color_Off"
        fi
}

# $1 message (optional)
debug_begin () {
        local message=$1
        if((debug)); then
                print_section
                echo -en "${color_debug}debug: $message"
        fi
}

# $1 message (optional)
debug_end () {
        local message=$1
        if((debug)); then
                echo -e "$message$Color_Off"
        fi
}

# $1 message
# stdin: all lines to go into debug output
debug_stream () {
        local message=$1
        [ -n "$1" ] || die_error "debug_stream() \$1 must be a non-zero message"
        debug "$message"
        while read line; do
                [ -n "$line" ] && debug "$line"
        done
}

# $1 something executable (program, function, ..)  which must return true
# $2 decisecond timeout
# return $1's last exit code
wait_until () {
        local f=$1
        local timeout=$2
        [[ -n $f ]] && declare -f | which --read-functions "$f" &>/dev/null || die_error "wait_until() \$1 must be something executable! not $1"
        [[ $timeout =~ ^[0-9]+$ ]] || die_error "wait_until() \$2 must be a number! not $2"
        timer=0
        local f_ret=
        while true; do
            $f
            f_ret=$?
            [[ $f_ret -eq 0 ]] && break
            [ $timer -lt $timeout ] || break
            sleep 0.1s
            timer=$((timer+1))
        done
        return $f_ret
}

# $1 test case
run_test () {
        local test=$1
        [ -n "$1" -a -f "tests/$test.sh" ] || die_error "run_test() \$1 must be the name of an existing testcase, not '$1'"
        [[ "$test" =~ [\ ] ]] && die_error "testcase may not have whitespace in the name (no specific reason, just makes everybodies life a bit easier)."
        source tests/default.sh
        source tests/$test.sh
        echo -e "${color_header}Running test $test$Color_Off"
        echo -e "${color_debug}sandbox : $sandbox$Color_Off"
        echo -e "${color_debug}output  : $output$Color_Off"
        for section in init pre start while stop post; do
                sbb_section=$section
                test_$section
        done
        sbb_section=
        testcases=$((testcases+1))
        echo
}

# $1 'pgrep -f'-compatible regex (be very careful about specifying and passing this correctly!)
# $2 deciseconds to wait for processes to exit after receiving TERM before issuing KILL (default 50)
kill_graceful () {
        local regex="$1"
        local timeout=${2:-50}
        [ -n "$1" ] || die_error "kill_graceful() \$1 must be a non-zero regex"
        [[ $timeout =~ ^[0-9]+$ ]] || die_error "kill_graceful() \$2 must be a number! not $2"
        debug "kill_graceful '$regex' $timeout"
        pkill -f "$regex" 2>/dev/null
        process_not_running () {
            ! pgrep -f "$regex" >/dev/null
        }
        wait_until process_not_running $timeout
        pkill -9 -f "$regex" 2>/dev/null
}

# $1 the "what", for example 'somefunction() shift; $@' to denote all params after the first one in somefunction()
# shift; $@ list of params of which at least one must be a readable file
at_least_one_readable_file () {
        local what="$1"
        [ -n "$what" ] || die_error "atleast_onefile_readable() \$1 must be an identifier"
        okay=0
        shift
        for f in $@; do
                [ -n "$f" ] || die_error "atleast_onefile_readable(): $what: all files listed must be non-zero strings"
                [ -f "$f" -a -r "$f" ] && okay=1
        done
        ((okay)) || die_error "$what must at least contain one existing and readable file. not $*"
}

show_summary () {
        color=${color_debug}
        [ $wins -gt 0 ] && color=${color_win}
        [ $fails -gt 0 ] && color=${color_fail}
        echo -e "${color}SUMMARY: $wins WIN, $fails FAIL in $testcases testcases${Color_Off}"
}

# assuming files like so: /tmp/blah/foo /tmp/blah/bar foobar, will condense to /tmp/blah/{foo,bar} foobar
# but only when the path contains the output dir. (this depends on $output not having an ending /)
# note this function does not care whether the files actually exist or not. it's just a display thing
# $@ filenames
compact_filenames () {
        compact=()
        normal=()
        for f in $@; do
               f_short=${f/$output\/}
               [ "$f_short" == "$f" ] && normal+=("$f") || compact+=("$f_short")
        done
        if [ ${#compact[@]} -eq 0 ]; then
                echo ${normal[@]}
        elif [ ${#compact[@]} -eq 1 ]; then
                echo $output/${compact[0]} ${normal[@]}
        else
                local str
                for i in ${compact[@]}; do
                        [ -n "$str" ] && str="$str,$i" || str=$i
                done
                echo "$output/{$str} ${normal[@]}"
       fi
}
