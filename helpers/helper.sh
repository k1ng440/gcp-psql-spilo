if [ -n "$TERM" ] && [ "$TERM" = unknown ]; then
	TERM=dumb
fi

function append_path() {
	if ! eval test -z "\"\${$1##*:$2:*}\"" -o -z "\"\${$1%%*:$2}\"" -o -z "\"\${$1##$2:*}\"" -o -z "\"\${$1##$2}\""; then
		eval "$1=\$$1:$2"
	fi
}

# shellcheck disable=SC2028
function git_sparse_clone() {
	url="$1" local_dir="$2" && shift 2

	mkdir -p "$local_dir"
	cd "$local_dir" || exit 1

	git init 1> /dev/null
	git remote add -f origin "$url" 1> /dev/null
	git config core.sparseCheckout true 1> /dev/null

	# Loops over remaining args
	for i; do
		echo "$i" >>.git/info/sparse-checkout
	done

	git pull origin master 1> /dev/null
}

function install_envsubst() {
	if [ ! -f "/usr/local/bin/envsubst" ]; then
		echo "*** envsubst already exists. Skipping"
		return
	fi

    # install envsubst template renderer
	echo "==> Installing envsubst template renderer"
	curl -sL "https://github.com/a8m/envsubst/releases/download/v1.1.0/envsubst-$(uname -s)-$(uname -m)" -o envsubst
	chmod +x envsubst
	mv envsubst /usr/local/bin
}

function ensure_locales() {
    truncate --size 0 /usr/share/i18n/SUPPORTED
	for loc in en_US $ADDITIONAL_LOCALES; do
		echo "$loc.UTF-8 UTF-8" >>/usr/share/i18n/SUPPORTED
		localedef -i $loc -c -f UTF-8 -A /usr/share/locale/locale.alias $loc.UTF-8
	done
}

create_symlink_postgres_executables() {
  for util in /usr/lib/postgresql/$PGVERSION/bin/*; do
    if [ ! -f "/usr/bin/${util##*/}" ]; then
      ln -s "$util" "/usr/bin/${util##*/}"
    fi
  done
}

function append_text() {
	grep -q "$1" "$2" || printf "%s\n" "$1" >> $2
}

function sedeasy() {
  sed -i "s/$(echo $1 | sed -e 's/\([[\/.*]\|\]\)/\\&/g')/$(echo $2 | sed -e 's/[\/&]/\\&/g')/g" $3
}

function apt_installed() {
    return $(dpkg-query -W -f '${Status}\n' "${1}" 2>&1|awk '/ok installed/{print 0;exit}{print 1}')
}

function apt_install() {
   	pkgs=("$@")
	missing_pkgs=""

	cmn_echo_info "==> Installing apt packages: $pkgs"

	for pkg in ${pkgs[@]}; do
		if ! $(apt_installed $pkg) ; then
			missing_pkgs+=" $pkg"
		fi
	done

	if [ "$missing_pkgs" == "" ]; then
		cmn_echo_info "*** All apt packages are already installed: $pkgs"
		return
	fi

    apt-get install -yqq $missing_pkgs 1> /dev/null
    cmn_echo_info "<== Installed apt packages"
}
