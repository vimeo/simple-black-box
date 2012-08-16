# not much to configure.  this probe comes with a config that works with output from all other probes and does the right thing.
# this probe is different than the others. we don't really need to query any of this probe's stdout/stderr, we just want to have a better interface to other probes' events
set_logstash_probe () {
        debug "set_logstash_probe"
        logstash_cfg=${sandbox}-logstash.conf
        logstash_cmd="java -jar logstash-1.1.1-monolithic.jar agent -f $logstash_cfg -- web --backend"
        sed -e "s#__test_id__#$test_id#" -e "s#__sandbox__#$sandbox#" -e "s#__output__#$output#" -e "s#__log__#$log#" probes/logstash.conf > $logstash_cfg
        rm -rf data/elasticsearch
        # an index needs to be created right from the start (otherwise we get errors), so use stdin..
        echo starting logstash | $logstash_cmd 'elasticsearch:///?local' > $output/logstash-stdout 2> $output/logstash-stderr &
        internal=1 assert_num_procs "^$logstash_cmd" 1
}

remove_logstash_probe () {
        debug "remove_logstash_probe"
        sudo pkill -f "^$logstash_cmd"
        internal=1 assert_num_procs "^$logstash_cmd" 0
}
