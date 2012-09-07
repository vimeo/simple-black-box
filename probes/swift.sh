# swift args get passed to the swift cli program
# example: swift_args="-A http://$swift_host:$swift_port/auth/v1.0 -U $swift_user -K $swift_pass"

# $1 swift_args
# $2 container
# $3 1 for existing, 0 for not existing (default: 1)
assert_container_exists () {
        local swift_args="$1"
        local container=$2
        local existing=${3:-1}
        [ -n "$swift_args" ] || die_error "assert_container_exists() needs a list of swift args as \$1"
        [ -n "$container" ] || die_error "assert_container_exists() needs a non-zero swift container name as \$2"
        check_is_in $existing 0 1 || die_error "assert_container_exists() needs the number 1 or 0 (or empty for default of 1) as \$3, not $3"
        if swift $swift_args list "$container" 2>&1 | grep -q "Container '$container' not found"; then
                if ((existing)); then
                        fail "no swift container '$container'"
                else
                        win "no swift container '$container'"
                fi
        else
                if ((existing)); then
                        win "1 swift container '$container'"
                else
                        fail "1 swift container '$container'"
                fi
        fi
}

# $1 swift_args
# $2 container
# $3 object
# $4 1 for existing, 0 for not existing (default: 1)
# $5 deciseconds to wait for the blob to (dis)appear. default 30
# your job to make sure the container exists!
assert_object_exists () {
        local swift_args="$1"
        local container=$2
        local object=$3
        local existing=${4:-1}
        local timeout=${5:-30}
        [ -n "$swift_args" ] || die_error "assert_object_exists() needs a list of swift args as \$1"
        [ -n "$container" ] || die_error "assert_object_exists() needs a non-zero swift container name as \$2"
        [ -n "$object" ] || die_error "assert_object_exists() needs a non-zero swift object name as \$3"
        check_is_in $existing 0 1 || die_error "assert_object_exists() needs the number 1 or 0 (or empty for default of 1) as \$4, not $4"
        [[ $timeout =~ ^[0-9]+$ ]] || die_error "assert_object_exists() \$5 must be a number! not $timeout"
        desired_object_exists () {
                # the regex matching is not safe if $object contains chars with special meanings in regexes!
                # can put "Container 'foo' not found" on stderr
                if swift $swift_args list "$container" 2>/dev/null | grep -q "^$object$"; then
                        ((existing)) && win "1 swift object '$object' in container '$container' (after $timer ds)" && return 0
                else
                        ! ((existing)) && win "no swift object '$object' in container '$container' (after $timer ds)" && return 0
                fi
                return 1
        }
        if ! wait_until desired_object_exists $timeout; then
                if ((existing)); then
                    fail "no swift object '$object' in container '$container' (waited $timer deciseconds)"
                else
                    fail "1 swift object '$object' in container '$container' (waited $timer deciseconds)"
                fi
        fi
}

# $1 swift_args
# $2 container
# $3 object
# $4 expected md5sum
# your job to make sure the object exists!
assert_object_md5sum () {
        local swift_args="$1"
        local container=$2
        local object=$3
        local md5sum=$4
        [ -n "$swift_args" ] || die_error "assert_object_md5sum() needs a list of swift args as \$1"
        [ -n "$container" ] || die_error "assert_object_md5sum() needs a non-zero swift container name as \$2"
        [ -n "$object" ] || die_error "assert_object_md5sum() needs a non-zero swift object name as \$3"
        [ ${#md5sum} -eq 32 ] || die_error "assert_object_md5sum() \$4 must be an md5sum of 32 characters, not '$4'"
        # can put "Object 'container/object' not found" on stderr
        local md5sum_swift=$(swift $swift_args download $container -o - $object 2>/dev/null | md5sum | cut -f1 -d' ')
        if [ $md5sum_swift = $md5sum ]; then
                win "swift object '$object' in container '$container' has md5sum $md5sum"
        else
                fail "swift object '$object' in container '$container' has md5sum $md5sum_swift, not the expected $md5sum"
        fi
}
