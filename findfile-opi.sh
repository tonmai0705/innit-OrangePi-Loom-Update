#!/bin/bash
user=$HOME

source=$(grep -o -E 'source-[0-9]+' $user/.node-red/flows.json | sed 's/source-//' | sort -u)
        echo "Source: $source"
        
if [ -f "$user/loom/config.txt" ]; then
        echo "พบไฟล์"
else
        echo "ไม่พบไฟล์"
fi

if [ -d "$user/loom" ]; then
        echo "พบไดเลกทอรี่ loom"
else
echo "ไม่พบไดเลกทอรี่ loom"
fi

if [ -d "$user/loo1m" ]; then
        echo "พบไดเลกทอรี่ loo1m"
else
echo "ไม่พบไดเลกทอรี่ loo1m"
fi
cat << EOF > $user/loom/source.txt
$source
EOF
