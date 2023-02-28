#!/bin/bash

#  action | domain_id |                                   name                                   | type |                      content                       | ttl  | prio | change_date | ordername | auth | disabled 
# --------+-----------+--------------------------------------------------------------------------+------+----------------------------------------------------+------+------+-------------+-----------+------+----------

echo "BEGIN;"
IFS="|"
echo -e "\\pset null NULL\nselect * from arpa_insert;" | sudo -u postgres psql -1Aqt powerdns | while read -a fields
do
    ordername="${fields[8]}"
    if [[ "$ordername" != "NULL" ]]
    then
        ordername="'$ordername'"
    fi
    echo "INSERT INTO records (domain_id, name, type, content, ttl, prio, change_date, ordername, auth, disabled) VALUES (${fields[1]}, '${fields[2]}', '${fields[3]}', '${fields[4]}', ${fields[5]}, ${fields[6]}, ${fields[7]}, $ordername, '${fields[9]}', '${fields[10]}');"
done
echo "COMMIT;"
