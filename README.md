# Ubuntu 24.0 installation for Panasonic CF-53 mk4 & CF-54 mk2
Boot from the USB drive
Choose the language and keyboard layout
### Connect to a network: It is recommended to connect to the internet during installation. This allows the installer to download updates and third-party drivers
# Select the Installation type: Enable third-party drivers.
Create user account:
Name => oem
User => oem
password = 1234
# Begin the Installation
Restart
## Ubuntu configuration
Connect to Wi-fi
Open the ubuntu terminal ( Super + terminal) and perform the following commands:
sudo su => (then use the password, for this case 1234)
sudo apt update
sudo apt upgrade –y
sudo apt install git -y
### Check drives (Super + Software & updates)
Go to Additional drivers tab and make sure that says “No additional drivers available”

## Ubuntu testing
### How to Check Your Connected Devices: This method will show you how to check if the computer is detecting connected devices such as Webcam, 4G Modem, GPSd, Fingerprint, Touch Screen, or Smart Card Reader
Open the terminal and use the following commands
lsusb

If you do not see the device required in the list: This means the computer has not detected. This could be because the device is not working properly, it is not compatible, or it is not properly connected.

### How to Test Bluetooth & Wi-Fi: To test the Wi-Fi and Bluetooth, you don’t need to use the terminal. You can use the UI.
Settings => Networks || Bluetooth

### How to Set Up and Test the 4G Modem: Most of the time the Sierra Wireless EM7455 Modem works on Ubuntu 24.0, these devices are automatically detected and should work with the built-in drivers. However, you need to configurate the Access Point Name (APN) to connect your mobile data network.
## Insert the SIM Card: You will not see the “Mobile Network Configuration” option in the UI until a SIM Card is detected.
Go to Mobile Network Settings and configure the APN: Access Point Names => add new APN and you will need to fill these fields:
Name => internet
APN => sp.telus.com (remember you need to use the APN for the data provider)
Save changes and make sure to select this APN as the default

### Activate the Mobile data & Test:
ping 8.8.8.8
### How to Test GPS dedicated: To test the GPS module, you will use a service called gpsd and its related tools.  This service manages data from the GPS receiver and makes it available for other applications
Install gpsd and its tools: use the following command
sudo apt install gpsd gpsd-clients -y
Verify the GPS connection
lsusb | grep “U-Blox”
you will see the name of the device U-Blox AG [u-blox 8]
### Run GPS test with the following commands:

cgps
with this command you will see the data in console (text-based)
xgps
is a visual tool that shows the same information, it can take a few minutes to get a “fix” on the satellites.

### Troubleshooting: If the applications don’t show any data, it might be because you are in a space where the GPS doesn’t detect the satellites, or a problem with the gpsd service. You can check its status with:
sudo systemctl status gpsd
## WebCam Configuration: The Camera is usually detected and ready to go automatically. All you need to do is install a simple application to test it
sudo apt install cheese
### How to Calibrate the Touch Screen: You can calibrate the touchscreen using a command-line tool called xinput-calibrator. This tool is effective when you’re using the X Window System, which is the default display server on Ubuntu.
Install xinput-calibrator
sudo apt install xinput-calibrator
Run the Calibrator
Run the calibrator from the terminal. This will launch a simple graphical interface.
xinput_calibrator

Make the calibration permanent: After tapped all four points in the UI, the terminal will show the calibration data as a “snippet”. This snippet contains the values needed to make the calibration persistent across reboots.
Copy the entire output from the terminal (ctrl + shift + c)
sudo nano /etc/X11/xorg.conf.d/99-calibration.conf
Past the snippet into this file (ctrl + s) => save, (ctrl + x) => exit
reboot now
### How to Set up the Fingerprint Sensor: To test your fingerprint sensor, you will use a command-line tool called fprintd
Install fprintd
sudo apt install fprintd
Enroll a Fingerprint: If the sensor is detected, you can use fprintd to enroll a fingerprint.
fprintd-enroll
Follow the onscreen instructions, you’ll see a success message
fprint-verify
### How to set up the Smart Card Reader: To test the smart card reader, you can use command-line tools from pcsc-tools or opensc
Install the tools:
sudo apt install pcscd pcsc-tools
### Check is the Reader is detected
pscc_scan
The command will tell you if a reader is detected. Look for a line that says “Reader 0: <reader_name>…”. This means the system
recognizes the reader.
### Test with a card
Insert the smart card
pcsc_scan
The command will provide information about the card
Configure Computer Fan and Temperature: To diagnose a fan, you can use command-line tools to monitor your CPU temperature and fan speed.
Monitor CPU temperature: Install lm-sensors
sudo apt install lm-sensors
After installing, run the following command to have the system find all your hardware sensors. Press Enter at each question to accept the default options
sudo sensors-detect
sersors
With sensors command you can see the temperature of your CPU,GPU, and other parts.
Monitor Fan Speed: you can use lm-sensors along with fancontrol
Install fancontrol:
sudo apt install fancontrol
Configure fancontrol:
Sudo pwmconfig
### Follow the on-screen instructions to test the fans. This will show you the current speed in RPM
### Delete Test Profile and Prepare unit: To prepare the device for distribution as an (OEM) Original Equipment Manufacturer use the following commands:
Update and Upgrade the System:
sudo apt update && sudo apt full-upgrade -y
Install OEM packages:
sudo apt install -y oem-config-gtk oem-config-slideshow-ubuntu
Prepare the System for the End-User:
This is the most critical step. The oem-config-prepare command cleans up the system and sets it to a state where end-user can create their own account
sudo oem-config-prepare
Shutdown the device
sudo shutdown -h now
# Auto installation: This Script automates the process of scanning detected devices, installing the necessary drivers and packages for testing, and performing an OEM reset. While the script streamlines these tasks, it’s still highly recommended to manually test each device to verify its proper function.
Clone the repository
Make sure you are connected to Wi-Fi
cd Downloads
Sudo apt install git –y (in case that you did not install before)
git clone https://github.com/AndresVGu/toughbook-autoinstall
cd Toughbook-autoinstall
chmod +x autoinstall.sh
./autoinstall.sh




![image_qUmopwlnZAMuIE3+N/4rag==](./image_qUmopwlnZAMuIE3+N/4rag==.png)
![image_9km1ejTDhZRX/IdJKW5swA==](./image_9km1ejTDhZRX/IdJKW5swA==.png)
![image_fTiOAOOz0KOsAgbmfmu/CQ==](./image_fTiOAOOz0KOsAgbmfmu/CQ==.png)
![image_SLKwMDuQR64znT0XK0JaoA==](./image_SLKwMDuQR64znT0XK0JaoA==.png)
![image_UHbaOrFlWu/firAggGqb4Q==](./image_UHbaOrFlWu/firAggGqb4Q==.png)
