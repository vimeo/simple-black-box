# $1 config file
# $2 key 
# $3 value. for strings, don't forget to wrap in quotes (example: '"koekoek"' )
json_change_var () {
        local file=$1
        local key=$2
        local value=$3
        value=${value//#/\\#} # escape delimiter for below sed expression.
        sed -i "s#^\"$key\": .*#\"$key\": $value,#" $file
        json_debug_var $file $key
}

# $1 config file
# $2 key 
json_remove_var () {
        local file=$1
        local key=$2
        sed -i "/^\"$key\": /d" $file
        json_debug_var $file $key
}

# $1 config file
# $2 key 
# return the full json definition
json_debug_var () {
        local file=$1
        local key=$2
        debug "json $file $key : $(grep "^\"$key\": " $file)"
}

# $1 config file
# $2 key 
# get the value of the variable, assuming it's a string.
json_get_var_string () {
        local file=$1
        local key=$2
        grep "^\"$key\":" $file | sed 's/.*"\([^"]*\)",\?$/\1/'
}

# $1 config file
# $2 key
# get the value of the variable, assuming it's a number.
json_get_var_number () {
        local file=$1
        local key=$2
        grep "^\"$key\":" "$file" | cut -d' ' -f2 | sed 's/,$//'
}
