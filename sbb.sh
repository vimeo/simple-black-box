#!/bin/bash

source /usr/lib/libui.sh
source /usr/lib/libui-colors.sh
for f in lib/*.sh inputs/*.sh probes/*.sh; do
        source $f
done
shopt -s extglob

# you can use this variable to communicate from functions to the main scope,
# without putting the function in a subshell, so that it can exit the process
# in error conditions (die_error)
return=
debug=0
verbose=0
pause=0

# $1 exit code (default: 0)
usage() {
    cat << EOF
usage: $0 options [case1 [case2 [...]]]

simple black box behavior tester
if no cases are specified, will run them all

OPTIONS:
-h      Show this message
-d      show debug info
-p      Pause at each fail, to allow for manual inspection
-v      Verbose
EOF
    exit ${1:-0}
}

while getopts "hdpvc:" OPTION; do
     case $OPTION in
         h)
             usage
             ;;
         c)
             config="$OPTARG"
             ;;
         d)
             debug=1
             ;;
         p)
             pause=1
             ;;
         v)
             verbose=1
             ;;
         ?)
             usage 2
             ;;
     esac
done

### RUN ###
[ -r "$config" ] || die_error "must have a config file (with -c <config>), not '$config'"
source "$config" || die_error "failed to source config $config"
[ -n "$project" ] || die_error "\$project must be set to the name of your project"
[ -d "$src" ] || die_error "\$src must be set to a directory containing your project, not '$src'"

shift $(($OPTIND-1))
if [ $# -gt 0 ]; then
        for case in $@; do
                [ -n "$case" -a -f "tests/$case.sh" ] || die_error "no such testcase: $case"
        done
        for case in $@; do
                run_test $case
        done
else
        # run all tests that can run on their own, starting with the default one
        run_test default
        for t in tests/!(generic_*|default).sh; do
                run_test $(basename $t .sh)
        done
fi
show_summary
