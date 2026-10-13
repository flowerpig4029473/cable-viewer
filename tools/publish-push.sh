#!/bin/bash
# 미리보기에서 게시한 케이블을 GitHub에 올린다 (serve.py 가 게시 때마다 실행, Mac 용 publish-push.ps1).
# 올라가면 1~2분 뒤 https://flowerpig4029473.github.io/cable-viewer/?c=<Id> 에서 열린다.
id="$1"
root="$(cd "$(dirname "$0")/.." && pwd)"
log="${TMPDIR:-/tmp}/cable-viewer-publish.log"
export GIT_TERMINAL_PROMPT=0
{
  echo "$(date +%Y-%m-%dT%H:%M:%S) 게시 $id"
  git -C "$root" add -- report.json "cables/$id.json"
  git -C "$root" commit -q -m "보고 게시: $id" -- report.json "cables/$id.json"
  git -C "$root" push -q origin main
  echo "$(date +%Y-%m-%dT%H:%M:%S) 종료 $?"
} >> "$log" 2>&1
