#!/usr/bin/env bash
# Interactive menus: main, C2, G1

_menu_header() {
    local title="$1"
    echo ""
    separator
    echo -e "  ${TURQUOISE}${BOLD}${title}${END}  ${DIM}(${brand} ${model})${END}"
    separator
}

_menu_option() {
    local key="$1"
    local icon="$2"
    local label="$3"
    printf "  ${WHITE}[${TURQUOISE}%s${WHITE}]${END}  %s  %s\n" "$key" "$icon" "$label"
}

_menu_prompt() {
    echo ""
    read -rp "  $(echo -e "${TURQUOISE}>${END}") " choice
}

_menu_exit() {
    echo ""
    separator
    msg_info "Session ended."
    echo ""
    exit 0
}

main_menu() {
    while true; do
        _menu_header "MAIN MENU"
        _menu_option "1" "📋" "Device Information"
        _menu_option "2" "🔍" "Hardware Detection"
        _menu_option "3" "📦" "Update & Install Drivers"
        _menu_option "4" "⌨ " "Keyboard Test"
        _menu_option "Q" "🚪" "Exit"
        _menu_prompt

        case "$choice" in
            1) echo ""; collect_info ;;
            2) echo ""; detect_devices "default" ;;
            3) echo ""; check_dependencies; install_drivers ;;
            4) echo ""; keyboard_test ;;
            s5p) prepare_environment ;;
            t6c) install_touch_calibrator "touch-calibrator.sh" "AutoCalibrate Fujitsu" "touch-calibration.desktop" ;;
            t7c) install_touch_calibrator "touch-calibrator-cf31.sh" "CF-31 MK5 Automatic-Calibration" "touch-calibrationcf31.desktop" ;;
            g8d) force_gdm ;;
            [qQ]) _menu_exit ;;
            *) msg_err "Invalid option." ;;
        esac
    done
}

c2_main_menu() {
    while true; do
        _menu_header "CF-C2 MENU"
        _menu_option "1" "📋" "Device Information"
        _menu_option "2" "🔍" "Hardware Detection"
        _menu_option "3" "📦" "Update & Install Drivers"
        _menu_option "4" "⌨ " "Keyboard Test"
        _menu_option "5" "🔊" "Sound Activation"
        _menu_option "Q" "🚪" "Exit"
        _menu_prompt

        case "$choice" in
            1) echo ""; collect_info ;;
            2) echo ""; detect_devices "c2" ;;
            3) echo ""; check_dependencies; install_drivers ;;
            4) echo ""; keyboard_test ;;
            5) echo ""; install_sound_autostart_c2; sleep 1 ;;
            s6p) prepare_environment_c2 ;;
            [qQ]) _menu_exit ;;
            *) msg_err "Invalid option." ;;
        esac
    done
}

g1_main_menu() {
    while true; do
        _menu_header "FZ-G1 MENU"
        _menu_option "1" "📋" "Device Information"
        _menu_option "2" "🔍" "Hardware Detection"
        _menu_option "3" "📦" "Update & Install Drivers"
        _menu_option "4" "🔊" "Sound Activation"
        _menu_option "5" "💾" "Disk Resize"
        _menu_option "Q" "🚪" "Exit"
        _menu_prompt

        case "$choice" in
            1) echo ""; collect_info ;;
            2) echo ""; detect_devices "g1" ;;
            3) echo ""; check_dependencies; install_drivers ;;
            4) echo ""; install_sound_autostart ;;
            5)
                echo ""
                sudo apt install -y cloud-guest-utils
                sudo growpart /dev/sda 5
                sudo resize2fs /dev/sda5
                msg_ok "Resize successful."
                ;;
            k6t) keyboard_test ;;
            [qQ]) _menu_exit ;;
            *) msg_err "Invalid option." ;;
        esac
    done
}
