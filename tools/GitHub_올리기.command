#!/bin/bash
# 바뀐 내용(게시한 케이블 포함)을 GitHub에 올린다. 1~2분 뒤 QR 화면에 반영. (Mac 용 GitHub_올리기.bat)
cd "$(dirname "$0")/.." || exit 1
git add report.json cables
git diff --cached --quiet || git commit -q -m "보고 게시"
git push -u origin main
echo
read -r -p "엔터를 누르면 닫힙니다…" _
