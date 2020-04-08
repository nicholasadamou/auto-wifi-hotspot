#!/bin/bash

# shellcheck disable=SC1090

# Raspberry Pi - Auto WiFi Hotspot Switch Internet (Uninstaller)
# A script to allow the Raspberry Pi to connect to a know wifi router or
# automatically generate an Internet Hotspot Access Point if no network
# is found. You can then use SSH or VNC on the move and switch between
# the hotspot and network without a reboot.
# see: http://www.raspberryconnect.com/network/item/330-raspberry-pi-auto-wifi-hotspot-switch-internet

declare -r BASH_UTILS_URL="https://raw.githubusercontent.com/nicholasadamou/utilities/master/utilities.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

uninstall_auto_hotspot() {
	apt_update
    apt_upgrade

	declare -a PKGS=(
        "hostapd"
        "dnsmasq"
        "network-manager"
    )

    for PKG in "${PKGS[@]}"; do
        remove_package "$PKG"
    done

	declare -a FILES_TO_DELETE=(
		"/etc/hostapd/hostapd.conf"
		"/etc/default/hostapd"
		"/etc/dnsmasq.conf"
		"/etc/network/interfaces"
		"/etc/sysctl.conf"
		"/etc/systemd/system/autohotspot.service"
		"/usr/bin/autohotspot"
	)

	for file in "${FILES_TO_DELETE[@]}"; do
		ask_for_confirmation "Do you want to remove ${file}?"

		if answer_is_yes; then
			sudo rm -rf "$file"
		fi

		if [[ -e "$file.bak" ]]; then
			mv "$file.bak" "$file"
		fi
	done
}

restart() {
    ask_for_confirmation "Do you want to restart?"

    if answer_is_yes; then
        sudo shutdown -r now &> /dev/null
    fi
}

main() {
    # Ensure that the following actions
    # are made relative to this file's path.

    cd "$(dirname "${BASH_SOURCE[0]}")" \
        && source <(curl -s "$BASH_UTILS_URL") \
        || exit 1

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    ask_for_sudo

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    uninstall_auto_hotspot

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    restart
}

main
