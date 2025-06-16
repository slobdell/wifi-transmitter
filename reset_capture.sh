#!/bin/bash

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
