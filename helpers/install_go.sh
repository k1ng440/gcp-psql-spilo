function install_go() {
	append_path PATH "${GOROOT}/bin"
	append_path PATH "${GOPATH}/bin"

	if [ ! -f /opt/go/bin/go ]; then
		rm -rf $GOROOT
		cmn_echo_info "==> Installing golang"
		curl -sL https://raw.githubusercontent.com/canha/golang-tools-install-script/master/goinstall.sh | bash > /dev/null 2>&1
		cmn_echo_info "<== Installing Golang"
	fi
}
