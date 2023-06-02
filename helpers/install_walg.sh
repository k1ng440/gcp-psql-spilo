function install_walg() {
	if [ -f "/usr/bin/wal-g" ]; then
		EV=$(wal-g --version | grep -Po '(?<=wal-g version )[^\s]+')
		if [ "$WALG_VERSION" == "$EV" ]; then
			cmn_echo_info "*** wal-g $EV is already installed. Skipping"
			return
		fi

		cmn_echo_warn "==> wal-g version mismatched. wanted: $WALG_VERSION, installed: $EV. Installing"
 	else
 		cmn_echo_info "==> Installing and configuring wal-g"
	fi


	DISTRIB_ID=$(sed -n 's/DISTRIB_ID=//p' /etc/lsb-release | awk '{print tolower($0)}')
	DISTRIB_VERSION=$(sed -n 's/DISTRIB_RELEASE=//p' /etc/lsb-release)
	FILENAME="wal-g-pg-$DISTRIB_ID-$DISTRIB_VERSION-amd64"

	wget -q https://github.com/wal-g/wal-g/releases/download/$WALG_VERSION/$FILENAME.tar.gz
	tar -zxf $FILENAME.tar.gz
	rm $FILENAME.tar.gz
	chmod +x $FILENAME
	mv $FILENAME /usr/bin/wal-g

	mkdir -p /etc/wal-e.d
	echo >/etc/wal-e.d/env.sh
	echo >/etc/wal-e.d/envexec.sh

	{
		echo '#!/bin/bash'
		echo "export USE_WALG_BACKUP=true"
		echo "export WALG_BACKUP_COMPRESSION_METHOD=lz4"
		echo "export USE_WALG_RESTORE=true"
		echo "export GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIALS_PATH"
		echo "export TMPDIR=$PGDATA/tmp"
		echo "export WALG_GS_PREFIX=$WALE_GS_PREFIX"
		echo "export USE_WALG=true"
		echo "export WALG_LOG_DESTINATION=stderr,syslog"
		echo "export WALG_DOWNLOAD_CONCURRENCY=$(grep -c ^processor /proc/cpuinfo)"
		echo "export WALG_UPLOAD_CONCURRENCY=$(($(grep -c ^processor /proc/cpuinfo) / 2))"
		echo "export WALG_COMPRESSION_METHOD=lz4"
		echo "export PGHOST=/var/run/postgresql"
	} >>/etc/wal-e.d/env.sh

	{
		echo '#!/bin/bash'
		echo ""
		echo "source /etc/wal-e.d/env.sh"
		echo ""
		echo 'exec "$@"'
	} >>/etc/wal-e.d/envexec.sh

	chmod +x /etc/wal-e.d/envexec.sh
	chmod +x /etc/wal-e.d/env.sh

	if [ ! -s "/var/log/postgresql/walg.log" ]; then
		echo >/var/log/postgresql/walg.log
	fi

	chown -R postgres:postgres /var/log/postgresql
	cmn_echo_info "<== wal-g has been installed and configured"
}
