#!/bin/bash

source /etc/wal-e.d/env.sh
source /scripts/walg-log.sh

readonly wal_filename=$1
readonly wal_destination=$2

[[ -z $wal_filename || -z $wal_destination ]] && exit 1

log "arguments: $*. running wal-g wal-fetch $wal_filename $wal_destination"

/usr/bin/wal-g wal-fetch $wal_filename $wal_destination
