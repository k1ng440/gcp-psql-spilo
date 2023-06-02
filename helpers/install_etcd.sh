function install_etcd() {
    if [ ! -f "/bin/etcdctl" ]; then
		cmn_echo_info "etcdctl is already exist. Skipping"
		return
	fi

	cmn_echo_info "==> Installing etcdctl"
	curl -sL https://github.com/coreos/etcd/releases/download/v${ETCDVERSION}/etcd-v${ETCDVERSION}-linux-amd64.tar.gz | tar xz -C /bin --strip=1 --wildcards --no-anchored etcdctl etcd
	cmn_echo_info "<== Installed etcdctl"
}