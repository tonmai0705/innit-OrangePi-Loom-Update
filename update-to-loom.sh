#!/bin/bash

echo "กำลัสร้างไฟล์...gitDLTest.sh"
cat << EOR > gitDLTest.sh
#!/bin/bash
echo "ปริ้นนนนนนนนนนนนนเด้อ"

EOR
echo "กำลัสร้างไฟล์  gitDLTest.sh is successfully"
chmod +x /home/orangepi/gitDLtest.sh

echo "กำลัสร้างไฟล์...gitDLTest2.sh"
cat << EOR2 > gitDLTest2.sh
#!/bin/bash
echo "ปริ้นนนนนนนนนนนนนเด้อ2"

EOR2
echo "กำลัสร้างไฟล์  gitDLTest2.sh is successfully"
chmod +x /home/orangepi/gitDLtest2.sh
