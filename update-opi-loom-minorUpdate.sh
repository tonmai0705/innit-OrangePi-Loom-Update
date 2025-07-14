#!/bin/bash
user=$HOME
# update&upgrade
sudo apt update -y && sudo apt upgrade -y
# stamp datetime update
cat << EOF > $setting/update.json
{
  "version": "$(curl -s https://raw.githubusercontent.com/tonmai0705/innit-OrangePi-Loom-Update/refs/heads/Develop/version.txt)",
  "date": "$(date +%Y%m%d)"
}
