#!/bin/bash
IP="$(curl -s icanhazip.com)"
sed -i "s/console/console +ip ${IP}/g" /lib/systemd/system/csgo.service
