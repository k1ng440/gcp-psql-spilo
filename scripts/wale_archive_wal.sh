#!/bin/bash

source /etc/wal-e.d/env.sh
source /scripts/walg-log.sh

readonly wal_path=$1

log "arguments: $*. running wal-g wal-push $wal_path"
nice -n 19 /usr/bin/wal-g wal-push "$wal_path"
