#!/bin/bash

domain="bozas6.com"                       # your domain
type="A"                                    # Record type A, CNAME, MX, etc.
name="csgo"                                  # name of record to update
ttl="600"                                  # Time to Live min value 600
port="1"                                    # Required port, Min value 1
key="$GODADDY_KEY"            # key for godaddy developer API
secret="$GODADDY_SECRET"         # secret for godaddy developer API

headers="Authorization: sso-key $key:$secret"

newIp="$1"
echo "newIp:" $newIp

curl -X PUT "https://api.godaddy.com/v1/domains/$domain/records/$type/$name" \
	-H "accept: application/json" \
	-H "Content-Type: application/json" \
	-H "$headers" \
	-d "[ { \"data\": \"$newIp\", \"port\": $port, \"priority\": 0, \"protocol\": \"string\", \"service\": \"string\", \"ttl\":600, \"weight\": 0 }]"