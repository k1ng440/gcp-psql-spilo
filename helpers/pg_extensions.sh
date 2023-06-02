function install_timescaledb() {
	if [ ! -f "/usr/share/postgresql/$PGVERSION/extension/timescaledb.control" ]; then
		cmn_echo_info "==> Installing timescaledb"
		curl -s https://packagecloud.io/install/repositories/timescale/timescaledb/script.deb.sh | sudo bash
		TIMESCALEDB_MV=$(echo $TIMESCALEDB | awk -F. '{print $1}')
		apt_install timescaledb-tools "timescaledb-$TIMESCALEDB_MV-$TIMESCALEDB-postgresql-$PGVERSION"
		cmn_echo_info "<== Installed timescaledb"
	else
		cmn_echo_info "*** timescaledb already exists. Skipping"
	fi
}
