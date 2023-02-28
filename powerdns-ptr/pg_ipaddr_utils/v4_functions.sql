/*
Copyright (C) 2017 American Registry for Internet Numbers (ARIN)

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

/*
Constructs an IPv4 textual address from an array.
  v4_array - either array of text or array of integer, each item representing an octet of the v4 address
  zero_pad - boolean. when true the address is zero padded
Returns
  a text object containing the address
 */
create or replace function v4_array_to_text( v4_array anyarray, zero_pad boolean )
  returns text
language plpgsql
as $$
BEGIN
  if zero_pad THEN
    return lpad( v4_array[1]::text, 3, '0'::text ) || '.'
        || lpad( v4_array[2]::text, 3, '0'::text ) || '.'
        || lpad( v4_array[3]::text, 3, '0'::text ) || '.'
        || lpad( v4_array[4]::text, 3, '0'::text );
  END IF;
  -- else
  return v4_array[1] || '.' || v4_array[2] || '.' || v4_array[3] || '.' || v4_array[4];
END;
$$;

/*
Constructs a zero padded IPv4 address.
 */
create or replace function v4_zero_pad( v4 text )
  returns text
language plpgsql
as $$
declare
  v4_array text[];
begin
  v4_array = regexp_split_to_array( v4, '\.' );
  return v4_array_to_text( v4_array, true );
end;
$$;


/*
Constructs an unpadded IPv4 address.
 */
create or replace function v4_un_pad( v4 text )
  returns text
language plpgsql
as $$
declare
  v4_old text[];
  v4_new integer[];
  i integer;
begin
  v4_old = regexp_split_to_array( v4, '\.' );
  foreach i in array v4_old loop
    v4_new = array_append( v4_new, i );
  end loop;
  return v4_array_to_text( v4_new, false );
end;
$$;

/*
Constructs the reverse DNS zone name from an inet object.
 */
create or replace function v4_rdns( v4 inet )
  returns text
language plpgsql
as $$
declare
  v4_array text[];
  zone_index integer;
  mask_len integer;
  retval text;
begin
  v4_array = regexp_split_to_array( host(v4), '\.' );
  mask_len = masklen( v4 );
  zone_index = ( mask_len - ( mask_len % 8 ) ) / 8;
  retval = '';
  for i in 1..zone_index loop
    retval = v4_array[ i ] || '.' || retval;
  END LOOP;
  retval = retval || 'in-addr.arpa';
  return retval;
end;
$$;
