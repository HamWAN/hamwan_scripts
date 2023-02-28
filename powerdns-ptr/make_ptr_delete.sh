#!/bin/bash

#  action |   id   | domain_id |                                   name                                   | type |                    content                    | ttl | prio | change_date | ordername | auth | disabled 
# --------+--------+-----------+--------------------------------------------------------------------------+------+-----------------------------------------------+-----+------+-------------+-----------+------+----------

IDs=$(echo "select string_agg(id::text, ',') from arpa_delete;" | sudo -u postgres psql -1Aqt powerdns)
echo "DELETE FROM records WHERE id IN ($IDs);"
