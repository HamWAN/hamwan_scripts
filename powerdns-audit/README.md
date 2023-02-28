Audit PowerDNS for Errors
=========================

# Install
- Import audit.sql

# Examine
- `select * from audit_ns_errors;` will show NSes that are delegating authority, so should not be marked auth=true in the database.
- `select * from audit_glue_errors;` will show As that are not authoritative, just for glue, so should not be auth=true in the database.
- `select * from overloaded;` will show As that have more than one IP defined.  While overloaded IPs are not strictly errors, they can expose inconsistencies in the data.
- `select * from duplicate_records;` will show records that are duplicates and should have some redundant entries deleted.
- `generate_ns.sh` will expose authoritative domains that don't have their NSes configured properly.  Piping the output of this command to `sudo -u postgres psql powerdns` will fix the records.
