HamWAN SSH Blacklister
=============

Parses centralized syslogging and pushes updates to the firewall blacklists to block blatent scanners.

Usage
-----

Requires username on script host (where logs are located) and firewalls to match.
Requires your system to be running ssh-agent with valid keys granting login to script host and firewalls

	ssh -A username@scripthost "/path/to/script"
