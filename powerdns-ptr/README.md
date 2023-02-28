Automatic PTR Management in PowerDNS
====================================

# Install
- Import v4_functions.sql and v6_functions.sql from https://github.com/arineng/pg_ipaddr_utils.git or from the pg_ipaddr_utils subdirectory here.
- Import arpa.sql.

# Examine
- `select * from arpa_insert;` will tell you which PTRs want to be inserted.
- `select * from arpa_delete;` will tell you which PTRs want to be deleted.

# Enforce
- `make_ptr_insert.sh | sudo -u postgres psql powerdns`
- `make_ptr_delete.sh | sudo -u postgres psql powerdns`
