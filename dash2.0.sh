#!/bin/bash

# โฟลเดอร์ Node-RED ของคุณ (แก้ไขให้ตรงกับเครื่องคุณ)
NODE_RED_DIR="$HOME/.node-red"

echo "กำลังเข้าไปที่โฟลเดอร์ Node-RED: $NODE_RED_DIR"
cd "$NODE_RED_DIR" || { echo "ไม่พบโฟลเดอร์ Node-RED"; exit 1; }

echo "กำลังติดตั้ง Node-RED Dashboard 2.0"
npm install node-red-dashboard@2.0.0

echo "ติดตั้งเสร็จเรียบร้อย"

echo "แนะนำให้รีสตาร์ท Node-RED เพื่อให้ Dashboard ใช้งานได้"
