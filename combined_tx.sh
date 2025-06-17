#!/bin/bash

# Pi5
MAC_ADDRESS=00:c0:ca:b7:9c:97
# Pi4
MAC_ADDRESS=00:c0:ca:b7:9c:9b
FRAME_RATE=30
BROADCAST_SIZE=1920x1080
MONITOR_SIZE=1280x720

# v4l2-ctl --list-devices
# find this ID via "ls -l /dev/v4l/by-id/"
CAPTURE_INPUT=/dev/v4l/by-id/usb-MACROSILICON_USB3_Video_67720542-video-index0
WFB_INTERFACE=wlan1
WFB_UDP_PORT=5600
ABSTRACT_PORT=1

echo "adapter mac is $MAC_ADDRESS"
WLAN_INTERFACE="$(ip -o link show | grep $MAC_ADDRESS | awk -F': ' '{print $2}')"

# Check if we found an interface
if [ -z "$WLAN_INTERFACE" ]; then
    echo "Error: Could not find network interface with MAC address $MAC_ADDRESS"
    exit 1
fi

echo "Waiting for interface $WLAN_INTERFACE to appear..."

# This loop will run until the 'ip link show' command succeeds
while ! ip link show $WLAN_INTERFACE > /dev/null 2>&1; do
    sleep 1
done

echo "Interface $WLAN_INTERFACE found. Proceeding with configuration."

# Now that we know the device exists, we can safely configure it.
sudo nmcli dev set $WLAN_INTERFACE managed no

echo "Starting WFB-NG transmitter on $WLAN_INTERFACE..."

echo "bringing down link..."
sudo ip link set $WLAN_INTERFACE down
echo "setting monitor none"
sudo iw dev $WLAN_INTERFACE set monitor none
echo "bringing link up..."
sudo ip link set $WLAN_INTERFACE up
echo "setting channel 36"
sudo iw dev $WLAN_INTERFACE set channel 40
# confirm with iwconfig wlan1
#
# This script resets the USB capture device at path 2-2.
# HDMI ADAPTER MUST BE PLUGGED INTO BOTTOM USB3 PORT
USB_DEVICE_PATH="2-2"

echo "Resetting USB device at /sys/bus/usb/devices/$USB_DEVICE_PATH ..."

# Unbind the device from its driver. This requires sudo privileges.
echo $USB_DEVICE_PATH > /sys/bus/usb/drivers/usb/unbind

# Wait a moment for the unbind to complete.
sleep 1

# Bind the device back to its driver.
echo $USB_DEVICE_PATH > /sys/bus/usb/drivers/usb/bind

echo "Reset complete."
# This script resets the USB capture device at path 2-2.
# HDMI ADAPTER MUST BE PLUGGED INTO BOTTOM USB3 PORT
USB_DEVICE_PATH="2-2"

echo "Resetting USB device at /sys/bus/usb/devices/$USB_DEVICE_PATH ..."

# Unbind the device from its driver. This requires sudo privileges.
echo $USB_DEVICE_PATH > /sys/bus/usb/drivers/usb/unbind

# Wait a moment for the unbind to complete.
sleep 1

# Bind the device back to its driver.
echo $USB_DEVICE_PATH > /sys/bus/usb/drivers/usb/bind

echo "Reset complete."

echo "starting wfb_tx"
sudo wfb_tx -l 1000 -K /home/eblimp/projects/video-tx-rx/tx.key -p 1 -u $WFB_UDP_PORT $WLAN_INTERFACE &

ffmpeg \
    -f v4l2 -input_format yuyv422 -video_size $BROADCAST_SIZE -framerate $FRAME_RATE -i "$CAPTURE_INPUT" \
    -filter_complex "[0:v]split=2[broadcast_out][preview_in];[preview_in]scale=$MONITOR_SIZE,format=rgb565le[preview_out]" \
    -map "[preview_out]" -f fbdev /dev/fb0 \
    -map "[broadcast_out]" -c:v h264_v4l2m2m -b:v 6M -f mpegts "udp://127.0.0.1:$WFB_UDP_PORT?pkt_size=1316&buffer_size=1000000"
