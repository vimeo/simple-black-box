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
logstash=0

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
-s      Enable a logstash instance to capture and index output of all probes
-v      Verbose
EOF
    exit ${1:-0}
}

while getopts "hdpsvc:" OPTION; do
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
         s)
             logstash=1
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
        ((logstash)) && set_logstash_probe
        for case in $@; do
                run_test $case
        done
else
        ((logstash)) && set_logstash_probe
        # run all tests starting with the default one
        run_test default
        shopt -s nullglob
        tests=(tests/!(default*).sh)
        shopt -u nullglob
        for t in "${tests[@]}"; do
                run_test $(basename $t .sh)
        done
fi
show_summary
((logstash)) && remove_logstash_probe_interactive
