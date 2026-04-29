#!/usr/bin/env bash
# Hardware detection: scans USB devices, bluetooth, cameras, touch, network, GPS

# ── Fixed-width table constants ──
_DET_COL1=30
_DET_COL2=18
_DET_W=$((_DET_COL1 + 3 + _DET_COL2))

_det_border() {
    printf -v _b1 "%*s" "$_DET_COL1" ""; _b1="${_b1// /═}"
    printf -v _b2 "%*s" "$_DET_COL2" ""; _b2="${_b2// /═}"
    echo "${_b1}═╤═${_b2}"
}

_det_border_mid() {
    printf -v _b1 "%*s" "$_DET_COL1" ""; _b1="${_b1// /─}"
    printf -v _b2 "%*s" "$_DET_COL2" ""; _b2="${_b2// /─}"
    echo "${_b1}─┼─${_b2}"
}

_det_border_bot() {
    printf -v _b1 "%*s" "$_DET_COL1" ""; _b1="${_b1// /═}"
    printf -v _b2 "%*s" "$_DET_COL2" ""; _b2="${_b2// /═}"
    echo "${_b1}═╧═${_b2}"
}

_detection_header() {
    local TITLE="HARDWARE DETECTION"
    local BORDER
    BORDER=$(_det_border)
    local BORDER_FULL="${BORDER}"
    local INNER_W=${_DET_W}

    local TITLE_LEN=${#TITLE}
    local LP=$(( (INNER_W - TITLE_LEN) / 2 ))
    local RP=$(( INNER_W - TITLE_LEN - LP ))
    printf -v LSP "%*s" "$LP" ""
    printf -v RSP "%*s" "$RP" ""

    echo -e "  ${TURQUOISE}╔═${BORDER_FULL}═╗${END}"
    echo -e "  ${TURQUOISE}║${END} ${LSP}${BOLD}${TITLE}${END}${RSP} ${TURQUOISE}║${END}"
    echo -e "  ${TURQUOISE}╠═${BORDER_FULL}═╣${END}"
    printf "  ${TURQUOISE}║${END} %-${_DET_COL1}s ${TURQUOISE}│${END} %-${_DET_COL2}s ${TURQUOISE}║${END}\n" "Device" "Status"
    local MID
    MID=$(_det_border_mid)
    echo -e "  ${TURQUOISE}╟─${MID}─╢${END}"
}

_detection_row() {
    local device="$1"
    local detected="$2"

    if $detected; then
        printf "  ${TURQUOISE}║${END} ${GREEN}%-${_DET_COL1}s${END} ${TURQUOISE}│${END} ${GREEN}%-${_DET_COL2}s${END} ${TURQUOISE}║${END}\n" \
            "$device" "[+] Detected"
    else
        printf "  ${TURQUOISE}║${END} ${RED}%-${_DET_COL1}s${END} ${TURQUOISE}│${END} ${RED}%-${_DET_COL2}s${END} ${TURQUOISE}║${END}\n" \
            "$device" "[-] Not Detected"
    fi
}

_detection_footer() {
    local BORDER
    BORDER=$(_det_border_bot)
    echo -e "  ${TURQUOISE}╚═${BORDER}═╝${END}"
}

# ── GPS detection: USB (U-Blox) OR serial port (ttyS0/ttyS4) ──

_detect_gps() {
    local usb_devices="$1"

    # Check USB
    if echo "$usb_devices" | grep -qi "U-Blox"; then
        return 0
    fi

    # Check serial ports
    local tty_output
    tty_output=$(dmesg 2>/dev/null | grep -i tty)
    if echo "$tty_output" | grep -qE "ttyS0|ttyS4"; then
        return 0
    fi

    return 1
}

# ── Main detection function ──
# Usage: detect_devices <model_type>
#   model_type: "default" | "c2" | "g1"

detect_devices() {
    local model_type="${1:-default}"
    local start=$SECONDS

    msg_info "Starting device detection..."

    # Ensure model globals are set (safety net)
    if [[ -z "$brand" || -z "$model" ]]; then
        detect_model
    fi

    command -v v4l2-ctl &>/dev/null || {
        echo "[!] Installing v4l-utils ..."
        sudo apt install v4l-utils -y
    }

    msg_warn "Make sure that each device is properly connected."
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

    # ── Title ──
    draw_box "You are working on a ${brand} ${model}"
    echo ""

    echo ""
    _detection_header

    # ── USB devices ──
    for device_name in "${devices_to_check[@]}"; do
        if echo "$usb_devices" | grep -qi "$device_name"; then
            _detection_row "$device_name" true
        else
            _detection_row "$device_name" false
        fi
    done

    # ── Bluetooth via systemd (c2 & g1) ──
    if $check_bluetooth_systemd; then
        local BT_STATUS
        BT_STATUS=$(sudo systemctl status bluetooth 2>/dev/null)
        if echo "$BT_STATUS" | grep -q "Active: active (running)"; then
            _detection_row "Bluetooth" true
        else
            _detection_row "Bluetooth" false
        fi
    fi

    # ── Wi-Fi ──
    local WIFI_DEV
    WIFI_DEV=$(nmcli -t -f TYPE,STATE device 2>/dev/null | grep "^wifi:")
    if [ -n "$WIFI_DEV" ]; then
        local WIFI_NAME
        WIFI_NAME=$(nmcli -t -f DEVICE,TYPE device 2>/dev/null | grep ":wifi$" | cut -d: -f1)
        _detection_row "Wi-Fi ($WIFI_NAME)" true
    else
        _detection_row "Wi-Fi" false
    fi

    # ── 4G Modem ──
    local modemg
    modemg=$(echo "$usb_devices" | grep "Sierra Wireless" | awk -F 'Inc. ' '{print $2}')

    if echo "$usb_devices" | grep -qi "Sierra Wireless"; then
        _detection_row "Sierra Wireless (${modemg})" true
    else
        _detection_row "Sierra Wireless (4G Modem)" false
    fi

    # ── GPS (USB + serial port fallback) ──
    if _detect_gps "$usb_devices"; then
        _detection_row "GPS Dedicated" true
    else
        _detection_row "GPS Dedicated" false
    fi

    # ── Optical drive (default only) ──
    if $check_optical; then
        local OPTICAL_STATUS
        OPTICAL_STATUS=$(dmesg 2>/dev/null | grep -i 'dvd\|cdrom\|optical')
        if [ -n "$OPTICAL_STATUS" ]; then
            _detection_row "Optical Drive (DVD)" true
        else
            _detection_row "Optical Drive (DVD)" false
        fi
    fi

    # ── Cameras ──
    local V4L_OUTPUT
    V4L_OUTPUT=$(v4l2-ctl --list-devices 2>/dev/null)

    if echo "$V4L_OUTPUT" | grep -q "/dev/video0"; then
        _detection_row "Front Camera" true
    else
        _detection_row "Front Camera" false
    fi

    if $check_rear_camera; then
        if echo "$V4L_OUTPUT" | grep -q "/dev/video1"; then
            _detection_row "Rear Camera" true
        else
            _detection_row "Rear Camera" false
        fi
    fi

    # For default model, check cameras via lsusb
    if [[ "$model_type" == "default" ]]; then
        local -a cameras=("Webcam:Front Camera" "Camera:Rear Camera")
        for item in "${cameras[@]}"; do
            local search_pattern="${item%%:*}"
            local output_alias="${item##*:}"
            if echo "$usb_devices" | grep -qi "$search_pattern"; then
                _detection_row "$output_alias" true
            else
                _detection_row "$output_alias" false
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

    _detection_row "Touch Screen" $touch_detected

    _detection_footer

    local elapsed=$(( SECONDS - start ))
    echo ""
    msg_ok "Scan completed."
    msg_time "[Hardware Detection] $((elapsed / 60))m $((elapsed % 60))s"
}
