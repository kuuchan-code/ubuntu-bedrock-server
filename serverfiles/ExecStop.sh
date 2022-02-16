#!/bin/bash
python3 -u ExecStop-minecord.py &
sleep 2s
echo 'stop' > /run/servername.stdin
sudo systemctl stop servername.socket