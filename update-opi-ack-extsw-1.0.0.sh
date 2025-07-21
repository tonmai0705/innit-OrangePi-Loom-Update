#!/bin/bash
sudo apt update && sudo apt -y upgrade
npm install @flowfuse/node-red-dashboard --prefix ~/.node-red 
user=$HOME

#check Diractory and create
if [ ! -d "$user/ext" ]; then
mkdir ext
mkdir $user/data

#create scriptConfig.sh
cat << 'EOF' > $user/ext/scriptConfig.sh
#!/bin/bash
user="$HOME"
tmpFile="$user/ext/config.txt.tmp"
finalFile="$user/ext/config.txt"
backupFile="$user/ext/config.txt.bak"
if [ -f "$tmpFile" ]; then
        if [ -f "$finalFile" ]; then
                cp "$finalFile" "$backupFile"
                sync
        fi
sync
mv "$tmpFile" "$finalFile"
else
echo "Not Found"
fi
EOF
chmod +x $user/ext/scriptConfig.sh

#create config file
cat << 'EOF' > $user/ext/config.txt
{"date":"2025/07/21","datestamp":"20250721","time":"08:43:51","ip":"192.168.1.111","hourstamp":"00","changehour":0,"bot_token":"0","chat_id":"0","local":{"ip":"192.168.0.9","index":{"pro":0,"pow":0}},"things":{"broker":0,"port":0,"username":0,"topic":0,"index":{"pro":0,"pow":0}},"temp":{"mt_in":{"now":0,"min":0,"max":0},"mt_out":{"now":0,"min":0,"max":0},"cl_in":{"now":0,"min":0,"max":0},"cl_out":{"now":0,"min":0,"max":0}},"speed":{"scr":{"now":0,"min":0,"max":0},"hol":{"now":0,"min":0,"max":0},"ann":{"now":0,"min":0,"max":0},"str":{"now":0,"min":0,"max":0}},"meter":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]}
EOF
fi

#check led state
if [ ! -d "$user/stat_led" ]; then
mkdir stat_led
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

cat << 'EOF' > $user/stat_led/modbus_err.sh.sh
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
chmod +x $user/stat_led/modbus_err.sh.sh
fi

#node-red flows
cat << 'EOF' > $user/.node-red/flows.json
[
    {
        "id": "a4638d4e8237493c",
        "type": "tab",
        "label": "main",
        "disabled": false,
        "info": "#Description\r\n-MQTT Protocols",
        "env": []
    },
    {
        "id": "4d3c8d61d6d0cf94",
        "type": "subflow",
        "name": "ME337",
        "info": "",
        "category": "",
        "in": [
            {
                "x": 230,
                "y": 60,
                "wires": [
                    {
                        "id": "bb440e053e24db36"
                    }
                ]
            }
        ],
        "out": [
            {
                "x": 980,
                "y": 500,
                "wires": [
                    {
                        "id": "8dfc46ddc3bffa53",
                        "port": 0
                    }
                ]
            }
        ],
        "env": [],
        "meta": {},
        "color": "#A6FF00"
    },
    {
        "id": "416e4ad47d77d15d",
        "type": "subflow",
        "name": "Extruder",
        "info": "Input\r\n- payload Key\r\n    - 'unitid' = Modbus ID\r\n    - 'fc' = Modbus Function Code\r\n    - 'address' = address register\r\n    - 'main' = speed main register\r\n    - 'take_up' = speed take up register\r\n    - 'meter' = meter register\r\n    - 'values' = values for Modbus write",
        "category": "Special Node",
        "in": [
            {
                "x": 40,
                "y": 60,
                "wires": [
                    {
                        "id": "f6145de4c3efe695"
                    },
                    {
                        "id": "d9d9fc8ac7855822"
                    }
                ]
            }
        ],
        "out": [
            {
                "x": 400,
                "y": 280,
                "wires": [
                    {
                        "id": "8ead4a4afb84bc30",
                        "port": 0
                    }
                ]
            }
        ],
        "env": [],
        "meta": {},
        "color": "#41b653",
        "icon": "font-awesome/fa-cogs",
        "status": {
            "x": 460,
            "y": 300,
            "wires": [
                {
                    "id": "9f51b4f10a6c9ac1",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "4f29820d32ebeb14",
        "type": "subflow",
        "name": "OnBoard",
        "info": "Input\r\n- current rate (msg.current_rate)\r\n- timestamp (msg.payload)",
        "category": "PowerMeter",
        "in": [
            {
                "x": 60,
                "y": 100,
                "wires": [
                    {
                        "id": "ed5602e9fb9196a6"
                    },
                    {
                        "id": "585b0e5df295256e"
                    }
                ]
            }
        ],
        "out": [
            {
                "x": 580,
                "y": 400,
                "wires": [
                    {
                        "id": "ce1481109e94455c",
                        "port": 0
                    }
                ]
            }
        ],
        "env": [],
        "meta": {},
        "color": "#A6FF00",
        "icon": "font-awesome/fa-tachometer",
        "status": {
            "x": 340,
            "y": 360,
            "wires": [
                {
                    "id": "ab10bbf8004addb5",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "84087161fd829d92",
        "type": "subflow",
        "name": "Product.csv",
        "info": "inout\r\n - msg.path\r\n\r\noutput\r\n - 1: msg.payload .csv(object) + colum\r\n - 2: msg.payload .csv(object)",
        "category": "Special Node",
        "in": [
            {
                "x": 100,
                "y": 180,
                "wires": [
                    {
                        "id": "854eb4f62546adcb"
                    },
                    {
                        "id": "ec681e6e8b6dc504"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#f3dd00",
        "icon": "font-awesome/fa-book",
        "status": {
            "x": 970,
            "y": 180,
            "wires": [
                {
                    "id": "a5f3d640d8df39da",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "327188e739dd9e39",
        "type": "subflow",
        "name": "power.csv",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 50,
                "y": 30,
                "wires": [
                    {
                        "id": "72330c8a31557423"
                    }
                ]
            }
        ],
        "out": [
            {
                "x": 360,
                "y": 40,
                "wires": [
                    {
                        "id": "699f8fb22d99fcf0",
                        "port": 0
                    }
                ]
            }
        ],
        "env": [],
        "meta": {},
        "color": "#00c500",
        "icon": "node-red-contrib-filesystem/fs-mkdir.svg"
    },
    {
        "id": "766dd95607e2bd11",
        "type": "subflow",
        "name": "product.csv",
        "info": "input\r\n - msg.path // path your file\r\n\r\noutput\r\n - msg.payload // payload .csv(object)",
        "category": "Special Node",
        "in": [
            {
                "x": 60,
                "y": 80,
                "wires": [
                    {
                        "id": "a5f173bb48c85e9c"
                    }
                ]
            }
        ],
        "out": [
            {
                "x": 420,
                "y": 80,
                "wires": [
                    {
                        "id": "fea015996e00245b",
                        "port": 0
                    }
                ]
            }
        ],
        "env": [],
        "meta": {},
        "color": "#00c500",
        "icon": "node-red-contrib-filesystem/fs-mkdir.svg"
    },
    {
        "id": "3c87dd77ddd56ab5",
        "type": "subflow",
        "name": "API.set",
        "info": "",
        "category": "Special Node",
        "in": [],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#00ceea",
        "icon": "font-awesome/fa-cloud",
        "status": {
            "x": 860,
            "y": 280,
            "wires": [
                {
                    "id": "def0597e21ffc9ac",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "5cf1d8d919e64156",
        "type": "subflow",
        "name": "UI Selection",
        "info": "",
        "category": "Special Node",
        "in": [],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#42a4f5",
        "icon": "font-awesome/fa-flash"
    },
    {
        "id": "7fe66403ea1a14c9",
        "type": "subflow",
        "name": "List ",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 60,
                "y": 80,
                "wires": [
                    {
                        "id": "0fe03920e069b952"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#f95ed6",
        "icon": "node-red-contrib-filesystem/fs-list.svg",
        "status": {
            "x": 960,
            "y": 80,
            "wires": [
                {
                    "id": "ced2fb5fb7b6d214",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "02f6142c6c7e99bb",
        "type": "subflow",
        "name": "conf.Set",
        "info": "input\r\n - Data config to config.csv file",
        "category": "Special Node",
        "in": [
            {
                "x": 50,
                "y": 30,
                "wires": [
                    {
                        "id": "861f956f24a820d1"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#ff834a",
        "icon": "node-red/cog.svg"
    },
    {
        "id": "6fa1970c13440cc6",
        "type": "subflow",
        "name": "Get IP",
        "info": "",
        "category": "Special node",
        "in": [
            {
                "x": 80,
                "y": 80,
                "wires": [
                    {
                        "id": "b74bb320b5bc3c63"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#ff6100",
        "icon": "node-red/white-globe.svg",
        "status": {
            "x": 480,
            "y": 60,
            "wires": [
                {
                    "id": "5dd73751e98d7f8b",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "f386491b277c5eef",
        "type": "subflow",
        "name": "Global",
        "info": "",
        "category": "Special node",
        "in": [
            {
                "x": 60,
                "y": 80,
                "wires": [
                    {
                        "id": "bd9c9e92281baaf1"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#046a3b",
        "icon": "font-awesome/fa-globe",
        "status": {
            "x": 360,
            "y": 80,
            "wires": [
                {
                    "id": "68173607fb2aaab1",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "31057fe0b0d4c1ec",
        "type": "subflow",
        "name": "Blink",
        "info": "input\r\n - msg.",
        "category": "Lamp",
        "in": [
            {
                "x": 40,
                "y": 40,
                "wires": [
                    {
                        "id": "db6fc316f972fc7a"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#ef42f5",
        "icon": "font-awesome/fa-lightbulb-o"
    },
    {
        "id": "509f550183b44678",
        "type": "subflow",
        "name": "conf.Get",
        "info": "input\r\n - msg.\r\noutput\r\n - msg.payload (config.csv)",
        "category": "Special Node",
        "in": [
            {
                "x": 50,
                "y": 30,
                "wires": [
                    {
                        "id": "9d59bd99c742070f"
                    }
                ]
            }
        ],
        "out": [
            {
                "x": 440,
                "y": 40,
                "wires": [
                    {
                        "id": "1d906f7812c229a3",
                        "port": 0
                    },
                    {
                        "id": "0bfd0466d7206413",
                        "port": 0
                    }
                ]
            }
        ],
        "env": [],
        "meta": {},
        "color": "#ff834a",
        "icon": "node-red/cog.svg"
    },
    {
        "id": "db4fabd6a1540331",
        "type": "subflow",
        "name": "Thingsboard",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 60,
                "y": 60,
                "wires": [
                    {
                        "id": "48368b80a493ddf8"
                    },
                    {
                        "id": "66f48e5b501373bc"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#607d8b",
        "icon": "font-awesome/fa-area-chart",
        "status": {
            "x": 680,
            "y": 60,
            "wires": [
                {
                    "id": "e3d8f6657de33357",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "2475655a38fb291d",
        "type": "subflow",
        "name": "Delete Thingsboard",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 60,
                "y": 20,
                "wires": [
                    {
                        "id": "41f5532d4a7103fe"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#06ffdd",
        "icon": "node-red/alert.svg"
    },
    {
        "id": "a64e2ac5a1b6390b",
        "type": "subflow",
        "name": "HTTP Things Board",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 60,
                "y": 80,
                "wires": [
                    {
                        "id": "71af026a4f564a9b"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#42e6f5",
        "icon": "font-awesome/fa-feed",
        "status": {
            "x": 420,
            "y": 80,
            "wires": [
                {
                    "id": "02fcc1765deebed1",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "2bafb72664960be0",
        "type": "subflow",
        "name": "CSV Thingsboard",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 60,
                "y": 100,
                "wires": [
                    {
                        "id": "bd7abb7d25a89c27"
                    }
                ]
            }
        ],
        "out": [
            {
                "x": 740,
                "y": 100,
                "wires": [
                    {
                        "id": "b525daa1de310d5c",
                        "port": 0
                    }
                ]
            },
            {
                "x": 560,
                "y": 140,
                "wires": [
                    {
                        "id": "d4423d018ce4f524",
                        "port": 0
                    }
                ]
            }
        ],
        "env": [],
        "meta": {},
        "color": "#607d8b",
        "icon": "font-awesome/fa-database",
        "status": {
            "x": 740,
            "y": 40,
            "wires": [
                {
                    "id": "393b596221693772",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "4f0fd70632b3c011",
        "type": "subflow",
        "name": "ME337test",
        "info": "input\r\n    msg.unidid",
        "category": "PowerMeter",
        "in": [
            {
                "x": 160,
                "y": 150,
                "wires": [
                    {
                        "id": "9d0382eb7add361f"
                    },
                    {
                        "id": "08092ba982aebf66"
                    }
                ]
            }
        ],
        "out": [
            {
                "x": 460,
                "y": 80,
                "wires": [
                    {
                        "id": "408a08ee9acadf58",
                        "port": 0
                    }
                ]
            }
        ],
        "env": [],
        "meta": {},
        "color": "#A6FF00"
    },
    {
        "id": "13f006802899e0be",
        "type": "subflow",
        "name": "Ping",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 60,
                "y": 80,
                "wires": [
                    {
                        "id": "633e9c4b40e42584"
                    }
                ]
            }
        ],
        "out": [
            {
                "x": 840,
                "y": 80,
                "wires": [
                    {
                        "id": "c7fcb9a183a78340",
                        "port": 0
                    }
                ]
            }
        ],
        "env": [],
        "meta": {},
        "color": "#ffb900",
        "icon": "font-awesome/fa-chain",
        "status": {
            "x": 840,
            "y": 140,
            "wires": [
                {
                    "id": "346948538b2e924a",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "8e2e38d354fe03ed",
        "type": "subflow",
        "name": "Commu",
        "info": "Input\r\n- msg.",
        "category": "Lamp",
        "in": [
            {
                "x": 40,
                "y": 40,
                "wires": [
                    {
                        "id": "1c5975849d6fe242"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#6C00FF",
        "icon": "node-red/light.svg"
    },
    {
        "id": "d70462931d98191e",
        "type": "subflow",
        "name": "Temp Board",
        "info": "",
        "category": "",
        "in": [
            {
                "x": 60,
                "y": 80,
                "wires": [
                    {
                        "id": "a0c1fc8ef292ea30"
                    }
                ]
            }
        ],
        "out": [
            {
                "x": 560,
                "y": 60,
                "wires": [
                    {
                        "id": "100c04dfb1fc8533",
                        "port": 0
                    }
                ]
            }
        ],
        "env": [],
        "meta": {},
        "color": "#DDAA99"
    },
    {
        "id": "e226ede58ea4b202",
        "type": "subflow",
        "name": "Modbus Reboot",
        "info": "",
        "category": "",
        "in": [],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#6229ff",
        "icon": "node-red/alert.svg",
        "status": {
            "x": 380,
            "y": 220,
            "wires": [
                {
                    "id": "c5418b2844d316d7",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "08bf79c0de8b2ac1",
        "type": "subflow",
        "name": "3-Phase kWh Meter",
        "info": "",
        "category": "PowerMeter",
        "in": [
            {
                "x": 80,
                "y": 100,
                "wires": [
                    {
                        "id": "c0f9612c44d3b1a9"
                    },
                    {
                        "id": "98efd0b00952e62f"
                    },
                    {
                        "id": "01448e1706374234"
                    }
                ]
            }
        ],
        "out": [
            {
                "x": 520,
                "y": 360,
                "wires": [
                    {
                        "id": "eca5291042b4bf09",
                        "port": 0
                    }
                ]
            }
        ],
        "env": [],
        "meta": {},
        "color": "#0ac3c9",
        "icon": "node-red/status.svg"
    },
    {
        "id": "5444d5754c7e8492",
        "type": "subflow",
        "name": "Temp to PLC",
        "info": "",
        "category": "",
        "in": [
            {
                "x": 60,
                "y": 100,
                "wires": [
                    {
                        "id": "19678fef328fa5a4"
                    },
                    {
                        "id": "758d37fd74bb8898"
                    }
                ]
            }
        ],
        "out": [
            {
                "x": 820,
                "y": 200,
                "wires": [
                    {
                        "id": "232ec32b38bad6f9",
                        "port": 0
                    }
                ]
            }
        ],
        "env": [],
        "meta": {},
        "color": "#DDAA99",
        "status": {
            "x": 820,
            "y": 100,
            "wires": [
                {
                    "id": "8b64f67972fa28c3",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "459dc2665cb0fd05",
        "type": "subflow",
        "name": "Telegram API",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 60,
                "y": 80,
                "wires": [
                    {
                        "id": "c58fc5dd0a3782e6"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#38d2fc",
        "icon": "font-awesome/fa-paper-plane",
        "status": {
            "x": 840,
            "y": 80,
            "wires": [
                {
                    "id": "da506d58575ccd4a",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "5186eb39253053a0",
        "type": "subflow",
        "name": "Actu-Lum Cloud Server",
        "info": "",
        "category": "NSP",
        "in": [
            {
                "x": 60,
                "y": 80,
                "wires": [
                    {
                        "id": "ee3cb4661478a727"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#40cfff",
        "icon": "font-awesome/fa-cloud-upload",
        "status": {
            "x": 680,
            "y": 80,
            "wires": [
                {
                    "id": "7089388e2e3162b3",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "0d668fc71eab2a38",
        "type": "subflow",
        "name": "Subflow 1",
        "info": "",
        "in": [],
        "out": []
    },
    {
        "id": "12021995985b969c",
        "type": "subflow",
        "name": "Subflow 2",
        "info": "",
        "category": "",
        "in": [
            {
                "x": 60,
                "y": 80,
                "wires": [
                    {
                        "id": "0f1c91d0e51de893"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#DDAA99",
        "status": {
            "x": 720,
            "y": 80,
            "wires": [
                {
                    "id": "e3a2b851d624434a",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "2b98acde2363f390",
        "type": "subflow",
        "name": "Delete Thingsboard (2)",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 60,
                "y": 20,
                "wires": [
                    {
                        "id": "65cafb99a2d8ea22"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#06ffdd",
        "icon": "node-red/alert.svg"
    },
    {
        "id": "fb9a76fc3fc3bf75",
        "type": "subflow",
        "name": "MQTT Things Board",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 260,
                "y": 80,
                "wires": [
                    {
                        "id": "afd5d4f8d1f23ed4"
                    },
                    {
                        "id": "ee71a4cd9a89ccb4"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#42e6f5",
        "icon": "font-awesome/fa-feed",
        "status": {
            "x": 420,
            "y": 80,
            "wires": [
                {
                    "id": "afd5d4f8d1f23ed4",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "2e0105dcea086c8e",
        "type": "subflow",
        "name": "CSV Thingsboard (2)",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 60,
                "y": 100,
                "wires": [
                    {
                        "id": "3de8ccb8ea347799"
                    }
                ]
            }
        ],
        "out": [
            {
                "x": 740,
                "y": 100,
                "wires": [
                    {
                        "id": "ed4575f3c65e3dd9",
                        "port": 0
                    }
                ]
            }
        ],
        "env": [],
        "meta": {},
        "color": "#607d8b",
        "icon": "font-awesome/fa-database",
        "status": {
            "x": 740,
            "y": 40,
            "wires": [
                {
                    "id": "a58b51ecd58caf5a",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "5c066a4a210a6f29",
        "type": "group",
        "z": "a4638d4e8237493c",
        "name": "Modbus",
        "style": {
            "stroke": "#ff0000",
            "label": true,
            "label-position": "n",
            "color": "#ff3f3f",
            "fill": "#000000",
            "fill-opacity": "1"
        },
        "nodes": [
            "94d8bed30760b9ab",
            "b5cc5e62d075e23c",
            "8dde1267333c6a89",
            "e520305b2c0acc0c",
            "d02275d776d7a56d",
            "5994866ceafe6967",
            "ea7a27ca30464756",
            "a241e24d2a8bd154",
            "b34905dcb1c392f4",
            "f2e4983af2f69097",
            "3de79f17e996a803",
            "1095488ec8f233c2",
            "6c07456b931359bb",
            "12dd0b09b0e85bbb",
            "b79a8caa8c12d89b",
            "173c54a7d9c4c04d",
            "6a9232d5cdac3c29",
            "6fcede93d69086fc",
            "87f713810b33a180",
            "cfc9a42476888a7b",
            "964add341126d593"
        ],
        "x": 244,
        "y": 79,
        "w": 702,
        "h": 302
    },
    {
        "id": "358de3fc3d0c3af8",
        "type": "group",
        "z": "4f29820d32ebeb14",
        "name": "",
        "style": {
            "label": true,
            "stroke": "#0070c0",
            "fill": "#000000",
            "label-position": "n",
            "color": "#3f93cf"
        },
        "nodes": [
            "7a6609194f821a65",
            "ed5602e9fb9196a6",
            "a551913c95f77777",
            "c8a96d6f637749b0",
            "ca4b8ee67492864b",
            "6a8cec485f693b21",
            "5a5076a80b987df8",
            "83cae54a6e393b85",
            "338f82eeac2df0c4",
            "c9b6f5fd1b7111d8",
            "d766edb56f4cf828",
            "7a1caac4460ad806",
            "eb0c8cda22c456e6",
            "ce1481109e94455c",
            "585b0e5df295256e",
            "ab10bbf8004addb5"
        ],
        "x": 104,
        "y": 39,
        "w": 462,
        "h": 402
    },
    {
        "id": "c65113dc80938b27",
        "type": "group",
        "z": "a4638d4e8237493c",
        "name": "Product & Power",
        "style": {
            "label": true,
            "label-position": "n",
            "color": "#92d04f",
            "stroke": "#92d04f",
            "fill": "#000000",
            "fill-opacity": "1"
        },
        "nodes": [
            "be91844f8b0985bc",
            "0bb91ff2ea50d493",
            "75909748614ac097",
            "6c35abd254398878",
            "446099760a4cb78e"
        ],
        "x": 244,
        "y": 399,
        "w": 542,
        "h": 102
    },
    {
        "id": "e58558cb75de9af5",
        "type": "group",
        "z": "84087161fd829d92",
        "name": "Power",
        "style": {
            "label": true
        },
        "nodes": [
            "ec681e6e8b6dc504",
            "91bbc3864133b185",
            "2e08ad99f972e679",
            "14ee0d84e5405125",
            "3ee4450ecf3c66f3",
            "2d7496a55fd4d5e5",
            "6b7fdbc76da5753a",
            "cd67d193c28c206a",
            "6e0b50d6e2f6c050",
            "02f11ab3313a9672"
        ],
        "x": 174,
        "y": 199,
        "w": 592,
        "h": 122
    },
    {
        "id": "06e517f2e69268b9",
        "type": "group",
        "z": "84087161fd829d92",
        "name": "Product",
        "style": {
            "label": true
        },
        "nodes": [
            "854eb4f62546adcb",
            "bb66bd0fb5225235",
            "6fee32cfab3c9cae",
            "96c87dc3db41c897",
            "888f91628a6972ce",
            "21232d92a0568ba1",
            "4cb68426af89913b",
            "d85755f4700406ad",
            "a72a90a834670a67",
            "22a14c902b412f4a"
        ],
        "x": 174,
        "y": 39,
        "w": 592,
        "h": 122
    },
    {
        "id": "0134013d6c49db3c",
        "type": "group",
        "z": "a4638d4e8237493c",
        "name": "API & UI",
        "style": {
            "stroke": "#6f2fa0",
            "fill": "#000000",
            "fill-opacity": "1",
            "label": true,
            "label-position": "n",
            "color": "#dbcbe7"
        },
        "nodes": [
            "aaa02e33b2312586"
        ],
        "x": 794,
        "y": 399,
        "w": 152,
        "h": 82
    },
    {
        "id": "72e3abb3e7faf340",
        "type": "group",
        "z": "a4638d4e8237493c",
        "name": "Filename",
        "style": {
            "stroke": "#0070c0",
            "fill": "#000000",
            "label": true,
            "label-position": "n",
            "color": "#3f93cf",
            "fill-opacity": "1"
        },
        "nodes": [
            "65c6c67163f4a846",
            "54b953cb7c4b2af9",
            "782058517c0086ed",
            "e910a6992307569f",
            "28abf05cd47dacbe",
            "847ddf396d892cec",
            "b9c18f7fcd8e7a77",
            "3d6407e35ec14c30",
            "85b4fe24b79a8752",
            "3bbc4188314c94b0",
            "0be2359769c61c3a",
            "37cd68613dcfe737",
            "db63266254b0328a",
            "e6290a07b12de109",
            "b0abde57f8695277"
        ],
        "x": 954,
        "y": 79,
        "w": 412,
        "h": 402
    },
    {
        "id": "af4007faccb71e48",
        "type": "group",
        "z": "a4638d4e8237493c",
        "name": "Things Board Log",
        "style": {
            "label": true,
            "stroke": "#607d8b",
            "fill": "#000000",
            "fill-opacity": "0.93",
            "label-position": "n",
            "color": "#607d8b"
        },
        "nodes": [
            "0374611cfdba1420",
            "185912f8d1668211",
            "6fdc936b9c9e8ee7",
            "d93828fb405910d4"
        ],
        "x": 244,
        "y": 519,
        "w": 542,
        "h": 102
    },
    {
        "id": "48aaab48a5e282bd",
        "type": "group",
        "z": "a4638d4e8237493c",
        "name": "Telegram",
        "style": {
            "stroke": "#0070c0",
            "fill": "#000000",
            "fill-opacity": "0.9",
            "label": true,
            "label-position": "n",
            "color": "#3f93cf"
        },
        "nodes": [
            "b3fe5e767a5564d1",
            "d6697f2dedb0c187",
            "bc442d4e5e05fdd9"
        ],
        "x": 244,
        "y": 619,
        "w": 542,
        "h": 82
    },
    {
        "id": "3ede334f566d2cd3",
        "type": "group",
        "z": "a4638d4e8237493c",
        "name": "Things Board Transmission",
        "style": {
            "stroke": "#607d8b",
            "fill": "#000000",
            "fill-opacity": "0.94",
            "label": true,
            "label-position": "n",
            "color": "#607d8b"
        },
        "nodes": [
            "17b4e662190c5772",
            "2b1315c081abf404",
            "199c10969eee6b5a"
        ],
        "x": 804,
        "y": 499,
        "w": 612,
        "h": 102
    },
    {
        "id": "ed5602e9fb9196a6",
        "type": "junction",
        "z": "4f29820d32ebeb14",
        "g": "358de3fc3d0c3af8",
        "x": 160,
        "y": 100,
        "wires": [
            [
                "a551913c95f77777",
                "7a6609194f821a65"
            ]
        ]
    },
    {
        "id": "291667434678740d",
        "type": "modbus-client",
        "name": "",
        "clienttype": "serial",
        "bufferCommands": true,
        "stateLogEnabled": false,
        "queueLogEnabled": false,
        "failureLogEnabled": true,
        "tcpHost": "127.0.0.1",
        "tcpPort": "502",
        "tcpType": "DEFAULT",
        "serialPort": "/dev/ttyUSB0",
        "serialType": "RTU-BUFFERD",
        "serialBaudrate": "9600",
        "serialDatabits": "8",
        "serialStopbits": "1",
        "serialParity": "none",
        "serialConnectionDelay": "100",
        "serialAsciiResponseStartDelimiter": "0x3A",
        "unit_id": 1,
        "commandDelay": 1,
        "clientTimeout": 1000,
        "reconnectOnTimeout": true,
        "reconnectTimeout": 2000,
        "parallelUnitIdsAllowed": true,
        "showErrors": false,
        "showWarnings": true,
        "showLogs": true
    },
    {
        "id": "b1c16cc4bf11ba76",
        "type": "ui-base",
        "name": "My Dashboard",
        "path": "/dashboard",
        "appIcon": "",
        "includeClientData": true,
        "acceptsClientConfig": [
            "ui-notification",
            "ui-control"
        ],
        "showPathInSidebar": false,
        "navigationStyle": "default",
        "titleBarStyle": "default"
    },
    {
        "id": "818c81dd7f0dc596",
        "type": "ui-group",
        "name": "Login",
        "page": "69c090379216efb6",
        "width": "4",
        "height": "5",
        "order": 2,
        "showTitle": true,
        "className": "",
        "visible": "true",
        "disabled": "false",
        "groupType": "dialog"
    },
    {
        "id": "963da81f78ac7902",
        "type": "ui-group",
        "name": "Home",
        "page": "69c090379216efb6",
        "width": "12",
        "height": "12",
        "order": 1,
        "showTitle": false,
        "className": "",
        "visible": "true",
        "disabled": "false",
        "groupType": "default"
    },
    {
        "id": "1a25a88e19cb234a",
        "type": "ui-group",
        "name": "Configurations",
        "page": "69c090379216efb6",
        "width": "7",
        "height": "1",
        "order": 3,
        "showTitle": true,
        "className": "",
        "visible": "false",
        "disabled": "false",
        "groupType": "dialog"
    },
    {
        "id": "5afa5b8f48610c59",
        "type": "ui-group",
        "name": "TBconfig",
        "page": "69c090379216efb6",
        "width": "6",
        "height": "1",
        "order": 4,
        "showTitle": false,
        "className": "",
        "visible": "true",
        "disabled": "false",
        "groupType": "dialog"
    },
    {
        "id": "69c090379216efb6",
        "type": "ui-page",
        "name": "Admin",
        "ui": "b1c16cc4bf11ba76",
        "path": "/Admin",
        "icon": "home",
        "layout": "grid",
        "theme": "13a6e3bd8913ab9c",
        "breakpoints": [
            {
                "name": "Default",
                "px": "0",
                "cols": "3"
            },
            {
                "name": "Tablet",
                "px": "576",
                "cols": "6"
            },
            {
                "name": "Small Desktop",
                "px": "768",
                "cols": "9"
            },
            {
                "name": "Desktop",
                "px": "1024",
                "cols": "12"
            }
        ],
        "order": 1,
        "className": "",
        "visible": "true",
        "disabled": "false"
    },
    {
        "id": "13a6e3bd8913ab9c",
        "type": "ui-theme",
        "name": "User",
        "colors": {
            "surface": "#becf96",
            "primary": "#021562",
            "bgPage": "#ecf1e0",
            "groupBg": "#ffffff",
            "groupOutline": "#cccccc"
        },
        "sizes": {
            "density": "default",
            "pagePadding": "12px",
            "groupGap": "12px",
            "groupBorderRadius": "4px",
            "widgetGap": "12px"
        }
    },
    {
        "id": "2c538605a7eee495",
        "type": "ui-group",
        "name": "PCconfig",
        "page": "69c090379216efb6",
        "width": "6",
        "height": "1",
        "order": 5,
        "showTitle": false,
        "className": "",
        "visible": "true",
        "disabled": "false",
        "groupType": "dialog"
    },
    {
        "id": "9f6f2b404040703b",
        "type": "ui-spacer",
        "group": "2c538605a7eee495",
        "name": "spacer",
        "tooltip": "",
        "order": 1,
        "width": 1,
        "height": 1,
        "className": ""
    },
    {
        "id": "f2bec2318b7febd7",
        "type": "ui-group",
        "name": "telegram",
        "page": "69c090379216efb6",
        "width": "6",
        "height": "1",
        "order": 6,
        "showTitle": false,
        "className": "",
        "visible": "true",
        "disabled": "false",
        "groupType": "dialog"
    },
    {
        "id": "46e77e42f3b6378f",
        "type": "mqtt-broker",
        "name": "Server",
        "broker": "192.168.1.105",
        "port": "1883",
        "clientid": "",
        "autoConnect": true,
        "usetls": false,
        "protocolVersion": "4",
        "keepalive": "60",
        "cleansession": true,
        "autoUnsubscribe": true,
        "birthTopic": "",
        "birthQos": "0",
        "birthRetain": "false",
        "birthPayload": "",
        "birthMsg": {},
        "closeTopic": "",
        "closeQos": "0",
        "closeRetain": "false",
        "closePayload": "",
        "closeMsg": {},
        "willTopic": "",
        "willQos": "0",
        "willRetain": "false",
        "willPayload": "",
        "willMsg": {},
        "userProps": "",
        "sessionExpiry": ""
    },
    {
        "id": "815e3f9da8379ab4",
        "type": "mqtt-broker",
        "name": "",
        "broker": "192.168.1.111",
        "port": "1883",
        "clientid": "",
        "autoConnect": true,
        "usetls": false,
        "protocolVersion": "3",
        "keepalive": "60",
        "cleansession": true,
        "autoUnsubscribe": true,
        "birthTopic": "",
        "birthQos": "0",
        "birthRetain": "false",
        "birthPayload": "",
        "birthMsg": {},
        "closeTopic": "",
        "closeQos": "0",
        "closeRetain": "false",
        "closePayload": "",
        "closeMsg": {},
        "willTopic": "",
        "willQos": "0",
        "willRetain": "false",
        "willPayload": "",
        "willMsg": {},
        "userProps": "",
        "sessionExpiry": ""
    },
    {
        "id": "671b0c9fe984dafc",
        "type": "influxdb",
        "hostname": "http://192.168.1.105",
        "port": "8086",
        "protocol": "http",
        "database": "",
        "name": "",
        "usetls": false,
        "tls": "",
        "influxdbVersion": "2.0",
        "url": "http://192.168.1.105:8086",
        "timeout": "10",
        "rejectUnauthorized": true
    },
    {
        "id": "5d7e54ca.019d44",
        "type": "influxdb",
        "hostname": "127.0.0.1",
        "port": "8086",
        "protocol": "http",
        "database": "database",
        "name": "",
        "usetls": false,
        "tls": "d50d0c9f.31e858",
        "influxdbVersion": "2.0",
        "url": "https://localhost:9999",
        "rejectUnauthorized": false
    },
    {
        "id": "d50d0c9f.31e858",
        "type": "tls-config",
        "name": "",
        "cert": "",
        "key": "",
        "ca": "",
        "certname": "",
        "keyname": "",
        "caname": "",
        "servername": "",
        "verifyservercert": false
    },
    {
        "id": "ff6cb27f865e69c1",
        "type": "influxdb",
        "hostname": "127.0.0.1",
        "port": "8086",
        "protocol": "http",
        "database": "database",
        "name": "Tag",
        "usetls": false,
        "tls": "",
        "influxdbVersion": "2.0",
        "url": "http://192.168.1.105:8086",
        "timeout": "10",
        "rejectUnauthorized": true
    },
    {
        "id": "69581d8e0efbf41e",
        "type": "function",
        "z": "4d3c8d61d6d0cf94",
        "name": "percentage",
        "func": "var energyA = flow.get(\"energyA\");\nvar energyB = flow.get(\"energyB\");\nvar energyC = flow.get(\"energyC\");\nvar current = flow.get(\"current_\");\n\n// var total_energy = Number(parseFloat(Number(energyA) + Number(energyB) + Number(energyC)).toFixed(1));\nvar total_current = Number(parseFloat(Number(current[0]) + Number(current[1]) + Number(current[2])).toFixed(1));\nif (total_current == 0) {\n    total_current = 1;\n}\nvar percentage_kwhA = parseFloat((Number(current[0]) / Number(total_current)) * 100).toFixed(1);\nvar percentage_kwhB = parseFloat((Number(current[1]) / Number(total_current)) * 100).toFixed(1);\nvar percentage_kwhC = parseFloat((Number(current[2]) / Number(total_current)) * 100).toFixed(1);\n\nflow.set(\"percentage_kwhA\", percentage_kwhA);\nflow.set(\"percentage_kwhB\", percentage_kwhB);\nflow.set(\"percentage_kwhC\", percentage_kwhC);\n\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 720,
        "y": 460,
        "wires": [
            []
        ]
    },
    {
        "id": "856181f39a4f4063",
        "type": "function",
        "z": "4d3c8d61d6d0cf94",
        "name": "total_energy",
        "func": "var input = msg.payload\nconst output = toUint32(input)\nmsg.payload = output[0]\nflow.set(\"true_energy\", output[0])\n\nfunction toUint32(data) {\n    const voltages = [];\n    for (let i = 0; i < data.length; i += 2) {\n        // รวมค่า 16 บิตจาก data[i] และ data[i + 1] ให้เป็น 32 บิต\n        const combined = (data[i] << 16) | data[i + 1];\n\n        // ตรวจสอบผลลัพธ์จากการรวมค่า\n        voltages.push(combined);\n    }\n    return voltages;\n}\nreturn msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 540,
        "y": 470,
        "wires": [
            [
                "69581d8e0efbf41e",
                "19e38ab6f3217c37"
            ]
        ]
    },
    {
        "id": "19e38ab6f3217c37",
        "type": "function",
        "z": "4d3c8d61d6d0cf94",
        "name": "Per Munits",
        "func": "var energy_input = Number(flow.get(\"true_energy\")) || 0\nvar energy_now = Number(flow.get(\"energy_now\")) || 0\nvar energy_after = Number(flow.get(\"energy_after\")) || 0\nvar onetime = flow.get(\"onetime\") || undefined\n\nif (!onetime) {\n    energy_after = energy_input\n    flow.set(\"onetime\", true)\n    flow.set(\"energy_after\", energy_after)\n} else {\n    var energy_minuts = energy_input - energy_after\n    energy_after = energy_input\n    flow.set(\"energy_after\", energy_after)\n    flow.set(\"energy_minuts\", energy_minuts)\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 730,
        "y": 500,
        "wires": [
            [
                "8dfc46ddc3bffa53"
            ]
        ]
    },
    {
        "id": "69f60d1bb300b8c4",
        "type": "function",
        "z": "4d3c8d61d6d0cf94",
        "name": "Current",
        "func": "var input = msg.payload\nconst output = toFloat32(input)\nmsg.payload = output\nflow.set(\"current_\",output);\n\nfunction toFloat32(data) {\n    const voltages = [];\n    for (let i = 0; i < data.length; i += 2) {\n        const combined = (data[i] << 16) | (data[i + 1]);\n        const float32Array = new Float32Array(1);\n        const int32Array = new Int32Array(float32Array.buffer);\n        int32Array[0] = combined;\n        voltages.push(float32Array[0].toFixed(2));\n    }\n    return voltages;\n}\nreturn msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 530,
        "y": 150,
        "wires": [
            []
        ]
    },
    {
        "id": "5e2987be9d2752a1",
        "type": "function",
        "z": "4d3c8d61d6d0cf94",
        "name": "Voltage",
        "func": "var input = msg.payload\nconst output = toFloat32(input)\nmsg.payload = output\nflow.set(\"volt_\", output);\n\nfunction toFloat32(data) {\n    const voltages = [];\n    for (let i = 0; i < data.length; i += 2) {\n        const combined = (data[i] << 16) | (data[i + 1]);\n        const float32Array1 = new Float32Array(1);\n        const int32Array = new Int32Array(float32Array1.buffer);\n        int32Array[0] = combined;\n        voltages.push(float32Array1[0].toFixed(2));\n    }\n    return voltages;\n}\nreturn msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 530,
        "y": 70,
        "wires": [
            []
        ]
    },
    {
        "id": "5b8ee46483fee273",
        "type": "function",
        "z": "4d3c8d61d6d0cf94",
        "name": "Power",
        "func": "var input = msg.payload\nconst output = toFloat32(input)\nmsg.payload = output\nflow.set(\"powerp_\", output);\n\nfunction toFloat32(data) {\n    const voltages = [];\n    for (let i = 0; i < data.length; i += 2) {\n        const combined = (data[i] << 16) | (data[i + 1]);\n        const float32Array2 = new Float32Array(1);\n        const int32Array = new Int32Array(float32Array2.buffer);\n        int32Array[0] = combined;\n        voltages.push(float32Array2[0].toFixed(2));\n    }\n    return voltages;\n}\nreturn msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 520,
        "y": 230,
        "wires": [
            []
        ]
    },
    {
        "id": "f43845eb84be9455",
        "type": "function",
        "z": "4d3c8d61d6d0cf94",
        "name": "Powerfactor",
        "func": "var input = msg.payload\nconst output = toFloat32(input)\nmsg.payload = output\nflow.set(\"powerf_\", output);\n\nfunction toFloat32(data) {\n    const voltages = [];\n    for (let i = 0; i < data.length; i += 2) {\n        const combined = (data[i] << 16) | (data[i + 1]);\n        const float32Array3 = new Float32Array(1);\n        const int32Array = new Int32Array(float32Array3.buffer);\n        int32Array[0] = combined;\n        voltages.push(float32Array3[0].toFixed(2));\n    }\n    return voltages;\n}\nreturn msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 540,
        "y": 310,
        "wires": [
            []
        ]
    },
    {
        "id": "349632205a889503",
        "type": "function",
        "z": "4d3c8d61d6d0cf94",
        "name": "Energy",
        "func": "var input = msg.payload;\nconst output = toUint32(input);\nmsg.payload = output;\nflow.set(\"total_energy\", output[0]);\n\nfunction toUint32(data) {\n    const voltages = [];\n    for (let i = 0; i < data.length; i += 2) {\n        // ผสมค่าจากสองไบต์ โดยไบต์แรกคือ MSB และไบต์ที่สองคือ LSB\n        const combined = (data[i] << 8) | data[i + 1];\n        voltages.push(combined); // ไม่ต้องแปลงเป็น Float\n    }\n    return voltages;\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 530,
        "y": 390,
        "wires": [
            []
        ]
    },
    {
        "id": "8dfc46ddc3bffa53",
        "type": "function",
        "z": "4d3c8d61d6d0cf94",
        "name": "SOV.",
        "func": "let volt = flow.get(\"volt_\");\nlet current = flow.get(\"current_\");\nlet powerp = flow.get(\"powerp_\");\nlet powerf = flow.get(\"powerf_\");\nlet energy = flow.get(\"true_energy\");\nlet energy_minuts = flow.get(\"energy_minuts\");\nlet percentage_kwhA = flow.get(\"percentage_kwhA\");\nlet percentage_kwhB = flow.get(\"percentage_kwhB\");\nlet percentage_kwhC = flow.get(\"percentage_kwhC\");\n\nmsg.payload = {\n    'voltage': volt,\n    'current': current,\n    'power': powerp,\n    'powerfactor': powerf,\n    'percentage_kwh':{\n        '1': percentage_kwhA,\n        '2': percentage_kwhB,\n        '3': percentage_kwhC,\n    },\n    'energy':{\n        'energy_total': energy,\n        'energy_round': energy_minuts,\n    }\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 880,
        "y": 500,
        "wires": [
            []
        ]
    },
    {
        "id": "bb440e053e24db36",
        "type": "function",
        "z": "4d3c8d61d6d0cf94",
        "name": "input",
        "func": "let unidID = msg.unitid;\n\nmsg.payload = {\n    value: '',\n    unitid: unidID,\n    fc: 3,\n    address: 1010,\n    quantity: 6\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 320,
        "y": 60,
        "wires": [
            [
                "12b9fde4ce41f0b9",
                "587b5c2cd8bfa983"
            ]
        ]
    },
    {
        "id": "120c9b929f5fc91e",
        "type": "function",
        "z": "4d3c8d61d6d0cf94",
        "name": "input",
        "func": "let unidID = msg.payload.unitid;\n\nmsg.payload = {\n    value: '',\n    unitid: unidID,\n    fc: 3,\n    address: 1000,\n    quantity: 6\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 320,
        "y": 140,
        "wires": [
            [
                "de4a905d8fc9ba72",
                "f57b2bf3364a8a9a"
            ]
        ]
    },
    {
        "id": "587b5c2cd8bfa983",
        "type": "delay",
        "z": "4d3c8d61d6d0cf94",
        "name": "",
        "pauseType": "delay",
        "timeout": "200",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "2",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": true,
        "allowrate": false,
        "outputs": 1,
        "x": 225,
        "y": 140,
        "wires": [
            [
                "120c9b929f5fc91e"
            ]
        ],
        "l": false
    },
    {
        "id": "bfe88bb9b747ab18",
        "type": "function",
        "z": "4d3c8d61d6d0cf94",
        "name": "input",
        "func": "let unidID = msg.payload.unitid;\n\nmsg.payload = {\n    value: '',\n    unitid: unidID,\n    fc: 3,\n    address: 1028,\n    quantity: 6\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 320,
        "y": 220,
        "wires": [
            [
                "3ee938beaf242b85",
                "b6af38ec7330194f"
            ]
        ]
    },
    {
        "id": "de4a905d8fc9ba72",
        "type": "delay",
        "z": "4d3c8d61d6d0cf94",
        "name": "",
        "pauseType": "delay",
        "timeout": "200",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "2",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": true,
        "allowrate": false,
        "outputs": 1,
        "x": 225,
        "y": 220,
        "wires": [
            [
                "bfe88bb9b747ab18"
            ]
        ],
        "l": false
    },
    {
        "id": "82c35c51784e26ab",
        "type": "function",
        "z": "4d3c8d61d6d0cf94",
        "name": "input",
        "func": "let unidID = msg.payload.unitid;\n\nmsg.payload = {\n    value: '',\n    unitid: unidID,\n    fc: 3,\n    address: 1052,\n    quantity: 6\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 320,
        "y": 300,
        "wires": [
            [
                "50b22372b1512c66",
                "18eb82e88e33e9c3"
            ]
        ]
    },
    {
        "id": "3ee938beaf242b85",
        "type": "delay",
        "z": "4d3c8d61d6d0cf94",
        "name": "",
        "pauseType": "delay",
        "timeout": "200",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "2",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": true,
        "allowrate": false,
        "outputs": 1,
        "x": 225,
        "y": 300,
        "wires": [
            [
                "82c35c51784e26ab"
            ]
        ],
        "l": false
    },
    {
        "id": "ad6dd41fabe683f8",
        "type": "function",
        "z": "4d3c8d61d6d0cf94",
        "name": "input",
        "func": "let unidID = msg.payload.unitid;\n\nmsg.payload = {\n    value: '',\n    unitid: unidID,\n    fc: 3,\n    address: 2606,\n    quantity: 2\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 320,
        "y": 380,
        "wires": [
            [
                "6a5fa282d7fbb922",
                "1582c9f166f499e6"
            ]
        ]
    },
    {
        "id": "50b22372b1512c66",
        "type": "delay",
        "z": "4d3c8d61d6d0cf94",
        "name": "",
        "pauseType": "delay",
        "timeout": "200",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "2",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": true,
        "allowrate": false,
        "outputs": 1,
        "x": 225,
        "y": 380,
        "wires": [
            [
                "ad6dd41fabe683f8"
            ]
        ],
        "l": false
    },
    {
        "id": "8439852f353546d9",
        "type": "function",
        "z": "4d3c8d61d6d0cf94",
        "name": "input",
        "func": "let unidID = msg.payload.unitid;\n\nmsg.payload = {\n    value: '',\n    unitid: unidID,\n    fc: 3,\n    address: 2606,\n    quantity: 2\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 320,
        "y": 460,
        "wires": [
            [
                "7d1bc6ee080770f1"
            ]
        ]
    },
    {
        "id": "6a5fa282d7fbb922",
        "type": "delay",
        "z": "4d3c8d61d6d0cf94",
        "name": "",
        "pauseType": "delay",
        "timeout": "200",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "2",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": true,
        "allowrate": false,
        "outputs": 1,
        "x": 225,
        "y": 460,
        "wires": [
            [
                "8439852f353546d9"
            ]
        ],
        "l": false
    },
    {
        "id": "b46fec26525f1d8b",
        "type": "modbus-response",
        "z": "4d3c8d61d6d0cf94",
        "name": "",
        "registerShowMax": "2",
        "x": 560,
        "y": 430,
        "wires": []
    },
    {
        "id": "4c128e6d7d8f9f39",
        "type": "modbus-response",
        "z": "4d3c8d61d6d0cf94",
        "name": "",
        "registerShowMax": "6",
        "x": 560,
        "y": 110,
        "wires": []
    },
    {
        "id": "c018b231fcd1c234",
        "type": "modbus-response",
        "z": "4d3c8d61d6d0cf94",
        "name": "",
        "registerShowMax": "6",
        "x": 560,
        "y": 30,
        "wires": []
    },
    {
        "id": "422cdf054bc91347",
        "type": "modbus-response",
        "z": "4d3c8d61d6d0cf94",
        "name": "",
        "registerShowMax": "6",
        "x": 560,
        "y": 190,
        "wires": []
    },
    {
        "id": "2823a1065cc80568",
        "type": "modbus-response",
        "z": "4d3c8d61d6d0cf94",
        "name": "",
        "registerShowMax": "6",
        "x": 560,
        "y": 270,
        "wires": []
    },
    {
        "id": "4793450567799737",
        "type": "modbus-response",
        "z": "4d3c8d61d6d0cf94",
        "name": "",
        "registerShowMax": "6",
        "x": 560,
        "y": 350,
        "wires": []
    },
    {
        "id": "f57b2bf3364a8a9a",
        "type": "modbus-flex-getter",
        "z": "4d3c8d61d6d0cf94",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 435,
        "y": 140,
        "wires": [
            [
                "4c128e6d7d8f9f39",
                "69f60d1bb300b8c4"
            ],
            []
        ],
        "l": false
    },
    {
        "id": "12b9fde4ce41f0b9",
        "type": "modbus-flex-getter",
        "z": "4d3c8d61d6d0cf94",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 435,
        "y": 60,
        "wires": [
            [
                "c018b231fcd1c234",
                "5e2987be9d2752a1"
            ],
            []
        ],
        "l": false
    },
    {
        "id": "b6af38ec7330194f",
        "type": "modbus-flex-getter",
        "z": "4d3c8d61d6d0cf94",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 435,
        "y": 220,
        "wires": [
            [
                "422cdf054bc91347",
                "5b8ee46483fee273"
            ],
            []
        ],
        "l": false
    },
    {
        "id": "18eb82e88e33e9c3",
        "type": "modbus-flex-getter",
        "z": "4d3c8d61d6d0cf94",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 435,
        "y": 300,
        "wires": [
            [
                "f43845eb84be9455",
                "2823a1065cc80568"
            ],
            []
        ],
        "l": false
    },
    {
        "id": "1582c9f166f499e6",
        "type": "modbus-flex-getter",
        "z": "4d3c8d61d6d0cf94",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 435,
        "y": 380,
        "wires": [
            [
                "4793450567799737",
                "349632205a889503"
            ],
            []
        ],
        "l": false
    },
    {
        "id": "7d1bc6ee080770f1",
        "type": "modbus-flex-getter",
        "z": "4d3c8d61d6d0cf94",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 435,
        "y": 460,
        "wires": [
            [
                "856181f39a4f4063",
                "b46fec26525f1d8b"
            ],
            []
        ],
        "l": false
    },
    {
        "id": "f6145de4c3efe695",
        "type": "switch",
        "z": "416e4ad47d77d15d",
        "name": "",
        "property": "modbus_read",
        "propertyType": "msg",
        "rules": [
            {
                "t": "false"
            },
            {
                "t": "true"
            }
        ],
        "checkall": "true",
        "repair": false,
        "outputs": 2,
        "x": 155,
        "y": 60,
        "wires": [
            [
                "08f653cf7e21be8b"
            ],
            [
                "fbd2b0cc45e00d05"
            ]
        ],
        "l": false
    },
    {
        "id": "99cb2ee399c79dde",
        "type": "modbus-flex-getter",
        "z": "416e4ad47d77d15d",
        "name": "Meter",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 290,
        "y": 80,
        "wires": [
            [
                "e585486e16899a86"
            ],
            []
        ]
    },
    {
        "id": "fbd2b0cc45e00d05",
        "type": "function",
        "z": "416e4ad47d77d15d",
        "name": "function 667",
        "func": "let meter = msg.payload.meter;\nlet unitid = msg.payload.unitid;\nlet fc = msg.payload.fc;\n\n    massage();\nmsg.payload = { \n    value: '',\n    'fc': fc,\n    'unitid': unitid,\n    'address': meter,\n    'quantity': 1\n    }; return msg\n\nfunction massage(){\n    msg.unitid = msg.payload.unitid;\n    msg.fc = msg.payload.fc;\n    msg.screw = msg.payload.screw;\n    msg.holding = msg.payload.holding;\n    msg.annealing = msg.payload.annealing;\n    msg.stretching = msg.payload.stretching;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 205,
        "y": 80,
        "wires": [
            [
                "99cb2ee399c79dde",
                "5ab1baf3818432c3"
            ]
        ],
        "l": false
    },
    {
        "id": "3fd9b144ed4f33dd",
        "type": "modbus-flex-getter",
        "z": "416e4ad47d77d15d",
        "name": "Screw",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 290,
        "y": 120,
        "wires": [
            [
                "7a0598ef5eca402f"
            ],
            []
        ]
    },
    {
        "id": "807734bd9b3ec595",
        "type": "function",
        "z": "416e4ad47d77d15d",
        "name": "function 668",
        "func": "let screw = msg.screw;\nlet unitid = msg.unitid;\nlet fc = msg.fc;\nmsg.payload = { \n    value: '',\n    'fc': fc,\n    'unitid': unitid,\n    'address': screw,\n    'quantity': 1\n    };\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 205,
        "y": 120,
        "wires": [
            [
                "3fd9b144ed4f33dd",
                "116a552a588003ea"
            ]
        ],
        "l": false
    },
    {
        "id": "917afd6e2d79a31f",
        "type": "modbus-flex-getter",
        "z": "416e4ad47d77d15d",
        "name": "Annealing",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 300,
        "y": 200,
        "wires": [
            [
                "9fffd56488d863c7"
            ],
            []
        ]
    },
    {
        "id": "690f6e4c773df5e9",
        "type": "function",
        "z": "416e4ad47d77d15d",
        "name": "function 669",
        "func": "let annealing = msg.annealing;\nlet unitid = msg.unitid;\nlet fc = msg.fc;\nmsg.payload = { \n    value: '',\n    'fc': fc,\n    'unitid': unitid,\n    'address': annealing,\n    'quantity': 1\n    };\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 205,
        "y": 200,
        "wires": [
            [
                "917afd6e2d79a31f"
            ]
        ],
        "l": false
    },
    {
        "id": "08f653cf7e21be8b",
        "type": "function",
        "z": "416e4ad47d77d15d",
        "name": "function 670",
        "func": "let values = msg.payload.values;\nlet address = msg.payload.reset;\nlet id = msg.payload.unitid;\nlet fc = msg.payload.fc;\nmsg.payload = { \n    value: values,\n    'fc': fc,\n    'unitid': id,\n    'address': address,\n    'quantity': 1\n    }; return msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 205,
        "y": 40,
        "wires": [
            [
                "e2094dfe6c8cb03e"
            ]
        ],
        "l": false
    },
    {
        "id": "e2094dfe6c8cb03e",
        "type": "modbus-flex-write",
        "z": "416e4ad47d77d15d",
        "name": "reset",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "server": "291667434678740d",
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 290,
        "y": 40,
        "wires": [
            [
                "db025decafc9b2e7"
            ],
            []
        ]
    },
    {
        "id": "d9d9fc8ac7855822",
        "type": "function",
        "z": "416e4ad47d77d15d",
        "name": "timestamp",
        "func": "flow.set(\"timestamp\",msg.timestamp);\nflow.set(\"time\", msg.time);\nflow.set(\"fc\", msg.payload.fc);\nflow.set(\"id\", msg.payload.unitid);\nflow.set(\"screw\", msg.payload.screw)",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 105,
        "y": 40,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "5ab1baf3818432c3",
        "type": "delay",
        "z": "416e4ad47d77d15d",
        "name": "",
        "pauseType": "delay",
        "timeout": "100",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 155,
        "y": 120,
        "wires": [
            [
                "807734bd9b3ec595"
            ]
        ],
        "l": false
    },
    {
        "id": "4895402da3a70671",
        "type": "delay",
        "z": "416e4ad47d77d15d",
        "name": "",
        "pauseType": "delay",
        "timeout": "100",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 155,
        "y": 200,
        "wires": [
            [
                "690f6e4c773df5e9",
                "02e4b9c29eb1e868"
            ]
        ],
        "l": false
    },
    {
        "id": "e585486e16899a86",
        "type": "function",
        "z": "416e4ad47d77d15d",
        "name": "f",
        "func": "flow.set(\"meter\", msg.payload[0]) || 0;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 430,
        "y": 60,
        "wires": [
            []
        ]
    },
    {
        "id": "7a0598ef5eca402f",
        "type": "function",
        "z": "416e4ad47d77d15d",
        "name": "f",
        "func": "flow.set(\"screw\", msg.payload[0]) || 0;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 430,
        "y": 100,
        "wires": [
            []
        ]
    },
    {
        "id": "9fffd56488d863c7",
        "type": "function",
        "z": "416e4ad47d77d15d",
        "name": "f",
        "func": "flow.set(\"annealing\", msg.payload[0]) || 0;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 430,
        "y": 180,
        "wires": [
            []
        ]
    },
    {
        "id": "9f51b4f10a6c9ac1",
        "type": "function",
        "z": "416e4ad47d77d15d",
        "name": "function 671",
        "func": "msg.payload = {\n    fill: \"green\",\n    shape: \"dot\",\n    text: `Meter: ${flow.get(\"meter\")} | reset:${flow.get(\"reset\") || \"00:00:00\"}`\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 205,
        "y": 300,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "db025decafc9b2e7",
        "type": "function",
        "z": "416e4ad47d77d15d",
        "name": "f",
        "func": "flow.set(\"reset\", flow.get(\"time\") || 0);",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 430,
        "y": 20,
        "wires": [
            []
        ]
    },
    {
        "id": "baa2f6675849c2c5",
        "type": "modbus-flex-getter",
        "z": "416e4ad47d77d15d",
        "name": "Holding",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 300,
        "y": 160,
        "wires": [
            [
                "95e05ffb0eb22cdf"
            ],
            []
        ]
    },
    {
        "id": "6e21a9eaf98b6a97",
        "type": "function",
        "z": "416e4ad47d77d15d",
        "name": "function 672",
        "func": "let holding = msg.holding;\nlet unitid = msg.unitid;\nlet fc = msg.fc;\nmsg.payload = { \n    value: '',\n    'fc': fc,\n    'unitid': unitid,\n    'address': holding,\n    'quantity': 1\n    };\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 205,
        "y": 160,
        "wires": [
            [
                "baa2f6675849c2c5",
                "4895402da3a70671"
            ]
        ],
        "l": false
    },
    {
        "id": "116a552a588003ea",
        "type": "delay",
        "z": "416e4ad47d77d15d",
        "name": "",
        "pauseType": "delay",
        "timeout": "100",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 155,
        "y": 160,
        "wires": [
            [
                "6e21a9eaf98b6a97"
            ]
        ],
        "l": false
    },
    {
        "id": "95e05ffb0eb22cdf",
        "type": "function",
        "z": "416e4ad47d77d15d",
        "name": "f",
        "func": "flow.set(\"holding\", msg.payload[0]) || 0;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 430,
        "y": 140,
        "wires": [
            []
        ]
    },
    {
        "id": "4cc3e4dfb12007dd",
        "type": "modbus-flex-getter",
        "z": "416e4ad47d77d15d",
        "name": "Stretching",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 300,
        "y": 240,
        "wires": [
            [
                "98603c9a32e88343"
            ],
            []
        ]
    },
    {
        "id": "20edfc5dc616087d",
        "type": "function",
        "z": "416e4ad47d77d15d",
        "name": "function 673",
        "func": "let stretching = msg.stretching;\nlet unitid = msg.unitid;\nlet fc = msg.fc;\nmsg.payload = { \n    value: '',\n    'fc': fc,\n    'unitid': unitid,\n    'address': stretching,\n    'quantity': 2\n    };\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 205,
        "y": 240,
        "wires": [
            [
                "4cc3e4dfb12007dd"
            ]
        ],
        "l": false
    },
    {
        "id": "98603c9a32e88343",
        "type": "function",
        "z": "416e4ad47d77d15d",
        "name": "f",
        "func": "flow.set(\"stretching\", msg.payload[0]) || 0;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 430,
        "y": 220,
        "wires": [
            []
        ]
    },
    {
        "id": "02e4b9c29eb1e868",
        "type": "delay",
        "z": "416e4ad47d77d15d",
        "name": "",
        "pauseType": "delay",
        "timeout": "100",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 155,
        "y": 240,
        "wires": [
            [
                "20edfc5dc616087d",
                "9f4c330c6c078259"
            ]
        ],
        "l": false
    },
    {
        "id": "8ead4a4afb84bc30",
        "type": "function",
        "z": "416e4ad47d77d15d",
        "name": "f",
        "func": "msg.payload = {\n    'timestamp': flow.get(\"timestamp\"),\n    'meter': flow.get(\"meter\"),\n    'screw': flow.get(\"screw\"),\n    'holding': flow.get(\"holding\"),\n    'annealing': flow.get(\"annealing\"),\n    'stretching': flow.get(\"stretching\")\n};return msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 290,
        "y": 280,
        "wires": [
            []
        ]
    },
    {
        "id": "9f4c330c6c078259",
        "type": "delay",
        "z": "416e4ad47d77d15d",
        "name": "",
        "pauseType": "delay",
        "timeout": "200",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 155,
        "y": 280,
        "wires": [
            [
                "8ead4a4afb84bc30",
                "9f51b4f10a6c9ac1"
            ]
        ],
        "l": false
    },
    {
        "id": "a551913c95f77777",
        "type": "modbus-getter",
        "z": "4f29820d32ebeb14",
        "g": "358de3fc3d0c3af8",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "unitid": "1",
        "dataType": "InputRegister",
        "adr": "0",
        "quantity": "10",
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 260,
        "y": 120,
        "wires": [
            [
                "c8a96d6f637749b0",
                "ca4b8ee67492864b"
            ],
            []
        ]
    },
    {
        "id": "c8a96d6f637749b0",
        "type": "modbus-response",
        "z": "4f29820d32ebeb14",
        "g": "358de3fc3d0c3af8",
        "name": "",
        "registerShowMax": 20,
        "x": 450,
        "y": 100,
        "wires": []
    },
    {
        "id": "5a5076a80b987df8",
        "type": "modbus-getter",
        "z": "4f29820d32ebeb14",
        "g": "358de3fc3d0c3af8",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "unitid": "2",
        "dataType": "InputRegister",
        "adr": "0",
        "quantity": "10",
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 260,
        "y": 200,
        "wires": [
            [
                "83cae54a6e393b85",
                "338f82eeac2df0c4"
            ],
            []
        ]
    },
    {
        "id": "83cae54a6e393b85",
        "type": "modbus-response",
        "z": "4f29820d32ebeb14",
        "g": "358de3fc3d0c3af8",
        "name": "",
        "registerShowMax": 20,
        "x": 450,
        "y": 180,
        "wires": []
    },
    {
        "id": "d766edb56f4cf828",
        "type": "modbus-getter",
        "z": "4f29820d32ebeb14",
        "g": "358de3fc3d0c3af8",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "unitid": "3",
        "dataType": "InputRegister",
        "adr": "0",
        "quantity": "10",
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 260,
        "y": 280,
        "wires": [
            [
                "7a1caac4460ad806",
                "eb0c8cda22c456e6"
            ],
            []
        ]
    },
    {
        "id": "7a1caac4460ad806",
        "type": "modbus-response",
        "z": "4f29820d32ebeb14",
        "g": "358de3fc3d0c3af8",
        "name": "",
        "registerShowMax": 20,
        "x": 450,
        "y": 260,
        "wires": []
    },
    {
        "id": "ca4b8ee67492864b",
        "type": "function",
        "z": "4f29820d32ebeb14",
        "g": "358de3fc3d0c3af8",
        "name": "function 659",
        "func": "var current_rate = flow.get(\"current_rate\");\nvar voltageA = msg.payload[0]/10;\nflow.set(\"voltageA\", voltageA);\n//////////////////////////////////////////////////////////\nvar input11 = parseInt(msg.payload[2], 10).toString(16);\nvar input12 = parseInt(msg.payload[1], 10).toString(16);\nvar len1 = input12.length;\nif(len1 == 1){\n    input12 = \"000\"+input12;\n}else if(len1 == 2){\n    input12 = \"00\"+input12;\n}else if(len1 == 3){\n    input12 = \"0\"+input12;\n}else if(len1 == 0){\n    input12 = \"0000\";\n}\nvar input13 = String(input11)+String(input12);\nvar output1 = Number(parseInt(input13,16).toString(10));\noutput1 = output1 * current_rate;\noutput1 = parseFloat(Number(output1)/1000).toFixed(2);\nflow.set(\"currentA\",output1);\n////////////////////////////////////////////////////////////\nvar input21 = parseInt(msg.payload[4], 10).toString(16);\nvar input22 = parseInt(msg.payload[3], 10).toString(16);\nvar len2 = input22.length;\nif (len2 == 1) {\n    input22 = \"000\" + input22;\n} else if (len2 == 2) {\n    input22 = \"00\" + input22;\n} else if (len2 == 3) {\n    input22 = \"0\" + input22;\n} else if (len2 == 0) {\n    input22 = \"0000\";\n}\nvar input23 = String(input21) + String(input22);\nvar output2 = Number(parseInt(input23, 16).toString(10));\noutput2 = output2 * current_rate;\noutput2 = parseFloat(Number(output2) / 1000).toFixed(2);\nflow.set(\"powerA\", output2);\n////////////////////////////////////////////////////////////\nvar input31 = parseInt(msg.payload[6], 10).toString(16);\nvar input32 = parseInt(msg.payload[5], 10).toString(16);\nvar len3 = input32.length;\nif (len3 == 1) {\n    input32 = \"000\" + input32;\n} else if (len3 == 2) {\n    input32 = \"00\" + input32;\n} else if (len3 == 3) {\n    input32 = \"0\" + input32;\n} else if (len3 == 0) {\n    input32 = \"0000\";\n}\nvar input33 = String(input31) + String(input32);\nvar output3 = Number(parseInt(input33, 16).toString(10));\noutput3 = output3 * current_rate;\noutput3 = parseFloat(Number(output3) / 1000).toFixed(2);\nflow.set(\"energyA\", output3);\n////////////////////////////////////////////////////////////\nvar power_factorA = msg.payload[8]/100;\nflow.set(\"powerfactorA\", power_factorA);\nflow.set(\"board01\", \"Ok\");\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 430,
        "y": 140,
        "wires": [
            [
                "6a8cec485f693b21"
            ]
        ]
    },
    {
        "id": "338f82eeac2df0c4",
        "type": "function",
        "z": "4f29820d32ebeb14",
        "g": "358de3fc3d0c3af8",
        "name": "function 660",
        "func": "var current_rate = flow.get(\"current_rate\");\nvar voltageB = msg.payload[0]/10;\nflow.set(\"voltageB\", voltageB);\n//////////////////////////////////////////////////////////\nvar input11 = parseInt(msg.payload[2], 10).toString(16);\nvar input12 = parseInt(msg.payload[1], 10).toString(16);\nvar len1 = input12.length;\nif(len1 == 1){\n    input12 = \"000\"+input12;\n}else if(len1 == 2){\n    input12 = \"00\"+input12;\n}else if(len1 == 3){\n    input12 = \"0\"+input12;\n}else if(len1 == 0){\n    input12 = \"0000\";\n}\nvar input13 = String(input11)+String(input12);\nvar output1 = Number(parseInt(input13,16).toString(10));\noutput1 = output1 * current_rate;\noutput1 = parseFloat(Number(output1)/1000).toFixed(2);\nflow.set(\"currentB\",output1);\n////////////////////////////////////////////////////////////\nvar input21 = parseInt(msg.payload[4], 10).toString(16);\nvar input22 = parseInt(msg.payload[3], 10).toString(16);\nvar len2 = input22.length;\nif (len2 == 1) {\n    input22 = \"000\" + input22;\n} else if (len2 == 2) {\n    input22 = \"00\" + input22;\n} else if (len2 == 3) {\n    input22 = \"0\" + input22;\n} else if (len2 == 0) {\n    input22 = \"0000\";\n}\nvar input23 = String(input21) + String(input22);\nvar output2 = Number(parseInt(input23, 16).toString(10));\noutput2 = output2 * current_rate;\noutput2 = parseFloat(Number(output2) / 1000).toFixed(2);\nflow.set(\"powerB\", output2);\n////////////////////////////////////////////////////////////\nvar input31 = parseInt(msg.payload[6], 10).toString(16);\nvar input32 = parseInt(msg.payload[5], 10).toString(16);\nvar len3 = input32.length;\nif (len3 == 1) {\n    input32 = \"000\" + input32;\n} else if (len3 == 2) {\n    input32 = \"00\" + input32;\n} else if (len3 == 3) {\n    input32 = \"0\" + input32;\n} else if (len3 == 0) {\n    input32 = \"0000\";\n}\nvar input33 = String(input31) + String(input32);\nvar output3 = Number(parseInt(input33, 16).toString(10));\noutput3 = output3 * current_rate;\noutput3 = parseFloat(Number(output3) / 1000).toFixed(2);\nflow.set(\"energyB\", output3);\n////////////////////////////////////////////////////////////\nvar power_factorB = msg.payload[8]/100;\nflow.set(\"powerfactorB\", power_factorB);\nflow.set(\"board02\", \"Ok\");\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 430,
        "y": 220,
        "wires": [
            [
                "c9b6f5fd1b7111d8"
            ]
        ]
    },
    {
        "id": "eb0c8cda22c456e6",
        "type": "function",
        "z": "4f29820d32ebeb14",
        "g": "358de3fc3d0c3af8",
        "name": "function 661",
        "func": "var current_rate = flow.get(\"current_rate\");\nvar voltageC = msg.payload[0]/10;\nflow.set(\"voltageC\", voltageC);\n//////////////////////////////////////////////////////////\nvar input11 = parseInt(msg.payload[2], 10).toString(16);\nvar input12 = parseInt(msg.payload[1], 10).toString(16);\nvar len1 = input12.length;\nif(len1 == 1){\n    input12 = \"000\"+input12;\n}else if(len1 == 2){\n    input12 = \"00\"+input12;\n}else if(len1 == 3){\n    input12 = \"0\"+input12;\n}else if(len1 == 0){\n    input12 = \"0000\";\n}\nvar input13 = String(input11)+String(input12);\nvar output1 = Number(parseInt(input13,16).toString(10));\noutput1 = output1 * current_rate;\noutput1 = parseFloat(Number(output1)/1000).toFixed(2);\nflow.set(\"currentC\",output1);\n////////////////////////////////////////////////////////////\nvar input21 = parseInt(msg.payload[4], 10).toString(16);\nvar input22 = parseInt(msg.payload[3], 10).toString(16);\nvar len2 = input22.length;\nif (len2 == 1) {\n    input22 = \"000\" + input22;\n} else if (len2 == 2) {\n    input22 = \"00\" + input22;\n} else if (len2 == 3) {\n    input22 = \"0\" + input22;\n} else if (len2 == 0) {\n    input22 = \"0000\";\n}\nvar input23 = String(input21) + String(input22);\nvar output2 = Number(parseInt(input23, 16).toString(10));\noutput2 = output2 * current_rate;\noutput2 = parseFloat(Number(output2) / 1000).toFixed(2);\nflow.set(\"powerC\", output2);\n////////////////////////////////////////////////////////////\nvar input31 = parseInt(msg.payload[6], 10).toString(16);\nvar input32 = parseInt(msg.payload[5], 10).toString(16);\nvar len3 = input32.length;\nif (len3 == 1) {\n    input32 = \"000\" + input32;\n} else if (len3 == 2) {\n    input32 = \"00\" + input32;\n} else if (len3 == 3) {\n    input32 = \"0\" + input32;\n} else if (len3 == 0) {\n    input32 = \"0000\";\n}\nvar input33 = String(input31) + String(input32);\nvar output3 = Number(parseInt(input33, 16).toString(10));\noutput3 = output3 * current_rate;\noutput3 = parseFloat(Number(output3) / 1000).toFixed(2);\nflow.set(\"energyC\", output3);\n////////////////////////////////////////////////////////////\nvar power_factorC = msg.payload[8]/100;\nflow.set(\"powerfactorC\", power_factorC);\nflow.set(\"board03\", \"Ok\");\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 430,
        "y": 300,
        "wires": [
            []
        ]
    },
    {
        "id": "7a6609194f821a65",
        "type": "function",
        "z": "4f29820d32ebeb14",
        "g": "358de3fc3d0c3af8",
        "name": "timestamp",
        "func": "flow.set(\"timestamp\", msg.payload);\nflow.set(\"current_rate\", msg.current_rate);",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 250,
        "y": 80,
        "wires": [
            []
        ]
    },
    {
        "id": "ce1481109e94455c",
        "type": "function",
        "z": "4f29820d32ebeb14",
        "g": "358de3fc3d0c3af8",
        "name": "function 662",
        "func": "var voltA = flow.get(\"voltageA\");\nvar voltB = flow.get(\"voltageB\");\nvar voltC = flow.get(\"voltageC\");\n\nvar currentA = flow.get(\"currentA\");\nvar currentB = flow.get(\"currentB\");\nvar currentC = flow.get(\"currentC\");\n\nvar powerA = flow.get(\"powerA\");\nvar powerB = flow.get(\"powerB\");\nvar powerC = flow.get(\"powerC\");\n\nvar energyA = flow.get(\"energyA\");\nvar energyB = flow.get(\"energyB\");\nvar energyC = flow.get(\"energyC\");\n\nvar powerfactorA = flow.get(\"powerfactorA\");\nvar powerfactorB = flow.get(\"powerfactorB\");\nvar powerfactorC = flow.get(\"powerfactorC\");\n\nvar timestamp_res =  flow.get(\"timestamp\");\nvar percentage_powerA,percentage_powerB,percentage_powerC;\nvar percentage_kwhA, percentage_kwhB, percentage_kwhC;\n\nvar total_power = Number(parseFloat(Number(powerA) + Number(powerB) + Number(powerC)).toFixed(2));\nif(powerA && powerB && powerC){\n     percentage_powerA = parseFloat((Number(powerA) / Number(total_power)) * 100).toFixed(1);\n     percentage_powerB = parseFloat((Number(powerB) / Number(total_power)) * 100).toFixed(1);\n     percentage_powerC = parseFloat((Number(powerC) / Number(total_power)) * 100).toFixed(1);\n}else{\n     percentage_powerA = 0;\n     percentage_powerB = 0;\n     percentage_powerC = 0;\n}\n\nvar total_current = Number(parseFloat(Number(currentA) + Number(currentB) + Number(currentC)).toFixed(2));\nif(currentA && currentB && currentC){\n     percentage_kwhA = parseFloat((Number(currentA) / Number(total_current)) * 100).toFixed(1);\n     percentage_kwhB = parseFloat((Number(currentB) / Number(total_current)) * 100).toFixed(1);\n     percentage_kwhC = parseFloat((Number(currentC) / Number(total_current)) * 100).toFixed(1);\n}else{\n    percentage_kwhA = 0;\n    percentage_kwhB = 0;\n    percentage_kwhC = 0;\n}\n\nvar total_energy = Number(parseFloat(Number(energyA) + Number(energyB) + Number(energyC)).toFixed(2));\nvar timestamp = flow.get(\"timestamp\")\n\nmsg.payload = {\n    'ts': timestamp,\n    'tsres': timestamp_res,\n    'volt':{\n        'A': voltA, \n        'B': voltB, \n        'C': voltC\n    },\n    'current':{\n         'A': currentA, \n         'B': currentB, \n         'C': currentC\n    },\n    'power':{\n         'A': powerA, \n         'B': powerB, \n         'C': powerC\n    },\n    'energy':{\n        'A': energyA, \n        'B': energyB, \n        'C': energyC\n    },\n    'powerfactor':{\n        'A': powerfactorA, \n        'B': powerfactorB, \n        'C': powerfactorC\n    },\n    'percentage':{\n        'power':{\n            'A': percentage_powerA,\n            'B': percentage_powerB,\n            'C': percentage_powerC\n        },\n        'current': {\n            'A': percentage_kwhA,\n            'B': percentage_kwhB,\n            'C': percentage_kwhC\n        }\n    },\n    'total':{\n        'energy': total_energy,\n        'power': total_power,\n        'current': total_current,\n    }\n}\nreturn msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 430,
        "y": 400,
        "wires": [
            []
        ]
    },
    {
        "id": "c9b6f5fd1b7111d8",
        "type": "delay",
        "z": "4f29820d32ebeb14",
        "g": "358de3fc3d0c3af8",
        "name": "",
        "pauseType": "delay",
        "timeout": "100",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 145,
        "y": 260,
        "wires": [
            [
                "d766edb56f4cf828"
            ]
        ],
        "l": false
    },
    {
        "id": "6a8cec485f693b21",
        "type": "delay",
        "z": "4f29820d32ebeb14",
        "g": "358de3fc3d0c3af8",
        "name": "",
        "pauseType": "delay",
        "timeout": "100",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 145,
        "y": 180,
        "wires": [
            [
                "5a5076a80b987df8"
            ]
        ],
        "l": false
    },
    {
        "id": "585b0e5df295256e",
        "type": "delay",
        "z": "4f29820d32ebeb14",
        "g": "358de3fc3d0c3af8",
        "name": "",
        "pauseType": "delay",
        "timeout": "600",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 145,
        "y": 360,
        "wires": [
            [
                "ab10bbf8004addb5"
            ]
        ],
        "l": false
    },
    {
        "id": "ab10bbf8004addb5",
        "type": "function",
        "z": "4f29820d32ebeb14",
        "g": "358de3fc3d0c3af8",
        "name": "state",
        "func": "\nmsg.payload = {\n    fill: `green`,\n    shape: `dot`,\n    text: `Board1:${flow.get(\"board01\") || \"fail\"} Board2:${flow.get(\"board02\") || \"fail\"} Board3:${flow.get(\"board03\") || \"fail\"}`\n};\nif(flow.get(\"board01\") && flow.get(\"board02\") && flow.get(\"board03\") ){\n        global.set(\"rtu.state\", true);\n}else{\n        global.set(\"rtu.state\", false);\n}\nflow.set(\"board01\", undefined);\nflow.set(\"board02\", undefined);\nflow.set(\"board03\", undefined);\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 230,
        "y": 360,
        "wires": [
            [
                "ce1481109e94455c"
            ]
        ]
    },
    {
        "id": "854eb4f62546adcb",
        "type": "switch",
        "z": "84087161fd829d92",
        "g": "06e517f2e69268b9",
        "name": "",
        "property": "localpro",
        "propertyType": "msg",
        "rules": [
            {
                "t": "eq",
                "v": "0",
                "vt": "str"
            },
            {
                "t": "eq",
                "v": "1",
                "vt": "str"
            }
        ],
        "checkall": "true",
        "repair": false,
        "outputs": 2,
        "x": 215,
        "y": 100,
        "wires": [
            [
                "bb66bd0fb5225235"
            ],
            [
                "6fee32cfab3c9cae"
            ]
        ],
        "l": false
    },
    {
        "id": "bb66bd0fb5225235",
        "type": "function",
        "z": "84087161fd829d92",
        "g": "06e517f2e69268b9",
        "name": "data Log",
        "func": "let timestamp = msg.filesystem.timestamp;\nlet date = msg.filesystem.date;\nlet ip = msg.filesystem.ip;\nlet date_data = msg.filesystem.date_data;\nlet time = msg.filesystem.time;\nlet shift = msg.filesystem.shift;\n\nconst temp = msg.production.temp;\nlet mt_in_now = temp.motor_in.now;\nlet mt_in_min = temp.motor_in.min;\nlet mt_in_max = temp.motor_in.max;\nlet mt_out_now = temp.motor_out.now;\nlet mt_out_min = temp.motor_out.min;\nlet mt_out_max = temp.motor_out.max;\nlet cl_in_now = temp.cooling_in.now;\nlet cl_in_min = temp.cooling_in.min;\nlet cl_in_max = temp.cooling_in.max;\nlet cl_out_now = temp.cooling_out.now;\nlet cl_out_min = temp.cooling_out.min;\nlet cl_out_max = temp.cooling_out.max;\n\nconst speed = msg.production.speed;\nlet scr_now = speed.screw.now;\nlet scr_min = speed.screw.min;\nlet scr_max = speed.screw.max;\nlet hol_now = speed.holding.now;\nlet hol_min = speed.holding.min;\nlet hol_max = speed.holding.max;\nlet ann_now = speed.annealing.now;\nlet ann_min = speed.annealing.min;\nlet ann_max = speed.annealing.max;\nlet str_now = speed.stretching.now;\nlet str_min = speed.stretching.min;\nlet str_max = speed.stretching.max;\n\nconst production = msg.production;\nlet meter = production.meter.meter;\nlet meter_A = production.meter.total.meter_A;\nlet meter_B = production.meter.total.meter_B;\nlet total_meter = production.meter.total.meter;\nlet meter_min = production.meter.total.meter_min;\n\nmsg.payload = {\n    timestamp: timestamp,\n    date: date,\n    time: time,\n    ip: ip,\n    shift: shift,\n    date_data: date_data,\n    mt_in_now: mt_in_now,\n    mt_in_min: mt_in_min,\n    mt_in_max: mt_in_max,\n    mt_out_now: mt_out_now,\n    mt_out_min: mt_out_min,\n    mt_out_max: mt_out_max,\n    cl_in_now: cl_in_now,\n    cl_in_min: cl_in_min,\n    cl_in_max: cl_in_max,\n    cl_out_now: cl_out_now,\n    cl_out_min: cl_out_min,\n    cl_out_max: cl_out_max,\n    scr_now: scr_now,\n    scr_min: scr_min,\n    scr_max: scr_max,\n    hol_now: hol_now,\n    hol_min: hol_min,\n    hol_max: hol_max,\n    ann_now: ann_now,\n    ann_min: ann_min,\n    ann_max: ann_max,\n    str_now: str_now,\n    str_min: str_min,\n    str_max: str_max,\n    meter0: meter[0], meter1: meter[1], \n    meter2: meter[2], meter3: meter[3], \n    meter4: meter[4], meter5: meter[5], \n    meter6: meter[6], meter7: meter[7], \n    meter8: meter[8], meter9: meter[9], \n    meter10: meter[10], meter11: meter[11], \n    meter12: meter[12], meter13: meter[13],\n    meter14: meter[14], meter15: meter[15], \n    meter16: meter[16], meter17: meter[17], \n    meter18: meter[18], meter19: meter[19], \n    meter20: meter[20], meter21: meter[21], \n    meter22: meter[22], meter23: meter[23],\n    meter_A:meter_A, meter_B: meter_B,\n    total_meter: total_meter, \n    meter_min: meter_min\n}\nnode.status({ fill: \"blue\", shape: \"dot\", text: global.get(\"time\") });\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 310,
        "y": 80,
        "wires": [
            [
                "96c87dc3db41c897"
            ]
        ]
    },
    {
        "id": "6fee32cfab3c9cae",
        "type": "function",
        "z": "84087161fd829d92",
        "g": "06e517f2e69268b9",
        "name": "data Log",
        "func": "let timestamp = msg.filesystem.timestamp;\nlet date = msg.filesystem.date;\nlet ip = msg.filesystem.ip;\nlet date_data = msg.filesystem.date_data;\nlet time = msg.filesystem.time;\nlet shift = msg.filesystem.shift;\n\nconst temp = msg.production.temp;\nlet mt_in_now = temp.motor_in.now;\nlet mt_in_min = temp.motor_in.min;\nlet mt_in_max = temp.motor_in.max;\nlet mt_out_now = temp.motor_out.now;\nlet mt_out_min = temp.motor_out.min;\nlet mt_out_max = temp.motor_out.max;\nlet cl_in_now = temp.cooling_in.now;\nlet cl_in_min = temp.cooling_in.min;\nlet cl_in_max = temp.cooling_in.max;\nlet cl_out_now = temp.cooling_out.now;\nlet cl_out_min = temp.cooling_out.min;\nlet cl_out_max = temp.cooling_out.max;\n\nconst speed = msg.production.speed;\nlet scr_now = speed.screw.now;\nlet scr_min = speed.screw.min;\nlet scr_max = speed.screw.max;\nlet hol_now = speed.holding.now;\nlet hol_min = speed.holding.min;\nlet hol_max = speed.holding.max;\nlet ann_now = speed.annealing.now;\nlet ann_min = speed.annealing.min;\nlet ann_max = speed.annealing.max;\nlet str_now = speed.stretching.now;\nlet str_min = speed.stretching.min;\nlet str_max = speed.stretching.max;\n\nconst production = msg.production;\nlet meter = production.meter.meter;\nlet meter_A = production.meter.total.meter_A;\nlet meter_B = production.meter.total.meter_B;\nlet total_meter = production.meter.total.meter;\nlet meter_min = production.meter.total.meter_min;\n\nmsg.payload = {\n    timestamp: timestamp,\n    date: date,\n    time: time,\n    ip: ip,\n    shift: shift,\n    date_data: date_data,\n    mt_in_now: mt_in_now,\n    mt_in_min: mt_in_min,\n    mt_in_max: mt_in_max,\n    mt_out_now: mt_out_now,\n    mt_out_min: mt_out_min,\n    mt_out_max: mt_out_max,\n    cl_in_now: cl_in_now,\n    cl_in_min: cl_in_min,\n    cl_in_max: cl_in_max,\n    cl_out_now: cl_out_now,\n    cl_out_min: cl_out_min,\n    cl_out_max: cl_out_max,\n    scr_now: scr_now,\n    scr_min: scr_min,\n    scr_max: scr_max,\n    hol_now: hol_now,\n    hol_min: hol_min,\n    hol_max: hol_max,\n    ann_now: ann_now,\n    ann_min: ann_min,\n    ann_max: ann_max,\n    str_now: str_now,\n    str_min: str_min,\n    str_max: str_max,\n    meter0: meter[0], meter1: meter[1], \n    meter2: meter[2], meter3: meter[3], \n    meter4: meter[4], meter5: meter[5], \n    meter6: meter[6], meter7: meter[7], \n    meter8: meter[8], meter9: meter[9], \n    meter10: meter[10], meter11: meter[11], \n    meter12: meter[12], meter13: meter[13],\n    meter14: meter[14], meter15: meter[15], \n    meter16: meter[16], meter17: meter[17], \n    meter18: meter[18], meter19: meter[19], \n    meter20: meter[20], meter21: meter[21], \n    meter22: meter[22], meter23: meter[23],\n    meter_A:meter_A, meter_B: meter_B,\n    total_meter: total_meter, \n    meter_min: meter_min\n}\nnode.status({ fill: \"blue\", shape: \"dot\", text: global.get(\"time\") });\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 310,
        "y": 120,
        "wires": [
            [
                "888f91628a6972ce"
            ]
        ]
    },
    {
        "id": "96c87dc3db41c897",
        "type": "csv",
        "z": "84087161fd829d92",
        "g": "06e517f2e69268b9",
        "name": "",
        "sep": ",",
        "hdrin": false,
        "hdrout": "all",
        "multi": "one",
        "ret": "\\r\\n",
        "temp": " timestamp,date,time,ip,shift,date_data,mt_in_now,mt_in_min,mt_in_max,mt_out_now,mt_out_min,mt_out_max,cl_in_now,cl_in_min,cl_in_max,cl_out_now,cl_out_min,cl_out_max,scr_now,scr_min,scr_max,hol_now,hol_min,hol_max,ann_now,ann_min,ann_max,str_now,str_min,str_max,meter0, meter1,meter2,meter3,meter4,meter5,meter6,meter7,meter8,meter9,meter10,meter11,meter12,meter13,meter14,meter15, meter16,meter17,meter18,meter19,meter20, meter21,meter22,meter23,meter_A,meter_B,total_meter,meter_min",
        "skip": "0",
        "strings": true,
        "include_empty_strings": "",
        "include_null_values": "",
        "x": 405,
        "y": 80,
        "wires": [
            [
                "21232d92a0568ba1"
            ]
        ],
        "l": false
    },
    {
        "id": "888f91628a6972ce",
        "type": "csv",
        "z": "84087161fd829d92",
        "g": "06e517f2e69268b9",
        "name": "",
        "sep": ",",
        "hdrin": "",
        "hdrout": "none",
        "multi": "one",
        "ret": "\\r\\n",
        "temp": "",
        "skip": "0",
        "strings": true,
        "include_empty_strings": "",
        "include_null_values": "",
        "x": 405,
        "y": 120,
        "wires": [
            [
                "21232d92a0568ba1"
            ]
        ],
        "l": false
    },
    {
        "id": "ec681e6e8b6dc504",
        "type": "switch",
        "z": "84087161fd829d92",
        "g": "e58558cb75de9af5",
        "name": "",
        "property": "localpow",
        "propertyType": "msg",
        "rules": [
            {
                "t": "eq",
                "v": "0",
                "vt": "str"
            },
            {
                "t": "eq",
                "v": "1",
                "vt": "str"
            }
        ],
        "checkall": "true",
        "repair": false,
        "outputs": 2,
        "x": 215,
        "y": 260,
        "wires": [
            [
                "91bbc3864133b185"
            ],
            [
                "2e08ad99f972e679"
            ]
        ],
        "l": false
    },
    {
        "id": "91bbc3864133b185",
        "type": "function",
        "z": "84087161fd829d92",
        "g": "e58558cb75de9af5",
        "name": "data Log",
        "func": "let energy = msg.power.energy;\nlet voltage = msg.power.voltage;\nlet current = msg.power.current;\nlet powerfactor = msg.power.powerfactor;\nlet power = msg.power.power;\nlet power_percentage = msg.power.percentagekwh;\nlet current_percentage =  msg.power.percentageAmp;\n\nlet energy_A = msg.power.total.energy_A;\nlet energy_B = msg.power.total.energy_B;\nlet total_energy = msg.power.total.energy;\nlet co2 = msg.power.total.co2;\n\nlet timestamp = msg.filesystem.timestamp;\nvar date = msg.filesystem.date;\nvar time = msg.filesystem.time;\nvar date_data = msg.filesystem.date_data;\nvar ip = msg.filesystem.ip;\nvar shift = msg.filesystem.shift;\n\nmsg.payload = {\n    date: date, time: time, ip: ip, timestamp: timestamp, date_data: date_data, shift: shift,\n    voltA: voltage.A, voltB: voltage.B, voltC: voltage.C,\n    currentA: current.A, currentB: current.B, currentC: current.C,\n    powerA: power.A, powerB: power.B, powerC: power.C,\n    powerfA: powerfactor.A, powerfB: powerfactor.B, powerfC: powerfactor.C,\n    powerpA: power_percentage.A, powerpB: power_percentage.B, powerpC: power_percentage.C,\n    currentpA: current_percentage.A, currentpB: current_percentage.B, currentpC: current_percentage.C,\n    energy0: energy[0], energy1: energy[1], energy2: energy[2], energy3: energy[3], energy4: energy[4], energy5: energy[5], energy6: energy[6],\n    energy7: energy[7], energy8: energy[8], energy9: energy[9], energy10: energy[10], energy11: energy[11], energy12: energy[12], energy13: energy[13],\n    energy14: energy[14], energy15: energy[15], energy16: energy[16], energy17: energy[17], energy18: energy[18], energy19: energy[19], energy20: energy[20],\n    energy21: energy[21], energy22: energy[22], energy23: energy[23],\n    total_energy: total_energy, co2: co2, energy_A: energy_A, energy_B: energy_B\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 310,
        "y": 240,
        "wires": [
            [
                "14ee0d84e5405125"
            ]
        ]
    },
    {
        "id": "2e08ad99f972e679",
        "type": "function",
        "z": "84087161fd829d92",
        "g": "e58558cb75de9af5",
        "name": "data Log",
        "func": "let energy = msg.power.energy;\nlet voltage = msg.power.voltage;\nlet current = msg.power.current;\nlet powerfactor = msg.power.powerfactor;\nlet power = msg.power.power;\nlet power_percentage = msg.power.percentagekwh;\nlet current_percentage = msg.power.percentageAmp;\n\nlet energy_A = msg.power.total.energy_A;\nlet energy_B = msg.power.total.energy_B;\nlet total_energy = msg.power.total.energy;\nlet co2 = msg.power.total.co2;\n\nlet timestamp = msg.filesystem.timestamp;\nvar date = msg.filesystem.date;\nvar time = msg.filesystem.time;\nvar date_data = msg.filesystem.date_data;\nvar ip = msg.filesystem.ip;\nvar shift = msg.filesystem.shift;\n\nmsg.payload = {\n    date: date, time: time, ip: ip, timestamp: timestamp, date_data: date_data, shift: shift,\n    voltA: voltage.A, voltB: voltage.B, voltC: voltage.C,\n    currentA: current.A, currentB: current.B, currentC: current.C,\n    powerA: power.A, powerB: power.B, powerC: power.C,\n    powerfA: powerfactor.A, powerfB: powerfactor.B, powerfC: powerfactor.C,\n    powerpA: power_percentage.A, powerpB: power_percentage.B, powerpC: power_percentage.C,\n    currentpA: current_percentage.A, currentpB: current_percentage.B, currentpC: current_percentage.C,\n    energy0: energy[0], energy1: energy[1], energy2: energy[2], energy3: energy[3], energy4: energy[4], energy5: energy[5], energy6: energy[6],\n    energy7: energy[7], energy8: energy[8], energy9: energy[9], energy10: energy[10], energy11: energy[11], energy12: energy[12], energy13: energy[13],\n    energy14: energy[14], energy15: energy[15], energy16: energy[16], energy17: energy[17], energy18: energy[18], energy19: energy[19], energy20: energy[20],\n    energy21: energy[21], energy22: energy[22], energy23: energy[23],\n    total_energy: total_energy, co2: co2, energy_A: energy_A, energy_B: energy_B\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 310,
        "y": 280,
        "wires": [
            [
                "3ee4450ecf3c66f3"
            ]
        ]
    },
    {
        "id": "14ee0d84e5405125",
        "type": "csv",
        "z": "84087161fd829d92",
        "g": "e58558cb75de9af5",
        "name": "",
        "sep": ",",
        "hdrin": "",
        "hdrout": "all",
        "multi": "one",
        "ret": "\\r\\n",
        "temp": "date,time,ip,timestamp,date_data,shift, voltA,voltB,voltC, currentA,currentB,currentC, powerA,powerB,powerC, powerfA,powerfB,powerfC, powerpA,powerpB,powerpC, currentpA,currentpB,currentpC, energy0,energy1,energy2,energy3,energy4,energy5,energy6, energy7,energy8,energy9,energy10,energy11,energy12,energy13, energy14,energy15,energy16,energy17,energy18,energy19,energy20, energy21,energy22,energy23, total_energy,co2,energy_A,energy_B,",
        "skip": "0",
        "strings": true,
        "include_empty_strings": "",
        "include_null_values": "",
        "x": 405,
        "y": 240,
        "wires": [
            [
                "2d7496a55fd4d5e5"
            ]
        ],
        "l": false
    },
    {
        "id": "3ee4450ecf3c66f3",
        "type": "csv",
        "z": "84087161fd829d92",
        "g": "e58558cb75de9af5",
        "name": "",
        "sep": ",",
        "hdrin": "",
        "hdrout": "none",
        "multi": "one",
        "ret": "\\r\\n",
        "temp": "",
        "skip": "0",
        "strings": true,
        "include_empty_strings": "",
        "include_null_values": "",
        "x": 405,
        "y": 280,
        "wires": [
            [
                "2d7496a55fd4d5e5"
            ]
        ],
        "l": false
    },
    {
        "id": "21232d92a0568ba1",
        "type": "file",
        "z": "84087161fd829d92",
        "g": "06e517f2e69268b9",
        "name": "Write",
        "filename": "pathlocalpro",
        "filenameType": "msg",
        "appendNewline": false,
        "createDir": true,
        "overwriteFile": "false",
        "encoding": "utf8",
        "x": 475,
        "y": 100,
        "wires": [
            [
                "d85755f4700406ad"
            ]
        ],
        "l": false
    },
    {
        "id": "4cb68426af89913b",
        "type": "file in",
        "z": "84087161fd829d92",
        "g": "06e517f2e69268b9",
        "name": "",
        "filename": "pathlocalpro",
        "filenameType": "msg",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "none",
        "allProps": false,
        "x": 595,
        "y": 100,
        "wires": [
            [
                "a72a90a834670a67"
            ]
        ],
        "l": false
    },
    {
        "id": "d85755f4700406ad",
        "type": "delay",
        "z": "84087161fd829d92",
        "g": "06e517f2e69268b9",
        "name": "",
        "pauseType": "delay",
        "timeout": "50",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 535,
        "y": 100,
        "wires": [
            [
                "4cb68426af89913b"
            ]
        ],
        "l": false
    },
    {
        "id": "a72a90a834670a67",
        "type": "csv",
        "z": "84087161fd829d92",
        "g": "06e517f2e69268b9",
        "name": "",
        "sep": ",",
        "hdrin": "",
        "hdrout": "none",
        "multi": "mult",
        "ret": "\\n",
        "temp": "",
        "skip": "0",
        "strings": true,
        "include_empty_strings": "",
        "include_null_values": "",
        "x": 655,
        "y": 100,
        "wires": [
            [
                "22a14c902b412f4a"
            ]
        ],
        "l": false
    },
    {
        "id": "2d7496a55fd4d5e5",
        "type": "file",
        "z": "84087161fd829d92",
        "g": "e58558cb75de9af5",
        "name": "Write",
        "filename": "pathlocalpow",
        "filenameType": "msg",
        "appendNewline": false,
        "createDir": true,
        "overwriteFile": "false",
        "encoding": "utf8",
        "x": 475,
        "y": 260,
        "wires": [
            [
                "cd67d193c28c206a"
            ]
        ],
        "l": false
    },
    {
        "id": "6b7fdbc76da5753a",
        "type": "file in",
        "z": "84087161fd829d92",
        "g": "e58558cb75de9af5",
        "name": "",
        "filename": "pathlocalpow",
        "filenameType": "msg",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "none",
        "allProps": false,
        "x": 595,
        "y": 260,
        "wires": [
            [
                "6e0b50d6e2f6c050"
            ]
        ],
        "l": false
    },
    {
        "id": "cd67d193c28c206a",
        "type": "delay",
        "z": "84087161fd829d92",
        "g": "e58558cb75de9af5",
        "name": "",
        "pauseType": "delay",
        "timeout": "50",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 535,
        "y": 260,
        "wires": [
            [
                "6b7fdbc76da5753a"
            ]
        ],
        "l": false
    },
    {
        "id": "6e0b50d6e2f6c050",
        "type": "csv",
        "z": "84087161fd829d92",
        "g": "e58558cb75de9af5",
        "name": "",
        "sep": ",",
        "hdrin": "",
        "hdrout": "none",
        "multi": "mult",
        "ret": "\\n",
        "temp": "",
        "skip": "0",
        "strings": true,
        "include_empty_strings": "",
        "include_null_values": "",
        "x": 655,
        "y": 260,
        "wires": [
            [
                "02f11ab3313a9672"
            ]
        ],
        "l": false
    },
    {
        "id": "22a14c902b412f4a",
        "type": "function",
        "z": "84087161fd829d92",
        "g": "06e517f2e69268b9",
        "name": "listProduction",
        "func": "var length = msg.payload.length\n    length = length - 1\nglobal.set(\"local.row.pro\", length)\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 725,
        "y": 100,
        "wires": [
            [
                "e51230850e6d2ae7"
            ]
        ],
        "icon": "node-red/debug.svg",
        "l": false
    },
    {
        "id": "02f11ab3313a9672",
        "type": "function",
        "z": "84087161fd829d92",
        "g": "e58558cb75de9af5",
        "name": "le",
        "func": "var length = msg.payload.length\nlength = length - 1\nglobal.set(\"local.row.pow\", length)\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 725,
        "y": 260,
        "wires": [
            [
                "e51230850e6d2ae7"
            ]
        ],
        "l": false
    },
    {
        "id": "a5f3d640d8df39da",
        "type": "delay",
        "z": "84087161fd829d92",
        "name": "",
        "pauseType": "rate",
        "timeout": "5",
        "timeoutUnits": "seconds",
        "rate": "1",
        "nbRateUnits": "40",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": true,
        "allowrate": false,
        "outputs": 1,
        "x": 895,
        "y": 180,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "e51230850e6d2ae7",
        "type": "function",
        "z": "84087161fd829d92",
        "name": "function 674",
        "func": "msg.payload = {\n    fill: \"yellow\",\n    shape: \"dot\",\n    text: `time: ${global.get(\"time\")} row.local(pr/po):${global.get(\"local.row.pro\")}/${global.get(\"local.row.pow\")}`\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 835,
        "y": 180,
        "wires": [
            [
                "a5f3d640d8df39da"
            ]
        ],
        "l": false
    },
    {
        "id": "72330c8a31557423",
        "type": "file in",
        "z": "327188e739dd9e39",
        "name": "",
        "filename": "pathlocalpow",
        "filenameType": "msg",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "none",
        "allProps": false,
        "x": 180,
        "y": 40,
        "wires": [
            [
                "699f8fb22d99fcf0"
            ]
        ]
    },
    {
        "id": "699f8fb22d99fcf0",
        "type": "csv",
        "z": "327188e739dd9e39",
        "name": "",
        "sep": ",",
        "hdrin": true,
        "hdrout": "",
        "multi": "mult",
        "ret": "\\r\\n",
        "temp": "",
        "skip": "0",
        "strings": true,
        "include_empty_strings": false,
        "include_null_values": false,
        "x": 295,
        "y": 40,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "a5f173bb48c85e9c",
        "type": "file in",
        "z": "766dd95607e2bd11",
        "name": "",
        "filename": "pathlocalpro",
        "filenameType": "msg",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "none",
        "allProps": false,
        "x": 200,
        "y": 80,
        "wires": [
            [
                "fea015996e00245b"
            ]
        ]
    },
    {
        "id": "fea015996e00245b",
        "type": "csv",
        "z": "766dd95607e2bd11",
        "name": "",
        "sep": ",",
        "hdrin": true,
        "hdrout": "",
        "multi": "mult",
        "ret": "\\r\\n",
        "temp": "",
        "skip": "0",
        "strings": true,
        "include_empty_strings": false,
        "include_null_values": false,
        "x": 315,
        "y": 80,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "646d7a4ff021a4f0",
        "type": "http in",
        "z": "3c87dd77ddd56ab5",
        "name": "API",
        "url": "/api/production-data",
        "method": "get",
        "upload": false,
        "swaggerDoc": "",
        "x": 105,
        "y": 80,
        "wires": [
            [
                "17dee4f60acb9d6b"
            ]
        ],
        "l": false
    },
    {
        "id": "cd7aeb4493655420",
        "type": "http in",
        "z": "3c87dd77ddd56ab5",
        "name": "API",
        "url": "/api/power-data",
        "method": "get",
        "upload": false,
        "swaggerDoc": "",
        "x": 105,
        "y": 160,
        "wires": [
            [
                "b630e11947d2ec4a"
            ]
        ],
        "l": false
    },
    {
        "id": "17072a28dd91691f",
        "type": "http response",
        "z": "3c87dd77ddd56ab5",
        "name": "API Response",
        "statusCode": "",
        "headers": {},
        "x": 675,
        "y": 80,
        "wires": [],
        "l": false
    },
    {
        "id": "8bb68df45afb15b9",
        "type": "http response",
        "z": "3c87dd77ddd56ab5",
        "name": "API Response",
        "statusCode": "",
        "headers": {},
        "x": 675,
        "y": 160,
        "wires": [],
        "l": false
    },
    {
        "id": "d46d58c3cba48624",
        "type": "subflow:766dd95607e2bd11",
        "z": "3c87dd77ddd56ab5",
        "name": "",
        "x": 360,
        "y": 80,
        "wires": [
            [
                "f75560b842f52c43"
            ]
        ]
    },
    {
        "id": "17dee4f60acb9d6b",
        "type": "function",
        "z": "3c87dd77ddd56ab5",
        "name": "Path",
        "func": "var connected = global.get(\"local.connection\");\nvar list = global.get(\"local.row.pro\") || 1;\nvar index = global.get(\"local.index.pro\") || 1;\n    msg.pathlocalpro =  `/home/orangepi/ext/data/production/log.csv`;\nif (connected && (index < list)){\n    return msg\n}\nnode.status({fill:\"red\",shape:\"ring\",text:list + index});",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 200,
        "y": 80,
        "wires": [
            [
                "d46d58c3cba48624"
            ]
        ]
    },
    {
        "id": "f75560b842f52c43",
        "type": "function",
        "z": "3c87dd77ddd56ab5",
        "name": "API Product",
        "func": "let index = global.get(\"local.index.pro\");\nconst load = msg.payload[index];\nflow.set(\"time.Pro\", load.time);\nlet meter = {};\nfor (let i = 0; i <= 23; i++) {\n    meter[i] = load[`meter${i}`];\n};\n\nconst API = {\n    'filesystem': {\n        date: load.date,\n        time: load.time,\n        ip: load.ip,\n        shift: load.shift,\n        date_data: load.date_data,\n        timestamp: load.timestamp\n    },\n    'values': {\n        'temp': {\n            'motor_in': {\n                'now': load.mt_in_now,\n                'min': load.mt_in_min,\n                'max': load.mt_in_max\n            },\n            'motor_out': {\n                'now': load.mt_out_now,\n                'min': load.mt_out_min,\n                'max': load.mt_out_max\n            },\n            'cooling_in': {\n                'now': load.cl_in_now,\n                'min': load.cl_in_min,\n                'max': load.cl_in_max\n            },\n            'cooling_out': {\n                'now': load.cl_out_now,\n                'min': load.cl_out_min,\n                'max': load.cl_out_max\n            },\n        },\n        'speed': {\n            'screw': {\n                'now': load.scr_now,\n                'min': load.scr_min,\n                'max': load.scr_max\n            },\n            'holding': {\n                'now': load.hol_now,\n                'min': load.hol_min,\n                'max': load.hol_max\n            },\n            'annealing': {\n                'now': load.ann_now,\n                'min': load.ann_min,\n                'max': load.ann_max\n            },\n            'stretching':{\n                'now': load.str_now,\n                'min': load.str_min,\n                'max': load.str_max\n            }\n        },\n        'meter': {\n            0: meter[0], 1: meter[1], 2: meter[2], 3: meter[3], 4: meter[4], 5: meter[5],\n            6: meter[6], 7: meter[7], 8: meter[8], 9: meter[9], 10: meter[10], 11: meter[11],\n            12: meter[12], 13: meter[13], 14: meter[14], 15: meter[15], 16: meter[16], 17: meter[17],\n            18: meter[18], 19: meter[19], 20: meter[20], 21: meter[21], 22: meter[22], 23: meter[23]\n        },\n        'total': {\n            'meter_min': load.meter_min,\n            'meter': load.total_meter,\n            'meter_A': load.meter_A,\n            'meter_B': load.meter_B,\n        }\n    }\n}\nnode.status({ fill: \"blue\", shape: \"dot\", text: load.time});\nconst jsonAPI = JSON.stringify(API);\nglobal.set(\"local.index.pro\", index + 1);\nmsg.payload = jsonAPI;\nreturn msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 540,
        "y": 80,
        "wires": [
            [
                "17072a28dd91691f",
                "def0597e21ffc9ac",
                "70d0f0fe1c72f9bd"
            ]
        ]
    },
    {
        "id": "b630e11947d2ec4a",
        "type": "function",
        "z": "3c87dd77ddd56ab5",
        "name": "Path",
        "func": "var connected = global.get(\"local.connection\");\nvar list = global.get(\"local.row.pow\") || 1;\nvar index = global.get(\"local.things.pow\") || 1;\nmsg.pathlocalpow = `/home/orangepi/ext/data/power/log.csv`;\nif (connected && (index < list)){\n    return msg\n}\nnode.status({fill:\"red\",shape:\"ring\",text:list + index});",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 200,
        "y": 160,
        "wires": [
            [
                "32395ba54cd9aed9"
            ]
        ]
    },
    {
        "id": "32395ba54cd9aed9",
        "type": "subflow:327188e739dd9e39",
        "z": "3c87dd77ddd56ab5",
        "name": "",
        "x": 350,
        "y": 160,
        "wires": [
            [
                "9eb30e66b1985f68"
            ]
        ]
    },
    {
        "id": "9eb30e66b1985f68",
        "type": "function",
        "z": "3c87dd77ddd56ab5",
        "name": "API Power",
        "func": "var index = global.get(\"local.index.pow\");\nlet timestamp = msg.payload[index].timestamp;\nlet date = msg.payload[index].date;\nlet time = msg.payload[index].time; flow.set(\"time.Pow\", time);\nlet ip = msg.payload[index].ip;\nlet date_data = msg.payload[index].date_data;\n// let shift = msg.payload[index].shift;\n\nvar voltageA = msg.payload[index].voltB;\nvar voltageB = msg.payload[index].voltB;\nvar voltageC = msg.payload[index].voltB;\n\nvar currentA = msg.payload[index].currentA;\nvar currentB = msg.payload[index].currentB;\nvar currentC = msg.payload[index].currentC;\n\nvar powerA = msg.payload[index].powerA;\nvar powerB = msg.payload[index].powerB;\nvar powerC = msg.payload[index].powerC;\n\nvar powerfactorA = msg.payload[index].powerfA;\nvar powerfactorB = msg.payload[index].powerfB;\nvar powerfactorC = msg.payload[index].powerfC;\n\nvar percentagekwhA = msg.payload[index].powerpA;\nvar percentagekwhB = msg.payload[index].powerpB;\nvar percentagekwhC = msg.payload[index].powerpC;\n\nvar percentageAmpA = msg.payload[index].currentpA;\nvar percentageAmpB = msg.payload[index].currentpB;\nvar percentageAmpC = msg.payload[index].currentpC;\n\nvar energy = Array.from({ length: 24 }, (_, i) => msg.payload[index][`energy${i}`]);\n\nlet energy_min = msg.payload[index].energy_min;\nlet total_energy = msg.payload[index].total_energy;\nlet energy_A = msg.payload[index].energy_A;\nlet energy_B = msg.payload[index].energy_B;\nlet co2 = msg.payload[index].co2;\n\nconst API = {\n    'filesystem':{ \n        date: date,\n        time: time, \n        ip: ip, \n        date_data: date_data,\n        timestamp: timestamp\n    },\n    'values':{\n        'voltage':{\n            A: voltageA,\n            B: voltageB,\n            C: voltageC\n        },\n        'current':{\n            A: currentA,\n            B: currentB,\n            C: currentC\n        },\n        'power':{\n            A: powerA,\n            B: powerB,\n            C: powerC\n        },\n        'powerfactor':{\n            A: powerfactorA,\n            B: powerfactorB,\n            C: powerfactorC\n        },\n        'percentagekwh':{\n            A: percentagekwhA,\n            B: percentagekwhB,\n            C: percentagekwhC            \n        },\n        'percentageAmp':{\n            A: percentageAmpA,\n            B: percentageAmpB,\n            C: percentageAmpC            \n        },\n        'energy':{\n            0: energy[0], 1: energy[1], 2: energy[2], 3: energy[3], 4: energy[4], 5: energy[5], \n            6: energy[6], 7: energy[7], 8: energy[8], 9: energy[9], 10: energy[10], 11: energy[11], \n            12: energy[12], 13: energy[13], 14: energy[14], 15: energy[15], 16: energy[16], 17: energy[17], \n            18: energy[18], 19: energy[19], 20: energy[20],21: energy[21], 22: energy[22], 23: energy[23]\n        },\n        'total':{\n            'energy': total_energy,\n            'energy_A': energy_A,\n            'energy_B': energy_B,\n            'co2': co2\n        }\n    }\n}\nnode.status({fill:\"blue\",shape:\"dot\",text:time});\nconst jsonAPI = JSON.stringify(API)\nglobal.set(\"local.index.pow\", index + 1)\nmsg.payload = jsonAPI;\nreturn msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 540,
        "y": 160,
        "wires": [
            [
                "8bb68df45afb15b9",
                "def0597e21ffc9ac",
                "f36ce8ff3fa3cabe"
            ]
        ]
    },
    {
        "id": "def0597e21ffc9ac",
        "type": "function",
        "z": "3c87dd77ddd56ab5",
        "name": "function 677",
        "func": "msg.payload = {\n    fill: \"blue\",\n    shape: \"dot\",\n    text: \" Pro:\" + flow.get(\"time.Pro\") + \" Pow:\" + flow.get(\"time.Pow\")\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 750,
        "y": 280,
        "wires": [
            []
        ]
    },
    {
        "id": "2b774076463377f6",
        "type": "exec",
        "z": "3c87dd77ddd56ab5",
        "command": "",
        "addpay": "remove",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "",
        "x": 830,
        "y": 200,
        "wires": [
            [],
            [],
            []
        ]
    },
    {
        "id": "f36ce8ff3fa3cabe",
        "type": "function",
        "z": "3c87dd77ddd56ab5",
        "name": "function 676",
        "func": "let index = global.get(\"local.index.pow\");\nlet row = global.get(\"local.row.pow\");\nif(row > 1000 && index == row){\n    msg.remove = `rm /home/orangepi/ext/data/power/log.csv`;\n    return msg;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 675,
        "y": 200,
        "wires": [
            [
                "2b774076463377f6"
            ]
        ],
        "icon": "font-awesome/fa-times-circle",
        "l": false
    },
    {
        "id": "329cbedad04d4239",
        "type": "exec",
        "z": "3c87dd77ddd56ab5",
        "command": "",
        "addpay": "remove",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "",
        "x": 830,
        "y": 120,
        "wires": [
            [],
            [],
            []
        ]
    },
    {
        "id": "70d0f0fe1c72f9bd",
        "type": "function",
        "z": "3c87dd77ddd56ab5",
        "name": "function 3",
        "func": "let index = global.get(\"local.index.pro\");\nlet row = global.get(\"local.row.pro\");\nif(row > 1000 && index == row){\n    msg.remove = `rm /home/orangepi/ext/data/production/log.csv`;\n    return msg;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 675,
        "y": 120,
        "wires": [
            [
                "329cbedad04d4239"
            ]
        ],
        "icon": "font-awesome/fa-times-circle",
        "l": false
    },
    {
        "id": "fc0464d9fda188ed",
        "type": "ui-form",
        "z": "5cf1d8d919e64156",
        "name": "form login",
        "group": "818c81dd7f0dc596",
        "label": "Login for Administrator",
        "order": 1,
        "width": "4",
        "height": "5",
        "options": [
            {
                "label": "E-Mail Address",
                "key": "username",
                "type": "email",
                "required": true,
                "rows": null
            },
            {
                "label": "Password",
                "key": "password",
                "type": "password",
                "required": true,
                "rows": null
            }
        ],
        "formValue": {
            "username": "",
            "password": ""
        },
        "payload": "",
        "submit": "submit",
        "cancel": "clear",
        "resetOnSubmit": true,
        "topic": "topic",
        "topicType": "msg",
        "splitLayout": "",
        "className": "",
        "passthru": false,
        "dropdownOptions": [],
        "x": 180,
        "y": 200,
        "wires": [
            [
                "d5056b7e93029074",
                "e204c70bf5bec561"
            ]
        ]
    },
    {
        "id": "b9edef1b1700064d",
        "type": "ui-button",
        "z": "5cf1d8d919e64156",
        "group": "963da81f78ac7902",
        "name": "Login",
        "label": "Login for Admin",
        "order": 1,
        "width": "4",
        "height": "1",
        "emulateClick": false,
        "tooltip": "",
        "color": "",
        "bgcolor": "",
        "className": "",
        "icon": "",
        "iconPosition": "left",
        "payload": "{\"groups\":{\"show\":[\"Admin:Login\"]}}",
        "payloadType": "json",
        "topic": "topic",
        "topicType": "msg",
        "buttonColor": "",
        "textColor": "",
        "iconColor": "",
        "enableClick": true,
        "enablePointerdown": false,
        "pointerdownPayload": "",
        "pointerdownPayloadType": "str",
        "enablePointerup": false,
        "pointerupPayload": "",
        "pointerupPayloadType": "str",
        "x": 390,
        "y": 160,
        "wires": [
            [
                "62355c04413b7e35"
            ]
        ]
    },
    {
        "id": "62355c04413b7e35",
        "type": "ui-control",
        "z": "5cf1d8d919e64156",
        "name": "",
        "ui": "b1c16cc4bf11ba76",
        "events": "all",
        "x": 540,
        "y": 200,
        "wires": [
            []
        ]
    },
    {
        "id": "d5056b7e93029074",
        "type": "change",
        "z": "5cf1d8d919e64156",
        "name": "Hide Dialog",
        "rules": [
            {
                "t": "set",
                "p": "payload",
                "pt": "msg",
                "to": "{\"groups\":{\"hide\":[\"Admin:Login\"]}}",
                "tot": "json"
            }
        ],
        "action": "",
        "property": "",
        "from": "",
        "to": "",
        "reg": false,
        "x": 425,
        "y": 200,
        "wires": [
            [
                "62355c04413b7e35"
            ]
        ],
        "l": false
    },
    {
        "id": "e204c70bf5bec561",
        "type": "function",
        "z": "5cf1d8d919e64156",
        "name": "login",
        "func": "if ((msg.payload.username === \"adminiot@hotmail.com\") && (msg.payload.password === \"1704\")){\n    msg.start = true\n    return msg;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 330,
        "y": 260,
        "wires": [
            [
                "3605ebf1fa7d464a",
                "57a65f6c721d8d5d"
            ]
        ]
    },
    {
        "id": "3605ebf1fa7d464a",
        "type": "change",
        "z": "5cf1d8d919e64156",
        "name": "Hide Dialog",
        "rules": [
            {
                "t": "set",
                "p": "payload",
                "pt": "msg",
                "to": "{\"groups\":{\"hide\":[\"Admin:Home\"],\"show\":[\"Admin:Configurations\"]}}",
                "tot": "json"
            }
        ],
        "action": "",
        "property": "",
        "from": "",
        "to": "",
        "reg": false,
        "x": 425,
        "y": 260,
        "wires": [
            [
                "62355c04413b7e35",
                "84e54cea553943e8",
                "ec402d832131b1a4",
                "b8ffe1dca80a0a8e",
                "7ead7bb186d2c989",
                "c59a9d6dfeeba601",
                "c69d06c109dea856",
                "c476d9264f540db2"
            ]
        ],
        "l": false
    },
    {
        "id": "38758c03634510e8",
        "type": "ui-button",
        "z": "5cf1d8d919e64156",
        "group": "1a25a88e19cb234a",
        "name": "Log Out",
        "label": "Log Out",
        "order": 11,
        "width": "7",
        "height": "1",
        "emulateClick": true,
        "tooltip": "",
        "color": "",
        "bgcolor": "",
        "className": "",
        "icon": "",
        "iconPosition": "left",
        "payload": "{\"groups\":{\"show\":[\"Admin:Home\"],\"hide\":[\"Admin:Configurations\"]}}",
        "payloadType": "json",
        "topic": "topic",
        "topicType": "msg",
        "buttonColor": "",
        "textColor": "",
        "iconColor": "",
        "enableClick": true,
        "enablePointerdown": false,
        "pointerdownPayload": "",
        "pointerdownPayloadType": "str",
        "enablePointerup": false,
        "pointerupPayload": "",
        "pointerupPayloadType": "str",
        "x": 760,
        "y": 200,
        "wires": [
            [
                "eae6d39dd1f5a209",
                "8bc5d0c5574eaac3"
            ]
        ]
    },
    {
        "id": "eae6d39dd1f5a209",
        "type": "ui-control",
        "z": "5cf1d8d919e64156",
        "name": "",
        "ui": "b1c16cc4bf11ba76",
        "events": "all",
        "x": 900,
        "y": 200,
        "wires": [
            []
        ]
    },
    {
        "id": "13fd2f7b8d620b8f",
        "type": "ui-form",
        "z": "5cf1d8d919e64156",
        "name": "Things Board Configurations",
        "group": "5afa5b8f48610c59",
        "label": "Things Board Configurations",
        "order": 1,
        "width": "4",
        "height": "2",
        "options": [
            {
                "label": "Broker",
                "key": "broker",
                "type": "text",
                "required": true,
                "rows": null
            },
            {
                "label": "Port",
                "key": "port",
                "type": "number",
                "required": true,
                "rows": null
            },
            {
                "label": "Username",
                "key": "username",
                "type": "text",
                "required": true,
                "rows": null
            },
            {
                "label": "Topic",
                "key": "topic",
                "type": "text",
                "required": true,
                "rows": null
            }
        ],
        "formValue": {
            "broker": "",
            "port": "",
            "username": "",
            "topic": ""
        },
        "payload": "",
        "submit": "Enter",
        "cancel": "",
        "resetOnSubmit": true,
        "topic": "topic",
        "topicType": "msg",
        "splitLayout": "",
        "className": "",
        "passthru": false,
        "dropdownOptions": [],
        "x": 620,
        "y": 680,
        "wires": [
            [
                "3c1c93a4389d2ccd"
            ]
        ]
    },
    {
        "id": "3c1c93a4389d2ccd",
        "type": "function",
        "z": "5cf1d8d919e64156",
        "name": "Things Board Config",
        "func": "global.set(\"things.broker\", msg.payload.broker);\nglobal.set(\"things.username\", msg.payload.username);\nglobal.set(\"things.topic\", msg.payload.topic);\nglobal.set(\"things.port\", msg.payload.port);\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 860,
        "y": 680,
        "wires": [
            [
                "517e2e9d8935598b"
            ]
        ]
    },
    {
        "id": "84e54cea553943e8",
        "type": "function",
        "z": "5cf1d8d919e64156",
        "name": "Dedault",
        "func": "let broker = global.get(\"things.broker\")\nmsg.payload = \" \" + broker\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 600,
        "y": 260,
        "wires": [
            [
                "8cf2e5938285be42"
            ]
        ]
    },
    {
        "id": "8cf2e5938285be42",
        "type": "ui-text",
        "z": "5cf1d8d919e64156",
        "group": "1a25a88e19cb234a",
        "order": 1,
        "width": "6",
        "height": "1",
        "name": "",
        "label": "Broker Things board : ",
        "format": "{{msg.payload}}",
        "layout": "row-left",
        "style": true,
        "font": "Arial Narrow,Nimbus Sans L,sans-serif",
        "fontSize": "20",
        "color": "#000000",
        "wrapText": false,
        "className": "",
        "x": 860,
        "y": 260,
        "wires": []
    },
    {
        "id": "ec402d832131b1a4",
        "type": "function",
        "z": "5cf1d8d919e64156",
        "name": "Dedault",
        "func": "let username = global.get(\"things.username\")\nmsg.payload = \" \" + username\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 600,
        "y": 440,
        "wires": [
            [
                "27e09e6861115d87"
            ]
        ]
    },
    {
        "id": "27e09e6861115d87",
        "type": "ui-text",
        "z": "5cf1d8d919e64156",
        "group": "1a25a88e19cb234a",
        "order": 4,
        "width": "6",
        "height": "1",
        "name": "",
        "label": "Username : ",
        "format": "{{msg.payload}}",
        "layout": "row-left",
        "style": true,
        "font": "Arial Narrow,Nimbus Sans L,sans-serif",
        "fontSize": "20",
        "color": "#000000",
        "wrapText": false,
        "className": "",
        "x": 830,
        "y": 440,
        "wires": []
    },
    {
        "id": "faec4220ce1098f0",
        "type": "ui-button",
        "z": "5cf1d8d919e64156",
        "group": "1a25a88e19cb234a",
        "name": "Edit1",
        "label": "Edit",
        "order": 5,
        "width": "1",
        "height": "1",
        "emulateClick": false,
        "tooltip": "",
        "color": "",
        "bgcolor": "",
        "className": "",
        "icon": "",
        "iconPosition": "left",
        "payload": "{\"groups\":{\"show\":[\"Admin:TBconfig\"]}}",
        "payloadType": "json",
        "topic": "topic",
        "topicType": "msg",
        "buttonColor": "",
        "textColor": "",
        "iconColor": "",
        "enableClick": true,
        "enablePointerdown": false,
        "pointerdownPayload": "",
        "pointerdownPayloadType": "str",
        "enablePointerup": false,
        "pointerupPayload": "",
        "pointerupPayloadType": "str",
        "x": 1150,
        "y": 680,
        "wires": [
            [
                "8ab1650f7be9deba"
            ]
        ]
    },
    {
        "id": "8ab1650f7be9deba",
        "type": "ui-control",
        "z": "5cf1d8d919e64156",
        "name": "",
        "ui": "b1c16cc4bf11ba76",
        "events": "all",
        "x": 1370,
        "y": 680,
        "wires": [
            [
                "369e91a543fa6bbf"
            ]
        ]
    },
    {
        "id": "319e33da706f36fc",
        "type": "function",
        "z": "5cf1d8d919e64156",
        "name": "Log out",
        "func": "var countdown = context.get(\"countdown\") || 0\nvar start = context.get(\"start\") || false\n\nif(msg.start){\n    context.set(\"start\", true)\n}\nif(start){\n    let count = Number(countdown) + 1\n    context.set(\"countdown\", count)\n} \nif (countdown > 600){\n    context.set(\"start\", false)\n    context.set(\"countdown\", 0)\n    return msg\n}\nif(msg.resection){\n    context.set(\"start\", false)\n    context.set(\"countdown\", 0)\n}\nnode.status({fill:\"blue\",shape:\"dot\",text:\"Sec : \" + countdown});",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 600,
        "y": 160,
        "wires": [
            [
                "38758c03634510e8"
            ]
        ]
    },
    {
        "id": "8537162beacd8160",
        "type": "link in",
        "z": "5cf1d8d919e64156",
        "name": "link in 75",
        "links": [
            "57a65f6c721d8d5d",
            "7905c8ebfe653b58"
        ],
        "x": 495,
        "y": 160,
        "wires": [
            [
                "319e33da706f36fc"
            ]
        ]
    },
    {
        "id": "57a65f6c721d8d5d",
        "type": "link out",
        "z": "5cf1d8d919e64156",
        "name": "link out 4",
        "mode": "link",
        "links": [
            "8537162beacd8160"
        ],
        "x": 425,
        "y": 300,
        "wires": []
    },
    {
        "id": "02ec76de2f1983f4",
        "type": "change",
        "z": "5cf1d8d919e64156",
        "name": "Hide Dialog",
        "rules": [
            {
                "t": "set",
                "p": "payload",
                "pt": "msg",
                "to": "{\"groups\":{\"show\":[\"Admin:Home\"],\"hide\":[\"Admin:Configurations\"]}}",
                "tot": "json"
            }
        ],
        "action": "",
        "property": "",
        "from": "",
        "to": "",
        "reg": false,
        "x": 1255,
        "y": 720,
        "wires": [
            [
                "8ab1650f7be9deba"
            ]
        ],
        "l": false
    },
    {
        "id": "f674edeb6d3eb745",
        "type": "change",
        "z": "5cf1d8d919e64156",
        "name": "Hide Dialog",
        "rules": [
            {
                "t": "set",
                "p": "resection",
                "pt": "msg",
                "to": "true",
                "tot": "bool"
            }
        ],
        "action": "",
        "property": "",
        "from": "",
        "to": "",
        "reg": false,
        "x": 495,
        "y": 120,
        "wires": [
            [
                "319e33da706f36fc"
            ]
        ],
        "l": false
    },
    {
        "id": "8bc5d0c5574eaac3",
        "type": "link out",
        "z": "5cf1d8d919e64156",
        "name": "link out 6",
        "mode": "link",
        "links": [
            "599713cf36ba4a8d"
        ],
        "x": 855,
        "y": 160,
        "wires": []
    },
    {
        "id": "599713cf36ba4a8d",
        "type": "link in",
        "z": "5cf1d8d919e64156",
        "name": "link in 77",
        "links": [
            "8bc5d0c5574eaac3"
        ],
        "x": 425,
        "y": 120,
        "wires": [
            [
                "f674edeb6d3eb745"
            ]
        ]
    },
    {
        "id": "b30b28aab9b4b1c3",
        "type": "inject",
        "z": "5cf1d8d919e64156",
        "name": "",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            }
        ],
        "repeat": "1",
        "crontab": "",
        "once": false,
        "onceDelay": 0.1,
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 310,
        "y": 60,
        "wires": [
            [
                "7905c8ebfe653b58"
            ]
        ]
    },
    {
        "id": "7905c8ebfe653b58",
        "type": "link out",
        "z": "5cf1d8d919e64156",
        "name": "link out 3",
        "mode": "link",
        "links": [
            "8537162beacd8160"
        ],
        "x": 425,
        "y": 60,
        "wires": []
    },
    {
        "id": "2481bfaa989e2cbb",
        "type": "ui-event",
        "z": "5cf1d8d919e64156",
        "ui": "b1c16cc4bf11ba76",
        "name": "",
        "x": 1140,
        "y": 720,
        "wires": [
            [
                "02ec76de2f1983f4"
            ]
        ]
    },
    {
        "id": "b9c4fbc9b9946965",
        "type": "ui-button",
        "z": "5cf1d8d919e64156",
        "group": "1a25a88e19cb234a",
        "name": "Edit2",
        "label": "Edit",
        "order": 7,
        "width": "1",
        "height": "1",
        "emulateClick": false,
        "tooltip": "",
        "color": "",
        "bgcolor": "",
        "className": "",
        "icon": "",
        "iconPosition": "left",
        "payload": "{\"groups\":{\"show\":[\"Admin:PCconfig\"]}}",
        "payloadType": "json",
        "topic": "topic",
        "topicType": "msg",
        "buttonColor": "",
        "textColor": "",
        "iconColor": "",
        "enableClick": true,
        "enablePointerdown": false,
        "pointerdownPayload": "",
        "pointerdownPayloadType": "str",
        "enablePointerup": false,
        "pointerupPayload": "",
        "pointerupPayloadType": "str",
        "x": 1150,
        "y": 760,
        "wires": [
            [
                "02a0fa15d7aff043"
            ]
        ]
    },
    {
        "id": "02a0fa15d7aff043",
        "type": "ui-control",
        "z": "5cf1d8d919e64156",
        "name": "",
        "ui": "b1c16cc4bf11ba76",
        "events": "all",
        "x": 1370,
        "y": 760,
        "wires": [
            [
                "b6c1ecab704e3189"
            ]
        ]
    },
    {
        "id": "0166c4132c1e0467",
        "type": "change",
        "z": "5cf1d8d919e64156",
        "name": "Hide Dialog",
        "rules": [
            {
                "t": "set",
                "p": "payload",
                "pt": "msg",
                "to": "{\"groups\":{\"show\":[\"Admin:Home\"],\"hide\":[\"Admin:Configurations\"]}}",
                "tot": "json"
            }
        ],
        "action": "",
        "property": "",
        "from": "",
        "to": "",
        "reg": false,
        "x": 1255,
        "y": 800,
        "wires": [
            [
                "02a0fa15d7aff043"
            ]
        ],
        "l": false
    },
    {
        "id": "a2f32f4605b560b2",
        "type": "ui-event",
        "z": "5cf1d8d919e64156",
        "ui": "b1c16cc4bf11ba76",
        "name": "",
        "x": 1140,
        "y": 800,
        "wires": [
            [
                "0166c4132c1e0467"
            ]
        ]
    },
    {
        "id": "eb05e7ef2207f8dc",
        "type": "function",
        "z": "5cf1d8d919e64156",
        "name": "Things Board Config",
        "func": "global.set(\"local.ip\", msg.payload.lcserver);\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 860,
        "y": 760,
        "wires": [
            [
                "4a5ca876f66d8f79"
            ]
        ]
    },
    {
        "id": "aab5af8e6aa7da45",
        "type": "ui-form",
        "z": "5cf1d8d919e64156",
        "name": "Server Configurations",
        "group": "2c538605a7eee495",
        "label": "Local Server Configurations",
        "order": 2,
        "width": "4",
        "height": "2",
        "options": [
            {
                "label": "IP Local Server",
                "key": "lcserver",
                "type": "text",
                "required": true,
                "rows": null
            }
        ],
        "formValue": {
            "lcserver": ""
        },
        "payload": "",
        "submit": "Enter",
        "cancel": "",
        "resetOnSubmit": true,
        "topic": "topic",
        "topicType": "msg",
        "splitLayout": "",
        "className": "",
        "passthru": false,
        "dropdownOptions": [],
        "x": 640,
        "y": 760,
        "wires": [
            [
                "eb05e7ef2207f8dc"
            ]
        ]
    },
    {
        "id": "b8ffe1dca80a0a8e",
        "type": "function",
        "z": "5cf1d8d919e64156",
        "name": "Dedault",
        "func": "let lc_server = global.get(\"local.ip\")\nmsg.payload = \" \" + lc_server\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 600,
        "y": 500,
        "wires": [
            [
                "407f770346cf3d35"
            ]
        ]
    },
    {
        "id": "407f770346cf3d35",
        "type": "ui-text",
        "z": "5cf1d8d919e64156",
        "group": "1a25a88e19cb234a",
        "order": 6,
        "width": "6",
        "height": "1",
        "name": "",
        "label": "IP Local Server : ",
        "format": "{{msg.payload}}",
        "layout": "row-left",
        "style": true,
        "font": "Arial Narrow,Nimbus Sans L,sans-serif",
        "fontSize": "20",
        "color": "#000000",
        "wrapText": true,
        "className": "",
        "x": 840,
        "y": 500,
        "wires": []
    },
    {
        "id": "517e2e9d8935598b",
        "type": "link out",
        "z": "5cf1d8d919e64156",
        "name": "link out 11",
        "mode": "link",
        "links": [
            "124fbc88b5bbc25e"
        ],
        "x": 1005,
        "y": 680,
        "wires": []
    },
    {
        "id": "4a5ca876f66d8f79",
        "type": "link out",
        "z": "5cf1d8d919e64156",
        "name": "link out 12",
        "mode": "link",
        "links": [
            "9fc435df6a1d7f35"
        ],
        "x": 1005,
        "y": 760,
        "wires": []
    },
    {
        "id": "124fbc88b5bbc25e",
        "type": "link in",
        "z": "5cf1d8d919e64156",
        "name": "link in 78",
        "links": [
            "517e2e9d8935598b"
        ],
        "x": 465,
        "y": 360,
        "wires": [
            [
                "84e54cea553943e8",
                "ec402d832131b1a4",
                "7ead7bb186d2c989",
                "c59a9d6dfeeba601"
            ]
        ]
    },
    {
        "id": "9fc435df6a1d7f35",
        "type": "link in",
        "z": "5cf1d8d919e64156",
        "name": "link in 79",
        "links": [
            "4a5ca876f66d8f79"
        ],
        "x": 475,
        "y": 500,
        "wires": [
            [
                "b8ffe1dca80a0a8e"
            ]
        ]
    },
    {
        "id": "7ead7bb186d2c989",
        "type": "function",
        "z": "5cf1d8d919e64156",
        "name": "Dedault",
        "func": "let port = global.get(\"things.port\")\nmsg.payload = \" \" + port\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 600,
        "y": 320,
        "wires": [
            [
                "31336472e6f91b06"
            ]
        ]
    },
    {
        "id": "31336472e6f91b06",
        "type": "ui-text",
        "z": "5cf1d8d919e64156",
        "group": "1a25a88e19cb234a",
        "order": 2,
        "width": "6",
        "height": "1",
        "name": "",
        "label": "Port : ",
        "format": "{{msg.payload}}",
        "layout": "row-left",
        "style": true,
        "font": "Arial Narrow,Nimbus Sans L,sans-serif",
        "fontSize": "20",
        "color": "#000000",
        "wrapText": false,
        "className": "",
        "x": 810,
        "y": 320,
        "wires": []
    },
    {
        "id": "c59a9d6dfeeba601",
        "type": "function",
        "z": "5cf1d8d919e64156",
        "name": "Dedault",
        "func": "let topic = global.get(\"things.topic\")\nmsg.payload = \" \" + topic\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 600,
        "y": 380,
        "wires": [
            [
                "fe7e4ef3c777d4aa"
            ]
        ]
    },
    {
        "id": "fe7e4ef3c777d4aa",
        "type": "ui-text",
        "z": "5cf1d8d919e64156",
        "group": "1a25a88e19cb234a",
        "order": 3,
        "width": "6",
        "height": "1",
        "name": "",
        "label": "Topic : ",
        "format": "{{msg.payload}}",
        "layout": "row-left",
        "style": true,
        "font": "Arial Narrow,Nimbus Sans L,sans-serif",
        "fontSize": "20",
        "color": "#000000",
        "wrapText": false,
        "className": "",
        "x": 810,
        "y": 380,
        "wires": []
    },
    {
        "id": "b8b5bfc6366c4d3d",
        "type": "ui-template",
        "z": "5cf1d8d919e64156",
        "group": "",
        "page": "",
        "ui": "b1c16cc4bf11ba76",
        "name": "CSS",
        "order": 0,
        "width": 0,
        "height": 0,
        "head": "",
        "format": "    .v-navigation-drawer {\n        background: url(\"https://i.ytimg.com/vi/_VE1CqAAmuc/maxresdefault.jpg\") no-repeat center center;\n        background-size: cover;\n        /* ทำให้รูปภาพขยายเต็มขนาด */\n        position: relative;\n        /* เพิ่มตำแหน่ง relative เพื่อให้ overlay ทำงานได้ */\n    }\n        /* เพิ่มโทนมืด 50% บนรูปภาพ */\n    .v-navigation-drawer::after {\n        content: \"\";\n        position: absolute;\n        top: 0;\n        left: 0;\n        right: 0;\n        bottom: 0;\n        background-color: rgba(0, 0, 0, 0.5); /* สีดำโปร่งใส 50% */\n        z-index: 1; /* ทำให้โทนมืดอยู่เหนือพื้นหลัง */\n    }\n    .v-navigation-drawer .v-navigation-drawer__content {\n        z-index: 2; /* ทำให้เนื้อหาของ Sidebar อยู่เหนือโทนมืด */\n        color: white; /* ทำให้ตัวอักษรเป็นสีขาว */\n    }\n    /* end Navigation Drawer */\n    .v-toolbar.v-app-bar {\n        background: url('https://developer.android.com/static/images/design/ui/mobile/system-bars-hero.png') no-repeat center center !important;\n        background-size: cover !important;\n        color: black;\n    }",
        "storeOutMessages": true,
        "passthru": true,
        "resendOnRefresh": true,
        "templateScope": "site:style",
        "className": "",
        "x": 1050,
        "y": 200,
        "wires": [
            []
        ]
    },
    {
        "id": "418a4ea39bf72c6b",
        "type": "ui-button",
        "z": "5cf1d8d919e64156",
        "group": "1a25a88e19cb234a",
        "name": "Edit3",
        "label": "Edit",
        "order": 10,
        "width": "1",
        "height": "1",
        "emulateClick": false,
        "tooltip": "",
        "color": "",
        "bgcolor": "",
        "className": "",
        "icon": "",
        "iconPosition": "left",
        "payload": "{\"groups\":{\"show\":[\"Admin:telegram\"]}}",
        "payloadType": "json",
        "topic": "topic",
        "topicType": "msg",
        "buttonColor": "",
        "textColor": "",
        "iconColor": "",
        "enableClick": true,
        "enablePointerdown": false,
        "pointerdownPayload": "",
        "pointerdownPayloadType": "str",
        "enablePointerup": false,
        "pointerupPayload": "",
        "pointerupPayloadType": "str",
        "x": 1150,
        "y": 840,
        "wires": [
            [
                "42c87e6078e6961f"
            ]
        ]
    },
    {
        "id": "42c87e6078e6961f",
        "type": "ui-control",
        "z": "5cf1d8d919e64156",
        "name": "",
        "ui": "b1c16cc4bf11ba76",
        "events": "all",
        "x": 1370,
        "y": 840,
        "wires": [
            [
                "366b498c1b319bc8"
            ]
        ]
    },
    {
        "id": "3e830438d5794322",
        "type": "change",
        "z": "5cf1d8d919e64156",
        "name": "Hide Dialog",
        "rules": [
            {
                "t": "set",
                "p": "payload",
                "pt": "msg",
                "to": "{\"groups\":{\"show\":[\"Admin:Home\"],\"hide\":[\"Admin:teletram\"]}}",
                "tot": "json"
            }
        ],
        "action": "",
        "property": "",
        "from": "",
        "to": "",
        "reg": false,
        "x": 1255,
        "y": 880,
        "wires": [
            [
                "42c87e6078e6961f"
            ]
        ],
        "l": false
    },
    {
        "id": "2c4e03b965487eba",
        "type": "ui-event",
        "z": "5cf1d8d919e64156",
        "ui": "b1c16cc4bf11ba76",
        "name": "",
        "x": 1140,
        "y": 880,
        "wires": [
            [
                "3e830438d5794322"
            ]
        ]
    },
    {
        "id": "c69d06c109dea856",
        "type": "function",
        "z": "5cf1d8d919e64156",
        "name": "Dedault",
        "func": "let bot_token = global.get(\"bot_token\")\nmsg.payload = \" \" + bot_token\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 600,
        "y": 560,
        "wires": [
            [
                "36305a2678750c0a"
            ]
        ]
    },
    {
        "id": "36305a2678750c0a",
        "type": "ui-text",
        "z": "5cf1d8d919e64156",
        "group": "1a25a88e19cb234a",
        "order": 8,
        "width": "6",
        "height": "1",
        "name": "",
        "label": "Bot Token : ",
        "format": "{{msg.payload}}",
        "layout": "row-left",
        "style": true,
        "font": "Arial Narrow,Nimbus Sans L,sans-serif",
        "fontSize": "20",
        "color": "#000000",
        "wrapText": true,
        "className": "",
        "x": 830,
        "y": 560,
        "wires": []
    },
    {
        "id": "e5551093c3394f6b",
        "type": "ui-text",
        "z": "5cf1d8d919e64156",
        "group": "1a25a88e19cb234a",
        "order": 9,
        "width": "6",
        "height": "1",
        "name": "",
        "label": "Chat ID : ",
        "format": "{{msg.payload}}",
        "layout": "row-left",
        "style": true,
        "font": "Arial Narrow,Nimbus Sans L,sans-serif",
        "fontSize": "20",
        "color": "#000000",
        "wrapText": true,
        "className": "",
        "x": 820,
        "y": 620,
        "wires": []
    },
    {
        "id": "c476d9264f540db2",
        "type": "function",
        "z": "5cf1d8d919e64156",
        "name": "Dedault",
        "func": "let chat_id = global.get(\"chat_id\")\nmsg.payload = \" \" + chat_id\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 600,
        "y": 620,
        "wires": [
            [
                "e5551093c3394f6b"
            ]
        ]
    },
    {
        "id": "15c211527512f4a8",
        "type": "ui-form",
        "z": "5cf1d8d919e64156",
        "name": "Telegram Configurations",
        "group": "f2bec2318b7febd7",
        "label": "Telegram Configurations",
        "order": 1,
        "width": "4",
        "height": "2",
        "options": [
            {
                "label": "Bot Token",
                "key": "botToken",
                "type": "text",
                "required": true,
                "rows": null
            },
            {
                "label": "Chat ID",
                "key": "chatId",
                "type": "text",
                "required": true,
                "rows": null
            }
        ],
        "formValue": {
            "botToken": "",
            "chatId": ""
        },
        "payload": "",
        "submit": "Enter",
        "cancel": "",
        "resetOnSubmit": true,
        "topic": "topic",
        "topicType": "msg",
        "splitLayout": "",
        "className": "",
        "passthru": false,
        "dropdownOptions": [],
        "x": 630,
        "y": 840,
        "wires": [
            [
                "9e4d4aad0a278ae9"
            ]
        ]
    },
    {
        "id": "9e4d4aad0a278ae9",
        "type": "function",
        "z": "5cf1d8d919e64156",
        "name": "Things Board Config",
        "func": "global.set(\"bot_token\", msg.payload.botToken);\nglobal.set(\"chat_id\", msg.payload.chatId);\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 860,
        "y": 840,
        "wires": [
            [
                "9991ad229f4f64e2"
            ]
        ]
    },
    {
        "id": "9991ad229f4f64e2",
        "type": "link out",
        "z": "5cf1d8d919e64156",
        "name": "link out 17",
        "mode": "link",
        "links": [
            "5ea00c9a686ae28e"
        ],
        "x": 1005,
        "y": 840,
        "wires": []
    },
    {
        "id": "5ea00c9a686ae28e",
        "type": "link in",
        "z": "5cf1d8d919e64156",
        "name": "link in 84",
        "links": [
            "9991ad229f4f64e2"
        ],
        "x": 475,
        "y": 580,
        "wires": [
            [
                "c69d06c109dea856",
                "c476d9264f540db2"
            ]
        ]
    },
    {
        "id": "14a14993620aabd9",
        "type": "function",
        "z": "5cf1d8d919e64156",
        "name": "function 707",
        "func": "msg.payload = {\n    'broker': global.get(\"things.broker\"),\n    'port': global.get(\"things.port\"),\n    'username': global.get(\"things.username\"),\n    'topic': global.get(\"things.topic\"),\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 390,
        "y": 680,
        "wires": [
            [
                "13fd2f7b8d620b8f"
            ]
        ]
    },
    {
        "id": "369e91a543fa6bbf",
        "type": "link out",
        "z": "5cf1d8d919e64156",
        "name": "link out 18",
        "mode": "link",
        "links": [
            "cb54a2c9b7abb89c"
        ],
        "x": 1465,
        "y": 680,
        "wires": []
    },
    {
        "id": "cb54a2c9b7abb89c",
        "type": "link in",
        "z": "5cf1d8d919e64156",
        "name": "link in 85",
        "links": [
            "369e91a543fa6bbf"
        ],
        "x": 275,
        "y": 680,
        "wires": [
            [
                "14a14993620aabd9"
            ]
        ]
    },
    {
        "id": "b6c1ecab704e3189",
        "type": "link out",
        "z": "5cf1d8d919e64156",
        "name": "link out 19",
        "mode": "link",
        "links": [
            "b851e82b9df48d98"
        ],
        "x": 1465,
        "y": 760,
        "wires": []
    },
    {
        "id": "b851e82b9df48d98",
        "type": "link in",
        "z": "5cf1d8d919e64156",
        "name": "link in 86",
        "links": [
            "b6c1ecab704e3189"
        ],
        "x": 275,
        "y": 760,
        "wires": [
            [
                "092513f8399f12ad"
            ]
        ]
    },
    {
        "id": "092513f8399f12ad",
        "type": "function",
        "z": "5cf1d8d919e64156",
        "name": "function 708",
        "func": "msg.payload = {\n    'lcserver': global.get(\"local.lcserver\")\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 390,
        "y": 760,
        "wires": [
            [
                "aab5af8e6aa7da45"
            ]
        ]
    },
    {
        "id": "366b498c1b319bc8",
        "type": "link out",
        "z": "5cf1d8d919e64156",
        "name": "link out 20",
        "mode": "link",
        "links": [
            "daf22a986e604975"
        ],
        "x": 1465,
        "y": 840,
        "wires": []
    },
    {
        "id": "daf22a986e604975",
        "type": "link in",
        "z": "5cf1d8d919e64156",
        "name": "link in 87",
        "links": [
            "366b498c1b319bc8"
        ],
        "x": 275,
        "y": 840,
        "wires": [
            [
                "2d57e240160caff5"
            ]
        ]
    },
    {
        "id": "2d57e240160caff5",
        "type": "function",
        "z": "5cf1d8d919e64156",
        "name": "function 709",
        "func": "msg.payload = {\n    'botToken': global.get(\"bot_token\"),\n    'chatId': global.get(\"chat_id\")\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 390,
        "y": 840,
        "wires": [
            [
                "15c211527512f4a8"
            ]
        ]
    },
    {
        "id": "0fe03920e069b952",
        "type": "fs-file-lister",
        "z": "7fe66403ea1a14c9",
        "name": "file list",
        "start": "/",
        "pattern": "*.*",
        "folders": "*",
        "hidden": true,
        "lstype": "files",
        "path": true,
        "single": true,
        "depth": "0",
        "stat": true,
        "showWarnings": false,
        "x": 170,
        "y": 80,
        "wires": [
            [
                "d07d8a2971351ed4"
            ]
        ]
    },
    {
        "id": "a27a8b5e9e921540",
        "type": "fs-file-lister",
        "z": "7fe66403ea1a14c9",
        "name": "file list",
        "start": "/",
        "pattern": "*.*",
        "folders": "*",
        "hidden": true,
        "lstype": "files",
        "path": true,
        "single": true,
        "depth": "0",
        "stat": true,
        "showWarnings": false,
        "x": 370,
        "y": 80,
        "wires": [
            [
                "6e1e697ce86c43eb"
            ]
        ]
    },
    {
        "id": "d07d8a2971351ed4",
        "type": "function",
        "z": "7fe66403ea1a14c9",
        "name": "path",
        "func": "msg.productFileList = msg.payload.length;\nmsg.payload = msg.pathPower;\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 265,
        "y": 80,
        "wires": [
            [
                "a27a8b5e9e921540"
            ]
        ],
        "l": false
    },
    {
        "id": "6e1e697ce86c43eb",
        "type": "function",
        "z": "7fe66403ea1a14c9",
        "name": "set",
        "func": "global.set(\"local.list.pow\", msg.payload.length);\nmsg.powerFileList = msg.payload.length;\nglobal.set(\"local.list.pro\", msg.productFileList);\n// path Production file list \nmsg.payload = {\"start\": `/home/orangepi/ext/datathingsboard/production/`};\n// path Power file list\nmsg.path_power = { \"start\": `/home/orangepi/powermeter/thingsboard/`};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 475,
        "y": 80,
        "wires": [
            [
                "90d8ee1385ba5dd7"
            ]
        ],
        "l": false
    },
    {
        "id": "90d8ee1385ba5dd7",
        "type": "fs-file-lister",
        "z": "7fe66403ea1a14c9",
        "name": "file list",
        "start": "/",
        "pattern": "*.*",
        "folders": "*",
        "hidden": true,
        "lstype": "files",
        "path": true,
        "single": true,
        "depth": "0",
        "stat": true,
        "showWarnings": false,
        "x": 590,
        "y": 80,
        "wires": [
            [
                "528dce132376567c"
            ]
        ]
    },
    {
        "id": "6796edfb500ec737",
        "type": "fs-file-lister",
        "z": "7fe66403ea1a14c9",
        "name": "file list",
        "start": "/",
        "pattern": "*.*",
        "folders": "*",
        "hidden": true,
        "lstype": "files",
        "path": true,
        "single": true,
        "depth": "0",
        "stat": true,
        "showWarnings": false,
        "x": 790,
        "y": 80,
        "wires": [
            [
                "ced2fb5fb7b6d214"
            ]
        ]
    },
    {
        "id": "528dce132376567c",
        "type": "function",
        "z": "7fe66403ea1a14c9",
        "name": "path",
        "func": "msg.thingsboardProductFileList = msg.payload.length;\nmsg.payload = msg.path_power;\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 685,
        "y": 80,
        "wires": [
            [
                "6796edfb500ec737"
            ]
        ],
        "l": false
    },
    {
        "id": "ced2fb5fb7b6d214",
        "type": "function",
        "z": "7fe66403ea1a14c9",
        "name": "set",
        "func": "global.set(\"things.list.pow\", msg.payload.length);\nglobal.set(\"things.list.pro\", msg.thingsboardProductFileList);\nmsg.payload = {\n    fill: `blue`,\n    shape: `dot`,\n    text: `thingspro: ${msg.thingsboardProductFileList} thingspow: ${msg.payload.length} localpro: ${msg.productFileList} localpow: ${msg.powerFileList}`\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 885,
        "y": 80,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "861f956f24a820d1",
        "type": "file",
        "z": "02f6142c6c7e99bb",
        "name": "config",
        "filename": "/home/orangepi/ext/config.txt.tmp",
        "filenameType": "str",
        "appendNewline": false,
        "createDir": true,
        "overwriteFile": "true",
        "encoding": "utf8",
        "x": 170,
        "y": 60,
        "wires": [
            [
                "529efc0a45b6c9d8"
            ]
        ],
        "icon": "node-red/redis.svg"
    },
    {
        "id": "529efc0a45b6c9d8",
        "type": "exec",
        "z": "02f6142c6c7e99bb",
        "command": ". $HOME/ext/scriptConfig.sh",
        "addpay": "",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "move .tmp",
        "x": 330,
        "y": 80,
        "wires": [
            [],
            [],
            []
        ]
    },
    {
        "id": "b74bb320b5bc3c63",
        "type": "exec",
        "z": "6fa1970c13440cc6",
        "command": "hostname -I",
        "addpay": false,
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "name": "Fetch IP",
        "x": 200,
        "y": 80,
        "wires": [
            [
                "5dd73751e98d7f8b"
            ],
            [],
            []
        ]
    },
    {
        "id": "5dd73751e98d7f8b",
        "type": "function",
        "z": "6fa1970c13440cc6",
        "name": "function 2",
        "func": "let ip = msg.payload.replace(/[\\r\\n\\t ]/g, \"\");\nlet get_ip = global.get(\"IP\");\n    if(get_ip === undefined || ip){\n        global.set(\"IP\", ip);\n    };\nmsg.payload = {\n    fill: \"yellow\",\n    shape: \"ring\",\n    text: `IP:${ip}`\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 360,
        "y": 60,
        "wires": [
            []
        ]
    },
    {
        "id": "bd9c9e92281baaf1",
        "type": "moment",
        "z": "f386491b277c5eef",
        "name": "",
        "topic": "",
        "input": "",
        "inputType": "date",
        "inTz": "Asia/Bangkok",
        "adjAmount": 0,
        "adjType": "days",
        "adjDir": "add",
        "format": "",
        "locale": "en-US",
        "output": "payload",
        "outputType": "msg",
        "outTz": "Asia/Bangkok",
        "x": 125,
        "y": 80,
        "wires": [
            [
                "68173607fb2aaab1"
            ]
        ],
        "l": false
    },
    {
        "id": "68173607fb2aaab1",
        "type": "function",
        "z": "f386491b277c5eef",
        "name": "function 1",
        "func": "var date = new Date(msg.payload);\nlet previousDate = new Date(date); \n    previousDate.setDate(previousDate.getDate() - 1).toString().padStart(2, 0);\nvar year = date.getFullYear(); \nvar month = (date.getMonth() + 1).toString().padStart(2, '0');\nvar day = date.getDate().toString().padStart(2, '0');\nvar hours = date.getHours().toString().padStart(2, '0');\nvar minutes = date.getMinutes().toString().padStart(2, '0');\nvar seconds = date.getSeconds().toString().padStart(2, '0');\nvar dateMian = `${year}/${month}/${day}`;\nvar time = `${hours}:${minutes}:${seconds}`;\nvar datestamp = global.get(\"datestamp\");\nlet hoursNum = Number(hours);\n    globalSet();\n////////////////////////////// end function set date ///////////////////////////////////////\nif (hoursNum >= 8 && hoursNum <= 23) {\n    let dateset = filename(date);\n    var datenow = dateNow(date);\n    global.set(\"date_data\", dateset);\n} else {\n    let dateset = filename(previousDate);\n    var datenow = dateNow(previousDate);\n    global.set(\"date_data\", dateset);\n}\n    global.set(\"shift\", (hoursNum >= 8 && hoursNum <= 19) ? \"A\" : \"B\");\n\nif (datestamp) {\n    if (datenow != datestamp) {\n        resetValues();\n        global.set(\"report\", true);\n        // stamp date\n        global.set(\"datestamp\", datenow);\n    } else {\n        // stamp date\n        global.set(\"datestamp\", datenow);\n    }\n} else {\n    global.set(\"datestamp\", datenow);\n}\n    global.set(\"datenow\", datenow);\n    msg.payload = {\n        fill: \"green\",\n        shape: \"ring\",\n        text: `DATESTAMP:${datestamp} DATE${day}/${month}/${year} TIME:${time}`\n    };\n    return msg;\n\nfunction filename(date){\n    let year = date.getFullYear();\n    let month = (date.getMonth() + 1).toString().padStart(2, '0');\n    let day = date.getDate().toString().padStart(2, '0');\n    return `${year}${month}${day}`;\n}\n\nfunction resetValues(){\n    var energy = new Array(24).fill(0);\n    global.set(\"energy\", energy);\n    var meter = new Array(24).fill(0);\n    global.set(\"meter\", meter);\n\n    global.set(\"temp.mt_in.min\", 0);\n    global.set(\"temp.mt_in.max\", 0);\n    global.set(\"temp.mt_out.min\", 0);\n    global.set(\"temp.mt_out.max\", 0);\n    \n    global.set(\"temp.cl_in.min\", 0);\n    global.set(\"temp.cl_in.max\", 0);\n    global.set(\"temp.cl_out.min\", 0);\n    global.set(\"temp.cl_out.max\", 0);\n\n    global.set(\"speed.scr.min\", 0);\n    global.set(\"speed.scr.max\", 0);\n    global.set(\"speed.hol.min\", 0);\n    global.set(\"speed.hol.max\", 0);\n    global.set(\"speed.ann.min\", 0);\n    global.set(\"speed.ann.max\", 0);\n    global.set(\"speed.str.min\", 0);\n    global.set(\"speed.str.max\", 0);\n}\n\nfunction globalSet(){\n    global.set(\"date\", dateMian);\n    global.set(\"day\", day);\n    global.set(\"month\", month);\n    global.set(\"year\", year);\n    global.set(\"time\", time);\n    global.set(\"hour\", hours);\n    global.set(\"minute\", minutes);\n    global.set(\"second\", seconds);\n}\n\nfunction dateNow(date){\n    let year = date.getFullYear();\n    let month = (date.getMonth() + 1).toString().padStart(2, '0');\n    let day = date.getDate().toString().padStart(2, '0');\n    return `${year}${month}${day}`;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 240,
        "y": 80,
        "wires": [
            []
        ]
    },
    {
        "id": "db6fc316f972fc7a",
        "type": "exec",
        "z": "31057fe0b0d4c1ec",
        "command": "./stat_led/blink.sh",
        "addpay": "payload",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "WeightScale Ready",
        "x": 115,
        "y": 40,
        "wires": [
            [],
            [],
            []
        ],
        "icon": "node-red/light.svg",
        "l": false
    },
    {
        "id": "9d59bd99c742070f",
        "type": "file in",
        "z": "509f550183b44678",
        "name": "Read",
        "filename": "/home/orangepi/ext/config.txt",
        "filenameType": "str",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "utf8",
        "allProps": false,
        "x": 150,
        "y": 40,
        "wires": [
            [
                "1d906f7812c229a3"
            ]
        ],
        "icon": "node-red/sort.svg"
    },
    {
        "id": "1d906f7812c229a3",
        "type": "function",
        "z": "509f550183b44678",
        "name": "function 705",
        "func": "msg.payload = JSON.parse(msg.payload) || [];\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 310,
        "y": 40,
        "wires": [
            []
        ]
    },
    {
        "id": "091181234bd32a1d",
        "type": "catch",
        "z": "509f550183b44678",
        "name": "",
        "scope": [
            "9d59bd99c742070f"
        ],
        "uncaught": false,
        "x": 150,
        "y": 80,
        "wires": [
            [
                "91c9f0db5c183e77"
            ]
        ]
    },
    {
        "id": "91c9f0db5c183e77",
        "type": "file in",
        "z": "509f550183b44678",
        "name": "Read",
        "filename": "/home/orangepi/ext/config.txt.bak",
        "filenameType": "str",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "utf8",
        "allProps": false,
        "x": 290,
        "y": 80,
        "wires": [
            [
                "0bfd0466d7206413"
            ]
        ],
        "icon": "node-red/sort.svg"
    },
    {
        "id": "0bfd0466d7206413",
        "type": "function",
        "z": "509f550183b44678",
        "name": "function 4725",
        "func": "msg.payload = JSON.parse(msg.payload) || [];\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 460,
        "y": 80,
        "wires": [
            [
                "13e5e83fe8bf9607"
            ]
        ]
    },
    {
        "id": "13e5e83fe8bf9607",
        "type": "exec",
        "z": "509f550183b44678",
        "command": "cp $HOME/ext/config.txt.bak $HOME/ext/config.txt",
        "addpay": "",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "repiar config",
        "x": 630,
        "y": 120,
        "wires": [
            [],
            [],
            []
        ]
    },
    {
        "id": "48368b80a493ddf8",
        "type": "switch",
        "z": "db4fabd6a1540331",
        "name": "",
        "property": "payload.list_tb_pow",
        "propertyType": "msg",
        "rules": [
            {
                "t": "eq",
                "v": "0",
                "vt": "str"
            },
            {
                "t": "eq",
                "v": "1",
                "vt": "str"
            }
        ],
        "checkall": "true",
        "repair": false,
        "outputs": 2,
        "x": 135,
        "y": 60,
        "wires": [
            [
                "4c68998f43fcb69b"
            ],
            [
                "b18f8c24443db873"
            ]
        ],
        "l": false
    },
    {
        "id": "4c68998f43fcb69b",
        "type": "function",
        "z": "db4fabd6a1540331",
        "name": "data Log",
        "func": "msg.payload ={\n    date: msg.payload.date,  time: msg.payload.time, timestamp: msg.payload.timestamp,\n    voltageA: msg.payload.voltageA, \n    voltageB: msg.payload.voltageB, \n    voltageC: msg.payload.voltageC,\n    currentA: msg.payload.currentA, \n    currentB: msg.payload.currentB, \n    currentC: msg.payload.currentC,\n    powerA: msg.payload.powerA, \n    powerB: msg.payload.powerB, \n    powerC: msg.payload.powerC,\n    powerfactorA: msg.payload.powerfactorA, \n    powerfactorB: msg.payload.powerfactorB, \n    powerfactorC: msg.payload.powerfactorC,\n    powerpercentageA: msg.payload.powerpercentageA, \n    powerpercentageB: msg.payload.powerpercentageB, \n    powerpercentageC: msg.payload.powerpercentageC, \n    currentpercentageA: msg.payload.currentpercentageA,\n    currentpercentageB: msg.payload.currentpercentageB,\n    currentpercentageC: msg.payload.currentpercentageC,\n    energy_A: msg.payload.energy_A, \n    energy_B: msg.payload.energy_B,\n    energy_min: msg.payload.energy_min,\n    energy_hour: msg.payload.energy_hour,\n    total_energy: msg.payload.total_energy,\n    co2: msg.payload.co2\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 220,
        "y": 40,
        "wires": [
            [
                "21a4319b38ba5b43"
            ]
        ]
    },
    {
        "id": "b18f8c24443db873",
        "type": "function",
        "z": "db4fabd6a1540331",
        "name": "data Log",
        "func": "msg.payload ={\n    date: msg.payload.date,  time: msg.payload.time, timestamp: msg.payload.timestamp,\n    voltageA: msg.payload.voltageA, \n    voltageB: msg.payload.voltageB, \n    voltageC: msg.payload.voltageC,\n    currentA: msg.payload.currentA, \n    currentB: msg.payload.currentB, \n    currentC: msg.payload.currentC,\n    powerA: msg.payload.powerA, \n    powerB: msg.payload.powerB, \n    powerC: msg.payload.powerC,\n    powerfactorA: msg.payload.powerfactorA, \n    powerfactorB: msg.payload.powerfactorB, \n    powerfactorC: msg.payload.powerfactorC,\n    powerpercentageA: msg.payload.powerpercentageA, \n    powerpercentageB: msg.payload.powerpercentageB, \n    powerpercentageC: msg.payload.powerpercentageC, \n    currentpercentageA: msg.payload.currentpercentageA,\n    currentpercentageB: msg.payload.currentpercentageB,\n    currentpercentageC: msg.payload.currentpercentageC,\n    energy_A: msg.payload.energy_A, \n    energy_B: msg.payload.energy_B,\n    energy_min: msg.payload.energy_min,\n    energy_hour: msg.payload.energy_hour,\n    total_energy: msg.payload.total_energy,\n    co2: msg.payload.co2\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 220,
        "y": 80,
        "wires": [
            [
                "53a8089ac98a9c68"
            ]
        ]
    },
    {
        "id": "21a4319b38ba5b43",
        "type": "csv",
        "z": "db4fabd6a1540331",
        "name": "",
        "sep": ",",
        "hdrin": false,
        "hdrout": "all",
        "multi": "one",
        "ret": "\\r\\n",
        "temp": "date,time,timestamp,voltageA,voltageB,voltageC,currentA,currentB,currentC,powerA,powerB,powerC,powerfactorA,powerfactorB,powerfactorC,powerpercentageA,powerpercentageB,powerpercentageC,currentpercentageA,currentpercentageB,currentpercentageC,energy_A,energy_B,energy_min,energy_hour,total_energy,co2",
        "skip": "0",
        "strings": true,
        "include_empty_strings": "",
        "include_null_values": "",
        "x": 315,
        "y": 40,
        "wires": [
            [
                "68d27f2d3f48c562"
            ]
        ],
        "l": false
    },
    {
        "id": "53a8089ac98a9c68",
        "type": "csv",
        "z": "db4fabd6a1540331",
        "name": "",
        "sep": ",",
        "hdrin": "",
        "hdrout": "none",
        "multi": "one",
        "ret": "\\r\\n",
        "temp": "date,time,timestamp,voltageA,voltageB,voltageC,currentA,currentB,currentC,powerA,powerB,powerC,powerfactorA,powerfactorB,powerfactorC,powerpercentageA,powerpercentageB,powerpercentageC,currentpercentageA,currentpercentageB,currentpercentageC,energy_A,energy_B,energy_min,energy_hour,total_energy,co2",
        "skip": "0",
        "strings": true,
        "include_empty_strings": "",
        "include_null_values": "",
        "x": 315,
        "y": 80,
        "wires": [
            [
                "68d27f2d3f48c562"
            ]
        ],
        "l": false
    },
    {
        "id": "68d27f2d3f48c562",
        "type": "file",
        "z": "db4fabd6a1540331",
        "name": "Write",
        "filename": "path_power",
        "filenameType": "msg",
        "appendNewline": false,
        "createDir": true,
        "overwriteFile": "false",
        "encoding": "utf8",
        "x": 375,
        "y": 60,
        "wires": [
            [
                "91601d0950f02f6f"
            ]
        ],
        "l": false
    },
    {
        "id": "7fa0e7e04a825177",
        "type": "file in",
        "z": "db4fabd6a1540331",
        "name": "",
        "filename": "path_power",
        "filenameType": "msg",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "none",
        "allProps": false,
        "x": 495,
        "y": 60,
        "wires": [
            [
                "b46642c65dc7f3ca"
            ]
        ],
        "l": false
    },
    {
        "id": "91601d0950f02f6f",
        "type": "delay",
        "z": "db4fabd6a1540331",
        "name": "",
        "pauseType": "delay",
        "timeout": "50",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 435,
        "y": 60,
        "wires": [
            [
                "7fa0e7e04a825177"
            ]
        ],
        "l": false
    },
    {
        "id": "b46642c65dc7f3ca",
        "type": "csv",
        "z": "db4fabd6a1540331",
        "name": "",
        "sep": ",",
        "hdrin": "",
        "hdrout": "none",
        "multi": "mult",
        "ret": "\\n",
        "temp": "",
        "skip": "0",
        "strings": true,
        "include_empty_strings": "",
        "include_null_values": "",
        "x": 555,
        "y": 60,
        "wires": [
            [
                "e3d8f6657de33357"
            ]
        ],
        "l": false
    },
    {
        "id": "e3d8f6657de33357",
        "type": "function",
        "z": "db4fabd6a1540331",
        "name": "le",
        "func": "var length = msg.payload.length\nlength = length - 1\nglobal.set(\"things.row.pow\", length)\nmsg.payload = {\n    fill: \"blue\",\n    shape: \"dot\",\n    text: `row ${length}`\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 615,
        "y": 60,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "66f48e5b501373bc",
        "type": "function",
        "z": "db4fabd6a1540331",
        "name": "data Log",
        "func": "msg.report_thingsboard = `/home/orangepi/powermeter/report_thingsboard/${global.get(\"date_data\")}.csv`;\n\nlet energy = global.get(\"energy\");\nlet dateString = global.get(\"date_data\");\nlet year = dateString.substring(0, 4);\nlet month = dateString.substring(4, 6) - 1;\nlet day = dateString.substring(6, 8);\n// สร้าง Date object พร้อมเวลา\nlet date = new Date(year, month, day, 7, 59, 0); // เวลา 07:59:00\n// แปลงเป็น timestamp (milliseconds)\nlet timestamp = date.getTime();\nmsg.payload = {\n    timestamp: timestamp,\n    ...Object.fromEntries(energy.map((value, index) => [`energy${index}`, value])),\n    energy_A: msg.payload.energy_A, \n    energy_B: msg.payload.energy_B,\n    total_energy: parseFloat(msg.payload.total_energy).toFixed(3),\n    co2: parseFloat(msg.payload.co2).toFixed(3)\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 220,
        "y": 120,
        "wires": [
            [
                "d521fd0ebba71aca"
            ]
        ]
    },
    {
        "id": "d521fd0ebba71aca",
        "type": "csv",
        "z": "db4fabd6a1540331",
        "name": "",
        "sep": ",",
        "hdrin": false,
        "hdrout": "all",
        "multi": "one",
        "ret": "\\r\\n",
        "temp": "timestamp,energy0, energy1, energy2, energy3, energy4, energy5, energy6,energy7, energy8, energy9, energy10, energy11, energy12, energy13,     energy14, energy15, energy16, energy17, energy18, energy19, energy20,     energy21, energy22, energy23, energy_A, energy_B, total_energy,co2",
        "skip": "0",
        "strings": true,
        "include_empty_strings": "",
        "include_null_values": "",
        "x": 325,
        "y": 120,
        "wires": [
            [
                "2765a0fe436151cb"
            ]
        ],
        "l": false
    },
    {
        "id": "2765a0fe436151cb",
        "type": "file",
        "z": "db4fabd6a1540331",
        "name": "Write",
        "filename": "report_thingsboard",
        "filenameType": "msg",
        "appendNewline": false,
        "createDir": true,
        "overwriteFile": "true",
        "encoding": "utf8",
        "x": 385,
        "y": 120,
        "wires": [
            [
                "0af3757be4333dd1"
            ]
        ],
        "l": false
    },
    {
        "id": "58ac2f95d7dd0014",
        "type": "file in",
        "z": "db4fabd6a1540331",
        "name": "",
        "filename": "report_thingsboard",
        "filenameType": "msg",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "none",
        "allProps": false,
        "x": 505,
        "y": 120,
        "wires": [
            [
                "220d71fdaf921789"
            ]
        ],
        "l": false
    },
    {
        "id": "0af3757be4333dd1",
        "type": "delay",
        "z": "db4fabd6a1540331",
        "name": "",
        "pauseType": "delay",
        "timeout": "50",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 445,
        "y": 120,
        "wires": [
            [
                "58ac2f95d7dd0014"
            ]
        ],
        "l": false
    },
    {
        "id": "220d71fdaf921789",
        "type": "csv",
        "z": "db4fabd6a1540331",
        "name": "",
        "sep": ",",
        "hdrin": "",
        "hdrout": "none",
        "multi": "mult",
        "ret": "\\n",
        "temp": "",
        "skip": "0",
        "strings": true,
        "include_empty_strings": "",
        "include_null_values": "",
        "x": 565,
        "y": 120,
        "wires": [
            [
                "a4ab60f626f19a7b"
            ]
        ],
        "l": false
    },
    {
        "id": "a4ab60f626f19a7b",
        "type": "function",
        "z": "db4fabd6a1540331",
        "name": "le",
        "func": "var length = msg.payload.length\nlength = length - 1\nglobal.set(\"row_ReportThingsboard\", length)\nmsg.payload = {\n    fill: \"blue\",\n    shape: \"dot\",\n    text: `row ${length}`\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 625,
        "y": 120,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "41f5532d4a7103fe",
        "type": "function",
        "z": "2475655a38fb291d",
        "name": "delete",
        "func": "let rowthingsboard = global.get(\"things.row.pow\") || 0;\nlet indexthingsboard = global.get(\"things.index.pow\") || 0;\nif((rowthingsboard >= 1000) && (indexthingsboard === rowthingsboard) ){\n    return msg;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 190,
        "y": 20,
        "wires": [
            [
                "d8619bc53b98f588"
            ]
        ]
    },
    {
        "id": "d8619bc53b98f588",
        "type": "exec",
        "z": "2475655a38fb291d",
        "command": "rm /home/orangepi/powermeter/thingsboard/log_thingsboard.csv",
        "addpay": "",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "rm",
        "x": 350,
        "y": 40,
        "wires": [
            [],
            [],
            []
        ]
    },
    {
        "id": "71af026a4f564a9b",
        "type": "http request",
        "z": "a64e2ac5a1b6390b",
        "name": "ThingBoards",
        "method": "POST",
        "ret": "txt",
        "paytoqs": "ignore",
        "url": "",
        "tls": "",
        "persist": false,
        "proxy": "",
        "insecureHTTPParser": false,
        "authType": "",
        "senderr": false,
        "headers": [],
        "x": 210,
        "y": 80,
        "wires": [
            [
                "02fcc1765deebed1"
            ]
        ]
    },
    {
        "id": "02fcc1765deebed1",
        "type": "function",
        "z": "a64e2ac5a1b6390b",
        "name": "function 645",
        "func": "var statusCode = msg.statusCode\nvar index = global.get(\"things.index.pow\") || 0\n\nif (statusCode === 200){\n    index = index + 1\n    global.set(\"things.index.pow\", index)\n}\nmsg.payload = {\n    fill: \"blue\",\n    shape: \"dot\",\n    text: `index: ${index} time success:${global.get(\"time\")} | CODE: ${statusCode}`\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 345,
        "y": 80,
        "wires": [
            [
                "70a615300af80bf9",
                "70a4832a4231f295"
            ]
        ],
        "icon": "font-awesome/fa-check",
        "l": false
    },
    {
        "id": "70a615300af80bf9",
        "type": "subflow:2475655a38fb291d",
        "z": "a64e2ac5a1b6390b",
        "name": "",
        "x": 500,
        "y": 120,
        "wires": []
    },
    {
        "id": "41047c8f89e6fccf",
        "type": "function",
        "z": "a64e2ac5a1b6390b",
        "name": "read",
        "func": "let payload = msg.payload[0];\n\n// สร้างออบเจ็กต์ค่าพลังงานโดยใช้ลูป\nlet energyValues = {};\nfor (let i = 0; i < 24; i++) {\n    let hour = i < 10 ? `0${i}` : `${i}`;  // เพิ่มเลขศูนย์นำหน้าเวลาที่น้อยกว่า 10\n    let key = `energy${i}`;\n    energyValues[`${hour}:00`] = payload[key];\n}\n\n// สร้างออบเจ็กต์ผลลัพธ์ที่ต้องการ\nmsg.url = `http://${global.get(\"server\")}/api/v1/${global.get(\"token\")}/telemetry`;\nconst obj = {\n    ts: payload.timestamp,\n    values: {\n        total_energy_day: Number(payload.total_energy || 0),\n        total_co2_day: Number(payload.co2 || 0),\n        ...energyValues  // เพิ่มข้อมูลพลังงานที่สร้างจากลูป\n    }\n};\n\nmsg.payload = obj;\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 910,
        "y": 40,
        "wires": [
            [
                "31aaf3b868a6ae8e"
            ]
        ]
    },
    {
        "id": "70a4832a4231f295",
        "type": "function",
        "z": "a64e2ac5a1b6390b",
        "name": "loop",
        "func": "var report = global.get(\"report\");\nif (report){\n    return msg;\n};",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 450,
        "y": 40,
        "wires": [
            [
                "50b97f84505a62ea"
            ]
        ]
    },
    {
        "id": "31aaf3b868a6ae8e",
        "type": "http request",
        "z": "a64e2ac5a1b6390b",
        "name": "ThingBoards",
        "method": "POST",
        "ret": "txt",
        "paytoqs": "ignore",
        "url": "",
        "tls": "",
        "persist": false,
        "proxy": "",
        "insecureHTTPParser": false,
        "authType": "",
        "senderr": false,
        "headers": [],
        "x": 1070,
        "y": 40,
        "wires": [
            [
                "00fb0451e85afc9f"
            ]
        ]
    },
    {
        "id": "00fb0451e85afc9f",
        "type": "function",
        "z": "a64e2ac5a1b6390b",
        "name": "function 4",
        "func": "var statusCode = msg.statusCode;\nif (statusCode === 200){\n    msg.rm = `rm /home/orangepi/powermeter/report_thingsboard/${msg.fileremove}`;\n    return msg\n};",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 1205,
        "y": 40,
        "wires": [
            [
                "1bcec44d80140f9d"
            ]
        ],
        "icon": "font-awesome/fa-check",
        "l": false
    },
    {
        "id": "50b97f84505a62ea",
        "type": "fs-file-lister",
        "z": "a64e2ac5a1b6390b",
        "name": "",
        "start": "/home/orangepi/powermeter/report_thingsboard/",
        "pattern": "*.*",
        "folders": "*",
        "hidden": true,
        "lstype": "files",
        "path": true,
        "single": true,
        "depth": "0",
        "stat": true,
        "showWarnings": false,
        "x": 545,
        "y": 40,
        "wires": [
            [
                "a704de9912fd8786"
            ]
        ],
        "l": false
    },
    {
        "id": "a704de9912fd8786",
        "type": "function",
        "z": "a64e2ac5a1b6390b",
        "name": "name",
        "func": "var datenow = `${global.get(\"datenow\")}.csv`;\nvar obj = msg.payload[0].name;\nvar parts = obj.split(\"/\");\nvar filereport = parts[5];\nmsg.filereport = \"/home/orangepi/powermeter/report_thingsboard/\" + filereport;\nmsg.fileremove = filereport;\nnode.status({ fill: \"yellow\", shape: \"ring\", text: \"remove: \" + filereport });\nif (datenow != filereport) {\n    return msg;\n}else {\n    global.set(\"loop\", false);\n};",
        "outputs": 1,
        "timeout": "",
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 650,
        "y": 40,
        "wires": [
            [
                "86ccd62866eec912"
            ]
        ]
    },
    {
        "id": "86ccd62866eec912",
        "type": "file in",
        "z": "a64e2ac5a1b6390b",
        "name": "",
        "filename": "filereport",
        "filenameType": "msg",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "utf8",
        "allProps": false,
        "x": 745,
        "y": 40,
        "wires": [
            [
                "93a0681b7b4d2012"
            ]
        ],
        "l": false
    },
    {
        "id": "93a0681b7b4d2012",
        "type": "csv",
        "z": "a64e2ac5a1b6390b",
        "name": "",
        "sep": ",",
        "hdrin": true,
        "hdrout": "",
        "multi": "mult",
        "ret": "\\r\\n",
        "temp": "",
        "skip": "0",
        "strings": true,
        "include_empty_strings": false,
        "include_null_values": false,
        "x": 805,
        "y": 40,
        "wires": [
            [
                "41047c8f89e6fccf"
            ]
        ],
        "l": false
    },
    {
        "id": "1bcec44d80140f9d",
        "type": "exec",
        "z": "a64e2ac5a1b6390b",
        "command": "",
        "addpay": "rm",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "",
        "x": 1310,
        "y": 40,
        "wires": [
            [],
            [],
            []
        ]
    },
    {
        "id": "bd7abb7d25a89c27",
        "type": "function",
        "z": "2bafb72664960be0",
        "name": "Index/Con.",
        "func": "var rowthingsboard = global.get(\"things.row.pow\") || 0;\nvar indexthingsboard = global.get(\"things.index.pow\") || 0;\n\nif (indexthingsboard < rowthingsboard){\n    msg.path = `/home/orangepi/powermeter/thingsboard/log_power.csv`;\n    node.status({ fill: \"blue\", shape: \"dot\", text: `index:${indexthingsboard} < row:${rowthingsboard} `});\n    return msg;\n}else{\n    node.status({ fill: \"blue\", shape: \"dot\", text: `index:${indexthingsboard} = row:${rowthingsboard} ` });\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 210,
        "y": 100,
        "wires": [
            [
                "30a4fbc321f74c21"
            ]
        ],
        "icon": "node-red/cog.svg"
    },
    {
        "id": "30a4fbc321f74c21",
        "type": "file in",
        "z": "2bafb72664960be0",
        "name": "",
        "filename": "path",
        "filenameType": "msg",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "utf8",
        "allProps": false,
        "x": 380,
        "y": 100,
        "wires": [
            [
                "d4423d018ce4f524"
            ]
        ]
    },
    {
        "id": "d4423d018ce4f524",
        "type": "csv",
        "z": "2bafb72664960be0",
        "name": "",
        "sep": ",",
        "hdrin": true,
        "hdrout": "",
        "multi": "mult",
        "ret": "\\r\\n",
        "temp": "",
        "skip": "0",
        "strings": true,
        "include_empty_strings": false,
        "include_null_values": false,
        "x": 485,
        "y": 100,
        "wires": [
            [
                "b525daa1de310d5c",
                "393b596221693772"
            ]
        ],
        "l": false
    },
    {
        "id": "b525daa1de310d5c",
        "type": "function",
        "z": "2bafb72664960be0",
        "name": "function 644",
        "func": "var index = global.get(\"things.index.pow\") || 0;\nvar date = msg.payload[index].date;\nvar time = msg.payload[index].time;\nvar timestamp = msg.payload[index].timestamp;\nvar voltageA = msg.payload[index].voltageA;\nvar voltageB = msg.payload[index].voltageB;\nvar voltageC = msg.payload[index].voltageC;\nvar currentA = msg.payload[index].currentA;\nvar currentB = msg.payload[index].currentB;\nvar currentC = msg.payload[index].currentC;\nvar powerA = msg.payload[index].powerA;\nvar powerB = msg.payload[index].powerB;\nvar powerC = msg.payload[index].powerC;\nvar powerfactorA = msg.payload[index].powerfactorA;\nvar powerfactorB = msg.payload[index].powerfactorB;\nvar powerfactorC = msg.payload[index].powerfactorC;\nvar powerpercentageA = msg.payload[index].powerpercentageA;\nvar powerpercentageB = msg.payload[index].powerpercentageB;\nvar powerpercentageC = msg.payload[index].powerpercentageC;\nvar currentpercentageA = msg.payload[index].currentpercentageA;\nvar currentpercentageB = msg.payload[index].currentpercentageB;\nvar currentpercentageC = msg.payload[index].currentpercentageC;\nvar energy_A = msg.payload[index].energy_A;\nvar energy_B = msg.payload[index].energy_B;\nvar total_energy = msg.payload[index].total_energy;\nvar energy_hour = msg.payload[index].energy_hour;\nvar energy_min = msg.payload[index].energy_min;\nvar co2 = msg.payload[index].co2\nmsg.url = `http://${global.get(\"server\")}/api/v1/${global.get(\"token\")}/telemetry`;\n\nconst obj = {\n    \"ts\": timestamp,\n    \"values\": {\n    date : date,\n    time : time,\n    voltageA: voltageA,\n    voltageB: voltageB,\n    voltageC: voltageC,\n    currentA: currentA,\n    currentB: currentB,\n    currentC: currentC,\n    powerA: powerA,\n    powerB: powerB,\n    powerC: powerC,\n    powerfactorA : powerfactorA,\n    powerfactorB : powerfactorB,\n    powerfactorC : powerfactorC,\n    currentpercentageA: currentpercentageA,\n    currentpercentageB: currentpercentageB,\n    currentpercentageC: currentpercentageC,\n    powerpercentageA: powerpercentageA,\n    powerpercentageB: powerpercentageB,\n    powerpercentageC: powerpercentageC,\n    energy_A: energy_A,\n    energy_B: energy_B,\n    energy_hour: energy_hour,\n    energy_min: energy_min,\n    total_energy: total_energy,\n    co2: co2\n    }\n};\nconst myJSON = JSON.stringify(obj);\nmsg.payload = myJSON;\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 610,
        "y": 100,
        "wires": [
            []
        ]
    },
    {
        "id": "393b596221693772",
        "type": "function",
        "z": "2bafb72664960be0",
        "name": "function 5",
        "func": "let time = msg.payload[global.get(\"things.index.pow\")].time;\nnode.status({ fill: \"blue\", shape: \"ring\", text: time});\nmsg.payload = {\n    fill: \"blue\",\n    shape: \"dot\", \n    text: time\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 600,
        "y": 40,
        "wires": [
            []
        ]
    },
    {
        "id": "408a08ee9acadf58",
        "type": "function",
        "z": "4f0fd70632b3c011",
        "name": "percentage",
        "func": "let volt = flow.get(\"volt_\");\nlet current = flow.get(\"current_\");\nlet powerp = flow.get(\"powerp_\");\nlet powerfactor = flow.get(\"powerf_\");\nlet energy = flow.get(\"true_energy\");\n\nvar percentage_currentA, percentage_currentB, percentage_currentC;\nvar currentA = flow.get(\"current_.0\");\nvar currentB = flow.get(\"current_.1\");\nvar currentC = flow.get(\"current_.2\");\nvar percentage_powerA, percentage_powerB, percentage_powerC;\nvar powerA = flow.get(\"power_.0\");\nvar powerB = flow.get(\"power_.1\");\nvar powerC = flow.get(\"power_.2\");\n\n// var total_energy = Number(parseFloat(Number(energyA) + Number(energyB) + Number(energyC)).toFixed(1));\nvar total_power = Number(parseFloat(Number(powerA) + Number(powerB) + Number(powerC)).toFixed(3));\nif(powerA && powerB && powerC){\n     percentage_powerA = parseFloat((Number(powerA) / Number(total_power)) * 100).toFixed(1);\n     percentage_powerB = parseFloat((Number(powerB) / Number(total_power)) * 100).toFixed(1);\n     percentage_powerC = parseFloat((Number(powerC) / Number(total_power)) * 100).toFixed(1);\n}else{\n     percentage_powerA = 0;\n     percentage_powerB = 0;\n     percentage_powerC = 0;\n}\n\nvar total_current = Number(parseFloat(Number(currentA) + Number(currentB) + Number(currentC)).toFixed(2));\nif (currentA && currentB && currentC) {\n    percentage_currentA = parseFloat((Number(currentA) / Number(total_current)) * 100).toFixed(1);\n    percentage_currentB = parseFloat((Number(currentB) / Number(total_current)) * 100).toFixed(1);\n    percentage_currentC = parseFloat((Number(currentC) / Number(total_current)) * 100).toFixed(1);\n} else {\n    percentage_currentA = 0;\n    percentage_currentB = 0;\n    percentage_currentC = 0;\n}\nvar timestamp_res = flow.get(\"timestamp_res\");\n\nmsg.payload = {\n    'ts_res': timestamp_res,\n    'volt':{\n        'A': volt[0], \n        'B': volt[1], \n        'C': volt[2]\n    },\n    'current':{\n         'A': currentA, \n         'B': currentB, \n         'C': currentC\n    },\n    'power':{\n         'A': powerA, \n         'B': powerB, \n         'C': powerC\n    },\n    // 'energy':{\n    //     'A': energyA, \n    //     'B': energyB, \n    //     'C': energyC\n    // },\n    'powerfactor':{\n        'A': powerfactor[0], \n        'B': powerfactor[1], \n        'C': powerfactor[2]\n    },\n    'percentage':{\n        'power':{\n            'A': percentage_powerA,\n            'B': percentage_powerB,\n            'C': percentage_powerC\n        },\n        'current': {\n            'A': percentage_currentA,\n            'B': percentage_currentB,\n            'C': percentage_currentC\n        }\n    },\n    'total':{\n        'energy_stack': energy,\n        'power': total_power,\n        'current': total_current,\n    }\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 330,
        "y": 80,
        "wires": [
            []
        ]
    },
    {
        "id": "73252c97d335b6c6",
        "type": "function",
        "z": "4f0fd70632b3c011",
        "name": "total_energy",
        "func": "var input = msg.payload\nconst output = toUint32(input)\nmsg.payload = output[0]\nflow.set(\"true_energy\", output[0])\n\nfunction toUint32(data) {\n    const voltages = [];\n    for (let i = 0; i < data.length; i += 2) {\n        // รวมค่า 16 บิตจาก data[i] และ data[i + 1] ให้เป็น 32 บิต\n        const combined = (data[i] << 16) | data[i + 1];\n\n        // ตรวจสอบผลลัพธ์จากการรวมค่า\n        voltages.push(combined);\n    }\n    return voltages;\n}\nflow.set(\"timestamp_res\", global.get(\"timestamp\"));",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 470,
        "y": 560,
        "wires": [
            []
        ]
    },
    {
        "id": "9d6e5d47ad61f81c",
        "type": "modbus-response",
        "z": "4f0fd70632b3c011",
        "name": "",
        "registerShowMax": "2",
        "x": 490,
        "y": 520,
        "wires": []
    },
    {
        "id": "540c1cad940dcdbf",
        "type": "modbus-response",
        "z": "4f0fd70632b3c011",
        "name": "",
        "registerShowMax": "6",
        "x": 490,
        "y": 200,
        "wires": []
    },
    {
        "id": "63036ac46ca642a4",
        "type": "function",
        "z": "4f0fd70632b3c011",
        "name": "Current",
        "func": "var input = msg.payload\nconst output = toFloat32(input)\nmsg.payload = output\nflow.set(\"current_\",output);\n\nfunction toFloat32(data) {\n    const voltages = [];\n    for (let i = 0; i < data.length; i += 2) {\n        const combined = (data[i] << 16) | (data[i + 1]);\n        const float32Array = new Float32Array(1);\n        const int32Array = new Int32Array(float32Array.buffer);\n        int32Array[0] = combined;\n        voltages.push(float32Array[0].toFixed(2));\n    }\n    return voltages;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 460,
        "y": 240,
        "wires": [
            []
        ]
    },
    {
        "id": "739ec078eae5eb70",
        "type": "function",
        "z": "4f0fd70632b3c011",
        "name": "Voltage",
        "func": "var input = msg.payload\nconst output = toFloat32(input)\nmsg.payload = output\nflow.set(\"volt_\", output);\n\nfunction toFloat32(data) {\n    const voltages = [];\n    for (let i = 0; i < data.length; i += 2) {\n        const combined = (data[i] << 16) | (data[i + 1]);\n        const float32Array1 = new Float32Array(1);\n        const int32Array = new Int32Array(float32Array1.buffer);\n        int32Array[0] = combined;\n        voltages.push(float32Array1[0].toFixed(2));\n    }\n    return voltages;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 460,
        "y": 160,
        "wires": [
            []
        ]
    },
    {
        "id": "e0cadc065353599c",
        "type": "modbus-response",
        "z": "4f0fd70632b3c011",
        "name": "",
        "registerShowMax": "6",
        "x": 490,
        "y": 120,
        "wires": []
    },
    {
        "id": "55982cca013f3905",
        "type": "function",
        "z": "4f0fd70632b3c011",
        "name": "Power",
        "func": "var input = msg.payload\nconst output = toFloat32(input)\nmsg.payload = output\nflow.set(\"powerp_\", output);\n\nfunction toFloat32(data) {\n    const voltages = [];\n    for (let i = 0; i < data.length; i += 2) {\n        const combined = (data[i] << 16) | (data[i + 1]);\n        const float32Array2 = new Float32Array(1);\n        const int32Array = new Int32Array(float32Array2.buffer);\n        int32Array[0] = combined;\n        voltages.push(float32Array2[0].toFixed(2));\n    }\n    return voltages;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 450,
        "y": 320,
        "wires": [
            []
        ]
    },
    {
        "id": "268b0f47a412bf6b",
        "type": "modbus-response",
        "z": "4f0fd70632b3c011",
        "name": "",
        "registerShowMax": "6",
        "x": 490,
        "y": 280,
        "wires": []
    },
    {
        "id": "fd0794e605fbfd55",
        "type": "modbus-response",
        "z": "4f0fd70632b3c011",
        "name": "",
        "registerShowMax": "6",
        "x": 490,
        "y": 360,
        "wires": []
    },
    {
        "id": "47b638804cbfcbf5",
        "type": "function",
        "z": "4f0fd70632b3c011",
        "name": "Powerfactor",
        "func": "var input = msg.payload\nconst output = toFloat32(input)\nmsg.payload = output\nflow.set(\"powerf_\", output);\n\nfunction toFloat32(data) {\n    const voltages = [];\n    for (let i = 0; i < data.length; i += 2) {\n        const combined = (data[i] << 16) | (data[i + 1]);\n        const float32Array3 = new Float32Array(1);\n        const int32Array = new Int32Array(float32Array3.buffer);\n        int32Array[0] = combined;\n        voltages.push(float32Array3[0].toFixed(2));\n    }\n    return voltages;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 470,
        "y": 400,
        "wires": [
            []
        ]
    },
    {
        "id": "1e9d3ebb5e47fae3",
        "type": "modbus-response",
        "z": "4f0fd70632b3c011",
        "name": "",
        "registerShowMax": "6",
        "x": 490,
        "y": 440,
        "wires": []
    },
    {
        "id": "e59bd4f33361a5ad",
        "type": "function",
        "z": "4f0fd70632b3c011",
        "name": "Energy",
        "func": "var input = msg.payload;\nconst output = toUint32(input);\nmsg.payload = output;\nflow.set(\"total_energy\", output[0]);\n\nfunction toUint32(data) {\n    const voltages = [];\n    for (let i = 0; i < data.length; i += 2) {\n        // ผสมค่าจากสองไบต์ โดยไบต์แรกคือ MSB และไบต์ที่สองคือ LSB\n        const combined = (data[i] << 8) | data[i + 1];\n        voltages.push(combined); // ไม่ต้องแปลงเป็น Float\n    }\n    return voltages;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 460,
        "y": 480,
        "wires": [
            []
        ]
    },
    {
        "id": "60b47940cc463d14",
        "type": "modbus-flex-getter",
        "z": "4f0fd70632b3c011",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 365,
        "y": 230,
        "wires": [
            [
                "540c1cad940dcdbf",
                "63036ac46ca642a4"
            ],
            []
        ],
        "l": false
    },
    {
        "id": "03a5a292b0fb2180",
        "type": "modbus-flex-getter",
        "z": "4f0fd70632b3c011",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 365,
        "y": 150,
        "wires": [
            [
                "739ec078eae5eb70",
                "e0cadc065353599c"
            ],
            []
        ],
        "l": false
    },
    {
        "id": "9634affc4eda446c",
        "type": "modbus-flex-getter",
        "z": "4f0fd70632b3c011",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 365,
        "y": 310,
        "wires": [
            [
                "55982cca013f3905",
                "268b0f47a412bf6b"
            ],
            []
        ],
        "l": false
    },
    {
        "id": "685a9ae9cd0480a0",
        "type": "modbus-flex-getter",
        "z": "4f0fd70632b3c011",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 365,
        "y": 390,
        "wires": [
            [
                "fd0794e605fbfd55",
                "47b638804cbfcbf5"
            ],
            []
        ],
        "l": false
    },
    {
        "id": "506e62597f11dbc0",
        "type": "modbus-flex-getter",
        "z": "4f0fd70632b3c011",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 365,
        "y": 470,
        "wires": [
            [
                "1e9d3ebb5e47fae3",
                "e59bd4f33361a5ad"
            ],
            []
        ],
        "l": false
    },
    {
        "id": "9d0382eb7add361f",
        "type": "function",
        "z": "4f0fd70632b3c011",
        "name": "input",
        "func": "let unidID = msg.unitid;\n\nmsg.payload = {\n    value: '',\n    unitid: unidID,\n    fc: 3,\n    address: 1010,\n    quantity: 6\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 250,
        "y": 150,
        "wires": [
            [
                "03a5a292b0fb2180",
                "a543e66a7ff6fad4"
            ]
        ]
    },
    {
        "id": "2c02f5d4d7ed34f8",
        "type": "function",
        "z": "4f0fd70632b3c011",
        "name": "input",
        "func": "let unidID = msg.payload.unitid;\n\nmsg.payload = {\n    value: '',\n    unitid: unidID,\n    fc: 3,\n    address: 1000,\n    quantity: 6\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 250,
        "y": 230,
        "wires": [
            [
                "60b47940cc463d14",
                "c726bd05942d6432"
            ]
        ]
    },
    {
        "id": "a543e66a7ff6fad4",
        "type": "delay",
        "z": "4f0fd70632b3c011",
        "name": "",
        "pauseType": "delay",
        "timeout": "100",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "2",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": true,
        "allowrate": false,
        "outputs": 1,
        "x": 155,
        "y": 230,
        "wires": [
            [
                "2c02f5d4d7ed34f8"
            ]
        ],
        "l": false
    },
    {
        "id": "5096ee1813c0e8ce",
        "type": "function",
        "z": "4f0fd70632b3c011",
        "name": "input",
        "func": "let unidID = msg.payload.unitid;\n\nmsg.payload = {\n    value: '',\n    unitid: unidID,\n    fc: 3,\n    address: 1028,\n    quantity: 6\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 250,
        "y": 310,
        "wires": [
            [
                "9634affc4eda446c",
                "9b0c42b8cd6584b0"
            ]
        ]
    },
    {
        "id": "c726bd05942d6432",
        "type": "delay",
        "z": "4f0fd70632b3c011",
        "name": "",
        "pauseType": "delay",
        "timeout": "100",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "2",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": true,
        "allowrate": false,
        "outputs": 1,
        "x": 155,
        "y": 310,
        "wires": [
            [
                "5096ee1813c0e8ce"
            ]
        ],
        "l": false
    },
    {
        "id": "1786e0cfdb2eee21",
        "type": "function",
        "z": "4f0fd70632b3c011",
        "name": "input",
        "func": "let unidID = msg.payload.unitid;\n\nmsg.payload = {\n    value: '',\n    unitid: unidID,\n    fc: 3,\n    address: 1052,\n    quantity: 6\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 250,
        "y": 390,
        "wires": [
            [
                "685a9ae9cd0480a0",
                "a2ab30f91bd6bdd1"
            ]
        ]
    },
    {
        "id": "9b0c42b8cd6584b0",
        "type": "delay",
        "z": "4f0fd70632b3c011",
        "name": "",
        "pauseType": "delay",
        "timeout": "100",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "2",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": true,
        "allowrate": false,
        "outputs": 1,
        "x": 155,
        "y": 390,
        "wires": [
            [
                "1786e0cfdb2eee21"
            ]
        ],
        "l": false
    },
    {
        "id": "815cd66e038c4369",
        "type": "function",
        "z": "4f0fd70632b3c011",
        "name": "input",
        "func": "let unidID = msg.payload.unitid;\n\nmsg.payload = {\n    value: '',\n    unitid: unidID,\n    fc: 3,\n    address: 2606,\n    quantity: 2\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 250,
        "y": 470,
        "wires": [
            [
                "506e62597f11dbc0",
                "70c47df067df8a78"
            ]
        ]
    },
    {
        "id": "a2ab30f91bd6bdd1",
        "type": "delay",
        "z": "4f0fd70632b3c011",
        "name": "",
        "pauseType": "delay",
        "timeout": "100",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "2",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": true,
        "allowrate": false,
        "outputs": 1,
        "x": 155,
        "y": 470,
        "wires": [
            [
                "815cd66e038c4369"
            ]
        ],
        "l": false
    },
    {
        "id": "735376b235eb757e",
        "type": "function",
        "z": "4f0fd70632b3c011",
        "name": "input",
        "func": "let unidID = msg.payload.unitid;\n\nmsg.payload = {\n    value: '',\n    unitid: unidID,\n    fc: 3,\n    address: 2606,\n    quantity: 2\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 250,
        "y": 550,
        "wires": [
            [
                "38a0c33a11a7cd6b"
            ]
        ]
    },
    {
        "id": "70c47df067df8a78",
        "type": "delay",
        "z": "4f0fd70632b3c011",
        "name": "",
        "pauseType": "delay",
        "timeout": "100",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "2",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": true,
        "allowrate": false,
        "outputs": 1,
        "x": 155,
        "y": 550,
        "wires": [
            [
                "735376b235eb757e"
            ]
        ],
        "l": false
    },
    {
        "id": "38a0c33a11a7cd6b",
        "type": "modbus-flex-getter",
        "z": "4f0fd70632b3c011",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 365,
        "y": 550,
        "wires": [
            [
                "73252c97d335b6c6",
                "9d6e5d47ad61f81c"
            ],
            []
        ],
        "l": false
    },
    {
        "id": "08092ba982aebf66",
        "type": "delay",
        "z": "4f0fd70632b3c011",
        "name": "",
        "pauseType": "delay",
        "timeout": "700",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "2",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": true,
        "allowrate": false,
        "outputs": 1,
        "x": 225,
        "y": 100,
        "wires": [
            [
                "408a08ee9acadf58"
            ]
        ],
        "l": false
    },
    {
        "id": "633e9c4b40e42584",
        "type": "ping",
        "z": "13f006802899e0be",
        "protocol": "IPv4",
        "mode": "triggered",
        "name": "",
        "host": "",
        "timer": "10",
        "inputs": 1,
        "x": 135,
        "y": 80,
        "wires": [
            [
                "5805fc6c631c073d"
            ]
        ],
        "l": false
    },
    {
        "id": "5805fc6c631c073d",
        "type": "function",
        "z": "13f006802899e0be",
        "name": "function 684",
        "func": "global.set(\"local.connection\", (msg.payload) ? true : false);\nmsg.payload = global.get(\"things.broker\");\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 250,
        "y": 80,
        "wires": [
            [
                "368282a3c6c7686a"
            ]
        ]
    },
    {
        "id": "2caed5e8c38011f9",
        "type": "function",
        "z": "13f006802899e0be",
        "name": "function 685",
        "func": "global.set(\"things.connection\", (msg.payload) ? true : false);\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 490,
        "y": 80,
        "wires": [
            [
                "346948538b2e924a",
                "c7fcb9a183a78340"
            ]
        ]
    },
    {
        "id": "346948538b2e924a",
        "type": "function",
        "z": "13f006802899e0be",
        "name": "function 686",
        "func": "var sho2 = `[${global.get(\"time\")}] C1:${global.get(\"local.connection\")} C2:${global.get(\"things.connection\")}`;\nmsg.payload = {\n    \"fill\": \"blue\",\n    \"shape\": \"dot\",\n    \"text\": sho2\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 690,
        "y": 140,
        "wires": [
            []
        ]
    },
    {
        "id": "368282a3c6c7686a",
        "type": "ping",
        "z": "13f006802899e0be",
        "protocol": "IPv4",
        "mode": "triggered",
        "name": "",
        "host": "",
        "timer": "10",
        "inputs": 1,
        "x": 365,
        "y": 80,
        "wires": [
            [
                "2caed5e8c38011f9"
            ]
        ],
        "l": false
    },
    {
        "id": "c7fcb9a183a78340",
        "type": "function",
        "z": "13f006802899e0be",
        "name": "function 687",
        "func": "let c1 = global.get(\"local.connection\");\nlet c2 = global.get(\"things.connection\");\nlet stat = flow.get(\"stat\"); // ใช้ตัวแปรใน flow เพื่อเก็บสถานะ\n// ตรวจสอบว่า payload เปลี่ยนแปลงหรือยัง\nif (stat === undefined) {\n    // ถ้ายังไม่มีสถานะเก็บไว้ (สถานะเริ่มต้น)\n    stat = {\n        payload: null, // ค่าพื้นฐานของ payload\n        isProcessed: false // กำหนดสถานะให้ทำงานได้ครั้งแรก\n    };\n    flow.set(\"stat\", stat); // เก็บสถานะใน flow\n}\n// ตรวจสอบเงื่อนไขที่กำหนด\nif ((c1 && c2) || (stat.isProcessed === false)) {\n    if (stat.payload !== 3) { // ตรวจสอบว่า payload มีการเปลี่ยนแปลงหรือไม่\n        msg.payload = 3;\n        stat.payload = 3; // อัปเดตสถานะ payload\n        stat.isProcessed = true; // ตั้งค่าสถานะว่าได้ทำการประมวลผลแล้ว\n        return msg;\n    }\n} else if ((c1 && !c2) || (!c1 && c2)) {\n    if (stat.payload !== 1) { // ตรวจสอบว่า payload มีการเปลี่ยนแปลงหรือไม่\n        msg.payload = 1;\n        stat.payload = 1; // อัปเดตสถานะ payload\n        stat.isProcessed = true; // ตั้งค่าสถานะว่าได้ทำการประมวลผลแล้ว\n        return msg;\n    }\n} else {\n    if (stat.payload !== 2) { // ตรวจสอบว่า payload มีการเปลี่ยนแปลงหรือไม่\n        msg.payload = 2;\n        stat.payload = 2; // อัปเดตสถานะ payload\n        stat.isProcessed = true; // ตั้งค่าสถานะว่าได้ทำการประมวลผลแล้ว\n        return msg;\n    }\n}\nflow.set(\"stat\", stat); // อัปเดตสถานะใน flow",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 690,
        "y": 80,
        "wires": [
            []
        ]
    },
    {
        "id": "31d0b6ab517e74b4",
        "type": "exec",
        "z": "8e2e38d354fe03ed",
        "command": "./stat_led/blink11.sh ",
        "addpay": "payload",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "blink",
        "x": 310,
        "y": 40,
        "wires": [
            [],
            [],
            []
        ]
    },
    {
        "id": "1c5975849d6fe242",
        "type": "function",
        "z": "8e2e38d354fe03ed",
        "name": "function 6",
        "func": "msg.payload = 1;\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 160,
        "y": 40,
        "wires": [
            [
                "31d0b6ab517e74b4"
            ]
        ]
    },
    {
        "id": "a0c1fc8ef292ea30",
        "type": "function",
        "z": "d70462931d98191e",
        "name": "",
        "func": "let fc = msg.fc;\nlet unitid = msg.unitid;\nlet address = msg.address;\nlet quantity = msg.quantity;\n\nmsg.payload = { \n    value: '',\n    'fc': fc,\n    'unitid': unitid,\n    'address': address,\n    'quantity': quantity\n    }; return msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 190,
        "y": 80,
        "wires": [
            [
                "100c04dfb1fc8533"
            ]
        ]
    },
    {
        "id": "100c04dfb1fc8533",
        "type": "modbus-flex-getter",
        "z": "d70462931d98191e",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 390,
        "y": 80,
        "wires": [
            [],
            []
        ]
    },
    {
        "id": "698cc965e4a64996",
        "type": "inject",
        "z": "e226ede58ea4b202",
        "name": "",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            }
        ],
        "repeat": "1",
        "crontab": "",
        "once": false,
        "onceDelay": 0.1,
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 155,
        "y": 160,
        "wires": [
            [
                "d1e4489c3e8ca995",
                "c5418b2844d316d7"
            ]
        ],
        "icon": "font-awesome/fa-info-circle",
        "l": false
    },
    {
        "id": "d1e4489c3e8ca995",
        "type": "function",
        "z": "e226ede58ea4b202",
        "name": "function 6",
        "func": "let time_cal = msg.payload - global.get(\"rtu.check.temperature\");\nlet count = flow.get(\"count\") || 0;\ntime_cal > 10000 || !global.get(\"timestamp\") ? flow.set(\"count\", count + 1) : flow.set(\"count\", 0); // 3000 millisec\nreturn count > 300 ? msg : undefined;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 260,
        "y": 160,
        "wires": [
            [
                "9eb83d2ca8ce536d"
            ]
        ]
    },
    {
        "id": "c5418b2844d316d7",
        "type": "function",
        "z": "e226ede58ea4b202",
        "name": "function 7",
        "func": "let count = flow.get(\"count\")\nmsg.count = count\nmsg.payload = {\n    fill: count < 1? \"green\" : \"red\",\n    shape: count < 1? \"dot\" : \"ring\",\n    text: count\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 260,
        "y": 220,
        "wires": [
            [
                "b20e01c67a28eeb6"
            ]
        ]
    },
    {
        "id": "9eb83d2ca8ce536d",
        "type": "exec",
        "z": "e226ede58ea4b202",
        "command": "reboot",
        "addpay": "",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "",
        "x": 410,
        "y": 160,
        "wires": [
            [],
            [],
            []
        ]
    },
    {
        "id": "09af4c1ad37430eb",
        "type": "exec",
        "z": "e226ede58ea4b202",
        "command": "./stat_led/modbus_err.sh",
        "addpay": "",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "blink err",
        "x": 560,
        "y": 280,
        "wires": [
            [],
            [],
            []
        ]
    },
    {
        "id": "b20e01c67a28eeb6",
        "type": "switch",
        "z": "e226ede58ea4b202",
        "name": "",
        "property": "count",
        "propertyType": "msg",
        "rules": [
            {
                "t": "gt",
                "v": "0",
                "vt": "num"
            }
        ],
        "checkall": "true",
        "repair": false,
        "outputs": 1,
        "x": 410,
        "y": 280,
        "wires": [
            [
                "09af4c1ad37430eb"
            ]
        ]
    },
    {
        "id": "98efd0b00952e62f",
        "type": "modbus-getter",
        "z": "08bf79c0de8b2ac1",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "unitid": "3",
        "dataType": "HoldingRegister",
        "adr": "0",
        "quantity": "60",
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 220,
        "y": 120,
        "wires": [
            [
                "ed7ca99d23b92deb",
                "5d31d81fc827e8fd",
                "d866c62cbc8951d0",
                "c793a6ebde239565",
                "88fca284226aa5fa",
                "11e678e628526da7"
            ],
            []
        ]
    },
    {
        "id": "ed7ca99d23b92deb",
        "type": "modbus-response",
        "z": "08bf79c0de8b2ac1",
        "name": "",
        "registerShowMax": "60",
        "x": 420,
        "y": 100,
        "wires": []
    },
    {
        "id": "5d31d81fc827e8fd",
        "type": "function",
        "z": "08bf79c0de8b2ac1",
        "name": "energy",
        "func": "var input1 = parseInt(msg.payload[56], 10).toString(16);\nvar input2 = parseInt(msg.payload[57], 10).toString(16).padStart(4, \"0\");\nvar input3 = input1 + input2;\nvar output = parseInt(input3, 16).toString(10);\nflow.set(\"total_energy\", output);\nnode.status({ fill: \"blue\", shape: \"ring\", text: output });\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 390,
        "y": 160,
        "wires": [
            []
        ]
    },
    {
        "id": "d866c62cbc8951d0",
        "type": "function",
        "z": "08bf79c0de8b2ac1",
        "name": "Voltage",
        "func": "let output1 = convertToVoltage(msg.payload[0], msg.payload[1]);\nlet output2 = convertToVoltage(msg.payload[2], msg.payload[3]);\nlet output3 = convertToVoltage(msg.payload[4], msg.payload[5]);\n\nflow.set(\"voltageA\", output1);\nflow.set(\"voltageB\", output2);\nflow.set(\"voltageC\", output3);\nnode.status({ fill: \"blue\", shape: \"ring\", text: output3 });\n\nfunction convertToVoltage(high, low) {\n    let highHex = parseInt(high, 10).toString(16);\n    let lowHex = parseInt(low, 10).toString(16).padStart(4, \"0\");\n\n    let combinedHex = highHex + lowHex;\n    let decimalValue = parseInt(combinedHex, 16).toString(10);\n    return parseFloat(Number(decimalValue) / 1000).toFixed(1);\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 400,
        "y": 200,
        "wires": [
            []
        ]
    },
    {
        "id": "c793a6ebde239565",
        "type": "function",
        "z": "08bf79c0de8b2ac1",
        "name": "Current",
        "func": "let output1 = convertToCurrent(msg.payload[12], msg.payload[13]);\nlet output2 = convertToCurrent(msg.payload[14], msg.payload[15]);\nlet output3 = convertToCurrent(msg.payload[16], msg.payload[17]);\n\nflow.set(\"currentA\", output1);\nflow.set(\"currentB\", output2);\nflow.set(\"currentC\", output3);\nnode.status({ fill: \"blue\", shape: \"ring\", text: output3 });\n\nfunction convertToCurrent(high, low) {\n    let highHex = parseInt(high, 10).toString(16);\n    let lowHex = parseInt(low, 10).toString(16).padStart(4, \"0\");\n\n    let combinedHex = highHex + lowHex;\n    let decimalValue = parseInt(combinedHex, 16).toString(10);\n    return parseFloat(Number(decimalValue) / 1000).toFixed(1);\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 400,
        "y": 240,
        "wires": [
            []
        ]
    },
    {
        "id": "88fca284226aa5fa",
        "type": "function",
        "z": "08bf79c0de8b2ac1",
        "name": "Power",
        "func": "let output1 = convertToPower(msg.payload[18], msg.payload[19]);\nlet output2 = convertToPower(msg.payload[20], msg.payload[21]);\nlet output3 = convertToPower(msg.payload[22], msg.payload[23]);\n\nflow.set(\"powerA\", output1);\nflow.set(\"powerB\", output2);\nflow.set(\"powerC\", output3);\n\n// คำนวณเปอร์เซ็นต์พลังงานแต่ละเฟส\nlet total_power = Number(output1) + Number(output2) + Number(output3);\nif (total_power > 0) {\n    let percentage_A = ((Number(output1) / total_power) * 100).toFixed(1);\n    let percentage_B = ((Number(output2) / total_power) * 100).toFixed(1);\n    let percentage_C = ((Number(output3) / total_power) * 100).toFixed(1);\n    flow.set(\"percentage_kwhA\", percentage_A);\n    flow.set(\"percentage_kwhB\", percentage_B);\n    flow.set(\"percentage_kwhC\", percentage_C);\n}\nnode.status({ fill: \"blue\", shape: \"ring\", text: output3 });\n\nfunction convertToPower(high, low) {\n    let highHex = parseInt(high, 10).toString(16);\n    let lowHex = parseInt(low, 10).toString(16).padStart(4, \"0\");\n\n    let combinedHex = highHex + lowHex;\n    let decimalValue = parseInt(combinedHex, 16).toString(10);\n    return parseFloat(Number(decimalValue) / 1000).toFixed(1);\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 390,
        "y": 280,
        "wires": [
            []
        ]
    },
    {
        "id": "11e678e628526da7",
        "type": "function",
        "z": "08bf79c0de8b2ac1",
        "name": "Power factor",
        "func": "let output1 = convertToFactor(msg.payload[34], msg.payload[35]);\nlet output2 = convertToFactor(msg.payload[36], msg.payload[37]);\nlet output3 = convertToFactor(msg.payload[38], msg.payload[39]);\n\nflow.set(\"powerfactorA\", output1);\nflow.set(\"powerfactorB\", output2);\nflow.set(\"powerfactorC\", output3);\n\nnode.status({ fill: \"blue\", shape: \"ring\", text: output3 });\nreturn msg;\n\nfunction convertToFactor(high, low) {\n    let highHex = parseInt(high, 10).toString(16);\n    let lowHex = parseInt(low, 10).toString(16).padStart(4, \"0\");\n\n    let combinedHex = highHex + lowHex;\n    let decimalValue = parseInt(combinedHex, 16).toString(10);\n    return parseFloat(Number(decimalValue) / 1000).toFixed(2);\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 410,
        "y": 320,
        "wires": [
            []
        ]
    },
    {
        "id": "eca5291042b4bf09",
        "type": "function",
        "z": "08bf79c0de8b2ac1",
        "name": "values",
        "func": "var voltA = flow.get(\"voltageA\");\nvar voltB = flow.get(\"voltageB\");\nvar voltC = flow.get(\"voltageC\");\n\nvar currentA = flow.get(\"currentA\");\nvar currentB = flow.get(\"currentB\");\nvar currentC = flow.get(\"currentC\");\n\nvar powerA = flow.get(\"powerA\");\nvar powerB = flow.get(\"powerB\");\nvar powerC = flow.get(\"powerC\");\n\nvar energyA = flow.get(\"energyA\");\nvar energyB = flow.get(\"energyB\");\nvar energyC = flow.get(\"energyC\");\n\nvar powerfactorA = flow.get(\"powerfactorA\");\nvar powerfactorB = flow.get(\"powerfactorB\");\nvar powerfactorC = flow.get(\"powerfactorC\");\n\nvar timestamp_res =  flow.get(\"timestamp\");\nvar percentage_powerA,percentage_powerB,percentage_powerC;\nvar percentage_currentA, percentage_currentB, percentage_currentC;\n\nvar total_power = Number(parseFloat(Number(powerA) + Number(powerB) + Number(powerC)).toFixed(3));\nif(powerA && powerB && powerC){\n     percentage_powerA = parseFloat((Number(powerA) / Number(total_power)) * 100).toFixed(1);\n     percentage_powerB = parseFloat((Number(powerB) / Number(total_power)) * 100).toFixed(1);\n     percentage_powerC = parseFloat((Number(powerC) / Number(total_power)) * 100).toFixed(1);\n}else{\n     percentage_powerA = 0;\n     percentage_powerB = 0;\n     percentage_powerC = 0;\n}\n\nvar total_current = Number(parseFloat(Number(currentA) + Number(currentB) + Number(currentC)).toFixed(2));\nif(currentA && currentB && currentC){\n     percentage_currentA = parseFloat((Number(currentA) / Number(total_current)) * 100).toFixed(1);\n     percentage_currentB = parseFloat((Number(currentB) / Number(total_current)) * 100).toFixed(1);\n     percentage_currentC = parseFloat((Number(currentC) / Number(total_current)) * 100).toFixed(1);\n}else{\n    percentage_currentA = 0;\n    percentage_currentB = 0;\n    percentage_currentC = 0;\n}\n\nvar energy_stack = flow.get(\"total_energy\");\nvar timestamp = flow.get(\"timestamp\")\n\nmsg.payload = {\n    'ts': timestamp,\n    'tsres': timestamp_res,\n    'volt':{\n        'A': Number(voltA), \n        'B': Number(voltB), \n        'C': Number(voltC)\n    },\n    'current':{\n        'A': Number(currentA), \n        'B': Number(currentB), \n        'C': Number(currentC)\n    },\n    'power':{\n        'A': Number(powerA), \n        'B': Number(powerB), \n        'C': Number(powerC)\n    },\n    'energy':{\n        'A': Number(energyA), \n        'B': Number(energyB), \n        'C': Number(energyC)\n    },\n    'powerfactor':{\n        'A': Number(powerfactorA), \n        'B': Number(powerfactorB), \n        'C': Number(powerfactorC)\n    },\n    'percentage':{\n        'power':{\n            'A': Number(percentage_powerA),\n            'B': Number(percentage_powerB),\n            'C': Number(percentage_powerC)\n        },\n        'current': {\n            'A': Number(percentage_currentA),\n            'B': Number(percentage_currentB),\n            'C': Number(percentage_currentC)\n        }\n    },\n    'total':{\n        'energy_stack': Number(energy_stack),\n        'power': Number(total_power),\n        'current': Number(total_current),\n    }\n}\nreturn msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 390,
        "y": 360,
        "wires": [
            []
        ]
    },
    {
        "id": "c0f9612c44d3b1a9",
        "type": "function",
        "z": "08bf79c0de8b2ac1",
        "name": "timestamp",
        "func": "flow.set(\"timestamp\", msg.timestamp);",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 210,
        "y": 80,
        "wires": [
            []
        ]
    },
    {
        "id": "01448e1706374234",
        "type": "delay",
        "z": "08bf79c0de8b2ac1",
        "name": "",
        "pauseType": "delay",
        "timeout": "500",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 155,
        "y": 360,
        "wires": [
            [
                "eca5291042b4bf09"
            ]
        ],
        "l": false
    },
    {
        "id": "e391938b1b829351",
        "type": "function",
        "z": "5444d5754c7e8492",
        "name": "function 699",
        "func": "let values = flow.get(\"values\");\nmsg.payload = { \n    value: values,\n    'fc': 16,\n    'unitid': 1,\n    'address': 110,\n    'quantity': 4\n    }; \nreturn msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 270,
        "y": 140,
        "wires": [
            [
                "f2b85a1340bf58f1"
            ]
        ]
    },
    {
        "id": "45a81fc131c1a653",
        "type": "modbus-response",
        "z": "5444d5754c7e8492",
        "name": "",
        "registerShowMax": 20,
        "x": 710,
        "y": 140,
        "wires": []
    },
    {
        "id": "1b03d86b09de8847",
        "type": "delay",
        "z": "5444d5754c7e8492",
        "name": "",
        "pauseType": "delay",
        "timeout": "100",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 135,
        "y": 140,
        "wires": [
            [
                "e391938b1b829351"
            ]
        ],
        "l": false
    },
    {
        "id": "f2b85a1340bf58f1",
        "type": "modbus-flex-write",
        "z": "5444d5754c7e8492",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "server": "291667434678740d",
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 470,
        "y": 140,
        "wires": [
            [
                "45a81fc131c1a653",
                "232ec32b38bad6f9"
            ],
            []
        ]
    },
    {
        "id": "19678fef328fa5a4",
        "type": "function",
        "z": "5444d5754c7e8492",
        "name": "function 701",
        "func": "flow.set(\"timestamp\", msg.timestamp);\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 190,
        "y": 60,
        "wires": [
            []
        ]
    },
    {
        "id": "eedfcfaea08f2738",
        "type": "function",
        "z": "5444d5754c7e8492",
        "name": "",
        "func": "let fc = msg.fc;\nlet unitid = msg.unitid;\nlet address = msg.address;\nlet quantity = msg.quantity;\n\nmsg.payload = { \n    value: '',\n    'fc': fc,\n    'unitid': unitid,\n    'address': address,\n    'quantity': quantity\n    }; return msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 260,
        "y": 100,
        "wires": [
            [
                "9c1d51e470aa2253"
            ]
        ]
    },
    {
        "id": "9c1d51e470aa2253",
        "type": "modbus-flex-getter",
        "z": "5444d5754c7e8492",
        "name": "",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 470,
        "y": 100,
        "wires": [
            [
                "8b64f67972fa28c3",
                "09685f05be72adad",
                "1b03d86b09de8847"
            ],
            []
        ]
    },
    {
        "id": "8b64f67972fa28c3",
        "type": "function",
        "z": "5444d5754c7e8492",
        "name": "function 702",
        "func": "let values = [    \n    msg.payload[0], \n    msg.payload[1], \n    msg.payload[2], \n    msg.payload[3]\n    ]\nflow.set(\"values\", values);\nmsg.payload = { \n    'fill': \"bule\",\n    'shape': \"dot\",\n    'text': values\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 690,
        "y": 100,
        "wires": [
            []
        ]
    },
    {
        "id": "758d37fd74bb8898",
        "type": "delay",
        "z": "5444d5754c7e8492",
        "name": "",
        "pauseType": "delay",
        "timeout": "100",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 135,
        "y": 100,
        "wires": [
            [
                "eedfcfaea08f2738"
            ]
        ],
        "l": false
    },
    {
        "id": "09685f05be72adad",
        "type": "modbus-response",
        "z": "5444d5754c7e8492",
        "name": "",
        "registerShowMax": 20,
        "x": 710,
        "y": 60,
        "wires": []
    },
    {
        "id": "232ec32b38bad6f9",
        "type": "function",
        "z": "5444d5754c7e8492",
        "name": "function 704",
        "func": "msg.payload = {\n    'timestamp': flow.get(\"timestamp\"),\n    'values': flow.get(\"values\")\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 690,
        "y": 200,
        "wires": [
            []
        ]
    },
    {
        "id": "c58fc5dd0a3782e6",
        "type": "http request",
        "z": "459dc2665cb0fd05",
        "name": "",
        "method": "use",
        "ret": "txt",
        "paytoqs": "ignore",
        "url": "",
        "tls": "",
        "persist": false,
        "proxy": "",
        "insecureHTTPParser": false,
        "authType": "",
        "senderr": false,
        "headers": [],
        "x": 510,
        "y": 80,
        "wires": [
            [
                "da506d58575ccd4a"
            ]
        ]
    },
    {
        "id": "da506d58575ccd4a",
        "type": "function",
        "z": "459dc2665cb0fd05",
        "name": "err_code",
        "func": "if(msg.statusCode === 200){\n    if(msg.alarm === 0 || msg.alarm === 2){\n        global.set(\"hourstamp\", global.get(\"hour\"));\n    }\n    msg.payload = {\n    \"fill\": \"blue\",\n    \"shape\": \"dot\",\n    \"text\": `Time: ${global.get(\"time\")} Code: ${msg.statusCode}`    \n    };return msg;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 700,
        "y": 80,
        "wires": [
            [
                "0e554ea7674813e7"
            ]
        ]
    },
    {
        "id": "1b8aad88f8326708",
        "type": "function",
        "z": "459dc2665cb0fd05",
        "name": "function 706",
        "func": "let botToken = msg.botToken;\nlet chatId = msg.chatId; // Chat ID ของคุณ\nlet alarm = msg.alarm;\n\n// ส่งสติ๊กเกอร์หลังจากส่งข้อความ\nlet stickerID1 = \"CAACAgIAAxkBAAEN03Rns5fAFE4drhsFktIE1ZtKXHIa0QACswEAAhZCawp4Wn8enz1mxDYE\";\nlet stickerID2 = \"CAACAgIAAxkBAAEN7-VnxW7KwZNXfhZSOTXmdd43VsCFhgAC4wwAAjAT0Euml6TE9QhYWzYE\";\nlet stickerID3 = \"CAACAgIAAxkBAAEOWK5oCFY3AzHgH0HlRVBeLFaVCsdiiAACxwEAAhZCawrrRsAAAVV7qqI2BA\";\n\nif(alarm === 0){\nvar stickerMsg1 = {\n    url: `https://api.telegram.org/bot${botToken}/sendSticker?chat_id=${chatId}&sticker=${stickerID1}`,\n    method: \"GET\",\n    payload: \"sticker\"\n};\nreturn stickerMsg1;\n}else if(alarm === 1){\nvar stickerMsg2 = {\n    url: `https://api.telegram.org/bot${botToken}/sendSticker?chat_id=${chatId}&sticker=${stickerID2}`,\n    method: \"GET\",\n    payload: \"sticker\"\n};\nreturn stickerMsg2;\n}\nelse if(alarm === 2){\nvar stickerMsg3 = {\n    url: `https://api.telegram.org/bot${botToken}/sendSticker?chat_id=${chatId}&sticker=${stickerID3}`,\n    method: \"GET\",\n    payload: \"sticker\"\n};\nreturn stickerMsg3;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 330,
        "y": 120,
        "wires": [
            [
                "c58fc5dd0a3782e6"
            ]
        ]
    },
    {
        "id": "39985fd99854bdfa",
        "type": "delay",
        "z": "459dc2665cb0fd05",
        "name": "",
        "pauseType": "delay",
        "timeout": "1",
        "timeoutUnits": "seconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 160,
        "y": 120,
        "wires": [
            [
                "1b8aad88f8326708"
            ]
        ]
    },
    {
        "id": "0e554ea7674813e7",
        "type": "link out",
        "z": "459dc2665cb0fd05",
        "name": "link out 16",
        "mode": "link",
        "links": [
            "dbb4a095eeebc6ad"
        ],
        "x": 835,
        "y": 120,
        "wires": []
    },
    {
        "id": "dbb4a095eeebc6ad",
        "type": "link in",
        "z": "459dc2665cb0fd05",
        "name": "link in 83",
        "links": [
            "0e554ea7674813e7"
        ],
        "x": 55,
        "y": 120,
        "wires": [
            [
                "39985fd99854bdfa"
            ]
        ]
    },
    {
        "id": "21be4e819a07b9fc",
        "type": "http request",
        "z": "5186eb39253053a0",
        "name": "",
        "method": "POST",
        "ret": "txt",
        "paytoqs": "ignore",
        "url": "http://103.80.48.82:1880/power/device-ext/data-log",
        "tls": "",
        "persist": false,
        "proxy": "",
        "insecureHTTPParser": false,
        "authType": "",
        "senderr": false,
        "headers": [],
        "x": 370,
        "y": 80,
        "wires": [
            [
                "7089388e2e3162b3"
            ]
        ]
    },
    {
        "id": "ee3cb4661478a727",
        "type": "function",
        "z": "5186eb39253053a0",
        "name": "function 1",
        "func": "msg.payload = msg.payload;\ndelete msg.tocloud;\ndelete msg.columns;\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 200,
        "y": 80,
        "wires": [
            [
                "21be4e819a07b9fc"
            ]
        ]
    },
    {
        "id": "7089388e2e3162b3",
        "type": "function",
        "z": "5186eb39253053a0",
        "name": "function 2",
        "func": "const code = msg.statusCode;\nif(code === 200){\n    msg.payload = {\n        'fill': 'blue',\n        'shape': 'dot',\n        'text': `${global.get(\"time\")} Code: ${code} Is OK`\n    }\n    return msg;\n}else{\n    msg.payload = {\n    'fill': 'red',\n    'shape': 'dot',\n        'text': `${global.get(\"time\")} Code: ${code} Is Err`\n    }\n    return msg;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 560,
        "y": 80,
        "wires": [
            []
        ]
    },
    {
        "id": "7b266960418331fd",
        "type": "http request",
        "z": "12021995985b969c",
        "name": "",
        "method": "POST",
        "ret": "txt",
        "paytoqs": "ignore",
        "url": "http://103.80.48.82:1880/production/device-ext/data-log",
        "tls": "",
        "persist": false,
        "proxy": "",
        "insecureHTTPParser": false,
        "authType": "",
        "senderr": false,
        "headers": [],
        "x": 390,
        "y": 80,
        "wires": [
            [
                "e3a2b851d624434a"
            ]
        ]
    },
    {
        "id": "0f1c91d0e51de893",
        "type": "function",
        "z": "12021995985b969c",
        "name": "function 4721",
        "func": "msg.payload = msg.payload;\ndelete msg.tocloud;\ndelete msg.columns;\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 220,
        "y": 80,
        "wires": [
            [
                "7b266960418331fd"
            ]
        ]
    },
    {
        "id": "e3a2b851d624434a",
        "type": "function",
        "z": "12021995985b969c",
        "name": "function 4722",
        "func": "const code = msg.statusCode;\nif(code === 200){\n    msg.payload = {\n        'fill': 'blue',\n        'shape': 'dot',\n        'text': `${global.get(\"time\")} Code: ${code} Is OK`\n    }\n    return msg;\n}else{\n    msg.payload = {\n    'fill': 'red',\n    'shape': 'dot',\n        'text': `${global.get(\"time\")} Code: ${code} Is Err`\n    }\n    return msg;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 580,
        "y": 80,
        "wires": [
            []
        ]
    },
    {
        "id": "65cafb99a2d8ea22",
        "type": "function",
        "z": "2b98acde2363f390",
        "name": "delete",
        "func": "let rowthingsboard = global.get(\"things.row.pow\") || 0;\nlet indexthingsboard = global.get(\"things.index.pow\") || 0;\nif((rowthingsboard >= 1000) && (indexthingsboard === rowthingsboard) ){\n    return msg;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 190,
        "y": 20,
        "wires": [
            [
                "1e62283ce9473e92"
            ]
        ]
    },
    {
        "id": "1e62283ce9473e92",
        "type": "exec",
        "z": "2b98acde2363f390",
        "command": "rm /home/orangepi/powermeter/thingsboard/log_thingsboard.csv",
        "addpay": "",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "rm",
        "x": 350,
        "y": 40,
        "wires": [
            [],
            [],
            []
        ]
    },
    {
        "id": "afd5d4f8d1f23ed4",
        "type": "function",
        "z": "fb9a76fc3fc3bf75",
        "name": "function 645",
        "func": "var index = global.get(\"things.index.pow\") || 0\n    index = index + 1\n    global.set(\"things.index.pow\", index)\nmsg.payload = {\n    fill: \"blue\",\n    shape: \"dot\",\n    text: `index: ${index} time success:${global.get(\"time\")}`\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 345,
        "y": 80,
        "wires": [
            [
                "8cef230230652a64",
                "1fb8fecfd9b33962"
            ]
        ],
        "icon": "font-awesome/fa-check",
        "l": false
    },
    {
        "id": "8cef230230652a64",
        "type": "subflow:2b98acde2363f390",
        "z": "fb9a76fc3fc3bf75",
        "name": "",
        "x": 490,
        "y": 120,
        "wires": []
    },
    {
        "id": "ee71a4cd9a89ccb4",
        "type": "mqtt out",
        "z": "fb9a76fc3fc3bf75",
        "name": "",
        "topic": "",
        "qos": "",
        "retain": "",
        "respTopic": "",
        "contentType": "",
        "userProps": "",
        "correl": "",
        "expiry": "",
        "broker": "46e77e42f3b6378f",
        "x": 370,
        "y": 160,
        "wires": []
    },
    {
        "id": "9b36fcba403aa823",
        "type": "function",
        "z": "fb9a76fc3fc3bf75",
        "name": "Broker1",
        "func": "let broker = global.get(\"things.broker\");\nlet port = global.get(\"things.port\");\nlet username = global.get(\"things.username\");\nlet topic = global.get(\"things.topic\");\n\nmsg.action = \"connect\";\nmsg.broker = {\n    broker: broker,\n    port: port,\n    username: username,\n    password: \"\",\n    force: true\n};\nmsg.topic = topic;\nmsg.qos = 1;\nmsg.retain = false;\nreturn msg;\n",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 220,
        "y": 160,
        "wires": [
            [
                "ee71a4cd9a89ccb4"
            ]
        ]
    },
    {
        "id": "0b92a587025744af",
        "type": "inject",
        "z": "fb9a76fc3fc3bf75",
        "name": "",
        "props": [],
        "repeat": "",
        "crontab": "",
        "once": true,
        "onceDelay": "1",
        "topic": "",
        "x": 115,
        "y": 160,
        "wires": [
            [
                "9b36fcba403aa823"
            ]
        ],
        "l": false
    },
    {
        "id": "1fb8fecfd9b33962",
        "type": "function",
        "z": "fb9a76fc3fc3bf75",
        "name": "loop",
        "func": "var report = global.get(\"report\");\nif (report){\n    return msg;\n};",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 450,
        "y": 40,
        "wires": [
            [
                "8a278ef7b8f02e7e"
            ]
        ]
    },
    {
        "id": "9c477714492d62e5",
        "type": "function",
        "z": "fb9a76fc3fc3bf75",
        "name": "function 4",
        "func": "\n    msg.rm = `rm /home/orangepi/powermeter/report_thingsboard/${msg.fileremove}`;\n    return msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 815,
        "y": 40,
        "wires": [
            [
                "d2fd4ddace542871"
            ]
        ],
        "icon": "font-awesome/fa-check",
        "l": false
    },
    {
        "id": "8a278ef7b8f02e7e",
        "type": "fs-file-lister",
        "z": "fb9a76fc3fc3bf75",
        "name": "",
        "start": "/home/orangepi/powermeter/report_thingsboard/",
        "pattern": "*.*",
        "folders": "*",
        "hidden": true,
        "lstype": "files",
        "path": true,
        "single": true,
        "depth": "0",
        "stat": true,
        "showWarnings": false,
        "x": 545,
        "y": 40,
        "wires": [
            [
                "8e57a9e9120b9a7b"
            ]
        ],
        "l": false
    },
    {
        "id": "8e57a9e9120b9a7b",
        "type": "function",
        "z": "fb9a76fc3fc3bf75",
        "name": "name",
        "func": "var datenow = `${global.get(\"datenow\")}.csv`;\nvar obj = msg.payload[0].name;\nvar parts = obj.split(\"/\");\nvar filereport = parts[5];\nmsg.filereport = \"/home/orangepi/powermeter/report_thingsboard/\" + filereport;\nmsg.fileremove = filereport;\nnode.status({ fill: \"yellow\", shape: \"ring\", text: \"remove: \" + filereport });\nif (datenow != filereport) {\n    return msg;\n}else {\n    global.set(\"loop\", false);\n    global.set(\"report\", undefined);\n};",
        "outputs": 1,
        "timeout": "",
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 650,
        "y": 40,
        "wires": [
            [
                "6efe8ab51e3db803",
                "ef78502b549ac32e"
            ]
        ]
    },
    {
        "id": "d2fd4ddace542871",
        "type": "exec",
        "z": "fb9a76fc3fc3bf75",
        "command": "",
        "addpay": "rm",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "",
        "x": 920,
        "y": 40,
        "wires": [
            [],
            [],
            []
        ]
    },
    {
        "id": "6efe8ab51e3db803",
        "type": "delay",
        "z": "fb9a76fc3fc3bf75",
        "name": "",
        "pauseType": "delay",
        "timeout": "1",
        "timeoutUnits": "seconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 755,
        "y": 40,
        "wires": [
            [
                "9c477714492d62e5"
            ]
        ],
        "l": false
    },
    {
        "id": "e6ca647c6b4db84b",
        "type": "function",
        "z": "fb9a76fc3fc3bf75",
        "name": "read",
        "func": "let payload = msg.payload[0];\n\n// สร้างออบเจ็กต์ค่าพลังงานโดยใช้ลูป\nlet energyValues = {};\nfor (let i = 0; i < 24; i++) {\n    let hour = i < 10 ? `0${i}` : `${i}`;  // เพิ่มเลขศูนย์นำหน้าเวลาที่น้อยกว่า 10\n    let key = `energy${i}`;\n    energyValues[`${hour}:00`] = payload[key];\n}\n\n// สร้างออบเจ็กต์ผลลัพธ์ที่ต้องการ\nmsg.topic = \"v1/devices/me/telemetry\";\nconst obj = {\n    ts: payload.timestamp,\n    values: {\n        total_energy_day: Number(payload.total_energy || 0),\n        total_co2_day: Number(payload.co2 || 0),\n        ...energyValues  // เพิ่มข้อมูลพลังงานที่สร้างจากลูป\n    }\n};\nmsg.qos = 1;\nmsg.retain = false;\nmsg.payload = obj;\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 920,
        "y": 80,
        "wires": [
            [
                "771ca1941c66b71d"
            ]
        ]
    },
    {
        "id": "ef78502b549ac32e",
        "type": "file in",
        "z": "fb9a76fc3fc3bf75",
        "name": "",
        "filename": "filereport",
        "filenameType": "msg",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "utf8",
        "allProps": false,
        "x": 755,
        "y": 80,
        "wires": [
            [
                "9563b951214b54cf"
            ]
        ],
        "l": false
    },
    {
        "id": "9563b951214b54cf",
        "type": "csv",
        "z": "fb9a76fc3fc3bf75",
        "name": "",
        "sep": ",",
        "hdrin": true,
        "hdrout": "",
        "multi": "mult",
        "ret": "\\r\\n",
        "temp": "",
        "skip": "0",
        "strings": true,
        "include_empty_strings": false,
        "include_null_values": false,
        "x": 815,
        "y": 80,
        "wires": [
            [
                "e6ca647c6b4db84b"
            ]
        ],
        "l": false
    },
    {
        "id": "771ca1941c66b71d",
        "type": "mqtt out",
        "z": "fb9a76fc3fc3bf75",
        "name": "",
        "topic": "",
        "qos": "",
        "retain": "",
        "respTopic": "",
        "contentType": "",
        "userProps": "",
        "correl": "",
        "expiry": "",
        "broker": "46e77e42f3b6378f",
        "x": 1060,
        "y": 80,
        "wires": []
    },
    {
        "id": "3de8ccb8ea347799",
        "type": "function",
        "z": "2e0105dcea086c8e",
        "name": "Index/Con.",
        "func": "let row = global.get(\"things.row.pow\") || 0;\nlet index = global.get(\"things.index.pow\") || 1;\nlet connect = global.get(\"things.connection\");\n\nif ((index < row) && connect){\n    msg.path = `/home/orangepi/powermeter/thingsboard/log_power.csv`;\n    node.status({ fill: \"blue\", shape: \"dot\", text: `index:${index} < row:${row} `});\n    return msg;\n}else{\n    node.status({ fill: \"blue\", shape: \"dot\", text: `index:${index} = row:${row} ` });\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 210,
        "y": 100,
        "wires": [
            [
                "1738ddf3235020fd"
            ]
        ],
        "icon": "node-red/cog.svg"
    },
    {
        "id": "1738ddf3235020fd",
        "type": "file in",
        "z": "2e0105dcea086c8e",
        "name": "",
        "filename": "path",
        "filenameType": "msg",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "utf8",
        "allProps": false,
        "x": 380,
        "y": 100,
        "wires": [
            [
                "b8d2e19452529d3c"
            ]
        ]
    },
    {
        "id": "b8d2e19452529d3c",
        "type": "csv",
        "z": "2e0105dcea086c8e",
        "name": "",
        "sep": ",",
        "hdrin": true,
        "hdrout": "",
        "multi": "mult",
        "ret": "\\r\\n",
        "temp": "",
        "skip": "0",
        "strings": true,
        "include_empty_strings": false,
        "include_null_values": false,
        "x": 485,
        "y": 100,
        "wires": [
            [
                "ed4575f3c65e3dd9",
                "a58b51ecd58caf5a"
            ]
        ],
        "l": false
    },
    {
        "id": "ed4575f3c65e3dd9",
        "type": "function",
        "z": "2e0105dcea086c8e",
        "name": "function 644",
        "func": "var index = global.get(\"things.index.pow\");\n\nvar date = msg.payload[index].date;\nvar time = msg.payload[index].time;\nvar timestamp = msg.payload[index].timestamp;\nvar voltageA = msg.payload[index].voltageA;\nvar voltageB = msg.payload[index].voltageB;\nvar voltageC = msg.payload[index].voltageC;\nvar currentA = msg.payload[index].currentA;\nvar currentB = msg.payload[index].currentB;\nvar currentC = msg.payload[index].currentC;\nvar powerA = msg.payload[index].powerA;\nvar powerB = msg.payload[index].powerB;\nvar powerC = msg.payload[index].powerC;\nvar powerfactorA = msg.payload[index].powerfactorA;\nvar powerfactorB = msg.payload[index].powerfactorB;\nvar powerfactorC = msg.payload[index].powerfactorC;\nvar powerpercentageA = msg.payload[index].powerpercentageA;\nvar powerpercentageB = msg.payload[index].powerpercentageB;\nvar powerpercentageC = msg.payload[index].powerpercentageC;\nvar currentpercentageA = msg.payload[index].currentpercentageA;\nvar currentpercentageB = msg.payload[index].currentpercentageB;\nvar currentpercentageC = msg.payload[index].currentpercentageC;\nvar energy_A = msg.payload[index].energy_A;\nvar energy_B = msg.payload[index].energy_B;\nvar total_energy = msg.payload[index].total_energy;\nvar energy_hour = msg.payload[index].energy_hour;\nvar energy_min = msg.payload[index].energy_min;\nvar co2 = msg.payload[index].co2\n\nconst obj = {\n    \"ts\": timestamp,\n    \"values\": {\n    date : date,\n    time : time,\n    voltageA: voltageA,\n    voltageB: voltageB,\n    voltageC: voltageC,\n    currentA: currentA,\n    currentB: currentB,\n    currentC: currentC,\n    powerA: powerA,\n    powerB: powerB,\n    powerC: powerC,\n    powerfactorA : powerfactorA,\n    powerfactorB : powerfactorB,\n    powerfactorC : powerfactorC,\n    currentpercentageA: currentpercentageA,\n    currentpercentageB: currentpercentageB,\n    currentpercentageC: currentpercentageC,\n    powerpercentageA: powerpercentageA,\n    powerpercentageB: powerpercentageB,\n    powerpercentageC: powerpercentageC,\n    energy_A: energy_A,\n    energy_B: energy_B,\n    energy_hour: energy_hour,\n    energy_min: energy_min,\n    total_energy: total_energy,\n    co2: co2\n    }\n};\nconst myJSON = JSON.stringify(obj);\nmsg.topic = \"v1/devices/me/telemetry\";\nmsg.payload = myJSON;\nmsg.qos = 1;\nmsg.retain = false;\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 610,
        "y": 100,
        "wires": [
            []
        ]
    },
    {
        "id": "a58b51ecd58caf5a",
        "type": "function",
        "z": "2e0105dcea086c8e",
        "name": "function 5",
        "func": "let index = global.get(\"things.index.pow\");\nlet time = msg.payload[index].time;\nnode.status({ fill: \"blue\", shape: \"ring\", text: time});\nmsg.payload = {\n    fill: \"blue\",\n    shape: \"dot\", \n    text: time\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 600,
        "y": 40,
        "wires": [
            []
        ]
    },
    {
        "id": "bc0f31b6dca4e838",
        "type": "catch",
        "z": "2e0105dcea086c8e",
        "name": "",
        "scope": [
            "ed4575f3c65e3dd9"
        ],
        "uncaught": false,
        "x": 590,
        "y": 160,
        "wires": [
            [
                "744b1c2e5e8ba92b"
            ]
        ]
    },
    {
        "id": "744b1c2e5e8ba92b",
        "type": "function",
        "z": "2e0105dcea086c8e",
        "name": "function 8",
        "func": "let index = global.get(\"things.index.pow\");\n    global.set(\"things.index.pow\", index + 1);",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 740,
        "y": 160,
        "wires": [
            []
        ]
    },
    {
        "id": "94d8bed30760b9ab",
        "type": "subflow:416e4ad47d77d15d",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "",
        "x": 480,
        "y": 180,
        "wires": [
            [
                "8dde1267333c6a89",
                "13ddfbdaa2138663"
            ]
        ]
    },
    {
        "id": "b5cc5e62d075e23c",
        "type": "function",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "Write PLC reset",
        "func": "var hours = Number(global.get(\"hour\"));\nvar changehour = Number(global.get(\"changehour\"));\nif(changehour != undefined && changehour != null){\n    if(hours != changehour){\n        msg.timestamp = msg.payload;\n        msg.payload = {\n            unitid: 1,\n            reset: 105,\n            fc: 6,\n            values: 1,\n        };\n        msg.modbus_read = false;\n        msg.time = global.get(\"time\");\n        global.set(\"changehour\", hours);\n        return msg;\n    }else{\n        msg.timestamp = msg.payload;\n        msg.modbus_read = true;\n        msg.payload = {\n            unitid: 1,\n            fc: 3,\n            screw: 102,\n            holding: 208,\n            annealing: 308,\n            stretching: 408,\n            meter: 506\n        };\n            node.status({fill:\"yellow\",shape:\"dot\",text:global.get(\"time\")});\n        return msg;\n    };\n};",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 365,
        "y": 180,
        "wires": [
            [
                "94d8bed30760b9ab"
            ]
        ],
        "l": false
    },
    {
        "id": "8dde1267333c6a89",
        "type": "function",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "values",
        "func": "let meter = msg.payload.meter;\nlet screw = msg.payload.screw;\nlet holding = msg.payload.holding;\nlet annealing = msg.payload.annealing;\nlet stretching = msg.payload.stretching;\n    setmeter();\n    global.set(\"rtu.check.production\", msg.payload.timestamp);\n    nowminmax(\"speed\", \"scr\", screw);\n    nowminmax(\"speed\", \"hol\", holding);\n    nowminmax(\"speed\", \"ann\", annealing);\n    nowminmax(\"speed\", \"str\", stretching);\n    node.status({fill:\"blue\",shape:\"dot\",text:global.get(\"time\")});\nreturn msg;\n\nfunction setmeter() {\n    var meter_ = global.get(\"meter\") || [];\n    var hour = global.get(\"hour\");\n    meter_.splice(Number(hour), 1, meter);\n}\n\nfunction nowminmax(type, group, input) {\n    global.set(`${type}.${group}.now`, input);\n    let input_min = global.get(`${type}.${group}.min`) || 0;\n    let input_max = global.get(`${type}.${group}.max`) || 0;\n\n    if (input > 0) {\n        if (!input_min || input < input_min) {\n            input_min = input;\n            global.set(`${type}.${group}.min`, input_min);\n        }\n        if (!input_max || input > input_max) {\n            input_max = input;\n            global.set(`${type}.${group}.max`, input_max);\n        };\n    };\n};",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 710,
        "y": 180,
        "wires": [
            [
                "173c54a7d9c4c04d"
            ]
        ]
    },
    {
        "id": "e520305b2c0acc0c",
        "type": "inject",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            }
        ],
        "repeat": "3",
        "crontab": "",
        "once": true,
        "onceDelay": "10",
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 305,
        "y": 120,
        "wires": [
            [
                "b79a8caa8c12d89b"
            ]
        ],
        "icon": "font-awesome/fa-archive",
        "l": false
    },
    {
        "id": "d02275d776d7a56d",
        "type": "link out",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "link out 6",
        "mode": "link",
        "links": [
            "6a9232d5cdac3c29",
            "be91844f8b0985bc"
        ],
        "x": 905,
        "y": 240,
        "wires": [],
        "icon": "node-red-contrib-modbus/modbus-icon.png"
    },
    {
        "id": "5994866ceafe6967",
        "type": "link in",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "link in 12",
        "links": [
            "173c54a7d9c4c04d"
        ],
        "x": 285,
        "y": 240,
        "wires": [
            [
                "964add341126d593"
            ]
        ],
        "icon": "font-awesome/fa-arrow-circle-right"
    },
    {
        "id": "ea7a27ca30464756",
        "type": "delay",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "1 m",
        "pauseType": "rate",
        "timeout": "1",
        "timeoutUnits": "minutes",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "minute",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": true,
        "allowrate": false,
        "outputs": 1,
        "x": 825,
        "y": 240,
        "wires": [
            [
                "d02275d776d7a56d"
            ]
        ],
        "l": false
    },
    {
        "id": "be91844f8b0985bc",
        "type": "link in",
        "z": "a4638d4e8237493c",
        "g": "c65113dc80938b27",
        "name": "link in 4",
        "links": [
            "d02275d776d7a56d"
        ],
        "x": 285,
        "y": 440,
        "wires": [
            [
                "6c35abd254398878"
            ]
        ]
    },
    {
        "id": "0bb91ff2ea50d493",
        "type": "function",
        "z": "a4638d4e8237493c",
        "g": "c65113dc80938b27",
        "name": "Set CSV",
        "func": "const positionA = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];\nconst positionB = [20, 21, 22, 23, 0, 1, 2, 3, 4, 5, 6, 7];\nlet meter = global.get(\"meter\");\nlet energy = global.get(\"energy\");\nlet energy_A = positionA.reduce((acc, pos) => acc + (energy[pos] || 0), 0);\nlet energy_B = positionB.reduce((acc, pos) => acc + (energy[pos] || 0), 0);\nlet meter_A = positionA.reduce((acc, pos) => acc + (meter[pos] || 0), 0);\nlet meter_B = positionB.reduce((acc, pos) => acc + (meter[pos] || 0), 0);\nlet total_meter = meter_A + meter_B;\nlet total_energy = energy_A + energy_B;\nlet co2 = flow.get(\"co2\") || 0;\n    msg.pathlocalpro =  `/home/orangepi/ext/data/production/log.csv`;\n    msg.pathlocalpow = `/home/orangepi/ext/data/power/log.csv`;\n    msg.localpro = global.get(\"local.list.pro\") || 0;\n    msg.localpow = global.get(\"local.list.pow\") || 0;\n    setPayload();\n    node.status({fill:\"green\",shape:\"dot\",text:global.get(\"time\")});\nreturn msg;\n\nfunction setPayload(){\n    msg.filesystem = {\n        timestamp: global.get(\"timestamp\"),\n        ip : global.get(\"IP\"),\n        date_data : global.get(\"date_data\"),\n        date: global.get(\"date\"),\n        time: global.get(\"time\"),\n        shift: global.get(\"shift\")\n    };\n    msg.production = {\n        temp:{\n            motor_in:{\n                now: global.get(\"temp.mt_in.now\"),\n                min: global.get(\"temp.mt_in.min\"),\n                max: global.get(\"temp.mt_in.max\")\n            },\n            motor_out:{\n                now: global.get(\"temp.mt_out.now\"),\n                min: global.get(\"temp.mt_out.min\"),\n                max: global.get(\"temp.mt_out.max\")\n            },\n            cooling_in:{\n                now: global.get(\"temp.cl_in.now\"),\n                min: global.get(\"temp.cl_in.min\"),\n                max: global.get(\"temp.cl_in.max\")\n            },\n            cooling_out:{\n                now: global.get(\"temp.cl_out.now\"),\n                min: global.get(\"temp.cl_out.min\"),\n                max: global.get(\"temp.cl_out.max\")\n            }\n        },\n        speed: {\n            screw: {\n                now: global.get(\"speed.scr.now\"),\n                min: global.get(\"speed.scr.min\"),\n                max: global.get(\"speed.scr.max\")\n            },\n            holding: {\n                now: global.get(\"speed.hol.now\"),\n                min: global.get(\"speed.hol.min\"),\n                max: global.get(\"speed.hol.max\")\n            },\n            annealing: {\n                now: global.get(\"speed.ann.now\"),\n                min: global.get(\"speed.ann.min\"),\n                max: global.get(\"speed.ann.max\")\n            },\n            stretching: {\n                now: global.get(\"speed.str.now\"),\n                min: global.get(\"speed.str.min\"),\n                max: global.get(\"speed.str.max\")\n            }\n        },\n        meter:{\n            meter: meter,\n            total:{\n                meter_A: meter_A,\n                meter_B: meter_B,\n                meter: total_meter,\n                meter_min: flow.get(\"meter_munits\")\n            }\n        }\n    };\n    msg.power = {\n        'voltage': flow.get(\"voltage\"),\n        'current': flow.get(\"current\"),\n        'power': flow.get(\"power\"),\n        'powerfactor': flow.get(\"powerfactor\"),\n        'percentagekwh': flow.get(\"percentage.power\"),\n        'percentageAmp': flow.get(\"percentage.current\"),\n        energy: energy,\n        'total':{\n            'energy': total_energy,\n            'energy_A': energy_A,\n            'energy_B': energy_B,\n            'co2': co2\n        }\n    };\n};",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 480,
        "y": 440,
        "wires": [
            [
                "446099760a4cb78e",
                "75909748614ac097"
            ]
        ]
    },
    {
        "id": "75909748614ac097",
        "type": "subflow:84087161fd829d92",
        "z": "a4638d4e8237493c",
        "g": "c65113dc80938b27",
        "name": "",
        "x": 690,
        "y": 440,
        "wires": []
    },
    {
        "id": "6c35abd254398878",
        "type": "delay",
        "z": "a4638d4e8237493c",
        "g": "c65113dc80938b27",
        "name": "200 ms",
        "pauseType": "delay",
        "timeout": "200",
        "timeoutUnits": "milliseconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 365,
        "y": 440,
        "wires": [
            [
                "0bb91ff2ea50d493"
            ]
        ],
        "l": false
    },
    {
        "id": "446099760a4cb78e",
        "type": "link out",
        "z": "a4638d4e8237493c",
        "g": "c65113dc80938b27",
        "name": "link out 8",
        "mode": "link",
        "links": [],
        "x": 575,
        "y": 460,
        "wires": []
    },
    {
        "id": "aaa02e33b2312586",
        "type": "subflow:3c87dd77ddd56ab5",
        "z": "a4638d4e8237493c",
        "g": "0134013d6c49db3c",
        "name": "",
        "x": 870,
        "y": 440,
        "wires": []
    },
    {
        "id": "65c6c67163f4a846",
        "type": "subflow:509f550183b44678",
        "z": "a4638d4e8237493c",
        "g": "72e3abb3e7faf340",
        "name": "",
        "x": 1120,
        "y": 180,
        "wires": [
            [
                "b9c18f7fcd8e7a77",
                "6fccb8ace5f750a8"
            ]
        ]
    },
    {
        "id": "54b953cb7c4b2af9",
        "type": "subflow:31057fe0b0d4c1ec",
        "z": "a4638d4e8237493c",
        "g": "72e3abb3e7faf340",
        "name": "",
        "x": 1290,
        "y": 340,
        "wires": []
    },
    {
        "id": "782058517c0086ed",
        "type": "subflow:f386491b277c5eef",
        "z": "a4638d4e8237493c",
        "g": "72e3abb3e7faf340",
        "name": "",
        "x": 1110,
        "y": 280,
        "wires": []
    },
    {
        "id": "e910a6992307569f",
        "type": "inject",
        "z": "a4638d4e8237493c",
        "g": "72e3abb3e7faf340",
        "name": "",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            }
        ],
        "repeat": "1",
        "crontab": "",
        "once": true,
        "onceDelay": 0.1,
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 1015,
        "y": 280,
        "wires": [
            [
                "782058517c0086ed"
            ]
        ],
        "icon": "font-awesome/fa-clock-o",
        "l": false
    },
    {
        "id": "28abf05cd47dacbe",
        "type": "subflow:6fa1970c13440cc6",
        "z": "a4638d4e8237493c",
        "g": "72e3abb3e7faf340",
        "name": "",
        "x": 1110,
        "y": 220,
        "wires": []
    },
    {
        "id": "847ddf396d892cec",
        "type": "inject",
        "z": "a4638d4e8237493c",
        "g": "72e3abb3e7faf340",
        "name": "",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            }
        ],
        "repeat": "300",
        "crontab": "",
        "once": true,
        "onceDelay": 0.1,
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 1015,
        "y": 180,
        "wires": [
            [
                "65c6c67163f4a846",
                "28abf05cd47dacbe"
            ]
        ],
        "icon": "node-red/cog.svg",
        "l": false
    },
    {
        "id": "b9c18f7fcd8e7a77",
        "type": "function",
        "z": "a4638d4e8237493c",
        "g": "72e3abb3e7faf340",
        "name": "Set value",
        "func": "global.set(\"datestamp\", msg.payload.datestamp);\nglobal.set(\"changehour\", msg.payload.changehour);\nglobal.set(\"hourstamp\", msg.payload.hourstamp);\nglobal.set(\"bot_token\", msg.payload.bot_token);\nglobal.set(\"chat_id\", msg.payload.chat_id);\nglobal.set(\"IP\", msg.payload.ip);\n\nconst speed = msg.payload.speed;\nglobal.set(\"speed.scr.min\", speed.scr.min || 0);\nglobal.set(\"speed.scr.max\", speed.scr.max || 0);\nglobal.set(\"speed.hol.min\", speed.hol.min || 0);\nglobal.set(\"speed.hol.max\", speed.hol.max || 0);\nglobal.set(\"speed.ann.min\", speed.ann.min || 0);\nglobal.set(\"speed.ann.max\", speed.ann.max || 0);\nglobal.set(\"speed.str.min\", speed.str.min || 0);\nglobal.set(\"speed.str.max\", speed.str.max || 0);\n\nconst temp = msg.payload.temp;\nglobal.set(\"temp.mt_in.min\", temp.mt_in.min || 0);\nglobal.set(\"temp.mt_in.max\", temp.mt_in.max || 0);\nglobal.set(\"temp.mt_out.min\", temp.mt_out.min || 0);\nglobal.set(\"temp.mt_out.max\", temp.mt_out.max || 0);\nglobal.set(\"temp.cl_in.min\", temp.cl_in.min || 0);\nglobal.set(\"temp.cl_in.max\", temp.cl_in.max || 0);\nglobal.set(\"temp.cl_out.min\", temp.cl_out.min || 0);\nglobal.set(\"temp.cl_out.max\", temp.cl_out.max || 0);\n\nconst local = msg.payload.local;\nglobal.set(\"local.index.pro\", local.index.pro || 0);\nglobal.set(\"local.index.pow\", local.index.pow || 0);\nglobal.set(\"local.ip\", local.ip || 0);\n\nconst things = msg.payload.things;\nglobal.set(\"things.index.pro\", things.index.pro || 0);\nglobal.set(\"things.index.pow\", things.index.pow || 0);\nglobal.set(\"things.broker\", things.broker || 0);\nglobal.set(\"things.port\", things.port || 0);\nglobal.set(\"things.username\", things.username || 0);\nglobal.set(\"things.topic\", things.topic || 0);\n\nvar meter = new Array(24).fill(0);\nglobal.set(\"meter\", msg.payload.meter);\n\nvar energy = new Array(24).fill(0);\nglobal.set(\"energy\", msg.payload.energy);\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 1255,
        "y": 180,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "3d6407e35ec14c30",
        "type": "function",
        "z": "a4638d4e8237493c",
        "g": "72e3abb3e7faf340",
        "name": "fig value",
        "func": "var energy = global.get(\"energy\");\nvar meter = global.get(\"meter\");\n///////////////////thingboard//////////////////////\n\n[\"pro\", \"pow\"].forEach(type => {\n    if (global.get(`local.row.${type}`) <= 1) {\n        global.set(`local.index.${type}`, 0);\n    }\n});\n\n[\"pro\", \"pow\"].forEach(type => {\n    if (global.get(`things.row.${type}`) <= 1) {\n        global.set(`things.index.${type}`, 0);\n    }\n});\n\nmsg.payload = {\n    \"date\": global.get(\"date\"),\n    \"datestamp\": global.get(\"datestamp\"),\n    \"time\": global.get(\"time\"),\n    \"ip\": global.get(\"IP\"),\n    \"hourstamp\": global.get(\"hourstamp\"),\n    \"changehour\": global.get(\"changehour\"),\n    \"bot_token\": global.get(\"bot_token\"),\n    \"chat_id\": global.get(\"chat_id\"),\n    local:{\n        ip: global.get(\"local.ip\"),\n        index: {\n            pro: global.get(\"local.index.pro\"),\n            pow: global.get(\"local.index.pow\"),\n        },\n\n    },\n    things:{\n        broker: global.get(\"things.broker\"),\n        port: global.get(\"things.port\"),\n        username: global.get(\"things.username\"),\n        topic: global.get(\"things.topic\"),\n        index: {\n            pro: global.get(\"things.index.pro\"),\n            pow: global.get(\"things.index.pow\"),\n        },\n    },\n     temp:{\n            mt_in:{\n                now: global.get(\"temp.mt_in.now\"),\n                min: global.get(\"temp.mt_in.min\"),\n                max: global.get(\"temp.mt_in.max\")\n            },\n            mt_out:{\n                now: global.get(\"temp.mt_out.now\"),\n                min: global.get(\"temp.mt_out.min\"),\n                max: global.get(\"temp.mt_out.max\")\n            },\n            cl_in:{\n                now: global.get(\"temp.cl_in.now\"),\n                min: global.get(\"temp.cl_in.min\"),\n                max: global.get(\"temp.cl_in.max\")\n            },\n            cl_out:{\n                now: global.get(\"temp.cl_out.now\"),\n                min: global.get(\"temp.cl_out.min\"),\n                max: global.get(\"temp.cl_out.max\")\n            }\n        },\n    speed: {\n            scr: {\n                now: global.get(\"speed.scr.now\"),\n                min: global.get(\"speed.scr.min\"),\n                max: global.get(\"speed.scr.max\")\n            },\n            hol: {\n                now: global.get(\"speed.hol.now\"),\n                min: global.get(\"speed.hol.min\"),\n                max: global.get(\"speed.hol.max\")\n            },\n            ann: {\n                now: global.get(\"speed.ann.now\"),\n                min: global.get(\"speed.ann.min\"),\n                max: global.get(\"speed.ann.max\")\n            },\n            str: {\n                now: global.get(\"speed.str.now\"),\n                min: global.get(\"speed.str.min\"),\n                max: global.get(\"speed.str.max\")\n            }\n        },\n        meter: global.get(\"meter\"),\n        energy: global.get(\"energy\")\n};return msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 1120,
        "y": 400,
        "wires": [
            [
                "3bbc4188314c94b0"
            ]
        ]
    },
    {
        "id": "85b4fe24b79a8752",
        "type": "inject",
        "z": "a4638d4e8237493c",
        "g": "72e3abb3e7faf340",
        "name": "",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            }
        ],
        "repeat": "1",
        "crontab": "",
        "once": false,
        "onceDelay": 0.1,
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 1015,
        "y": 400,
        "wires": [
            [
                "3d6407e35ec14c30",
                "37cd68613dcfe737"
            ]
        ],
        "icon": "node-red/leveldb.svg",
        "l": false
    },
    {
        "id": "3bbc4188314c94b0",
        "type": "subflow:02f6142c6c7e99bb",
        "z": "a4638d4e8237493c",
        "g": "72e3abb3e7faf340",
        "name": "",
        "x": 1255,
        "y": 400,
        "wires": [],
        "l": false
    },
    {
        "id": "0be2359769c61c3a",
        "type": "subflow:7fe66403ea1a14c9",
        "z": "a4638d4e8237493c",
        "g": "72e3abb3e7faf340",
        "name": "",
        "x": 1170,
        "y": 440,
        "wires": []
    },
    {
        "id": "37cd68613dcfe737",
        "type": "function",
        "z": "a4638d4e8237493c",
        "g": "72e3abb3e7faf340",
        "name": "path",
        "func": "// path Production file list \nmsg.payload = {\"start\": \"/home/orangepi/ext/data/production/\"};\n// path Power file list\nmsg.pathPower = {\"start\": \"/home/orangepi/ext/data/power/\"};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 1075,
        "y": 440,
        "wires": [
            [
                "0be2359769c61c3a"
            ]
        ],
        "l": false
    },
    {
        "id": "db63266254b0328a",
        "type": "subflow:5cf1d8d919e64156",
        "z": "a4638d4e8237493c",
        "g": "72e3abb3e7faf340",
        "name": "UI Selection",
        "x": 1130,
        "y": 120,
        "wires": []
    },
    {
        "id": "0374611cfdba1420",
        "type": "link in",
        "z": "a4638d4e8237493c",
        "g": "af4007faccb71e48",
        "name": "link in 2",
        "links": [],
        "x": 285,
        "y": 560,
        "wires": [
            [
                "6fdc936b9c9e8ee7"
            ]
        ]
    },
    {
        "id": "185912f8d1668211",
        "type": "subflow:db4fabd6a1540331",
        "z": "a4638d4e8237493c",
        "g": "af4007faccb71e48",
        "name": "",
        "x": 690,
        "y": 560,
        "wires": []
    },
    {
        "id": "6fdc936b9c9e8ee7",
        "type": "function",
        "z": "a4638d4e8237493c",
        "g": "af4007faccb71e48",
        "name": "Values",
        "func": "let timestamp = global.get(\"timestamp\");\nlet date = global.get(\"date\");\nlet time = global.get(\"time\");\nlet energy_A = flow.get(\"energy_A\");\nlet energy_B = flow.get(\"energy_B\");\nlet total_energy = flow.get(\"total_energy\");\nlet energy_hour = flow.get(\"energy_hour\");\nlet energy_min = flow.get(\"energy_munits\");\nlet co2 = flow.get(\"co2\");\nlet { A: voltageA = 0, B: voltageB = 0, C: voltageC = 0 } = flow.get(\"voltage\") || {};\nlet { A: powerA = 0, B: powerB = 0, C: powerC = 0 } = flow.get(\"power\") || {};\nlet { A: powerpercentageA, B: powerpercentageB, C: powerpercentageC } = flow.get(\"percentage\").power || {};\nlet { A: currentA = 0, B: currentB = 0, C: currentC = 0 } = flow.get(\"current\") || {};\nlet { A: currentpercentageA, B: currentpercentageB, C: currentpercentageC } = flow.get(\"percentage\").current || {};\nlet { A: powerfactorA = 0, B: powerfactorB = 0, C: powerfactorC = 0 } = flow.get(\"powerfactor\") || {};\nlet list_tb_pow = global.get(\"things.list.pow\");\nmsg.path_power = `/home/orangepi/powermeter/thingsboard/log_power.csv`;\nnode.status({fill:\"blue\",shape:\"dot\",text:global.get(\"time\")});\nmsg.payload ={\n    list_tb_pow: list_tb_pow,\n    date: date,  time: time, timestamp: timestamp,\n    voltageA: voltageA, \n    voltageB: voltageB, \n    voltageC: voltageC,\n    currentA: currentA, \n    currentB: currentB, \n    currentC: currentC,\n    powerA: powerA, \n    powerB: powerB, \n    powerC: powerC,\n    powerfactorA: powerfactorA, \n    powerfactorB: powerfactorB, \n    powerfactorC: powerfactorC,\n    powerpercentageA: powerpercentageA, \n    powerpercentageB: powerpercentageB, \n    powerpercentageC: powerpercentageC,\n    currentpercentageA: currentpercentageA,\n    currentpercentageB: currentpercentageB,\n    currentpercentageC: currentpercentageC,\n    energy_A: energy_A, \n    energy_B: energy_B,\n    energy_min: energy_min,\n    energy_hour: energy_hour,\n    total_energy: total_energy,\n    co2: co2\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 470,
        "y": 560,
        "wires": [
            [
                "185912f8d1668211",
                "d93828fb405910d4"
            ]
        ],
        "icon": "font-awesome/fa-archive"
    },
    {
        "id": "e6290a07b12de109",
        "type": "subflow:13f006802899e0be",
        "z": "a4638d4e8237493c",
        "g": "72e3abb3e7faf340",
        "name": "",
        "x": 1110,
        "y": 340,
        "wires": [
            [
                "54b953cb7c4b2af9"
            ]
        ]
    },
    {
        "id": "b0abde57f8695277",
        "type": "inject",
        "z": "a4638d4e8237493c",
        "g": "72e3abb3e7faf340",
        "name": "",
        "props": [
            {
                "p": "payload"
            }
        ],
        "repeat": "10",
        "crontab": "",
        "once": false,
        "onceDelay": 0.1,
        "topic": "",
        "payload": "local.ip",
        "payloadType": "global",
        "x": 1015,
        "y": 340,
        "wires": [
            [
                "e6290a07b12de109"
            ]
        ],
        "icon": "font-awesome/fa-globe",
        "l": false
    },
    {
        "id": "b79a8caa8c12d89b",
        "type": "function",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "config temp register",
        "func": "global.set(\"timestamp\", msg.payload);\nmsg.timestamp = global.get(\"timestamp\");\nmsg.fc = 3; // ฟังก์ชัน RTU\nmsg.unitid = 2; // ID Device\nmsg.address = 1; // ตำแหน่ง register เริ่มต้น\nmsg.quantity = 4; // จำนวน register ที่ขอ\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 365,
        "y": 120,
        "wires": [
            [
                "12dd0b09b0e85bbb"
            ]
        ],
        "l": false
    },
    {
        "id": "a241e24d2a8bd154",
        "type": "subflow:e226ede58ea4b202",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "",
        "x": 400,
        "y": 340,
        "wires": []
    },
    {
        "id": "b34905dcb1c392f4",
        "type": "subflow:08bf79c0de8b2ac1",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "",
        "x": 520,
        "y": 240,
        "wires": [
            [
                "f2e4983af2f69097"
            ]
        ]
    },
    {
        "id": "f2e4983af2f69097",
        "type": "function",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "values",
        "func": "let pl = msg.payload\n    // timestamp\n    global.set(\"rtu.check.powermeter\", pl.ts);\n    flow.set(\"timestamp\", pl.ts);\n    flow.set(\"timestamp_res\", pl.tsres);\n    // volt\n    flow.set(\"voltage.A\", pl.volt.A);\n    flow.set(\"voltage.B\", pl.volt.B);\n    flow.set(\"voltage.C\", pl.volt.C);\n    // powerfactor\n    flow.set(\"powerfactor.A\", pl.powerfactor.A);\n    flow.set(\"powerfactor.B\", pl.powerfactor.B);\n    flow.set(\"powerfactor.C\", pl.powerfactor.C);\n    // percentage\n    flow.set(\"percentage.power.A\", pl.percentage.power.A);\n    flow.set(\"percentage.power.B\", pl.percentage.power.B);\n    flow.set(\"percentage.power.C\", pl.percentage.power.C);\n    flow.set(\"percentage.current.A\", pl.percentage.current.A);\n    flow.set(\"percentage.current.B\", pl.percentage.current.B);\n    flow.set(\"percentage.current.C\", pl.percentage.current.C);\n    // current\n    flow.set(\"current.A\", pl.current.A);\n    flow.set(\"current.B\", pl.current.B);\n    flow.set(\"current.C\", pl.current.C);\n    flow.set(\"total_current\", pl.total.current);\n    // power\n    flow.set(\"power.A\", pl.power.A);\n    flow.set(\"power.B\", pl.power.B);\n    flow.set(\"power.C\", pl.power.C);\n    flow.set(\"total_power\", pl.total.power);\n    // energy\n    flow.set(\"energy.A\", pl.energy.A);\n    flow.set(\"energy.B\", pl.energy.B);\n    flow.set(\"energy.C\", pl.energy.C);\n    flow.set(\"energy_stack\", pl.total.energy_stack);\n    \n    node.status({fill:\"blue\",shape:\"dot\",text:global.get(\"time\")});\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 710,
        "y": 240,
        "wires": [
            [
                "ea7a27ca30464756"
            ]
        ]
    },
    {
        "id": "3de79f17e996a803",
        "type": "function",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "energy_",
        "func": "\nvar hour = Number(global.get(\"hour\"));\nvar onetime = context.get(\"onetime\");\nvar energy_now = context.get(\"energy_now\") || 0;\nvar energy = global.get(\"energy\");\n\nvar energy_stack = flow.get(\"energy_stack\");\n\nvar timestamp = flow.get(\"timestamp\");\nvar timestamp_res = flow.get(\"timestamp_res\");\nif (timestamp != timestamp_res) {\n    msg.initialvalues = true;\n}\n\nvar energy_previous = context.get(\"energy_previous\");\nif (!energy_previous) {\n    context.set(\"energy_previous\", energy_stack);\n}\nif (hour != onetime) {\n    if (Number(energy[hour]) === 0){\n        energy_previous = Number(energy_stack) - Number(context.get(\"energy_previous\"));\n        energy.splice(hour, 1, energy_previous);\n        global.set(\"energy\", energy);\n        context.set(\"onetime\", hour);\n        context.set(\"energy_now\", Number(energy_stack) - Number(energy[hour]));\n    }else{\n        context.set(\"onetime\", hour);\n        context.set(\"energy_now\", Number(energy_stack) - Number(energy[hour]));\n    }\n} else {\n    var energy_push = energy_stack - energy_now;\n    if (energy_push) {\n        energy_push = Number(parseFloat(energy_push).toFixed(3));\n        energy.splice(hour, 1, energy_push);\n        global.set(\"energy\",energy);\n    }\n}\ncontext.set(\"energy_previous\", energy_stack);\n\nvar total_energy_send = energy.map(Number).reduce((a, b) => a + b, 0);\n\nvar co2 = (total_energy_send * 0.4822);\nflow.set(\"co2\", co2);\nnode.status({ fill: \"blue\", shape: \"ring\", text: energy_stack + \" >> \" + energy_push });\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 480,
        "y": 300,
        "wires": [
            [
                "1095488ec8f233c2",
                "6c07456b931359bb"
            ]
        ]
    },
    {
        "id": "1095488ec8f233c2",
        "type": "function",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "Per Munits",
        "func": "var energy_input = Number(flow.get(\"energy_stack\")) || 0;\nvar energy_befor = Number(context.get(\"energy_befor\")) || 0;\nvar hour = global.get(\"hour\");\nvar onetime = context.get(\"onetime\") || undefined;\nvar energy_munits;\n\nif((hour === \"08\" && onetime) || msg.initialvalues){\n    context.set(\"onetime\", undefined);\n    onetime = undefined;\n}\nif(!onetime){\n    context.set(\"onetime\", true);\n    context.set(\"energy_befor\", energy_input);\n    energy_munits = 0;\n    flow.set(\"energy_munits\", energy_munits);\n}else{\n    energy_munits = parseFloat(energy_input - energy_befor).toFixed(3);\n    context.set(\"energy_befor\", energy_input);\n    flow.set(\"energy_munits\", energy_munits);\n}\nnode.status({fill:\"blue\",shape:\"dot\",text: energy_munits + \" kW/m\"});\nreturn msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 850,
        "y": 300,
        "wires": [
            []
        ]
    },
    {
        "id": "6c07456b931359bb",
        "type": "function",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "energy_send",
        "func": "var hour = Number(global.get(\"hour\"));\nvar energy = global.get(\"energy\");\n\nif (hour != undefined || hour != null) {\n   flow.set(\"energy_hour\", energy[hour]);\n   node.status({fill:\"blue\",shape:\"dot\",text: hour + \" | \" + energy[hour] + \" | \" + global.get(\"time\")});\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 650,
        "y": 320,
        "wires": [
            []
        ]
    },
    {
        "id": "12dd0b09b0e85bbb",
        "type": "subflow:5444d5754c7e8492",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "",
        "x": 490,
        "y": 120,
        "wires": [
            [
                "87f713810b33a180"
            ]
        ]
    },
    {
        "id": "173c54a7d9c4c04d",
        "type": "link out",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "link out 13",
        "mode": "link",
        "links": [
            "5994866ceafe6967"
        ],
        "x": 905,
        "y": 180,
        "wires": [],
        "icon": "node-red-contrib-modbus/modbus-icon.png"
    },
    {
        "id": "6a9232d5cdac3c29",
        "type": "link in",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "link in 80",
        "links": [
            "d02275d776d7a56d"
        ],
        "x": 285,
        "y": 300,
        "wires": [
            [
                "3de79f17e996a803"
            ]
        ],
        "icon": "font-awesome/fa-arrow-circle-right"
    },
    {
        "id": "6fcede93d69086fc",
        "type": "link in",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "link in 82",
        "links": [
            "cfc9a42476888a7b"
        ],
        "x": 285,
        "y": 180,
        "wires": [
            [
                "b5cc5e62d075e23c"
            ]
        ]
    },
    {
        "id": "87f713810b33a180",
        "type": "function",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "values",
        "func": "    global.set(\"rtu.check.temperature\", msg.payload.timestamp);\nlet temp = msg.payload.values;\n    nowminmax(`temp`, `mt_in`, temp[0]);\n    nowminmax(`temp`, `mt_out`, temp[1]);\n    nowminmax(`temp`, `cl_in`, temp[2]);\n    nowminmax(`temp`, `cl_out`, temp[3]);\n   node.status({fill:\"blue\",shape:\"dot\",text:global.get(\"time\")});\nreturn msg;\n\nfunction nowminmax(type, group, input) {\n    input = input / 10;\n    global.set(`${type}.${group}.now`, input);\n    let input_min = global.get(`${type}.${group}.min`) || 0;\n    let input_max = global.get(`${type}.${group}.max`) || 0;\n\n    if (input > 0 && input < 6000) {\n        if (!input_min || input < input_min) {\n            input_min = input;\n            global.set(`${type}.${group}.min`, input_min);\n        }\n        if (!input_max || input > input_max) {\n            input_max = input;\n            global.set(`${type}.${group}.max`, input_max);\n        };\n    }else{\n            global.set(`${type}.${group}.now`, -1);\n            global.set(`${type}.${group}.min`, -1);\n            global.set(`${type}.${group}.max`, -1);\n    };\n};",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 710,
        "y": 120,
        "wires": [
            [
                "cfc9a42476888a7b"
            ]
        ]
    },
    {
        "id": "cfc9a42476888a7b",
        "type": "link out",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "link out 15",
        "mode": "link",
        "links": [
            "6fcede93d69086fc"
        ],
        "x": 905,
        "y": 120,
        "wires": [],
        "icon": "node-red-contrib-modbus/modbus-icon.png"
    },
    {
        "id": "964add341126d593",
        "type": "function",
        "z": "a4638d4e8237493c",
        "g": "5c066a4a210a6f29",
        "name": "function 700",
        "func": "msg.timestamp = global.get(\"timestamp\");\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 365,
        "y": 240,
        "wires": [
            [
                "b34905dcb1c392f4"
            ]
        ],
        "l": false
    },
    {
        "id": "b3fe5e767a5564d1",
        "type": "inject",
        "z": "a4638d4e8237493c",
        "g": "48aaab48a5e282bd",
        "name": "",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            }
        ],
        "repeat": "30",
        "crontab": "",
        "once": false,
        "onceDelay": 0.1,
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 305,
        "y": 660,
        "wires": [
            [
                "d6697f2dedb0c187"
            ]
        ],
        "l": false
    },
    {
        "id": "d6697f2dedb0c187",
        "type": "function",
        "z": "a4638d4e8237493c",
        "g": "48aaab48a5e282bd",
        "name": "Alarm.values",
        "func": "let botToken = global.get(\"bot_token\");\nmsg.botToken = botToken;\nlet chatId =  global.get(\"chat_id\");\nmsg.chatId = chatId;\nlet contexthour = global.get(\"hourstamp\") || 0;\nlet globalhour = global.get(\"hour\");\n\nlet temp_mt_in = global.get(\"temp.mt_in.now\");\nlet temp_mt_out = global.get(\"temp.mt_out.now\");\n\nif (temp_mt_out >= 42 && temp_mt_out < 1000){\n    msg.alarm = 1;\n    let message = `🚨 Alarm! มีเหตุการณ์ผิดปกติ! อุณหภูมิน้ำเข้า:${temp_mt_in} อุณหภูมิน้ำออก:${temp_mt_out}`;\n    msg.url = `https://api.telegram.org/bot${botToken}/sendMessage?chat_id=${chatId}&text=${encodeURIComponent(message)}`;\n    global.set(\"hourstamp\", \"99\");\n    msg.method = \"GET\";\n    return msg;\n}\nelse if ((globalhour !== contexthour) && (temp_mt_out > 1000 || temp_mt_in > 1000)) {\n    msg.alarm = 2;\n    let message = `❗ Alarm! เซ็นเซอร์อาจทำงานไม่ปกติ อุณหภูมิน้ำเข้า:${temp_mt_in} อุณหภูมิน้ำออก:${temp_mt_out}`;\n    msg.url = `https://api.telegram.org/bot${botToken}/sendMessage?chat_id=${chatId}&text=${encodeURIComponent(message)}`;\n    msg.method = \"GET\";\n    return msg;\n}\nelse if((globalhour !== contexthour) && temp_mt_out < 42){\n    msg.alarm = 0;\n    let message = `🟢 อุณหภูมิปกติ! อุณหภูมิน้ำเข้า:${temp_mt_in} อุณหภูมิน้ำออก:${temp_mt_out}`;\n    msg.url = `https://api.telegram.org/bot${botToken}/sendMessage?chat_id=${chatId}&text=${encodeURIComponent(message)}`;\n    msg.method = \"GET\";\n    return msg;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 490,
        "y": 660,
        "wires": [
            [
                "bc442d4e5e05fdd9"
            ]
        ]
    },
    {
        "id": "bc442d4e5e05fdd9",
        "type": "subflow:459dc2665cb0fd05",
        "z": "a4638d4e8237493c",
        "g": "48aaab48a5e282bd",
        "name": "",
        "x": 680,
        "y": 660,
        "wires": []
    },
    {
        "id": "d93828fb405910d4",
        "type": "debug",
        "z": "a4638d4e8237493c",
        "g": "af4007faccb71e48",
        "name": "debug 3",
        "active": true,
        "tosidebar": true,
        "console": false,
        "tostatus": false,
        "complete": "true",
        "targetType": "full",
        "statusVal": "",
        "statusType": "auto",
        "x": 555,
        "y": 580,
        "wires": [],
        "l": false
    },
    {
        "id": "17b4e662190c5772",
        "type": "inject",
        "z": "a4638d4e8237493c",
        "g": "3ede334f566d2cd3",
        "name": "",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            }
        ],
        "repeat": "10",
        "crontab": "",
        "once": false,
        "onceDelay": 0.1,
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 865,
        "y": 560,
        "wires": [
            [
                "2b1315c081abf404"
            ]
        ],
        "icon": "@flowfuse/node-red-dashboard/ui-markdown.svg",
        "l": false
    },
    {
        "id": "2b1315c081abf404",
        "type": "subflow:2e0105dcea086c8e",
        "z": "a4638d4e8237493c",
        "g": "3ede334f566d2cd3",
        "name": "",
        "x": 1060,
        "y": 560,
        "wires": [
            [
                "199c10969eee6b5a",
                "df655336ca9eab34"
            ]
        ]
    },
    {
        "id": "199c10969eee6b5a",
        "type": "subflow:fb9a76fc3fc3bf75",
        "z": "a4638d4e8237493c",
        "g": "3ede334f566d2cd3",
        "name": "",
        "x": 1290,
        "y": 540,
        "wires": []
    },
    {
        "id": "9211ca2b23f3430f",
        "type": "debug",
        "z": "a4638d4e8237493c",
        "name": "debug 5",
        "active": true,
        "tosidebar": true,
        "console": false,
        "tostatus": false,
        "complete": "true",
        "targetType": "full",
        "statusVal": "",
        "statusType": "auto",
        "x": 1320,
        "y": 620,
        "wires": []
    },
    {
        "id": "df655336ca9eab34",
        "type": "function",
        "z": "a4638d4e8237493c",
        "name": "function 4723",
        "func": "msg.payload = JSON.parse(msg.payload);\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 1215,
        "y": 620,
        "wires": [
            [
                "9211ca2b23f3430f"
            ]
        ],
        "l": false
    },
    {
        "id": "8e8127f88023da73",
        "type": "mqtt out",
        "z": "a4638d4e8237493c",
        "name": "",
        "topic": "",
        "qos": "",
        "retain": "",
        "respTopic": "",
        "contentType": "",
        "userProps": "",
        "correl": "",
        "expiry": "",
        "broker": "46e77e42f3b6378f",
        "x": 550,
        "y": 820,
        "wires": []
    },
    {
        "id": "ef3b2b27c4477d00",
        "type": "function",
        "z": "a4638d4e8237493c",
        "name": "Broker1",
        "func": "let broker = global.get(\"things.broker\");\nlet port = global.get(\"things.port\");\nlet username = global.get(\"things.username\");\nlet topic = global.get(\"things.topic\");\n\nmsg.action = \"connect\";\nmsg.broker = {\n    broker: broker,\n    port: port,\n    username: username,\n    password: \"\",\n    force: true\n};\nmsg.topic = topic;\nmsg.qos = 1;\nmsg.retain = false;\nreturn msg;\n",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 400,
        "y": 820,
        "wires": [
            [
                "8e8127f88023da73"
            ]
        ]
    },
    {
        "id": "0911069044c86b8c",
        "type": "inject",
        "z": "a4638d4e8237493c",
        "name": "",
        "props": [],
        "repeat": "",
        "crontab": "",
        "once": true,
        "onceDelay": "1",
        "topic": "",
        "x": 295,
        "y": 820,
        "wires": [
            [
                "ef3b2b27c4477d00"
            ]
        ],
        "l": false
    },
    {
        "id": "13ddfbdaa2138663",
        "type": "debug",
        "z": "a4638d4e8237493c",
        "name": "debug 6",
        "active": false,
        "tosidebar": true,
        "console": false,
        "tostatus": false,
        "complete": "true",
        "targetType": "full",
        "statusVal": "",
        "statusType": "auto",
        "x": 675,
        "y": 60,
        "wires": [],
        "l": false
    },
    {
        "id": "f0aac4a43198d51b",
        "type": "inject",
        "z": "a4638d4e8237493c",
        "name": "",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            }
        ],
        "repeat": "",
        "crontab": "",
        "once": false,
        "onceDelay": 0.1,
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 340,
        "y": 780,
        "wires": [
            [
                "c1d85f0ad241fc95"
            ]
        ]
    },
    {
        "id": "c1d85f0ad241fc95",
        "type": "function",
        "z": "a4638d4e8237493c",
        "name": "function 4724",
        "func": "global.set(\"bot_token\", \"7803640032:AAH61ene0tfoXAm3hxPc6b7d8BxmZVdfb7I\");\nglobal.set(\"chat_id\", \"-1002524874212\");\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 520,
        "y": 780,
        "wires": [
            []
        ]
    },
    {
        "id": "6fccb8ace5f750a8",
        "type": "debug",
        "z": "a4638d4e8237493c",
        "name": "debug 7",
        "active": true,
        "tosidebar": true,
        "console": false,
        "tostatus": false,
        "complete": "true",
        "targetType": "full",
        "statusVal": "",
        "statusType": "auto",
        "x": 1420,
        "y": 140,
        "wires": []
    }
]
EOF
node-red-restart
