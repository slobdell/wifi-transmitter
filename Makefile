tx:
	sudo wfb_tx -l 1000 -K ./tx.key -p 1 -u 5600 wlan1

rx:
	sudo wfb_rx -l 1000 -K ./rx.key -p 1 -u 5000 wlan1

hello:
	echo "FINAL LOOPBACK TEST" | nc -u -q0 127.0.0.1 5001

listen:
	nc -l -u -p 5000

scan:
	nmap -sn 10.72.55.0/24
