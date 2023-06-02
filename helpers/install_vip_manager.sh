function install_vip_manager() {
    (
		cmn_echo_info "==> installing VIP manager"
		cd /tmp || exit 1
		VIP_MANAGER_FILENAME="vip-manager_`echo $VIP_MANAGER_VERSION | sed -e "s/^v//"`-1_amd64.deb"
		rm -rf "$VIP_MANAGER_FILENAME"
		curl -sL "https://github.com/cybertec-postgresql/vip-manager/releases/download/${VIP_MANAGER_VERSION}/${VIP_MANAGER_FILENAME}" -o "$VIP_MANAGER_FILENAME" && dpkg -i "$VIP_MANAGER_FILENAME"
		systemctl stop vip-manager.service

		mkdir -p /etc/default
		envsubst < "$DIR/templates/vip-manager.template.yaml" > /etc/default/vip-manager.yml
		systemctl restart vip-manager.service
	)
}