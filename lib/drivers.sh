#!/usr/bin/env bash
# Driver and package installation

# Flag to avoid running apt update/upgrade twice
_SYSTEM_UPDATED=false

_ensure_system_updated() {
    if $_SYSTEM_UPDATED; then
        return
    fi
    echo "🔄 Updating package lists..."
    local start=$SECONDS
    sudo apt-get update -qq

    local UPGRADABLE
    UPGRADABLE=$(apt-get -s upgrade | grep -P '^\d+ upgraded' | cut -d' ' -f1)
    [[ "$UPGRADABLE" -gt 0 ]] && sudo apt-get upgrade -y

    local elapsed=$(( SECONDS - start ))
    echo -e "${GRAY}[System Update] completed in $((elapsed / 60))m $((elapsed % 60))s${END}"
    _SYSTEM_UPDATED=true
}

check_dependencies() {
    echo -e "${PURPLE}[!] Checking Dependencies...${END}"
    sleep 1

    _ensure_system_updated

    if ! command -v libreoffice &>/dev/null; then
        echo "[!] Installing LibreOffice ..."
        sudo snap install libreoffice
    fi

    echo -e "${YELLOW}[!] Collecting Device Information.${END}"
}

# Reuses _detect_gps logic from detection.sh for driver installation
_gps_detected() {
    local usb_devices="$1"
    if echo "$usb_devices" | grep -qi "U-Blox"; then
        return 0
    fi
    local tty_output
    tty_output=$(dmesg 2>/dev/null | grep -i tty)
    if echo "$tty_output" | grep -qE "ttyS0|ttyS4"; then
        return 0
    fi
    return 1
}

install_drivers() {
    echo -e "${GREEN}[+] Starting driver installation...${END}"
    local total_start=$SECONDS

    _ensure_system_updated

    local devices_to_check=("Sierra Wireless" "Fingerprint" "Webcam" "Bluetooth" "Smart Card Reader" "Touch Panel" "eGalaxTouch")
    local usb_devices
    usb_devices=$(lsusb)

    printf "%-25s | %s\n" "Component" "Status"
    printf "%-25s | %s\n" "-------------------------" "------------"

    # GPS (USB + serial port)
    if _gps_detected "$usb_devices"; then
        printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "GPS" "Detected"
        echo "  -> Installing GPS packages..."
        sudo apt install -y gpsd gpsd-clients
        sleep 1
    else
        printf "${RED}%-25s${END} | ${RED}%s${END}\n" "GPS" "Not Detected"
    fi

    for device_name in "${devices_to_check[@]}"; do
        if echo "$usb_devices" | grep -qi "$device_name"; then
            printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "$device_name" "Detected"
            case "$device_name" in
                "Sierra Wireless")
                    echo "  -> Sierra Wireless detected. Skipping automatic installation."
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
    local total_elapsed=$(( SECONDS - total_start ))
    echo -e "${GRAY}[Driver Installation] completed in $((total_elapsed / 60))m $((total_elapsed % 60))s${END}"
    echo -e "${YELLOW}[!] Test all devices manually before running the OEM system preparation.${END}"
}
