Deprecated
==========

This script parses the AMPR encap file to generate routes. With the release of
the AMPR API, this is no longer necessary. A new version of this script that
utilizes the AMPR API is available at
https://github.com/kd7lxl/python-amprapi/.
Maintenance efforts will be focused on the new
[python-amprapi](https://github.com/kd7lxl/python-amprapi).


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