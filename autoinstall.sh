#!/usr/bin/env bash

#
# Panasonic Toughbook OEM Utility — AutoInstall
# Author: Andres Villarreal (a.k.a. @4vs3c)
#
# Entry point: sources all modules and launches the appropriate menu
# based on the detected Toughbook model.
#

# ── Resolve script directory (works even via symlinks) ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Load modules ──
source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/sysinfo.sh"
source "$SCRIPT_DIR/lib/detection.sh"
source "$SCRIPT_DIR/lib/drivers.sh"
source "$SCRIPT_DIR/lib/tools.sh"
source "$SCRIPT_DIR/lib/oem.sh"
source "$SCRIPT_DIR/lib/menus.sh"

# ── Trap Ctrl+C ──
trap ctrl_c INT

# ── Startup checks ──
check_root
show_banner
check_internet
check_version

# ── Detect model and launch menu ──
menu_model=$(sudo dmidecode -s system-product-name \
    | sed -r 's/([A-Z]{2})([0-9]{2})-([0-9])/\1-\2 MK\3/' 2>/dev/null)

case "$menu_model" in
    "CF-54-2")
        menu_model="CF-54 Mk2"
        main_menu
        ;;
    "CF-54-3")
        menu_model="CF-54 Mk3"
        main_menu
        ;;
    "FZ-G1A"*)
        menu_model="FZ-G1 MK1"
        g1_main_menu
        ;;
    "CF-C2C"*)
        menu_model="CF-C2 MK2"
        c2_main_menu
        ;;
    "CF-53 MK4")
        main_menu
        ;;
    *)
        main_menu
        ;;
esac
