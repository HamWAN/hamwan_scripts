#!/usr/bin/env python
#
# Copyright 2014 Tom Hayward <tom@tomh.us>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

from difflib import unified_diff
import subprocess
import sys


def filter_comments(l):
    return filter(lambda x: not x.startswith("#"), l)


def usage():
    print "Usage:", sys.argv[0], "FILE", "HOSTNAMES...", "COMMAND"
    print
    print "FILE\tCompare output to the contents of this file."
    print "HOSTNAMES\tHost to query and compare"
    print "COMMAND\tCommand sent to host. This should match the command used to"
    print "\tgenerate FILE."
    print
    print "ROS comments (lines beginning with #), it will be ignored."
    sys.exit()


def main():
    if len(sys.argv) < 4 or "-h" in sys.argv[1:] or "--help" in sys.argv[1:]:
        usage()
    
    with open(sys.argv[1], 'r') as f:
        verify = filter_comments([line.rstrip() for line in f])

    command = sys.argv.pop()
    hosts = sys.argv[2:]

    processes = []
    for host in hosts:
        ssh = subprocess.Popen(['ssh', host, command], stdout=subprocess.PIPE)
        processes.append((host, ssh))

    for host, ssh in processes:
        if ssh.wait() != 0:
            print host, "failed"
            continue

        reply = filter_comments(ssh.stdout.read().splitlines())

        if verify == reply:
            print host, "matched"
        else:
            for line in unified_diff(verify, reply, fromfile='verify', tofile=host):
                print line


if __name__ == "__main__":
    main()
