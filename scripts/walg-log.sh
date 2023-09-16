#!/usr/bin/env bash

function log() {
  echo "$(date "+%Y-%m-%d %H:%M:%S.%3N") - $0 - $*" | tee -a /var/log/postgresql/walg.log
}
