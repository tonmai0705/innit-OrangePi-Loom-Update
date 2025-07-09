#!/bin/bash
user = $HOME

rm $user/.node-red/flows.json

cat << 'EOF' > "$user/.node-red/flows.json"



EOF

node-red-restart
