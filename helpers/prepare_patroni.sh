prepare_patroni() {
	cmn_echo_info "===> Preparing patroni"
	if systemctl -q is-active patroni; then
		systemctl stop patroni
	fi

	# access to postgres user without password from root
	mkdir -p /etc/patroni/pgpass
	echo "*:*:*:postgres:$POSTGRES_SUPERUSER_PASSWORD" > /etc/patroni/pgpass/.pgpass
	chmod 600 /etc/patroni/pgpass/.pgpass
	chown -R postgres: /etc/patroni/pgpass

	if ! grep -e 'postgres /dev/watchdog' /etc/sudoers; then
		# grant permissions to /bin/chown
		echo 'postgres ALL=(ALL) NOPASSWD: /bin/chown postgres /dev/watchdog' >>/etc/sudoers
	fi

	append_text "#### Patroni ####" /etc/environment
	append_text "PGPASSFILE=/etc/patroni/pgpass/.pgpass" /etc/environment
	append_text "PATRONI_CONFIGURATION=/etc/patroni/patroni.yml" /etc/environment
	append_text "PATRONICTL_CONFIG_FILE=/etc/patroni/patroni.yml" /etc/environment
	append_text "ALLOW_NOSSL=true" /etc/environment

	# disable postgres systemd
	systemctl stop postgresql
	systemctl disable postgresql

  	envsubst < "$DIR/templates/patroni.template.yml" > /etc/patroni/patroni.yml
    envsubst < "$DIR/templates/patroni.template.service" > /etc/systemd/system/patroni.service

	systemctl daemon-reload
	systemctl enable patroni
	systemctl start patroni
}
