# $1 config file
# $2 key 
# $3 value. for strings, don't forget to wrap in quotes (example: '"koekoek"' )
json_change_var () {
        local file="$1"
        local key=$2
        local value="$3"
        [ -n "$file" -a -f "$file" ] || die_error "json_change_var \$1 must be the config file, not '$1'"
        [ -n "$key" ] || die_error "json_change_var \$2 must be a non-zero config key, not '$2'"
        [ -n "$value" ] || die_error "json_change_var \$3 must be a non-zero new config value, not '$3'"
        value=${value//#/\\#} # escape delimiter for below sed expression.
        sed -i "s#^\"$key\": .*#\"$key\": $value,#" "$file"
        json_debug_var "$file" $key
}

# $1 config file
# $2 key 
json_remove_var () {
        local file="$1"
        local key=$2
        [ -n "$file" -a -f "$file" ] || die_error "json_remove_var \$1 must be the config file, not '$1'"
        [ -n "$key" ] || die_error "json_remove_var \$2 must be a non-zero config key, not '$2'"
        sed -i "/^\"$key\": /d" "$file"
        json_debug_var "$file" $key
}

# $1 config file
# $2 key 
# return the full json definition
json_debug_var () {
        local file=$1
        local key=$2
        [ -n "$file" -a -f "$file" ] || die_error "json_debug_var \$1 must be the config file, not '$1'"
        [ -n "$key" ] || die_error "json_debug_var \$2 must be a non-zero config key, not '$2'"
        debug "json $file $key : $(grep "^\"$key\": " "$file")"
}

# $1 config file
# $2 key 
# get the value of the variable, assuming it's a string.
json_get_var_string () {
        local file=$1
        local key=$2
        [ -n "$file" -a -f "$file" ] || die_error "json_get_var_string \$1 must be the config file, not '$1'"
        [ -n "$key" ] || die_error "json_get_var_string \$2 must be a non-zero config key, not '$2'"
        grep "^\"$key\":" "$file" | sed 's/.*"\([^"]*\)",\?$/\1/'
}

# $1 config file
# $2 key
# get the value of the variable, assuming it's a number.
json_get_var_number () {
        local file=$1
        local key=$2
        [ -n "$file" -a -f "$file" ] || die_error "json_get_var_string \$1 must be the config file, not '$1'"
        [ -n "$key" ] || die_error "json_get_var_string \$2 must be a non-zero config key, not '$2'"
        grep "^\"$key\":" "$file" | cut -d' ' -f2 | sed 's/,$//'
}
