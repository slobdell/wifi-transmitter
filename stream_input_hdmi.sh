#!/bin/bash

FRAME_RATE=30
BROADCAST_SIZE=1280x720
MONITOR_SIZE=1280x720

# v4l2-ctl --list-devices
# find this ID via "ls -l /dev/v4l/by-id/"
CAPTURE_INPUT=/dev/v4l/by-id/usb-MACROSILICON_USB3_Video_67720542-video-index0
WFB_INTERFACE=wlan1
WFB_UDP_PORT=5600
ABSTRACT_PORT=1

sudo ./reset_capture.sh

# On Pi 4 - Terminal 2 (The ffmpeg pipeline)
#ffmpeg \
#    -f v4l2 -input_format yuyv422 -video_size 1280x720 -framerate 30 -i "$CAPTURE_INPUT" \
#    -vf "format=yuv420p" \
#    -c:v libx264 -preset ultrafast -tune zerolatency -b:v 2M \
#    -x264opts "keyint=15:min-keyint=15:no-scenecut:bframes=0:ref=1" \
#    -f mpegts "udp://127.0.0.1:5600?pkt_size=1316&buffer_size=1000000"


# THIS WORKS, hardware encode and transmit
# ffmpeg -f v4l2 -input_format yuyv422 -video_size 1920x1080 -framerate 30 -i /dev/v4l/by-id/usb-MACROSILICON_USB3_Video_67720542-video-index0 -c:v h264_v4l2m2m -b:v 6M -f mpegts - | nc -u -q0 127.0.0.1 5600
# exit 0

# this will broadcast both to the wifi transmitter as well as the local monitor
ffmpeg \
    -f v4l2 -input_format yuyv422 -video_size $BROADCAST_SIZE -framerate $FRAME_RATE -i "$CAPTURE_INPUT" \
    -filter_complex "[0:v]split=2[broadcast_out][preview_in];[preview_in]scale=$MONITOR_SIZE,format=rgb565le[preview_out]" \
    -map "[preview_out]" -f fbdev /dev/fb0 \
    -map "[broadcast_out]" -c:v h264_v4l2m2m -b:v 6M -f mpegts "udp://127.0.0.1:$WFB_UDP_PORT?pkt_size=1316&buffer_size=1000000"
# | nc -u -q0 127.0.0.1 $WFB_UDP_PORT
