#!/usr/bin/php5
<?php
        $grep_string = "login failure for user root";
        $grep_log = "/srv/log/HamWAN/Unfiltered.log";

        $tmp_file = "/tmp/ssh_blacklister.tmp";

        $hamwan_edges = array("198.178.136.80", "209.189.196.68");
        $hamwan_blacklist = "blockscanners";
        $hamwan_blacklist_time = "1d";

        // Check for log entries showing root login failures. Hint, root shouldn't be a valid user.
        exec("grep \"" . $grep_string . "\" " . $grep_log, $output);

        // Check if there's actually any log entries we got back
        if(count($output) > 0){
                // Check if our tmp file exists. If it does, read the contents to figure out if our current entry is new to us.
                // If it doesn't exist yet, then it will be created later.
                $last_time = 0;
                if(file_exists($tmp_file)){
                        $last_time = file_get_contents($tmp_file);
                }

                // Explode the grep output to get our data
                $output = explode(",", $output[count($output)-1]);

                // Grab the time out of the output
                $time = explode(" ", $output[2]);
                $time = $time[2];
                $time = strtotime($time);

                // Grab the offending IP out of the output
                $ip = explode(" ", $output[8]);
                $ip = $ip[7];

                // Check if our current time is greater than our last time, if so, it's new and we need to push to the edges
                if($time > $last_time){
                        // Open a logging connection
                        openlog("sshBlacklister", LOG_PID | LOG_PERROR, LOG_LOCAL0);

                        // It's new, lets push the IP to the edge FW's blacklist
                        foreach($hamwan_edges as $value){
                                // Push the FW update out.
                                exec("ssh -A " . $value . " \"/ip firewall address-list add list=".$hamwan_blacklist." timeout=".$hamwan_blacklist_time." address=".$ip."\"", $output);

                                // Log that we've done so
                                syslog(LOG_INFO, "Added " . $ip . " to blacklist on router at " . $value . " due to failed login attempts.");

                                // And print a message locally
                                echo("Adding " . $ip . " to blacklist on router at " . $value . "\n");
                        }
                        closelog();

                        // Update the last time to the current time
                        file_put_contents($tmp_file, $time);
                }else{
                        echo("Nothing new to add.\n");
                }

                //echo($time . " - " . strtotime("now") . " - " . (strtotime("now") - $time) . "\n");
                //echo($ip . "\n");
                //print_r($output);
        }
?>
