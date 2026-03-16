#!/bin/bash
#
# OEM ALSA Audio Init Script
# Panasonic Toughbook / Ubuntu 22
#

SERVICE_NAME="oem-audio-init.service"
SCRIPT_PATH="/usr/local/bin/alsamixer/c2audioconf.sh"
STATE_FILE="/var/lib/alsa/asound.state"

# ---------- CONFIGURACIÓN ----------
HEADPHONE_VOL="100%"
MASTER_VOL="100%"
PCM_VOL="100%"
SLEEP_TIME=3
# -----------------------------------

log() {
    logger "[OEM-AUDIO] $1"
}

# Esperar a que ALSA esté disponible
sleep "$SLEEP_TIME"

# Detectar tarjeta Realtek automáticamente
CARD=$(aplay -l | grep -i "PCH" | awk -F: '{print $1}' | awk '{print $2}')

# Fallback si no se detecta
[ -z "$CARD" ] && CARD=0

log "Using ALSA card $CARD (HDA Intel PCH)"

# ---------- CONFIGURACIÓN DE AUDIO ----------

# Master
amixer -c "$CARD" sset Master "$MASTER_VOL" unmute >/dev/null 2>&1

# PCM
amixer -c "$CARD" sset PCM "$PCM_VOL" unmute >/dev/null 2>&1

# Headphones
amixer -c "$CARD" sset Headphone "$HEADPHONE_VOL" unmute >/dev/null 2>&1

# Speaker (por si el modelo lo usa)
amixer -c "$CARD" sset Speaker "$MASTER_VOL" unmute >/dev/null 2>&1

# Auto-Mute desactivado (muy importante en laptops)
amixer -c "$CARD" sset "Auto-Mute Mode" Disabled >/dev/null 2>&1

# ---------- GUARDAR CONFIGURACIÓN ----------

alsactl store >/dev/null 2>&1

log "Audio configuration applied and ALSA state saved"

# ---------- AUTO-INSTALACIÓN DEL SERVICIO ----------

if [ ! -f "/etc/systemd/system/$SERVICE_NAME" ]; then

    log "Installing systemd service"

cat <<EOF > /etc/systemd/system/$SERVICE_NAME
[Unit]
Description=OEM ALSA Audio Init
After=sound.target
Requires=sound.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reexec
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"

    log "Service installed and enabled"

fi

exit 0