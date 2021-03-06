#!/bin/bash
#
# Based on available sizes in FRA1 region - update slug in Terraform main
# Takes in DO_PAT token and `sed`s main.tf with first available of optimal sizes


SIZES=("s-4vcpu-8gb-amd" "s-4vcpu-8gb-intel" "c-4")
# s-4vcpu-8gb-amd      AMD w/ NVMe          8 GB / 4 CPUs    $48
# s-4vcpu-8gb-intel    Intel w/ NVMe        8 GB / 4 CPUs    $48
# c-4                  Compute-optimized    8 GB / 4 CPUs    $80

AVAILABLE=$(curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${1}" "https://api.digitalocean.com/v2/regions" | jq '.regions[] | select(.slug=="fra1") .sizes')
for size in "${SIZES[@]}"; do
   if [[ "$(echo "${AVAILABLE}" | grep "${size}")" != "" ]]; then
      TARGET=${size}
      break
  fi
done

echo "Targeting: ${size} \o/"
sed -i "s/UPDATESLUG/${TARGET}/g" main.tf

