#!/bin/bash
# iec-tables.json으로 규격값_확인표.csv를 다시 만든다 (Mac 용 규격값_확인표_만들기.bat)
/usr/bin/python3 -B "$(dirname "$0")/make-checklist.py"
echo
read -r -p "엔터를 누르면 닫힙니다…" _
