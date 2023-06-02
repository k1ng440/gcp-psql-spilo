function configure_pgqd() {
	systemctl enable pgqd
	service pgqd stop
    envsubst < $DIR/templates/pgqd.template.ini > /etc/pgqd.ini
    service pgqd start
}


