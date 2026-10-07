#!/bin/bash
# Returns a list of HamWAN Mikrotik routers from the HamWAN portal
json=$(curl -s https://encrypted.hamwan.org/host/ansible.json)
hamwan=$(jq -r '.owner_HamWAN[]' <<< "$json" | grep "^  " | sed -e 's/.*"\(.*\)".*/\1/' | sort -u)
routeros=$(jq -r '.os_routeros[]' <<< "$json" | grep "^  " | sed -e 's/.*"\(.*\)".*/\1/' | sort -u)
comm -12 <(echo "$hamwan") <(echo "$routeros") | sort -R
