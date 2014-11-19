amprupdate.py
=============

Reads AMPR encap format from stdin and update the target Mikrotik router with
new, removed, or changed routes from the encap.

Usage
-----

	cat encap.txt | ./amprupdate.py [-v] [-n] [-f] TARGET_IP

`-f` force. Continue even when sanity check fails.

`-n` dry-run. No changes will be made to target router.

`-v` verbose mode. Commands to target router will be printed.