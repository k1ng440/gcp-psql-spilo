function create_crontab() {
	cmn_echo_info "==> Setting up cronjob"

	{
		echo "$WALE_BACKUP_SCHEDULE /scripts/patroni_wait.sh -t $WALE_SCHEDULE_BACKUP_MAXIMUM_WAIT -i 10 -r master -- /scripts/wale_full_backup.sh $PGDATA $WALE_BACKUP_DAYS_TO_RETAIN"
		echo "* * * * * bash /scripts/reprioritize_archival.sh"
		echo "@daily /usr/bin/echo > /var/log/postgresql/pg.log"
		echo "@daily /usr/bin/rm -f /var/log/postgresql/pg.1*.log.gz"
	} > mycron

	crontab -u postgres mycron
	rm mycron
	cmn_echo_info "<== cronjob setup complete"
}