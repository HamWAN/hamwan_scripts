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
Constructs an IPv6 textual address from an array.
  v6_array - either array of text or array of integer, each item representing a hex value of the v6 address
  zero_pad - boolean. when true the address is zero padded
Returns
  a text object containing the address
 */
create or replace function v6_array_to_text( v6_array text[], zero_pad boolean )
  returns text
language plpgsql
as $$
declare
  retval text;
  skip_zero boolean;
  dc_appended boolean;
  word text;
BEGIN
  retval = '';
  if zero_pad THEN

    for i in 1..array_length( v6_array, 1 ) LOOP
      retval = retval || v6_array[i];
      if ( i % 4 = 0 ) and ( i < 32 ) THEN
        retval = retval || ':';
      END IF;
    END LOOP;

  ELSE

    skip_zero = true;
    dc_appended = false;
    for i in 1..array_length( v6_array, 1 ) by 4 LOOP
      word = array_to_string( v6_array[ i:i+3], '' );
      if word = '0000' THEN
        if not skip_zero THEN
          retval = retval || '0';
          if i < 28 THEN
            retval = retval || ':';
          END IF;
        ELSE
          if retval = '' THEN
            retval = ':';
          END IF;
          if not dc_appended THEN
            retval = retval || ':';
            dc_appended = true;
          END IF;
        END IF;
      ELSE
        if dc_appended THEN
          skip_zero = false;
        END IF;
        retval = retval || ltrim( word, '0' );
        if i < 28 THEN
          retval = retval || ':';
        END IF;
      END IF;
    END LOOP;

  END IF;
  return retval;
END;
$$;

/*
Creates a text array from a textual representation of an IPv6 address.
  v6 - textual representation of an IPv6 address
Returns
  a text array (text[]) with each item being a single hex character of the IPv6 address.
 */
create or replace function v6_text_to_array( v6 text )
  returns text[]
language plpgsql
as $$
DECLARE
  v6_array text[];
  arr text[];
  arr_item text;
  word_index integer;
  word_arr text[];
BEGIN
  v6_array = array_fill( '0'::text, array[ 32 ] );
  word_index = 0;
  arr = regexp_split_to_array( v6, ':' );
  if arr[ 1 ] = '' THEN
    word_arr = regexp_split_to_array( lpad( arr[ 3 ], 4, '0' ), '' );
    for i in 1..4 LOOP
      v6_array[ 28 + i ] = word_arr[i];
    END LOOP;
  ELSE
    foreach arr_item in array arr LOOP
      if not arr_item = '' THEN
        word_arr = regexp_split_to_array( lpad( arr_item, 4, '0' ), '' );
        for i in 1..4 LOOP
          v6_array[ ( word_index * 4 ) + i ] = word_arr[i];
        END LOOP;
        word_index = word_index + 1;
      ELSE
        word_index = word_index + ( 9 - array_length( arr, 1 ) );
      END IF;
    END LOOP;
  END IF;
  RETURN v6_array;
END;
$$;

/*
Constructs a zero padded IPv6 address.
 */
create or replace function v6_zero_pad( v6 text )
  returns text
language plpgsql
as $$
declare
  v6_array text[];
begin
  v6_array = v6_text_to_array( v6 );
  return v6_array_to_text( v6_array, true );
end;
$$;


/*
Constructs an unpadded IPv6 address.
 */
create or replace function v6_un_pad( v6 text )
  returns text
language plpgsql
as $$
declare
  v6_array text[];
begin
  v6_array = v6_text_to_array( v6 );
  return v6_array_to_text( v6_array, false );
end;
$$;

/*
Constructs the reverse DNS zone name from an inet object.
 */
create or replace function v6_rdns( v6 inet )
  returns text
language plpgsql
as $$
declare
  v6_array text[];
  zone_index integer;
  mask_len integer;
  retval text;
begin
  v6_array = v6_text_to_array( host(v6) );
  mask_len = masklen( v6 );
  zone_index = ( mask_len - ( mask_len % 4 ) ) / 4;
  retval = '';
  for i in 1..zone_index loop
    retval = v6_array[ i ] || '.' || retval;
  END LOOP;
  retval = retval || 'ip6.arpa';
  return retval;
end;
$$;
