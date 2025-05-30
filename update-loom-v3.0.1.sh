#!/bin/bash
rm -rf $HOME/loom/
echo "delete file data is done..."
rm $HOME/connected_lemp.sh
rm $HOME/alarm_lemp.sh
echo "delete file lemp is done..."
rm $HOME/.node-red/flows.json
echo "delete flow.json is done..."
echo " "
echo "delete file is successfully..."

npm install @flowfuse/node-red-dashboard --prefix ~/.node-red
echo "ติดตั้ง Dashboard 2.0 เรียบร้อย!"
mkdir stat_led
cat << EOF > $HOME/stat_led/blink11.sh

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

cat << EOF > $HOME/stat_led/blink.sh 

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

cat << EOF > $HOME/stat_led/modbus_err.sh

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

echo "[ACK-IoT] ลบข้อมูล <Loom Config> เรียบร้อย..."
echo "[ACK-IoT] ติดตั้ง flowfuse@dashboard 2.0 เรียบร้อย..."
echo "[ACK-IoT] ติดตั้ง led state เรียบร้อย..."
echo "[ACK-IoT] ติดตั้ง flows.json เรียบร้อย..."
echo "[ACK-IoT] Orange Pi พร้อมทำงานแล้ว กรุณารีสตาร์ทอุปกรณ์..."
