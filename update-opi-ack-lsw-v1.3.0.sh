#!/bin/bash
sudo apt update && sudo apt -y upgrade
echo " [ACK-IoT Orange Pi Update Version] กำลังติดตั้ง Dashboard 2.0 และติดตั้ง flows Node-red กรุณารอสักครู่..."
npm install @flowfuse/node-red-dashboard --prefix ~/.node-red
user=$HOME
#2025-07-8|15:04AM
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
fi
cat << 'EOF' > $user/loom/scriptConfig.sh
#!/bin/bash
user="$HOME"
tmpFile="$user/loom/config.txt.tmp"
finalFile="$user/loom/config.txt"
backupFile="$user/loom/config.txt.bak"
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
chmod +x $user/loom/scriptConfig.sh

#if [ ! -f "$user/loom/config.txt" ]; then
#cat << 'EOF' > $user/loom/config.txt
#{"state":{"datestamp":"-","changehour":-,"upt":{"nla":0,"ota":0,"totalA":0,"nlb":0,"otb":0,"totalB":0,"index":0,"ip":"-","version":"-"},"values":{"maintake":{"main":{"min":0,"max":0},"take":{"min":0,"max":0}},"meter":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"working":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]}}
#EOF
#fi

rm $user/loom/data/log.csv

if [ ! -f "$user/loom/source.txt" ]; then
source=$(grep -o -E 'source-[0-9]+' $user/.node-red/flows.json | sed 's/source-//' | sort -u)
cat << EOF > $user/loom/source.txt
$source
EOF
        echo "Log Source: $source"
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
[
    {
        "id": "777823ab3e1fee97",
        "type": "tab",
        "label": "Flow 1",
        "disabled": false,
        "info": "",
        "env": []
    },
    {
        "id": "df4a94479416f0c4",
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
                        "id": "5198508231fcf8a8"
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
                    "id": "f3b472b4726bfeec",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "a67f25631bef1988",
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
                        "id": "59eb51568d8158c9"
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
                    "id": "23bad38c2d77961c",
                    "port": 0
                }
            ]
        }
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
                "x": 560,
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
            "x": 560,
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
        "id": "e226ede58ea4b202",
        "type": "subflow",
        "name": "Modbus & Alarm",
        "info": "",
        "category": "Special Node",
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
        "id": "aa3c99c011a59edd",
        "type": "subflow",
        "name": "conf.Set",
        "info": "input\r\n - Data config to config.txt file",
        "category": "Special Node",
        "in": [
            {
                "x": 50,
                "y": 30,
                "wires": [
                    {
                        "id": "67264d9b0e343db6"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#ff834a",
        "icon": "node-red/cog.svg",
        "status": {
            "x": 760,
            "y": 60,
            "wires": [
                {
                    "id": "4fa647803c42f119",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "b7d6774c49a75902",
        "type": "subflow",
        "name": "File",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 60,
                "y": 80,
                "wires": [
                    {
                        "id": "9ac210c7c0b99891"
                    }
                ]
            }
        ],
        "out": [
            {
                "x": 320,
                "y": 80,
                "wires": [
                    {
                        "id": "5730377ef1841b85",
                        "port": 0
                    }
                ]
            }
        ],
        "env": [],
        "meta": {},
        "color": "#FFFFFF",
        "icon": "node-red/file.svg",
        "status": {
            "x": 480,
            "y": 120,
            "wires": [
                {
                    "id": "0d197ce9478787bb",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "341bdc3e7e68ae46",
        "type": "subflow",
        "name": "conf.Get",
        "info": "input\r\n - msg.\r\noutput\r\n - msg.payload (config.txt)",
        "category": "Special Node",
        "in": [
            {
                "x": 50,
                "y": 130,
                "wires": [
                    {
                        "id": "7dcb29351996d6be"
                    },
                    {
                        "id": "258890b7306744af"
                    },
                    {
                        "id": "8e7c7d80304fe097"
                    },
                    {
                        "id": "d6c523303ab0a091"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#ff834a",
        "icon": "node-red/cog.svg",
        "status": {
            "x": 640,
            "y": 80,
            "wires": [
                {
                    "id": "24e85514de7978d5",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "424004941bcb3307",
        "type": "subflow",
        "name": "Product.csv",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 50,
                "y": 30,
                "wires": [
                    {
                        "id": "3925be8bad2bdf74"
                    }
                ]
            }
        ],
        "out": [
            {
                "x": 560,
                "y": 40,
                "wires": [
                    {
                        "id": "0a3028182b518b6e",
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
        "id": "a007640620fd4d52",
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
                        "id": "6f98bf351570cfd0"
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
        "id": "77aa6425a6e4878c",
        "type": "subflow",
        "name": "Delete",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 60,
                "y": 80,
                "wires": [
                    {
                        "id": "9112ab91340ace88"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#1d84ff",
        "icon": "font-awesome/fa-close"
    },
    {
        "id": "a6ecc454e1b3c0c3",
        "type": "subflow",
        "name": "API",
        "info": "",
        "category": "Special Node",
        "in": [],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#00e4ff",
        "icon": "font-awesome/fa-cloud-upload",
        "status": {
            "x": 980,
            "y": 120,
            "wires": [
                {
                    "id": "043a074eaca99487",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "7a70a201eaa0a148",
        "type": "subflow",
        "name": "Count",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 60,
                "y": 80,
                "wires": [
                    {
                        "id": "329b2dc06d31e4a6"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#fca903",
        "icon": "font-awesome/fa-plus-circle",
        "status": {
            "x": 420,
            "y": 80,
            "wires": [
                {
                    "id": "6bf085a9f0b65ea1",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "f1016d6dfc436da7",
        "type": "subflow",
        "name": "Power.csv",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 50,
                "y": 30,
                "wires": [
                    {
                        "id": "ef469af3a6dd75f8"
                    }
                ]
            }
        ],
        "out": [
            {
                "x": 380,
                "y": 40,
                "wires": [
                    {
                        "id": "562f9af20391c406",
                        "port": 0
                    }
                ]
            },
            {
                "x": 380,
                "y": 80,
                "wires": [
                    {
                        "id": "580c9972ff966756",
                        "port": 0
                    }
                ]
            }
        ],
        "env": [],
        "meta": {},
        "color": "#f3dd00",
        "icon": "font-awesome/fa-inbox"
    },
    {
        "id": "78457dab5d6c0503",
        "type": "subflow",
        "name": "Device Log",
        "info": "",
        "category": "Special Node",
        "in": [
            {
                "x": 60,
                "y": 120,
                "wires": [
                    {
                        "id": "18936721347779ca"
                    },
                    {
                        "id": "5bd37418f0f1f7c3"
                    }
                ]
            }
        ],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#a1a5ff",
        "icon": "node-red/alert.svg",
        "status": {
            "x": 360,
            "y": 180,
            "wires": [
                {
                    "id": "656d5fdf90f37195",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "9f979da7e8a5400d",
        "type": "subflow",
        "name": "Dashboard",
        "info": "",
        "category": "Special Node",
        "in": [],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#ff3636",
        "icon": "node-red-contrib-chartjs/pie_chart.png"
    },
    {
        "id": "1406c468fdce7358",
        "type": "subflow",
        "name": "Telegram http",
        "info": "",
        "category": "",
        "in": [
            {
                "x": 60,
                "y": 80,
                "wires": [
                    {
                        "id": "62597ed5138d084d"
                    }
                ]
            }
        ],
        "out": [
            {
                "x": 480,
                "y": 80,
                "wires": [
                    {
                        "id": "fbda616582fab4cb",
                        "port": 0
                    }
                ]
            }
        ],
        "env": [],
        "meta": {},
        "color": "#03befc",
        "icon": "font-awesome/fa-send"
    },
    {
        "id": "c9bf91fd5c385f43",
        "type": "subflow",
        "name": "state upTime",
        "info": "",
        "category": "Special Node",
        "in": [],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#fcba03",
        "icon": "font-awesome/fa-clock-o",
        "status": {
            "x": 380,
            "y": 80,
            "wires": [
                {
                    "id": "d6a67c89385322a2",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "062d9ee6cb5e367f",
        "type": "subflow",
        "name": "Sensor Check",
        "info": "",
        "category": "Special Node",
        "in": [],
        "out": [],
        "env": [],
        "meta": {},
        "color": "#87A980",
        "status": {
            "x": 370,
            "y": 160,
            "wires": [
                {
                    "id": "2a334b79d30a7edf",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "451150a92cfdb00f",
        "type": "group",
        "z": "777823ab3e1fee97",
        "name": "System",
        "style": {
            "stroke": "#ff0000",
            "fill": "#000000",
            "fill-opacity": "0.89",
            "label": true,
            "label-position": "n",
            "color": "#ffC000"
        },
        "nodes": [
            "9827f5270df78aba",
            "8d2314a673078d68",
            "cb4e9770746b4c2d",
            "641e370bc218b3e1",
            "54b953cb7c4b2af9",
            "e6290a07b12de109",
            "b0abde57f8695277",
            "a241e24d2a8bd154",
            "bc26e53c6604a53c",
            "2e091e726e419728",
            "7d876bfc55befcf6",
            "fe159939e00a876e",
            "c974acb909bd6616",
            "8f882b3c1846c4d2",
            "b57537dcf374507c",
            "09e65fc5a9cf3984",
            "b64538e02f4df6e9"
        ],
        "x": 774,
        "y": 39,
        "w": 412,
        "h": 402
    },
    {
        "id": "9036c777fe360381",
        "type": "group",
        "z": "777823ab3e1fee97",
        "name": "Server Log",
        "style": {
            "label": true,
            "label-position": "n",
            "color": "#92d04f",
            "stroke": "#ffff3f",
            "fill": "#000000",
            "fill-opacity": "1"
        },
        "nodes": [
            "65638a0971dafdf2",
            "bca7972e18afe768",
            "e814c362277b941f",
            "f5baaac8574c3c63",
            "e02e37f582fc0ef1",
            "7051805b6fc3e4c5",
            "a68e65d6bd73a95c",
            "54d61fbff53a0240"
        ],
        "x": 774,
        "y": 459,
        "w": 412,
        "h": 122
    },
    {
        "id": "6be6c492a2953951",
        "type": "group",
        "z": "777823ab3e1fee97",
        "name": "Modbus",
        "style": {
            "stroke": "#ff0000",
            "fill": "#000000",
            "fill-opacity": "0.86",
            "label": true,
            "label-position": "n",
            "color": "#ffC000"
        },
        "nodes": [
            "165854dba9786ef4",
            "8cb095c264d1728b",
            "d53e6b2f26983416",
            "020abe7539ad09c4",
            "0a51b58526c3eac5",
            "1a7e9f67f1527628",
            "87858dfa873e16c3",
            "2b0bc6d5e24e124c",
            "0eb02406f8dff0ba",
            "8f9c36612b955b2f",
            "ed51c14eaa7633a7",
            "51f8481c029f9f8d",
            "4a4b0af55f35b68b",
            "6640ba01536a2946",
            "d1b4a59f01f7a3ac",
            "2eb5bec75f01e20f",
            "f6a699b11f2d2677",
            "d233508a056c55a0",
            "f4bb43f8de8fb162",
            "3e759bafa1177ed1",
            "195dabaf8bf83f47",
            "2b24aa05aa5379ed",
            "f2925150b152ddfd",
            "a31df86427795839",
            "72694dc1ac5df943",
            "707e34c1a544e5d1",
            "b83a6608cf3531d8",
            "792452b6dfad242c",
            "72949a75b63686fd",
            "ac29116d0411fcab",
            "fd6dded7e0aa82a2"
        ],
        "x": 44,
        "y": 39,
        "w": 702,
        "h": 542
    },
    {
        "id": "2e091e726e419728",
        "type": "group",
        "z": "777823ab3e1fee97",
        "g": "451150a92cfdb00f",
        "name": "API",
        "style": {
            "label": true,
            "label-position": "n",
            "color": "#0070c0",
            "stroke": "#ff0000",
            "fill": "#000000",
            "fill-opacity": "1"
        },
        "nodes": [],
        "x": 1050,
        "y": 270,
        "w": 40,
        "h": 40
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
        "showWarnings": true,
        "showLogs": true
    },
    {
        "id": "d6f3a7fd07525d85",
        "type": "ui-base",
        "name": "myDashboard",
        "path": "/dashboard",
        "appIcon": "",
        "includeClientData": true,
        "acceptsClientConfig": [
            "ui-notification",
            "ui-control"
        ],
        "showPathInSidebar": false,
        "headerContent": "page",
        "navigationStyle": "default",
        "titleBarStyle": "default",
        "showReconnectNotification": true,
        "notificationDisplayTime": 1,
        "showDisconnectNotification": true,
        "allowInstall": false
    },
    {
        "id": "93042030270d6867",
        "type": "ui-theme",
        "name": "ui_template.themes.defaultTheme",
        "colors": {
            "surface": "#2e2e2e",
            "primary": "#0094ce",
            "bgPage": "#2e2e2e",
            "groupBg": "#2e2e2e",
            "groupOutline": "#2e2e2e"
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
        "id": "20308079d89423ea",
        "type": "ui-page",
        "name": "Home",
        "ui": "d6f3a7fd07525d85",
        "path": "/page1",
        "icon": "home",
        "layout": "grid",
        "theme": "93042030270d6867",
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
        "visible": true,
        "disabled": false
    },
    {
        "id": "6da9956de8144acb",
        "type": "ui-group",
        "name": "Homepage",
        "page": "20308079d89423ea",
        "width": "12",
        "height": 1,
        "order": 3,
        "showTitle": false,
        "className": "",
        "visible": "true",
        "disabled": "false",
        "groupType": "default"
    },
    {
        "id": "c8b6450989c369f5",
        "type": "ui-group",
        "name": "DateSelect",
        "page": "20308079d89423ea",
        "width": 6,
        "height": 1,
        "order": 1,
        "showTitle": true,
        "className": "",
        "visible": "true",
        "disabled": "false",
        "groupType": "default"
    },
    {
        "id": "72adefdf7b5e4ced",
        "type": "ui-group",
        "name": "Cmd Update",
        "page": "20308079d89423ea",
        "width": 6,
        "height": 1,
        "order": 2,
        "showTitle": true,
        "className": "",
        "visible": "true",
        "disabled": "false",
        "groupType": "default"
    },
    {
        "id": "93ca67d43751815a",
        "type": "ui-page",
        "name": "Data Source",
        "ui": "d6f3a7fd07525d85",
        "path": "/page2",
        "icon": "home",
        "layout": "grid",
        "theme": "93042030270d6867",
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
        "order": 2,
        "className": "",
        "visible": "true",
        "disabled": "false"
    },
    {
        "id": "4d19f97e8673be96",
        "type": "ui-group",
        "name": "1",
        "page": "93ca67d43751815a",
        "width": 6,
        "height": 1,
        "order": 1,
        "showTitle": false,
        "className": "",
        "visible": "true",
        "disabled": "false",
        "groupType": "default"
    },
    {
        "id": "5198508231fcf8a8",
        "type": "exec",
        "z": "df4a94479416f0c4",
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
                "f3b472b4726bfeec"
            ],
            [],
            []
        ]
    },
    {
        "id": "f3b472b4726bfeec",
        "type": "function",
        "z": "df4a94479416f0c4",
        "name": "function 2",
        "func": "let ip = msg.payload.replace(/[\\r\\n\\t ]/g, \"\");\nlet get_ip = global.get(\"config.state.ip\");\n    if((get_ip === undefined && ip) || ip){\n        global.set(\"config.state.ip\", ip);\n    };\nmsg.payload = {\n    fill: \"yellow\",\n    shape: \"ring\",\n    text: `IP:${ip}`\n};\nreturn msg;",
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
        "id": "6b6cdff899b96d18",
        "type": "inject",
        "z": "df4a94479416f0c4",
        "name": "",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            },
            {
                "p": "path",
                "v": "/home/orangepi/loom/data/log.csv",
                "vt": "str"
            }
        ],
        "repeat": "3",
        "crontab": "",
        "once": false,
        "onceDelay": 0.1,
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 95,
        "y": 200,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "1ab2c4d09e12f25f",
        "type": "function",
        "z": "df4a94479416f0c4",
        "name": "function 13",
        "func": "const index = global.get(\"config.state.index\");\nconst ip = msg.payload[index - 1].ip;\n if(!ip){\n    global.set(\"config.state.index\", index + 1);\n }",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 375,
        "y": 200,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "3b8945c733c04fba",
        "type": "file in",
        "z": "df4a94479416f0c4",
        "name": "",
        "filename": "path",
        "filenameType": "msg",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "none",
        "allProps": false,
        "x": 200,
        "y": 200,
        "wires": [
            [
                "a703196f82a9e5ef"
            ]
        ]
    },
    {
        "id": "a703196f82a9e5ef",
        "type": "csv",
        "z": "df4a94479416f0c4",
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
        "y": 200,
        "wires": [
            [
                "1ab2c4d09e12f25f"
            ]
        ],
        "l": false
    },
    {
        "id": "59eb51568d8158c9",
        "type": "moment",
        "z": "a67f25631bef1988",
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
                "23bad38c2d77961c"
            ]
        ],
        "l": false
    },
    {
        "id": "23bad38c2d77961c",
        "type": "function",
        "z": "a67f25631bef1988",
        "name": "function 1",
        "func": "var date = new Date(msg.payload);\nlet previousDate = new Date(date); \n    previousDate.setDate(previousDate.getDate() - 1).toString().padStart(2, 0);\nvar year = date.getFullYear(); \nvar month = (date.getMonth() + 1).toString().padStart(2, '0');\nvar day = date.getDate().toString().padStart(2, '0');\nvar hours = date.getHours().toString().padStart(2, '0');\nvar minutes = date.getMinutes().toString().padStart(2, '0');\nvar seconds = date.getSeconds().toString().padStart(2, '0');\nvar dateMian = `${year}/${month}/${day}`;\nvar time = `${hours}:${minutes}:${seconds}`;\nvar datestamp = global.get(\"config.state.datestamp\");\nlet hoursNum = Number(hours);\n    globalSet();\n////////////////////////////// end function set date ///////////////////////////////////////\nif (hoursNum >= 8 && hoursNum <= 23) {\n    let dateset = filename(date);\n    var datenow = dateNow(date);\n    global.set(\"config.state.date_data\", dateset);\n} else {\n    let dateset = filename(previousDate);\n    var datenow = dateNow(previousDate);\n    global.set(\"config.state.date_data\", dateset);\n}\n\nif (datestamp) {\n    if (datenow != datestamp) {\n        resetValues();\n        // global.set(\"report\", true);\n        // stamp date\n        global.set(\"config.state.datestamp\", datenow);\n    } else {\n        // stamp date\n        global.set(\"config.state.datestamp\", datenow);\n    }\n} else {\n    global.set(\"config.state.datestamp\", datenow);\n}\n    global.set(\"config.state.datenow\", datenow);\n    msg.payload = {\n        fill: \"green\",\n        shape: \"ring\",\n        text: `DATESTAMP:${datestamp} DATE${day}/${month}/${year} TIME:${time}`\n    };\n    return msg;\n\nfunction filename(date){\n    let year = date.getFullYear();\n    let month = (date.getMonth() + 1).toString().padStart(2, '0');\n    let day = date.getDate().toString().padStart(2, '0');\n    return `${year}${month}${day}`;\n}\n\nfunction resetValues(){\n    var meter = new Array(24).fill(0);\n    global.set(\"values.meter\", meter);\n    var working = new Array(24).fill(0);\n    global.set(\"values.working\", working);\n    global.set(\"values.maintake.main.min\", 0);\n    global.set(\"values.maintake.main.min\", 0);\n    global.set(\"values.maintake.take.min\", 0);\n    global.set(\"values.maintake.take.max\", 0);\n    global.set(\"config.state.upt.nla\", 0);\n    global.set(\"config.state.upt.ota\", 0);\n    global.set(\"config.state.upt.totalA\", 0);\n    global.set(\"config.state.upt.nlb\", 0);\n    global.set(\"config.state.upt.otb\", 0);\n    global.set(\"config.state.upt.totalB\", 0);\n}\n\nfunction globalSet(){\n    global.set(\"config.datetime.date\", dateMian);\n    global.set(\"config.datetime.day\", day);\n    global.set(\"config.datetime.month\", month);\n    global.set(\"config.datetime.year\", year);\n    global.set(\"config.datetime.time\", time);\n    global.set(\"config.datetime.hour\", hours);\n    global.set(\"config.datetime.minute\", minutes);\n    global.set(\"config.datetime.second\", seconds);\n}\n\nfunction dateNow(date){\n    let year = date.getFullYear();\n    let month = (date.getMonth() + 1).toString().padStart(2, '0');\n    let day = date.getDate().toString().padStart(2, '0');\n    return `${year}${month}${day}`;\n}",
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
        "func": "global.set(\"config.state.connected\", (msg.payload) ? true : false);\nmsg.payload = global.get(\"config.state.connected\");\nreturn msg;",
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
                "c7fcb9a183a78340",
                "346948538b2e924a"
            ]
        ]
    },
    {
        "id": "346948538b2e924a",
        "type": "function",
        "z": "13f006802899e0be",
        "name": "function 686",
        "func": "var sho2 = `[${global.get(\"config.datetime.time\")}] Connected:${global.get(\"config.state.connected\")}`;\nmsg.payload = {\n    \"fill\": \"blue\",\n    \"shape\": \"dot\",\n    \"text\": sho2\n}\nreturn msg;",
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
        "id": "c7fcb9a183a78340",
        "type": "function",
        "z": "13f006802899e0be",
        "name": "function 687",
        "func": "let c1 = global.get(\"config.state.connected\");\nlet stat = flow.get(\"stat\"); // ใช้ตัวแปรใน flow เพื่อเก็บสถานะ\n// ตรวจสอบว่า payload เปลี่ยนแปลงหรือยัง\nif (stat === undefined) {\n    // ถ้ายังไม่มีสถานะเก็บไว้ (สถานะเริ่มต้น)\n    stat = {\n        payload: 1, // ค่าพื้นฐานของ payload\n        isProcessed: false // กำหนดสถานะให้ทำงานได้ครั้งแรก\n    };\n    flow.set(\"stat\", stat); // เก็บสถานะใน flow\n}\n// ตรวจสอบเงื่อนไขที่กำหนด\nif (c1) {\n    if (stat.payload !== 3) { // ตรวจสอบว่า payload มีการเปลี่ยนแปลงหรือไม่\n        msg.payload = 3;\n        stat.payload = 3; // อัปเดตสถานะ payload\n        stat.isProcessed = true; // ตั้งค่าสถานะว่าได้ทำการประมวลผลแล้ว\n        return msg;\n    }\n} else {\n    if (stat.payload !== 2) { // ตรวจสอบว่า payload มีการเปลี่ยนแปลงหรือไม่\n        msg.payload = 2;\n        stat.payload = 2; // อัปเดตสถานะ payload\n        stat.isProcessed = true; // ตั้งค่าสถานะว่าได้ทำการประมวลผลแล้ว\n        return msg;\n    }\n}\nflow.set(\"stat\", stat); // อัปเดตสถานะใน flow",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 430,
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
        "once": true,
        "onceDelay": "35",
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 135,
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
        "func": "let time_cal = msg.payload - global.get(\"config.datetime.timestamp\");\nlet count = flow.get(\"count\") || 0;\ntime_cal > 10000 || !global.get(\"config.datetime.timestamp\") ? flow.set(\"count\", count + 1) : flow.set(\"count\", 0); // 3000 millisec\nreturn count > 300 ? msg : undefined;",
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
                "ce2564d1100f0cb3"
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
        "x": 280,
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
        "x": 650,
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
        "id": "4bcac64d1b91385f",
        "type": "subflow:1406c468fdce7358",
        "z": "e226ede58ea4b202",
        "name": "",
        "x": 500,
        "y": 160,
        "wires": [
            [
                "9eb83d2ca8ce536d"
            ]
        ]
    },
    {
        "id": "ce2564d1100f0cb3",
        "type": "function",
        "z": "e226ede58ea4b202",
        "name": "function 11",
        "func": "let wot = flow.get(\"wot\");\nif (!wot) {\n    msg.payload = `❗⛓️‍💥 ${global.get(\"config.state.ip\")} > การส่งข้อมูลของ Converter RS485 อาจมีปัญหา...`;\n    node.status({ fill: \"green\", shape: \"ring\", text: global.get(\"time\") });\n    flow.set(\"wot\", true);\n    return msg;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 375,
        "y": 160,
        "wires": [
            [
                "4bcac64d1b91385f"
            ]
        ],
        "l": false
    },
    {
        "id": "861f956f24a820d1",
        "type": "file",
        "z": "aa3c99c011a59edd",
        "name": "config",
        "filename": "/home/orangepi/loom/config.txt.tmp",
        "filenameType": "str",
        "appendNewline": false,
        "createDir": true,
        "overwriteFile": "true",
        "encoding": "utf8",
        "x": 310,
        "y": 40,
        "wires": [
            [
                "529efc0a45b6c9d8"
            ]
        ],
        "icon": "node-red/redis.svg"
    },
    {
        "id": "67264d9b0e343db6",
        "type": "function",
        "z": "aa3c99c011a59edd",
        "name": "fig value",
        "func": "msg.payload = {\n    \"state\": {\n        \"datestamp\": global.get(\"config.state.datestamp\"),\n        \"hourstamp\": global.get(\"config.state.hourstamp\"),\n        \"changehour\": global.get(\"config.state.changehour\"),\n        \"upt\":{\n            \"nla\": global.get(\"config.state.upt.nla\") || 0,\n            \"ota\": global.get(\"config.state.upt.ota\") || 0,\n            \"totalA\": global.get(\"config.state.upt.totalA\") || 0,\n            \"nlb\": global.get(\"config.state.upt.nlb\") || 0,\n            \"otb\": global.get(\"config.state.upt.otb\") || 0,\n            \"totalB\": global.get(\"config.state.upt.totalB\") || 0,\n            \"total\": global.get(\"config.state.upt.total\") || 0,\n        },\n        \"index\": global.get(\"config.state.index\"),\n        \"ip\": global.get(\"config.state.ip\"),\n        \"version\": global.get(\"version\") || \"-\"\n    },\n    \"values\": {\n        \"maintake\": {\n            \"main\": {\n                \"min\": global.get(\"values.maintake.main.min\"),\n                \"max\": global.get(\"values.maintake.main.max\")\n            },\n            \"take\": {\n                \"min\": global.get(\"values.maintake.take.min\"),\n                \"max\": global.get(\"values.maintake.take.max\")\n            }\n        },\n        \"meter\": global.get(\"values.meter\"),\n        \"working\": global.get(\"values.working\")\n    }\n}\nreturn msg;",
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
                "861f956f24a820d1"
            ]
        ]
    },
    {
        "id": "529efc0a45b6c9d8",
        "type": "exec",
        "z": "aa3c99c011a59edd",
        "command": ". $HOME/loom/scriptConfig.sh",
        "addpay": "",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "move .tmp",
        "x": 470,
        "y": 60,
        "wires": [
            [
                "4fa647803c42f119"
            ],
            [],
            []
        ]
    },
    {
        "id": "4fa647803c42f119",
        "type": "function",
        "z": "aa3c99c011a59edd",
        "name": "function 689",
        "func": "msg.payload = {\n    'fill': 'blue',\n    'shape': 'dot',\n    'text': `${global.get(\"config.datetime.time\")} : ${msg.filename}` \n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 650,
        "y": 60,
        "wires": [
            []
        ]
    },
    {
        "id": "5730377ef1841b85",
        "type": "function",
        "z": "b7d6774c49a75902",
        "name": "list",
        "func": "var fileList = msg.payload;\nvar fileno = fileList.length;\n    global.set(\"config.state.file\", fileno)\n    return msg;",
        "outputs": 1,
        "timeout": "",
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 210,
        "y": 80,
        "wires": [
            [
                "0d197ce9478787bb"
            ]
        ]
    },
    {
        "id": "9ac210c7c0b99891",
        "type": "fs-file-lister",
        "z": "b7d6774c49a75902",
        "name": "file list",
        "start": "/home/orangepi/loom/data/",
        "pattern": "*.*",
        "folders": "*",
        "hidden": true,
        "lstype": "files",
        "path": true,
        "single": true,
        "depth": "0",
        "stat": true,
        "showWarnings": false,
        "x": 125,
        "y": 80,
        "wires": [
            [
                "5730377ef1841b85"
            ]
        ],
        "l": false
    },
    {
        "id": "0d197ce9478787bb",
        "type": "function",
        "z": "b7d6774c49a75902",
        "name": "function 6",
        "func": "msg.payload = {\n    fill : \"bule\",\n    shape : \"dot\",\n    text: `file:${global.get(\"config.state.file\")}}`\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 360,
        "y": 120,
        "wires": [
            []
        ]
    },
    {
        "id": "581e4659c476b910",
        "type": "file in",
        "z": "341bdc3e7e68ae46",
        "name": "Read",
        "filename": "/home/orangepi/loom/config.txt",
        "filenameType": "str",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "utf8",
        "allProps": false,
        "x": 310,
        "y": 140,
        "wires": [
            [
                "1af31287089bf3ac",
                "24e85514de7978d5"
            ]
        ],
        "icon": "node-red/sort.svg"
    },
    {
        "id": "1af31287089bf3ac",
        "type": "function",
        "z": "341bdc3e7e68ae46",
        "name": "Set value",
        "func": "const payload = JSON.parse(msg.payload);\n    global.set(\"config.state.ip\", payload.state.ip);\n    global.set(\"config.state.datestamp\", payload.state.datestamp);\n    global.set(\"config.state.index\", payload.state.index);\n    global.set(\"config.state.changehour\", payload.state.changehour);\n    global.set(\"config.state.upt.total\", payload.state.upt.total);\n    global.set(\"config.state.upt.nla\", payload.state.upt.nla);\n    global.set(\"config.state.upt.ota\", payload.state.upt.ota);\n    global.set(\"config.state.upt.totalA\", payload.state.upt.totalA);\n    global.set(\"config.state.upt.nlb\", payload.state.upt.nlb);\n    global.set(\"config.state.upt.otb\", payload.state.upt.otb);\n    global.set(\"config.state.upt.totalB\", payload.state.upt.totalB);\n    global.set(\"version\", payload.state.version || \"-\");\n    let main_min = payload.values.maintake.main.min ;\n    global.set(\"values.maintake.main.min\", main_min);\n    let main_max = payload.values.maintake.main.max ;\n    global.set(\"values.maintake.main.max\", main_max);\n    let take_min = payload.values.maintake.take.min ;\n    global.set(\"values.maintake.take.min\", take_min);\n    let take_max = payload.values.maintake.take.max ;\n    global.set(\"values.maintake.take.max\", take_max);\n    const arr1 = new Array(24).fill(0);\n    const arr2 = new Array(24).fill(0);\n    let meter = payload.values.meter;\n    global.set(\"values.meter\", meter || arr1);\n    let working = payload.values.working;\n    global.set(\"values.working\", working || arr2);\n    ",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 415,
        "y": 140,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "0010ce9b239656e0",
        "type": "catch",
        "z": "341bdc3e7e68ae46",
        "name": "",
        "scope": [
            "581e4659c476b910",
            "1af31287089bf3ac"
        ],
        "uncaught": false,
        "x": 310,
        "y": 180,
        "wires": [
            [
                "4c08362380676e6d"
            ]
        ]
    },
    {
        "id": "403b9f45ce07e19d",
        "type": "function",
        "z": "341bdc3e7e68ae46",
        "name": "function 10",
        "func": "const payload = JSON.parse(msg.payload);\n    global.set(\"config.state.ip\", payload.state.ip);\n    global.set(\"config.state.datestamp\", payload.state.datestamp);\n    global.set(\"config.state.index\", payload.state.index);\n    global.set(\"config.state.changehour\", payload.state.changehour);\n    global.set(\"config.state.upt.total\", payload.state.upt.total);\n    global.set(\"config.state.upt.nla\", payload.state.upt.nla);\n    global.set(\"config.state.upt.ota\", payload.state.upt.ota);\n    global.set(\"config.state.upt.totalA\", payload.state.upt.totalA);\n    global.set(\"config.state.upt.nlb\", payload.state.upt.nlb);\n    global.set(\"config.state.upt.otb\", payload.state.upt.otb);\n    global.set(\"config.state.upt.totalB\", payload.state.upt.totalB);\n    global.set(\"version\", payload.state.version || \"-\");\n    let main_min = payload.values.maintake.main.min ;\n    global.set(\"values.maintake.main.min\", main_min);\n    let main_max = payload.values.maintake.main.max ;\n    global.set(\"values.maintake.main.max\", main_max);\n    let take_min = payload.values.maintake.take.min ;\n    global.set(\"values.maintake.take.min\", take_min);\n    let take_max = payload.values.maintake.take.max ;\n    global.set(\"values.maintake.take.max\", take_max);\n    const arr1 = new Array(24).fill(0);\n    const arr2 = new Array(24).fill(0);\n    let meter = payload.values.meter;\n    global.set(\"values.meter\", meter || arr1);  \n    let working = payload.values.working;\n    global.set(\"values.working\", working || arr2);\n    return msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 545,
        "y": 180,
        "wires": [
            [
                "13e5e83fe8bf9607",
                "28a9aa3fad6e642c"
            ]
        ],
        "l": false
    },
    {
        "id": "24e85514de7978d5",
        "type": "function",
        "z": "341bdc3e7e68ae46",
        "name": "function 11",
        "func": "if(msg.payload){\nmsg.payload = {\n    'fill': 'bule',\n    'shape': 'dot',\n    'text': `ts: ${flow.get(\"ts\")}`\n}\nreturn msg;\n}\n",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 490,
        "y": 80,
        "wires": [
            []
        ]
    },
    {
        "id": "7dcb29351996d6be",
        "type": "delay",
        "z": "341bdc3e7e68ae46",
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
        "y": 140,
        "wires": [
            [
                "581e4659c476b910"
            ]
        ]
    },
    {
        "id": "258890b7306744af",
        "type": "file in",
        "z": "341bdc3e7e68ae46",
        "name": "",
        "filename": "/home/orangepi/loom/data/log.csv",
        "filenameType": "str",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "none",
        "allProps": false,
        "x": 115,
        "y": 100,
        "wires": [
            [
                "b8503deb0ae9cab9"
            ]
        ],
        "l": false
    },
    {
        "id": "b8503deb0ae9cab9",
        "type": "csv",
        "z": "341bdc3e7e68ae46",
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
        "x": 175,
        "y": 100,
        "wires": [
            [
                "48a2a0290809c5a0"
            ]
        ],
        "l": false
    },
    {
        "id": "48a2a0290809c5a0",
        "type": "function",
        "z": "341bdc3e7e68ae46",
        "name": "le",
        "func": "var length = msg.payload.length\nlength = length - 1\nglobal.set(\"config.state.row\", length)",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 235,
        "y": 100,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "8e7c7d80304fe097",
        "type": "function",
        "z": "341bdc3e7e68ae46",
        "name": "function 12",
        "func": "const date = new Date(msg.payload);\n\nconst bangkokTime = date.toLocaleString('en-GB', { \n  timeZone: 'Asia/Bangkok',\n  year: 'numeric', month: '2-digit', day: '2-digit',\n  hour: '2-digit', minute: '2-digit', second: '2-digit'\n});\nflow.set(\"ts\", bangkokTime);\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 170,
        "y": 180,
        "wires": [
            []
        ]
    },
    {
        "id": "d6c523303ab0a091",
        "type": "file in",
        "z": "341bdc3e7e68ae46",
        "name": "",
        "filename": "/home/orangepi/loom/source.txt",
        "filenameType": "str",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "none",
        "allProps": false,
        "x": 115,
        "y": 60,
        "wires": [
            [
                "061df98b883d0c2f"
            ]
        ],
        "l": false
    },
    {
        "id": "061df98b883d0c2f",
        "type": "function",
        "z": "341bdc3e7e68ae46",
        "name": "le",
        "func": "var source = Number(msg.payload)\nglobal.set(\"source\", source)",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 175,
        "y": 60,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "4c08362380676e6d",
        "type": "file in",
        "z": "341bdc3e7e68ae46",
        "name": "Read",
        "filename": "/home/orangepi/loom/config.txt.bak",
        "filenameType": "str",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "utf8",
        "allProps": false,
        "x": 450,
        "y": 180,
        "wires": [
            [
                "403b9f45ce07e19d"
            ]
        ],
        "icon": "node-red/sort.svg"
    },
    {
        "id": "13e5e83fe8bf9607",
        "type": "exec",
        "z": "341bdc3e7e68ae46",
        "command": "cp $HOME/loom/config.txt.bak $HOME/loom/config.txt",
        "addpay": "",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "repiar config",
        "x": 650,
        "y": 200,
        "wires": [
            [],
            [],
            []
        ]
    },
    {
        "id": "133f022c804089c9",
        "type": "subflow:1406c468fdce7358",
        "z": "341bdc3e7e68ae46",
        "name": "",
        "x": 740,
        "y": 140,
        "wires": [
            []
        ]
    },
    {
        "id": "28a9aa3fad6e642c",
        "type": "function",
        "z": "341bdc3e7e68ae46",
        "name": "function 690",
        "func": "\nif (1) {\n    msg.payload = `🗂️ ${global.get(\"config.state.ip\")} > Orange Pi เกิดปัญหาในการอ่านไฟล์ Config... Overwrite > config.txt`;\n    node.status({ fill: \"green\", shape: \"ring\", text: global.get(\"time\") });\n    flow.set(\"wot\", true);\n    return msg;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 615,
        "y": 140,
        "wires": [
            [
                "133f022c804089c9"
            ]
        ],
        "l": false
    },
    {
        "id": "3925be8bad2bdf74",
        "type": "file in",
        "z": "424004941bcb3307",
        "name": "",
        "filename": "path",
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
                "8104a50cbc2556ae"
            ]
        ]
    },
    {
        "id": "8104a50cbc2556ae",
        "type": "csv",
        "z": "424004941bcb3307",
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
            [
                "0a3028182b518b6e"
            ]
        ],
        "l": false
    },
    {
        "id": "0a3028182b518b6e",
        "type": "function",
        "z": "424004941bcb3307",
        "name": "API Power",
        "func": "const index = global.get(\"config.state.index\") || 0;\n\nconst date = msg.payload[index].date;\nconst time = msg.payload[index].time;\nconst date_data = msg.payload[index].date_data;\nconst ip = msg.payload[index].ip;\nconst timestamp = msg.payload[index].timestamp;\n\nconst meter = [\n    msg.payload[index].m_0,\n    msg.payload[index].m_1,\n    msg.payload[index].m_2,\n    msg.payload[index].m_3,\n    msg.payload[index].m_4,\n    msg.payload[index].m_5,\n    msg.payload[index].m_6,\n    msg.payload[index].m_7,\n    msg.payload[index].m_8,\n    msg.payload[index].m_9,\n    msg.payload[index].m_10,\n    msg.payload[index].m_11,\n    msg.payload[index].m_12,\n    msg.payload[index].m_13,\n    msg.payload[index].m_14,\n    msg.payload[index].m_15,\n    msg.payload[index].m_16,\n    msg.payload[index].m_17,\n    msg.payload[index].m_18,\n    msg.payload[index].m_19,\n    msg.payload[index].m_20,\n    msg.payload[index].m_21,\n    msg.payload[index].m_22,\n    msg.payload[index].m_23,\n]\n\nconst working = [\n    msg.payload[index].w_0,\n    msg.payload[index].w_1,\n    msg.payload[index].w_2,\n    msg.payload[index].w_3,\n    msg.payload[index].w_4,\n    msg.payload[index].w_5,\n    msg.payload[index].w_6,\n    msg.payload[index].w_7,\n    msg.payload[index].w_8,\n    msg.payload[index].w_9,\n    msg.payload[index].w_10,\n    msg.payload[index].w_11,\n    msg.payload[index].w_12,\n    msg.payload[index].w_13,\n    msg.payload[index].w_14,\n    msg.payload[index].w_15,\n    msg.payload[index].w_16,\n    msg.payload[index].w_17,\n    msg.payload[index].w_18,\n    msg.payload[index].w_19,\n    msg.payload[index].w_20,\n    msg.payload[index].w_21,\n    msg.payload[index].w_22,\n    msg.payload[index].w_23,\n]\n\nconst API = {\n    'filesystem':{ \n        date: date, \n        time: time, \n        ip: ip, \n        date_data: date_data,\n        timestamp: timestamp,\n        'upTime': {\n            'total': global.get(\"config.state.upt.total\"),\n            'totalA': global.get(\"config.state.upt.totalA\"),\n            'totalB': global.get(\"config.state.upt.totalB\"),\n            'nla': global.get(\"config.state.upt.nla\"),\n            'ota': global.get(\"config.state.upt.ota\"),\n            'nlb': global.get(\"config.state.upt.nlb\"),\n            'otb': global.get(\"config.state.upt.otb\"),\n        }\n    },\n    'values':{\n        'meter': {\n            0: meter[0], 1: meter[1], 2: meter[2], 3: meter[3], 4: meter[4], 5: meter[5],\n            6: meter[6], 7: meter[7], 8: meter[8], 9: meter[9], 10: meter[10], 11: meter[11],\n            12: meter[12], 13: meter[13], 14: meter[14], 15: meter[15], 16: meter[16], 17: meter[17],\n            18: meter[18], 19: meter[19], 20: meter[20], 21: meter[21], 22: meter[22], 23: meter[23]\n        },\n        'working': {\n            0: working[0], 1: working[1], 2: working[2], 3: working[3], 4: working[4], 5: working[5],\n            6: working[6], 7: working[7], 8: working[8], 9: working[9], 10: working[10], 11: working[11],\n            12: working[12], 13: working[13], 14: working[14], 15: working[15], 16: working[16], 17: working[17],\n            18: working[18], 19: working[19], 20: working[20], 21: working[21], 22: working[22], 23: working[23]\n        },\n        'total':{\n            \"meter\":{\n                \"total\": msg.payload[index].total_meter,\n                \"totalA\": msg.payload[index].total_meterA,\n                \"totalB\": msg.payload[index].total_meterB,\n                \"NLA\": msg.payload[index].meterNLA,\n                \"NLB\": msg.payload[index].meterNLB,\n                \"OTA\": msg.payload[index].meterOTA,\n                \"OTB\": msg.payload[index].meterOTB,\n            },\n            \"working\":{\n                \"total\": msg.payload[index].total_working,\n                \"totalA\": msg.payload[index].total_workingA,\n                \"totalB\": msg.payload[index].total_workingB,\n                \"NLA\": msg.payload[index].workingNLA,\n                \"NLB\": msg.payload[index].workingNLB,\n                \"OTA\": msg.payload[index].workingOTA,\n                \"OTB\": msg.payload[index].workingOTB,\n            }\n        },\n        'maintake':{\n            'main':{\n                'now': msg.payload[index].main_now,\n                'min': msg.payload[index].main_min,\n                'max': msg.payload[index].main_max\n            },\n            'take':{\n                'now': msg.payload[index].take_now,\n                'min': msg.payload[index].take_min,\n                'max': msg.payload[index].take_max\n            }\n        }\n    }\n};\nmsg.payload = JSON.stringify(API);\nreturn msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 430,
        "y": 40,
        "wires": [
            []
        ]
    },
    {
        "id": "db40ab8bf0220701",
        "type": "catch",
        "z": "424004941bcb3307",
        "name": "",
        "scope": [
            "0a3028182b518b6e"
        ],
        "uncaught": false,
        "x": 90,
        "y": 100,
        "wires": [
            [
                "f5d79e7797a4b637"
            ]
        ]
    },
    {
        "id": "f5d79e7797a4b637",
        "type": "function",
        "z": "424004941bcb3307",
        "name": "function 9",
        "func": "let index = global.get(\"config.state.index\");\nglobal.set(\"config.state.index\", index + 1);",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 240,
        "y": 100,
        "wires": [
            []
        ]
    },
    {
        "id": "4a84a0a8603ab232",
        "type": "exec",
        "z": "a007640620fd4d52",
        "command": "./stat_led/blink11.sh",
        "addpay": "payload",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "blink11",
        "x": 360,
        "y": 40,
        "wires": [
            [],
            [],
            []
        ]
    },
    {
        "id": "6f98bf351570cfd0",
        "type": "function",
        "z": "a007640620fd4d52",
        "name": "function 664",
        "func": "msg.payload = 1\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 170,
        "y": 40,
        "wires": [
            [
                "4a84a0a8603ab232"
            ]
        ]
    },
    {
        "id": "79406b7c65e62058",
        "type": "exec",
        "z": "77aa6425a6e4878c",
        "command": "",
        "addpay": "remove",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "",
        "x": 270,
        "y": 80,
        "wires": [
            [],
            [],
            []
        ]
    },
    {
        "id": "9112ab91340ace88",
        "type": "function",
        "z": "77aa6425a6e4878c",
        "name": "function 3",
        "func": "let index = global.get(\"config.state.index\");\nlet row = global.get(\"config.state.row\");\nif(row > 1000 && index == row){\n    msg.remove = `rm /home/orangepi/loom/data/log.csv`;\n    global.set(\"config.state.index\", 0);\n    return msg;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 155,
        "y": 80,
        "wires": [
            [
                "79406b7c65e62058"
            ]
        ],
        "icon": "font-awesome/fa-times-circle",
        "l": false
    },
    {
        "id": "933493d52353d337",
        "type": "http in",
        "z": "a6ecc454e1b3c0c3",
        "name": "API",
        "url": "/api/power-data",
        "method": "get",
        "upload": false,
        "swaggerDoc": "",
        "x": 1025,
        "y": 420,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "fb1eb8640f6f4943",
        "type": "http response",
        "z": "a6ecc454e1b3c0c3",
        "name": "API Response",
        "statusCode": "",
        "headers": {},
        "x": 1445,
        "y": 420,
        "wires": [],
        "l": false
    },
    {
        "id": "f6905c9e73692c2d",
        "type": "function",
        "z": "a6ecc454e1b3c0c3",
        "name": "function 645",
        "func": "var index = global.get(\"index.i0\") || 0;\n    index = index + 1;\n    global.set(\"index.i0\", index);\nmsg.payload = {\n    fill: \"blue\",\n    shape: \"dot\",\n    text: `HTTP:[Time:${global.get(\"time\")}]`\n    };\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 1405,
        "y": 440,
        "wires": [
            [
                "7420857d31044523"
            ]
        ],
        "icon": "font-awesome/fa-check",
        "l": false
    },
    {
        "id": "7420857d31044523",
        "type": "subflow:77aa6425a6e4878c",
        "z": "a6ecc454e1b3c0c3",
        "name": "",
        "x": 1510,
        "y": 480,
        "wires": []
    },
    {
        "id": "c33b83fa52c22681",
        "type": "subflow:a007640620fd4d52",
        "z": "a6ecc454e1b3c0c3",
        "name": "",
        "x": 1405,
        "y": 400,
        "wires": [],
        "l": false
    },
    {
        "id": "c3b32e2e3482646f",
        "type": "subflow:424004941bcb3307",
        "z": "a6ecc454e1b3c0c3",
        "name": "",
        "x": 1310,
        "y": 420,
        "wires": [
            [
                "c33b83fa52c22681",
                "fb1eb8640f6f4943",
                "f6905c9e73692c2d"
            ]
        ]
    },
    {
        "id": "634c3eb58dd47522",
        "type": "function",
        "z": "a6ecc454e1b3c0c3",
        "name": "Path",
        "func": "var connected = global.get(\"Connect.c0\");\nvar row = global.get(\"row.r0\");\nvar index = global.get(\"index.i0\");\nmsg.path_power = \"/home/orangepi/powermeter/log_power/log.csv\";\nif (connected && (index < row)){\n    node.status({fill:\"green\",shape:\"dot\",text:`index:${global.get(\"index\")} row:${global.get(\"row\")}`});\n    return msg;\n}else{\n    node.status({fill:\"green\",shape:\"dot\",text:`index:${global.get(\"index\")} row:${global.get(\"row\")}`})\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 1150,
        "y": 420,
        "wires": [
            [
                "c3b32e2e3482646f"
            ]
        ]
    },
    {
        "id": "2cfa0e1ee1913505",
        "type": "http request",
        "z": "a6ecc454e1b3c0c3",
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
        "x": 650,
        "y": 120,
        "wires": [
            [
                "043a074eaca99487"
            ]
        ]
    },
    {
        "id": "0b36a72b6512a560",
        "type": "function",
        "z": "a6ecc454e1b3c0c3",
        "name": "function 14",
        "func": "delete msg.tocloud;\ndelete msg.columns;\nmsg.url = `http://192.168.0.9:1880/api/product/device-opi-datasource-${global.get(\"source\")}`\nmsg.method = \"POST\";\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 535,
        "y": 120,
        "wires": [
            [
                "2cfa0e1ee1913505",
                "67854f70e118416c"
            ]
        ],
        "l": false
    },
    {
        "id": "043a074eaca99487",
        "type": "function",
        "z": "a6ecc454e1b3c0c3",
        "name": "function 15",
        "func": "const code = msg.statusCode;\nif(code === 200){\n    var index = global.get(\"config.state.index\") || 0;\n    index = index + 1;\n    global.set(\"config.state.index\", index);\n}\nmsg.payload = {\n    fill: \"blue\",\n    shape: \"dot\",\n    text: `http:[Time:${global.get(\"config.datetime.time\")} State: ${code}] row:${global.get(\"config.state.row\")} index:${global.get(\"config.state.index\")}`\n    };\nreturn msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 840,
        "y": 120,
        "wires": [
            [
                "866dc313d77cb598"
            ]
        ]
    },
    {
        "id": "866dc313d77cb598",
        "type": "subflow:77aa6425a6e4878c",
        "z": "a6ecc454e1b3c0c3",
        "name": "",
        "x": 975,
        "y": 160,
        "wires": [],
        "l": false
    },
    {
        "id": "6d9ae71f879ce0a3",
        "type": "subflow:a007640620fd4d52",
        "z": "a6ecc454e1b3c0c3",
        "name": "",
        "x": 485,
        "y": 100,
        "wires": [],
        "l": false
    },
    {
        "id": "fce74f821aaeba36",
        "type": "subflow:424004941bcb3307",
        "z": "a6ecc454e1b3c0c3",
        "name": "",
        "x": 390,
        "y": 120,
        "wires": [
            [
                "6d9ae71f879ce0a3",
                "0b36a72b6512a560"
            ]
        ]
    },
    {
        "id": "1cb42bbca3762b28",
        "type": "function",
        "z": "a6ecc454e1b3c0c3",
        "name": "Path",
        "func": "var connected = global.get(\"config.state.connected\");\nvar row = global.get(\"config.state.row\");\nvar index = global.get(\"config.state.index\") || 0;\nmsg.path = \"/home/orangepi/loom/data/log.csv\";\nif (connected && (index < row)){\n    return msg;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 230,
        "y": 120,
        "wires": [
            [
                "fce74f821aaeba36"
            ]
        ]
    },
    {
        "id": "485ac7c96e994e5a",
        "type": "inject",
        "z": "a6ecc454e1b3c0c3",
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
        "repeat": "5",
        "crontab": "",
        "once": true,
        "onceDelay": "60",
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 115,
        "y": 120,
        "wires": [
            [
                "1cb42bbca3762b28"
            ]
        ],
        "l": false
    },
    {
        "id": "4f891f3db959c16b",
        "type": "http request",
        "z": "a6ecc454e1b3c0c3",
        "name": "PC Office",
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
        "x": 640,
        "y": 180,
        "wires": [
            []
        ]
    },
    {
        "id": "bc79ff833f6c7a57",
        "type": "function",
        "z": "a6ecc454e1b3c0c3",
        "name": "PC Office",
        "func": "msg.url = `http://192.168.1.105:1880/api/product/device-opi-datasource-${global.get(\"source\")}`\nmsg.method = \"POST\";\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 535,
        "y": 180,
        "wires": [
            [
                "4f891f3db959c16b",
                "220b8e3652de1e40"
            ]
        ],
        "l": false
    },
    {
        "id": "a7375655513b6318",
        "type": "http request",
        "z": "a6ecc454e1b3c0c3",
        "name": "PC Cloud",
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
        "x": 640,
        "y": 240,
        "wires": [
            []
        ]
    },
    {
        "id": "c9cbf9c116349360",
        "type": "function",
        "z": "a6ecc454e1b3c0c3",
        "name": "function 24",
        "func": "msg.url = `http://147.50.230.159:1880/api/product/device-opi-datasource-${global.get(\"source\")}`\nmsg.method = \"POST\";\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 535,
        "y": 240,
        "wires": [
            [
                "a7375655513b6318"
            ]
        ],
        "l": false
    },
    {
        "id": "67854f70e118416c",
        "type": "delay",
        "z": "a6ecc454e1b3c0c3",
        "name": "",
        "pauseType": "delay",
        "timeout": "2",
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
        "x": 475,
        "y": 180,
        "wires": [
            [
                "bc79ff833f6c7a57"
            ]
        ],
        "l": false
    },
    {
        "id": "220b8e3652de1e40",
        "type": "delay",
        "z": "a6ecc454e1b3c0c3",
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
        "x": 475,
        "y": 240,
        "wires": [
            [
                "c9cbf9c116349360"
            ]
        ],
        "l": false
    },
    {
        "id": "35f043d859b8937c",
        "type": "ui-form",
        "z": "a6ecc454e1b3c0c3",
        "name": "Source",
        "group": "4d19f97e8673be96",
        "label": "",
        "order": 2,
        "width": "4",
        "height": 0,
        "options": [
            {
                "label": "source",
                "key": "source",
                "type": "dropdown",
                "required": true,
                "rows": null
            }
        ],
        "formValue": {
            "source": ""
        },
        "payload": "",
        "submit": "submit",
        "cancel": "",
        "resetOnSubmit": true,
        "topic": "topic",
        "topicType": "msg",
        "splitLayout": "",
        "className": "",
        "passthru": false,
        "dropdownOptions": [
            {
                "dropdown": "source",
                "value": "1",
                "label": "1"
            },
            {
                "dropdown": "source",
                "value": "2",
                "label": "2"
            },
            {
                "dropdown": "source",
                "value": "3",
                "label": "3"
            },
            {
                "dropdown": "source",
                "value": "4",
                "label": "4"
            },
            {
                "dropdown": "source",
                "value": "5",
                "label": "5"
            },
            {
                "dropdown": "source",
                "value": "6",
                "label": "6"
            },
            {
                "dropdown": "source",
                "value": "7",
                "label": "7"
            },
            {
                "dropdown": "source",
                "value": "8",
                "label": "8"
            },
            {
                "dropdown": "source",
                "value": "9",
                "label": "9"
            }
        ],
        "x": 140,
        "y": 440,
        "wires": [
            [
                "388a61be8ad3f3fd"
            ]
        ]
    },
    {
        "id": "6bda80ac4b036aac",
        "type": "ui-text",
        "z": "a6ecc454e1b3c0c3",
        "group": "4d19f97e8673be96",
        "order": 1,
        "width": "2",
        "height": "1",
        "name": "Source",
        "label": "Source : ",
        "format": "{{msg.payload}}",
        "layout": "row-center",
        "style": false,
        "font": "",
        "fontSize": 16,
        "color": "#717171",
        "wrapText": false,
        "className": "",
        "x": 700,
        "y": 400,
        "wires": []
    },
    {
        "id": "a4dab5d4091589a0",
        "type": "function",
        "z": "a6ecc454e1b3c0c3",
        "name": "function 26",
        "func": "msg.payload = global.get(\"source\") || \"-\";\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 550,
        "y": 400,
        "wires": [
            [
                "6bda80ac4b036aac"
            ]
        ]
    },
    {
        "id": "07a96f5ffd797c28",
        "type": "inject",
        "z": "a6ecc454e1b3c0c3",
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
        "once": true,
        "onceDelay": "60",
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 445,
        "y": 400,
        "wires": [
            [
                "a4dab5d4091589a0"
            ]
        ],
        "l": false
    },
    {
        "id": "388a61be8ad3f3fd",
        "type": "function",
        "z": "a6ecc454e1b3c0c3",
        "name": "function 28",
        "func": "msg.payload = msg.payload.source;\nvar source = Number(msg.payload)\nglobal.set(\"source\", source)\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 310,
        "y": 440,
        "wires": [
            [
                "51dc1c2d2107552d"
            ]
        ]
    },
    {
        "id": "51dc1c2d2107552d",
        "type": "file",
        "z": "a6ecc454e1b3c0c3",
        "name": "",
        "filename": "/home/orangepi/loom/source.txt",
        "filenameType": "str",
        "appendNewline": true,
        "createDir": true,
        "overwriteFile": "true",
        "encoding": "none",
        "x": 435,
        "y": 440,
        "wires": [
            [
                "a4dab5d4091589a0"
            ]
        ],
        "l": false
    },
    {
        "id": "329b2dc06d31e4a6",
        "type": "file",
        "z": "7a70a201eaa0a148",
        "name": "Write",
        "filename": "path",
        "filenameType": "msg",
        "appendNewline": false,
        "createDir": true,
        "overwriteFile": "false",
        "encoding": "utf8",
        "x": 115,
        "y": 80,
        "wires": [
            [
                "b899c4a32f80d2b3"
            ]
        ],
        "l": false
    },
    {
        "id": "7bda5491c4569ef2",
        "type": "file in",
        "z": "7a70a201eaa0a148",
        "name": "",
        "filename": "path",
        "filenameType": "msg",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "none",
        "allProps": false,
        "x": 235,
        "y": 80,
        "wires": [
            [
                "9ad283424a955e6e"
            ]
        ],
        "l": false
    },
    {
        "id": "b899c4a32f80d2b3",
        "type": "delay",
        "z": "7a70a201eaa0a148",
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
        "x": 175,
        "y": 80,
        "wires": [
            [
                "7bda5491c4569ef2"
            ]
        ],
        "l": false
    },
    {
        "id": "9ad283424a955e6e",
        "type": "csv",
        "z": "7a70a201eaa0a148",
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
        "x": 295,
        "y": 80,
        "wires": [
            [
                "6bf085a9f0b65ea1"
            ]
        ],
        "l": false
    },
    {
        "id": "6bf085a9f0b65ea1",
        "type": "function",
        "z": "7a70a201eaa0a148",
        "name": "le",
        "func": "var length = msg.payload.length;\nlength = length - 1;\nglobal.set(\"config.state.row\", length);\nif(length <= 1){\n    global.set(\"config.state.index\", 0);\n};\nmsg.payload = {\n    fill: \"blue\",\n    shape: \"dot\",\n    text: `row:${length}`};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 355,
        "y": 80,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "ef469af3a6dd75f8",
        "type": "switch",
        "z": "f1016d6dfc436da7",
        "name": "",
        "property": "file",
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
        "x": 125,
        "y": 60,
        "wires": [
            [
                "94b9bf90eedb0722"
            ],
            [
                "b536e3111c63eed1"
            ]
        ],
        "l": false
    },
    {
        "id": "94b9bf90eedb0722",
        "type": "function",
        "z": "f1016d6dfc436da7",
        "name": "data Log",
        "func": "const payload = msg.payload;\nconst date = payload.date;\nconst time = payload.time;\nconst timestamp = payload.timestamp;\nconst ip = payload.ip;\nconst date_data = payload.date_data;\nconst upt = payload.upt;\n\n// values \nconst main = payload.values.maintake.main;\nconst take = payload.values.maintake.take;\nconst meter = payload.values.meter;\nconst working = payload.values.working;\nconst total = payload.values.total;\n\nmsg.payload = {\n    'date': date,\n    'time': time,\n    'timestamp': timestamp,\n    'ip': ip,\n    'date_data': date_data,\n    'total_meter': total.meter.total,\n    'total_meterA': total.meter.totala,\n    'total_meterB': total.meter.totalb,\n    'meterNLA': total.meter.nla,\n    'meterNLB': total.meter.nlb,\n    'meterOTA': total.meter.ota,\n    'meterOTB': total.meter.otb,\n    'm_0': meter[0],\n    'm_1': meter[1],\n    'm_2': meter[2],\n    'm_3': meter[3],\n    'm_4': meter[4],\n    'm_5': meter[5],\n    'm_6': meter[6],\n    'm_7': meter[7],\n    'm_8': meter[8],\n    'm_9': meter[9],\n    'm_10': meter[10],\n    'm_11': meter[11],\n    'm_12': meter[12],\n    'm_13': meter[13],\n    'm_14': meter[14],\n    'm_15': meter[15],\n    'm_16': meter[16],\n    'm_17': meter[17],\n    'm_18': meter[18],\n    'm_19': meter[19],\n    'm_20': meter[20],\n    'm_21': meter[21],\n    'm_22': meter[22],\n    'm_23': meter[23],\n    'total_working': total.working.total,\n    'total_workingA': total.working.totala,\n    'total_workingB': total.working.totalb,\n    'workingNLA': total.working.nla,\n    'workingNLB': total.working.nlb,\n    'workingOTA': total.working.ota,\n    'workingOTB': total.working.otb,\n    'w_0': working[0],\n    'w_1': working[1],\n    'w_2': working[2],\n    'w_3': working[3],\n    'w_4': working[4],\n    'w_5': working[5],\n    'w_6': working[6],\n    'w_7': working[7],\n    'w_8': working[8],\n    'w_9': working[9],\n    'w_10': working[10],\n    'w_11': working[11],\n    'w_12': working[12],\n    'w_13': working[13],\n    'w_14': working[14],\n    'w_15': working[15],\n    'w_16': working[16],\n    'w_17': working[17],\n    'w_18': working[18],\n    'w_19': working[19],\n    'w_20': working[20],\n    'w_21': working[21],\n    'w_22': working[22],\n    'w_23': working[23],\n    'main_now': main.now || 0,\n    'main_min': main.min || 0,\n    'main_max': main.max || 0,\n    'take_now': take.now || 0,\n    'take_min': take.min || 0,\n    'take_max': take.max || 0,\n    'upTimetotal': upt.total,\n    'upTimetotalA': upt.totalA,\n    'upTimetotalB': upt.totalB,\n    'upTimenla': upt.nla,\n    'upTimeota': upt.ota,\n    'upTimenlb': upt.nlb,\n    'upTimeotb': upt.otb,\n}\nreturn msg;",
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
                "562f9af20391c406"
            ]
        ]
    },
    {
        "id": "b536e3111c63eed1",
        "type": "function",
        "z": "f1016d6dfc436da7",
        "name": "data Log",
        "func": "const payload = msg.payload;\nconst date = payload.date;\nconst time = payload.time;\nconst timestamp = payload.timestamp;\nconst ip = payload.ip;\nconst date_data = payload.date_data;\nconst upt = payload.upt;\n\n// values \nconst main = payload.values.maintake.main;\nconst take = payload.values.maintake.take;\nconst meter = payload.values.meter;\nconst working = payload.values.working;\nconst total = payload.values.total;\n\nmsg.payload = {\n    'date': date,\n    'time': time,\n    'timestamp': timestamp,\n    'ip': ip,\n    'date_data': date_data,\n    'total_meter': total.meter.total,\n    'total_meterA': total.meter.totala,\n    'total_meterB': total.meter.totalb,\n    'meterNLA': total.meter.nla,\n    'meterNLB': total.meter.nlb,\n    'meterOTA': total.meter.ota,\n    'meterOTB': total.meter.otb,\n    'm_0': meter[0],\n    'm_1': meter[1],\n    'm_2': meter[2],\n    'm_3': meter[3],\n    'm_4': meter[4],\n    'm_5': meter[5],\n    'm_6': meter[6],\n    'm_7': meter[7],\n    'm_8': meter[8],\n    'm_9': meter[9],\n    'm_10': meter[10],\n    'm_11': meter[11],\n    'm_12': meter[12],\n    'm_13': meter[13],\n    'm_14': meter[14],\n    'm_15': meter[15],\n    'm_16': meter[16],\n    'm_17': meter[17],\n    'm_18': meter[18],\n    'm_19': meter[19],\n    'm_20': meter[20],\n    'm_21': meter[21],\n    'm_22': meter[22],\n    'm_23': meter[23],\n    'total_working': total.working.total,\n    'total_workingA': total.working.totala,\n    'total_workingB': total.working.totalb,\n    'workingNLA': total.working.nla,\n    'workingNLB': total.working.nlb,\n    'workingOTA': total.working.ota,\n    'workingOTB': total.working.otb,\n    'w_0': working[0],\n    'w_1': working[1],\n    'w_2': working[2],\n    'w_3': working[3],\n    'w_4': working[4],\n    'w_5': working[5],\n    'w_6': working[6],\n    'w_7': working[7],\n    'w_8': working[8],\n    'w_9': working[9],\n    'w_10': working[10],\n    'w_11': working[11],\n    'w_12': working[12],\n    'w_13': working[13],\n    'w_14': working[14],\n    'w_15': working[15],\n    'w_16': working[16],\n    'w_17': working[17],\n    'w_18': working[18],\n    'w_19': working[19],\n    'w_20': working[20],\n    'w_21': working[21],\n    'w_22': working[22],\n    'w_23': working[23],\n    'main_now': main.now || 0,\n    'main_min': main.min || 0,\n    'main_max': main.max || 0,\n    'take_now': take.now || 0,\n    'take_min': take.min || 0,\n    'take_max': take.max || 0,\n    'upTimetotal': upt.total,\n    'upTimetotalA': upt.totalA,\n    'upTimetotalB': upt.totalB,\n    'upTimenla': upt.nla,\n    'upTimeota': upt.ota,\n    'upTimenlb': upt.nlb,\n    'upTimeotb': upt.otb,\n}\nreturn msg;",
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
                "580c9972ff966756"
            ]
        ]
    },
    {
        "id": "562f9af20391c406",
        "type": "csv",
        "z": "f1016d6dfc436da7",
        "name": "",
        "sep": ",",
        "hdrin": "",
        "hdrout": "all",
        "multi": "one",
        "ret": "\\r\\n",
        "temp": "date,time,timestamp,ip,date_data,total_meter,meterNLA,meterOTA,total_meterA,meterNLB,meterOTB,total_meterB,m_0,m_1,m_2,m_3,m_4,m_5,m_6,m_7,m_8,m_9,m_10,m_11,m_12,m_13,m_14,m_15,m_16,m_17,m_18,m_19,m_20,m_21,m_22,m_23,total_working,workingNLA,workingOTA,total_workingA,workingNLB,workingOTB,total_workingB,w_0,w_1,w_2,w_3,w_4,w_5,w_6,w_7,w_8,w_9,w_10,w_11,w_12,w_13,w_14,w_15,w_16,w_17,w_18,w_19,w_20,w_21,w_22,w_23,main_now,main_min,main_max,take_now,take_min,take_max,upTimetotal,upTimetotalA,upTimetotalB,upTimenla,upTimeota,upTimenlb,upTimeotb",
        "skip": "0",
        "strings": true,
        "include_empty_strings": "",
        "include_null_values": "",
        "x": 315,
        "y": 40,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "580c9972ff966756",
        "type": "csv",
        "z": "f1016d6dfc436da7",
        "name": "",
        "sep": ",",
        "hdrin": "",
        "hdrout": "none",
        "multi": "one",
        "ret": "\\r\\n",
        "temp": "date,time,timestamp,ip,date_data,total_meter,meterNLA,meterOTA,total_meterA,meterNLB,meterOTB,total_meterB,m_0,m_1,m_2,m_3,m_4,m_5,m_6,m_7,m_8,m_9,m_10,m_11,m_12,m_13,m_14,m_15,m_16,m_17,m_18,m_19,m_20,m_21,m_22,m_23,total_working,workingNLA,workingOTA,total_workingA,workingNLB,workingOTB,total_workingB,w_0,w_1,w_2,w_3,w_4,w_5,w_6,w_7,w_8,w_9,w_10,w_11,w_12,w_13,w_14,w_15,w_16,w_17,w_18,w_19,w_20,w_21,w_22,w_23,main_now,main_min,main_max,take_now,take_min,take_max,upTimetotal,upTimetotalA,upTimetotalB,upTimenla,upTimeota,upTimenlb,upTimeotb",
        "skip": "0",
        "strings": true,
        "include_empty_strings": "",
        "include_null_values": "",
        "x": 315,
        "y": 80,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "5bd37418f0f1f7c3",
        "type": "function",
        "z": "78457dab5d6c0503",
        "name": "meter",
        "func": "var date = new Date(msg.payload);\nlet previousDate = new Date(date); \n    previousDate.setDate(previousDate.getDate() - 1).toString().padStart(2, 0);\nvar year = date.getFullYear(); \nvar month = (date.getMonth() + 1).toString().padStart(2, '0');\nvar day = date.getDate().toString().padStart(2, '0');\nvar hour = date.getHours().toString().padStart(2, '0');\nlet fs_c = flow.get(\"fs\");\nlet fs = (Number(global.get(\"config.datetime.minute\"))) <= 30 ? \"f\" : \"s\";\nmsg.path = `/home/orangepi/deviceLog/${year}/${month}-${day}/${hour}/${fs}.csv`;\nlet path = `/home/orangepi/deviceLog/${year}/`;\nflow.set(\"path\", path);\nif(fs != fs_c){\n    flow.set(\"fs\", fs);\n    msg.reset = \" \";\n}\nmsg.payload = {\n    'ts': flow.get(\"ts\"),\n    'date': global.get(\"config.datetime.date\"),\n    'time': global.get(\"config.datetime.time\"),\n    'ip': global.get(\"config.state.ip\"),\n    'index': global.get(\"config.state.index\"),\n    'datestamp': global.get(\"config.state.datestamp\"),\n    'datenow': global.get(\"config.state.datenow\"),\n    'main': global.get(\"values.maintake.main.now\"),\n    'm_min': global.get(\"values.maintake.main.min\"),\n    'm_max': global.get(\"values.maintake.main.max\"),\n    'take': global.get(\"values.maintake.take.now\"),\n    't_min': global.get(\"values.maintake.take.min\"),\n    't_max': global.get(\"values.maintake.take.max\"),\n    'take_cal': Number(parseFloat(((global.get(\"values.maintake.main.now\") * 8) / 39.37) / 7.7).toFixed(2)) || 0,\n    'count': global.get(\"hex32\"),\n    'total_m': global.get(\"values.total.meter.total\"),\n};\nnode.status({ fill: \"blue\", shape: \"dot\", text:\"count: \" + global.get(\"hex32\")});\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 190,
        "y": 140,
        "wires": [
            [
                "656d5fdf90f37195",
                "11d7e025f0296cd9"
            ]
        ]
    },
    {
        "id": "656d5fdf90f37195",
        "type": "function",
        "z": "78457dab5d6c0503",
        "name": "function 3",
        "func": "msg.payload = {\n    'fill': 'blue',\n    'shape': 'dot',\n    'text': `[C]: ${global.get(\"hex32\")}`\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 285,
        "y": 180,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "11d7e025f0296cd9",
        "type": "csv",
        "z": "78457dab5d6c0503",
        "name": "",
        "sep": ",",
        "hdrin": false,
        "hdrout": "once",
        "multi": "one",
        "ret": "\\r\\n",
        "temp": "",
        "skip": "0",
        "strings": true,
        "include_empty_strings": "",
        "include_null_values": "",
        "x": 340,
        "y": 140,
        "wires": [
            [
                "5971486c721e0300"
            ]
        ]
    },
    {
        "id": "5971486c721e0300",
        "type": "file",
        "z": "78457dab5d6c0503",
        "name": "",
        "filename": "path",
        "filenameType": "msg",
        "appendNewline": false,
        "createDir": true,
        "overwriteFile": "false",
        "encoding": "utf8",
        "x": 500,
        "y": 140,
        "wires": [
            []
        ]
    },
    {
        "id": "d1c1aa82c8b72a93",
        "type": "function",
        "z": "78457dab5d6c0503",
        "name": "function 4",
        "func": "let path = flow.get(\"path\");\nmsg.payload = { 'start': path}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 200,
        "y": 300,
        "wires": [
            [
                "d9db9591a4d3b731"
            ]
        ]
    },
    {
        "id": "d9db9591a4d3b731",
        "type": "fs-file-lister",
        "z": "78457dab5d6c0503",
        "name": "",
        "start": "/",
        "pattern": "*.*",
        "folders": "*",
        "hidden": true,
        "lstype": "directories",
        "path": true,
        "single": true,
        "depth": "0",
        "stat": true,
        "showWarnings": false,
        "x": 360,
        "y": 300,
        "wires": [
            [
                "c1dfe81f680e6f01"
            ]
        ]
    },
    {
        "id": "18936721347779ca",
        "type": "function",
        "z": "78457dab5d6c0503",
        "name": "function 7",
        "func": "flow.set(\"speed_main_motor\", msg.main);\nflow.set(\"speed_take_up\", msg.take);\nflow.set(\"take_cal\", msg.take_cal);\nflow.set(\"ts\", msg.payload);",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 200,
        "y": 80,
        "wires": [
            []
        ]
    },
    {
        "id": "c1dfe81f680e6f01",
        "type": "function",
        "z": "78457dab5d6c0503",
        "name": "function 5",
        "func": "let length = msg.payload.length;\nlet delete_file = msg.payload[0].name;\n    if(length > 30){\n        msg.payload = `rm -rf ${delete_file}`\n        return msg;\n    }",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 520,
        "y": 300,
        "wires": [
            [
                "d376633b3de3778a"
            ]
        ]
    },
    {
        "id": "d376633b3de3778a",
        "type": "exec",
        "z": "78457dab5d6c0503",
        "command": "",
        "addpay": "payload",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "",
        "x": 730,
        "y": 300,
        "wires": [
            [],
            [],
            []
        ]
    },
    {
        "id": "22b7ddd5b8f324e8",
        "type": "inject",
        "z": "78457dab5d6c0503",
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
        "repeat": "60",
        "crontab": "",
        "once": false,
        "onceDelay": 0.1,
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 85,
        "y": 300,
        "wires": [
            [
                "d1c1aa82c8b72a93"
            ]
        ],
        "l": false
    },
    {
        "id": "ae3d5428e72f795e",
        "type": "ui-form",
        "z": "9f979da7e8a5400d",
        "name": "Date Set",
        "group": "c8b6450989c369f5",
        "label": "Date Set",
        "order": 1,
        "width": "2",
        "height": "6",
        "options": [
            {
                "label": "Date",
                "key": "date",
                "type": "date",
                "required": true,
                "rows": null
            },
            {
                "label": "Time",
                "key": "time",
                "type": "time",
                "required": true,
                "rows": null
            },
            {
                "label": "range",
                "key": "range",
                "type": "dropdown",
                "required": true,
                "rows": null
            }
        ],
        "formValue": {
            "date": "",
            "time": "",
            "range": ""
        },
        "payload": "",
        "submit": "submit",
        "cancel": "",
        "resetOnSubmit": false,
        "topic": "topic",
        "topicType": "msg",
        "splitLayout": false,
        "className": "",
        "passthru": false,
        "dropdownOptions": [
            {
                "dropdown": "range",
                "value": "f",
                "label": "< 00:30"
            },
            {
                "dropdown": "range",
                "value": "s",
                "label": "> 00:30"
            }
        ],
        "x": 200,
        "y": 80,
        "wires": [
            [
                "7bdd2a0ff8b3a124"
            ]
        ]
    },
    {
        "id": "8a5b72bf773262df",
        "type": "ui-table",
        "z": "9f979da7e8a5400d",
        "group": "6da9956de8144acb",
        "name": "Log",
        "label": "Log",
        "order": 1,
        "width": 0,
        "height": 0,
        "maxrows": 0,
        "passthru": false,
        "autocols": true,
        "showSearch": true,
        "deselect": true,
        "selectionType": "none",
        "columns": [],
        "mobileBreakpoint": "sm",
        "mobileBreakpointType": "defaults",
        "action": "replace",
        "x": 850,
        "y": 80,
        "wires": [
            []
        ]
    },
    {
        "id": "7bdd2a0ff8b3a124",
        "type": "function",
        "z": "9f979da7e8a5400d",
        "name": "function 16",
        "func": "const date = msg.payload.date;\nconst time = msg.payload.time;\nlet arr = date.split(\"-\");\nconst year = arr[0];\nconst month = arr[1];\nconst day = arr[2];\nconst hour = time.substring(0,2);\nconst range = msg.payload.range\nmsg.path = `/home/orangepi/deviceLog/${year}/${month}-${day}/${hour}/${range}.csv`\nmsg.payload = {\n    'year': year,\n    'month': month,\n    'day': day,\n    'hour': hour,\n    'range': range\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 370,
        "y": 80,
        "wires": [
            [
                "fb91dffcd2ba9264"
            ]
        ]
    },
    {
        "id": "fb91dffcd2ba9264",
        "type": "file in",
        "z": "9f979da7e8a5400d",
        "name": "",
        "filename": "path",
        "filenameType": "msg",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "none",
        "allProps": false,
        "x": 540,
        "y": 80,
        "wires": [
            [
                "d14440ddfc00f24d"
            ]
        ]
    },
    {
        "id": "d14440ddfc00f24d",
        "type": "csv",
        "z": "9f979da7e8a5400d",
        "name": "",
        "sep": ",",
        "hdrin": "",
        "hdrout": "none",
        "multi": "mult",
        "ret": "\\r\\n",
        "temp": "",
        "skip": "0",
        "strings": true,
        "include_empty_strings": "",
        "include_null_values": "",
        "x": 690,
        "y": 80,
        "wires": [
            [
                "8a5b72bf773262df"
            ]
        ]
    },
    {
        "id": "4dda3b250a7dd136",
        "type": "ui-event",
        "z": "9f979da7e8a5400d",
        "ui": "d6f3a7fd07525d85",
        "name": "",
        "x": 630,
        "y": 120,
        "wires": [
            [
                "7e5c7f382706458d"
            ]
        ]
    },
    {
        "id": "7e5c7f382706458d",
        "type": "function",
        "z": "9f979da7e8a5400d",
        "name": "function 17",
        "func": "msg.payload = [];\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 725,
        "y": 120,
        "wires": [
            [
                "8a5b72bf773262df",
                "2f132ec082f8504a"
            ]
        ],
        "l": false
    },
    {
        "id": "0bfe4e44d508948c",
        "type": "exec",
        "z": "9f979da7e8a5400d",
        "command": "",
        "addpay": "payload",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "",
        "x": 830,
        "y": 300,
        "wires": [
            [
                "b4c63890a364599b"
            ],
            [],
            []
        ]
    },
    {
        "id": "a5a92509c611eeaa",
        "type": "ui-text-input",
        "z": "9f979da7e8a5400d",
        "group": "72adefdf7b5e4ced",
        "name": "",
        "label": "Version Update",
        "order": 2,
        "width": "2",
        "height": 0,
        "topic": "topic",
        "topicType": "msg",
        "mode": "text",
        "tooltip": "",
        "delay": 300,
        "passthru": true,
        "sendOnDelay": false,
        "sendOnBlur": false,
        "sendOnEnter": true,
        "className": "",
        "clearable": false,
        "sendOnClear": true,
        "icon": "",
        "iconPosition": "left",
        "iconInnerPosition": "inside",
        "x": 280,
        "y": 180,
        "wires": [
            [
                "b6730286a98ef205"
            ]
        ]
    },
    {
        "id": "20096dec95d8ca8b",
        "type": "ui-button",
        "z": "9f979da7e8a5400d",
        "group": "72adefdf7b5e4ced",
        "name": "",
        "label": "Update",
        "order": 3,
        "width": "6",
        "height": 0,
        "emulateClick": false,
        "tooltip": "",
        "color": "",
        "bgcolor": "",
        "className": "",
        "icon": "",
        "iconPosition": "left",
        "payload": "",
        "payloadType": "str",
        "topic": "payload",
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
        "x": 480,
        "y": 300,
        "wires": [
            [
                "d83203e8df4e2258"
            ]
        ]
    },
    {
        "id": "b6730286a98ef205",
        "type": "function",
        "z": "9f979da7e8a5400d",
        "name": "function 18",
        "func": "const version = msg.payload\n    flow.set(\"vs\", version);\nmsg.ui_update = {\n    'label': `Update To Version : ${version}`\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 310,
        "y": 300,
        "wires": [
            [
                "20096dec95d8ca8b"
            ]
        ]
    },
    {
        "id": "d83203e8df4e2258",
        "type": "function",
        "z": "9f979da7e8a5400d",
        "name": "function 19",
        "func": "const version = flow.get(\"vs\")\nmsg.payload = `curl -s https://raw.githubusercontent.com/tonmai0705/innit-OrangePi-Loom-Update/refs/heads/main/updaet-opi-loom-source-9-v${version}.sh | bash`\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 650,
        "y": 300,
        "wires": [
            [
                "0bfe4e44d508948c"
            ]
        ]
    },
    {
        "id": "b4c63890a364599b",
        "type": "function",
        "z": "9f979da7e8a5400d",
        "name": "function 20",
        "func": "if(msg.payload){\n    global.set(\"version\", flow.get(\"vs\"));\n    msg.ui_update = {\n    'label': `Software Version :`\n    }\n    msg.payload = `Software Version: ${global.get(\"version\")}`\n    return msg;\n}else{\n    msg.ui_update = {\n    'label': `Software Version :`\n    }\n    msg.payload = `Version Not Found`\n    return msg;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 1010,
        "y": 280,
        "wires": [
            [
                "e7bae9c9943d4e7f",
                "c540559361daad49"
            ]
        ]
    },
    {
        "id": "e7bae9c9943d4e7f",
        "type": "ui-text",
        "z": "9f979da7e8a5400d",
        "group": "72adefdf7b5e4ced",
        "order": 1,
        "width": "3",
        "height": 0,
        "name": "",
        "label": "",
        "format": "{{msg.payload}}",
        "layout": "row-center",
        "style": false,
        "font": "",
        "fontSize": 16,
        "color": "#717171",
        "wrapText": false,
        "className": "",
        "x": 1170,
        "y": 220,
        "wires": []
    },
    {
        "id": "2f132ec082f8504a",
        "type": "function",
        "z": "9f979da7e8a5400d",
        "name": "function 21",
        "func": "msg.ui_update = {\n    'label': `Software Version :`\n}\nmsg.payload = `${global.get(\"version\")}`\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 1010,
        "y": 220,
        "wires": [
            [
                "e7bae9c9943d4e7f"
            ]
        ]
    },
    {
        "id": "2f95bf4b23247bd3",
        "type": "file",
        "z": "9f979da7e8a5400d",
        "name": "config",
        "filename": "/home/orangepi/loom/config.txt.tmp",
        "filenameType": "str",
        "appendNewline": false,
        "createDir": true,
        "overwriteFile": "true",
        "encoding": "utf8",
        "x": 1310,
        "y": 320,
        "wires": [
            [
                "eefc3029131a18d7"
            ]
        ],
        "icon": "node-red/redis.svg"
    },
    {
        "id": "c540559361daad49",
        "type": "function",
        "z": "9f979da7e8a5400d",
        "name": "fig value",
        "func": "msg.payload = {\n    \"state\": {\n        \"datestamp\": global.get(\"config.state.datestamp\"),\n        \"hourstamp\": global.get(\"config.state.hourstamp\"),\n        \"changehour\": global.get(\"config.state.changehour\"),\n        \"index\": global.get(\"config.state.index\"),\n        \"ip\": global.get(\"config.state.ip\"),\n        \"version\": global.get(\"version\") || \"-\"\n    },\n    \"values\": {\n        \"maintake\": {\n            \"main\": {\n                \"min\": global.get(\"values.maintake.main.min\"),\n                \"max\": global.get(\"values.maintake.main.max\")\n            },\n            \"take\": {\n                \"min\": global.get(\"values.maintake.take.min\"),\n                \"max\": global.get(\"values.maintake.take.max\")\n            }\n        },\n        \"meter\": global.get(\"values.meter\"),\n        \"working\": global.get(\"values.working\")\n    }\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 1160,
        "y": 320,
        "wires": [
            [
                "2f95bf4b23247bd3"
            ]
        ]
    },
    {
        "id": "eefc3029131a18d7",
        "type": "exec",
        "z": "9f979da7e8a5400d",
        "command": "mv /home/orangepi/loom/config.txt.tmp /home/orangepi/loom/config.txt",
        "addpay": "",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "move .tmp",
        "x": 1450,
        "y": 340,
        "wires": [
            [
                "1d920d649052d9ea"
            ],
            [],
            []
        ]
    },
    {
        "id": "1d920d649052d9ea",
        "type": "function",
        "z": "9f979da7e8a5400d",
        "name": "function 22",
        "func": "msg.payload = {\n    'fill': 'blue',\n    'shape': 'dot',\n    'text': msg.filename \n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 1630,
        "y": 340,
        "wires": [
            []
        ]
    },
    {
        "id": "fbda616582fab4cb",
        "type": "http request",
        "z": "1406c468fdce7358",
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
        "x": 350,
        "y": 80,
        "wires": [
            []
        ]
    },
    {
        "id": "62597ed5138d084d",
        "type": "function",
        "z": "1406c468fdce7358",
        "name": "function 10",
        "func": "let botToken = \"8181762860:AAEDyLgCoHmRrZ4nrSxUPYfe2Xsov_mvH3g\";\nlet chatId = \"-4940675177\";\nlet message = msg.payload;\n\nmsg.url = `https://api.telegram.org/bot${botToken}/sendMessage`;\nmsg.method = \"POST\";\nmsg.payload = {\n    chat_id: chatId,\n    text: message\n};\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 180,
        "y": 80,
        "wires": [
            [
                "fbda616582fab4cb"
            ]
        ]
    },
    {
        "id": "4d414fcfa4d1f563",
        "type": "inject",
        "z": "c9bf91fd5c385f43",
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
        "onceDelay": "6",
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 145,
        "y": 80,
        "wires": [
            [
                "d6a67c89385322a2"
            ]
        ],
        "l": false
    },
    {
        "id": "d6a67c89385322a2",
        "type": "function",
        "z": "c9bf91fd5c385f43",
        "name": "UPTIME",
        "func": "let upTimenla = global.get(\"config.state.upt.nla\") || 0;\nlet upTimeota = global.get(\"config.state.upt.ota\") || 0;\nlet upTimetotalA = global.get(\"config.state.upt.totalA\") || 0;\nlet upTimenlb = global.get(\"config.state.upt.nlb\") || 0;\nlet upTimeotb = global.get(\"config.state.upt.otb\") || 0;\nlet upTimetotalB = global.get(\"config.state.upt.totalB\") || 0;\n\nlet upTimetotal = global.get(\"config.state.upt.total\") || 0;\nconst sec = 1;\nvar secNow;\nlet hour = global.get(\"config.datetime.hour\");\n    hour = Number(hour);\n    if(hour >= 8 && hour <= 17){\n        global.set(\"config.state.upt.nla\", upTimenla + sec);\n        secNow = upTimenla;\n    }else if(hour >= 18 && hour <= 19){\n        global.set(\"config.state.upt.ota\", upTimeota + sec);\n        secNow = upTimeota;\n    }else if(hour >= 20 && hour <= 5){\n        global.set(\"config.state.upt.nlb\", upTimenlb + sec); \n        secNow = upTimenlb;\n    }else if(hour >= 6 && hour <= 7){\n        global.set(\"config.state.upt.otb\", upTimeotb + sec);\n        secNow = upTimeotb;\n    }\n    upTimetotalA = upTimenla + upTimeota;\n        global.set(\"config.state.upt.totalA\", upTimetotalA);\n    upTimetotalB = upTimenlb + upTimeotb;\n        global.set(\"config.state.upt.totalB\", upTimetotalB);\n    upTimetotal = upTimetotalA + upTimetotalB;\n        global.set(\"config.state.upt.total\", upTimetotal);\nmsg.payload = {\n    'fill': 'yellow',\n    'shape': 'dot',\n    'text': `Second: ${secNow} | nla: ${setTime(upTimenla)} | ota: ${setTime(upTimeota)} | nlb: ${setTime(upTimenlb)} | otb: ${setTime(upTimeotb)} | total: ${setTime(upTimetotal)}`\n};\nreturn msg;\n\nfunction setTime(second){\n    let hours = Math.floor(second / 3600)\n    let minutes = Math.floor((second % 3600) / 60)\n    let seconds = Math.floor((second % 60) / 1)\n    let format = hours + ':' + minutes + ':' + seconds\n    return format;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 260,
        "y": 80,
        "wires": [
            []
        ]
    },
    {
        "id": "b876448f3a68636e",
        "type": "inject",
        "z": "062d9ee6cb5e367f",
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
        "onceDelay": "40",
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 145,
        "y": 100,
        "wires": [
            [
                "d254c4f3ec67d313",
                "fa505a146959395d",
                "2a334b79d30a7edf"
            ]
        ],
        "l": false
    },
    {
        "id": "d254c4f3ec67d313",
        "type": "function",
        "z": "062d9ee6cb5e367f",
        "name": "take up check",
        "func": "const main = global.get(\"values.maintake.main.now\");\nlet alarmMain = flow.get(\"alarmMain\") || false;\nconst hour = global.get(\"config.datetime.hour\");\nconst otw = context.get(\"otw\") || \"-\" // otw: one time working\nalarmMain = hour == otw ? true : false;\nif(main > 0 && !alarmMain){\n    context.set(\"otw\", hour);\n    return msg; \n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 260,
        "y": 80,
        "wires": [
            [
                "cafeef43fd6b7fd0"
            ]
        ]
    },
    {
        "id": "938ff7e5f30f5df6",
        "type": "function",
        "z": "062d9ee6cb5e367f",
        "name": "function 23",
        "func": "const takeUp = global.get(\"values.maintake.take.now\");\nconst main = global.get(\"values.maintake.main.now\");\nif (main > 0 && takeUp == 0) {\n    msg.payload = `${global.get(\"config.state.ip\")} 🔩 > [takeUp: ${takeUp} main: ${main}] เซ็นเซอร์ Take up อาจมีปัญหา...`;\n    return msg;\n}",
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
                "3a4ac4dbcb8962f9"
            ]
        ]
    },
    {
        "id": "cafeef43fd6b7fd0",
        "type": "delay",
        "z": "062d9ee6cb5e367f",
        "name": "",
        "pauseType": "delay",
        "timeout": "10",
        "timeoutUnits": "seconds",
        "rate": "1",
        "nbRateUnits": "10",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 375,
        "y": 80,
        "wires": [
            [
                "938ff7e5f30f5df6"
            ]
        ],
        "l": false
    },
    {
        "id": "fa505a146959395d",
        "type": "function",
        "z": "062d9ee6cb5e367f",
        "name": "main check",
        "func": "const takeUp = global.get(\"values.maintake.take.now\");\nlet alarmTake = flow.get(\"alarmTake\") || false;\nconst hour = global.get(\"config.datetime.hour\");\nconst otw = context.get(\"otw\") || \"-\" // otw: one time working\nalarmTake = hour == otw ? true : false;\nif(takeUp > 0 && !alarmTake){\n    context.set(\"otw\", hour);\n    return msg; \n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 250,
        "y": 120,
        "wires": [
            [
                "2cf3a1fca4c05388"
            ]
        ]
    },
    {
        "id": "c69c76cd5d3d874f",
        "type": "subflow:1406c468fdce7358",
        "z": "062d9ee6cb5e367f",
        "name": "",
        "x": 680,
        "y": 120,
        "wires": [
            [
                "1eec8d095382c328"
            ]
        ]
    },
    {
        "id": "1eec8d095382c328",
        "type": "function",
        "z": "062d9ee6cb5e367f",
        "name": "function 25",
        "func": "const httpCode = msg.statusCode;\n\nif(httpCode == 200){\n    flow.set(\"alarmTake\", true);    \n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 805,
        "y": 120,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "3a4ac4dbcb8962f9",
        "type": "subflow:1406c468fdce7358",
        "z": "062d9ee6cb5e367f",
        "name": "",
        "x": 680,
        "y": 80,
        "wires": [
            [
                "029c5ec1b4cd0fb6"
            ]
        ]
    },
    {
        "id": "029c5ec1b4cd0fb6",
        "type": "function",
        "z": "062d9ee6cb5e367f",
        "name": "function 27",
        "func": "const httpCode = msg.statusCode;\n\nif(httpCode == 200){\n    flow.set(\"alarmMain\", true);    \n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 805,
        "y": 80,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "2a334b79d30a7edf",
        "type": "function",
        "z": "062d9ee6cb5e367f",
        "name": "Status",
        "func": "msg.payload ={\n    'fill': 'green',\n    'shape': 'dot',\n    'text': `${global.get(\"config.datetime.time\")}: Last Time Check`\n}\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 230,
        "y": 160,
        "wires": [
            []
        ]
    },
    {
        "id": "2cf3a1fca4c05388",
        "type": "delay",
        "z": "062d9ee6cb5e367f",
        "name": "",
        "pauseType": "delay",
        "timeout": "10",
        "timeoutUnits": "seconds",
        "rate": "1",
        "nbRateUnits": "10",
        "rateUnits": "second",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": false,
        "allowrate": false,
        "outputs": 1,
        "x": 375,
        "y": 120,
        "wires": [
            [
                "20ce10615defa2e5"
            ]
        ],
        "l": false
    },
    {
        "id": "20ce10615defa2e5",
        "type": "function",
        "z": "062d9ee6cb5e367f",
        "name": "main check",
        "func": "const takeUp = global.get(\"values.maintake.take.now\");\nconst main = global.get(\"values.maintake.main.now\");\n\nif(takeUp > 0 && main == 0){\n    msg.payload = `${global.get(\"config.state.ip\")} 🔩 > [takeUp: ${takeUp} main: ${main}] เซ็นเซอร์ Main อาจมีปัญหา...`;\n    return msg; \n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 490,
        "y": 120,
        "wires": [
            [
                "c69c76cd5d3d874f"
            ]
        ]
    },
    {
        "id": "9827f5270df78aba",
        "type": "subflow:df4a94479416f0c4",
        "z": "777823ab3e1fee97",
        "g": "451150a92cfdb00f",
        "name": "",
        "x": 930,
        "y": 120,
        "wires": []
    },
    {
        "id": "8d2314a673078d68",
        "type": "inject",
        "z": "777823ab3e1fee97",
        "g": "451150a92cfdb00f",
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
        "once": true,
        "onceDelay": "5",
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 835,
        "y": 80,
        "wires": [
            [
                "bc26e53c6604a53c"
            ]
        ],
        "icon": "node-red/cog.svg",
        "l": false
    },
    {
        "id": "cb4e9770746b4c2d",
        "type": "subflow:a67f25631bef1988",
        "z": "777823ab3e1fee97",
        "g": "451150a92cfdb00f",
        "name": "",
        "x": 930,
        "y": 180,
        "wires": []
    },
    {
        "id": "641e370bc218b3e1",
        "type": "inject",
        "z": "777823ab3e1fee97",
        "g": "451150a92cfdb00f",
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
        "onceDelay": "31",
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 835,
        "y": 180,
        "wires": [
            [
                "cb4e9770746b4c2d"
            ]
        ],
        "icon": "font-awesome/fa-clock-o",
        "l": false
    },
    {
        "id": "54b953cb7c4b2af9",
        "type": "subflow:31057fe0b0d4c1ec",
        "z": "777823ab3e1fee97",
        "g": "451150a92cfdb00f",
        "name": "",
        "x": 1050,
        "y": 240,
        "wires": []
    },
    {
        "id": "e6290a07b12de109",
        "type": "subflow:13f006802899e0be",
        "z": "777823ab3e1fee97",
        "g": "451150a92cfdb00f",
        "name": "",
        "x": 930,
        "y": 240,
        "wires": [
            [
                "54b953cb7c4b2af9"
            ]
        ]
    },
    {
        "id": "b0abde57f8695277",
        "type": "inject",
        "z": "777823ab3e1fee97",
        "g": "451150a92cfdb00f",
        "name": "",
        "props": [
            {
                "p": "payload"
            }
        ],
        "repeat": "10",
        "crontab": "",
        "once": true,
        "onceDelay": "31",
        "topic": "",
        "payload": "192.168.0.9",
        "payloadType": "str",
        "x": 835,
        "y": 240,
        "wires": [
            [
                "e6290a07b12de109"
            ]
        ],
        "icon": "font-awesome/fa-globe",
        "l": false
    },
    {
        "id": "a241e24d2a8bd154",
        "type": "subflow:e226ede58ea4b202",
        "z": "777823ab3e1fee97",
        "g": "451150a92cfdb00f",
        "name": "",
        "x": 1080,
        "y": 120,
        "wires": []
    },
    {
        "id": "bc26e53c6604a53c",
        "type": "subflow:341bdc3e7e68ae46",
        "z": "777823ab3e1fee97",
        "g": "451150a92cfdb00f",
        "name": "",
        "x": 940,
        "y": 80,
        "wires": []
    },
    {
        "id": "65638a0971dafdf2",
        "type": "link in",
        "z": "777823ab3e1fee97",
        "g": "9036c777fe360381",
        "name": "link in 5",
        "links": [
            "f2925150b152ddfd"
        ],
        "x": 815,
        "y": 500,
        "wires": [
            [
                "e02e37f582fc0ef1"
            ]
        ],
        "icon": "node-red-contrib-modbus/modbus-icon.png"
    },
    {
        "id": "bca7972e18afe768",
        "type": "function",
        "z": "777823ab3e1fee97",
        "g": "9036c777fe360381",
        "name": "Values",
        "func": "msg.path = `/home/orangepi/loom/data/log.csv`;\nmsg.file = global.get(\"config.state.file\");\nconst meter = global.get(\"values.meter\");\nconst working = global.get(\"values.working\");\n\nconst positionNLA = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17];\nconst positionOTA = [18, 19];\nconst positionNLB = [20, 21, 22, 23, 0, 1, 2, 3, 4, 5];\nconst positionOTB = [6, 7];\n\n\nlet meterNLA = positionNLA.reduce((acc, pos) => acc + (meter[pos] || 0), 0);\nglobal.set(\"values.total.meter.nla\", meterNLA);\nlet meterOTA = positionOTA.reduce((acc, pos) => acc + (meter[pos] || 0), 0);\nglobal.set(\"values.total.meter.ota\", meterOTA);\nlet totalA = meterNLA + meterOTA;\nglobal.set(\"values.total.meter.totalA\", totalA);\n\nlet meterNLB = positionNLB.reduce((acc, pos) => acc + (meter[pos] || 0), 0);\nglobal.set(\"values.total.meter.nlb\", meterNLB);\nlet meterOTB = positionOTB.reduce((acc, pos) => acc + (meter[pos] || 0), 0);\nglobal.set(\"values.total.meter.otb\", meterOTB);\nlet totalB = meterNLB + meterOTB;\nglobal.set(\"values.total.meter.totalB\", totalB);\n\nlet total_meter = totalA + totalB || 0;\nglobal.set(\"values.total.meter.total\", total_meter);\n\nlet workingNLA = positionNLA.reduce((acc, pos) => acc + (working[pos] || 0), 0);\nglobal.set(\"values.total.working.nla\", workingNLA);\nlet workingOTA = positionOTA.reduce((acc, pos) => acc + (working[pos] || 0), 0);\nglobal.set(\"values.total.working.ota\", workingOTA);\nlet totalwA = workingNLA + workingOTA;\nglobal.set(\"values.total.working.totalA\", totalwA);\n\nlet workingNLB = positionNLB.reduce((acc, pos) => acc + (working[pos] || 0), 0);\nglobal.set(\"values.total.working.nlb\", workingNLB);\nlet workingOTB = positionOTA.reduce((acc, pos) => acc + (working[pos] || 0), 0);\nglobal.set(\"values.total.working.otb\", workingOTB);\nlet totalwB = workingNLB + workingOTB;\nglobal.set(\"values.total.working.totalB\", totalwB);\n\nlet total_working = totalwA + totalwB || 0;\nglobal.set(\"values.total.working.total\", total_working);\n\nmsg.payload = {\n    'date': global.get(\"config.datetime.date\") || 0,\n    'time': global.get(\"config.datetime.time\") || 0,\n    'timestamp': global.get(\"config.datetime.timestamp\") || 0,\n    'ip': global.get(\"config.state.ip\"),\n    'date_data': global.get(\"config.state.date_data\") || 0,\n    'upt': {\n        'total': global.get(\"config.state.upt.total\")|| 0,\n        'totalA': global.get(\"config.state.upt.totalA\")|| 0,\n        'totalB': global.get(\"config.state.upt.totalB\")|| 0,\n        'nla': global.get(\"config.state.upt.nla\")|| 0,\n        'ota': global.get(\"config.state.upt.ota\")|| 0,\n        'nlb': global.get(\"config.state.upt.nlb\")|| 0,\n        'otb': global.get(\"config.state.upt.otb\")|| 0,\n    },\n    \"values\":{\n        \"maintake\":{\n            \"main\": global.get(\"values.maintake.main\") ,\n            \"take\": global.get(\"values.maintake.take\") ,\n        },\n        \"meter\": meter  || 0,\n        \"working\": working || 0,\n        \"total\":{\n            \"meter\":{\n                \"nla\": global.get(\"values.total.meter.nla\") || 0,\n                \"nlb\": global.get(\"values.total.meter.nlb\") || 0,\n                \"ota\": global.get(\"values.total.meter.ota\") || 0,\n                \"otb\": global.get(\"values.total.meter.otb\") || 0,\n                \"totala\": global.get(\"values.total.meter.totalA\") || 0,\n                \"totalb\": global.get(\"values.total.meter.totalB\") || 0,\n                \"total\": global.get(\"values.total.meter.total\") || 0,\n            },\n            \"working\":{\n                \"nla\": global.get(\"values.total.working.nla\") || 0,\n                \"nlb\": global.get(\"values.total.working.nlb\") || 0,\n                \"ota\": global.get(\"values.total.working.ota\") || 0,\n                \"otb\": global.get(\"values.total.working.otb\") || 0,\n                \"totala\": global.get(\"values.total.working.totalA\") || 0,\n                \"totalb\": global.get(\"values.total.working.totalB\") || 0,\n                \"total\": global.get(\"values.total.working.total\") || 0,\n            }\n        }\n    }\n}\nnode.status({fill:\"blue\",shape:\"dot\",text: global.get(\"config.datetime.time\")});\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 895,
        "y": 540,
        "wires": [
            [
                "e814c362277b941f"
            ]
        ],
        "icon": "font-awesome/fa-archive",
        "l": false
    },
    {
        "id": "e814c362277b941f",
        "type": "subflow:f1016d6dfc436da7",
        "z": "777823ab3e1fee97",
        "g": "9036c777fe360381",
        "name": "",
        "x": 1010,
        "y": 540,
        "wires": [
            [
                "f5baaac8574c3c63"
            ],
            [
                "f5baaac8574c3c63"
            ]
        ]
    },
    {
        "id": "f5baaac8574c3c63",
        "type": "subflow:7a70a201eaa0a148",
        "z": "777823ab3e1fee97",
        "g": "9036c777fe360381",
        "name": "",
        "x": 1145,
        "y": 540,
        "wires": [],
        "l": false
    },
    {
        "id": "165854dba9786ef4",
        "type": "modbus-write",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "Write",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "unitid": "1",
        "dataType": "HoldingRegister",
        "adr": "181",
        "quantity": "1",
        "server": "291667434678740d",
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 340,
        "y": 100,
        "wires": [
            [
                "d53e6b2f26983416",
                "020abe7539ad09c4"
            ],
            []
        ]
    },
    {
        "id": "8cb095c264d1728b",
        "type": "function",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "Write PLC reset",
        "func": "var hours = Number(global.get(\"config.datetime.hour\"));\nvar changehour = Number(global.get(\"config.state.changehour\"));\n\nvar count = context.get(\"count\") || 0;\n\nif (changehour != undefined && changehour != null) {\n    if (hours != changehour) {\n        msg.payload = 1;\n        msg.modbus_read = false;\n        if (count > 3) {\n            global.set(\"config.state.changehour\", hours);\n        }\n        context.set(\"count\", count + 1);\n        node.status({ fill: \"green\", shape: \"dot\", text: \"Change hour \" + global.get(\"config.datetime.time\") });\n        return msg;\n    } else {\n        context.set(\"count\", 0);\n        msg.modbus_read = true;\n        return msg;\n    }\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 175,
        "y": 120,
        "wires": [
            [
                "1a7e9f67f1527628"
            ]
        ],
        "l": false
    },
    {
        "id": "d53e6b2f26983416",
        "type": "modbus-response",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "PLC Response",
        "registerShowMax": "1",
        "x": 425,
        "y": 100,
        "wires": [],
        "l": false
    },
    {
        "id": "020abe7539ad09c4",
        "type": "function",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "Write PLC reset",
        "func": "var hours = Number(global.get(\"config.datetime.hour\"))\nvar changehour = Number(global.get(\"config.state.changehour\"))\nvar datestamp = context.get(\"config.state.datestamp\") || 0\nvar datenow = global.get(\"config.state.datenow\")\n\nif (datenow != datestamp) {\n    msg.payload = 1\n    // global.set(\"changehour\", hours)\n    context.set(\"config.state.datestamp\", datenow)\n    node.status({ fill: \"green\", shape: \"dot\", text: \"Change hour \" + global.get(\"config.datetime.time\") });\n    return msg;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 425,
        "y": 140,
        "wires": [
            [
                "87858dfa873e16c3"
            ]
        ],
        "l": false
    },
    {
        "id": "0a51b58526c3eac5",
        "type": "inject",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "1 S",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            },
            {
                "p": "timestamp",
                "v": "",
                "vt": "date"
            }
        ],
        "repeat": "1",
        "crontab": "",
        "once": true,
        "onceDelay": "35",
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 105,
        "y": 120,
        "wires": [
            [
                "2b0bc6d5e24e124c",
                "8cb095c264d1728b"
            ]
        ],
        "icon": "node-red/trigger.svg",
        "l": false
    },
    {
        "id": "1a7e9f67f1527628",
        "type": "switch",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
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
        "x": 235,
        "y": 120,
        "wires": [
            [
                "165854dba9786ef4"
            ],
            [
                "0eb02406f8dff0ba"
            ]
        ],
        "l": false
    },
    {
        "id": "87858dfa873e16c3",
        "type": "modbus-write",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "Write",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "unitid": "1",
        "dataType": "HoldingRegister",
        "adr": "182",
        "quantity": "1",
        "server": "291667434678740d",
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 510,
        "y": 120,
        "wires": [
            [
                "8f9c36612b955b2f"
            ],
            []
        ]
    },
    {
        "id": "2b0bc6d5e24e124c",
        "type": "function",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "timestamp",
        "func": "flow.set(\"config.datetime.timestamp\", msg.timestamp);\nnode.status({ fill: \"blue\", shape: \"dot\", text: msg.timestamp });",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 175,
        "y": 80,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "0eb02406f8dff0ba",
        "type": "modbus-getter",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "Get PLC",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "unitid": "1",
        "dataType": "HoldingRegister",
        "adr": "102",
        "quantity": "1",
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 350,
        "y": 200,
        "wires": [
            [
                "ed51c14eaa7633a7",
                "51f8481c029f9f8d"
            ],
            []
        ]
    },
    {
        "id": "8f9c36612b955b2f",
        "type": "modbus-response",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "PLC Response",
        "registerShowMax": "1",
        "x": 595,
        "y": 140,
        "wires": [],
        "l": false
    },
    {
        "id": "ed51c14eaa7633a7",
        "type": "modbus-response",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "PLC Response",
        "registerShowMax": "1",
        "x": 445,
        "y": 180,
        "wires": [],
        "l": false
    },
    {
        "id": "51f8481c029f9f8d",
        "type": "function",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "Modbus[102]",
        "func": "var main_speed = msg.payload[0];\n    nowminmax(\"values.maintake\", \"main\", main_speed);\n    node.status({ fill: \"blue\", shape: \"dot\", text: global.get(\"config.datetime.time\") + \" : \" + main_speed });\nreturn msg;\n\nfunction nowminmax(type, group, input) {\n    global.set(`${type}.${group}.now`, input);\n    let input_min = global.get(`${type}.${group}.min`) || 0;\n    let input_max = global.get(`${type}.${group}.max`) || 0;\n\n    if (input > 0 && input < 6000) {\n        if (!input_min || input < input_min) {\n            input_min = input;\n            global.set(`${type}.${group}.min`, input_min);\n        }\n        if (!input_max || input > input_max) {\n            input_max = input;\n            global.set(`${type}.${group}.max`, input_max);\n        };\n    }else{\n            global.set(`${type}.${group}.now`, 0);\n    };\n};",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 500,
        "y": 220,
        "wires": [
            [
                "4a4b0af55f35b68b"
            ]
        ]
    },
    {
        "id": "4a4b0af55f35b68b",
        "type": "modbus-getter",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "Get PLC",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "unitid": "1",
        "dataType": "HoldingRegister",
        "adr": "208",
        "quantity": "1",
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 350,
        "y": 280,
        "wires": [
            [
                "6640ba01536a2946",
                "d1b4a59f01f7a3ac"
            ],
            []
        ]
    },
    {
        "id": "6640ba01536a2946",
        "type": "modbus-response",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "PLC Response",
        "registerShowMax": "1",
        "x": 445,
        "y": 260,
        "wires": [],
        "l": false
    },
    {
        "id": "d1b4a59f01f7a3ac",
        "type": "function",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "Modbus[208]",
        "func": "var cm_min = msg.payload[0]; \ncm_min = Number(cm_min / 100);\n    nowminmax(\"values.maintake\", \"take\", cm_min);\n    node.status({ fill: \"blue\", shape: \"dot\", text: global.get(\"config.datetime.time\") + \" : \" + cm_min });\nreturn msg;\n\nfunction nowminmax(type, group, input) {\n    global.set(`${type}.${group}.now`, input);\n    let input_min = global.get(`${type}.${group}.min`) || 0;\n    let input_max = global.get(`${type}.${group}.max`) || 0;\n\n    if (input > 0 && input < 6000) {\n        if (!input_min || input < input_min) {\n            input_min = input;\n            global.set(`${type}.${group}.min`, input_min);\n        }\n        if (!input_max || input > input_max) {\n            input_max = input;\n            global.set(`${type}.${group}.max`, input_max);\n        };\n    }else{\n            global.set(`${type}.${group}.now`, 0);\n    }\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 500,
        "y": 300,
        "wires": [
            [
                "2eb5bec75f01e20f"
            ]
        ]
    },
    {
        "id": "2eb5bec75f01e20f",
        "type": "modbus-getter",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "Get PLC",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "unitid": "1",
        "dataType": "HoldingRegister",
        "adr": "305",
        "quantity": "1",
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 350,
        "y": 360,
        "wires": [
            [
                "f6a699b11f2d2677",
                "d233508a056c55a0"
            ],
            []
        ]
    },
    {
        "id": "f6a699b11f2d2677",
        "type": "modbus-response",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "PLC Response",
        "registerShowMax": "7",
        "x": 445,
        "y": 340,
        "wires": [],
        "l": false
    },
    {
        "id": "d233508a056c55a0",
        "type": "function",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "Modbus [150-173]",
        "func": "var mt = msg.payload[0]\nvar meter = global.get(\"values.meter\");\nvar hour = global.get(\"config.datetime.hour\");\nmeter.splice(Number(hour), 1, mt) \nnode.status({ fill: \"blue\", shape: \"dot\", text: global.get(\"config.datetime.time\") + \" : meter_[\" + hour + \"] = \" + meter[Number(hour)] });\nreturn msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 520,
        "y": 380,
        "wires": [
            [
                "f4bb43f8de8fb162"
            ]
        ]
    },
    {
        "id": "f4bb43f8de8fb162",
        "type": "modbus-getter",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "Get PLC",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "unitid": "1",
        "dataType": "HoldingRegister",
        "adr": "600",
        "quantity": "1",
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 350,
        "y": 440,
        "wires": [
            [
                "3e759bafa1177ed1",
                "195dabaf8bf83f47",
                "a31df86427795839",
                "72694dc1ac5df943"
            ],
            []
        ]
    },
    {
        "id": "3e759bafa1177ed1",
        "type": "modbus-response",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "PLC Response",
        "registerShowMax": "1",
        "x": 445,
        "y": 420,
        "wires": [],
        "l": false
    },
    {
        "id": "195dabaf8bf83f47",
        "type": "function",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "Modbus [600]",
        "func": "var second = msg.payload[0] // working time (second)\nvar working_ = global.get(\"values.working\");\nvar hour = global.get(\"config.datetime.hour\")\nvar showtime\nworking_.splice(Number(hour), 1, second)\nvar hours = Math.floor(second / 3600)\nvar minutes = Math.floor((second % 3600) / 60)\nvar seconds = Math.floor((second % 60) / 1)\nshowtime = hours + ':' + minutes + ':' + seconds\nnode.status({ fill: \"blue\", shape: \"dot\", text: global.get(\"config.datetime.time\") +  \" : working: [\" + hour + \"] = \" + showtime });\nreturn msg",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 510,
        "y": 460,
        "wires": [
            [
                "2b24aa05aa5379ed"
            ]
        ]
    },
    {
        "id": "2b24aa05aa5379ed",
        "type": "delay",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "",
        "pauseType": "rate",
        "timeout": "5",
        "timeoutUnits": "seconds",
        "rate": "1",
        "nbRateUnits": "1",
        "rateUnits": "minute",
        "randomFirst": "1",
        "randomLast": "5",
        "randomUnits": "seconds",
        "drop": true,
        "allowrate": false,
        "outputs": 1,
        "x": 645,
        "y": 460,
        "wires": [
            [
                "f2925150b152ddfd"
            ]
        ],
        "l": false
    },
    {
        "id": "f2925150b152ddfd",
        "type": "link out",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "link out 6",
        "mode": "link",
        "links": [
            "65638a0971dafdf2"
        ],
        "x": 705,
        "y": 460,
        "wires": []
    },
    {
        "id": "a31df86427795839",
        "type": "function",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "function 8",
        "func": "global.set(\"config.datetime.timestamp\", flow.get(\"config.datetime.timestamp\"));\nnode.status({fill:\"bule\",shape:\"ring\",text: global.get(\"config.datetime.timestamp\")});\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 505,
        "y": 420,
        "wires": [
            []
        ],
        "icon": "node-red/timer.svg",
        "l": false
    },
    {
        "id": "72949a75b63686fd",
        "type": "subflow:78457dab5d6c0503",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "",
        "x": 175,
        "y": 180,
        "wires": [],
        "l": false
    },
    {
        "id": "792452b6dfad242c",
        "type": "inject",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
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
        "x": 105,
        "y": 180,
        "wires": [
            [
                "72949a75b63686fd"
            ]
        ],
        "l": false
    },
    {
        "id": "7d876bfc55befcf6",
        "type": "subflow:a6ecc454e1b3c0c3",
        "z": "777823ab3e1fee97",
        "g": "451150a92cfdb00f",
        "name": "",
        "x": 930,
        "y": 300,
        "wires": []
    },
    {
        "id": "72694dc1ac5df943",
        "type": "modbus-getter",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "Get PLC",
        "showStatusActivities": false,
        "showErrors": false,
        "showWarnings": true,
        "logIOActivities": false,
        "unitid": "1",
        "dataType": "HoldingRegister",
        "adr": "399",
        "quantity": "2",
        "server": "291667434678740d",
        "useIOFile": false,
        "ioFile": "",
        "useIOForPayload": false,
        "emptyMsgOnFail": false,
        "keepMsgProperties": false,
        "delayOnStart": false,
        "startDelayTime": "",
        "x": 352,
        "y": 518,
        "wires": [
            [
                "707e34c1a544e5d1",
                "b83a6608cf3531d8"
            ],
            []
        ]
    },
    {
        "id": "707e34c1a544e5d1",
        "type": "modbus-response",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "PLC Response",
        "registerShowMax": "2",
        "x": 445,
        "y": 500,
        "wires": [],
        "l": false
    },
    {
        "id": "b83a6608cf3531d8",
        "type": "function",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "meter",
        "func": "var input1 = parseInt(msg.payload[0], 10).toString(16);\nvar input2 = parseInt(msg.payload[1], 10).toString(16);\nlet length = input1.length;\n    if(length == 1){\n        input1 = \"000\" + input1;\n    } else if (length == 2){\n        input1 = \"00\" + input1;\n    } else if (length == 3) {\n        input1 = \"0\" + input1;\n    };\nvar hex32 = Number(parseInt((input2 + input1), 16).toString(10));\nglobal.set(\"hex32\", hex32);\nnode.status({ fill: \"blue\", shape: \"dot\", text: \"count: \" + hex32 });",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 490,
        "y": 540,
        "wires": [
            []
        ]
    },
    {
        "id": "fe159939e00a876e",
        "type": "subflow:9f979da7e8a5400d",
        "z": "777823ab3e1fee97",
        "g": "451150a92cfdb00f",
        "name": "",
        "x": 940,
        "y": 360,
        "wires": []
    },
    {
        "id": "c974acb909bd6616",
        "type": "inject",
        "z": "777823ab3e1fee97",
        "g": "451150a92cfdb00f",
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
        "x": 1055,
        "y": 360,
        "wires": [
            [
                "8f882b3c1846c4d2"
            ]
        ],
        "l": false
    },
    {
        "id": "8f882b3c1846c4d2",
        "type": "exec",
        "z": "777823ab3e1fee97",
        "g": "451150a92cfdb00f",
        "command": "reboot",
        "addpay": "",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "",
        "x": 1105,
        "y": 360,
        "wires": [
            [],
            [],
            []
        ],
        "l": false
    },
    {
        "id": "e02e37f582fc0ef1",
        "type": "subflow:b7d6774c49a75902",
        "z": "777823ab3e1fee97",
        "g": "9036c777fe360381",
        "name": "",
        "x": 930,
        "y": 500,
        "wires": [
            [
                "54d61fbff53a0240"
            ]
        ]
    },
    {
        "id": "7051805b6fc3e4c5",
        "type": "link out",
        "z": "777823ab3e1fee97",
        "g": "9036c777fe360381",
        "name": "link out 1",
        "mode": "link",
        "links": [
            "a68e65d6bd73a95c"
        ],
        "x": 1145,
        "y": 500,
        "wires": [],
        "icon": "font-awesome/fa-chain"
    },
    {
        "id": "a68e65d6bd73a95c",
        "type": "link in",
        "z": "777823ab3e1fee97",
        "g": "9036c777fe360381",
        "name": "link in 1",
        "links": [
            "7051805b6fc3e4c5"
        ],
        "x": 815,
        "y": 540,
        "wires": [
            [
                "bca7972e18afe768"
            ]
        ],
        "icon": "font-awesome/fa-chain"
    },
    {
        "id": "54d61fbff53a0240",
        "type": "delay",
        "z": "777823ab3e1fee97",
        "g": "9036c777fe360381",
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
        "x": 1085,
        "y": 500,
        "wires": [
            [
                "7051805b6fc3e4c5"
            ]
        ],
        "l": false
    },
    {
        "id": "b57537dcf374507c",
        "type": "inject",
        "z": "777823ab3e1fee97",
        "g": "451150a92cfdb00f",
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
        "once": true,
        "onceDelay": "5",
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 835,
        "y": 120,
        "wires": [
            [
                "9827f5270df78aba"
            ]
        ],
        "icon": "node-red/cog.svg",
        "l": false
    },
    {
        "id": "09e65fc5a9cf3984",
        "type": "subflow:aa3c99c011a59edd",
        "z": "777823ab3e1fee97",
        "g": "451150a92cfdb00f",
        "name": "",
        "x": 940,
        "y": 400,
        "wires": []
    },
    {
        "id": "b64538e02f4df6e9",
        "type": "inject",
        "z": "777823ab3e1fee97",
        "g": "451150a92cfdb00f",
        "name": "1 S",
        "props": [
            {
                "p": "payload"
            },
            {
                "p": "topic",
                "vt": "str"
            },
            {
                "p": "timestamp",
                "v": "",
                "vt": "date"
            }
        ],
        "repeat": "60",
        "crontab": "",
        "once": true,
        "onceDelay": "40",
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 835,
        "y": 400,
        "wires": [
            [
                "09e65fc5a9cf3984"
            ]
        ],
        "icon": "node-red/trigger.svg",
        "l": false
    },
    {
        "id": "ac29116d0411fcab",
        "type": "subflow:c9bf91fd5c385f43",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "",
        "x": 150,
        "y": 520,
        "wires": []
    },
    {
        "id": "fd6dded7e0aa82a2",
        "type": "subflow:062d9ee6cb5e367f",
        "z": "777823ab3e1fee97",
        "g": "6be6c492a2953951",
        "name": "",
        "x": 150,
        "y": 460,
        "wires": []
    }
]
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

echo " [ACK-IoT Orange Pi Update Version] ติดตั้ง @flowfuse/Dashboard 2.0 เรียบร้อย..."
echo " [ACK-IoT Orange Pi Update Version] Orange Pi พร้อมทำงานแล้ว การอัพเดทเสร็จสำบูรณ์ กรุณารีสตาร์ทอุปกรณ์..."
bash $user/updateandreboot/reb.sh




