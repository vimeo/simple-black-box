# $1 local file
# $2 expected md5sum
assert_file_md5sum () {
        local file="$1"
        local md5sum=$2
        [ -n "$file" -a -f "$file" -a -r "$file" ] || die_error "assert_file_md5sum() \$1 must be a readable file, not '$1'"
        [ ${#md5sum} -eq 32 ] || die_error "assert_file_md5sum() \$2 must be an md5sum of 32 characters, not '$2'"
        local md5_real=$(md5sum "$file" | cut -d' ' -f1)
        if [ $md5_real = $md5sum ]; then
                win "file '$file' has md5sum $md5sum"
        else
                fail "file '$file' has md5sum $md5_real, not $md5sum"
        fi
}
