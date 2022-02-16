#!/bin/bash
sudo systemctl stop servername.service
sudo systemctl stop servername.socket
tar -Jcf /home/username/servername$(date '+%Y%m%d%H%M').tar.xz -C /home/username/ servername
rm /home/username/servername/*.log
