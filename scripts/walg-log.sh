#!/usr/bin/env bash

function log() {
  echo "$(date "+%Y-%m-%d %H:%M:%S.%3N") - $0 - $*"
  echo "$(date "+%Y-%m-%d %H:%M:%S.%3N") - $0 - $*" >> /var/log/postgresql/walg.log
}
