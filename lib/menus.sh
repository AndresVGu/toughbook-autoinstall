#!/usr/bin/env bash
# Interactive menus: main, C2, G1

main_menu() {
    while true; do
        echo -e "\n${BLUE}--- Main Menu ---${END}"
        echo -e "[1] 🔎 Device Information"
        echo -e "[2] 🩺 Hardware Detection"
        echo -e "[3] ⚙️  Update Device"
        echo -e "[4] ⌨️  Test Keyboard"
        echo -e "⚠️ ${YELLOW}SYSPREP OPTION TEMPORARY DISABLED ${END} ⚠️"
        echo -e "⚠️ ${YELLOW}USE [Prepare for shipping end user] INSTEAD${END} ⚠️"
        echo -e "[q|Q] ↩️  Exit"
        read -rp "Select an option: " choice

        case "$choice" in
            1) collect_info ;;
            2) detect_devices "default" ;;
            3) check_dependencies; install_drivers ;;
            4) keyboard_test ;;
            5) prepare_environment ;;
            6) install_touch_calibrator "touch-calibrator.sh" "AutoCalibrate Fujitsu" "touch-calibration.desktop" ;;
            7) install_touch_calibrator "touch-calibrator-cf31.sh" "CF-31 MK5 Automatic-Calibration" "touch-calibrationcf31.desktop" ;;
            8) force_gdm ;;
            [qQ])
                echo -e "${RED}[*] Closing script...${END}"
                exit 0
                ;;
            *)
                echo -e "${RED}[!] Invalid option. Please try again.${END}"
                ;;
        esac
    done
}

c2_main_menu() {
    while true; do
        echo -e "\n${BLUE}--- Main Menu ---${END}"
        echo -e "[1] 🔎 Device Information"
        echo -e "[2] 🩺 Hardware Detection"
        echo -e "[3] ⚙️  Update Device"
        echo -e "[4] ⌨️  Test Keyboard"
        echo -e "[5] 🔊 Sound Activation"
        echo -e "[q|Q] ↩️  Exit"
        read -rp "Select an option: " choice

        case "$choice" in
            1) collect_info ;;
            2) detect_devices "c2" ;;
            3) check_dependencies; install_drivers ;;
            4) keyboard_test ;;
            5) install_sound_autostart_c2; sleep 1 ;;
            6) prepare_environment_c2 ;;
            [qQ])
                echo -e "${RED}[*] Closing script...${END}"
                exit 0
                ;;
            *)
                echo -e "${RED}[!] Invalid option. Please try again.${END}"
                ;;
        esac
    done
}

g1_main_menu() {
    while true; do
        echo -e "\n${BLUE}--- Main Menu ---${END}"
        echo -e "[1] 🔎 Device Information"
        echo -e "[2] 🩺 Hardware Detection"
        echo -e "[3] ⚙️  Update Device"
        echo -e "[4] 🔊 Sound Activation"
        echo -e "[5] Disk Resize"
        echo -e "⚠️ ${YELLOW}For SYSPREP use Prepare For Shipping To End User located on the Desktop${END} ⚠️"
        echo -e "[q|Q] ↩️  Exit"
        read -rp "Select an option: " choice

        case "$choice" in
            1) collect_info ;;
            2) detect_devices "g1" ;;
            3) check_dependencies; install_drivers ;;
            4) install_sound_autostart ;;
            5)
                sudo apt install -y cloud-guest-utils
                sudo growpart /dev/sda 5
                sudo resize2fs /dev/sda5
                echo -e "${GREEN}[+] Resize successful.${END}"
                ;;
            [qQ])
                echo -e "${RED}[*] Closing script...${END}"
                exit 0
                ;;
            *)
                echo -e "${RED}[!] Invalid option. Please try again.${END}"
                ;;
        esac
    done
}
