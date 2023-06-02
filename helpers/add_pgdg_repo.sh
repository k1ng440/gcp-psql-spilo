function add_pgdg_repos() {
	if [ -f "/etc/apt/sources.list.d/pgdg.list" ]; then
		cmn_echo_info "*** PostgreSQL repositories already exists. skipping"
		return
	fi

	cmn_echo_info "==> Installing PostgreSQL repository"
	DISTRIB_CODENAME=$(sed -n 's/DISTRIB_CODENAME=//p' /etc/lsb-release)
	echo >/etc/apt/sources.list.d/pgdg.list
	for t in deb deb-src; do
		echo "$t http://apt.postgresql.org/pub/repos/apt/ ${DISTRIB_CODENAME}-pgdg main" >> /etc/apt/sources.list.d/pgdg.list
	done
	curl -s -o - "https://www.postgresql.org/media/keys/ACCC4CF8.asc" | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add -
	apt-get update -yqq 1> /dev/null
	cmn_echo_info "<== Installed PostgreSQL repository"
}