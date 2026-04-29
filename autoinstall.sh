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
detect_model

case "$menu_type" in
    g1)  g1_main_menu ;;
    c2)  c2_main_menu ;;
    *)   main_menu ;;
esac
