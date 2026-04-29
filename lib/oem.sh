#!/usr/bin/env bash
# OEM environment preparation (Sysprep) and GDM configuration

force_gdm() {
    echo -e "${BLUE}[*] Forcing GDM as display manager...${END}"

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[ERROR] This function must be run as root.${END}"
        return 1
    fi

    if ! command -v gdm3 >/dev/null 2>&1 && ! systemctl list-unit-files | grep -q gdm; then
        echo -e "${RED}[ERROR] gdm3 is not installed.${END}"
        return 1
    fi

    echo "gdm3" > /etc/X11/default-display-manager
    systemctl enable gdm3 >/dev/null 2>&1 || {
        echo -e "${RED}[ERROR] Failed to enable gdm3.${END}"
        return 1
    }

    systemctl list-unit-files | grep -q sddm && systemctl disable sddm >/dev/null 2>&1

    mkdir -p /etc/gdm3
    cat > /etc/gdm3/custom.conf <<EOF
[daemon]
WaylandEnable=false
DefaultSession=gnome-xorg.desktop
EOF

    echo -e "${GREEN}[+] GDM configured successfully with GNOME on Xorg.${END}"
}

_oem_shutdown_countdown() {
    echo -e "👍 ${GREEN}System preparation is ready.${END}"
    echo -e "✨✨  ${YELLOW}Shutting down system in 5 seconds...${END}✨✨"
    for i in {5..1}; do
        echo "$i seconds..."
        sleep 1
    done
    sudo shutdown -h now
}

_install_oem_deps() {
    echo -e "${BLUE}[*] Installing OEM dependencies...${END}"
    sudo apt install -y oem-config-gtk oem-config-slideshow-ubuntu
    echo -e "${GREEN}[+] Dependencies installed successfully.${END}"
}

_run_oem_prepare() {
    echo -e "${PURPLE}[*] Initializing system preparation...${END}"
    if ! sudo oem-config-prepare; then
        echo -e "${RED}[-] OEM system initialization failed.${END}"
        exit 1
    fi
    _oem_shutdown_countdown
}

prepare_environment() {
    echo -e "\n${YELLOW}⚠️ WARNING: This action will prepare the system for OEM distribution.${END}"
    echo -e "It will delete the current user and perform a factory reset."
    read -rp "[y|Y] Continue | [n|N] Cancel: " choice

    case "$choice" in
        [yY])
            if command -v oem-config &>/dev/null; then
                _run_oem_prepare
            else
                _install_oem_deps
                _run_oem_prepare
            fi
            ;;
        [nN])
            echo -e "${BLUE}[*] Action canceled.${END}"
            ;;
        *)
            echo -e "${RED}🚫 Invalid option. Returning to the main menu.${END}"
            ;;
    esac
}

prepare_environment_c2() {
    echo -e "\n${YELLOW}⚠️ WARNING: This action will prepare the system for OEM distribution.${END}"
    echo -e "It will delete the current user and perform a factory reset."
    read -rp "[y|Y] Continue | [n|N] Cancel: " choice

    case "$choice" in
        [yY])
            _install_oem_deps

            echo -e "${BLUE}[*] Forcing GDM as display manager...${END}"
            echo "gdm3" > /etc/X11/default-display-manager

            _run_oem_prepare
            ;;
        [nN])
            echo -e "${BLUE}[*] Action canceled.${END}"
            ;;
        *)
            echo -e "${RED}🚫 Invalid option. Returning to the main menu.${END}"
            ;;
    esac
}
