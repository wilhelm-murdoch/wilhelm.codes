#!/usr/bin/env bash

SOURCE=${SOURCE:="${1}"}
export SOURCE

DESTINATION=${DESTINATION:="${2}"}
export DESTINATION

fswatch -o "${SOURCE}" | while read -r event; do 
    rsync -av --delete "${SOURCE}" "${DESTINATION}";
done