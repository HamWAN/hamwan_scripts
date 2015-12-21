# http://stackoverflow.com/questions/16659197/how-to-sign-a-clients-csr-with-openssl
if [ $# -ne 2 ]
then
	echo "Usage: sign.sh <CALLSIGN> <SUBJECT LINE>"
	echo
	echo "Example: sign.sh K7VE \"/C=US/ST=Washington/L=Edmonds/O=Puget Sound Data Ring/CN=K7VE\""
else
	openssl ca -config openssl.cnf -in "${1}.csr" -out "${1}.pem" -days 3650 -subj "${2}"
fi
