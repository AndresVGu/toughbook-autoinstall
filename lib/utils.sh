#!/usr/bin/env bash
# Utility functions: spinner, banner, checks, draw helpers

# Traps Ctrl+C and exits gracefully
ctrl_c() {
    echo -e "\n\n${RED}[!] Closing Script...${END}\n"
    exit 1
}

check_internet() {
    if ping -c 1 -q google.com &>/dev/null; then
        echo "🌐 Internet connection detected. Continuing..."
    else
        echo "❌ No Internet connection. Exiting script."
        exit 1
    fi
}

SPINNER_PID=""

spinner_start() {
    local msg="$1"
    local spin='|/-\'
    local i=0

    tput civis 2>/dev/null

    (
        while true; do
            i=$(( (i + 1) % 4 ))
            printf "\r${TURQUOISE}%s ${GREEN}%c${END}" "$msg" "${spin:$i:1}"
            sleep 0.1
        done
    ) &

    SPINNER_PID=$!
}

spinner_stop() {
    local status="$1"
    kill "$SPINNER_PID" 2>/dev/null
    wait "$SPINNER_PID" 2>/dev/null

    printf "\r\033[K"

    case "$status" in
        OK)   printf "${GREEN}✔ %s${END}\n" "Done" ;;
        WARN) printf "${YELLOW}⚠ %s${END}\n" "Warning" ;;
        FAIL) printf "${RED}✖ %s${END}\n" "Failed" ;;
        *)    echo ;;
    esac

    tput cnorm 2>/dev/null
}

check_version() {
    echo "🔄 Checking for updates..."

    git fetch origin >/dev/null 2>&1

    LOCAL_HASH=$(git rev-parse HEAD)
    REMOTE_HASH=$(git rev-parse @{u})

    if [[ "$LOCAL_HASH" != "$REMOTE_HASH" ]]; then
        echo "⬆️ Update found. Updating script..."
        git pull --quiet
        echo "🔁 Script updated. Restarting..."
        sleep 1
        exec "$0" "$@"
    else
        echo "✅ Script is already up to date."
    fi
}

show_banner() {
    clear
    echo -e "${TURQUOISE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║   ████████╗ ██████╗ ██╗   ██╗ ██████╗ ██╗  ██╗             ║"
    echo "║   ╚══██╔══╝██╔═══██╗██║   ██║██╔════╝ ██║ ██╔╝             ║"
    echo "║      ██║   ██║   ██║██║   ██║██║  ███╗█████╔╝              ║"
    echo "║      ██║   ██║   ██║██║   ██║██║   ██║██╔═██╗              ║"
    echo "║      ██║   ╚██████╔╝╚██████╔╝╚██████╔╝██║  ██╗             ║"
    echo "║      ╚═╝    ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝             ║"
    echo "║                                                            ║"
    echo "║        Panasonic Toughbook OEM Utility                     ║"
    echo "║        Ubuntu LTS   AutoInstall                            ║"
    echo "║                                                            ║"
    echo "║        Author: Andres Villarreal (@4vs3c)                  ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${END}"
    echo -e "${GRAY}🔧 Refurb • QA • OEM Preparation • Device Validation${END}\n"
    sleep 1.2
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        show_banner
        echo -e "\n${RED}[!] This script must be run as root!${END}\n"
        exit 1
    fi
}

# Draws a title box with model and OS info
draw_box() {
    local linux_os
    linux_os=$(neofetch --stdout | grep 'OS:' | awk -F': ' '{print $2}' | awk '{print $1, $2}')

    local UNIT_TEXT="$1"
    local TEXT_LEN=${#UNIT_TEXT}
    local OS_LEN=${#linux_os}
    local BORDER_CHAR="*"
    local BORDER_LEN=$((TEXT_LEN + 2))

    printf -v BORDER_LINE "%*s" $BORDER_LEN ""
    BORDER_LINE="${BORDER_LINE// /$BORDER_CHAR}"

    local DIFF=$((TEXT_LEN - OS_LEN))
    local LEFT_PAD=$(( (DIFF / 2) + 1 ))
    local RIGHT_PAD=$(( TEXT_LEN - OS_LEN - LEFT_PAD + 2))

    if [ $LEFT_PAD -lt 1 ]; then
        LEFT_PAD=1
        RIGHT_PAD=1
    fi

    printf -v LEFT_SPACES "%*s" $LEFT_PAD ""
    printf -v RIGHT_SPACES "%*s" $RIGHT_PAD ""

    echo -e "${TURQUOISE} +${BORDER_LINE}+ ${END}\n${TURQUOISE} | ${UNIT_TEXT} | ${END}\n${TURQUOISE} |${LEFT_SPACES}${linux_os}${RIGHT_SPACES}| ${END}\n${TURQUOISE} +${BORDER_LINE}+ ${END}"
}

# Detects and normalizes the Toughbook model.
# Sets globals: brand, model, serial, part_number, cpu, menu_type
detect_model() {
    brand=$(sudo dmidecode -s system-manufacturer | awk '{print $1}' 2>/dev/null)
    model=$(sudo dmidecode -s system-product-name \
        | sed -r 's/([A-Z]{2})([0-9]{2})-([0-9])/\1-\2 MK\3/' 2>/dev/null)
    serial=$(sudo dmidecode -s system-serial-number 2>/dev/null)
    part_number=$(sudo dmidecode -s system-sku-number 2>/dev/null)
    cpu=$(lscpu | grep "BIOS Model name:" | sed 's/BIOS Model name:\s*//')
    menu_type="main"

    case "$model" in
        "CF-54-2")
            model="CF-54 Mk2"
            ;;
        "CF-54-3")
            model="CF-54 Mk3"
            ;;
        "FZ-G1A"*)
            model="FZ-G1 MK1"
            part_number=$(sudo dmidecode -s system-product-name \
                | sed -r 's/([A-Z]{2})([0-9]{2})-([0-9])/\1-\2 MK\3/' 2>/dev/null)
            cpu=$(lscpu | grep "Model name:" | sed 's/Model name:\s*//')
            menu_type="g1"
            ;;
        "CF-53 MK4")
            cpu=$(lscpu | grep "Model name:" | sed 's/Model name:\s*//')
            ;;
        "CF-C2C"*)
            model="CF-C2 MK2"
            menu_type="c2"
            ;;
    esac
}

# Draws a generic info box with label:value pairs (pure ASCII aligned)
drawInfo_box() {
    local TITLE="$1"
    shift
    local ITEMS=("$@")

    local LABEL_W=18
    local VALUE_W=40
    local INNER_W=$((LABEL_W + 3 + VALUE_W))

    # Borders
    printf -v _bL "%*s" "$LABEL_W" ""; _bL="${_bL// /═}"
    printf -v _bV "%*s" "$VALUE_W" ""; _bV="${_bV// /═}"
    local BORDER_TOP="${_bL}═╤═${_bV}"
    local BORDER_BOT="${_bL}═╧═${_bV}"

    printf -v _mL "%*s" "$LABEL_W" ""; _mL="${_mL// /─}"
    printf -v _mV "%*s" "$VALUE_W" ""; _mV="${_mV// /─}"
    local BORDER_MID="${_mL}─┼─${_mV}"

    # Title centering
    local TITLE_LEN=${#TITLE}
    local LP=$(( (INNER_W - TITLE_LEN) / 2 ))
    local RP=$(( INNER_W - TITLE_LEN - LP ))
    printf -v LSP "%*s" "$LP" ""
    printf -v RSP "%*s" "$RP" ""

    echo -e "${TURQUOISE}╔═${BORDER_TOP}═╗${END}"
    echo -e "${TURQUOISE}║${END} ${LSP}${TITLE}${RSP} ${TURQUOISE}║${END}"
    echo -e "${TURQUOISE}╠═${BORDER_TOP}═╣${END}"

    local first_item=true
    for item in "${ITEMS[@]}"; do
        local label="${item%%:*}"
        local value="${item#*:}"
        value="${value# }"

        if ! $first_item; then
            echo -e "${TURQUOISE}╟─${BORDER_MID}─╢${END}"
        fi
        first_item=false

        # Word-wrap value
        local first_line=1
        local line=""

        for word in $value; do
            if (( ${#line} + ${#word} + 1 > VALUE_W )); then
                if (( first_line )); then
                    printf "${TURQUOISE}║${END} %-${LABEL_W}s ${TURQUOISE}│${END} ${GREEN}%-${VALUE_W}s${END} ${TURQUOISE}║${END}\n" \
                        "$label" "$line"
                    first_line=0
                else
                    printf "${TURQUOISE}║${END} %-${LABEL_W}s ${TURQUOISE}│${END} ${GREEN}%-${VALUE_W}s${END} ${TURQUOISE}║${END}\n" \
                        "" "$line"
                fi
                line="$word"
            else
                line="${line:+$line }$word"
            fi
        done

        if (( first_line )); then
            printf "${TURQUOISE}║${END} %-${LABEL_W}s ${TURQUOISE}│${END} ${GREEN}%-${VALUE_W}s${END} ${TURQUOISE}║${END}\n" \
                "$label" "$line"
        else
            printf "${TURQUOISE}║${END} %-${LABEL_W}s ${TURQUOISE}│${END} ${GREEN}%-${VALUE_W}s${END} ${TURQUOISE}║${END}\n" \
                "" "$line"
        fi
    done

    echo -e "${TURQUOISE}╚═${BORDER_BOT}═╝${END}"
}
