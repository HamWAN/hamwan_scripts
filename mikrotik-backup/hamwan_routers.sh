#!/bin/bash
# Returns a list of HamWAN Mikrotik routers from the HamWAN portal
json=$(curl -s https://encrypted.hamwan.org/host/ansible.json)
hamwan=$(jq -r '.owner_HamWAN[]' <<< "$json" | sort -u)
routeros=$(jq -r '.os_routeros[]' <<< "$json" | sort -u)
comm -12 <(echo "$hamwan") <(echo "$routeros") | sort -R
