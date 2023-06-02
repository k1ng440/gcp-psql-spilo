#!/bin/bash

export DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

export PGVERSION=13
export TIMESCALEDB=2.3.1
export ETCDVERSION=2.3.8
export VIP_MANAGER_VERSION=v1.0.1
export SPILO_COMMIT=49b31b40ac1f8bb78bf217746bb8b07646f716ad
export PATRONI_VERSION=v2.1.0
export WALG_VERSION=v1.0

# Filesystem
export ZPOOL_NAME="pgpool"
export ZFS_PGROOT="$ZPOOL_NAME/pgroot"
export ZFS_PG_TMP="$ZPOOL_NAME/pg_tmp" # postgresql temp
export ZFS_PG_LOG="$ZPOOL_NAME/pg_log" # postgresql log
export ZFS_SSD_TRIM="false"

export PGROOT="/$ZFS_PGROOT"
export PGDATA="$PGROOT/data"
export PG_TMP="/$ZFS_PG_TMP"
export PG_LOG="/$ZFS_PG_LOG"

export LC_ALL=en_US.utf-8
export GOROOT=/opt/go
export GOPATH=/var/go
export GOCACHE="/tmp"
export ALLOW_NOSSL=true
export WALE_ENV=/etc/patroni/wal_env
export DEBIAN_FRONTEND=noninteractive

export PATRONI_SCOPE="tsdb-production"
export WITH_ZFS="true"
while getopts ":-:" optchar; do
	[[ "${optchar}" == "-" ]] || continue
	case "${OPTARG}" in
	scope=*)
		scope=${OPTARG#*=}
		export PATRONI_SCOPE="$scope"
		;;
	no_zfs*)
		export WITH_ZFS="false"
		;;
	esac
done

#shellcheck source=config.sh
source "$DIR/config.sh"

# source all helper scripts
for file in "$DIR"/helpers/*.sh; do
	source <(cat "$file")
done

# Ensure we're running as root
cmn_assert_running_as_root

#set -ex

# system tuning
echo 0 >/proc/sys/vm/swappiness
sysctl -w vm.dirty_background_bytes=67108864 >/dev/null 2>&1
sysctl -w vm.dirty_bytes=134217728 >/dev/null 2>&1
if ! grep -qe softdog /etc/modules; then
	modprobe softdog >/dev/null 2>&1
	echo "softdog" >>/etc/modules
fi

export ZFS_POOL_DRIVES="false"
if [ $WITH_ZFS == "true" ]; then
	if compgen -G /dev/disk/by-id/google-local-nvme-ssd-* 1> /dev/null; then
		export ZFS_SSD_TRIM="true"
		export ZFS_POOL_DRIVES="/dev/nvme0n*"
	elif compgen -G /dev/disk/by-id/google-disk-* 1> /dev/null; then
		export ZFS_POOL_DRIVES="/dev/disk/by-id/google-disk-*"
	fi
fi

export BACKUP_FROM_REPLICA=false
if curl -s "http://metadata.google.internal/computeMetadata/v1/instance/attributes/backup_from_replica" -H "Metadata-Flavor: Google" | grep true; then
	export BACKUP_FROM_REPLICA=true
fi

append_path PATH "/snap/bin"
append_path PATH "/usr/lib/postgresql/$PGVERSION/bin"

mkdir -p /etc/patroni/
printf 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' >/etc/apt/apt.conf.d/01norecommend
cmn_echo_info "==> Running APT update and upgrade"
add-apt-repository universe 1> /dev/null
apt-get update -yqq 1> /dev/null
apt-get upgrade -yqq 1> /dev/null
cmn_echo_info "<== APT update and upgrade complete"

apt_install curl ca-certificates less gnupg1 nano locales jq libcap2-bin rsync git pv lzop perl

setcap 'cap_sys_nice+ep' /usr/bin/chrt
setcap 'cap_sys_nice+ep' /usr/bin/renice

if [ $WITH_ZFS != "true" ]; then
	cmn_echo_warn "** Skipping creation of ZFS pool. --no_zfs argument was provided."
	mkdir -p "$PGROOT"
	mkdir -p "$PG_TMP"
	mkdir -p "$PG_LOG"
elif [ "$ZFS_POOL_DRIVES" != "false" ]; then
	cmn_echo_info ">>>> Creating zfs pool using following drives: $ZFS_POOL_DRIVES <<<<"
	apt_install_zfs
	create_zfs_file_systems_for_postgres
else
	cmn_die ">>>>>>>>> FATAL ERROR: No drives found for ZFS. Creating directories <<<<<<<<<<<"
fi

cmn_echo_important "==> Installing Patroni with postgresql ${PGVERSION} and timescaledb ${TIMESCALEDB} <=="

if [ ! -d "/spilo" ]; then
	git_sparse_clone "https://github.com/zalando/spilo.git" "/spilo" "/postgres-appliance"
	rm -rf /spilo/.git
	mv /spilo/postgres-appliance/* /spilo && rm -rf /spilo/postgres-appliance && cd /spilo
fi

# install envsubst template renderer
install_envsubst

# add snap to PATH
if ! grep -q "snap/bin" /etc/bash.bashrc; then
	echo "" >>/etc/bash.bashrc
	echo "export PATH=$PATH:/snap/bin" >>/etc/bash.bashrc
fi

# install etcdctl
install_etcd

# Cleanup all locales but en_US.UTF-8 and optionally specified in ADDITIONAL_LOCALES arg
find /usr/share/i18n/charmaps/ -type f ! -name UTF-8.gz -delete

# Prepare find expression for locales
LOCALE_FIND_EXPR="-type f"
for loc in en_US en_GB $ADDITIONAL_LOCALES "i18n*" iso14651_t1 iso14651_t1_common "translit_*"; do
	LOCALE_FIND_EXPR="$LOCALE_FIND_EXPR ! -name $loc"
done

find /usr/share/i18n/locales/ $LOCALE_FIND_EXPR -delete

# Make sure we have the en_US.UTF-8 and all additional locales available
ensure_locales

# Add PGDG repositories
add_pgdg_repos

apt_install devscripts equivs build-essential pgxnclient fakeroot debhelper gcc libc6-dev make cmake libevent-dev libbrotli-dev libssl-dev libkrb5-dev
apt_install postgresql-common libevent-2.1 libevent-pthreads-2.1 sysstat brotli libbrotli1 python3.6 python3-psycopg2

# forbid creation of a main cluster when package is installed
sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf

# Install PostgreSQL binaries, contrib, plproxy and multiple pl's
install_postgresql
create_symlink_postgres_executables

# install go
install_go

# download pg extensions and install
install_timescaledb
tunescale_tune

# install pgbouncer
#install_pgbouncer

# Install patroni, wal-e and wal-g
install_patroni
prepare_patroni
install_walg
install_prometheus_exporter
install_node_exporter

# Clean up
cleanup_apt

append_text "PATH=\"$PATH\"" /etc/environment
append_text "WALE_ENV=$WALE_ENV" /etc/environment
append_text "LOG_ENV_DIR=/etc/patroni/log.d/env" /etc/environment
append_text "PGDATA=$PGDATA" /etc/environment
append_text "PGLOG=$PG_LOG" /etc/environment
append_text "GOROOT=$GOROOT" /etc/environment
append_text "GOPATH=$GOPATH" /etc/environment
append_text "HUMAN_ROLE=$HUMAN_ROLE" /etc/environment

## Ensure all logfiles exist, most appliances will have
## a foreign data wrapper pointing to these files
for i in $(seq 0 7); do
	if [ ! -f "${PG_LOG}/postgresql-$i.csv" ]; then
		touch "${PG_LOG}/postgresql-$i.csv"
	fi
done

mkdir -p /scripts
cp -r /spilo/scripts/* /scripts/
cp -r /spilo/bootstrap/* /scripts/
cp -r /spilo/major_upgrade/* /scripts/
cp -r $DIR/scripts/* /scripts/
chmod a+x /scripts/*.sh

cp "$DIR/credentials/gcp_credentials.json" "$GOOGLE_APPLICATION_CREDENTIALS_PATH"
chown postgres:postgres $GOOGLE_APPLICATION_CREDENTIALS_PATH

envsubst <"$DIR/templates/post_init.template.sh" >>/scripts/post_init.sh
sedeasy "../pg_log" "$PG_LOG" /scripts/post_init.sh

for num in 1 2; do
	filename="${PGROOT}/ONLY_DELETE_THIS_DUMMY_FILE_IN_A_POSTGRES_EMERGENCY_${num}"
	if [ ! -f $filename ]; then
		cmn_echo_info "==> Creating dummy file for emergency: $filename"
		dd if=/dev/zero of=$filename bs=1MB count=10000 1>/dev/null
		cmn_echo_info "<== Created dummy file: $filename"
	fi
done

chown -R postgres: "$PGROOT"
chown -R postgres: "$PG_TMP"
chown -R postgres: "$PG_LOG"

chmod -R go-w "$PGROOT"
chmod -R go-w "$PG_TMP"
chmod -R go-w "$PG_LOG"

chmod 0700 "$PGROOT"
chmod 0700 "$PG_TMP"
chmod 0700 "$PG_LOG"

create_crontab

cmn_echo_info "*** Starting Patroni ***"
systemctl start patroni

cmn_echo_info "*** Installing Taking initial backup in background *** "
sudo su postgres -c "/scripts/patroni_wait.sh -t ${INITAL_BACKUP_MAX_WAIT} -- /scripts/wale_full_backup.sh $PGDATA $WALE_BACKUP_DAYS_TO_RETAIN true" &

rm -rf "$DIR/ssh"
cd /