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

mkdir -p "$DIR"
cd "$DIR"

while read router
do
	echo Backing up "$router"... 1>&2
	SSH_CMD="ssh ${SSH_OPTS} $router"

	# ROS6 and ROS7 have a different datestamp on export output.  Need to accept both.
	# ROS6 pattern: mmm/dd/yyyy hh:mm:ss
 	# ROS7 pattern: yyyy-mm-dd hh:mm:ss
	$SSH_CMD '/export hide-sensitive' \
	| sed 's![0-9a-z/-][0-9a-z/-]* [0-2][0-9]:[0-5][0-9]:[0-5][0-9]!mm/dd/yyyy hh:mm:ss!' \
	| write_if_not_empty "$router" &

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
