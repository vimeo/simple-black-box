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
usage: $0 options

simple black box behavior tester

OPTIONS:
-h      Show this message
-d      show debug info
-p      Pause at each fail, to allow for manual inspection
-v      Verbose
EOF
    exit ${1:-0}
}

while getopts "hdpv" OPTION; do
     case $OPTION in
         h)
             usage
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
source config.sh

# run all tests that can run on their own
for t in tests/!(generic_*); do
        run_test $(basename $t .sh)
done
