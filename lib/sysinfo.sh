#!/usr/bin/env bash
# System information collection: hardware specs, battery, storage, RAM

# ── Side-by-side box renderer ──
# Renders two boxes next to each other from pre-built line arrays
_render_side_by_side() {
    local -n _left=$1
    local -n _right=$2
    local left_count=${#_left[@]}
    local right_count=${#_right[@]}
    local max=$(( left_count > right_count ? left_count : right_count ))

    # Get raw width of left box (strip ANSI codes to measure)
    local left_w=0
    if (( left_count > 0 )); then
        local stripped
        stripped=$(echo -e "${_left[0]}" | sed 's/\x1b\[[0-9;]*m//g')
        left_w=${#stripped}
    fi

    for (( i=0; i<max; i++ )); do
        local l="${_left[$i]:-}"
        local r="${_right[$i]:-}"

        if [[ -n "$l" ]]; then
            printf "%s" "$(echo -e "$l")"
        else
            printf "%-${left_w}s" ""
        fi

        printf "  "

        if [[ -n "$r" ]]; then
            echo -e "$r"
        else
            echo ""
        fi
    done
}

# ── Compact info box builder ──
# Builds box lines into an array variable instead of printing
# Usage: _build_box "ARRAY_NAME" "TITLE" "label1:value1" "label2:value2" ...
_build_box() {
    local -n _out=$1
    local TITLE="$2"
    shift 2
    local ITEMS=("$@")

    local LW=16
    local VW=22
    local IW=$((LW + 3 + VW))

    printf -v _bL "%*s" "$LW" ""; _bL="${_bL// /═}"
    printf -v _bV "%*s" "$VW" ""; _bV="${_bV// /═}"
    local BT="${_bL}═╤═${_bV}"
    local BB="${_bL}═╧═${_bV}"
    printf -v _mL "%*s" "$LW" ""; _mL="${_mL// /─}"
    printf -v _mV "%*s" "$VW" ""; _mV="${_mV// /─}"
    local BM="${_mL}─┼─${_mV}"

    local TL=${#TITLE}
    local LP=$(( (IW - TL) / 2 ))
    local RP=$(( IW - TL - LP ))
    printf -v LSP "%*s" "$LP" ""
    printf -v RSP "%*s" "$RP" ""

    _out=()
    _out+=("  ${TURQUOISE}╔═${BT}═╗${END}")
    _out+=("  ${TURQUOISE}║${END} ${LSP}${BOLD}${TITLE}${END}${RSP} ${TURQUOISE}║${END}")
    _out+=("  ${TURQUOISE}╠═${BT}═╣${END}")

    local first=true
    for item in "${ITEMS[@]}"; do
        local label="${item%%:*}"
        local value="${item#*:}"
        value="${value# }"

        if ! $first; then
            _out+=("  ${TURQUOISE}╟─${BM}─╢${END}")
        fi
        first=false

        _out+=("$(printf "  ${TURQUOISE}║${END} %-${LW}s ${TURQUOISE}│${END} ${GREEN}%-${VW}s${END} ${TURQUOISE}║${END}" "$label" "$value")")
    done

    _out+=("  ${TURQUOISE}╚═${BB}═╝${END}")
}

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

    # ── RAM (with serials and calculated total) ──
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

    # Calculate total RAM from slot sizes
    local size_a_mb=0 size_b_mb=0
    if [[ "$ram_size_a_raw" =~ ([0-9]+) ]]; then size_a_mb=${BASH_REMATCH[1]}; fi
    if [[ "$ram_size_b_raw" =~ ([0-9]+) ]]; then size_b_mb=${BASH_REMATCH[1]}; fi
    local total_ram_mb=$(( size_a_mb + size_b_mb ))

    local total_ram_display
    if (( total_ram_mb >= 1024 )); then
        total_ram_display="$((total_ram_mb / 1024)) GB"
    else
        total_ram_display="${total_ram_mb} MB"
    fi

    local slot_a_display="${ram_size_a_raw}"
    [[ "$slot_a_display" != "Empty" ]] && slot_a_display="${ram_size_a_raw} (${ram_serial_a})"
    local slot_b_display="${ram_size_b_raw}"
    [[ "$slot_b_display" != "Empty" ]] && slot_b_display="${ram_size_b_raw} (${ram_serial_b})"

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
        bat_message="OK - Amazon"
    elif [ "$clean_value_int" -gt 80 ]; then
        bat_message="OK - Shopify"
    elif [ "$clean_value_int" -gt 1 ]; then
        bat_message="Low - No guarantee"
    else
        bat_message="No Battery"
    fi

    # ── CPU short name ──
    local cpu_short="$cpu"
    if [[ $cpu =~ (i[0-9]-[0-9A-Z]+) ]]; then
        cpu_short="Intel ${BASH_REMATCH[1]}"
    fi

    # ── Collect done ──
    spinner_start "Collecting system information"
    sleep 1
    spinner_stop OK

    # ── Build boxes ──
    local -a box_sys box_bat box_mem

    _build_box box_sys "SYSTEM INFORMATION" \
        "Brand: $brand" \
        "Model: $model" \
        "Part Number: $part_number" \
        "Serial: $serial" \
        "CPU: $cpu_short"

    local batStatus="$bat_charging_icon $bat_state ($bat_status_1)"

    _build_box box_bat "BATTERY" \
        "Status: $batStatus" \
        "Health: $bat_health" \
        "Rating: $bat_message"

    _build_box box_mem "MEMORY" \
        "Total: $total_ram_display" \
        "Type: $ram_type" \
        "Slot 1: $slot_a_display" \
        "Slot 2: $slot_b_display"

    # ── Render side by side ──
    echo ""
    _render_side_by_side box_sys box_bat
    echo ""
    _draw_storage_info_and_mem box_mem

    echo ""
    echo -e "  ${DIM}Scroll: Ctrl + Shift + Up/Down${END}"

    local elapsed=$(( SECONDS - start ))
    msg_time "[Device Information] $((elapsed / 60))m $((elapsed % 60))s"
}

_draw_storage_info_and_mem() {
    local -n _mem_box=$1

    # Build storage lines
    local -a box_sto
    local C1=12 C2=8 C3=22 C4=20
    local IW=$((C1 + 3 + C2 + 3 + C3 + 3 + C4))

    printf -v _b1 "%*s" "$C1" ""; _b1="${_b1// /═}"
    printf -v _b2 "%*s" "$C2" ""; _b2="${_b2// /═}"
    printf -v _b3 "%*s" "$C3" ""; _b3="${_b3// /═}"
    printf -v _b4 "%*s" "$C4" ""; _b4="${_b4// /═}"
    local BT="${_b1}═╤═${_b2}═╤═${_b3}═╤═${_b4}"
    local BB="${_b1}═╧═${_b2}═╧═${_b3}═╧═${_b4}"
    printf -v _m1 "%*s" "$C1" ""; _m1="${_m1// /─}"
    printf -v _m2 "%*s" "$C2" ""; _m2="${_m2// /─}"
    printf -v _m3 "%*s" "$C3" ""; _m3="${_m3// /─}"
    printf -v _m4 "%*s" "$C4" ""; _m4="${_m4// /─}"
    local BM="${_m1}─┼─${_m2}─┼─${_m3}─┼─${_m4}"

    local TITLE="STORAGE"
    local TL=${#TITLE}
    local LP=$(( (IW - TL) / 2 ))
    local RP=$(( IW - TL - LP ))
    printf -v LSP "%*s" "$LP" ""
    printf -v RSP "%*s" "$RP" ""

    box_sto+=("  ${TURQUOISE}╔═${BT}═╗${END}")
    box_sto+=("  ${TURQUOISE}║${END} ${LSP}${BOLD}${TITLE}${END}${RSP} ${TURQUOISE}║${END}")
    box_sto+=("  ${TURQUOISE}╠═${BT}═╣${END}")
    box_sto+=("$(printf "  ${TURQUOISE}║${END} %-${C1}s ${TURQUOISE}│${END} %-${C2}s ${TURQUOISE}│${END} %-${C3}s ${TURQUOISE}│${END} %-${C4}s ${TURQUOISE}║${END}" "Device" "Size" "Serial" "Model")")
    box_sto+=("  ${TURQUOISE}╟─${BM}─╢${END}")

    while read -r dev size; do
        local SERIAL MODEL
        SERIAL=$(udevadm info --query=property --name="/dev/$dev" 2>/dev/null \
            | grep '^ID_SERIAL_SHORT=' | sed 's/^ID_SERIAL_SHORT=\([^_]*\).*/\1/')
        MODEL=$(udevadm info --query=property --name="/dev/$dev" 2>/dev/null \
            | grep '^ID_MODEL=' | sed 's/^ID_MODEL=\([^_]*\).*/\1/')
        SERIAL=${SERIAL:-N/A}
        MODEL=${MODEL:-Unknown}

        box_sto+=("$(printf "  ${TURQUOISE}║${END} %-${C1}s ${TURQUOISE}│${END} %-${C2}s ${TURQUOISE}│${END} %-${C3}s ${TURQUOISE}│${END} %-${C4}s ${TURQUOISE}║${END}" "/dev/$dev" "$size" "$SERIAL" "$MODEL")")
    done < <(lsblk -d -n -o NAME,SIZE,TYPE | awk '$3=="disk"{print $1,$2}')

    box_sto+=("  ${TURQUOISE}╚═${BB}═╝${END}")

    # Print storage on left, memory on right
    _render_side_by_side box_sto _mem_box
}
