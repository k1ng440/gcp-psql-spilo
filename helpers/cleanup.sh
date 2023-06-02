function cleanup_apt() {
	cmn_echo_info ">>>> cleaning up apt packages"
	apt-get autoremove -yqq 1> /dev/null
	apt-get clean 1> /dev/null
	find /var/log -type f -exec truncate --size 0 {} \;
}
