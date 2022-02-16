trap control_c SIGINT
control_c() {
    exit
}
read -p 'Enter the server name to be configured, separated by a space: ' servernames
if [ -z "$servernames" ]; then
    exit 1
fi
username=$(whoami)
echo '#!/bin/bash' >stop-backup-and-restart.sh
for servername in $servernames; do
    if [ -e /home/$username/$servername/ExecStart.sh ]; then
        cat /home/$username/$servername/ExecStart.sh
    fi
    read -p "Enter $servername execution command (LD_LIBRARY_PATH=. ./bedrock_server) " serverstartcommand
    if [ -z "$serverstartcommand" ]; then
        serverstartcommand='LD_LIBRARY_PATH=. ./bedrock_server'
    fi
    mkdir -p $servername
    mkdir -p /home/$username/$servername
    cp serverfiles/* $servername
    if [ -e /home/$username/$servername/.env ]; then
        cat /home/$username/$servername/.env
    fi
    read -p "Enter the webhook URL of the discord you want to output the status of $servername: " webhookurl
    echo WEBHOOK_URL=$webhookurl >$servername/.env
    sed -i "s/username/$username/g" $servername/ExecStart.sh
    sed -i "s/username/$username/g" $servername/stop-and-backup-for-restart.sh
    sed -i "s/servername/$servername/g" $servername/ExecStart.sh
    sed -i "s/servername/$servername/g" $servername/ExecStop.sh
    sed -i "s/servername/$servername/g" $servername/stop-and-backup-for-restart.sh
    sed -i "s#serverstartcommand#$serverstartcommand#g" $servername/ExecStart.sh
    mv $servername/* $servername/.[^\.]* /home/$username/$servername
    rmdir $servername
    cp exampleserver.service $servername.service
    sed -i "s/username/$username/g" $servername.service
    sed -i "s/exampleserver/$servername/g" $servername.service
    chmod 644 $servername.service
    echo "Install $servername.service into /etc/systemd/system/"
    sudo mv $servername.service /etc/systemd/system/
    cp exampleserver.socket $servername.socket
    sed -i "s/username/$username/g" $servername.socket
    sed -i "s/exampleserver/$servername/g" $servername.socket
    chmod 644 $servername.socket
    echo "Install $servername.socket into /etc/systemd/system/"
    sudo mv $servername.socket /etc/systemd/system/
    echo 'Reload systemd manager configuration'
    sudo systemctl daemon-reload
    echo "Enable $servername.service"
    sudo systemctl enable $servername.service
    echo "/home/$username/$servername/stop-and-backup-for-restart.sh" >>stop-backup-and-restart.sh
    echo "systemctl restart $servername" >>stop-backup-and-restart.sh
    echo
done
echo 'Export the root crontab'
sudo crontab -l >crontab.tmp
if ! grep -q "30 4 1 \* \* systemctl reboot" crontab.tmp; then
    echo "30 4 1 * * systemctl reboot" >>crontab.tmp
fi
if ! grep -q "30 4 2-31 \* \* /home/$username/.ubuntu-bedrock-server/stop-backup-and-restart.sh" crontab.tmp; then
    echo "30 4 2-31 * * /home/$username/.ubuntu-bedrock-server/stop-backup-and-restart.sh" >>crontab.tmp
fi
echo "Add this to the root crontab"
sudo crontab -u root crontab.tmp
rm crontab.tmp
chmod 755 stop-backup-and-restart.sh
mkdir -p /home/$username/.ubuntu-bedrock-server
mv stop-backup-and-restart.sh /home/$username/.ubuntu-bedrock-server
echo 'Completed setup'
