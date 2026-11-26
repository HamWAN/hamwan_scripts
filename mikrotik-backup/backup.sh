#!/bin/bash
# usage:
# ./hamwan_routers.sh | ./backup.sh

DIR=${DIR:-/srv/router-backup}
LIMIT=8
COMMON_OPTS="-o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -i /var/www/.ssh/id_rsa -o User=monitoring"
SCP_OPTS="$COMMON_OPTS"
SSH_OPTS="$COMMON_OPTS -n"

write_if_not_empty () {
	head=$(dd bs=1 count=1 2>/dev/null; echo a)
	head=${head%a}
	if [ "x$head" != x"" ]; then
		{ printf %s "$head"; cat; } > "$@"
	fi
}

run_ssh () {
	router=$1
	file=$2
	SSH_CMD="ssh ${SSH_OPTS} $router"

	# ROS6 and ROS7 have a different datestamp on export output.  Need to accept both.
	# ROS6 pattern: mmm/dd/yyyy hh:mm:ss
 	# ROS7 pattern: yyyy-mm-dd hh:mm:ss
	$SSH_CMD '/export hide-sensitive' \
	| sed 's![0-9a-z/-][0-9a-z/-]* [0-2][0-9]:[0-5][0-9]:[0-5][0-9]!mm/dd/yyyy hh:mm:ss!' \
	| write_if_not_empty "$file" &
}

mkdir -p "$DIR"
cd "$DIR"

while read router
do
	# A Mikrotik router can only listen on one address at a time.
	# Since we don't know whether a router is using its primary or mgmt address for ssh,
	# we try both. The one not listening will fail-fast with connection refused.
	echo Backing up "$router"... 1>&2
	run_ssh $router $router
	host "mgmt.$router" > /dev/null 2>&1
        if [ $? = 0 ]; then
		# Only try this if it exists.
		run_ssh mgmt.$router $router
	fi

	# only allow $LIMIT concurrent jobs
	until [ $(jobs -p | wc -l) -lt $LIMIT ]
	do
		sleep 1
	done
done

# wait for all jobs to complete
for job in $(jobs -p)
do
	wait $job
done

git init
git add -A
git commit -m "Auto commit."
