#!/bin/bash

#Raspberry Pi - Auto WiFi Hotspot Switch Internet
#A script to allow the Raspberry Pi to connect to a know wifi router or 
#automatically generate an Internet Hotspot Access Point if no network 
#is found. You can then use SSH or VNC on the move and switch between 
#the hotspot and network without a reboot.
#see: http://www.raspberryconnect.com/network/item/330-raspberry-pi-auto-wifi-hotspot-switch-internet

declare skipQuestions=false

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

verify_os() {
    declare -r MINIMUM_KALI_VERSION="2017.1"

    local os_name=""
    local os_version=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Check if the OS is `Kali-Linux` and
    # it's above the required version.

    os_name="$(uname -s)"

    if [ "$TRAVIS" == "true" ]; then
        return 0
    elif [ "$os_name" == "Linux" ] && [ -e "/etc/lsb-release" ]; then
        if [ "$(bash <(cat /etc/os-release; echo "echo ${ID/*, /}"))" == "kali" ]; then
            os_version="$(bash <(cat /etc/os-release; echo "echo ${VERSION/*, /}"))"

            if [ "$os_version" == "$MINIMUM_KALI_VERSION" ]; then
                return 0
            else
                printf "Sorry, this script is intended only for Kali-Linux %s+" "$MINIMUM_KALI_VERSION"
            fi
        fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    else
        printf "Sorry, this script is intended only for Kali-Linux!"
    fi

    return 1
}

setup_auto_hotspot() {
    update
    upgrade

    declare -a PKGS=(
        "hostapd"
        "dnsmasq"
    )

    for pkg in "${PKGS[@]}"; do
        install_package "$pkg" "$pkg"
        if cmd_exists "systemctl"; then
            execute "sudo systemctl disable $pkg" \
                "systemctl (disable $pkg)"
        fi
    done

    x="/etc/hostapd/hostapd.conf"
    if [ -e "$x" ]; then
        sudo cp "$x" "$x".bak
    fi

    if [ "$TRAVIS" != "true" ]; then
        print_question "Enter an SSID: "
        ssid="$(read -r)"

        passwd1="0"
        passwd2="1"
        until [ $passwd1 == $passwd2 ]; do
            print_question "Type a password to access your PiFi network, then press [ENTER]: "
            read -s passwd1
            print_question "Verify password to access your PiFi network, then press [ENTER]: "
            read -s passwd2
        done

        if [ "$passwd1" == "$passwd2" ]; then
            print_success "Password set. Edit $x to change."
        fi
    fi

    cat > "$x" <<- EOF
    interface=wlan0 
    driver=nl80211 
    ssid="$ssid" 
    hw_mode=g 
    channel=6 
    wmm_enabled=0 
    macaddr_acl=0 
    auth_algs=1 
    ignore_broadcast_ssid=0 
    wpa=2 
    wpa_passphrase="$passwd1" 
    wpa_key_mgmt=WPA-PSK 
    wpa_pairwise=TKIP 
    rsn_pairwise=CCMP
EOF

    x="/etc/default/hostapd"
    if [ -e "$x" ]; then
        sudo cp "$x" "$x".bak
    fi

    uncomment_str "$x" "#DAEMON_CONF=\"\"" "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\""

    x="/etc/dnsmasq.conf"
    if [ -e "$x" ]; then
        sudo cp "$x" "$x".bak
    fi

    cat > "$x" <<- EOF
    #Auto-Hotspot configuration
    interface=wlan0
    no-resolv
    bind-dynamic 
    server=8.8.8.8
    domain-needed
    bogus-priv
    dhcp-range=192.168.50.150,192.168.50.200,255.255.255.0,12h
EOF

    ssid="iPhone"
    passwd="dChyym8bmtCKHjEC"
    interface="wlan0"
    wpa_conf="/etc/wpa_supplicant/wpa_supplicant.conf"

    execute "wpa_passphrase $ssid $passwd > $wpa_conf" \
        "Configure wpa_supplicant.conf"

    x="/etc/network/interfaces"
    if [ -e "$x" ]; then
        sudo cp "$x" "$x".bak
    fi

    cat > "$x" <<- EOF
    # interfaces(5) file used by ifup(8) and ifdown(8)
    # Please note that this file is written to be used with dhcpcd
    # For static IP, consult /etc/dhcpcd.conf and 'man dhcpcd.conf'
    # Include files from /etc/network/interfaces.d:
    source-directory /etc/network/interfaces.d
    #auto lo wlan0
    iface lo inet loopback
    iface eth0 inet manual
    allow-hotplug wlan0
    #iface wlan0 inet manual
        wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
    iface $interface inet static
            address 192.168.50.5
            netmask 255.255.255.0
            network 192.168.50.0
            broadcast 192.168.50.255
    allow-hotplug wlan1
    iface wlan1 inet manual
        wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
EOF

    x="/etc/sysctl.conf"
    if [ -e "$x" ]; then
        sudo cp "$x" "$x".bak
    fi

    uncomment_str "$x" "#net.ipv4.ip_forward=1" "net.ipv4.ip_forward=1"

    x="/etc/systemd/system/autohotspot.service"
    cat < "$x" <<- EOF
    [Unit]
    Description=Automatically generates an internet Hotspot when a valid ssid is not in range
    After=multi-user.target
    [Service]
    Type=oneshot
    RemainAfterExit=yes
    ExecStart=/usr/bin/autohotspot
    [Install]
    WantedBy=multi-user.target
EOF

    if cmd_exists "systemctl"; then
        execute "sudo systemctl enable autohotspot.service" \
            "systemctl (enable autohotspot)"
    fi

    if ! cmd_exists "iw"; then
        install_package "iw" "iw"
    fi

    execute "sudo cp ./bin/autohotspot /usr/bin/autohotspot \
        && sudo chmod +x /usr/bin/autohotspot" \
        "cp ./bin/autohotspot -> /usr/bin/autohotspot"
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
        && . "utils.sh" \
        || exit 1

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Ensure the OS is supported and
    # it's above the required version.

    verify_os \
        || exit 1

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    skip_questions "$@" \
        && skipQuestions=true

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    ask_for_sudo

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    setup_auto_hotspot

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
    if ! $skipQuestions; then
        restart
    fi
}

main "$@"