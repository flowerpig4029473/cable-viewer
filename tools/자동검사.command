#!/bin/bash
# 자동 검사 (Mac 용 자동검사.bat)
/usr/bin/python3 "$(dirname "$0")/run-tests.py"
echo
read -r -p "엔터를 누르면 닫힙니다…" _
