# swift args get passed to the swift cli program
# example: swift_args="-A http://$swift_host:$swift_port/auth/v1.0 -U $swift_user -K $swift_pass"

# $1 swift_args
# $2 container
assert_container_exists () {
        local swift_args="$1"
        local container=$2
        [ -n "$swift_args" ] || die_error "assert_container_exists() needs a list of swift args as \$1"
        [ -n "$container" ] || die_error "assert_container_exists() needs a non-zero swift container name as \$2"
        # the echo is needed because grep -v needs always some input before the exitcodes are "normal"
        if { echo && swift $swift_args list "$container"; } 2>&1 | grep -vq "Container '$container' not found"; then
                win "swift container '$container' exists"
        else
                fail "swift container '$container' not found"
        fi
}

# $1 swift_args
# $2 container
# $3 object
# your job to make sure the container exists!
assert_object () {
        local swift_args="$1"
        local container=$2
        local object=$3
        [ -n "$swift_args" ] || die_error "assert_object() needs a list of swift args as \$1"
        [ -n "$container" ] || die_error "assert_object() needs a non-zero swift container name as \$2"
        [ -n "$object" ] || die_error "assert_object() needs a non-zero swift object name as \$3"
        # not safe if $object contains chars with special meanings in regexes!
        if swift $swift_args list "$container" | grep -q "^$object$"; then
                win "swift object $object exists in container $container"
        else
                fail "swift object $object not found in container $container"
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
        local md5sum_swift=$(swift $swift_args download $container -o - $object | md5sum | cut -f1 -d' ')
        if [ $md5sum_swift = $md5sum ]; then
                win "swift object $object in container $container has md5sum $md5sum"
        else
                fail "swift object $object in container $container has md5sum $md5sum_swift, not the expected $md5sum"
        fi
}
