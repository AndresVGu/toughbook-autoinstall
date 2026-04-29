#!/usr/bin/env bash
# Driver and package installation

check_dependencies() {
    echo -e "${PURPLE}[!] Checking Dependencies...${END}"
    sleep 1

    echo "🔄 Updating package lists..."
    sudo apt-get update -qq

    local UPGRADABLE
    UPGRADABLE=$(apt-get -s upgrade | grep -P '^\d+ upgraded' | cut -d' ' -f1)
    [[ "$UPGRADABLE" -gt 0 ]] && sudo apt-get upgrade -y

    if ! command -v libreoffice &>/dev/null; then
        echo "[!] Installing LibreOffice ..."
        sudo snap install libreoffice
    fi

    echo -e "${YELLOW}[!] Collecting Device Information.${END}"
}

install_drivers() {
    echo -e "${GREEN}[+] Starting driver installation...${END}"
    sudo apt update
    sudo apt upgrade -y

    local devices_to_check=("Sierra Wireless" "U-Blox" "Fingerprint" "Webcam" "Bluetooth" "Smart Card Reader" "Touch Panel" "eGalaxTouch")
    local usb_devices
    usb_devices=$(lsusb)

    printf "%-25s | %s\n" "Component" "Status"
    printf "%-25s | %s\n" "-------------------------" "------------"

    for device_name in "${devices_to_check[@]}"; do
        if echo "$usb_devices" | grep -qi "$device_name"; then
            printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "$device_name" "Detected"
            case "$device_name" in
                "Sierra Wireless")
                    echo "  -> Sierra Wireless detected. Skipping automatic installation."
                    ;;
                "U-Blox")
                    echo "  -> Installing GPS packages..."
                    sudo apt install -y gpsd gpsd-clients
                    ;;
                "Fingerprint")
                    echo "  -> Installing fingerprint packages..."
                    sudo apt install -y fprintd libpam-fprintd
                    ;;
                "Webcam")
                    echo "  -> Installing camera software..."
                    sudo apt install -y cheese
                    ;;
                "Bluetooth")
                    echo "  -> Bluetooth detected. Skipping automatic installation."
                    ;;
                "Smart Card Reader")
                    echo "  -> Installing smart card reader packages..."
                    sudo apt install -y pcsc-tools pcscd opensc libccid
                    ;;
                "Touch Panel"|"eGalaxTouch")
                    echo "  -> Installing Touch Panel calibrator..."
                    sudo apt install -y xinput-calibrator
                    ;;
            esac
            sleep 1
        else
            printf "${RED}%-25s${END} | ${RED}%s${END}\n" "$device_name" "Not Detected"
        fi
    done

    echo -e "${GREEN}[+] Analysis and installation complete.${END}"
    echo -e "${YELLOW}[!] Test all devices manually before running the OEM system preparation.${END}"
}
