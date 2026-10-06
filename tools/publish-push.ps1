param([Parameter(Mandatory)][string]$Id)
# 미리보기에서 게시한 케이블을 GitHub에 올린다 (serve.ps1 이 게시 때마다 실행).
# 올라가면 1~2분 뒤 https://flowerpig4029473.github.io/cable-viewer/?c=<Id> 에서 열린다.
$root = Split-Path -Parent $PSScriptRoot
$git = 'C:\Program Files\Git\cmd\git.exe'
$log = Join-Path $env:TEMP 'cable-viewer-publish.log'
$env:GIT_TERMINAL_PROMPT = '0'
"$(Get-Date -Format s) 게시 $Id" | Out-File $log -Append -Encoding utf8
& $git -C $root add -- report.json "cables/$Id.json" 2>&1 | Out-File $log -Append -Encoding utf8
& $git -C $root commit -q -m "보고 게시: $Id" -- report.json "cables/$Id.json" 2>&1 | Out-File $log -Append -Encoding utf8
& $git -C $root push -q origin main 2>&1 | Out-File $log -Append -Encoding utf8
"$(Get-Date -Format s) 종료 $LASTEXITCODE" | Out-File $log -Append -Encoding utf8
