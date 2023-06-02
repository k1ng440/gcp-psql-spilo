function install_patroni() {
	cmn_echo_info "==> Installing patroni and dependencies"

	# install most of the patroni dependencies from ubuntu packages
	BUILD_PACKAGES="python3-pip python3-wheel python3-dev patchutils binutils"
	PATRONI_EXTRA=$(apt-cache depends patroni |	sed -n -e 's/.* Depends: \(python3-.\+\)$/\1/p' | grep -Ev '^python3-(sphinx|etcd|consul|kazoo|kubernetes)')
	apt_install ${BUILD_PACKAGES} python3-pystache python3-requests ${PATRONI_EXTRA}

	pip3 install setuptools

	apt_install python3-etcd python3-meld3 \
		python3-boto python3-gevent python3-greenlet python3-cachetools \
		python3-rsa python3-pyasn1-modules python3-swiftclient

	find /usr/share/python-babel-localedata/locale-data -type f ! -name 'en_US*.dat' -delete
	pip3 install filechunkio 'git+https://github.com/zalando/pg_view.git@master#egg=pg-view' 1> /dev/null

	EXTRAS="etcd"
	cmn_echo_info "===> Installing patroni with extra: $EXTRAS"
	pip3 install "git+https://github.com/zalando/patroni.git@${PATRONI_VERSION}#egg=patroni[${EXTRAS}]" 1> /dev/null

	cmn_echo_info "<== Installed patroni and dependencies"
}