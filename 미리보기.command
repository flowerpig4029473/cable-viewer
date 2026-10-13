#!/bin/bash
# 더블클릭하면 이 Mac에서 뷰어가 열린다 (Mac 용 미리보기.bat). 창을 닫으면 종료.
exec /usr/bin/python3 "$(dirname "$0")/serve.py"
