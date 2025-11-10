#!/usr/bin/env bash

#
# Configuration script for Panasonic Toughbooks on Ubuntu 24
# Author: Andres Villarreal (a.k.a. @4vs3c)
#

# ==================== Colors ====================
readonly GREEN='\033[1;32m'
readonly END='\033[0m'
readonly RED='\033[1;31m'
readonly BLUE='\033[1;34m'
readonly YELLOW='\033[1;33m'
readonly PURPLE='\033[1;35m'
readonly TURQUOISE='\033[1;36m'
readonly GRAY='\033[1;37m'

# ==================== Utility Functions ====================

# Traps Ctrl+C and exits the script gracefully
ctrl_c() {
    echo -e "\n\n${RED}[!] Closing Script...${END}\n"
    exit 1
}

# Displays the script's banner
show_banner() {
    echo -e "\n${TURQUOISE}              _____            ______"
    echo -e "______ ____  ___  /______      ___   /_____________  /_______ __   /__    /_______"
    echo -e "_  __ \`/  / / /  __/  __ \\     __/  / _  \\_  ___// __/_/ __ \`/ /  /__ /  /__ __"
    echo -e "/ /_/ // /_/ // /_ / /_/ /     _/  / / / /(__  ) / /_ / /_/ / /  /__ /  /____"
    echo -e "\\__,_/ \\__,_/ \\__/ \\____/      /__/_/ /_//____/_ \\__/ \\__,_/ /_____//_____/ __"
    echo -e "${END}${YELLOW}(${END}${GRAY}By Andres V. ${END}${PURPLE}a.k.a. 4vs3c${END}${YELLOW})${END}${TURQUOISE}"
    echo -e "✨✨ For Ubuntu 24 & Panasonic Toughbooks${END} ✨✨"
    sleep 1.5
}



# Checks if the script is run with root privileges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        show_banner
        echo -e "\n${RED}[!] This script must be run as root!${END}\n"
        exit 1
    fi
}

#Neofetch
check_neofetch() {
    echo -e "${PURPLE}[!] Checking Dependencies...${END}"
    sleep 1

    sudo apt update -y
    sleep 0.5
    sudo apt upgrade -y

    sleep 1
    #Confirm dmidecode
    if command -v dmidecode &> /dev/null; then
        echo "[+] dmidecode alredy Installed."
    else
        echo "[!] Installing dmindecode..."
        sudo apt install dmidecode -y
    fi

    sleep 0.5
    #---------
    #nettools
    #---------
    #Confirm net-tools
    if command -v net-tools &> /dev/null; then
        echo "[+] net-tools already Installed."
    else
        echo "[!] Installing net-tools"
        sudo apt install net-tools -y
        sleep 1
        echo "export PATH=$PATH:/sbin" >> ~/.bashrc
    fi

    #Confirm acpi
    if command -v acpi &> /dev/null; then
        echo "[+] acpi already Installed."
    else    
        echo "[!] Installing acpi ..."
        sudo apt install acpi -y
    fi

    

    #--------
    #PYTHON
    #--------

    #Confirm python3
    if command -v python3 &> /dev/null; then
        echo "[+] python3 already Installed."
    else    
        echo "[!] Installing python3 ..."
        sudo apt install -y python3
        echo "[!] Installing Tkinter ..."
        sudo apt install -y python3-tk
    fi

    #Confirm pip3
    if command -v pip3 &> /dev/null; then
        echo "[+] pip3 already Installed."
    else    
        echo "[!] Installing pip3 ..."
        sudo apt install -y python3-pip
    fi

#------
#LibreOffice
#------
#Confirm python3
    if command -v libreoffice &> /dev/null; then
        echo "[+] LibreOffice already Installed."
    else    
        echo "[!] Installing Libreoffice ..."
        sudo snap install libreoffice
    fi

#---------
#-KeyTest-
#---------
    # Define la ruta completa de la carpeta Downloads
    sleep 1
    USER_DIR=$SUDO_USER
    DOWNLOADS_DIR="/home/$USER_DIR/Downloads"
    # Define el nombre de la carpeta de destino que crea git clone
    REPO_FOLDER="linux-keytest"
    # Define la ruta completa donde se esperaría encontrar la carpeta
    FULL_REPO_PATH="$DOWNLOADS_DIR/$REPO_FOLDER"
    # Define la URL del repositorio
    REPO_URL="https://github.com/AndresVGu/linux-keytest"

    echo "🔎 Verifing repository in $DOWNLOADS_DIR"

    # Verifica si la carpeta ya existe usando la ruta completa
   if [ -d "$FULL_REPO_PATH" ]; then
       echo "⚠️ **repository already on the system** (Directory $REPO_FOLDER already exist in $DOWNLOADS_DIR)"
   else
       echo "✅ Dierectory $REPO_FOLDER does not exist. Clonning in $DOWNLOADS_DIR..."
    
       # Clona el repositorio directamente en el directorio Downloads.
       # El comando 'git clone' creará automáticamente la carpeta 'linux-keytest' dentro de $DOWNLOADS_DIR.
       git clone "$REPO_URL" "$FULL_REPO_PATH"
    
       # Verifica si la clonación fue exitosa
       if [ $? -eq 0 ]; then
           echo "🎉 Repository has clonned succesfully $FULL_REPO_PATH"
       else
           echo "❌ ¡Error! Verify Internet connection and credentials"
       fi
    fi

    sleep 0.5
    echo -e "${YELLOW}[!] Collecting Device Information. ${END}"
    sleep 1

    #brand & model
    brand=$(sudo dmidecode -s system-manufacturer | awk '{print $1}' 2>/dev/null)
    model=$(sudo dmidecode -s system-product-name | sed -r 's/([A-Z]{2})([0-9]{2})-([0-9])/\1-\2 MK\3/' 2>/dev/null)

    #serial & part number
    serial=$(sudo dmidecode -s system-serial-number 2>/dev/null)
    part_number=$(sudo dmidecode -s system-sku-number 2>/dev/null)

    #hours
    hours=$(sudo dmidecode -t 22 2>/dev/null | grep "Hours" | awk '{print $2}')
    [ -z "$hours" ] && hours=$(uptime -p)

    #Procesor
    cpu=$(lscpu | grep "BIOS Model name:" | sed 's/BIOS Model name:\s*//')

    #RAM
    ram_gb=$(free -h | awk '/Mem:/ {sub(/[a-zA-Z]/,"",$2); print int($2+0.5)}')
    ram_type=$(sudo dmidecode -t memory | grep -E "Type:.*DDR" | awk '{print $2}' | head -n1)

    #slot 1
    ram_slot_a=$(sudo dmidecode -t memory | grep -E "Handle" | sed -n '3p' | awk '{print $2}' | cut -c1-6)
    [ -z "$ram_slot_a" ] && ram_slot_a=$(echo "Empty")

    ram_size_a=$(sudo dmidecode -t memory | grep -E "Size:" | sed -n '1p')
    [ -z "$ram_size_a" ] && ram_size_a=$(echo " ")

    ram_speed_a=$(sudo dmidecode -t memory 2>/dev/null | grep -E "Speed:" | head -n1 | awk '{print $2}')
    [ -z "$ram_speed_a" ] && ram_speed_a=$(echo " ")

    #slot 2
    ram_slot_b=$(sudo dmidecode -t memory | grep -E "Handle" | sed -n '6p' | awk '{print $2}' | cut -c1-6)
    [ -z "$ram_slot_b" ] && ram_slot_b=$(echo "Empty")

    ram_size_b=$(sudo dmidecode -t memory | grep -E "Size:" | sed -n '2p')
    [ -z "$ram_size_b" ] && ram_size_b=$(echo " ")

    ram_speed_b=$(sudo dmidecode -t memory 2>/dev/null | grep  -E "Speed:" | sed -n '3p' | awk '{print $2}')
    [ -z "$ram_speed_b" ] && ram_speed_b=$(echo " ")

    #Disks
    disks=$(lsblk -d -o TYPE,SIZE,SERIAL | grep "disk")
    [ -z "$disks" ] && disks=$(echo "Empty")
 
    #Battery
    
    #Healt
    bat_health=$(acpi -V | grep "mAh" | grep -o "[0-9]\+%")
    #Status
    bat_status=$(acpi -V | grep "Battery" | grep -o "[0-9]\+%" | sed -n '1p')
    clean_value=${bat_health%\%}
    bat_message=""
    
    if [ "$clean_value" -gt 85 ]; then
        bat_message="✅{GREEN} Recomended for Amazon Orders ${END}"
    elif [ "$clean_value" -gt 80 ]; then
        bat_message="✅${GREEN} Recomended for Shopify ${END}"
    elif [ "$clean_value" -gt 1 ]; then
        bat_message="⚠️${YELLOW} Battery Health lower than 80% ${END}" 
    else
        bat_message="❌${RED} No Battery Detected ${END}"
    fi

    #Information chart
    echo -e "${TURQUOISE}==================== PC INFO ====================${END}"
    echo -e "Brand:             $brand"
    echo -e "Model:             $model"
    echo -e "Part Number:       $part_number"
    echo -e "Serial Number      $serial"
    echo -e "Processor:         $cpu"
    echo -e "${TURQUOISE}-------------------- MEMORY ---------------------${END}"
    echo -e "RAM Total:  ${ram_gb} GB (${ram_type})"
    echo -e "Slot 1: ${ram_slot_a} ${ram_size_a}         Speed: ${ram_speed_a} MT/s"
    echo -e "Slot 2: ${ram_slot_b} ${ram_size_b}         Speed: ${ram_speed_b} MT/s"
    echo -e "${TURQUOISE}-------------------- Disks ----------------------${END}"
    echo "$disks"
    echo -e "${TURQUOISE}=================================================${END}"
    echo -e "${TURQUOISE}================ BATTERY INFO ===================${END}"
    echo -e "Power Status: $bat_status"
    echo -e "Battery Health: ${bat_health}   ||   ${bat_message}    "
}

# ==================== Core Functions ====================

# Detects connected USB devices
device_detection() {
    echo -e "${GREEN}[+] Starting device detection...${END}"
    echo -e "${YELLOW}[!] Make sure that each device is properly connected.${END}"
    sleep 1.5

    # Array of device names to look for
    #Add eGalaxTouch
    local devices_to_check=("Sierra Wireless" "U-Blox" "Fingerprint" "Webcam" "Bluetooth" "Smart Card Reader" "Touch Panel")
    local touch_devices=("Touch Panel" "eGalaxTouch")
    local usb_devices=$(lsusb)
    local touch_detected=false


    printf "%-25s | %s\n" "Device" "Status"
    printf "%-25s | %s\n" "-------------------------" "------------"

    for device_name in "${devices_to_check[@]}"; do
        if echo "$usb_devices" | grep -qi "$device_name"; then
            printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "$device_name" "✅ Detected"
        else
            printf "${RED}%-25s${END} | ${RED}%s${END}\n" "$device_name" "❌  Not Detected"
        fi
    done

    #-------------
    #Touch panels
    #-------------
    for touch in "${touch_devices[@]}"; do
        if echo "$usb_devices" | grep -qi "$touch"; then
            touch_detected=true
            break
       fi
    done
    
    # Touch Screen Input
    if $touch_detected; then
        printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "Touch Screen" "✅ Detected"
    else
        printf "${RED}%-25s${END} | ${RED}%s${END}\n" "Touch Screen" "❌ Not Detected"
    fi

    echo -e "${GREEN}[!] Scan completed.${END}"
}

# Installs necessary drivers and packages
install_drivers() {
    echo -e "${GREEN}[+] Starting driver installation...${END}"
    sudo apt update
    sudo apt upgrade -y

    local devices_to_check=("Sierra Wireless" "U-Blox" "Fingerprint" "Webcam" "Bluetooth" "Smart Card Reader" "Touch Panel" "eGalaxTouch")
    local usb_devices=$(lsusb)

    printf "%-25s | %s\n" "Component" "Status"
    printf "%-25s | %s\n" "-------------------------" "------------"

    for device_name in "${devices_to_check[@]}"; do
        if echo "$usb_devices" | grep -qi "$device_name"; then
            printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "$device_name" "Detected"
            case "$device_name" in
                "Sierra Wireless")
                    echo "  -> Sierra Wireless detected. Skipping automatic installation."
                    sleep 1
                    ;;
                "U-Blox")
                    echo "  -> Installing GPS packages..."
                    sudo apt install -y gpsd gpsd-clients
                    sleep 1
                    ;;
                "Fingerprint")
                    echo "  -> Fingerprint reader detected. Installing packages..."
                    sudo apt install -y fprintd libpam-fprintd
                    sleep 1
                    ;;
                "Webcam")
                    echo "  -> Installing camera software..."
                    sudo apt install -y cheese
                    sleep 1
                    ;;
                "Bluetooth")
                    echo "  -> Bluetooth detected. Skipping automatic installation."
                    sleep 1
                    ;;
                "Smart Card Reader")
                    echo "  -> Installing smart card reader packages..."
                    sudo apt install -y pcsc-tools pcscd opensc
                    sleep 1
                    ;;
                "Touch Panel")
                    echo "  -> Installing Touch Panel calibrator..."
                    sudo apt install -y xinput-calibrator
                    sleep 1
                    ;;
                "eGalaxTouch")
                    echo "  -> Installing Touch Panel calibrator..."
                    sudo apt install -y xinput-calibrator
                    sleep 1
                    ;;
            esac
        else
            printf "${RED}%-25s${END} | ${RED}%s${END}\n" "$device_name" "Not Detected"
        fi
    done

    echo -e "${GREEN}[+] Analysis and installation complete.${END}"
    echo -e "${YELLOW}[!] Test all devices manually before running the OEM system preparation.${END}"
}

# Prepares the system for OEM distribution
prepare_environment() {
    echo -e "\n${YELLOW}⚠️ WARNING: This action will prepare the system for OEM distribution.${END}"
    echo -e "It will delete the current user and perform a factory reset."
    read -rp "[y|Y] Continue | [n|N] Cancel: " choice

    case "$choice" in
        [yY])
            echo -e "${BLUE}[*] Installing OEM dependencies...${END}"
            if ! sudo apt install -y oem-config-gtk oem-config-slideshow-ubuntu; then
                echo -e "${RED}[-] Failed to install dependencies.${END}"
                exit 1
            fi

            echo -e "${GREEN}[+] Dependencies installed successfully.${END}"
            echo -e "${PURPLE}[*] Initializing system preparation...${END}"
            sleep 2

            if ! sudo oem-config-prepare; then
                echo -e "${RED}[-] OEM system initialization failed.${END}"
                exit 1
            fi

            echo -e "👍 ${GREEN}System preparation is ready.${END}"
            echo -e "✨✨  ${YELLOW}Shutting down system in 5 seconds...${END}✨✨"
            for i in {5..1}; do
                echo "$i seconds..."
                sleep 1
            done

            sudo shutdown -h now
            ;;
        [nN])
            echo -e "${BLUE}[*] Action canceled.${END}"
            ;;
        *)
            echo -e "${RED}🚫 Invalid option. Returning to the main menu.${END}"
            ;;
    esac
}

# ==================== Main Menu ====================
main_menu() {
    while true; do
        echo -e "\n${BLUE}--- Main Menu ---${END}"
        echo -e "[1] 🔎 Device Detection"
        echo -e "[2] ⚙️  Device & Driver Configuration"
        echo -e "[3] 💻 OEM Environment Setup ✨(SYSPREP)✨"
        echo -e "[q|Q] ↩️  Exit"
        read -rp "Select an option: " choice

        case "$choice" in
            1)
                device_detection
                ;;
            2)
                install_drivers
                ;;
            3)
                prepare_environment
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

# ==================== Execution Logic ====================
trap ctrl_c INT
check_root
show_banner
check_neofetch
main_menu
