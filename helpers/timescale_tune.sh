function tunescale_tune() {
	cmn_echo_info "===> Running timescaledb-tune on ${PGROOT}/postgres.base.conf"
	envsubst < $DIR/templates/postgres.base.template.conf > $PGROOT/postgres.base.conf
	chown postgres:postgres $PGROOT/postgres.base.conf
	timescaledb-tune -yes -quiet -pg-version $PGVERSION -conf-path $PGROOT/postgres.base.conf 2>&1 > $PGROOT/timescaledb-tune-output
	cmn_echo_info "<=== timescaledb-tune complete. wrote output to $PGROOT/timescaledb-tune-output"
}