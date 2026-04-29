#!/usr/bin/env bash
# System information collection: hardware specs, battery, storage, RAM

collect_info() {
    local start=$SECONDS

    # ── Dependencies ──
    command -v dmidecode &>/dev/null || { msg_info "Installing dmidecode..."; sudo apt install dmidecode -y; }
    command -v neofetch  &>/dev/null || { msg_info "Installing neofetch...";  sudo apt install neofetch -y; }
    command -v netstat   &>/dev/null || { msg_info "Installing net-tools..."; sudo apt install net-tools -y; echo "export PATH=\$PATH:/sbin" >> ~/.bashrc; }
    command -v acpi      &>/dev/null || { msg_info "Installing acpi...";      sudo apt install acpi -y; }

    # ── Refresh model data ──
    detect_model

    # ── Hours ──
    hours=$(sudo dmidecode -t 22 2>/dev/null | grep "Hours" | awk '{print $2}')
    [ -z "$hours" ] && hours=$(uptime -p)

    # ── RAM (with serials and calculated total in GB) ──
    ram_type=$(sudo dmidecode -t memory | grep -E "Type:.*DDR" | awk '{print $2}' | head -n1)

    local ram_size_a_raw ram_size_b_raw ram_serial_a ram_serial_b
    ram_size_a_raw=$(sudo dmidecode -t memory | awk '/^Memory Device$/,/^$/' | grep -m1 "Size:" | sed 's/.*: //')
    ram_size_b_raw=$(sudo dmidecode -t memory | awk '/^Memory Device$/,/^$/{found++} found==2' | grep -m1 "Size:" | sed 's/.*: //')

    ram_serial_a=$(sudo dmidecode -t memory | awk '/^Memory Device$/,/^$/' | grep -m1 "Serial Number:" | sed 's/.*: //')
    ram_serial_b=$(sudo dmidecode -t memory | awk '/^Memory Device$/,/^$/{found++} found==2' | grep -m1 "Serial Number:" | sed 's/.*: //')

    [[ "$ram_size_a_raw" == *"No Module"* ]] && ram_size_a_raw="Empty"
    [[ "$ram_size_b_raw" == *"No Module"* ]] && ram_size_b_raw="Empty"
    [ -z "$ram_size_a_raw" ] && ram_size_a_raw="Empty"
    [ -z "$ram_size_b_raw" ] && ram_size_b_raw="Empty"
    [[ "$ram_serial_a" == *"Not Specified"* ]] && ram_serial_a="N/A"
    [[ "$ram_serial_b" == *"Not Specified"* ]] && ram_serial_b="N/A"
    [ -z "$ram_serial_a" ] && ram_serial_a="N/A"
    [ -z "$ram_serial_b" ] && ram_serial_b="N/A"

    # Calculate total RAM in GB
    local size_a_mb=0 size_b_mb=0
    if [[ "$ram_size_a_raw" =~ ([0-9]+) ]]; then size_a_mb=${BASH_REMATCH[1]}; fi
    if [[ "$ram_size_b_raw" =~ ([0-9]+) ]]; then size_b_mb=${BASH_REMATCH[1]}; fi
    local total_ram_mb=$(( size_a_mb + size_b_mb ))
    local total_ram_gb=$(( total_ram_mb / 1024 ))
    (( total_ram_gb == 0 && total_ram_mb > 0 )) && total_ram_gb=1

    # Format slot display with GB and serial
    local slot_a_display="Empty"
    if [[ "$ram_size_a_raw" != "Empty" ]]; then
        local a_gb=$(( size_a_mb / 1024 ))
        slot_a_display="${a_gb} GB (SN: ${ram_serial_a})"
    fi

    local slot_b_display="Empty"
    if [[ "$ram_size_b_raw" != "Empty" ]]; then
        local b_gb=$(( size_b_mb / 1024 ))
        slot_b_display="${b_gb} GB (SN: ${ram_serial_b})"
    fi

    # ── Battery ──
    BAT_INFO=$(acpi -b 2>/dev/null)
    bat_present=false
    bat_state="Unknown"
    bat_charging_icon="[X]"

    if [[ -n "$BAT_INFO" ]]; then
        bat_present=true
        bat_state=$(echo "$BAT_INFO" | awk -F': ' '{print $2}' | awk -F',' '{print $1}')

        case "$bat_state" in
            Charging)    bat_charging_icon="[+]" ;;
            Discharging) bat_charging_icon="[!]" ;;
            Full)        bat_charging_icon="[=]" ;;
        esac
    fi

    bat_health=$(acpi -V 2>/dev/null | grep "mAh" | grep -o "[0-9]\+%")
    bat_status_1=$(acpi -V 2>/dev/null | awk -F, '/Battery/{print $2; exit}' | xargs)

    local clean_value=${bat_health%\%}
    local clean_value_int=$((clean_value))
    local bat_message=""

    if [ "$clean_value_int" -gt 85 ]; then
        bat_message="OK - Suitable for Amazon"
    elif [ "$clean_value_int" -gt 80 ]; then
        bat_message="OK - Suitable for Shopify"
    elif [ "$clean_value_int" -gt 1 ]; then
        bat_message="Low - No guaranteed battery life"
    else
        bat_message="No Battery Detected"
    fi

    # ── CPU short name ──
    local cpu_short="$cpu"
    if [[ $cpu =~ (i[0-9]-[0-9A-Z]+) ]]; then
        cpu_short="Intel ${BASH_REMATCH[1]}"
    fi

    # ── Display ──
    spinner_start "Collecting system information"
    sleep 1
    spinner_stop OK

    drawInfo_box "SYSTEM INFORMATION" \
        "Brand: $brand" \
        "Model: $model" \
        "Part Number: $part_number" \
        "Serial Number: $serial" \
        "CPU: $cpu_short"

    local batStatus="$bat_charging_icon $bat_state ($bat_status_1)"

    drawInfo_box "BATTERY INFORMATION" \
        "Status: $batStatus" \
        "Health: $bat_health" \
        "Recommendation: $bat_message"

    _draw_storage_info

    drawInfo_box "MEMORY INFORMATION" \
        "Total: ${total_ram_gb} GB" \
        "Type: $ram_type" \
        "Slot [1]: $slot_a_display" \
        "Slot [2]: $slot_b_display"

    echo ""
    echo -e "  ${DIM}Scroll: Ctrl + Shift + Up/Down${END}"

    local elapsed=$(( SECONDS - start ))
    msg_time "[Device Information] $((elapsed / 60))m $((elapsed % 60))s"
}

_draw_storage_info() {
    local TITLE="STORAGE INFORMATION"

    local C1=12 C2=8 C3=22 C4=20
    local INNER_W=$((C1 + 3 + C2 + 3 + C3 + 3 + C4))

    printf -v _b1 "%*s" "$C1" ""; _b1="${_b1// /═}"
    printf -v _b2 "%*s" "$C2" ""; _b2="${_b2// /═}"
    printf -v _b3 "%*s" "$C3" ""; _b3="${_b3// /═}"
    printf -v _b4 "%*s" "$C4" ""; _b4="${_b4// /═}"
    local BORDER_TOP="${_b1}═╤═${_b2}═╤═${_b3}═╤═${_b4}"
    local BORDER_BOT="${_b1}═╧═${_b2}═╧═${_b3}═╧═${_b4}"

    printf -v _m1 "%*s" "$C1" ""; _m1="${_m1// /─}"
    printf -v _m2 "%*s" "$C2" ""; _m2="${_m2// /─}"
    printf -v _m3 "%*s" "$C3" ""; _m3="${_m3// /─}"
    printf -v _m4 "%*s" "$C4" ""; _m4="${_m4// /─}"
    local BORDER_MID="${_m1}─┼─${_m2}─┼─${_m3}─┼─${_m4}"

    local TITLE_LEN=${#TITLE}
    local LP=$(( (INNER_W - TITLE_LEN) / 2 ))
    local RP=$(( INNER_W - TITLE_LEN - LP ))
    printf -v LSP "%*s" "$LP" ""
    printf -v RSP "%*s" "$RP" ""

    echo ""
    echo -e "  ${TURQUOISE}╔═${BORDER_TOP}═╗${END}"
    echo -e "  ${TURQUOISE}║${END} ${LSP}${BOLD}${TITLE}${END}${RSP} ${TURQUOISE}║${END}"
    echo -e "  ${TURQUOISE}╠═${BORDER_TOP}═╣${END}"

    printf "  ${TURQUOISE}║${END} %-${C1}s ${TURQUOISE}│${END} %-${C2}s ${TURQUOISE}│${END} %-${C3}s ${TURQUOISE}│${END} %-${C4}s ${TURQUOISE}║${END}\n" \
        "Device" "Size" "Serial" "Model"

    echo -e "  ${TURQUOISE}╟─${BORDER_MID}─╢${END}"

    lsblk -d -n -o NAME,SIZE,TYPE | awk '$3=="disk"{print $1,$2}' | while read -r dev size; do
        local SERIAL MODEL

        SERIAL=$(udevadm info --query=property --name="/dev/$dev" 2>/dev/null \
            | grep '^ID_SERIAL_SHORT=' | sed 's/^ID_SERIAL_SHORT=\([^_]*\).*/\1/')
        MODEL=$(udevadm info --query=property --name="/dev/$dev" 2>/dev/null \
            | grep '^ID_MODEL=' | sed 's/^ID_MODEL=\([^_]*\).*/\1/')

        SERIAL=${SERIAL:-N/A}
        MODEL=${MODEL:-Unknown}

        printf "  ${TURQUOISE}║${END} %-${C1}s ${TURQUOISE}│${END} %-${C2}s ${TURQUOISE}│${END} %-${C3}s ${TURQUOISE}│${END} %-${C4}s ${TURQUOISE}║${END}\n" \
            "/dev/$dev" "$size" "$SERIAL" "$MODEL"
    done

    echo -e "  ${TURQUOISE}╚═${BORDER_BOT}═╝${END}"
}
