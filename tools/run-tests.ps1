param([switch]$Update, [int]$Port = 8799)
# 자동 검사: 미리보기 서버를 띄우고 Edge를 화면 없이 실행해 tests/test.html 결과를 보여준다.
#   tools\자동검사.bat            검사 실행
#   tools\기준결과_갱신.bat       지금 결과를 기준 결과(tests/expected.json)로 저장
$root = Split-Path -Parent $PSScriptRoot
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$browser = @(
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $browser) { Write-Host 'Edge 또는 Chrome이 필요합니다.'; exit 2 }

$tmp = Join-Path $env:TEMP 'cable-viewer-test'
New-Item -ItemType Directory -Force $tmp | Out-Null
$log = Join-Path $tmp 'server.txt'
Remove-Item -LiteralPath $log -ErrorAction SilentlyContinue
$server = Start-Process powershell -PassThru -WindowStyle Hidden -RedirectStandardOutput $log `
  -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$root\serve.ps1`"", '-Port', $Port, '-NoBrowser'

try {
  # 서버가 알려준 주소 (포트가 사용 중이면 다음 번호로 열림)
  $base = $null
  for ($i = 0; $i -lt 50 -and -not $base; $i++) {
    Start-Sleep -Milliseconds 200
    if (Test-Path $log) {
      $m = Select-String -LiteralPath $log -Pattern 'http://localhost:\d+/' | Select-Object -First 1
      if ($m) { $base = $m.Matches[0].Value }
    }
  }
  if (-not $base) { Write-Host '미리보기 서버를 시작하지 못했습니다.'; exit 2 }

  $url = $base + 'tests/test.html' + $(if ($Update) { '?update' } else { '' })
  Write-Host "검사 중… ($url)"
  $flags = @('--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--no-first-run',
             "--user-data-dir=`"$tmp\browser`"", '--virtual-time-budget=120000', '--dump-dom', $url)
  $dump = Join-Path $tmp 'dom.html'
  Start-Process $browser -ArgumentList $flags -Wait -WindowStyle Hidden -RedirectStandardOutput $dump -RedirectStandardError (Join-Path $tmp 'browser-err.txt')
  $dom = [System.IO.File]::ReadAllText($dump, [System.Text.Encoding]::UTF8)

  $pre = [regex]::Match($dom, '<pre id="out"[^>]*>([\s\S]*?)</pre>')
  if (-not $pre.Success -or -not $pre.Groups[1].Value.Trim()) { Write-Host '검사 페이지 결과를 읽지 못했습니다.'; exit 2 }
  $text = [System.Net.WebUtility]::HtmlDecode($pre.Groups[1].Value)

  if ($Update) {
    $file = Join-Path $root 'tests\expected.json'
    [System.IO.File]::WriteAllText($file, $text.Trim() + "`n", (New-Object System.Text.UTF8Encoding $false))
    Write-Host "기준 결과 저장: $file"
    exit 0
  }

  $res = $text | ConvertFrom-Json
  if ($res.error) { Write-Host "실행 실패: $($res.error)"; exit 2 }
  Write-Host ''
  foreach ($r in $res.results) {
    if ($r.ok) { Write-Host "  통과  $($r.name)" -ForegroundColor Green }
    else {
      Write-Host "  실패  $($r.name)" -ForegroundColor Red
      foreach ($e in $r.errs) { Write-Host "        - $e" }
    }
  }
  Write-Host ''
  if ($res.ok) { Write-Host "모두 통과 ($($res.pass)/$($res.total))" -ForegroundColor Green; exit 0 }
  Write-Host "실패 $($res.total - $res.pass)건 ($($res.pass)/$($res.total))" -ForegroundColor Red
  exit 1
} finally {
  Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
}
