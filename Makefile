
tx:
	sudo wfb_tx -l 100 -K ./tx.key -p 1 -u 5001 wlan1

rx:
	sudo wfb_rx -l 100 -K ./rx.key -p 1 -u 5000 wlan1

hello:
	echo "FINAL LOOPBACK TEST" | nc -u -q0 127.0.0.1 5001
