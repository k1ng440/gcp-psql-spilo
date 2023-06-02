#! /bin/bash

rm -rf /tmp/timescale2.tgz
gsutil cp gs://compute_startup_scripts/timescale-us-central/timescale2.tgz /tmp/timescale2.tgz

tmpdir=$(mktemp -d)
tar zxvf /tmp/timescale2.tgz -C "$tmpdir"

cd "$tmpdir" || exit 1
chmod +x init2.sh
./init2.sh