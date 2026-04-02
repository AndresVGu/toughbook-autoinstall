# Ubuntu Installation & Configuration for ToughBooks

---

## Index

* [Recommended Ubuntu Versions by Model](#recommended-ubuntu-versions-by-model)
* [Installation Guide](#installation-guide)
* [Prepare Hard Drive (Source) for Cloning](#prepare-hard-drive-source-for-cloning)
* [Auto-Install Script](#auto-install-script)
* [Ubuntu Configuration](#ubuntu-configuration)
  * [How to Check Your Connected Devices](#how-to-check-your-connected-devices)
  * [How to Test Bluetooth and Wi-Fi](#how-to-test-bluetooth-and-wi-fi)
  * [How to Set Up and Test the 4G Modem](#how-to-set-up-and-test-the-4g-modem)
    * [Setting Up 4G Mobile Internet on Ubuntu 20.04](#setting-up-4g-mobile-internet-on-ubuntu-2004)
  * [How to Test GPS](#how-to-test-gps)
  * [Webcam Configuration](#webcam-configuration)
  * [How to Calibrate the Touch Screen](#how-to-calibrate-the-touch-screen)
    * [Make the Calibration Permanent](#make-the-calibration-permanent)
    * [In Case xinput_calibrator Doesn't Work](#in-case-xinput_calibrator-doesnt-work)
  * [How to Set Up the Fingerprint Sensor](#how-to-set-up-the-fingerprint-sensor)
  * [How to Set Up the Smart Card Reader](#how-to-set-up-the-smart-card-reader)
  * [Configure Computer Fan and Temperature](#configure-computer-fan-and-temperature)
* [Delete Test Profile and Prepare Unit](#delete-test-profile-and-prepare-unit)

---

## Recommended Ubuntu Versions by Model

When preparing to install an operating system, it is crucial to consider the version based on the specific hardware you intend to use. Different machine models often perform optimally with particular OS releases.

> **Note:** The following table lists the supported unit models and the corresponding **Ubuntu versions** recommended for their **correct and optimal functioning.**

| Model | Ubuntu Version |
|:-----:|:--------------|
| CF-31 MK5 | Ubuntu **22.04** LTS (Jammy Jellyfish) |
| CF-53 MK4 | Ubuntu **22.04** LTS (Jammy Jellyfish) |
| CF-54 MK2 | Ubuntu **22.04** LTS (Jammy Jellyfish) |
| CF-C2 MK2 | Ubuntu **22.04** LTS (Jammy Jellyfish) |
| FZ-G1 MK1 | Ubuntu **20.04** LTS (Focal Fossa) |
| FZ-G1 MK4 | Ubuntu **20.04** LTS (Focal Fossa) |
| CF-33 MK1 & MK2 | No Compatible |
| FZ-M1 | No Compatible |
| Dell Units | No 4G Compatible |

> **Important Note**
>
> If you are installing **Ubuntu 20.04** on a **Panasonic G1 MK1** using **FOG Project**, make sure to select **Option 5** during the **Autoinstall** process.
>
> If Option 5 is not used, you must manually extend the partition by running the following commands after installation:

```bash
sudo apt install -y cloud-guest-utils
sudo growpart /dev/sda 5
sudo resize2fs /dev/sda5
```

Failing to do this may result in the system not using the full disk capacity.

[⬆️ Go to Index](#index)

---

## Installation Guide

### 1. Boot from the USB Drive

> **Note:** If you are installing **Ubuntu 22.04 or an earlier version**, select the option **"Install OEM (for manufacturers only)"** instead of plain "Install Ubuntu." This enables the Sysprep (System Preparation) process.

### 2. Choose the Language and Keyboard Layout

### 3. Connect to a Network

It is recommended to connect to the internet during installation. **This allows the installer to download updates and third-party drivers.**

### 4. Select the Installation Type

Enable third-party drivers.

### 5. Create a User Account with the Following Credentials

It is important to use these credentials because when performing a **factory reset (Sysprep)**, the system needs to identify a user named **"oem"**; otherwise, the reset will fail.

| Field | Value |
|:-----:|:------|
| Name | oem |
| User | oem |
| Password | 1234 |

### 6. Begin the Installation

### 7. Restart

[⬆️ Go to Index](#index)

---

## Prepare Hard Drive (Source) for Cloning

When a Linux system is cloned, the exact disk configuration is copied to all target machines. If the source disk is not properly prepared, the cloned systems may contain hardware-specific or disk-specific identifiers that can cause boot problems.

Linux relies on identifiers such as UUIDs, initramfs configuration, and system IDs generated for the original machine. After cloning, these identifiers may:

* Not match the target hardware
* Appear duplicated across multiple machines
* Be detected at the wrong time during boot

This can lead to intermittent boot failures, such as the system entering emergency mode.

**Solution: Change the Partition Labels**

```bash
# On the source machine, open the terminal
lsblk
# Depending on the output, you may see sda1 (/boot) and sda2 (/)

# Assign labels
sudo e2label /dev/sda2 ROOT
sudo e2label /dev/sda1 BOOT
```

**Edit `/etc/fstab`**

```bash
sudo nano /etc/fstab
```

```bash
# Change:
# UUID=xxxx / ext4 defaults 0 1
# UUID=yyyy /boot ext4 defaults 0 2

# To:
LABEL=ROOT / ext4 defaults 0 1
LABEL=BOOT /boot ext4 defaults 0 2

# Regenerate boot
sudo update-initramfs -u
sudo update-grub
```

[⬆️ Go to Index](#index)

---

## Auto-Install Script

This script automates the process of **scanning detected devices, installing the necessary drivers and packages** for testing, and performing an **OEM reset (Sysprep)**.

> **Note:** While the script streamlines these tasks, it is still highly recommended to manually test each device to verify proper functionality.

### Clone the Repository

1. Make sure you are connected to Wi-Fi.

```bash
cd Downloads
sudo apt install git -y   # (skip if git is already installed)
git clone https://github.com/AndresVGu/toughbook-autoinstall
cd toughbook-autoinstall
chmod +x autoinstall.sh   # grants execution permission to the script
./autoinstall.sh          # executes the script
```

[⬆️ Go to Index](#index)

---

## Ubuntu Configuration

1. Connect to Wi-Fi.
2. Open the Ubuntu terminal (`Super` key → search "terminal") and run the following commands as **root**:  
   Use the password **→ 1234**

```bash
sudo su
sudo apt update -y && sudo apt upgrade -y
sudo apt install git -y
```

3. Check drivers: press `Super`, open **Software & Updates**, go to the **Additional Drivers** tab, and make sure it says **"No additional drivers available."**

![Additional Drivers](/assets/drivers.png)

---

## How to Check Your Connected Devices

This section explains how to verify that the computer detects connected devices such as a Webcam, 4G Modem, GPS, Fingerprint reader, Touch Screen, or Smart Card Reader.

Open the terminal and run:

```bash
lsusb
```

If you do not see the required device in the list, the computer has not detected it. This could mean the device is not working properly, is not compatible, or is not properly connected.

![lsusb output](/assets/1.png)

[⬆️ Go to Index](#index)

---

## How to Test Bluetooth and Wi-Fi

To test Wi-Fi and Bluetooth, you do not need to use the terminal. You can use the system UI:

**Settings → Network** (for Wi-Fi) or **Settings → Bluetooth**

[⬆️ Go to Index](#index)

---

## How to Set Up and Test the 4G Modem

In most cases, the **Sierra Wireless EM7455 Modem** works out of the box on Ubuntu 24.04, as these devices are automatically detected and use built-in drivers. However, you need to configure the Access Point Name (APN) to connect to your mobile data network.

1. **Insert the SIM Card.** The **"Mobile Network"** option will not appear in the UI until a SIM card is detected.
2. **Go to Mobile Network Settings** and configure the APN: navigate to **Access Point Names → Add New APN** and fill in the following fields:

   | Field | Value |
   |:-----:|:------|
   | Name | internet |
   | APN | sp.telus.com |

   > Remember to use the APN provided by your data carrier.

   ![Mobile Network Configuration](/assets/mobile_network.png)

3. Save changes and make sure to set this APN as the default.

4. **Activate Mobile Data and test the connection:**

```bash
ping 8.8.8.8
```

[⬆️ Go to Index](#index)

---

## Setting Up 4G Mobile Internet on Ubuntu 20.04

You must find the correct APN for your SIM card provider (e.g., Verizon, T-Mobile, Telus). You can search online for your provider's APN.

**Some examples:**

| Provider | APN |
|:--------:|:----|
| Verizon (USA) | vzwinternet |
| Telus (Canada) | sp.telus.com |
| T-Mobile (USA) | fast.t-mobile.com |

### Step 1 — Find Your 4G Device Name

Run the following command:

```bash
nmcli device
```

**What to look for:** Find a line where **TYPE** is listed as `gsm`, `wwan`, or anything other than `ethernet`, `wifi`, or `loopback`. The name in the first column (e.g., `cdc-wdm0`, `ttyACM0`) is your device name — write it down.

| DEVICE | TYPE | STATE | CONNECTION |
|:------:|:----:|:-----:|:----------:|
| **cdc-wdm0** | **gsm** | **disconnected** | **--** |
| eth0 | ethernet | connected | Wired Connection 1 |
| wlp2s0 | wifi | unavailable | -- |
| lo | loopback | unmanaged | -- |

*(In the example above, the device name is **cdc-wdm0**.)*

### Step 2 — Confirm the System Sees the SIM Card

This step confirms that your computer recognizes the SIM card and its modem.

```bash
mmcli -L
```

**What to look for:** If you see something like `/org/freedesktop/ModemManager1/Modem/0`, the system has found your 4G device and SIM card.

### Step 3 — Remove Old Connections

Old, unused connection settings can sometimes cause problems. It is best to remove any previous mobile connection to prevent interference.

Look for any connection names you no longer need, especially those with type **gsm** or **cdma**.

```bash
nmcli connection show           # lists all existing connections
nmcli connection delete "connection name"   # replace with the actual name
```

### Step 4 — Create Your New 4G Connection

Now bring all the pieces together: your Device Name (from Step 1), your desired connection name, and your carrier's APN.

```bash
nmcli connection add type gsm ifname "your_device_name" con-name "your_preferred_connection_name" apn "your_provider_apn"
```

**Example using the information from the previous steps:**
- Device Name: `cdc-wdm0`
- Connection Name: `My Verizon Internet`
- APN: `vzwinternet`

```bash
nmcli connection add type gsm ifname cdc-wdm0 con-name "My Verizon Internet" apn vzwinternet
```

### Step 5 — Activate the Connection

You have two ways to activate the new connection:

**Option A: Using the Settings Menu**
- Go to your main **Settings** menu.
- Find the **Mobile Network** or **Wireless** settings.
- Toggle the mobile network switch **ON**.
- Your new connection should appear and connect automatically.

**Option B: Using the Terminal**

```bash
nmcli connection up "your_preferred_connection_name"
# Example:
nmcli connection up "My Verizon Internet"
```

[⬆️ Go to Index](#index)

---

## How to Test GPS

To test the GPS module, you will use a service called `gpsd` and its related tools. This service manages data from the GPS receiver and makes it available to other applications.

1. **Install `gpsd` and its tools:**

```bash
sudo apt install gpsd gpsd-clients -y
```

2. **Verify the GPS connection:**

```bash
lsusb | grep "U-Blox"
```

You should see the device listed as **U-Blox AG [u-blox 8]**.

3. **Run the GPS test:**

```bash
cgps   # displays GPS data in the console (text-based)
xgps   # visual tool that shows the same information
```

It may take a few minutes to get a "fix" on the satellites.

![GPS UI Example](/assets/gps_ui.png)

> **Note:** If the applications do not show any data, you may be in a location where the GPS cannot detect satellites, or there may be an issue with the `gpsd` service. You can check its status with:

```bash
sudo systemctl status gpsd
```

[⬆️ Go to Index](#index)

---

## Webcam Configuration

The camera is usually detected and ready automatically. All you need to do is install a test application:

```bash
sudo apt install cheese -y
sudo apt install kamoso -y
```

> **Note:** On some units, such as **Dell devices**, the **Cheese** application may present errors or bugs. In that case, use **Kamoso** instead and remove Cheese:

```bash
sudo apt remove cheese
```

[⬆️ Go to Index](#index)

---

## How to Calibrate the Touch Screen

You can calibrate the touchscreen using a command-line tool called `xinput_calibrator`. This tool works when you are using the X Window System, which is the default display server on Ubuntu.

1. **Install `xinput_calibrator`:**

```bash
sudo apt install xinput-calibrator
```

2. **Run the calibrator.**  
   This will launch a simple graphical interface:

```bash
xinput_calibrator
```

![Touch Screen Calibrator](/assets/touch_calibrator.png)

---

## Make the Calibration Permanent

After tapping all four points in the UI, the terminal will display the calibration data as a **"snippet"**. This snippet contains the values needed to make the calibration persist across reboots.

1. Run the calibrator.
2. Copy the entire output from the terminal (`Ctrl + Shift + C`) and paste it into the configuration file, replacing the device name with your specific touch device:

```bash
sudo nano /etc/X11/xorg.conf.d/99-calibration.conf
# Paste the snippet into this file
# Ctrl + S  → Save
# Ctrl + X  → Exit
reboot now
```

---

## In Case xinput_calibrator Doesn't Work

1. Log out and select the **Gnome on Xorg** session from the login screen.
2. Open the terminal and authenticate as root.
3. Navigate to **/usr/local/bin**.
4. Create a bash script with the following content. (The values of the Coordinate Transformation Matrix may vary depending on the unit.)

```bash
#!/bin/sh

# Coordinate touch panel to screen
# Format: touch_area_width, 0, touch_x_offset, 0, touch_area_height, touch_y_offset, 0, 0, 1
xinput set-prop "Fujitsu Component USB Touch Panel" --type=float "Coordinate Transformation Matrix" 1.115 0 -0.0709 0 1.14 -0.108 0 0 1
```

5. Save the file and grant execution permissions.
6. Set up this script in the autostart panel.

### Calibration Values for CF-31 MK5 (Temporary)

Modify the script in `/usr/local/bin` and replace the following values:

```
SCALE_X  = 1.10
SCALE_Y  = 1.10
OFFSET_X = -0.042
OFFSET_Y = -0.07
```

Then run `git pull` on the toughbook repository, press option **[6]**, and delete the old startup script afterward.

[⬆️ Go to Index](#index)

---

## How to Set Up the Fingerprint Sensor

To test your fingerprint sensor, you will use a command-line tool called `fprintd`.

1. **Install `fprintd`:**

```bash
sudo apt install fprintd -y
```

2. **Enroll a fingerprint.** If the sensor is detected, use `fprintd` to register a fingerprint:

```bash
fprintd-enroll    # Follow the on-screen instructions; you will see a success message when done
fprintd-verify    # Verify the enrolled fingerprint
```

[⬆️ Go to Index](#index)

---

## How to Set Up the Smart Card Reader

To test the smart card reader, you can use command-line tools from `pcsc-tools` or `opensc`.

1. **Install the required tools:**

```bash
sudo apt install pcscd pcsc-tools -y
```

### Check if the Reader is Detected

```bash
pcsc_scan
```

The command will indicate whether a reader is detected. Look for a line that says `Reader 0: <reader_name>...` — this means the system recognizes the reader.

### Test with a Card

1. Insert the smart card.

```bash
pcsc_scan
```

The command will display information about the card.

[⬆️ Go to Index](#index)

---

## Configure Computer Fan and Temperature

> **Note:** This step is only necessary if a fan issue is noticed on a unit or if it is specifically required.

To diagnose a fan, you can use command-line tools to monitor CPU temperature and fan speed.

### Monitor CPU Temperature

1. **Install `lm-sensors`:**

```bash
sudo apt install lm-sensors -y
```

2. After installing, run the following command to let the system detect all hardware sensors. Press `Enter` at each prompt to accept the default options:

```bash
sudo sensors-detect
sensors
```

The `sensors` command displays the temperature of your CPU, GPU, and other components.

### Monitor Fan Speed

You can use **lm-sensors** along with **fancontrol**.

1. **Install `fancontrol`:**

```bash
sudo apt install fancontrol -y
```

2. **Configure `fancontrol`:**

```bash
sudo pwmconfig
```

Follow the on-screen instructions to test the fans. This will display the current speed in RPM.

[⬆️ Go to Index](#index)

---

## Delete Test Profile and Prepare Unit

> **Note:** If you are using Ubuntu 22.04, this step is not necessary — a built-in program on the desktop handles it automatically.

To prepare the device for distribution as an **Original Equipment Manufacturer (OEM)** unit, run the following commands:

1. **Update and upgrade the system:**

```bash
sudo apt update && sudo apt full-upgrade -y
```

2. **Install OEM packages:**

```bash
sudo apt install -y oem-config-gtk oem-config-slideshow-ubuntu
```

3. **Prepare the system for the end user:**

This is the most critical step. The `oem-config-prepare` command cleans up the system and sets it to a state where the end user can create their own account.

```bash
sudo oem-config-prepare
```

4. **Shut down the device:**

```bash
sudo shutdown -h now
```

[⬆️ Go to Index](#index)



