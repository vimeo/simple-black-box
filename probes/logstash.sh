# not much to configure.  this probe comes with a config that works with output from all other probes and does the right thing.
# this probe is different than the others. we don't really need to query any of this probe's stdout/stderr, we just want to have a better interface to other probes' events
# it's also different because you're allowed to keep logstash running after SBB completes. also, we need to remove any existing probe before starting a new one
set_logstash_probe () {
        debug "set_logstash_probe"
        logstash_cfg=$prefix-logstash.conf
        logstash_cmd="java -jar logstash-1.1.1-monolithic.jar agent -f $logstash_cfg --grok-patterns-path logstash-patterns -- web --backend"
        sed -e "s#__project__#$project#" -e "s#__prefix__#$prefix#" probes/logstash.conf > $logstash_cfg
        rm -rf data/elasticsearch
        remove_logstash_probe
        internal=1 assert_listening "tcp:9292" 0 0 # port must be available for use
        # an index needs to be created right from the start (otherwise we get errors), so use stdin.
        echo starting logstash at $(date) | $logstash_cmd 'elasticsearch:///?local' > $prefix-logstash-stdout 2> $prefix-logstash-stderr &
        internal=1 assert_num_procs "^$logstash_cmd" 1
        echo "sleeping 30s to let logstash stabilize. sorry about that..."
        sleep 30
        internal=1 assert_num_procs "^$logstash_cmd" 1
}

remove_logstash_probe () {
        debug "remove_logstash_probe"
        pkill -f "^$logstash_cmd"
        internal=1 assert_num_procs "^$logstash_cmd" 0
}

remove_logstash_probe_interactive () {
        echo "press enter to kill logstash instance. ^C to exit, leaving logstash instance running"
        read
        remove_logstash_probe
}
