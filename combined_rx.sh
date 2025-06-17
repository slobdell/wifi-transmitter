#!/bin/bash
# Pi5
MAC_ADDRESS=00:c0:ca:b7:9c:97

WFB_INTERFACE=wlan1
WFB_UDP_PORT=5000
ABSTRACT_PORT=1
WIFI_CHANNEL=40

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
sudo iw dev $WLAN_INTERFACE set channel $WIFI_CHANNEL
# confirm with iwconfig wlan1
#
sudo wfb_rx -l 1000 -K /home/eblimp/projects/wifi-transmitter/rx.key -p 1 -u $WFB_UDP_PORT $WLAN_INTERFACE &

sudo ffmpeg -probesize 1M -fifo_size 5000000 -overrun_nonfatal 1 -i udp://127.0.0.1:5000 -vf "format=rgb565le" -f fbdev /dev/fb0
