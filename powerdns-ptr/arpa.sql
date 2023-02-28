create or replace function v10_rdns( v10 inet )
  returns text
language plpgsql
as $$
begin
  if family(v10) = 4 then
    return v4_rdns(v10);
  elsif family(v10) = 6 then
    return v6_rdns(v10);
  else
    raise notice 'Unsupported inet address family';
  end if;
end;
$$;

create view arpa as select *, v10_rdns(content::inet) as arpa from records where type in ('A', 'AAAA');

create view arpa_insert as select distinct 'insert'::varchar(10) as action, domains.id as domain_id, arpa.arpa as name, 'PTR'::varchar(10) as type, arpa.name as content, arpa.ttl as ttl, arpa.prio as prio, arpa.change_date as change_date, arpa.ordername as ordername, arpa.auth as auth, arpa.disabled as disabled from arpa left outer join records on arpa.arpa = records.name inner join domains on arpa.arpa like concat('%.', domains.name) or arpa.arpa = domains.name where records.id is null or (records.type = 'PTR' and arpa.name not in (select content from records where type='PTR' and name=arpa.arpa)) order by domain_id, name;

create view arpa_delete as select 'delete'::varchar(10) as action, records.* from records left outer join arpa on records.content = arpa.name where records.type = 'PTR' and arpa.id is null order by domain_id, name;
