#!/bin/bash

# startup checks
if [ -z "$BASH" ]; then
  echo "Please use BASH."
  exit 3
fi
if [ ! -e "/usr/bin/which" ]; then
  echo "/usr/bin/which is missing."
  exit 3
fi
openssl=$(which openssl)
if [ $? -ne 0 ]; then
  echo "Please install openssl"
  exit 3
fi

# Usage Info
usage() {
  echo '''
  Usage: check_snmp [OPTIONS]
  [OPTIONS]
  -u URL             URL
  -p PORT            Port (default: 443)
  -w WARNING         Days left threshold for warning (default: 5)
  -c CRITICAL        Days left threshold for critical (default: 1)
  -o Output Only     Only returns days left
  '''
}

port=443
warning=5
critical=1

#get options
while getopts "p:u:w:c:o" opt; do
  case $opt in
    p)
      port=$OPTARG
      ;;
    u)
      url=$OPTARG
      ;;
    w)
      warning=$OPTARG
      ;;
    c)
      critical=$OPTARG
      ;;
    o)
      outputonly=1
      ;;
    *)
      usage
      exit 3
      ;;
  esac
done


if [ -z "$url" ]; then
  echo "Error: url is required"
  usage
  exit 3
fi

openssl=$(echo | openssl s_client -showcerts -servername $url -connect $url:$port 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "openssl did not return 0 - check domain name or run 'openssl s_client -showcerts -servername $1 -connect $1:443' for more details why"
  exit 3
fi
notafter=$(echo "$openssl" | openssl x509 -inform pem -noout -text | grep "Not After")
notafter=$(echo $notafter | sed "s/Not After\s:\s//")
notafter=$(date -d "${notafter}" +%s)
now=$(date -d now +%s)

daysleft=$(( (notafter - now) / 86400 ))

if [[ $outputonly -eq 1 ]] ; then
  echo $daysleft
else
  if [ $critical -ge $daysleft ]; then
    echo "CRITICAL: Certificate is only valid for another $daysleft days"
    exit 2
  fi
  if [ $warning -ge $daysleft ]; then
    echo "WARNING: Certificate is only valid for another $daysleft days"
    exit 1
  fi
  echo "OK: Certificate still valid for $daysleft days"
  exit 0
fi
