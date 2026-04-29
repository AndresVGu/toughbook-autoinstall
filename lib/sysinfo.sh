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
    ram_type=$(sudo dmidecode -t memory 2>/dev/null | grep -E "Type:.*DDR" | awk '{print $2}' | head -n1)

    local ram_size_a ram_size_b ram_serial_a ram_serial_b
    ram_size_a=$(sudo dmidecode -t memory 2>/dev/null | grep "Size:" | sed -n '1p' | awk '{print $2, $3}')
    ram_size_b=$(sudo dmidecode -t memory 2>/dev/null | grep "Size:" | sed -n '2p' | awk '{print $2, $3}')
    ram_serial_a=$(sudo dmidecode -t memory 2>/dev/null | grep "Serial Number:" | sed -n '1p' | awk -F': ' '{print $2}' | xargs)
    ram_serial_b=$(sudo dmidecode -t memory 2>/dev/null | grep "Serial Number:" | sed -n '2p' | awk -F': ' '{print $2}' | xargs)

    [[ -z "$ram_size_a" || "$ram_size_a" == *"No Module"* || "$ram_size_a" == *"Not"* ]] && ram_size_a=""
    [[ -z "$ram_size_b" || "$ram_size_b" == *"No Module"* || "$ram_size_b" == *"Not"* ]] && ram_size_b=""
    [[ -z "$ram_serial_a" || "$ram_serial_a" == *"Not Specified"* ]] && ram_serial_a="N/A"
    [[ -z "$ram_serial_b" || "$ram_serial_b" == *"Not Specified"* ]] && ram_serial_b="N/A"

    local size_a_mb=0 size_b_mb=0
    [[ "$ram_size_a" =~ ([0-9]+) ]] && size_a_mb=${BASH_REMATCH[1]}
    [[ "$ram_size_b" =~ ([0-9]+) ]] && size_b_mb=${BASH_REMATCH[1]}

    local a_gb=0 b_gb=0
    (( size_a_mb >= 1024 )) && a_gb=$(( size_a_mb / 1024 ))
    (( size_a_mb > 0 && size_a_mb < 1024 )) && a_gb=1
    (( size_b_mb >= 1024 )) && b_gb=$(( size_b_mb / 1024 ))
    (( size_b_mb > 0 && size_b_mb < 1024 )) && b_gb=1
    local total_gb=$(( a_gb + b_gb ))

    if (( total_gb == 0 )); then
        total_gb=$(free --giga 2>/dev/null | awk '/Mem:/ {print $2}')
        (( total_gb == 0 )) && total_gb=$(free -h | awk '/Mem:/ {sub(/[a-zA-Z]/,"",$2); print int($2+0.5)}')
    fi

    local slot_a_display="Empty"
    (( a_gb > 0 )) && slot_a_display="${a_gb} GB (SN: ${ram_serial_a})"

    local slot_b_display="Empty"
    (( b_gb > 0 )) && slot_b_display="${b_gb} GB (SN: ${ram_serial_b})"

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

    # Alternative charging detection via sysfs / upower
    local power_source="Unknown"
    local ac_online
    ac_online=$(cat /sys/class/power_supply/*/online 2>/dev/null | head -1)
    if [[ "$ac_online" == "1" ]]; then
        power_source="AC Connected"
    else
        power_source="Battery"
    fi

    local upower_state
    upower_state=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 2>/dev/null | grep "state:" | awk '{print $2}')
    [ -n "$upower_state" ] && bat_state="$upower_state"

    local upower_pct
    upower_pct=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 2>/dev/null | grep "percentage:" | awk '{print $2}')

    # Update icon and status based on best available state + AC connection
    local pct_num=0
    [[ "$upower_pct" =~ ([0-9]+) ]] && pct_num=${BASH_REMATCH[1]}

    if [[ "$ac_online" == "1" ]]; then
        # AC is connected
        if [[ "$upower_state" == "fully-charged" ]] || (( pct_num >= 100 )); then
            bat_charging_icon="[=]"; bat_state="Fully Charged - Connected"
        elif [[ "$upower_state" == "charging" ]]; then
            bat_charging_icon="[+]"; bat_state="Charging - Connected"
        else
            bat_charging_icon="[~]"; bat_state="Not Charging - Connected"
        fi
    else
        # On battery
        if [[ "$upower_state" == "discharging" ]]; then
            bat_charging_icon="[!]"; bat_state="Discharging"
        elif [[ "$upower_state" == "fully-charged" ]] || (( pct_num >= 100 )); then
            bat_charging_icon="[=]"; bat_state="Fully Charged"
        else
            bat_charging_icon="[-]"; bat_state="Not Charging"
        fi
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
        "Charge: ${upower_pct:-N/A}" \
        "Power Source: $power_source" \
        "Health: $bat_health" \
        "Recommendation: $bat_message"

    _draw_storage_info

    drawInfo_box "MEMORY INFORMATION" \
        "Total: ${total_gb} GB" \
        "Type: $ram_type" \
        "Slot [1]: $slot_a_display" \
        "Slot [2]: $slot_b_display"

    echo ""
    echo -e "  ${DIM}Scroll: Ctrl + Shift + Up/Down${END}"

    local elapsed=$(( SECONDS - start ))
    msg_time "[Device Information] $((elapsed / 60))m $((elapsed % 60))s"
}

# Normalize raw disk size (476.9G -> 512 GB, 238.5G -> 256 GB, etc.)
_normalize_disk_size() {
    local raw="$1"
    local num
    num=$(echo "$raw" | sed 's/[^0-9.]//g')
    local int_part=${num%%.*}

    if [[ "$raw" == *T* ]]; then
        echo "${int_part} TB"
    elif [[ "$raw" == *G* ]]; then
        if   (( int_part > 460 && int_part < 520 )); then echo "512 GB"
        elif (( int_part > 220 && int_part < 260 )); then echo "256 GB"
        elif (( int_part > 110 && int_part < 130 )); then echo "128 GB"
        elif (( int_part > 920 && int_part < 1030 )); then echo "1 TB"
        elif (( int_part > 1800 && int_part < 2050 )); then echo "2 TB"
        else echo "${int_part} GB"
        fi
    else
        echo "$raw"
    fi
}

_draw_storage_info() {
    local TITLE="STORAGE INFORMATION"

    local C1=14 C2=16 C3=18 C4=10 C5=16
    local INNER_W=$((C1 + 3 + C2 + 3 + C3 + 3 + C4 + 3 + C5))

    printf -v _b1 "%*s" "$C1" ""; _b1="${_b1// /═}"
    printf -v _b2 "%*s" "$C2" ""; _b2="${_b2// /═}"
    printf -v _b3 "%*s" "$C3" ""; _b3="${_b3// /═}"
    printf -v _b4 "%*s" "$C4" ""; _b4="${_b4// /═}"
    printf -v _b5 "%*s" "$C5" ""; _b5="${_b5// /═}"
    local BT="${_b1}═╤═${_b2}═╤═${_b3}═╤═${_b4}═╤═${_b5}"
    local BB="${_b1}═╧═${_b2}═╧═${_b3}═╧═${_b4}═╧═${_b5}"

    printf -v _m1 "%*s" "$C1" ""; _m1="${_m1// /─}"
    printf -v _m2 "%*s" "$C2" ""; _m2="${_m2// /─}"
    printf -v _m3 "%*s" "$C3" ""; _m3="${_m3// /─}"
    printf -v _m4 "%*s" "$C4" ""; _m4="${_m4// /─}"
    printf -v _m5 "%*s" "$C5" ""; _m5="${_m5// /─}"
    local BM="${_m1}─┼─${_m2}─┼─${_m3}─┼─${_m4}─┼─${_m5}"

    local TL=${#TITLE}
    local LP=$(( (INNER_W - TL) / 2 ))
    local RP=$(( INNER_W - TL - LP ))
    printf -v LSP "%*s" "$LP" ""
    printf -v RSP "%*s" "$RP" ""

    echo ""
    echo -e "  ${TURQUOISE}╔═${BT}═╗${END}"
    echo -e "  ${TURQUOISE}║${END} ${LSP}${BOLD}${TITLE}${END}${RSP} ${TURQUOISE}║${END}"
    echo -e "  ${TURQUOISE}╠═${BT}═╣${END}"

    printf "  ${TURQUOISE}║${END} %-${C1}s ${TURQUOISE}│${END} %-${C2}s ${TURQUOISE}│${END} %-${C3}s ${TURQUOISE}│${END} %-${C4}s ${TURQUOISE}│${END} %-${C5}s ${TURQUOISE}║${END}\n" \
        "Device" "Part Number" "Brand" "Size" "Serial"

    echo -e "  ${TURQUOISE}╟─${BM}─╢${END}"

    lsblk -d -n -o NAME,SIZE,TYPE | awk '$3=="disk"{print $1,$2}' | while read -r dev raw_size; do
        local FULL_MODEL SERIAL PART_NUM BRAND NORM_SIZE

        FULL_MODEL=$(udevadm info --query=property --name="/dev/$dev" 2>/dev/null \
            | grep '^ID_MODEL=' | sed 's/^ID_MODEL=//')
        SERIAL=$(udevadm info --query=property --name="/dev/$dev" 2>/dev/null \
            | grep '^ID_SERIAL_SHORT=' | sed 's/^ID_SERIAL_SHORT=//')

        SERIAL=${SERIAL:-N/A}
        FULL_MODEL=${FULL_MODEL:-Unknown}

        # First word = part number, rest = brand
        PART_NUM=$(echo "$FULL_MODEL" | awk '{print $1}')
        BRAND=$(echo "$FULL_MODEL" | awk '{$1=""; print}' | xargs)
        [ -z "$BRAND" ] && BRAND="Unknown"

        NORM_SIZE=$(_normalize_disk_size "$raw_size")

        printf "  ${TURQUOISE}║${END} %-${C1}s ${TURQUOISE}│${END} %-${C2}s ${TURQUOISE}│${END} %-${C3}s ${TURQUOISE}│${END} %-${C4}s ${TURQUOISE}│${END} %-${C5}s ${TURQUOISE}║${END}\n" \
            "/dev/$dev" "$PART_NUM" "$BRAND" "$NORM_SIZE" "$SERIAL"
    done

    echo -e "  ${TURQUOISE}╚═${BB}═╝${END}"
}
