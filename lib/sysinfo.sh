#!/usr/bin/env bash
# System information collection: hardware specs, battery, storage, RAM

collect_info() {

    # ── Dependencies ──
    command -v dmidecode &>/dev/null || { echo -e "${YELLOW}[+] Installing dmidecode...${END}"; sudo apt install dmidecode -y; }
    command -v neofetch  &>/dev/null || { echo -e "${YELLOW}[+] Installing neofetch...${END}";  sudo apt install neofetch -y; }
    command -v netstat   &>/dev/null || { echo -e "${YELLOW}[+] Installing net-tools...${END}"; sudo apt install net-tools -y; echo "export PATH=\$PATH:/sbin" >> ~/.bashrc; }
    command -v acpi      &>/dev/null || { echo -e "${YELLOW}[+] Installing acpi...${END}";      sudo apt install acpi -y; }

    # ── System identity ──
    brand=$(sudo dmidecode -s system-manufacturer | awk '{print $1}' 2>/dev/null)
    model=$(sudo dmidecode -s system-product-name | sed -r 's/([A-Z]{2})([0-9]{2})-([0-9])/\1-\2 MK\3/' 2>/dev/null)
    serial=$(sudo dmidecode -s system-serial-number 2>/dev/null)
    part_number=$(sudo dmidecode -s system-sku-number 2>/dev/null)
    cpu=$(lscpu | grep "BIOS Model name:" | sed 's/BIOS Model name:\s*//')

    case "$model" in
        "CF-54-2")
            model="CF-54 Mk2"
            ;;
        "CF-54-3")
            model="CF-54 Mk3"
            ;;
        "FZ-G1A"*)
            model="FZ-G1 MK1"
            part_number=$(sudo dmidecode -s system-product-name | sed -r 's/([A-Z]{2})([0-9]{2})-([0-9])/\1-\2 MK\3/' 2>/dev/null)
            cpu=$(lscpu | grep "Model name:" | sed 's/Model name:\s*//')
            ;;
        "CF-53 MK4")
            cpu=$(lscpu | grep "Model name:" | sed 's/Model name:\s*//')
            ;;
        "CF-C2C"*)
            model="CF-C2 MK2"
            ;;
    esac

    # ── Hours ──
    hours=$(sudo dmidecode -t 22 2>/dev/null | grep "Hours" | awk '{print $2}')
    [ -z "$hours" ] && hours=$(uptime -p)

    # ── RAM ──
    ram_gb=$(free -h | awk '/Mem:/ {sub(/[a-zA-Z]/,"",$2); print int($2+0.5)}')
    ram_type=$(sudo dmidecode -t memory | grep -E "Type:.*DDR" | awk '{print $2}' | head -n1)

    ram_size_a=$(sudo dmidecode -t memory | grep -E "Size:" | sed -n '1p' | sed 's/.*: //')
    [ -z "$ram_size_a" ] && ram_size_a=" "

    ram_size_b=$(sudo dmidecode -t memory | grep -E "Size:" | sed -n '2p' | sed 's/.*: //')
    [ -z "$ram_size_b" ] && ram_size_b=" "

    # ── Battery ──
    BAT_INFO=$(acpi -b 2>/dev/null)
    bat_present=false
    bat_state="Unknown"
    bat_percent="N/A"
    bat_charging_icon="[X]"

    if [[ -n "$BAT_INFO" ]]; then
        bat_present=true
        bat_state=$(echo "$BAT_INFO" | awk -F': ' '{print $2}' | awk -F',' '{print $1}')
        bat_percent=$(echo "$BAT_INFO" | grep -o '[0-9]\+%' | tr -d '%')

        case "$bat_state" in
            Charging)    bat_charging_icon="[⚡]" ;;
            Discharging) bat_charging_icon="[!]"  ;;
            Full)        bat_charging_icon="[√]"  ;;
        esac
    fi

    bat_health=$(acpi -V | grep "mAh" | grep -o "[0-9]\+%")
    bat_status_1=$(acpi -V 2>/dev/null | awk -F, '/Battery/{print $2; exit}' | xargs)

    local clean_value=${bat_health%\%}
    local clean_value_int=$((clean_value))
    local bat_message=""

    if [ "$clean_value_int" -gt 85 ]; then
        bat_message=" OK - Suitable for Amazon"
    elif [ "$clean_value_int" -gt 80 ]; then
        bat_message=" OK - Suitable for Shopify"
    elif [ "$clean_value_int" -gt 1 ]; then
        bat_message="[!] Lower than 80% - Suitable for orders without guaranteed battery life."
    else
        bat_message="[X] No Battery Detected"
    fi

    # ── CPU short name ──
    local cpu_short="$cpu"
    if [[ $cpu =~ (i[0-9]-[0-9A-Z]+) ]]; then
        cpu_short="Intel ${BASH_REMATCH[1]}"
    fi

    # ── Display ──
    spinner_start "Collecting system information"
    sleep 2
    spinner_stop OK

    drawInfo_box "SYSTEM INFORMATION" \
        "Brand: $brand" \
        "Model: $model" \
        "Part Number: $part_number" \
        "Serial Number: $serial" \
        "CPU: $cpu_short"

    local batStatus="$bat_charging_icon ($bat_status_1) $bat_state"

    drawInfo_box "BATTERY INFORMATION" \
        "Status:    $batStatus" \
        "Health: $bat_health" \
        "Recommendation: $bat_message"

    _draw_storage_info

    drawInfo_box "MEMORY INFORMATION" \
        "RAM Total: $ram_gb GB" \
        "RAM Type: $ram_type" \
        "Slot [1]: ${ram_size_a}" \
        "Slot [2]: ${ram_size_b}"

    echo -e "${YELLOW}TO SCROLL UP OR DOWN IN THE CONSOLE USE:${END}"
    echo -e "${YELLOW}[${END} ${TURQUOISE}Ctrl + Shift { ⬆️  or ⬇️  }${END} ${YELLOW}]${END}"
}

_draw_storage_info() {
    local TITLE="STORAGE INFORMATION"
    local BORDER_CHAR="═"

    local TERM_WIDTH
    TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
    local SAFE_MARGIN=6
    local MAX_BOX_WIDTH=$((TERM_WIDTH - SAFE_MARGIN))

    local HEADERS=("Device" "Size" "Serial" "Model")
    local COL_WIDTHS=(10 10 20 30)

    local TOTAL_COL_WIDTH=$((COL_WIDTHS[0]+COL_WIDTHS[1]+COL_WIDTHS[2]+COL_WIDTHS[3]+5))
    if (( TOTAL_COL_WIDTH > MAX_BOX_WIDTH )); then
        COL_WIDTHS[3]=$((MAX_BOX_WIDTH - (COL_WIDTHS[0]+COL_WIDTHS[1]+COL_WIDTHS[2]+5)))
        (( COL_WIDTHS[3] < 15 )) && COL_WIDTHS[3]=15
    fi

    local CONTENT_WIDTH=$((COL_WIDTHS[0]+COL_WIDTHS[1]+COL_WIDTHS[2]+COL_WIDTHS[3]+5))
    local BOX_WIDTH=$((CONTENT_WIDTH + 2))

    printf -v BORDER_LINE "%*s" "$BOX_WIDTH" ""
    BORDER_LINE="${BORDER_LINE// /$BORDER_CHAR}"

    local TITLE_LEN=${#TITLE}
    local LP=$(( (CONTENT_WIDTH - TITLE_LEN) / 2 ))
    local RP=$(( CONTENT_WIDTH - TITLE_LEN - LP ))
    printf -v LSP "%*s" "$LP" ""
    printf -v RSP "%*s" "$RP" ""

    echo -e "${TURQUOISE}╔${BORDER_LINE}╗${END}"
    echo -e "${TURQUOISE}║${END} ${LSP}${TITLE}${RSP} ${TURQUOISE}║${END}"
    echo -e "${TURQUOISE}╠${BORDER_LINE}╣${END}"

    printf "${TURQUOISE}║${END} %-*s %-*s %-*s %-*s ${TURQUOISE}║${END}\n" \
        "${COL_WIDTHS[0]}" "${HEADERS[0]}" \
        "${COL_WIDTHS[1]}" "${HEADERS[1]}" \
        "${COL_WIDTHS[2]}" "${HEADERS[2]}" \
        "${COL_WIDTHS[3]}" "${HEADERS[3]}"

    echo -e "${TURQUOISE}╠${BORDER_LINE}╣${END}"

    lsblk -d -n -o NAME,SIZE,TYPE | awk '$3=="disk"{print $1,$2}' | while read -r dev size; do
        local SERIAL MODEL

        SERIAL=$(udevadm info --query=property --name="/dev/$dev" 2>/dev/null \
            | grep '^ID_SERIAL_SHORT=' | sed 's/^ID_SERIAL_SHORT=\([^_]*\).*/\1/')
        MODEL=$(udevadm info --query=property --name="/dev/$dev" 2>/dev/null \
            | grep '^ID_MODEL=' | sed 's/^ID_MODEL=\([^_]*\).*/\1/')

        SERIAL=${SERIAL:-N/A}
        MODEL=${MODEL:-Unknown}

        printf "${TURQUOISE}║${END} %-*s %-*s %-*s %-*s ${TURQUOISE}║${END}\n" \
            "${COL_WIDTHS[0]}" "/dev/$dev" \
            "${COL_WIDTHS[1]}" "$size" \
            "${COL_WIDTHS[2]}" "$SERIAL" \
            "${COL_WIDTHS[3]}" "$MODEL"
    done

    echo -e "${TURQUOISE}╚${BORDER_LINE}╝${END}"
}
