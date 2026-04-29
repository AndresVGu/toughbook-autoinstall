#!/usr/bin/env bash
# Auxiliary tools: keyboard test, documentation, sound autostart, touch calibration

keyboard_test() {
    command -v python3 &>/dev/null || { echo "[!] Installing python3 ..."; sudo apt install -y python3; }
    command -v pip3    &>/dev/null || { echo "[!] Installing pip3 ...";    sudo apt install -y python3-pip; }

    local USER_DIR="$SUDO_USER"
    local DOWNLOADS_DIR="/home/$USER_DIR/Downloads"
    local REPO_FOLDER="linux-keytest"
    local FULL_REPO_PATH="$DOWNLOADS_DIR/$REPO_FOLDER"
    local REPO_URL="https://github.com/AndresVGu/linux-keytest"

    echo "🔎 Verifying repository in $DOWNLOADS_DIR"

    if [ -d "$FULL_REPO_PATH" ]; then
        echo "⚠️ Repository already on the system ($REPO_FOLDER exists in $DOWNLOADS_DIR)"
    else
        echo "✅ Directory $REPO_FOLDER does not exist. Cloning in $DOWNLOADS_DIR..."
        git clone "$REPO_URL" "$FULL_REPO_PATH"
        if [ $? -ne 0 ]; then
            echo "❌ Error! Verify Internet connection and credentials"
            return 1
        fi
        echo "🎉 Repository cloned successfully to $FULL_REPO_PATH"
    fi

    sudo apt install -y dbus-x11 python3-tk

    local KEYBOARD_PATH="$FULL_REPO_PATH/keytest.py"
    if [ ! -f "$KEYBOARD_PATH" ]; then
        echo "ERROR: Keytest file not found"
        return 1
    fi

    echo -e "Initializing Keytest"
    gnome-terminal -- bash -c "python3 \"$KEYBOARD_PATH\""
}

open_doc() {
    local url="$1"
    local usuario="$SUDO_USER"

    if [ -z "$url" ]; then
        echo "Error: You must provide a URL."
        return 1
    fi

    xhost +si:localuser:"$usuario" > /dev/null
    sudo -u "$usuario" firefox "$url" &
    xhost -si:localuser:"$usuario" > /dev/null
}

# Sound autostart for FZ-G1 / CF-53 / CF-54 models
install_sound_autostart() {
    _install_sound_autostart_generic "alsamixerconf.sh"
}

# Sound autostart for CF-C2 model
install_sound_autostart_c2() {
    _install_sound_autostart_generic "c2audioconf.sh"
}

_install_sound_autostart_generic() {
    local SCRIPT_NAME="$1"
    local INSTALL_PATH="/usr/local/bin/$SCRIPT_NAME"
    local AUTOSTART_FILE="sound-activation.desktop"
    local AUTOSTART_SYSTEM="/etc/xdg/autostart/$AUTOSTART_FILE"

    echo "[+] Adding execution permission to the script..."

    if [[ ! -f "$SCRIPT_NAME" ]]; then
        echo "[ERROR] $SCRIPT_NAME not found"
        return 1
    fi

    chmod 755 "$SCRIPT_NAME"

    echo "[+] Copying script to /usr/local/bin..."
    sudo cp "$SCRIPT_NAME" "$INSTALL_PATH"
    echo "[✓] Script copied successfully"

    echo "[+] Executing default script..."
    "$INSTALL_PATH"

    echo "[+] Creating autostart entry..."
    cat <<EOF > "$AUTOSTART_FILE"
[Desktop Entry]
Type=Application
Name=Sound Activation
Comment=Executes sound activation script
Exec=/bin/bash $INSTALL_PATH
Terminal=false
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF

    sudo cp "$AUTOSTART_FILE" "$AUTOSTART_SYSTEM"
    echo "[✓] Autostart configuration done"
}

# Touch calibration installer helper
install_touch_calibrator() {
    local SCRIPT_FILE="$1"
    local DESKTOP_NAME="$2"
    local DESKTOP_FILE="$3"

    echo "[+] Adding execution permission to the script..."
    chmod +x "$SCRIPT_FILE"
    sleep 1

    echo -e "${BLUE}Executing default calibration...${END}"
    ./"$SCRIPT_FILE"
    sleep 1

    echo -e "${BLUE}Copying default calibration to /usr/local/bin...${END}"
    cp "$SCRIPT_FILE" /usr/local/bin
    sleep 1
    echo -e "${GREEN}[!] Script copied successfully${END}"

    echo -e "${BLUE}Saving Calibration...${END}"
    local TOUCHCAL_PATH="/usr/local/bin/$SCRIPT_FILE"

    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=$DESKTOP_NAME
Comment=Executes Touch Screen Calibration Script
Exec=$TOUCHCAL_PATH
Terminal=true
Type=Application
X-GNOME-Autostart-enabled=true
EOF

    sudo cp "$DESKTOP_FILE" /etc/xdg/autostart/
    echo "[!] AutoStart Configuration Done."
    sleep 2
}
