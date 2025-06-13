#!/bin/bash
sudo apt update && sudo apt -y upgrade

rm -rf $HOME/loom/dataProduction
rm -d $HOME/loom/dataProduction
rm -rf $HOME/loom/thingsboard
rm -rf $HOME/loom/thingsboard/logdata
rm -d $HOME/loom/thingsboard/logdata
rm -rf $HOME/loom

echo " [ACK-IoT Orange Pi Update Version] ลบไฟล์ข้อมูลสำเร็จ..."
rm $HOME/connected_lemp.sh
rm $HOME/alarm_lemp.sh
echo " [ACK-IoT Orange Pi Update Version] ลบไฟล์ alarm_lemp.sh ลบไฟล์..."
rm $HOME/.node-red/flows.json
echo " [ACK-IoT Orange Pi Update Version] ลบไฟล์ flow.json ลบไฟล์..."
echo " "
mkdir stat_led
mkdir loom
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

cat << EOF > $HOME/loom/config.json
{"state": {"datestamp": " ","ip": " "},"values": {"maintake": {"main": {"min": 0,"max": 0},"take": {"min": 0,"max": 0}},"meter": [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"working": [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]}}
EOF

cat << 'EOF' > $HOME/.node-red/flows.json
[
    {
        "id": "abc53b7593744c7a",
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
        "id": "7fdfcac8ed68fe88",
        "type": "ui-form",
        "z": "abc53b7593744c7a",
        "name": "Date Set",
        "group": "6da9956de8144acb",
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
                "ac1f084370b876a0"
            ]
        ]
    },
    {
        "id": "f574ec999edbf8e8",
        "type": "ui-table",
        "z": "abc53b7593744c7a",
        "group": "6da9956de8144acb",
        "name": "Log",
        "label": "Log",
        "order": 2,
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
        "id": "ac1f084370b876a0",
        "type": "function",
        "z": "abc53b7593744c7a",
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
                "29471feb496ce2fd"
            ]
        ]
    },
    {
        "id": "29471feb496ce2fd",
        "type": "file in",
        "z": "abc53b7593744c7a",
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
                "5e72ed59f47dd6cf"
            ]
        ]
    },
    {
        "id": "5e72ed59f47dd6cf",
        "type": "csv",
        "z": "abc53b7593744c7a",
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
                "f574ec999edbf8e8"
            ]
        ]
    },
    {
        "id": "e5d729bea6f2eaad",
        "type": "ui-event",
        "z": "abc53b7593744c7a",
        "ui": "d6f3a7fd07525d85",
        "name": "",
        "x": 630,
        "y": 120,
        "wires": [
            [
                "e6c671fe6f89feb0"
            ]
        ]
    },
    {
        "id": "e6c671fe6f89feb0",
        "type": "function",
        "z": "abc53b7593744c7a",
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
                "f574ec999edbf8e8"
            ]
        ],
        "l": false
    },
    {
        "id": "32e2d21871673afd",
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
                        "id": "2efec3b2a5b505fd"
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
                        "id": "8978263aac81a018",
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
        "id": "2efec3b2a5b505fd",
        "type": "file in",
        "z": "32e2d21871673afd",
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
                "eba8cd8867675168"
            ]
        ]
    },
    {
        "id": "eba8cd8867675168",
        "type": "csv",
        "z": "32e2d21871673afd",
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
                "8978263aac81a018"
            ]
        ],
        "l": false
    },
    {
        "id": "8978263aac81a018",
        "type": "function",
        "z": "32e2d21871673afd",
        "name": "API Power",
        "func": "const index = global.get(\"config.state.index\");\n\nconst date = msg.payload[index].date;\nconst time = msg.payload[index].time;\nconst date_data = msg.payload[index].date_data;\nconst ip = msg.payload[index].ip;\nconst timestamp = msg.payload[index].timestamp;\n\nconst meter = [\n    msg.payload[index].m_0,\n    msg.payload[index].m_1,\n    msg.payload[index].m_2,\n    msg.payload[index].m_3,\n    msg.payload[index].m_4,\n    msg.payload[index].m_5,\n    msg.payload[index].m_6,\n    msg.payload[index].m_7,\n    msg.payload[index].m_8,\n    msg.payload[index].m_9,\n    msg.payload[index].m_10,\n    msg.payload[index].m_11,\n    msg.payload[index].m_12,\n    msg.payload[index].m_13,\n    msg.payload[index].m_14,\n    msg.payload[index].m_15,\n    msg.payload[index].m_16,\n    msg.payload[index].m_17,\n    msg.payload[index].m_18,\n    msg.payload[index].m_19,\n    msg.payload[index].m_20,\n    msg.payload[index].m_21,\n    msg.payload[index].m_22,\n    msg.payload[index].m_23,\n]\n\nconst working = [\n    msg.payload[index].w_0,\n    msg.payload[index].w_1,\n    msg.payload[index].w_2,\n    msg.payload[index].w_3,\n    msg.payload[index].w_4,\n    msg.payload[index].w_5,\n    msg.payload[index].w_6,\n    msg.payload[index].w_7,\n    msg.payload[index].w_8,\n    msg.payload[index].w_9,\n    msg.payload[index].w_10,\n    msg.payload[index].w_11,\n    msg.payload[index].w_12,\n    msg.payload[index].w_13,\n    msg.payload[index].w_14,\n    msg.payload[index].w_15,\n    msg.payload[index].w_16,\n    msg.payload[index].w_17,\n    msg.payload[index].w_18,\n    msg.payload[index].w_19,\n    msg.payload[index].w_20,\n    msg.payload[index].w_21,\n    msg.payload[index].w_22,\n    msg.payload[index].w_23,\n]\n\nconst API = {\n    'filesystem':{ \n        date: date, \n        time: time, \n        ip: ip, \n        date_data: date_data,\n        timestamp: timestamp\n    },\n    'values':{\n        'meter': {\n            0: meter[0], 1: meter[1], 2: meter[2], 3: meter[3], 4: meter[4], 5: meter[5],\n            6: meter[6], 7: meter[7], 8: meter[8], 9: meter[9], 10: meter[10], 11: meter[11],\n            12: meter[12], 13: meter[13], 14: meter[14], 15: meter[15], 16: meter[16], 17: meter[17],\n            18: meter[18], 19: meter[19], 20: meter[20], 21: meter[21], 22: meter[22], 23: meter[23]\n        },\n        'working': {\n            0: working[0], 1: working[1], 2: working[2], 3: working[3], 4: working[4], 5: working[5],\n            6: working[6], 7: working[7], 8: working[8], 9: working[9], 10: working[10], 11: working[11],\n            12: working[12], 13: working[13], 14: working[14], 15: working[15], 16: working[16], 17: working[17],\n            18: working[18], 19: working[19], 20: working[20], 21: working[21], 22: working[22], 23: working[23]\n        },\n        'total':{\n            \"meter\":{\n                \"total\": msg.payload[index].total_meter,\n                \"A\": msg.payload[index].meter_A,\n                \"B\": msg.payload[index].meter_B,\n            },\n            \"working\":{\n                \"total\": msg.payload[index].total_working,\n                \"A\": msg.payload[index].working_A,\n                \"B\": msg.payload[index].working_B,\n            }\n        },\n        'maintake':{\n            'main':{\n                'now': msg.payload[index].main_now,\n                'min': msg.payload[index].main_min,\n                'max': msg.payload[index].main_max\n            },\n            'take':{\n                'now': msg.payload[index].take_now,\n                'min': msg.payload[index].take_min,\n                'max': msg.payload[index].take_max\n            }\n        }\n    }\n};\nmsg.payload = JSON.stringify(API);\nreturn msg",
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
        "id": "aacfb7a36bc2a8d7",
        "type": "catch",
        "z": "32e2d21871673afd",
        "name": "",
        "scope": [
            "8978263aac81a018"
        ],
        "uncaught": false,
        "x": 90,
        "y": 100,
        "wires": [
            [
                "a34dd13c12ed0b21"
            ]
        ]
    },
    {
        "id": "a34dd13c12ed0b21",
        "type": "function",
        "z": "32e2d21871673afd",
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
        "id": "a11cd52db76956a1",
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
                        "id": "35186dabb29a75a2"
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
        "id": "456e6d86823f7f19",
        "type": "exec",
        "z": "a11cd52db76956a1",
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
        "id": "35186dabb29a75a2",
        "type": "function",
        "z": "a11cd52db76956a1",
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
                "456e6d86823f7f19"
            ]
        ]
    },
    {
        "id": "2a7ed9952b2046ba",
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
                        "id": "dc02e98134398a4d"
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
        "id": "353993b61aa8af74",
        "type": "exec",
        "z": "2a7ed9952b2046ba",
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
        "id": "dc02e98134398a4d",
        "type": "function",
        "z": "2a7ed9952b2046ba",
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
                "353993b61aa8af74"
            ]
        ],
        "icon": "font-awesome/fa-times-circle",
        "l": false
    },
    {
        "id": "fab06adde30cf6e9",
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
                    "id": "865a10ad5d505953",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "6dd9061f2d235f82",
        "type": "http in",
        "z": "fab06adde30cf6e9",
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
        "id": "217dd4a20c72e5a4",
        "type": "http response",
        "z": "fab06adde30cf6e9",
        "name": "API Response",
        "statusCode": "",
        "headers": {},
        "x": 1445,
        "y": 420,
        "wires": [],
        "l": false
    },
    {
        "id": "7f4b687e8b2842d7",
        "type": "function",
        "z": "fab06adde30cf6e9",
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
                "2204ebc2c72a71b2"
            ]
        ],
        "icon": "font-awesome/fa-check",
        "l": false
    },
    {
        "id": "2204ebc2c72a71b2",
        "type": "subflow:2a7ed9952b2046ba",
        "z": "fab06adde30cf6e9",
        "name": "",
        "x": 1510,
        "y": 480,
        "wires": []
    },
    {
        "id": "864ca5d7b8906734",
        "type": "subflow:a11cd52db76956a1",
        "z": "fab06adde30cf6e9",
        "name": "",
        "x": 1405,
        "y": 400,
        "wires": [],
        "l": false
    },
    {
        "id": "b3ef6c1885c3ed66",
        "type": "subflow:32e2d21871673afd",
        "z": "fab06adde30cf6e9",
        "name": "",
        "x": 1310,
        "y": 420,
        "wires": [
            [
                "864ca5d7b8906734",
                "217dd4a20c72e5a4",
                "7f4b687e8b2842d7"
            ]
        ]
    },
    {
        "id": "342992ec7c7e7089",
        "type": "function",
        "z": "fab06adde30cf6e9",
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
                "b3ef6c1885c3ed66"
            ]
        ]
    },
    {
        "id": "6da83df94132e059",
        "type": "http request",
        "z": "fab06adde30cf6e9",
        "name": "",
        "method": "POST",
        "ret": "txt",
        "paytoqs": "ignore",
        "url": "http://192.168.0.9:1880/api/product/device-opi-datasource-8",
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
                "865a10ad5d505953"
            ]
        ]
    },
    {
        "id": "6aae69660f29aabd",
        "type": "function",
        "z": "fab06adde30cf6e9",
        "name": "function 14",
        "func": "delete msg.tocloud;\ndelete msg.columns;\nreturn msg;",
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
                "6da83df94132e059"
            ]
        ],
        "l": false
    },
    {
        "id": "865a10ad5d505953",
        "type": "function",
        "z": "fab06adde30cf6e9",
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
                "7a044657874a4609"
            ]
        ]
    },
    {
        "id": "7a044657874a4609",
        "type": "subflow:2a7ed9952b2046ba",
        "z": "fab06adde30cf6e9",
        "name": "",
        "x": 975,
        "y": 160,
        "wires": [],
        "l": false
    },
    {
        "id": "9bb54d1b8d3187c3",
        "type": "subflow:a11cd52db76956a1",
        "z": "fab06adde30cf6e9",
        "name": "",
        "x": 485,
        "y": 100,
        "wires": [],
        "l": false
    },
    {
        "id": "a92c7f0c1a5108f8",
        "type": "subflow:32e2d21871673afd",
        "z": "fab06adde30cf6e9",
        "name": "",
        "x": 390,
        "y": 120,
        "wires": [
            [
                "9bb54d1b8d3187c3",
                "6aae69660f29aabd"
            ]
        ]
    },
    {
        "id": "7a1747e161640fb7",
        "type": "function",
        "z": "fab06adde30cf6e9",
        "name": "Path",
        "func": "var connected = global.get(\"config.state.connected\");\nvar row = global.get(\"config.state.row\");\nvar index = global.get(\"config.state.index\");\nmsg.path = \"/home/orangepi/loom/data/log.csv\";\nif (connected && (index < row)){\n    return msg;\n}",
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
                "a92c7f0c1a5108f8"
            ]
        ]
    },
    {
        "id": "b7a0777ad38421eb",
        "type": "inject",
        "z": "fab06adde30cf6e9",
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
                "7a1747e161640fb7"
            ]
        ],
        "l": false
    },
    {
        "id": "c7dff1e6d4b5248e",
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
                        "id": "d616ac06bfd2352b"
                    },
                    {
                        "id": "e8bb4fa6ec75a723"
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
                    "id": "6c4f9dbf8e86028b",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "e8bb4fa6ec75a723",
        "type": "function",
        "z": "c7dff1e6d4b5248e",
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
                "6c4f9dbf8e86028b",
                "f79eb8a41a468da1"
            ]
        ]
    },
    {
        "id": "6c4f9dbf8e86028b",
        "type": "function",
        "z": "c7dff1e6d4b5248e",
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
        "id": "f79eb8a41a468da1",
        "type": "csv",
        "z": "c7dff1e6d4b5248e",
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
                "f7ae70092fa77f4c"
            ]
        ]
    },
    {
        "id": "f7ae70092fa77f4c",
        "type": "file",
        "z": "c7dff1e6d4b5248e",
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
        "id": "187cb6f497a1a247",
        "type": "function",
        "z": "c7dff1e6d4b5248e",
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
                "9a55f776d8b46a54"
            ]
        ]
    },
    {
        "id": "9a55f776d8b46a54",
        "type": "fs-file-lister",
        "z": "c7dff1e6d4b5248e",
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
                "7e66d214d24ab49f"
            ]
        ]
    },
    {
        "id": "d616ac06bfd2352b",
        "type": "function",
        "z": "c7dff1e6d4b5248e",
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
        "id": "7e66d214d24ab49f",
        "type": "function",
        "z": "c7dff1e6d4b5248e",
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
                "d9ca87161056251d"
            ]
        ]
    },
    {
        "id": "d9ca87161056251d",
        "type": "exec",
        "z": "c7dff1e6d4b5248e",
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
        "id": "2f9cab71ec43c32a",
        "type": "inject",
        "z": "c7dff1e6d4b5248e",
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
                "187cb6f497a1a247"
            ]
        ],
        "l": false
    },
    {
        "id": "875b8b71e1110627",
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
                        "id": "51560de188eefafe"
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
                    "id": "807402e144b7514f",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "51560de188eefafe",
        "type": "file",
        "z": "875b8b71e1110627",
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
                "1c1a1f771513b2d7"
            ]
        ],
        "l": false
    },
    {
        "id": "b015bf9086c952f5",
        "type": "file in",
        "z": "875b8b71e1110627",
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
                "4c32a3dd2d9fbb1d"
            ]
        ],
        "l": false
    },
    {
        "id": "1c1a1f771513b2d7",
        "type": "delay",
        "z": "875b8b71e1110627",
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
                "b015bf9086c952f5"
            ]
        ],
        "l": false
    },
    {
        "id": "4c32a3dd2d9fbb1d",
        "type": "csv",
        "z": "875b8b71e1110627",
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
                "807402e144b7514f"
            ]
        ],
        "l": false
    },
    {
        "id": "807402e144b7514f",
        "type": "function",
        "z": "875b8b71e1110627",
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
        "id": "ae238763bc9f8d85",
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
                        "id": "adbc7e75f14bcfb1"
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
                        "id": "4b1ff534bfcd330c",
                        "port": 0
                    }
                ]
            },
            {
                "x": 380,
                "y": 80,
                "wires": [
                    {
                        "id": "0e0764acd3e77d9a",
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
        "id": "adbc7e75f14bcfb1",
        "type": "switch",
        "z": "ae238763bc9f8d85",
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
                "1bcff3ebb196a8db"
            ],
            [
                "0e0293ea48613959"
            ]
        ],
        "l": false
    },
    {
        "id": "1bcff3ebb196a8db",
        "type": "function",
        "z": "ae238763bc9f8d85",
        "name": "data Log",
        "func": "const payload = msg.payload;\nconst date = payload.date;\nconst time = payload.time;\nconst timestamp = payload.timestamp;\nconst ip = payload.ip;\nconst date_data = payload.date_data;\n\n// values \nconst main = payload.values.maintake.main;\nconst take = payload.values.maintake.take;\nconst meter = payload.values.meter;\nconst working = payload.values.working;\nconst total = payload.values.total;\n\nmsg.payload = {\n    'date': date,\n    'time': time,\n    'timestamp': timestamp,\n    'ip': ip,\n    'date_data': date_data,\n    'total_meter': total.meter.total,\n    'meter_A': total.meter.A,\n    'meter_B': total.meter.B,\n    'm_0': meter[0],\n    'm_1': meter[1],\n    'm_2': meter[2],\n    'm_3': meter[3],\n    'm_4': meter[4],\n    'm_5': meter[5],\n    'm_6': meter[6],\n    'm_7': meter[7],\n    'm_8': meter[8],\n    'm_9': meter[9],\n    'm_10': meter[10],\n    'm_11': meter[11],\n    'm_12': meter[12],\n    'm_13': meter[13],\n    'm_14': meter[14],\n    'm_15': meter[15],\n    'm_16': meter[16],\n    'm_17': meter[17],\n    'm_18': meter[18],\n    'm_19': meter[19],\n    'm_20': meter[20],\n    'm_21': meter[21],\n    'm_22': meter[22],\n    'm_23': meter[23],\n    'total_working': total.working.total,\n    'working_A': total.working.A,\n    'working_B': total.working.B,\n    'w_0': working[0],\n    'w_1': working[1],\n    'w_2': working[2],\n    'w_3': working[3],\n    'w_4': working[4],\n    'w_5': working[5],\n    'w_6': working[6],\n    'w_7': working[7],\n    'w_8': working[8],\n    'w_9': working[9],\n    'w_10': working[10],\n    'w_11': working[11],\n    'w_12': working[12],\n    'w_13': working[13],\n    'w_14': working[14],\n    'w_15': working[15],\n    'w_16': working[16],\n    'w_17': working[17],\n    'w_18': working[18],\n    'w_19': working[19],\n    'w_20': working[20],\n    'w_21': working[21],\n    'w_22': working[22],\n    'w_23': working[23],\n    'main_now': main.now,\n    'main_min': main.min,\n    'main_max': main.max,\n    'take_now': take.now,\n    'take_min': take.min,\n    'take_max': take.max,\n}\nreturn msg;",
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
                "4b1ff534bfcd330c"
            ]
        ]
    },
    {
        "id": "0e0293ea48613959",
        "type": "function",
        "z": "ae238763bc9f8d85",
        "name": "data Log",
        "func": "const payload = msg.payload;\nconst date = payload.date;\nconst time = payload.time;\nconst timestamp = payload.timestamp;\nconst ip = payload.ip;\nconst date_data = payload.date_data;\n\n// values \nconst main = payload.values.maintake.main;\nconst take = payload.values.maintake.take;\nconst meter = payload.values.meter;\nconst working = payload.values.working;\nconst total = payload.values.total;\n\nmsg.payload = {\n    'date': date,\n    'time': time,\n    'timestamp': timestamp,\n    'ip': ip,\n    'date_data': date_data,\n    'total_meter': total.meter.total,\n    'meter_A': total.meter.A,\n    'meter_B': total.meter.B,\n    'm_0': meter[0],\n    'm_1': meter[1],\n    'm_2': meter[2],\n    'm_3': meter[3],\n    'm_4': meter[4],\n    'm_5': meter[5],\n    'm_6': meter[6],\n    'm_7': meter[7],\n    'm_8': meter[8],\n    'm_9': meter[9],\n    'm_10': meter[10],\n    'm_11': meter[11],\n    'm_12': meter[12],\n    'm_13': meter[13],\n    'm_14': meter[14],\n    'm_15': meter[15],\n    'm_16': meter[16],\n    'm_17': meter[17],\n    'm_18': meter[18],\n    'm_19': meter[19],\n    'm_20': meter[20],\n    'm_21': meter[21],\n    'm_22': meter[22],\n    'm_23': meter[23],\n    'total_working': total.working.total,\n    'working_A': total.working.A,\n    'working_B': total.working.B,\n    'w_0': working[0],\n    'w_1': working[1],\n    'w_2': working[2],\n    'w_3': working[3],\n    'w_4': working[4],\n    'w_5': working[5],\n    'w_6': working[6],\n    'w_7': working[7],\n    'w_8': working[8],\n    'w_9': working[9],\n    'w_10': working[10],\n    'w_11': working[11],\n    'w_12': working[12],\n    'w_13': working[13],\n    'w_14': working[14],\n    'w_15': working[15],\n    'w_16': working[16],\n    'w_17': working[17],\n    'w_18': working[18],\n    'w_19': working[19],\n    'w_20': working[20],\n    'w_21': working[21],\n    'w_22': working[22],\n    'w_23': working[23],\n    'main_now': main.now,\n    'main_min': main.min,\n    'main_max': main.max,\n    'take_now': take.now,\n    'take_min': take.min,\n    'take_max': take.max,\n}\nreturn msg;",
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
                "0e0764acd3e77d9a"
            ]
        ]
    },
    {
        "id": "4b1ff534bfcd330c",
        "type": "csv",
        "z": "ae238763bc9f8d85",
        "name": "",
        "sep": ",",
        "hdrin": "",
        "hdrout": "all",
        "multi": "one",
        "ret": "\\r\\n",
        "temp": "date,time,timestamp,ip,date_data,total_meter,meter_A,meter_B,m_0,m_1,m_2,m_3,m_4,m_5,m_6,m_7,m_8,m_9,m_10,m_11,m_12,m_13,m_14,m_15,m_16,m_17,m_18,m_19,m_20,m_21,m_22,m_23,total_working,working_A,working_B,w_0,w_1,w_2,w_3,w_4,w_5,w_6,w_7,w_8,w_9,w_10,w_11,w_12,w_13,w_14,w_15,w_16,w_17,w_18,w_19,w_20,w_21,w_22,w_23,main_now,main_min,main_max,take_now,take_min,take_max",
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
        "id": "0e0764acd3e77d9a",
        "type": "csv",
        "z": "ae238763bc9f8d85",
        "name": "",
        "sep": ",",
        "hdrin": "",
        "hdrout": "none",
        "multi": "one",
        "ret": "\\r\\n",
        "temp": "date,time,timestamp,ip,date_data,total_meter,meter_A,meter_B,m_0,m_1,m_2,m_3,m_4,m_5,m_6,m_7,m_8,m_9,m_10,m_11,m_12,m_13,m_14,m_15,m_16,m_17,m_18,m_19,m_20,m_21,m_22,m_23,total_working,working_A,working_B,w_0,w_1,w_2,w_3,w_4,w_5,w_6,w_7,w_8,w_9,w_10,w_11,w_12,w_13,w_14,w_15,w_16,w_17,w_18,w_19,w_20,w_21,w_22,w_23,main_now,main_min,main_max,take_now,take_min,take_max",
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
        "id": "5bc49d2cedbc8397",
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
                        "id": "73e5c42378be7c05"
                    },
                    {
                        "id": "b7d9d28e10498573"
                    },
                    {
                        "id": "6d8a80d3e03eb12f"
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
            "x": 620,
            "y": 80,
            "wires": [
                {
                    "id": "d9390a8bc7180283",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "a21a7f9d4d1358fe",
        "type": "file in",
        "z": "5bc49d2cedbc8397",
        "name": "Read",
        "filename": "/home/orangepi/loom/config.json",
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
                "d9390a8bc7180283",
                "959178f71f9a79d1"
            ]
        ],
        "icon": "node-red/sort.svg"
    },
    {
        "id": "6e1e2b603c9965bf",
        "type": "function",
        "z": "5bc49d2cedbc8397",
        "name": "Set value",
        "func": "if(msg.payload){\nconst payload = msg.payload;\n    global.set(\"config.state.ip\", payload.state.ip);\n    global.set(\"config.state.datestamp\", payload.state.datestamp);\n    global.set(\"config.state.index\", payload.state.index || 0);\n    global.set(\"config.state.changehour\", payload.state.changehour || 0);\n\n    let main_min = payload.values.maintake.main.min || 0;\n    global.set(\"values.maintake.main.min\", main_min);\n    let main_max = payload.values.maintake.main.max || 0;\n    global.set(\"values.maintake.main.max\", main_max);\n    let take_min = payload.values.maintake.take.min || 0;\n    global.set(\"values.maintake.take.min\", take_min);\n    let take_max = payload.values.maintake.take.max || 0;\n    global.set(\"values.maintake.take.max\", take_max);\n\n    let meter = payload.values.meter || new Array(24).fill(0);\n    global.set(\"values.meter\", meter);\n    let working = payload.values.working || new Array(24).fill(0);\n    global.set(\"values.working\", working);\n}else {\n    return msg;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 545,
        "y": 140,
        "wires": [
            [
                "208455522b758b21"
            ]
        ],
        "l": false
    },
    {
        "id": "f0d671d88048ef15",
        "type": "catch",
        "z": "5bc49d2cedbc8397",
        "name": "",
        "scope": [
            "a21a7f9d4d1358fe"
        ],
        "uncaught": false,
        "x": 310,
        "y": 180,
        "wires": [
            [
                "e14c8b276ce788d6"
            ]
        ]
    },
    {
        "id": "e14c8b276ce788d6",
        "type": "function",
        "z": "5bc49d2cedbc8397",
        "name": "function 10",
        "func": "msg.payload = undefined;\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 435,
        "y": 180,
        "wires": [
            [
                "6e1e2b603c9965bf"
            ]
        ],
        "l": false
    },
    {
        "id": "208455522b758b21",
        "type": "exec",
        "z": "5bc49d2cedbc8397",
        "command": "reboot -h",
        "addpay": "",
        "append": "",
        "useSpawn": "false",
        "timer": "",
        "winHide": false,
        "oldrc": false,
        "name": "",
        "x": 660,
        "y": 140,
        "wires": [
            [],
            [],
            []
        ]
    },
    {
        "id": "d9390a8bc7180283",
        "type": "function",
        "z": "5bc49d2cedbc8397",
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
        "id": "73e5c42378be7c05",
        "type": "delay",
        "z": "5bc49d2cedbc8397",
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
                "a21a7f9d4d1358fe"
            ]
        ]
    },
    {
        "id": "b7d9d28e10498573",
        "type": "file in",
        "z": "5bc49d2cedbc8397",
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
                "f9e9985a7f8214c4"
            ]
        ],
        "l": false
    },
    {
        "id": "f9e9985a7f8214c4",
        "type": "csv",
        "z": "5bc49d2cedbc8397",
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
                "73a4718750a7674e"
            ]
        ],
        "l": false
    },
    {
        "id": "73a4718750a7674e",
        "type": "function",
        "z": "5bc49d2cedbc8397",
        "name": "le",
        "func": "var length = msg.payload.length\nlength = length - 1\nglobal.set(\"config.state.row\", length)\nreturn msg;",
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
        "id": "6d8a80d3e03eb12f",
        "type": "function",
        "z": "5bc49d2cedbc8397",
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
        "id": "959178f71f9a79d1",
        "type": "json",
        "z": "5bc49d2cedbc8397",
        "name": "",
        "property": "payload",
        "action": "",
        "pretty": false,
        "x": 435,
        "y": 140,
        "wires": [
            [
                "6e1e2b603c9965bf"
            ]
        ],
        "l": false
    },
    {
        "id": "9c705a1cd0d42b1e",
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
                        "id": "55a8ebaef5b1c296"
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
        "id": "d39e4c94d0490896",
        "type": "file",
        "z": "9c705a1cd0d42b1e",
        "name": "config",
        "filename": "/home/orangepi/loom/config.json",
        "filenameType": "str",
        "appendNewline": false,
        "createDir": true,
        "overwriteFile": "true",
        "encoding": "utf8",
        "x": 310,
        "y": 40,
        "wires": [
            []
        ],
        "icon": "node-red/redis.svg"
    },
    {
        "id": "55a8ebaef5b1c296",
        "type": "function",
        "z": "9c705a1cd0d42b1e",
        "name": "fig value",
        "func": "msg.payload = {\n    \"state\": {\n        \"datestamp\": global.get(\"config.state.datestamp\"),\n        \"hourstamp\": global.get(\"config.state.hourstamp\"),\n        \"changehour\": global.get(\"config.state.changehour\"),\n        \"index\": global.get(\"config.state.index\"),\n        \"ip\": global.get(\"config.state.ip\")\n    },\n    \"values\": {\n        \"maintake\": {\n            \"main\": {\n                \"min\": global.get(\"values.maintake.main.min\"),\n                \"max\": global.get(\"values.maintake.main.max\")\n            },\n            \"take\": {\n                \"min\": global.get(\"values.maintake.take.min\"),\n                \"max\": global.get(\"values.maintake.take.max\")\n            }\n        },\n        \"meter\": global.get(\"values.meter\"),\n        \"working\": global.get(\"values.working\")\n    }\n}\nreturn msg;",
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
                "d39e4c94d0490896"
            ]
        ]
    },
    {
        "id": "6431d1fa9822fd88",
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
                        "id": "e7140589ed3b5eab"
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
                        "id": "012cb45d0e01de66",
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
                    "id": "541521bacf7131da",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "012cb45d0e01de66",
        "type": "function",
        "z": "6431d1fa9822fd88",
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
                "541521bacf7131da"
            ]
        ]
    },
    {
        "id": "e7140589ed3b5eab",
        "type": "fs-file-lister",
        "z": "6431d1fa9822fd88",
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
                "012cb45d0e01de66"
            ]
        ],
        "l": false
    },
    {
        "id": "541521bacf7131da",
        "type": "function",
        "z": "6431d1fa9822fd88",
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
        "id": "7da0936fdefa56db",
        "type": "subflow",
        "name": "Modbus Reboot",
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
                    "id": "7f9821e1925cff57",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "920bd0566700dfa9",
        "type": "inject",
        "z": "7da0936fdefa56db",
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
                "d68a0f2645c7cdc8",
                "7f9821e1925cff57"
            ]
        ],
        "icon": "font-awesome/fa-info-circle",
        "l": false
    },
    {
        "id": "d68a0f2645c7cdc8",
        "type": "function",
        "z": "7da0936fdefa56db",
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
                "a42c5de0c486f4c6"
            ]
        ]
    },
    {
        "id": "7f9821e1925cff57",
        "type": "function",
        "z": "7da0936fdefa56db",
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
                "ed4e55e106f0fe30"
            ]
        ]
    },
    {
        "id": "a42c5de0c486f4c6",
        "type": "exec",
        "z": "7da0936fdefa56db",
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
        "id": "c483b5182de93440",
        "type": "exec",
        "z": "7da0936fdefa56db",
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
        "id": "ed4e55e106f0fe30",
        "type": "switch",
        "z": "7da0936fdefa56db",
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
                "c483b5182de93440"
            ]
        ]
    },
    {
        "id": "0767435f4d6529a9",
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
                        "id": "71457ca93b90dfc1"
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
                        "id": "10966293456a0df3",
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
                    "id": "071a29726c5dc8e6",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "71457ca93b90dfc1",
        "type": "ping",
        "z": "0767435f4d6529a9",
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
                "345d48fdf4762747"
            ]
        ],
        "l": false
    },
    {
        "id": "345d48fdf4762747",
        "type": "function",
        "z": "0767435f4d6529a9",
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
                "10966293456a0df3",
                "071a29726c5dc8e6"
            ]
        ]
    },
    {
        "id": "071a29726c5dc8e6",
        "type": "function",
        "z": "0767435f4d6529a9",
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
        "id": "10966293456a0df3",
        "type": "function",
        "z": "0767435f4d6529a9",
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
        "id": "4b50252361a6c012",
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
                        "id": "6e8b3e87259af019"
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
        "id": "6e8b3e87259af019",
        "type": "exec",
        "z": "4b50252361a6c012",
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
        "id": "c16e2bc8e1462c41",
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
                        "id": "62916d94029435d0"
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
                    "id": "5748792e99e20caf",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "62916d94029435d0",
        "type": "moment",
        "z": "c16e2bc8e1462c41",
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
                "5748792e99e20caf"
            ]
        ],
        "l": false
    },
    {
        "id": "5748792e99e20caf",
        "type": "function",
        "z": "c16e2bc8e1462c41",
        "name": "function 1",
        "func": "var date = new Date(msg.payload);\nlet previousDate = new Date(date); \n    previousDate.setDate(previousDate.getDate() - 1).toString().padStart(2, 0);\nvar year = date.getFullYear(); \nvar month = (date.getMonth() + 1).toString().padStart(2, '0');\nvar day = date.getDate().toString().padStart(2, '0');\nvar hours = date.getHours().toString().padStart(2, '0');\nvar minutes = date.getMinutes().toString().padStart(2, '0');\nvar seconds = date.getSeconds().toString().padStart(2, '0');\nvar dateMian = `${year}/${month}/${day}`;\nvar time = `${hours}:${minutes}:${seconds}`;\nvar datestamp = global.get(\"config.state.datestamp\");\nlet hoursNum = Number(hours);\n    globalSet();\n////////////////////////////// end function set date ///////////////////////////////////////\nif (hoursNum >= 8 && hoursNum <= 23) {\n    let dateset = filename(date);\n    var datenow = dateNow(date);\n    global.set(\"config.state.date_data\", dateset);\n} else {\n    let dateset = filename(previousDate);\n    var datenow = dateNow(previousDate);\n    global.set(\"config.state.date_data\", dateset);\n}\n\nif (datestamp) {\n    if (datenow != datestamp) {\n        resetValues();\n        // global.set(\"report\", true);\n        // stamp date\n        global.set(\"config.state.datestamp\", datenow);\n    } else {\n        // stamp date\n        global.set(\"config.state.datestamp\", datenow);\n    }\n} else {\n    global.set(\"config.state.datestamp\", datenow);\n}\n    global.set(\"config.state.datenow\", datenow);\n    msg.payload = {\n        fill: \"green\",\n        shape: \"ring\",\n        text: `DATESTAMP:${datestamp} DATE${day}/${month}/${year} TIME:${time}`\n    };\n    return msg;\n\nfunction filename(date){\n    let year = date.getFullYear();\n    let month = (date.getMonth() + 1).toString().padStart(2, '0');\n    let day = date.getDate().toString().padStart(2, '0');\n    return `${year}${month}${day}`;\n}\n\nfunction resetValues(){\n    var meter = new Array(24).fill(0);\n    global.set(\"values.meter\", meter);\n    var working = new Array(24).fill(0);\n    global.set(\"values.working\", working);\n    global.set(\"values.maintake.main.min\", 0);\n    global.set(\"values.maintake.main.min\", 0);\n    global.set(\"values.maintake.take.min\", 0);\n    global.set(\"values.maintake.take.max\", 0);\n}\n\nfunction globalSet(){\n    global.set(\"config.datetime.date\", dateMian);\n    global.set(\"config.datetime.day\", day);\n    global.set(\"config.datetime.month\", month);\n    global.set(\"config.datetime.year\", year);\n    global.set(\"config.datetime.time\", time);\n    global.set(\"config.datetime.hour\", hours);\n    global.set(\"config.datetime.minute\", minutes);\n    global.set(\"config.datetime.second\", seconds);\n}\n\nfunction dateNow(date){\n    let year = date.getFullYear();\n    let month = (date.getMonth() + 1).toString().padStart(2, '0');\n    let day = date.getDate().toString().padStart(2, '0');\n    return `${year}${month}${day}`;\n}",
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
        "id": "e7e3608f0667a95d",
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
                        "id": "eaba63eb4f942764"
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
                    "id": "cf646db5bc370297",
                    "port": 0
                }
            ]
        }
    },
    {
        "id": "eaba63eb4f942764",
        "type": "exec",
        "z": "e7e3608f0667a95d",
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
                "cf646db5bc370297"
            ],
            [],
            []
        ]
    },
    {
        "id": "cf646db5bc370297",
        "type": "function",
        "z": "e7e3608f0667a95d",
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
        "id": "d6901623d1be4359",
        "type": "inject",
        "z": "e7e3608f0667a95d",
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
        "id": "617cbc1d68f632ff",
        "type": "function",
        "z": "e7e3608f0667a95d",
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
        "id": "fb7041197596873b",
        "type": "file in",
        "z": "e7e3608f0667a95d",
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
                "8760ff1d9df97ba7"
            ]
        ]
    },
    {
        "id": "8760ff1d9df97ba7",
        "type": "csv",
        "z": "e7e3608f0667a95d",
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
                "617cbc1d68f632ff"
            ]
        ],
        "l": false
    },
    {
        "id": "0d821a970fef23e3",
        "type": "tab",
        "label": "Flow 1",
        "disabled": false,
        "info": "",
        "env": []
    },
    {
        "id": "dbb9e280e39bf68b",
        "type": "group",
        "z": "0d821a970fef23e3",
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
            "054306b1db997dff",
            "582e40d157bc2456",
            "8e16b99b62b30eda",
            "499a908579800021",
            "fac7e1e3c4a4af3a",
            "1a87ac396dc77104",
            "4f063bc9b4a1a402",
            "1394218c741b66d9",
            "8055d34639674d57",
            "5161ab69dedea570",
            "3de849382ad1b008",
            "4030e60f528762fb",
            "f7a6d7e82dfc46c1",
            "ce93fc1f8593fad2",
            "e8611e1d415eed5a",
            "d396225ba8a7b405",
            "b4d2e6aa35301385"
        ],
        "x": 774,
        "y": 39,
        "w": 422,
        "h": 422
    },
    {
        "id": "8e54dca34b38bec4",
        "type": "group",
        "z": "0d821a970fef23e3",
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
            "8a1e55ac2d1e9174",
            "c9f576b0868f2001",
            "01c24a8915383f3c",
            "f9ddb31ef691b174"
        ],
        "x": 774,
        "y": 499,
        "w": 422,
        "h": 82
    },
    {
        "id": "779c42b198e15102",
        "type": "group",
        "z": "0d821a970fef23e3",
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
            "99179d046041f1bc",
            "7fcd571219781538",
            "c8ef993ca15e7edf",
            "a2c2408bb5b44da3",
            "211e83f654484919",
            "71015dae2e601cca",
            "eada1f98251df5f7",
            "9fec579145379a4c",
            "81dff65f39246a0f",
            "714e722d84372b0d",
            "261afe584c5fd170",
            "92672ac2cd82f439",
            "3603312d1f525231",
            "a605fe4998765199",
            "f8019e4420e6cc25",
            "7679a160c36878af",
            "2120a13fd3daf2b3",
            "c87fc26d14db54d5",
            "fe1336e56ca7a2a1",
            "72cd5b94198ae41d",
            "f0f85b39421e0f7c",
            "cbe955842ffcdae0",
            "318ebdbcc7a6a6eb",
            "19f9139390e0c9b9",
            "acdb6b75711ab581",
            "5e151477e21aaed4",
            "22b2b53fa7df2366"
        ],
        "x": 44,
        "y": 39,
        "w": 702,
        "h": 542
    },
    {
        "id": "e8611e1d415eed5a",
        "type": "group",
        "z": "0d821a970fef23e3",
        "g": "dbb9e280e39bf68b",
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
        "x": 990,
        "y": 330,
        "w": 40,
        "h": 40
    },
    {
        "id": "054306b1db997dff",
        "type": "subflow:e7e3608f0667a95d",
        "z": "0d821a970fef23e3",
        "g": "dbb9e280e39bf68b",
        "name": "",
        "x": 930,
        "y": 120,
        "wires": []
    },
    {
        "id": "582e40d157bc2456",
        "type": "inject",
        "z": "0d821a970fef23e3",
        "g": "dbb9e280e39bf68b",
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
        "onceDelay": "5",
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 835,
        "y": 80,
        "wires": [
            [
                "054306b1db997dff",
                "4030e60f528762fb"
            ]
        ],
        "icon": "node-red/cog.svg",
        "l": false
    },
    {
        "id": "8e16b99b62b30eda",
        "type": "subflow:c16e2bc8e1462c41",
        "z": "0d821a970fef23e3",
        "g": "dbb9e280e39bf68b",
        "name": "",
        "x": 930,
        "y": 180,
        "wires": []
    },
    {
        "id": "499a908579800021",
        "type": "inject",
        "z": "0d821a970fef23e3",
        "g": "dbb9e280e39bf68b",
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
                "8e16b99b62b30eda"
            ]
        ],
        "icon": "font-awesome/fa-clock-o",
        "l": false
    },
    {
        "id": "fac7e1e3c4a4af3a",
        "type": "subflow:4b50252361a6c012",
        "z": "0d821a970fef23e3",
        "g": "dbb9e280e39bf68b",
        "name": "",
        "x": 1050,
        "y": 240,
        "wires": []
    },
    {
        "id": "1a87ac396dc77104",
        "type": "subflow:0767435f4d6529a9",
        "z": "0d821a970fef23e3",
        "g": "dbb9e280e39bf68b",
        "name": "",
        "x": 930,
        "y": 240,
        "wires": [
            [
                "fac7e1e3c4a4af3a"
            ]
        ]
    },
    {
        "id": "4f063bc9b4a1a402",
        "type": "inject",
        "z": "0d821a970fef23e3",
        "g": "dbb9e280e39bf68b",
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
                "1a87ac396dc77104"
            ]
        ],
        "icon": "font-awesome/fa-globe",
        "l": false
    },
    {
        "id": "1394218c741b66d9",
        "type": "subflow:7da0936fdefa56db",
        "z": "0d821a970fef23e3",
        "g": "dbb9e280e39bf68b",
        "name": "",
        "x": 1090,
        "y": 100,
        "wires": []
    },
    {
        "id": "8055d34639674d57",
        "type": "subflow:6431d1fa9822fd88",
        "z": "0d821a970fef23e3",
        "g": "dbb9e280e39bf68b",
        "name": "",
        "x": 930,
        "y": 300,
        "wires": [
            [
                "3de849382ad1b008"
            ]
        ]
    },
    {
        "id": "5161ab69dedea570",
        "type": "inject",
        "z": "0d821a970fef23e3",
        "g": "dbb9e280e39bf68b",
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
        "x": 835,
        "y": 300,
        "wires": [
            [
                "8055d34639674d57"
            ]
        ],
        "icon": "font-awesome/fa-clock-o",
        "l": false
    },
    {
        "id": "3de849382ad1b008",
        "type": "subflow:9c705a1cd0d42b1e",
        "z": "0d821a970fef23e3",
        "g": "dbb9e280e39bf68b",
        "name": "",
        "x": 1060,
        "y": 300,
        "wires": []
    },
    {
        "id": "4030e60f528762fb",
        "type": "subflow:5bc49d2cedbc8397",
        "z": "0d821a970fef23e3",
        "g": "dbb9e280e39bf68b",
        "name": "",
        "x": 940,
        "y": 80,
        "wires": []
    },
    {
        "id": "8a1e55ac2d1e9174",
        "type": "link in",
        "z": "0d821a970fef23e3",
        "g": "8e54dca34b38bec4",
        "name": "link in 5",
        "links": [
            "318ebdbcc7a6a6eb"
        ],
        "x": 815,
        "y": 540,
        "wires": [
            [
                "c9f576b0868f2001"
            ]
        ],
        "icon": "node-red-contrib-modbus/modbus-icon.png"
    },
    {
        "id": "c9f576b0868f2001",
        "type": "function",
        "z": "0d821a970fef23e3",
        "g": "8e54dca34b38bec4",
        "name": "Values",
        "func": "msg.path = `/home/orangepi/loom/data/log.csv`;\nmsg.file = global.get(\"config.state.file\");\nconst meter = global.get(\"values.meter\");\nconst working = global.get(\"values.working\");\nconst positionA = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];\nconst positionB = [20, 21, 22, 23, 0, 1, 2, 3, 4, 5, 6, 7];\n\nlet meterA = positionA.reduce((acc, pos) => acc + (meter[pos] || 0), 0);\nglobal.set(\"values.total.meter.A\", meterA);\nlet meterB = positionB.reduce((acc, pos) => acc + (meter[pos] || 0), 0);\nglobal.set(\"values.total.meter.B\", meterB);\nlet total_meter = meterA + meterB || 0;\nglobal.set(\"values.total.meter.total\", total_meter);\n\nlet workingA = positionA.reduce((acc, pos) => acc + (working[pos] || 0), 0);\nglobal.set(\"values.total.working.A\", workingA);\nlet workingB = positionB.reduce((acc, pos) => acc + (working[pos] || 0), 0);\nglobal.set(\"values.total.working.B\", workingB);\nlet total_working = workingA + workingB || 0;\nglobal.set(\"values.total.working.total\", total_working);\n\nmsg.payload = {\n    'date': global.get(\"config.datetime.date\"),\n    'time': global.get(\"config.datetime.time\"),\n    'timestamp': global.get(\"config.datetime.timestamp\"),\n    'ip': global.get(\"config.state.ip\"),\n    'date_data': global.get(\"config.state.date_data\"),\n    \"values\":{\n        \"maintake\":{\n            \"main\": global.get(\"values.maintake.main\"),\n            \"take\": global.get(\"values.maintake.take\"),\n        },\n        \"meter\": meter,\n        \"working\": working,\n        \"total\":{\n            \"meter\":{\n                \"A\": global.get(\"values.total.meter.A\"),\n                \"B\": global.get(\"values.total.meter.B\"),\n                \"total\": global.get(\"values.total.meter.total\")\n            },\n            \"working\":{\n                \"A\": global.get(\"values.total.working.A\"),\n                \"B\": global.get(\"values.total.working.B\"),\n                \"total\": global.get(\"values.total.working.total\")\n            }\n        }\n    }\n}\nnode.status({fill:\"blue\",shape:\"dot\",text: global.get(\"config.datetime.time\")});\nreturn msg;",
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
                "01c24a8915383f3c"
            ]
        ],
        "icon": "font-awesome/fa-archive",
        "l": false
    },
    {
        "id": "01c24a8915383f3c",
        "type": "subflow:ae238763bc9f8d85",
        "z": "0d821a970fef23e3",
        "g": "8e54dca34b38bec4",
        "name": "",
        "x": 1030,
        "y": 540,
        "wires": [
            [
                "f9ddb31ef691b174"
            ],
            [
                "f9ddb31ef691b174"
            ]
        ]
    },
    {
        "id": "f9ddb31ef691b174",
        "type": "subflow:875b8b71e1110627",
        "z": "0d821a970fef23e3",
        "g": "8e54dca34b38bec4",
        "name": "",
        "x": 1155,
        "y": 540,
        "wires": [],
        "l": false
    },
    {
        "id": "99179d046041f1bc",
        "type": "modbus-write",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
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
                "c8ef993ca15e7edf",
                "a2c2408bb5b44da3"
            ],
            []
        ]
    },
    {
        "id": "7fcd571219781538",
        "type": "function",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
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
                "71015dae2e601cca"
            ]
        ],
        "l": false
    },
    {
        "id": "c8ef993ca15e7edf",
        "type": "modbus-response",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
        "name": "PLC Response",
        "registerShowMax": "1",
        "x": 425,
        "y": 80,
        "wires": [],
        "l": false
    },
    {
        "id": "a2c2408bb5b44da3",
        "type": "function",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
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
                "eada1f98251df5f7"
            ]
        ],
        "l": false
    },
    {
        "id": "211e83f654484919",
        "type": "inject",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
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
                "9fec579145379a4c",
                "7fcd571219781538"
            ]
        ],
        "icon": "node-red/trigger.svg",
        "l": false
    },
    {
        "id": "71015dae2e601cca",
        "type": "switch",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
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
                "99179d046041f1bc"
            ],
            [
                "81dff65f39246a0f"
            ]
        ],
        "l": false
    },
    {
        "id": "eada1f98251df5f7",
        "type": "modbus-write",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
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
        "x": 520,
        "y": 140,
        "wires": [
            [
                "714e722d84372b0d"
            ],
            []
        ]
    },
    {
        "id": "9fec579145379a4c",
        "type": "function",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
        "name": "timestamp",
        "func": "flow.set(\"config.datetime.timestamp\", msg.timestamp);\nnode.status({ fill: \"blue\", shape: \"dot\", text: msg.timestamp });",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 175,
        "y": 180,
        "wires": [
            []
        ],
        "l": false
    },
    {
        "id": "81dff65f39246a0f",
        "type": "modbus-getter",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
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
                "261afe584c5fd170",
                "92672ac2cd82f439"
            ],
            []
        ]
    },
    {
        "id": "714e722d84372b0d",
        "type": "modbus-response",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
        "name": "PLC Response",
        "registerShowMax": "1",
        "x": 605,
        "y": 120,
        "wires": [],
        "l": false
    },
    {
        "id": "261afe584c5fd170",
        "type": "modbus-response",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
        "name": "PLC Response",
        "registerShowMax": "1",
        "x": 445,
        "y": 180,
        "wires": [],
        "l": false
    },
    {
        "id": "92672ac2cd82f439",
        "type": "function",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
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
                "3603312d1f525231"
            ]
        ]
    },
    {
        "id": "3603312d1f525231",
        "type": "modbus-getter",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
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
                "a605fe4998765199",
                "f8019e4420e6cc25"
            ],
            []
        ]
    },
    {
        "id": "a605fe4998765199",
        "type": "modbus-response",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
        "name": "PLC Response",
        "registerShowMax": "1",
        "x": 445,
        "y": 260,
        "wires": [],
        "l": false
    },
    {
        "id": "f8019e4420e6cc25",
        "type": "function",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
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
                "7679a160c36878af"
            ]
        ]
    },
    {
        "id": "7679a160c36878af",
        "type": "modbus-getter",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
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
                "2120a13fd3daf2b3",
                "c87fc26d14db54d5"
            ],
            []
        ]
    },
    {
        "id": "2120a13fd3daf2b3",
        "type": "modbus-response",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
        "name": "PLC Response",
        "registerShowMax": "7",
        "x": 445,
        "y": 340,
        "wires": [],
        "l": false
    },
    {
        "id": "c87fc26d14db54d5",
        "type": "function",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
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
                "fe1336e56ca7a2a1"
            ]
        ]
    },
    {
        "id": "fe1336e56ca7a2a1",
        "type": "modbus-getter",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
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
                "72cd5b94198ae41d",
                "f0f85b39421e0f7c",
                "19f9139390e0c9b9",
                "acdb6b75711ab581"
            ],
            []
        ]
    },
    {
        "id": "72cd5b94198ae41d",
        "type": "modbus-response",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
        "name": "PLC Response",
        "registerShowMax": "1",
        "x": 445,
        "y": 420,
        "wires": [],
        "l": false
    },
    {
        "id": "f0f85b39421e0f7c",
        "type": "function",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
        "name": "Modbus [600]",
        "func": "var second = msg.payload[0] // working time (second)\nvar working_ = global.get(\"values.working\");\nvar hour = global.get(\"config.datetime.hour\")\nvar showtime\n    working_.splice(Number(hour), 1, second)\nvar hours = Math.floor(second / 3600)\nvar minutes = Math.floor((second % 3600) / 60)\nvar seconds = Math.floor((second % 60) / 1)\nshowtime = hours + ':' + minutes + ':' + seconds\nnode.status({ fill: \"blue\", shape: \"dot\", text: global.get(\"config.datetime.time\") +  \" : working: [\" + hour + \"] = \" + showtime });\nreturn msg",
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
                "cbe955842ffcdae0"
            ]
        ]
    },
    {
        "id": "cbe955842ffcdae0",
        "type": "delay",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
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
                "318ebdbcc7a6a6eb"
            ]
        ],
        "l": false
    },
    {
        "id": "318ebdbcc7a6a6eb",
        "type": "link out",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
        "name": "link out 6",
        "mode": "link",
        "links": [
            "8a1e55ac2d1e9174"
        ],
        "x": 705,
        "y": 460,
        "wires": []
    },
    {
        "id": "19f9139390e0c9b9",
        "type": "function",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
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
        "id": "f7a6d7e82dfc46c1",
        "type": "subflow:c7dff1e6d4b5248e",
        "z": "0d821a970fef23e3",
        "g": "dbb9e280e39bf68b",
        "name": "",
        "x": 1115,
        "y": 160,
        "wires": [],
        "l": false
    },
    {
        "id": "ce93fc1f8593fad2",
        "type": "inject",
        "z": "0d821a970fef23e3",
        "g": "dbb9e280e39bf68b",
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
        "x": 1045,
        "y": 160,
        "wires": [
            [
                "f7a6d7e82dfc46c1"
            ]
        ],
        "l": false
    },
    {
        "id": "d396225ba8a7b405",
        "type": "subflow:fab06adde30cf6e9",
        "z": "0d821a970fef23e3",
        "g": "dbb9e280e39bf68b",
        "name": "",
        "x": 930,
        "y": 360,
        "wires": []
    },
    {
        "id": "acdb6b75711ab581",
        "type": "modbus-getter",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
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
                "5e151477e21aaed4",
                "22b2b53fa7df2366"
            ],
            []
        ]
    },
    {
        "id": "5e151477e21aaed4",
        "type": "modbus-response",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
        "name": "PLC Response",
        "registerShowMax": "2",
        "x": 445,
        "y": 500,
        "wires": [],
        "l": false
    },
    {
        "id": "22b2b53fa7df2366",
        "type": "function",
        "z": "0d821a970fef23e3",
        "g": "779c42b198e15102",
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
        "id": "b4d2e6aa35301385",
        "type": "subflow:abc53b7593744c7a",
        "z": "0d821a970fef23e3",
        "g": "dbb9e280e39bf68b",
        "name": "",
        "x": 940,
        "y": 420,
        "wires": []
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
    }
]
EOF

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

echo " [ACK-IoT Orange Pi Update Version] ลบข้อมูล <Loom Config> เรียบร้อย..."
echo " [ACK-IoT Orange Pi Update Version] ติดตั้ง led state เรียบร้อย..."
echo " [ACK-IoT Orange Pi Update Version] ติดตั้ง flows.json เรียบร้อย..."
echo " [ACK-IoT Orange Pi Update Version] ติดตั้ง @flowfuse/Dashboard 2.0 เรียบร้อย..."
echo " [ACK-IoT Orange Pi Update Version] Orange Pi พร้อมทำงานแล้ว การอัพเดทเสร็จสำบูรณ์ กรุณารีสตาร์ทอุปกรณ์..."
bash $HOME/updateandreboot/reb.sh
