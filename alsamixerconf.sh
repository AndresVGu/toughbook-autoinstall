#!/bin/bash
#
# OEM ALSA Headphone Volume Init Script
# Panasonic Toughbook / Ubuntu 20.04
#

SERVICE_NAME="oem-audio-init.service"
SCRIPT_PATH="/usr/local/bin/alsamixer/alsamixerconf.sh"
STATE_FILE="/var/lib/alsa/asound.state"

# ---------- CONFIGURACIÓN ----------
HEADPHONE_VOL="100%"
MASTER_VOL="100%"
SLEEP_TIME=2
# -----------------------------------

log() {
    logger "[OEM-AUDIO] $1"
}

# Esperar a que ALSA esté disponible
sleep "$SLEEP_TIME"

# Detectar tarjeta automáticamente
CARD=$(aplay -l | awk -F: '/card [0-9]+/ {print $1}' | awk '{print $2}' | head -n1)
[ -z "$CARD" ] && CARD=0

log "Using ALSA card $CARD"

# Aplicar volumen Headphone
amixer -c "$CARD" sset 'Headphone' "$HEADPHONE_VOL" unmute >/dev/null 2>&1

# Asegurar Master (opcional pero recomendado)
amixer -c "$CARD" sset 'Master' "$MASTER_VOL" unmute >/dev/null 2>&1

# Guardar estado ALSA (clave para persistencia tras reset)
alsactl store >/dev/null 2>&1

log "Headphone volume applied and ALSA state stored"

# ---------- AUTO-INSTALACIÓN DEL SERVICIO ----------
if [ ! -f "/etc/systemd/system/$SERVICE_NAME" ]; then
    log "Installing systemd service"

    cat <<EOF > /etc/systemd/system/$SERVICE_NAME
[Unit]
Description=OEM ALSA Headphone Volume Init
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
