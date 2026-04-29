#!/usr/bin/env bash
# Hardware detection: scans USB devices, bluetooth, cameras, touch, network

# Unified detection function — replaces device_detection, c2_detection, g1_detection
# Usage: detect_devices <model_type>
#   model_type: "default" | "c2" | "g1"
detect_devices() {
    local model_type="${1:-default}"

    echo -e "${GREEN}[+] Starting device detection...${END}"

    command -v v4l2-ctl &>/dev/null || {
        echo "[!] Installing v4l-utils ..."
        sudo apt install v4l-utils -y
    }

    echo -e "${YELLOW}[!] Make sure that each device is properly connected.${END}"
    sleep 1.5

    local usb_devices
    usb_devices=$(lsusb)
    local touch_detected=false

    # ── Model-specific config ──
    local -a devices_to_check
    local -a touch_devices
    local check_bluetooth_systemd=false
    local check_optical=false
    local check_rear_camera=false

    case "$model_type" in
        c2)
            devices_to_check=("Fingerprint" "SmartCard Reader")
            touch_devices=("MultiTouch" "eGalaxTouch")
            check_bluetooth_systemd=true
            ;;
        g1)
            devices_to_check=("Fingerprint" "Smart Card Reader")
            touch_devices=("Touch Panel" "eGalaxTouch")
            check_bluetooth_systemd=true
            check_rear_camera=true
            ;;
        *)
            devices_to_check=("Fingerprint" "Bluetooth" "Smart Card Reader")
            touch_devices=("Touch Panel" "eGalaxTouch")
            check_optical=true
            ;;
    esac

    local modemg
    modemg=$(echo "$usb_devices" | grep "Sierra Wireless" | awk -F 'Inc. ' '{print $2}')
    local -a network_devices=(
        "Sierra Wireless:Sierra Wireless(${modemg})"
        "U-Blox:GPS Dedicated"
    )

    # ── Title ──
    draw_box "You are working on a ${brand} ${model}"

    printf "%-25s | %s\n" "Device" "Status"
    printf "%-25s | %s\n" "-------------------------" "------------"

    # ── USB devices ──
    for device_name in "${devices_to_check[@]}"; do
        if echo "$usb_devices" | grep -qi "$device_name"; then
            printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "$device_name" "✅ Detected"
        else
            printf "${RED}%-25s${END} | ${RED}%s${END}\n" "$device_name" "❌  Not Detected"
        fi
    done

    # ── Bluetooth via systemd (c2 & g1) ──
    if $check_bluetooth_systemd; then
        local BT_STATUS
        BT_STATUS=$(sudo systemctl status bluetooth 2>/dev/null)
        if echo "$BT_STATUS" | grep -q "Active: active (running)"; then
            printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "Bluetooth" "✅ Detected"
        else
            printf "${RED}%-25s${END} | ${RED}%s${END}\n" "Bluetooth" "❌  Not Detected"
        fi
    fi

    # ── Network devices ──
    for item in "${network_devices[@]}"; do
        local search_pattern="${item%%:*}"
        local output_alias="${item##*:}"

        if echo "$usb_devices" | grep -qi "$search_pattern"; then
            printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "$output_alias" "✅ Detected"
        else
            printf "${RED}%-25s${END} | ${RED}%s${END}\n" "$output_alias" "❌  Not Detected"
        fi
    done

    # ── Optical drive (default only) ──
    if $check_optical; then
        local OPTICAL_STATUS
        OPTICAL_STATUS=$(dmesg | grep -i 'dvd\|cdrom\|optical')
        if [ -n "$OPTICAL_STATUS" ]; then
            printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "Optical Drive(DVD)" "✅ Detected"
        else
            printf "${RED}%-25s${END} | ${RED}%s${END}\n" "Optical Drive(DVD)" "❌  Not Detected"
        fi
    fi

    # ── Cameras ──
    local V4L_OUTPUT
    V4L_OUTPUT=$(v4l2-ctl --list-devices 2>/dev/null)

    if echo "$V4L_OUTPUT" | grep -q "/dev/video0"; then
        printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "Front Camera" "✅ Detected"
    else
        printf "${RED}%-25s${END} | ${RED}%s${END}\n" "Front Camera" "❌  Not Detected"
    fi

    if $check_rear_camera; then
        if echo "$V4L_OUTPUT" | grep -q "/dev/video1"; then
            printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "Rear Camera" "✅ Detected"
        else
            printf "${RED}%-25s${END} | ${RED}%s${END}\n" "Rear Camera" "❌  Not Detected"
        fi
    fi

    # For default model, check cameras via lsusb
    if [[ "$model_type" == "default" ]]; then
        local -a cameras=("Webcam:Front Camera" "Camera:Rear Camera")
        for item in "${cameras[@]}"; do
            local search_pattern="${item%%:*}"
            local output_alias="${item##*:}"
            if echo "$usb_devices" | grep -qi "$search_pattern"; then
                printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "$output_alias" "✅ Detected"
            else
                printf "${RED}%-25s${END} | ${RED}%s${END}\n" "$output_alias" "❌  Not Detected"
            fi
        done
    fi

    # ── Touch screen ──
    for touch in "${touch_devices[@]}"; do
        if echo "$usb_devices" | grep -qi "$touch"; then
            touch_detected=true
            break
        fi
    done

    if $touch_detected; then
        printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "Touch Screen" "✅ Detected"
    else
        printf "${RED}%-25s${END} | ${RED}%s${END}\n" "Touch Screen" "❌ Not Detected"
    fi

    echo -e "${GREEN}[!] Scan completed.${END}"
}
