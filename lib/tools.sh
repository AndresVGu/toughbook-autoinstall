#!/usr/bin/env bash
# Auxiliary tools: keyboard test, documentation, sound autostart, touch calibration

keyboard_test() {
    local USER_DIR="$SUDO_USER"
    local DOWNLOADS_DIR="/home/$USER_DIR/Downloads"
    local REPO_FOLDER="linux-keytest"
    local FULL_REPO_PATH="$DOWNLOADS_DIR/$REPO_FOLDER"
    local REPO_URL="https://github.com/AndresVGu/linux-keytest"

    echo "🔎 Verifying linux-keytest repository..."

    if [ -d "$FULL_REPO_PATH/.git" ]; then
        echo "[+] Repository found. Checking for updates..."
        cd "$FULL_REPO_PATH" || return 1

        git fetch origin --quiet 2>/dev/null
        LOCAL_HASH=$(git rev-parse HEAD 2>/dev/null)
        REMOTE_HASH=$(git rev-parse @{u} 2>/dev/null)

        if [[ "$LOCAL_HASH" != "$REMOTE_HASH" ]]; then
            echo "⬆️  Update available. Pulling latest changes..."
            git pull --quiet 2>/dev/null
            echo "✅ Repository updated."
        else
            echo "✅ Repository is up to date."
        fi

        cd - >/dev/null
    else
        echo "[!] Repository not found. Cloning..."
        rm -rf "$FULL_REPO_PATH" 2>/dev/null
        git clone "$REPO_URL" "$FULL_REPO_PATH"
        if [ $? -ne 0 ]; then
            echo "❌ Error cloning. Verify internet connection."
            return 1
        fi
        echo "🎉 Repository cloned successfully."
    fi

    # Install dependencies
    local DEPS=(python3 python3-tk dbus-x11)
    local MISSING=()

    for pkg in "${DEPS[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            MISSING+=("$pkg")
        fi
    done

    if [ ${#MISSING[@]} -gt 0 ]; then
        echo "[+] Installing missing dependencies: ${MISSING[*]}"
        sudo apt install -y "${MISSING[@]}"
        if [ $? -ne 0 ]; then
            echo -e "${RED}[!] Failed to install dependencies. Cannot run keytest.${END}"
            return 1
        fi
        echo -e "${GREEN}[+] Dependencies installed.${END}"
    fi

    local KEYBOARD_PATH="$FULL_REPO_PATH/keytest.py"
    if [ ! -f "$KEYBOARD_PATH" ]; then
        echo "ERROR: keytest.py not found in $FULL_REPO_PATH"
        return 1
    fi

    echo -e "Initializing Keytest..."
    gnome-terminal -- bash -c "cd '$FULL_REPO_PATH' && python3 keytest.py"
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
