create view auth_ns_errors as select * from records where type='NS' and ((content similar to '[abc].ns.hamwan.net' and auth=false) or (content not similar to '[abc].ns.hamwan.net' and auth=true));

create view auth_glue_errors as select * from records where name in (select distinct content from records where type='NS' and auth=true) and auth=false union select * from records where name in (select distinct content from records where type='NS' and auth=false) and auth=true;

create view overloaded as select * from records where type in ('A', 'AAAA') and content in (select content from (select count(content), content from records where type in ('A', 'AAAA') group by content having count(content) > 1) as foo) order by content;

create view duplicate_records as select count(*), name, type, content from records group by name, type, content having count(*) > 1 order by name, type, content;
