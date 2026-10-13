#!/bin/bash
# 지금 판정 결과를 기준 결과(tests/expected.json)로 저장 (Mac 용 기준결과_갱신.bat)
/usr/bin/python3 "$(dirname "$0")/run-tests.py" --update
echo
read -r -p "엔터를 누르면 닫힙니다…" _
