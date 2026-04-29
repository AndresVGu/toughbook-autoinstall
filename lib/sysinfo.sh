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

    # ── RAM (parse Memory Device blocks from dmidecode) ──
    local dmi_mem
    dmi_mem=$(sudo dmidecode -t memory 2>/dev/null)

    ram_type=$(echo "$dmi_mem" | grep -E "^\s+Type:" | grep -v "Type Detail" | head -1 | awk '{print $2}')

    # Extract data from first Memory Device block (Slot 1)
    local slot1_block slot2_block
    slot1_block=$(echo "$dmi_mem" | awk '/^Handle.*DMI type 17/{n++} n==1' )
    slot2_block=$(echo "$dmi_mem" | awk '/^Handle.*DMI type 17/{n++} n==2' )

    local ram_size_a ram_size_b ram_serial_a ram_serial_b ram_mfg_a ram_mfg_b ram_pn_a ram_pn_b ram_slot_a ram_slot_b

    ram_size_a=$(echo "$slot1_block" | grep "^\s*Size:" | head -1 | sed 's/.*Size: //')
    ram_serial_a=$(echo "$slot1_block" | grep "Serial Number:" | head -1 | sed 's/.*Serial Number: //' | xargs)
    ram_mfg_a=$(echo "$slot1_block" | grep "Manufacturer:" | head -1 | sed 's/.*Manufacturer: //' | xargs)
    ram_pn_a=$(echo "$slot1_block" | grep "Part Number:" | head -1 | sed 's/.*Part Number: //' | xargs)
    ram_slot_a=$(echo "$slot1_block" | grep "Locator:" | grep -v "Bank" | head -1 | sed 's/.*Locator: //' | xargs)

    ram_size_b=$(echo "$slot2_block" | grep "^\s*Size:" | head -1 | sed 's/.*Size: //')
    ram_serial_b=$(echo "$slot2_block" | grep "Serial Number:" | head -1 | sed 's/.*Serial Number: //' | xargs)
    ram_mfg_b=$(echo "$slot2_block" | grep "Manufacturer:" | head -1 | sed 's/.*Manufacturer: //' | xargs)
    ram_pn_b=$(echo "$slot2_block" | grep "Part Number:" | head -1 | sed 's/.*Part Number: //' | xargs)
    ram_slot_b=$(echo "$slot2_block" | grep "Locator:" | grep -v "Bank" | head -1 | sed 's/.*Locator: //' | xargs)

    # Extract numeric GB from Size field ("16 GB" -> 16)
    local a_gb=0 b_gb=0
    [[ "$ram_size_a" =~ ([0-9]+) ]] && a_gb=${BASH_REMATCH[1]}
    [[ "$ram_size_b" =~ ([0-9]+) ]] && b_gb=${BASH_REMATCH[1]}

    # If size was in MB, convert
    if [[ "$ram_size_a" == *MB* ]] && (( a_gb >= 1024 )); then a_gb=$(( a_gb / 1024 )); fi
    if [[ "$ram_size_b" == *MB* ]] && (( b_gb >= 1024 )); then b_gb=$(( b_gb / 1024 )); fi

    local total_gb=$(( a_gb + b_gb ))

    # Fallback if dmidecode gave 0
    if (( total_gb == 0 )); then
        total_gb=$(free --giga 2>/dev/null | awk '/Mem:/ {print $2}')
        (( total_gb == 0 )) && total_gb=$(free -h | awk '/Mem:/ {sub(/[a-zA-Z]/,"",$2); print int($2+0.5)}')
    fi

    # Clean empty values
    [[ -z "$ram_size_a" || "$ram_size_a" == *"No Module"* ]] && a_gb=0
    [[ -z "$ram_size_b" || "$ram_size_b" == *"No Module"* ]] && b_gb=0
    [[ -z "$ram_serial_a" || "$ram_serial_a" == *"Not"* ]] && ram_serial_a="N/A"
    [[ -z "$ram_serial_b" || "$ram_serial_b" == *"Not"* ]] && ram_serial_b="N/A"
    [[ -z "$ram_mfg_a" || "$ram_mfg_a" == *"Not"* ]] && ram_mfg_a="N/A"
    [[ -z "$ram_mfg_b" || "$ram_mfg_b" == *"Not"* ]] && ram_mfg_b="N/A"
    [[ -z "$ram_pn_a" || "$ram_pn_a" == *"Not"* ]] && ram_pn_a="N/A"
    [[ -z "$ram_pn_b" || "$ram_pn_b" == *"Not"* ]] && ram_pn_b="N/A"
    [ -z "$ram_slot_a" ] && ram_slot_a="Slot 1"
    [ -z "$ram_slot_b" ] && ram_slot_b="Slot 2"

    # Format slot display
    local slot_a_display="Empty"
    (( a_gb > 0 )) && slot_a_display="${a_gb} GB | ${ram_mfg_a} | SN: ${ram_serial_a}"

    local slot_b_display="Empty"
    (( b_gb > 0 )) && slot_b_display="${b_gb} GB | ${ram_mfg_b} | SN: ${ram_serial_b}"

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
