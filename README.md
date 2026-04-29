<h1 align="center">
  🛠️ Toughbook AutoInstall
</h1>

<p align="center">
  <b>Ubuntu LTS Configuration & OEM Preparation Toolkit for Panasonic Toughbooks</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Ubuntu%2020.04%20|%2022.04-E95420?logo=ubuntu&logoColor=white" alt="Ubuntu">
  <img src="https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnubash&logoColor=white" alt="Bash">
  <img src="https://img.shields.io/badge/Hardware-Panasonic%20Toughbook-003DA5" alt="Panasonic">
  <img src="https://img.shields.io/badge/License-MIT-blue" alt="License">
</p>

---

## 📑 Table of Contents

- [Overview](#overview)
- [Supported Models](#supported-models)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Installation Guide](#installation-guide)
  - [Boot from USB](#1-boot-from-the-usb-drive)
  - [Language & Keyboard](#2-choose-the-language-and-keyboard-layout)
  - [Network Connection](#3-connect-to-a-network)
  - [Installation Type](#4-select-the-installation-type)
  - [User Account](#5-create-a-user-account)
  - [Begin Installation](#6-begin-the-installation)
- [Prepare Hard Drive for Cloning](#prepare-hard-drive-source-for-cloning)
- [Auto-Install Script](#auto-install-script)
- [Ubuntu Configuration](#ubuntu-configuration)
  - [Check Connected Devices](#how-to-check-your-connected-devices)
  - [Bluetooth & Wi-Fi](#how-to-test-bluetooth-and-wi-fi)
  - [4G Modem Setup](#how-to-set-up-and-test-the-4g-modem)
    - [4G on Ubuntu 20.04](#setting-up-4g-mobile-internet-on-ubuntu-2004)
  - [GPS Testing](#how-to-test-gps)
  - [Webcam](#webcam-configuration)
  - [Touch Screen Calibration](#how-to-calibrate-the-touch-screen)
    - [Permanent Calibration](#make-the-calibration-permanent)
    - [Alternative Calibration](#in-case-xinput_calibrator-doesnt-work)
  - [Fingerprint Sensor](#how-to-set-up-the-fingerprint-sensor)
  - [Smart Card Reader](#how-to-set-up-the-smart-card-reader)
  - [Fan & Temperature](#configure-computer-fan-and-temperature)
- [OEM Preparation (Sysprep)](#delete-test-profile-and-prepare-unit)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Author](#author)

---

## Overview

This toolkit automates the process of installing, configuring, and preparing **Panasonic Toughbook** laptops running **Ubuntu LTS** for OEM distribution. It handles:

- 🔍 **Hardware detection** — Scans and identifies connected devices (4G modem, GPS, fingerprint, touch screen, etc.)
- ⚙️ **Driver installation** — Installs the required drivers and packages based on detected hardware
- 🧪 **Device testing** — Provides tools to verify each component works correctly
- 🔊 **Audio configuration** — Configures ALSA audio with persistent settings
- ✨ **OEM preparation (Sysprep)** — Resets the system for end-user delivery

---

## Supported Models

> **Important:** Choosing the correct Ubuntu version for your model is critical for optimal hardware compatibility.

| Model | Ubuntu Version | Notes |
|:------|:---------------|:------|
| CF-31 MK5 | **22.04** LTS (Jammy Jellyfish) | |
| CF-53 MK4 | **22.04** LTS (Jammy Jellyfish) | |
| CF-54 MK2 | **22.04** LTS (Jammy Jellyfish) | |
| CF-C2 MK2 | **22.04** LTS (Jammy Jellyfish) | |
| FZ-G1 MK1 | **20.04** LTS (Focal Fossa) | Requires Option 5 during Autoinstall via FOG Project |
| FZ-G1 MK4 | **20.04** LTS (Focal Fossa) | |
| CF-33 MK1 & MK2 | ❌ Not Compatible | |
| FZ-M1 | ❌ Not Compatible | |
| Dell Units | ⚠️ Partial | No 4G support |

> [!WARNING]
> **FZ-G1 MK1 with FOG Project:** If Option 5 is not used during Autoinstall, you must manually extend the partition:
>
> ```bash
> sudo apt install -y cloud-guest-utils
> sudo growpart /dev/sda 5
> sudo resize2fs /dev/sda5
> ```
>
> Failing to do this may result in the system not using the full disk capacity.

[⬆️ Back to top](#-table-of-contents)

---

## Prerequisites

Before running the script, ensure you have:

- A **Panasonic Toughbook** from the [supported models list](#supported-models)
- A **USB drive** with the corresponding Ubuntu LTS ISO
- **Internet connection** (Wi-Fi or Ethernet)
- **Root access** (the script must be run as root)

---

## Quick Start

```bash
cd ~/Downloads
sudo apt install git -y
git clone https://github.com/AndresVGu/toughbook-autoinstall
cd toughbook-autoinstall
chmod +x autoinstall.sh
sudo ./autoinstall.sh
```

The script will automatically detect your Toughbook model and display the appropriate menu.

[⬆️ Back to top](#-table-of-contents)

---

## Installation Guide

### 1. Boot from the USB Drive

> [!NOTE]
> For **Ubuntu 22.04 or earlier**, select **"Install OEM (for manufacturers only)"** instead of "Install Ubuntu." This enables the Sysprep (System Preparation) process.

### 2. Choose the Language and Keyboard Layout

### 3. Connect to a Network

Connect to the internet during installation to allow the installer to download updates and third-party drivers.

### 4. Select the Installation Type

Enable third-party drivers when prompted.

### 5. Create a User Account

> [!IMPORTANT]
> Use these exact credentials. The Sysprep (factory reset) process requires a user named **"oem"** to function correctly.

| Field | Value |
|:------|:------|
| Name | `oem` |
| User | `oem` |
| Password | `1234` |

### 6. Begin the Installation

Complete the installation wizard and restart when prompted.

[⬆️ Back to top](#-table-of-contents)

---

## Prepare Hard Drive (Source) for Cloning

When cloning a Linux system, hardware-specific identifiers (UUIDs, initramfs, system IDs) are copied to all target machines. Without proper preparation, cloned systems may experience **intermittent boot failures** or enter **emergency mode**.

### Solution: Replace UUIDs with Partition Labels

**1. Assign labels to partitions:**

```bash
lsblk
sudo e2label /dev/sda2 ROOT
sudo e2label /dev/sda1 BOOT
```

**2. Update `/etc/fstab`:**

```bash
sudo nano /etc/fstab
```

Replace UUID-based entries:

```diff
- UUID=xxxx  /      ext4  defaults  0 1
- UUID=yyyy  /boot  ext4  defaults  0 2
+ LABEL=ROOT  /      ext4  defaults  0 1
+ LABEL=BOOT  /boot  ext4  defaults  0 2
```

**3. Regenerate boot configuration:**

```bash
sudo update-initramfs -u
sudo update-grub
```

[⬆️ Back to top](#-table-of-contents)

---

## Auto-Install Script

The `autoinstall.sh` script automates device scanning, driver installation, and OEM preparation. It detects your Toughbook model automatically and presents a model-specific menu.

### Menu Options

| Option | Description |
|:------:|:------------|
| 1 | 🔎 Device Information — Displays system specs (CPU, RAM, storage, battery) |
| 2 | 🩺 Hardware Detection — Scans for connected peripherals |
| 3 | ⚙️ Update Device — Installs updates and drivers for detected hardware |
| 4 | ⌨️ Test Keyboard — Launches a keyboard testing utility |
| 5 | 🔊 Sound Activation — Configures ALSA audio *(model-specific)* |
| Q | ↩️ Exit |

> [!NOTE]
> While the script streamlines these tasks, it is still recommended to **manually test each device** to verify proper functionality.

### Clone and Run

```bash
cd ~/Downloads
sudo apt install git -y
git clone https://github.com/AndresVGu/toughbook-autoinstall
cd toughbook-autoinstall
chmod +x autoinstall.sh
sudo ./autoinstall.sh
```

[⬆️ Back to top](#-table-of-contents)

---

## Ubuntu Configuration

After installation, connect to Wi-Fi and run:

```bash
sudo su            # Password: 1234
sudo apt update -y && sudo apt upgrade -y
sudo apt install git -y
```

Then verify drivers: press `Super` → open **Software & Updates** → **Additional Drivers** tab → confirm it says **"No additional drivers available."**

![Additional Drivers](/assets/drivers.png)

---

### How to Check Your Connected Devices

Run `lsusb` to verify that the system detects all connected peripherals:

```bash
lsusb
```

If a device is missing from the list, it may not be working, compatible, or properly connected.

![lsusb output](/assets/1.png)

[⬆️ Back to top](#-table-of-contents)

---

### How to Test Bluetooth and Wi-Fi

No terminal required. Use the system UI:

- **Wi-Fi:** Settings → Network
- **Bluetooth:** Settings → Bluetooth

[⬆️ Back to top](#-table-of-contents)

---

### How to Set Up and Test the 4G Modem

The **Sierra Wireless EM7455** modem is typically detected automatically on Ubuntu 24.04. You only need to configure the APN.

**1. Insert the SIM card** — The "Mobile Network" option appears only after a SIM is detected.

**2. Configure the APN:** Settings → Mobile Network → Access Point Names → Add New APN

| Field | Value |
|:------|:------|
| Name | `internet` |
| APN | `sp.telus.com` |

> Use the APN provided by your data carrier.

![Mobile Network Configuration](/assets/mobile_network.png)

**3. Save and set as default APN.**

**4. Test the connection:**

```bash
ping 8.8.8.8
```

[⬆️ Back to top](#-table-of-contents)

---

### Setting Up 4G Mobile Internet on Ubuntu 20.04

For Ubuntu 20.04, manual configuration via `nmcli` is required.

**Common APNs:**

| Provider | APN |
|:---------|:----|
| Verizon (USA) | `vzwinternet` |
| Telus (Canada) | `sp.telus.com` |
| T-Mobile (USA) | `fast.t-mobile.com` |

#### Step 1 — Find Your 4G Device Name

```bash
nmcli device
```

Look for a device with TYPE `gsm` or `wwan`:

| DEVICE | TYPE | STATE | CONNECTION |
|:------:|:----:|:-----:|:----------:|
| **cdc-wdm0** | **gsm** | **disconnected** | **--** |
| eth0 | ethernet | connected | Wired Connection 1 |
| wlp2s0 | wifi | unavailable | -- |

#### Step 2 — Confirm the SIM Card is Detected

```bash
mmcli -L
```

You should see something like `/org/freedesktop/ModemManager1/Modem/0`.

#### Step 3 — Remove Old Connections

```bash
nmcli connection show
nmcli connection delete "connection name"
```

#### Step 4 — Create the 4G Connection

```bash
nmcli connection add type gsm ifname "<device_name>" con-name "<connection_name>" apn "<provider_apn>"
```

**Example:**

```bash
nmcli connection add type gsm ifname cdc-wdm0 con-name "My Verizon Internet" apn vzwinternet
```

#### Step 5 — Activate the Connection

**Option A:** Settings → Mobile Network → Toggle ON

**Option B:** Terminal

```bash
nmcli connection up "My Verizon Internet"
```

[⬆️ Back to top](#-table-of-contents)

---

### How to Test GPS

**1. Install GPS tools:**

```bash
sudo apt install gpsd gpsd-clients -y
```

**2. Verify the GPS device:**

```bash
lsusb | grep "U-Blox"
```

Expected output: **U-Blox AG [u-blox 8]**

**3. Run the GPS test:**

```bash
cgps    # Text-based GPS data
xgps    # Graphical GPS viewer
```

> It may take a few minutes to acquire a satellite fix.

![GPS UI Example](/assets/gps_ui.png)

If no data appears, check the `gpsd` service:

```bash
sudo systemctl status gpsd
```

[⬆️ Back to top](#-table-of-contents)

---

### Webcam Configuration

Install a camera test application:

```bash
sudo apt install cheese -y
sudo apt install kamoso -y
```

> [!NOTE]
> On **Dell devices**, Cheese may present errors. Use **Kamoso** instead:
> ```bash
> sudo apt remove cheese
> ```

[⬆️ Back to top](#-table-of-contents)

---

### How to Calibrate the Touch Screen

**1. Install the calibrator:**

```bash
sudo apt install xinput-calibrator
```

**2. Run the calibration:**

```bash
xinput_calibrator
```

![Touch Screen Calibrator](/assets/touch_calibrator.png)

---

#### Make the Calibration Permanent

After calibration, the terminal outputs a configuration snippet. Save it:

```bash
sudo nano /etc/X11/xorg.conf.d/99-calibration.conf
# Paste the snippet
# Ctrl+S → Save | Ctrl+X → Exit
reboot now
```

---

#### In Case xinput_calibrator Doesn't Work

1. Log out and select **GNOME on Xorg** from the login screen.
2. Open terminal as root.
3. Create a script in `/usr/local/bin/`:

```bash
#!/bin/sh
# Coordinate Transformation Matrix values may vary per unit
xinput set-prop "Fujitsu Component USB Touch Panel" --type=float \
  "Coordinate Transformation Matrix" 1.115 0 -0.0709 0 1.14 -0.108 0 0 1
```

4. Grant execution permissions and add to autostart.

**CF-31 MK5 calibration values:**

| Parameter | Value |
|:----------|:------|
| SCALE_X | `1.10` |
| SCALE_Y | `1.10` |
| OFFSET_X | `-0.042` |
| OFFSET_Y | `-0.07` |

Then run `git pull` on the repository, press option **[6]**, and remove the old startup script.

[⬆️ Back to top](#-table-of-contents)

---

### How to Set Up the Fingerprint Sensor

**1. Install fprintd:**

```bash
sudo apt install fprintd -y
```

**2. Enroll and verify:**

```bash
fprintd-enroll     # Register a fingerprint
fprintd-verify     # Test the enrolled fingerprint
```

[⬆️ Back to top](#-table-of-contents)

---

### How to Set Up the Smart Card Reader

**1. Install the tools:**

```bash
sudo apt install pcscd pcsc-tools -y
```

**2. Check if the reader is detected:**

```bash
pcsc_scan
```

Look for `Reader 0: <reader_name>...` in the output.

**3. Test with a card inserted:**

```bash
pcsc_scan
```

[⬆️ Back to top](#-table-of-contents)

---

### Configure Computer Fan and Temperature

> [!NOTE]
> Only necessary if a fan issue is noticed or specifically required.

**1. Install and detect sensors:**

```bash
sudo apt install lm-sensors -y
sudo sensors-detect    # Press Enter at each prompt
sensors                # View temperatures
```

**2. Monitor fan speed:**

```bash
sudo apt install fancontrol -y
sudo pwmconfig         # Follow on-screen instructions
```

[⬆️ Back to top](#-table-of-contents)

---

## Delete Test Profile and Prepare Unit

> [!NOTE]
> On Ubuntu 22.04, a built-in desktop program handles this automatically.

**1. Update the system:**

```bash
sudo apt update && sudo apt full-upgrade -y
```

**2. Install OEM packages:**

```bash
sudo apt install -y oem-config-gtk oem-config-slideshow-ubuntu
```

**3. Prepare for end user:**

```bash
sudo oem-config-prepare
```

**4. Shut down:**

```bash
sudo shutdown -h now
```

[⬆️ Back to top](#-table-of-contents)

---

## Troubleshooting

| Issue | Solution |
|:------|:---------|
| Script fails with "must be run as root" | Run with `sudo ./autoinstall.sh` |
| No internet connection detected | Connect to Wi-Fi or Ethernet before running |
| 4G modem not showing in `lsusb` | Ensure SIM card is inserted and modem is enabled in BIOS |
| GPS shows no data | Move to an open area; check `sudo systemctl status gpsd` |
| Touch screen calibration resets after reboot | Follow the [permanent calibration](#make-the-calibration-permanent) steps |
| Audio not working after OEM reset | The autostart service should restore it; check with `amixer` |
| Boot enters emergency mode after cloning | Follow the [cloning preparation](#prepare-hard-drive-source-for-cloning) steps |

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m "Add my feature"`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request

---

## Author

**Andres Villarreal** ([@4vs3c](https://github.com/AndresVGu))

---

<p align="center">
  <sub>Built with ❤️ for the refurb & QA team</sub>
</p>
