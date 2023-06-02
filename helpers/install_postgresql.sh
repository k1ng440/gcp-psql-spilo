function install_postgresql() {
	cmn_echo_important ">>>>> Installing PostgreSQL"

	# Install PostgreSQL binaries, contrib, plproxy and multiple pl's
	apt_install skytools3-ticker
	apt_install postgresql-${PGVERSION} postgresql-contrib-${PGVERSION} \
		postgresql-plpython3-${PGVERSION} postgresql-server-dev-${PGVERSION} \
		postgresql-${PGVERSION}-cron postgresql-${PGVERSION}-pgq3 \
		postgresql-${PGVERSION}-pg-stat-kcache postgresql-${PGVERSION}-pgaudit \
		postgresql-${PGVERSION}-plpgsql-check

	sed -i "s/ main.*$/ main/g" /etc/apt/sources.list.d/pgdg.list
	apt-get update -yqq 1> /dev/null
	apt_install postgresql-server-dev-${PGVERSION} libpq-dev libevent-dev

	cmn_echo_important "<<<<< Installed PostgreSQL"
}
