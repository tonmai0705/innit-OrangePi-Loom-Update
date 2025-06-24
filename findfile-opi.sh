#!/bin/bash
sudo apt update && sudo apt -y upgrade
user=$HOME

if [ -d "$user/loom" ]; then
        if [ -d "$user/loom/dataProduction" ]; then
                rm -rf $user/loom/dataProduction/*
                rm -d $user/loom/dataProduction
                echo " [ACK-IoT Orange Pi Update Version] ลบข้อมูล <dataProduction> เรียบร้อย..."
        fi
        if [ -d "$user/loom/thingsboard" ]; then
                rm -rf $user/loom/thingsboard/logdata/*
                rm -d $user/loom/thingsboard/logdata
                rm -d $user/loom/thngsboard
                echo " [ACK-IoT Orange Pi Update Version] ลบข้อมูล <thngsboard> เรียบร้อย..."
        fi
else
        mkdir $user/loom
        if [ ! -f "$user/loom/config.txt" ]; then
                cat << EOF > $user/loom/config.txt
                {"state": {"datestamp": " ","ip": " "},"values": {"maintake": {"main": {"min": 0,"max": 0},"take": {"min": 0,"max": 0}},"meter": [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"working": [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]}}
EOF
                echo "Config.txt is created"
        fi
fi

if [ ! -f "$user/loom/source.txt" ]; then
        source=$(grep -o -E 'source-[0-9]+' $user/.node-red/flows.json | sed 's/source-//' | sort -u)
        cat << EOF > $user/loom/source.txt
        $source
EOF
        echo "Source:$source"
fi

if [ ! -d "$user/stat_led" ]; then
        mkdir $user/stat_led
        if [ ! -f "$user/stat_led/blink11.sh" ]; then
                cat << 'EOF' > $user/stat_led/blink11.sh
                
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
                chmod +x $user/stat_led/blink11.sh
        fi
        if [ ! -f "$user/stat_led/blink.sh" ];then
                cat << 'EOF' > $user/stat_led/blink.sh 
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
                chmod +x $user/stat_led/blink.sh
        fi
        if [ ! -f "$user/stat_led/modbus_err.sh" ]; then
                cat << 'EOF' > $user/stat_led/modbus_err.sh
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
                chmod +x $user/stat_led/modbus_err.sh
        fi
        echo " [ACK-IoT Orange Pi Update Version] ติดตั้ง led state เรียบร้อย..."
fi
#--------------------------------------START-FLOWS-----------------------------------------------------------------

cat << 'EOF' > $user/.node-red/flows.json

EOF

#--------------------------------------END-FLOWS-----------------------------------------------------------------

if [ ! -f "$user/updateandreboot/reb.sh" ]; then
        mkdir $user/updateandreboot
        cat << 'EOF' > $user/updateandreboot/reb.sh
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
        chmod +x $user/updateandreboot/reb.sh

fi
echo " [ACK-IoT Orange Pi Update Version] กำลังติดตั้ง Dashboard 2.0 และติดตั้ง flows Node-red กรุณารอสักครู่..."
npm install @flowfuse/node-red-dashboard --prefix ~/.node-red

echo " [ACK-IoT Orange Pi Update Version] ติดตั้ง @flowfuse/Dashboard 2.0 เรียบร้อย..."
echo " [ACK-IoT Orange Pi Update Version] Orange Pi พร้อมทำงานแล้ว การอัพเดทเสร็จสำบูรณ์ กรุณารีสตาร์ทอุปกรณ์..."
bash $user/updateandreboot/reb.sh




