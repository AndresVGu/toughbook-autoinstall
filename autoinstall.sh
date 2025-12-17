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

#Check Version
check_version() {
	/usr/bin/git pull

	if [ $? -eq 0 ]; then
		echo "[+] Script updated."
	else
		echo "[!] Fail updating the script"
	fi

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

	if command -v neofetch &> /dev/null; then
		echo "[+] Neofetch already Installed."
	else
		echo "[!] Installing Neofetch..."
		sudo apt install neofetch -y
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
	#Procesor
    cpu=$(lscpu | grep "BIOS Model name:" | sed 's/BIOS Model name:\s*//')

	# --- Bloque de Validación y Modificación de la variable 'brand' ---
	case "$model" in
    	# Si la salida es exactamente CF-54-2
    	"CF-54-2")
        	model="CF-54 Mk2"
			cpu=$(lscpu | grep "BIOS Model name:" | sed 's/BIOS Model name:\s*//')
        	;;
    	# Si la salida es g1-1a (la validación es sensible a mayúsculas y minúsculas por defecto)
    	"FZ-G1A"*)
        	model="FZ-G1 MK1"
			part_number=$(sudo dmidecode -s system-product-name | sed -r 's/([A-Z]{2})([0-9]{2})-([0-9])/\1-\2 MK\3/' 2>/dev/null)
			cpu=$(lscpu | grep "Model name:" | sed 's/Model name:\s*//')
        	;;
    	# Caso por defecto (*): si no coincide con ninguno de los anteriores,
    	# no se ejecuta nada, y la variable 'brand' mantiene su valor original.
		"CF-53 MK4")
			cpu=$(lscpu | grep "Model name:" | sed 's/Model name:\s*//')
			;;
    	*)
			cpu=$(lscpu | grep "BIOS Model name:" | sed 's/BIOS Model name:\s*//')
        	# Opcional: puedes añadir un 'echo' para debug aquí si quieres
        	;;
	esac
	# -----------------------------------------------------------------

    #hours
    hours=$(sudo dmidecode -t 22 2>/dev/null | grep "Hours" | awk '{print $2}')
    [ -z "$hours" ] && hours=$(uptime -p)

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
	clean_value_int=$((clean_value))
    bat_message=""
    
    if [ "$clean_value_int" -gt 85 ]; then
        bat_message="✅${GREEN} Recomended for Amazon Orders ${END}"
    elif [ "$clean_value_int" -gt 80 ]; then
        bat_message="✅${GREEN} Recomended for Shopify ${END}"
    elif [ "$clean_value_int" -gt 1 ]; then
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
    echo -e "Battery Health: ${BLUE}${bat_health}${END}  ||   ${bat_message}    "
}

# ==================== Core Functions ====================
#Draw Title
draw_box(){

	# Obtener el OS (Nombre y Versión)
	linux_os=$(neofetch --stdout | grep 'OS:' | awk -F': ' '{print $2}' | awk '{print $1, $2}')
	
	local UNIT_TEXT="$1"
	local TEXT_LEN=${#UNIT_TEXT}
	local OS_LEN=${#linux_os} # Longitud de la línea del OS
	
	local BORDER_CHAR="*"
	# La longitud de la línea del borde y el contenido (TEXT_LEN + 2 espacios + 2 barras laterales)
	local BORDER_LEN=$((TEXT_LEN + 2))

	# 1. Crear la línea de borde
	printf -v BORDER_LINE "%*s" $BORDER_LEN ""
	BORDER_LINE="${BORDER_LINE// /$BORDER_CHAR}"

	# 2. Calcular el padding para centrar linux_os
	
	# La diferencia de longitud entre el texto principal y el OS
	local DIFF=$((TEXT_LEN - OS_LEN))
	
	# Calcular los espacios de relleno a la izquierda. Usamos (DIFF + 1) para dar un espacio de ' margen'
	# y dividimos por 2 para centrar.
	local LEFT_PAD=$(( (DIFF / 2) + 1 ))
	
	# Calcular los espacios de relleno a la derecha. Es el total de espacios (DIFF + 2) - LEFT_PAD.
	local RIGHT_PAD=$(( TEXT_LEN - OS_LEN - LEFT_PAD + 2))
    
    # Manejar el caso donde OS_LEN > TEXT_LEN. Esto podría hacer que el cuadro se vea raro.
    if [ $LEFT_PAD -lt 1 ]; then
        LEFT_PAD=1
        RIGHT_PAD=1
    fi

	# 3. Construir las cadenas de padding
	printf -v LEFT_SPACES "%*s" $LEFT_PAD ""
	printf -v RIGHT_SPACES "%*s" $RIGHT_PAD ""

	# Asume que TURQUOISE y END están definidos como variables de color
	# Se usa '\n' en un solo echo para evitar problemas con la variable de color $END
	echo -e "${TURQUOISE} +${BORDER_LINE}+ ${END}\n${TURQUOISE} | ${UNIT_TEXT} | ${END}\n${TURQUOISE} |${LEFT_SPACES}${linux_os}${RIGHT_SPACES}| ${END}\n${TURQUOISE} +${BORDER_LINE}+ ${END}"

}

# Detects connected USB devices

g1_detection(){
	echo -e "${GREEN}[+] Starting device detection...${END}"

	if command -v v4l-utils &> /dev/null; then
        echo "[+] v4l-utils already Installed."
    else    
        echo "[!] Installing v4l-utils ..."
        sudo apt install v4l-utils -y
    fi
    echo -e "${YELLOW}[!] Make sure that each device is properly connected.${END}"
    sleep 1.5

    # Array of device names to look for
    #Add eGalaxTouch
    local devices_to_check=( "Fingerprint" "Smart Card Reader")
    local touch_devices=("Touch Panel" "eGalaxTouch")
    local usb_devices=$(lsusb)
    local touch_detected=false
    local cameras=(
    	"Webcam:Front Camera" 
    	"Camera:Rear Camera")
    local modemg=$(lsusb | grep "Sierra Wireless" | awk -F 'Inc. ' '{print $2}')
    local network_devices=(
    "Sierra Wireless:Sierra Wireless(${modemg})"
    "U-Blox:GPS Dedicated")

	UNIT_TITLE="You are working on a ${brand} ${model}"
    draw_box "$UNIT_TITLE"


    printf "%-25s | %s\n" "Device" "Status"
    printf "%-25s | %s\n" "-------------------------" "------------"

    for device_name in "${devices_to_check[@]}"; do
        if echo "$usb_devices" | grep -qi "$device_name"; then
            printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "$device_name" "✅ Detected"
        else
            printf "${RED}%-25s${END} | ${RED}%s${END}\n" "$device_name" "❌  Not Detected"
        fi
    done

	#---------
	#--Bluetooth
	#---------
	BLUETOOTH_STATUS=$(sudo systemctl status bluetooth 2>/dev/null)
	BLUE_name="Bluetooth"
	if echo "$BLUETOOTH_STATUS" | grep -q "Active: active (running)"; then
    	printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "$BLUE_name" "✅ Detected"
	else
    	 printf "${RED}%-25s${END} | ${RED}%s${END}\n" "$BLUE_name" "❌  Not Detected"
	fi


    #----------
    #---NETWORK
    #----------
    for item in "${network_devices[@]}";do
        local search_pattern="${item%%:*}"
        local output_alias="${item##*:}"

        if echo "$usb_devices" | grep -qi "$search_pattern"; then
            printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "$output_alias" "✅ Detected"

        else
            printf "${RED}%-25s${END} | ${RED}%s${END}\n" "$output_alias" "❌  Not Detected"
        fi
    done

    #--------
    #Cameras
    #--------

	V4L_OUTPUT=$(v4l2-ctl --list-devices 2>/dev/null)
	# 1. Verificar la Cámara Frontal (asumiendo /dev/video0)
	# Buscamos la línea que contenga "/dev/video0" en la salida.
	FRONT_CAM="Front Camera"
	REAR_CAM="Rear Camera"
	
	if echo "$V4L_OUTPUT" | grep -q "/dev/video0"; then
    	printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "$FRONT_CAM" "✅ Detected"
	else
    	printf "${RED}%-25s${END} | ${RED}%s${END}\n" "$FRONT_CAM" "❌  Not Detected"
	fi

	# 2. Verificar la Cámara Trasera (asumiendo /dev/video1)
	# Buscamos la línea que contenga "/dev/video1" en la salida.
	if echo "$V4L_OUTPUT" | grep -q "/dev/video1"; then
    	printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "$REAR_CAM" "✅ Detected"
	else
    	printf "${RED}%-25s${END} | ${RED}%s${END}\n" "$REAR_CAM" "❌  Not Detected"
	fi
	


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


device_detection() {
    echo -e "${GREEN}[+] Starting device detection...${END}"
    echo -e "${YELLOW}[!] Make sure that each device is properly connected.${END}"
    sleep 1.5

    # Array of device names to look for
    #Add eGalaxTouch
    local devices_to_check=( "Fingerprint"  "Bluetooth" "Smart Card Reader")
    local touch_devices=("Touch Panel" "eGalaxTouch")
    local usb_devices=$(lsusb)
    local touch_detected=false
    local cameras=(
    	"Webcam:Front Camera" 
    	"Camera:Rear Camera")
    local modemg=$(lsusb | grep "Sierra Wireless" | awk -F 'Inc. ' '{print $2}')
    local network_devices=(
    "Sierra Wireless:Sierra Wireless(${modemg})"
    "U-Blox:GPS Dedicated")

	UNIT_TITLE="You are working on a ${brand} ${model}"
    draw_box "$UNIT_TITLE"


    printf "%-25s | %s\n" "Device" "Status"
    printf "%-25s | %s\n" "-------------------------" "------------"

    for device_name in "${devices_to_check[@]}"; do
        if echo "$usb_devices" | grep -qi "$device_name"; then
            printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "$device_name" "✅ Detected"
        else
            printf "${RED}%-25s${END} | ${RED}%s${END}\n" "$device_name" "❌  Not Detected"
        fi
    done

    #----------
    #---NETWORK
    #----------
    for item in "${network_devices[@]}";do
        local search_pattern="${item%%:*}"
        local output_alias="${item##*:}"

        if echo "$usb_devices" | grep -qi "$search_pattern"; then
            printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "$output_alias" "✅ Detected"

        else
            printf "${RED}%-25s${END} | ${RED}%s${END}\n" "$output_alias" "❌  Not Detected"
        fi
    done

	#-------------
	#-OPTICAL DRIVE
	#--------------

	OPTICAL_STATUS=$(dmesg | grep -i 'dvd\|cdrom\|optical')
	OP_ALIAS="Optical Drive(DVD)"

	if [ "$OPTICAL_STATUS" ]; then
    	printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "$OP_ALIAS" "✅ Detected"
	else
    	 printf "${RED}%-25s${END} | ${RED}%s${END}\n" "$OP_ALIAS" "❌  Not Detected"
	fi

    #--------
    #Cameras
    #--------
    for item in "${cameras[@]}";do
    	local search_pattern="${item%%:*}"
    	local output_alias="${item##*:}"

    	if echo "$usb_devices" | grep -qi "$search_pattern"; then
    		printf "${GREEN}%-25s${END} | ${GREEN}%s${END}\n" "$output_alias" "✅ Detected"

    	else 
    		printf "${RED}%-25s${END} | ${RED}%s${END}\n" "$output_alias" "❌  Not Detected"
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
                    sudo apt install -y pcsc-tools pcscd opensc libccid
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

#--------
#keytest
#---------
keyboard_test(){
	echo -e "keyboard test"
	sudo apt install dbus-x11 -y
	echo "[!] Installing Tkinter ..."
    sudo apt install -y python3-tk
	KEYBOARD_PATH="/home/$SUDO_USER/Downloads/linux-keytest/keytest.py"

	if [ ! -f "$KEYBOARD_PATH" ]; then
		echo "ERROR: Keytest undefined"
		exit 1
	fi

	echo -e "Initializing Keytest"

	gnome-terminal -- bash -c "python3 \"$KEYBOARD_PATH\""
}

#--------------
#Documentation
#---------------
open_doc() {
  	local url="$1"
    local usuario="$SUDO_USER"  # <--- ¡REEMPLAZA ESTO!

    if [ -z "$url" ]; then
        echo "Error: Debes proporcionar una URL."
        echo "Uso: ejecutar_firefox_como_usuario https://ejemplo.com"
        return 1
    fi

    echo "Ejecutando Firefox como el usuario '$usuario' en segundo plano..."
    
    # El 'xhost' es crucial: permite que el usuario 'TU_NOMBRE_DE_USUARIO'
    # se conecte al servidor gráfico que está siendo usado por root.
    xhost +si:localuser:"$usuario" > /dev/null
    
    # 'sudo -u' ejecuta el comando como el usuario especificado.
    # El '&' al final lo ejecuta en segundo plano.
    sudo -u "$usuario" firefox "$url" &
    
    # Se remueven los permisos después de la ejecución por seguridad.
    xhost -si:localuser:"$usuario" > /dev/null
}
#-------------------------------------------
# Prepares the system for OEM distribution
#-------------------------------------------

#prepare_environment() {
  #  echo -e "\n${YELLOW}⚠️ WARNING: This action will prepare the system for OEM distribution.${END}"
  #  echo -e "It will delete the current user and perform a factory reset."
  #  read -rp "[y|Y] Continue | [n|N] Cancel: " choice

 #   case "$choice" in
  #      [yY])
    #        echo -e "${BLUE}[*] Installing OEM dependencies...${END}"
    #        if ! sudo apt install -y oem-config-gtk oem-config-slideshow-ubuntu; then
     #           echo -e "${RED}[-] Failed to install dependencies.${END}"
    #            exit 1
    #        fi

     #       echo -e "${GREEN}[+] Dependencies installed successfully.${END}"
    #        echo -e "${PURPLE}[*] Initializing system preparation...${END}"
     #       sleep 2

     #       if ! sudo oem-config-prepare; then
      #          echo -e "${RED}[-] OEM system initialization failed.${END}"
     #           exit 1
      #      fi

      #      echo -e "👍 ${GREEN}System preparation is ready.${END}"
     #       echo -e "✨✨  ${YELLOW}Shutting down system in 5 seconds...${END}✨✨"
     #       for i in {5..1}; do
      #          echo "$i seconds..."
      #          sleep 1
      #      done

        #    sudo shutdown -h now
      #      ;;
      #  [nN])
       #     echo -e "${BLUE}[*] Action canceled.${END}"
      #      ;;
     #   *)
      #      echo -e "${RED}🚫 Invalid option. Returning to the main menu.${END}"
    #        ;;
  #  esac
#}
prepare_environment() {

    echo -e "\n${YELLOW}⚠️  WARNING: OEM SYSTEM PREPARATION (UBUNTU GNOME ONLY)${END}"
    echo -e "${RED}This will REMOVE the current user and reset the system for final customer setup.${END}"
    echo -e "${RED}GNOME on Xorg will be enforced as default session.${END}\n"

    read -rp "[y|Y] Continue | [n|N] Cancel: " choice

    case "$choice" in
        [yY])
            echo -e "${BLUE}[*] Verifying OS...${END}"

            if ! grep -qi "ubuntu" /etc/os-release; then
                echo -e "${RED}[-] This OEM reset is supported ONLY on Ubuntu GNOME.${END}"
                return 1
            fi

            echo -e "${GREEN}[+] Ubuntu detected.${END}"

            echo -e "${BLUE}[*] Ensuring GNOME + GDM environment...${END}"
            apt update

            # GNOME base (safe even if already installed)
            apt install -y ubuntu-desktop gdm3 \
                           oem-config-gtk \
                           oem-config-slideshow-ubuntu

            echo -e "${BLUE}[*] Removing Plasma / SDDM if present...${END}"
            apt purge -y sddm plasma-desktop kde-standard kde-full 2>/dev/null
            apt autoremove -y --purge

            echo -e "${BLUE}[*] Forcing GDM as display manager...${END}"
            echo "gdm3" > /etc/X11/default-display-manager
            systemctl enable gdm3
            systemctl disable sddm 2>/dev/null

            echo -e "${BLUE}[*] Enforcing GNOME on Xorg...${END}"

            mkdir -p /etc/gdm3
            cat <<EOF > /etc/gdm3/custom.conf
[daemon]
WaylandEnable=false
DefaultSession=gnome-xorg.desktop
EOF

            echo -e "${GREEN}[+] GNOME on Xorg configured successfully.${END}"

            echo -e "${PURPLE}[*] Running OEM system preparation...${END}"
            sleep 2

            if ! oem-config-prepare; then
                echo -e "${RED}[-] OEM system initialization failed.${END}"
                exit 1
            fi

            echo -e "\n👍 ${GREEN}OEM preparation completed successfully.${END}"
            echo -e "✨✨ ${YELLOW}System will power off in 5 seconds...${END} ✨✨"

            for i in {5..1}; do
                echo "$i..."
                sleep 1
            done

            shutdown -h now
            ;;
        [nN])
            echo -e "${BLUE}[*] OEM preparation canceled.${END}"
            ;;
        *)
            echo -e "${RED}[!] Invalid option. Returning to menu.${END}"
            ;;
    esac
}

# ==================== Main Menu ====================
main_menu() {
    while true; do
        echo -e "\n${BLUE}--- Main Menu ---${END}"
       # echo -e "[1] 🔎 Configuration & Testing Guide"
		echo -e "[1] 🔎 Device Detection"
        echo -e "[2] ⚙️  Device & Driver Configuration"
        echo -e "[3] ⌨️  Test Keyboard"
        echo -e "[4] 💻 OEM Environment Setup ✨(SYSPREP)✨"
		echo -e "[5]  Default Touch-Screen-AutoCalibration (ONLY FOR CF-53)"
        echo -e "[q|Q] ↩️  Exit"
        read -rp "Select an option: " choice

        case "$choice" in
            #1)
				#URL_DOC="https://github.com/AndresVGu/toughbook-autoinstall/blob/main/README.md"
              #  open_doc "$URL_DOC"
             #   ;;
			1)
                device_detection
                ;;
            2)
                install_drivers
                ;;
            3)
                keyboard_test
                ;;
            4)
                prepare_environment
                ;;
			5)
				echo "[+]Adding execution Permission to the script..."
				chmod +x touch-calibrator.sh
				sleep 1
				echo -e "${BLUE}Executing  Default calibration... ${END}"
				./touch-calibrator.sh
				sleep 1
				echo -e "${BLUE}Copying  Default calibration in [usr/local/bin]... ${END}"
				cp touch-calibrator.sh /usr/local/bin
				sleep 1
				echo -e "${GREEN}[!]Sript copied successfully${END}"
				sleep 0.5
				echo -e "${BLUE}Saving Calibration...${END}"
				
				TOUCHCAL_PATH="/usr/local/bin/touch-calibrator.sh"
				echo "[Desktop Entry]" > touch-calibration.desktop
				echo "Name=AutoCalibrate Fujitsu" >> touch-calibration.desktop
				echo "Comment=Executes Touch Screen Calibration Script" >> touch-calibration.desktop
				echo "Exec=$TOUCHCAL_PATH" >> touch-calibration.desktop
				echo "Terminal=true" >> touch-calibration.desktop
				echo "Type=Application" >> touch-calibration.desktop
				echo "X-GNOME-Autostart-enabled=true" >> touch-calibration.desktop
				
				sudo cp touch-calibration.desktop /etc/xdg/autostart/
				echo "[!] AutoStart Configuration Done.."
				sleep 2
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

# ====================  G1 Main Menu ====================
g1_main_menu() {
	
    while true; do
        echo -e "\n${BLUE}--- Main Menu ---${END}"
		echo -e "[1] 🔎 Device Detection"
        echo -e "[2] ⚙️  Device & Driver Configuration"
		echo -e "⚠️ ${YELLOW}For SYSPREP use Prepare For Shipping To End User located on the Desktop${END} ⚠️"
        echo -e "[q|Q] ↩️  Exit"
        read -rp "Select an option: " choice

        case "$choice" in
			1)
                g1_detection
                ;;
            2)
                install_drivers
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

check_root
show_banner
check_version
check_neofetch

#------------------------
#-------MENU-----------
#----------------------

menu_model=$(sudo dmidecode -s system-product-name | sed -r 's/([A-Z]{2})([0-9]{2})-([0-9])/\1-\2 MK\3/' 2>/dev/null)

# --- Bloque de Validación y Modificación de la variable 'brand' ---
	case "$menu_model" in
    	# Si la salida es exactamente CF-54-2
    	"CF-54-2")
        	menu_model="CF-54 Mk2"
			cpu=$(lscpu | grep "BIOS Model name:" | sed 's/BIOS Model name:\s*//')
			main_menu
        	;;
    	# Si la salida es g1-1a (la validación es sensible a mayúsculas y minúsculas por defecto)
    	"FZ-G1A"*)
        	menu_model="FZ-G1 MK1"
			part_number=$(sudo dmidecode -s system-product-name | sed -r 's/([A-Z]{2})([0-9]{2})-([0-9])/\1-\2 MK\3/' 2>/dev/null)
			cpu=$(lscpu | grep "Model name:" | sed 's/Model name:\s*//')
			g1_main_menu
        	;;
    	# Caso por defecto (*): si no coincide con ninguno de los anteriores,
    	# no se ejecuta nada, y la variable 'brand' mantiene su valor original.
		"CF-53 MK4")
			cpu=$(lscpu | grep "Model name:" | sed 's/Model name:\s*//')
			main_menu
			;;
    	*)
			cpu=$(lscpu | grep "BIOS Model name:" | sed 's/BIOS Model name:\s*//')
			main_menu
        	# Opcional: puedes añadir un 'echo' para debug aquí si quieres
        	;;
	esac
trap ctrl_c INT


