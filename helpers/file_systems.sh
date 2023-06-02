function apt_install_zfs() {
	apt_install zfsutils-linux liblzo2-dev
}

function create_zfs_file_systems_for_postgres() {
	cmn_echo_info "==> checking zpool status"
	if zpool status -x "${ZPOOL_NAME}" | grep -q healthy; then
		cmn_echo_info "*** ZFS file system already exists and healthy. Skipping"
	else
		restart_zfs_services
		cmn_echo_info "==> Creating ZFS file system"

		DISKS=""
		for d in $ZFS_POOL_DRIVES; do
			/usr/sbin/wipefs -a "$d"
			DISKS+="$d "
		done

		cmn_echo_info "==> Creating zpool using $DISKS"

		bash -c "$(/sbin/zpool create -o ashift=12 -f ${ZPOOL_NAME} ${DISKS})"

		zfs create $ZFS_PGROOT -o xattr=sa -o atime=off -o relatime=on -o compression=lz4 -o canmount=on -o recordsize=8k -o logbias=throughput -o mountpoint=$PGROOT
		zfs create $ZFS_PG_TMP -o xattr=sa -o quota=5G -o compression=lz4 -o atime=off -o relatime=on -o logbias=throughput -o mountpoint=$PG_TMP
		zfs create $ZFS_PG_LOG -o xattr=sa -o quota=5G -o compression=lz4 -o atime=off -o relatime=on -o logbias=throughput -o mountpoint=$PG_LOG

		cmn_echo_info "<== ZFS file system has been created successfully."
	fi
}

function restart_zfs_services() {
	ensure_zfs_metadata

	cmn_echo_info "==> Restarting ZFS services."
	systemctl restart zfs-import-cache
	systemctl restart zfs-import-scan
	systemctl restart zfs-mount
	systemctl restart zfs-share
	cmn_echo_info "<== ZFS services are restarted."
}

function ensure_zfs_metadata() {
	cmn_echo_info "==> Checking for stale zpool metadata"
	PARTED_DATA=$(parted -l)
	for d in $ZFS_POOL_DRIVES; do
		if echo $PARTED_DATA | grep -q "${d}: unrecognised disk label"; then
			export METADATA_MISSING="true"
			break
		fi
	done

	if [[ $METADATA_MISSING -eq "true" ]]; then
		cmn_echo_info "==> Found one or more disks with missing metadata. Removing zpool cache file"
		rm -f /etc/zfs/zpool.cache
		return
	fi

	cmn_echo_info "<== zpool metadata is healthy"
}
