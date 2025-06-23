#!/bin/bash
sudo apt update && sudo apt -y upgrade
rm -rf $HOME/loom/dataProduction/*
rm -d $HOME/loom/dataProduction
rm -rf $HOME/loom/thingsboard/*
rm -rf $HOME/loom/thingsboard/logdata/*
rm -d $HOME/loom/thingsboard/logdata

rm -rf $HOME/loom
cat << EOF > $HOME/loom/config.txt
{"state": {"datestamp": " ","ip": " "},"values": {"maintake": {"main": {"min": 0,"max": 0},"take": {"min": 0,"max": 0}},"meter": [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"working": [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]}}
EOF

mkdir updateandreboot
echo " [ACK-IoT Orange Pi Update Version] กำลังติดตั้ง Dashboard 2.0 และติดตั้ง flows Node-red กรุณารอสักครู่..."
npm install @flowfuse/node-red-dashboard --prefix ~/.node-red
cat << 'EOF' > $HOME/updateandreboot/reb.sh
#!/bin/bash

# เวลานับถอยหลัง (วินาที)
countdown=10

echo " [ACK-IoT Orange Pi Update Version] ระบบจะทำการรีบูตในอีก $countdown วินาที..."

# นับถอยหลัง
while [ $countdown -gt 0 ]; do
    echo " [ACK-IoT Orange Pi Update Version] OPI. Reboot In $countdown Second"
    sleep 1
    countdown=$((countdown - 1))
done

echo " [ACK-IoT Orange Pi Update Version] OPI Reboot!"
reboot -h
EOF
chmod +x $HOME/updateandreboot/reb.sh

cat << 'EOF' > $HOME/stat_led/blink11.sh

#!/bin/bash
# กำหนดหมายเลข GPIO pin
LED_PIN=11
# ตรวจสอบว่ามีพารามิเตอร์ถูกส่งเข้ามาหรือไม่
if [ $# -ne 1 ]; then
    echo "Usage: $0 <0|1>"
    exit 1
fi
# ตั้งค่า GPIO pin เป็น output
gpio mode $LED_PIN out
# ฟังก์ชันเพื่อกระพริบไฟ LED
blink_led() {
    trap "exit 0" SIGTERM  # จัดการกับสัญญาณ SIGTERM เพื่อหยุดการกระพริบ
        gpio write $LED_PIN 1
}
# รับพารามิเตอร์เพื่อควบคุมการกระพริบของไฟ LED
if [ $1 -eq 1 ]; then
    blink_led &  # เรียกฟังก์ชัน blink_led ใน background
    echo $! > /tmp/blink_led_pid  # บันทึก PID ของกระบวนการ blink_led
    echo "LED is blinking."
    sleep 1
    if [ -f /tmp/blink_led_pid ]; then
        kill -SIGTERM $(cat /tmp/blink_led_pid)  # ส่งสัญญาณ SIGTERM ไปที่กระบวนการ>
        rm /tmp/blink_led_pid  # ลบไฟล์ที่เก็บ PID
        echo "LED blinking stopped."
        gpio write $LED_PIN 0
    else
        echo "Blinking process not found."
    fi
else
    echo "Invalid parameter. Use 0 to stop blinking or 1 to start blinking."
    exit 1
fi

EOF

chmod +x $HOME/stat_led/blink11.sh

cat << 'EOF' > $HOME/stat_led/blink.sh 

#!/bin/bash
gpio_pin=12
# ตั้ง GPIO เป็นโหมด Output
gpio mode $gpio_pin out
# หยุด process ไฟกระพริบก่อน (ถ้ามี)
for pid in $(pgrep -f "blink.sh"); do
    if [ "$pid" != "$$" ]; then  # หลีกเลี่ยงการ kill ตัวเอง
        kill "$pid"
    fi
done
case "$1" in
    0)
        gpio write $gpio_pin 0  # ปิดไฟ
        ;;
    1)
        while true; do
            gpio write $gpio_pin 1
            sleep 1
            gpio write $gpio_pin 0
            sleep 1
        done &
        ;;
    2)
        while true; do
            gpio write $gpio_pin 1
            sleep 0.1
            gpio write $gpio_pin 0
            sleep 0.1
            gpio write $gpio_pin 1
            sleep 0.1
            gpio write $gpio_pin 0
            sleep 5
        done &
        ;;
    3)
        gpio write $gpio_pin 1  # ไฟติดค้าง
        ;;
    *)
        echo "Invalid input. Use 0, 1, 2, or 3."
        exit 1
        ;;
esac

EOF

chmod +x $HOME/stat_led/blink.sh

cat << 'EOF' > $HOME/stat_led/modbus_err.sh

#!/bin/bash

gpio_pin=11

# ตั้ง GPIO เป็นโหมด Output
gpio mode $gpio_pin out

# หยุด process ไฟกระพริบก่อน (ถ้ามี)
for pid in $(pgrep -f "modbus_err.sh"); do
    if [ "$pid" != "$$" ]; then  # หลีกเลี่ยงการ kill ตัวเอง
        kill "$pid"
    fi
done

# ทำงานกระพริบไฟเพียงครั้งเดียว
gpio write $gpio_pin 1
sleep 0.1
gpio write $gpio_pin 0
sleep 0.1
gpio write $gpio_pin 1
sleep 0.1
gpio write $gpio_pin 0

# หยุดกระบวนการที่เกี่ยวข้อง
for pid in $(pgrep -f "modbus_err.sh"); do
    if [ "$pid" != "$$" ]; then
        kill "$pid"
    fi
done

EOF

chmod +x $HOME/stat_led/modbus_err.sh

echo " [ACK-IoT Orange Pi Update Version] ลบข้อมูล <Loom Config> [/]"
echo " [ACK-IoT Orange Pi Update Version] ติดตั้ง led state [/]"
echo " [ACK-IoT Orange Pi Update Version] ติดตั้ง flows.json [/]"
echo " [ACK-IoT Orange Pi Update Version] Create scriptConfig.sh [/]"
echo " [ACK-IoT Orange Pi Update Version] Create modbus_err.sh [/]"
echo " [ACK-IoT Orange Pi Update Version] Create blink.sh [/]"
echo " [ACK-IoT Orange Pi Update Version] Create blink11.sh [/]"
echo " [ACK-IoT Orange Pi Update Version] Create reb.sh [/]"
echo " [ACK-IoT Orange Pi Update Version] ติดตั้ง @flowfuse/Dashboard 2.0 [/]"
