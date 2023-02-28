#!/bin/bash
unhealthy_sql="
select
   name as unhealthy
from
   domains 
where
   name not in 
   (
      select
         name 
      from
         (
            select
               domains.name,
               count(records.id) 
            from
               domains,
               records 
            where
               domains.type = 'MASTER' 
               and records.domain_id = domains.id 
               and records.name = domains.name 
               and records.type = 'NS' 
               and records.content in 
               (
                  'a.ns.hamwan.net',
                  'b.ns.hamwan.net',
                  'c.ns.hamwan.net'
               )
               and records.auth = true 
               and records.disabled = false 
            group by
               domains.name
         )
         as healthy 
      where
         count = 3
   )
;
"

for domain in $(sudo -u postgres psql powerdns -1 -t -c "$unhealthy_sql")
do
    id=$(sudo -u postgres psql powerdns -1 -t -c "select id from domains where name = '$domain'")
    for ns in a.ns.hamwan.net b.ns.hamwan.net c.ns.hamwan.net
    do
        echo "INSERT INTO records (domain_id, name, type, content, auth) VALUES ($id, '$domain', 'NS', '$ns', true);"
    done
done
