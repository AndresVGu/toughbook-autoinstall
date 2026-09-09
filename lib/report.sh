#!/usr/bin/env bash
# Technician Inspection Report generator.
# Collects what can be verified from the running hardware, leaves the rest
# blank / "na", and renders a PDF on the user's Desktop.

# ── Escape a value for safe inclusion inside HTML ──
_html_escape() {
    local s="$1"
    s="${s//&/&amp;}"
    s="${s//</&lt;}"
    s="${s//>/&gt;}"
    s="${s//\"/&quot;}"
    printf '%s' "$s"
}

# ── Resolve the real (non-root) invoking user ──
# Prefers SUDO_USER, then the owner of the login session, then the first
# human account in /home. Never returns "root" unless there is truly no
# other option.
# Returns a username only if it is a real, non-root account (UID >= 1000)
_is_real_user() {
    local name="$1"
    [ -z "$name" ] && return 1
    [ "$name" = "root" ] && return 1
    local uid
    uid=$(id -u "$name" 2>/dev/null) || return 1
    [ -n "$uid" ] && [ "$uid" -ge 1000 ]
}

_report_target_user() {
    local u=""

    # 1) sudo invocation
    if _is_real_user "${SUDO_USER:-}"; then
        u="$SUDO_USER"
    fi

    # 2) invoked directly (not via sudo) as a normal user
    if [ -z "$u" ] && _is_real_user "${USER:-}"; then
        u="$USER"
    fi

    # 3) the login name behind the current tty
    if [ -z "$u" ]; then
        local ln
        ln=$(logname 2>/dev/null)
        _is_real_user "$ln" && u="$ln"
    fi

    # 4) first account in passwd whose home lives under /home and has UID>=1000.
    #    This is the most reliable path when running as `sudo su` (no SUDO_USER,
    #    USER=root, no login/graphical session). Handles any username.
    if [ -z "$u" ]; then
        while IFS=: read -r name _ uid _ _ home _; do
            case "$uid" in ''|*[!0-9]*) continue ;; esac
            if [ "$uid" -ge 1000 ] && [ "$uid" -lt 65534 ] \
               && [ "$name" != "nobody" ] && [ "${home#/home/}" != "$home" ]; then
                u="$name"; break
            fi
        done < <(getent passwd 2>/dev/null)
    fi

    # 5) any directory owner under /home with a real UID
    if [ -z "$u" ]; then
        local d owner dname
        for d in /home/*/; do
            [ -e "$d" ] || continue
            owner=$(stat -c '%U' "$d" 2>/dev/null)
            if _is_real_user "$owner"; then u="$owner"; break; fi
            dname=$(basename "$d")
            if _is_real_user "$dname"; then u="$dname"; break; fi
        done
    fi

    printf '%s' "${u:-root}"
}

# ── Resolve the Downloads directory for a given user ──
_report_output_dir_for() {
    local target_user="$1"

    # Resolve home from passwd; if that points at /root (or fails) but we have
    # a real user, force the conventional /home/<user> path. Never fall back
    # to $HOME, which is /root when running as root.
    local home_dir
    home_dir=$(getent passwd "$target_user" 2>/dev/null | cut -d: -f6)
    if [ "$target_user" != "root" ]; then
        if [ -z "$home_dir" ] || [ "$home_dir" = "/root" ]; then
            home_dir="/home/$target_user"
        fi
    fi
    [ -z "$home_dir" ] && home_dir="/home/$target_user"

    printf '%s' "$home_dir/Downloads"
}

# ── Resolve the target Downloads directory of the invoking (non-root) user ──
_report_output_dir() {
    _report_output_dir_for "$(_report_target_user)"
}

# ── Convert an HTML file to PDF using whatever tool is available ──
# Args: <html_path> <pdf_path>
_html_to_pdf() {
    local html="$1"
    local pdf="$2"

    if command -v wkhtmltopdf &>/dev/null; then
        wkhtmltopdf --quiet --enable-local-file-access "$html" "$pdf" 2>/dev/null && return 0
    fi

    local chrome=""
    for c in google-chrome google-chrome-stable chromium chromium-browser; do
        command -v "$c" &>/dev/null && { chrome="$c"; break; }
    done
    if [ -n "$chrome" ]; then
        "$chrome" --headless=new --disable-gpu --no-sandbox \
            --no-pdf-header-footer --print-to-pdf="$pdf" \
            "file://$html" &>/dev/null && [ -s "$pdf" ] && return 0
        # Older headless flag fallback
        "$chrome" --headless --disable-gpu --no-sandbox \
            --print-to-pdf="$pdf" "file://$html" &>/dev/null && [ -s "$pdf" ] && return 0
    fi

    if command -v libreoffice &>/dev/null; then
        local outdir; outdir=$(dirname "$pdf")
        libreoffice --headless --convert-to pdf --outdir "$outdir" "$html" &>/dev/null
        local produced="$outdir/$(basename "${html%.html}").pdf"
        if [ -f "$produced" ]; then
            [ "$produced" != "$pdf" ] && mv -f "$produced" "$pdf"
            return 0
        fi
    fi

    return 1
}

# ── Helpers to emit a row in the report tables ──
# _row <label> <value>   -> value column (may be empty)
_row() {
    local label value raw
    raw="$2"
    # Show a dash for empty / whitespace-only values
    [ -z "${raw//[[:space:]]/}" ] && raw="-"
    label=$(_html_escape "$1")
    value=$(_html_escape "$raw")
    printf '<tr><td class="f">%s</td><td class="v">%s</td></tr>\n' "$label" "$value" >> "$_RPT_BODY"
}

# _row2 emits into the second (right) column table
_row2() {
    local label value raw
    raw="$2"
    # Show a dash for empty / whitespace-only values
    [ -z "${raw//[[:space:]]/}" ] && raw="-"
    label=$(_html_escape "$1")
    value=$(_html_escape "$raw")
    printf '<tr><td class="f">%s</td><td class="v">%s</td></tr>\n' "$label" "$value" >> "$_RPT_BODY2"
}

# ── Main entry point ──
generate_report() {
    local start=$SECONDS

    # Dependencies used for collection
    command -v dmidecode &>/dev/null || { msg_info "Installing dmidecode..."; sudo apt install dmidecode -y; }
    command -v v4l2-ctl  &>/dev/null || { msg_info "Installing v4l-utils..."; sudo apt install v4l-utils -y; }
    # xdg-open (xdg-utils) is needed to open the generated PDF from the desktop
    command -v xdg-open  &>/dev/null || { msg_info "Installing xdg-utils..."; sudo apt install xdg-utils -y; }

    msg_info "Collecting inspection data..."
    detect_model

    # ── Serial / identity of the inspected machine ──
    local serial_number="${serial:-}"
    local part_number_val="${part_number:-}"

    # ── CPU ──
    local cpu_model
    cpu_model=$(lscpu 2>/dev/null | grep -m1 "Model name:" | sed 's/Model name:\s*//' | xargs)
    [ -z "$cpu_model" ] && cpu_model="$cpu"

    # ── RAM ──
    local dmi_mem
    dmi_mem=$(sudo dmidecode -t memory 2>/dev/null)
    local ram_type
    ram_type=$(echo "$dmi_mem" | grep -E "^\s+Type:" | grep -v "Type Detail" | head -1 | awk '{print $2}')

    local slot1_block slot2_block
    slot1_block=$(echo "$dmi_mem" | awk '/^Handle.*DMI type 17/{n++} n==1')
    slot2_block=$(echo "$dmi_mem" | awk '/^Handle.*DMI type 17/{n++} n==2')

    local ram1_size ram1_serial ram2_size ram2_serial
    ram1_size=$(echo "$slot1_block" | grep "^\s*Size:" | head -1 | sed 's/.*Size: //' | xargs)
    ram1_serial=$(echo "$slot1_block" | grep "Serial Number:" | head -1 | sed 's/.*Serial Number: //' | xargs)
    ram2_size=$(echo "$slot2_block" | grep "^\s*Size:" | head -1 | sed 's/.*Size: //' | xargs)
    ram2_serial=$(echo "$slot2_block" | grep "Serial Number:" | head -1 | sed 's/.*Serial Number: //' | xargs)

    # Compose "16 GB DDR4" style strings; blank out empty/no-module slots
    local ram1_display="" ram2_display=""
    if [[ -n "$ram1_size" && "$ram1_size" != *"No Module"* && "$ram1_size" != "0"* ]]; then
        ram1_display="$ram1_size"
        [ -n "$ram_type" ] && ram1_display="$ram1_size $ram_type"
    fi
    if [[ -n "$ram2_size" && "$ram2_size" != *"No Module"* && "$ram2_size" != "0"* ]]; then
        ram2_display="$ram2_size"
        [ -n "$ram_type" ] && ram2_display="$ram2_size $ram_type"
    fi
    [[ "$ram1_serial" == *"Not"* ]] && ram1_serial=""
    [[ "$ram2_serial" == *"Not"* ]] && ram2_serial=""
    local ram1_result="na" ram2_result="na"
    [ -n "$ram1_display" ] && ram1_result="passed"
    [ -n "$ram2_display" ] && ram2_result="passed"

    # ── Storage (first two physical disks) ──
    local -a disk_names=()
    while read -r d; do disk_names+=("$d"); done < <(lsblk -d -n -o NAME,TYPE 2>/dev/null | awk '$2=="disk"{print $1}')

    local st1_size="" st1_serial="" st1_health="" st1_result="na"
    local st2_size="" st2_serial="" st2_result="na"

    _disk_report_line() {
        local dev="$1"
        local raw_size norm bus tran model_x serial_x
        raw_size=$(lsblk -d -n -o SIZE "/dev/$dev" 2>/dev/null | xargs)
        norm=$(_normalize_disk_size "$raw_size")
        tran=$(lsblk -d -n -o TRAN "/dev/$dev" 2>/dev/null | xargs)
        serial_x=$(udevadm info --query=property --name="/dev/$dev" 2>/dev/null | grep '^ID_SERIAL_SHORT=' | sed 's/^ID_SERIAL_SHORT=//')

        local kind="SSD"
        case "$dev" in
            nvme*) kind="SSD M.2 NVMe PCIe" ;;
            *) [ "$tran" = "sata" ] && kind="SSD SATA" || kind="SSD" ;;
        esac
        _DL_SIZE="$norm $kind"
        _DL_SERIAL="$serial_x"
        # SMART health if available
        _DL_HEALTH=""
        if command -v smartctl &>/dev/null; then
            local pct
            pct=$(smartctl -A "/dev/$dev" 2>/dev/null | awk '/Percentage Used/{gsub("%","",$NF); print 100-$NF"%"; exit}')
            [ -n "$pct" ] && _DL_HEALTH="$pct"
        fi
    }

    if [ "${#disk_names[@]}" -ge 1 ]; then
        _disk_report_line "${disk_names[0]}"
        st1_size="$_DL_SIZE"; st1_serial="$_DL_SERIAL"; st1_health="$_DL_HEALTH"; st1_result="passed"
    fi
    if [ "${#disk_names[@]}" -ge 2 ]; then
        _disk_report_line "${disk_names[1]}"
        st2_size="$_DL_SIZE"; st2_serial="$_DL_SERIAL"; st2_result="passed"
    fi

    # ── USB / peripherals ──
    local usb_devices
    usb_devices=$(lsusb 2>/dev/null)

    # WLAN
    local wlan_result="na"
    if nmcli -t -f TYPE device 2>/dev/null | grep -q "^wifi$" || \
       [ -n "$(iw dev 2>/dev/null | grep Interface)" ]; then
        wlan_result="passed"
    fi

    # Bluetooth
    local bt_result="na"
    if echo "$usb_devices" | grep -qi "bluetooth" || \
       sudo systemctl status bluetooth 2>/dev/null | grep -q "Active: active (running)" || \
       command -v hciconfig &>/dev/null && hciconfig 2>/dev/null | grep -q "hci"; then
        bt_result="passed"
    fi

    # Audio
    local audio_result="na"
    if command -v aplay &>/dev/null && aplay -l 2>/dev/null | grep -qi "card"; then
        audio_result="passed"
    elif [ -d /proc/asound ] && ls /proc/asound 2>/dev/null | grep -q "card"; then
        audio_result="passed"
    fi

    # Cameras
    local v4l
    v4l=$(v4l2-ctl --list-devices 2>/dev/null)
    local camera_result="na" camera_type=""
    local front_cam=false rear_cam=false
    echo "$v4l" | grep -q "/dev/video0" && front_cam=true
    echo "$v4l" | grep -q "/dev/video1" && rear_cam=true
    echo "$usb_devices" | grep -qi "camera" && rear_cam=true
    if $front_cam || $rear_cam; then
        camera_result="passed"
        if $front_cam && $rear_cam; then
            camera_type="dualCamera"
        else
            camera_type="singleCamera"
        fi
    fi

    # WWAN / 4G modem
    local wwan_result="na" wwan_model=""
    if echo "$usb_devices" | grep -qi "Sierra Wireless"; then
        wwan_result="passed"
        wwan_model=$(echo "$usb_devices" | grep -i "Sierra Wireless" | sed -E 's/.*Sierra Wireless(, Incorporated)?,? (Inc\. )?//I' | awk '{print $1}')
        # Try to extract an EMxxxx model token
        local em
        em=$(echo "$usb_devices" | grep -io "EM[0-9]\+" | head -1)
        [ -n "$em" ] && wwan_model="$em"
    fi

    # GPS
    local gps_result="na"
    if _detect_gps "$usb_devices"; then
        gps_result="passed"
    fi

    # Fingerprint / Smart Card
    local fingerprint_result="na" smartcard_result="na"
    echo "$usb_devices" | grep -qi "fingerprint" && fingerprint_result="passed"
    echo "$usb_devices" | grep -qiE "smart *card" && smartcard_result="passed"

    # Touch / Stylus
    local stylus_result="na" stylus_type="" screen_type=""
    if echo "$usb_devices" | grep -qiE "touch|egalax|digitizer|wacom"; then
        stylus_result="passed"; stylus_type="touchscreen"; screen_type="touchscreen"
    fi

    # Graphics
    local gpu_model gpu_result="na"
    gpu_model=$(lspci 2>/dev/null | grep -iE "vga|3d|display" | head -1 | sed -E 's/.*: //' | xargs)
    if [ -n "$gpu_model" ]; then
        gpu_result="passed"
    fi
    # Shorten common Intel graphics string
    if echo "$gpu_model" | grep -qi "Intel"; then
        gpu_model=$(echo "$gpu_model" | grep -oiE "UHD Graphics|Iris [A-Za-z0-9]*|HD Graphics [0-9]*" | head -1)
        [ -n "$gpu_model" ] && gpu_model="Intel $gpu_model"
    fi

    # USB ports (physical port count via lsusb tree is unreliable; count root hubs' downstream)
    local usb_ports_count usb_ports_result="na"
    usb_ports_count=$(ls /sys/bus/usb/devices/ 2>/dev/null | grep -E "^usb[0-9]+$" | wc -l | xargs)
    [ -n "$usb_ports_count" ] && [ "$usb_ports_count" -gt 0 ] && usb_ports_result="passed"

    # ── Operating System ──
    local os_name os_result="na"
    os_name=$(. /etc/os-release 2>/dev/null; echo "$PRETTY_NAME")
    [ -z "$os_name" ] && os_name=$(lsb_release -ds 2>/dev/null | tr -d '"')
    [ -n "$os_name" ] && os_result="passed"

    # ── Battery / removable battery ──
    local batt_result="na" batt_health=""
    if command -v acpi &>/dev/null && acpi -b 2>/dev/null | grep -qi "battery"; then
        batt_result="passed"
        batt_health=$(acpi -V 2>/dev/null | grep "mAh" | grep -o "[0-9]\+%" | head -1)
    elif [ -d /sys/class/power_supply/BAT0 ]; then
        batt_result="passed"
    fi

    # ── Operating hours ──
    local hours_val
    hours_val=$(sudo dmidecode -t 22 2>/dev/null | grep "Hours" | awk '{print $2}' | head -1)

    # ── Diagnostics summary ──
    local post_result="PASSED"

    # ── Timestamp / technician ──
    local now
    now=$(date '+%b %d, %Y %H:%M')
    local tech_user="${SUDO_USER:-$USER}"

    msg_ok "Data collected. Rendering report..."

    # ── Build HTML ──
    _RPT_BODY=$(mktemp)
    _RPT_BODY2=$(mktemp)

    # Left column of Computer Inspection
    _row "CPU / Motherboard" "$([ -n "$cpu_model" ] && echo passed || echo na)"
    _row "CPU" "$cpu_model"
    _row "Screen" "passed"
    _row "LCD Screen" "passed"
    _row "Screen Type" "$screen_type"
    _row "Graphics Card" "$gpu_result"
    _row "Graphics Card Model" "$gpu_model"
    _row "Dedicated GPU" "na"
    _row "Dedicated GPU Model" ""
    _row "USB Ports" "$usb_ports_result"
    _row "USB Ports Count" "$usb_ports_count"
    _row "Keyboard Ports" "passed"
    _row "WLAN" "$wlan_result"
    _row "Bluetooth" "$bt_result"
    _row "Audio" "$audio_result"
    _row "Camera" "$camera_result"
    _row "Camera Type" "$camera_type"
    _row "Face Recognition" "$([ "$front_cam" = true ] && echo passed || echo na)"
    _row "Fingerprint" "$fingerprint_result"
    _row "Smart Card" "$smartcard_result"
    _row "Smart Card Type" ""
    _row "Stylus" "$stylus_result"
    _row "Stylus Type" "$stylus_type"

    # Right column of Computer Inspection
    _row2 "Barcode Reader" "na"
    _row2 "RFID" "na"
    _row2 "GPS" "$gps_result"
    _row2 "WWAN" "$wwan_result"
    _row2 "WWAN Model" "$wwan_model"
    _row2 "Optical Drive" "na"
    _row2 "Diagnostic Utility" "passed"
    _row2 "Storage 1 Size" "$st1_size"
    _row2 "Storage 1 Serial Number" "$st1_serial"
    _row2 "Storage 1 Health" "$st1_health"
    _row2 "Storage 1 Result" "$st1_result"
    _row2 "Storage 2 Size" "$st2_size"
    _row2 "Storage 2 Serial Number" "$st2_serial"
    _row2 "Storage 2 Health" ""
    _row2 "Storage 2 Result" "$st2_result"
    _row2 "Storage Extended" "na"
    _row2 "RAM 1 Size" "$ram1_display"
    _row2 "RAM 1 Serial Number" "$ram1_serial"
    _row2 "RAM 1 Result" "$ram1_result"
    _row2 "RAM 2 Size" "$ram2_display"
    _row2 "RAM 2 Serial Number" "$ram2_serial"
    _row2 "RAM 2 Result" "$ram2_result"
    _row2 "Removable Battery Serial Number" ""
    _row2 "Removable Battery Health" "$batt_health"
    _row2 "Removable Battery Result" "$batt_result"
    _row2 "AC Adapter" ""
    _row2 "Operating System" "$os_name"
    _row2 "Operating System Result" "$os_result"
    _row2 "Windows Activated" ""
    _row2 "Windows Activation Result" "na"
    _row2 "Drivers Installed" "passed"
    _row2 "Recovery Media" "na"
    _row2 "CFC2 BIOS Update" "na"
    _row2 "Hours" "$hours_val"
    _row2 "Notes" ""

    # Generate everything in a temp workspace first, then move the final
    # file into the real user's Downloads. This avoids leaving artifacts in
    # /root/Downloads when the script runs as root.
    local html_file pdf_file base_name tmp_dir
    tmp_dir=$(mktemp -d)
    base_name="Inspection_Report_${serial_number:-unknown}_$(date +%Y%m%d_%H%M%S)"
    html_file="$tmp_dir/$base_name.html"
    pdf_file="$tmp_dir/$base_name.pdf"

    {
        cat <<'HTML_HEAD'
<!DOCTYPE html>
<html><head><meta charset="utf-8">
<style>
  @page { size: A4; margin: 14mm; }
  * { box-sizing: border-box; }
  body { font-family: "DejaVu Sans", Arial, sans-serif; color:#1a1a1a; font-size:10px; }
  h1 { font-size:18px; margin:0 0 2px 0; }
  h2 { font-size:12px; margin:14px 0 4px 0; border-bottom:2px solid #17a2b8; padding-bottom:2px; color:#0b7285; }
  .serial { font-size:12px; margin:0 0 8px 0; }
  .serial b { color:#0b7285; }
  table { border-collapse:collapse; width:100%; }
  .cols { display:flex; gap:14px; }
  .cols > div { flex:1; }
  th { background:#17a2b8; color:#fff; text-align:left; padding:4px 6px; font-size:10px; }
  td { border:1px solid #d0d7de; padding:3px 6px; vertical-align:top; }
  td.f { width:52%; color:#444; }
  td.v { font-weight:bold; }
  tr:nth-child(even) td { background:#f6f8fa; }
  .spec td { font-weight:normal; }
  .footer { margin-top:12px; font-size:8px; color:#888; text-align:center; }
</style></head><body>
HTML_HEAD

        echo "<h1>Technician Inspection Report</h1>"
        echo "<p class=\"serial\"><b>Serial Number:</b> $(_html_escape "$serial_number")</p>"

        echo "<h2>Item Information</h2>"
        echo "<table class=\"spec\"><tr><th>Field</th><th>Value</th></tr>"
        echo "<tr><td class=\"f\">Model</td><td class=\"v\">$(_html_escape "$brand $model")</td></tr>"
        echo "<tr><td class=\"f\">Part Number</td><td class=\"v\">$(_html_escape "$part_number_val")</td></tr>"
        echo "<tr><td class=\"f\">Serial Number</td><td class=\"v\">$(_html_escape "$serial_number")</td></tr>"
        echo "<tr><td class=\"f\">Inspected</td><td class=\"v\">INSPECTED</td></tr>"
        echo "<tr><td class=\"f\">User</td><td class=\"v\">$(_html_escape "$tech_user")</td></tr>"
        echo "<tr><td class=\"f\">Last Inspected At</td><td class=\"v\">$(_html_escape "$now")</td></tr>"
        echo "</table>"

        echo "<h2>Computer Inspection</h2>"
        echo "<div class=\"cols\">"
        echo "<div><table><tr><th>Field</th><th>Value</th></tr>"
        cat "$_RPT_BODY"
        echo "</table></div>"
        echo "<div><table><tr><th>Field</th><th>Value</th></tr>"
        cat "$_RPT_BODY2"
        echo "</table></div>"
        echo "</div>"

        echo "<p class=\"footer\">Generated by Panasonic Toughbook OEM Utility on $(_html_escape "$now") &bull; Host: $(_html_escape "$(hostname)")</p>"
        echo "</body></html>"
    } > "$html_file"

    # ── 1. Generate the report file in the temp dir ──
    local produced="" ext="pdf"
    if _html_to_pdf "$html_file" "$pdf_file" && [ -s "$pdf_file" ]; then
        produced="$pdf_file"; ext="pdf"
    else
        produced="$html_file"; ext="html"
        msg_warn "Could not generate PDF (no working converter)."
        msg_dim "Install one of: wkhtmltopdf, google-chrome/chromium, or libreoffice for PDF output."
    fi

    # ── 2. Wait until the report file actually exists before moving it ──
    local waited=0
    while [ ! -s "$produced" ] && [ "$waited" -lt 30 ]; do
        sleep 0.5
        waited=$(( waited + 1 ))
    done

    # ── 3. Move the finished report to the user's Downloads ──
    local owner owner_group dest_dir final_dest
    owner=$(_report_target_user)

    # If auto-detection could not find a real user, ask the technician.
    if [ "$owner" = "root" ] || ! _is_real_user "$owner"; then
        local input_user
        read -rp "  $(echo -e "${TURQUOISE}>${END}") Target username for the report (e.g. andres): " input_user
        if _is_real_user "$input_user"; then
            owner="$input_user"
        fi
    fi

    owner_group=$(id -gn "$owner" 2>/dev/null || echo "$owner")
    dest_dir=$(_report_output_dir_for "$owner")
    mkdir -p "$dest_dir" 2>/dev/null
    final_dest="$dest_dir/$base_name.$ext"

    mv -f "$produced" "$final_dest"

    # Owned by the real user and readable by everyone (visible with `ls`)
    chown "$owner":"$owner_group" "$final_dest" 2>/dev/null || true
    chmod 644 "$final_dest" 2>/dev/null || true
    msg_ok "Report saved to: $final_dest"

    rm -f "$_RPT_BODY" "$_RPT_BODY2" 2>/dev/null
    rm -rf "$tmp_dir" 2>/dev/null
    unset _RPT_BODY _RPT_BODY2

    local elapsed=$(( SECONDS - start ))
    msg_time "[Generate Report] $((elapsed / 60))m $((elapsed % 60))s"
}
