#!/usr/bin/env bash
# Utility functions: spinner, banner, checks, draw helpers

ctrl_c() {
    echo ""
    separator
    msg_err "Interrupted. Closing script..."
    echo ""
    exit 1
}

check_internet() {
    msg_info "Checking internet connection..."
    if ping -c 1 -q google.com &>/dev/null; then
        msg_ok "Internet connection detected."
    else
        msg_err "No internet connection. Exiting."
        exit 1
    fi
}

SPINNER_PID=""

spinner_start() {
    local msg="$1"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    tput civis 2>/dev/null

    (
        while true; do
            i=$(( (i + 1) % ${#spin} ))
            printf "\r  ${TURQUOISE}${spin:$i:1}${END} %s" "$msg"
            sleep 0.08
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
        OK)   msg_ok "Done" ;;
        WARN) msg_warn "Warning" ;;
        FAIL) msg_err "Failed" ;;
        *)    echo ;;
    esac

    tput cnorm 2>/dev/null
}

check_version() {
    msg_info "Checking for script updates..."

    if ! git rev-parse --git-dir &>/dev/null; then
        msg_warn "Not a git repository. Skipping."
        return
    fi

    if ! git remote get-url origin &>/dev/null; then
        msg_warn "No remote configured. Skipping."
        return
    fi

    if ! git fetch origin --quiet 2>/dev/null; then
        msg_warn "Could not reach remote. Skipping."
        return
    fi

    local LOCAL_HASH REMOTE_HASH
    LOCAL_HASH=$(git rev-parse HEAD 2>/dev/null)
    REMOTE_HASH=$(git rev-parse @{u} 2>/dev/null)

    if [[ -z "$REMOTE_HASH" ]]; then
        msg_warn "No upstream branch. Skipping."
        return
    fi

    if [[ "$LOCAL_HASH" != "$REMOTE_HASH" ]]; then
        msg_info "Update found. Pulling..."
        git pull --quiet
        msg_ok "Script updated. Restarting..."
        sleep 1
        exec "$0" "$@"
    else
        msg_ok "Script is up to date."
    fi
}

show_banner() {
    clear
    echo ""
    echo -e "${TURQUOISE}"
    echo "    ╔══════════════════════════════════════════════════╗"
    echo "    ║                                                  ║"
    echo "    ║   ████████╗ ██████╗ ██╗   ██╗ ██████╗ ██╗  ██╗  ║"
    echo "    ║   ╚══██╔══╝██╔═══██╗██║   ██║██╔════╝ ██║ ██╔╝  ║"
    echo "    ║      ██║   ██║   ██║██║   ██║██║  ███╗█████╔╝   ║"
    echo "    ║      ██║   ██║   ██║██║   ██║██║   ██║██╔═██╗   ║"
    echo "    ║      ██║   ╚██████╔╝╚██████╔╝╚██████╔╝██║  ██╗  ║"
    echo "    ║      ╚═╝    ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝  ║"
    echo "    ║                                                  ║"
    echo "    ║      Panasonic Toughbook OEM Utility              ║"
    echo "    ║      Ubuntu LTS AutoInstall                       ║"
    echo "    ║                                                  ║"
    echo "    ╚══════════════════════════════════════════════════╝"
    echo -e "${END}"
    echo -e "    ${DIM}Refurb  •  QA  •  OEM Preparation  •  Validation${END}"
    echo -e "    ${DIM}Author: Andres Villarreal (@4vs3c)${END}"
    echo ""
    sleep 1
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        show_banner
        msg_err "This script must be run as root!"
        echo -e "    ${DIM}Usage: sudo ./autoinstall.sh${END}\n"
        exit 1
    fi
}

# Draws a title box with model and OS info
draw_box() {
    local linux_os
    linux_os=$(neofetch --stdout 2>/dev/null | grep 'OS:' | awk -F': ' '{print $2}' | awk '{print $1, $2}')

    local UNIT_TEXT="$1"
    local W=${#UNIT_TEXT}
    local OS_W=${#linux_os}
    (( W < OS_W )) && W=$OS_W
    local BOX_W=$((W + 4))

    printf -v BORDER "%*s" "$BOX_W" ""
    BORDER="${BORDER// /─}"

    echo -e "  ${TURQUOISE}┌${BORDER}┐${END}"
    printf "  ${TURQUOISE}│${END}  %-${W}s  ${TURQUOISE}│${END}\n" "$UNIT_TEXT"
    printf "  ${TURQUOISE}│${END}  ${DIM}%-${W}s${END}  ${TURQUOISE}│${END}\n" "$linux_os"
    echo -e "  ${TURQUOISE}└${BORDER}┘${END}"
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

# Timer helper
timed() {
    local label="$1"
    shift
    local start=$SECONDS
    "$@"
    local elapsed=$(( SECONDS - start ))
    msg_time "[$label] completed in $((elapsed / 60))m $((elapsed % 60))s"
}

# Draws a generic info box with label:value pairs
drawInfo_box() {
    local TITLE="$1"
    shift
    local ITEMS=("$@")

    local LABEL_W=18
    local VALUE_W=40
    local INNER_W=$((LABEL_W + 3 + VALUE_W))

    printf -v _bL "%*s" "$LABEL_W" ""; _bL="${_bL// /═}"
    printf -v _bV "%*s" "$VALUE_W" ""; _bV="${_bV// /═}"
    local BORDER_TOP="${_bL}═╤═${_bV}"
    local BORDER_BOT="${_bL}═╧═${_bV}"

    printf -v _mL "%*s" "$LABEL_W" ""; _mL="${_mL// /─}"
    printf -v _mV "%*s" "$VALUE_W" ""; _mV="${_mV// /─}"
    local BORDER_MID="${_mL}─┼─${_mV}"

    local TITLE_LEN=${#TITLE}
    local LP=$(( (INNER_W - TITLE_LEN) / 2 ))
    local RP=$(( INNER_W - TITLE_LEN - LP ))
    printf -v LSP "%*s" "$LP" ""
    printf -v RSP "%*s" "$RP" ""

    echo ""
    echo -e "  ${TURQUOISE}╔═${BORDER_TOP}═╗${END}"
    echo -e "  ${TURQUOISE}║${END} ${LSP}${BOLD}${TITLE}${END}${RSP} ${TURQUOISE}║${END}"
    echo -e "  ${TURQUOISE}╠═${BORDER_TOP}═╣${END}"

    local first_item=true
    for item in "${ITEMS[@]}"; do
        local label="${item%%:*}"
        local value="${item#*:}"
        value="${value# }"

        if ! $first_item; then
            echo -e "  ${TURQUOISE}╟─${BORDER_MID}─╢${END}"
        fi
        first_item=false

        local first_line=1
        local line=""

        for word in $value; do
            if (( ${#line} + ${#word} + 1 > VALUE_W )); then
                if (( first_line )); then
                    printf "  ${TURQUOISE}║${END} %-${LABEL_W}s ${TURQUOISE}│${END} ${GREEN}%-${VALUE_W}s${END} ${TURQUOISE}║${END}\n" \
                        "$label" "$line"
                    first_line=0
                else
                    printf "  ${TURQUOISE}║${END} %-${LABEL_W}s ${TURQUOISE}│${END} ${GREEN}%-${VALUE_W}s${END} ${TURQUOISE}║${END}\n" \
                        "" "$line"
                fi
                line="$word"
            else
                line="${line:+$line }$word"
            fi
        done

        if (( first_line )); then
            printf "  ${TURQUOISE}║${END} %-${LABEL_W}s ${TURQUOISE}│${END} ${GREEN}%-${VALUE_W}s${END} ${TURQUOISE}║${END}\n" \
                "$label" "$line"
        else
            printf "  ${TURQUOISE}║${END} %-${LABEL_W}s ${TURQUOISE}│${END} ${GREEN}%-${VALUE_W}s${END} ${TURQUOISE}║${END}\n" \
                "" "$line"
        fi
    done

    echo -e "  ${TURQUOISE}╚═${BORDER_BOT}═╝${END}"
}
