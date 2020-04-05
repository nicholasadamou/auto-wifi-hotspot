#!/bin/bash

# shellcheck disable=SC1090

# Raspberry Pi - Auto WiFi Hotspot Switch Internet (Installer)
# A script to allow the Raspberry Pi to connect to a know wifi router or
# automatically generate an Internet Hotspot Access Point if no network
# is found. You can then use SSH or VNC on the move and switch between
# the hotspot and network without a reboot.
# see: http://www.raspberryconnect.com/network/item/330-raspberry-pi-auto-wifi-hotspot-switch-internet

declare BASH_UTILS_URL="https://raw.githubusercontent.com/nicholasadamou/utilities/master/utilities.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

setup_auto_hotspot() {
    apt_update
    apt_upgrade

    declare -a PKGS=(
        "hostapd"
        "dnsmasq"
        "network-manager"
    )

    for PKG in "${PKGS[@]}"; do
        install_package "$PKG"
    done

    declare -a PKGS_TO_DISABLE=(
        "hostapd"
        "dnsmasq"
    )

    for PKG in "${PKGS_TO_DISABLE[@]}"; do
        if cmd_exists "systemctl"; then
            sudo systemctl disable "$PKG"
        fi
    done

    FILE="/etc/hostapd/hostapd.conf"
    sudo touch "$FILE"

    ask "Enter an SSID for the HostAPD Hotspot: "
    SSID="$(get_answer)"

    PASSWD1="0"
    PASSWD2="1"
    until [ $PASSWD1 == $PASSWD2 ]; do
        print_question "Type a password to access '$SSID', then press [ENTER]: "
        read -s -r
		PASSWD1="$(get_answer)"

		printf "\n"

        print_question "Verify password to access '$SSID', then press [ENTER]: "
        read -s -r
		PASSWD2="$(get_answer)"

		printf "\n"
    done

    if [ "$PASSWD1" == "$PASSWD2" ]; then
        print_success "Password set. Edit $FILE to change."
    fi

    cat > "$FILE" <<- EOF
    interface=wlan0
    driver=nl80211
    ssid="$SSID"
    hw_mode=g
    channel=6
    wmm_enabled=0
    macaddr_acl=0
    auth_algs=1
    ignore_broadcast_ssid=0
    wpa=2
    wpa_passphrase="$PASSWD1"
    wpa_key_mgmt=WPA2-PSK
    wpa_pairwise=TKIP
    rsn_pairwise=CCMP
EOF

    FILE="/etc/default/hostapd"
    if [ -e "$FILE" ]; then
        sudo cp "$FILE" "$FILE".bak
	fi

    add_value_and_uncomment "$FILE" "#DAEMON_CONF=\"\"" "/etc/hostapd/hostapd.conf"

    FILE="/etc/dnsmasq.conf"
    if [ -e "$FILE" ]; then
        sudo cp "$FILE" "$FILE".bak
	fi

    cat > "$FILE" <<- EOF
    # Auto-Hotspot configuration
    interface=wlan0
    no-resolv
    bind-dynamic
    server=1.1.1.1 # Cloudflare DNS
    domain-needed
    bogus-priv
    dhcp-range=192.168.50.150,192.168.50.200,255.255.255.0,12h
EOF

    INTERFACE="wlan0"

    nmcli device wifi list

    ask "Enter an SSID: "
    SSID="$(get_answer)"

    PASSWD1="0"
    PASSWD2="1"
    until [ $PASSWD1 == $PASSWD2 ]; do
        print_question "Type a password to access $SSID, then press [ENTER]: "
        read -s -r
		PASSWD1="$(get_answer)"

        print_question "Verify password to access $SSID, then press [ENTER]: "
        read -s -r
		PASSWD2="$(get_answer)"

    done

    if [ "$PASSWD1" == "$PASSWD2" ]; then
        WPA_CONF="/etc/wpa_supplicant/wpa_supplicant.conf"

        if [ -f "$WPA_CONF" ]; then
            wpa_passphrase "$SSID" "$PASSWD1" > $WPA_CONF
        fi
    fi

    FILE="/etc/network/interfaces"
    if [ -e "$FILE" ]; then
        sudo cp "$FILE" "$FILE".bak
    fi

    cat > "$FILE" <<- EOF
    # interfaces(5) file used by ifup(8) and ifdown(8)
    # Please note that this file is written to be used with dhcpcd
    # For static IP, consult /etc/dhcpcd.conf and 'man dhcpcd.conf'
    # Include files from /etc/network/interfaces.d:
    source-directory /etc/network/interfaces.d
    #auto lo wlan0
    iface lo inet loopback
    iface eth0 inet manual
    allow-hotplug $INTERFACE
    #iface wlan0 inet manual
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
    iface $INTERFACE inet static
            address 192.168.50.5
            netmask 255.255.255.0
            network 192.168.50.0
            broadcast 192.168.50.255
    allow-hotplug wlan1
    iface wlan1 inet manual
        wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
EOF

    FILE="/etc/sysctl.conf"
    if [ -e "$FILE" ]; then
        sudo cp "$FILE" "$FILE".bak
    fi

    uncomment_str "$FILE" "#net.ipv4.ip_forward=1"

    FILE="/etc/systemd/system/autohotspot.service"

    ! [ -f "$FILE" ] && sudo touch "$FILE"

    cat > "$FILE" <<- EOF
    [Unit]
    Description=Automatically generates an internet Hotspot when a valid SSID is not in range
    After=multi-user.target
    [Service]
    Type=oneshot
    RemainAfterExit=yes
    EFILEecStart=/usr/bin/autohotspot
    [Install]
    WantedBy=multi-user.target
EOF

    if cmd_exists "systemctl"; then
        sudo systemctl enable autohotspot.service
    fi

	sudo cp ./bin/autohotspot /usr/bin/autohotspot \
        && sudo chmod +x /usr/bin/autohotspot
}

restart() {
    ask_for_confirmation "Do you want to restart?"

    if answer_is_yes; then
        sudo shutdown -r now &> /dev/null
    fi
}

main() {
    # Ensure that the bash utilities functions have
	# been sourced.

    source <(curl -s "$BASH_UTILS_URL")

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    ask_for_sudo

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    setup_auto_hotspot

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    restart
}

main
