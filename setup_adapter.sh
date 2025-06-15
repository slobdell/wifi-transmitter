#!/bin/bash
#

MAC_ADDRESS=00:c0:ca:b7:9c:97
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
