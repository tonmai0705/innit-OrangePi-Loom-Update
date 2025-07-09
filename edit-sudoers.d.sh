#!/bin/bash
echo 'orangepi ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nodered.service' | sudo tee /etc/sudoers.d/nodered-nopasswd
sudo chmod 440 /etc/sudoers.d/nodered-nopasswd
