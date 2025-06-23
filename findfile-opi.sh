#!/bin/bash
user="$HOME"

if [ -f "user/loom/config.txt" ]; then
        echo "พบไฟล์"
else
        echo "ไม่พบไฟล์"
fi

if [ -d "user/loom" ]; then
        echo "พบไดเลกทอรี่ loom"
else
echo "ไม่พบไดเลกทอรี่ loom"
fi

if [ -d "user/loo1m" ]; then
        echo "พบไดเลกทอรี่ loo1m"
else
echo "ไม่พบไดเลกทอรี่ loo1m"
fi
