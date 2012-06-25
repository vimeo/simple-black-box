# $1 local file
# $2 expected md5sum
assert_file_md5sum () {
        local file=$1
        local md5sum=$2
        local md5_real=$(md5sum $file | cut -d' ' -f1)
        if [ $md5_real = $md5sum ]; then
                win "file $file has md5sum $md5sum"
        else
                fail "file $file has md5sum $md5_real, not $md5sum"
        fi
}
