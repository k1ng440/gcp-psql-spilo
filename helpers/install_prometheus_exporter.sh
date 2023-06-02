function install_prometheus_exporter() {
	cmn_echo_info "==> Installing postgres_exporter"
	/opt/go/bin/go get github.com/prometheus-community/postgres_exporter/cmd/postgres_exporter 1> /dev/null
	cp "$DIR/templates/postgres-prometheus-exporter.service" /etc/systemd/system
	cp "$DIR/templates/node_exporter_queries.yaml" /etc/patroni/node_exporter_queries.yaml

	systemctl enable postgres-prometheus-exporter.service 1> /dev/null
	systemctl start postgres-prometheus-exporter.service 1> /dev/null
	cmn_echo_info "<== Installed postgres_exporter"
}

function install_node_exporter() {
	cmn_echo_info "==> Installing node_exporter"

	mkdir -p /etc/sysconfig
	if id "node_exporter" &>/dev/null; then
		cmn_echo_info "*** User node_exporter is already exist"
	else
		useradd -rs /bin/false node_exporter
	fi

	/opt/go/bin/go get github.com/prometheus/node_exporter 1> /dev/null

	cp "$DIR/templates/sysconfig.node_exporter" /etc/sysconfig/node_exporter
	cp "$DIR/templates/node_exporter.service" /etc/systemd/system

	systemctl enable node_exporter.service 1> /dev/null
	systemctl start node_exporter.service 1> /dev/null
	cmn_echo_info "<== Installed node_exporter"
}