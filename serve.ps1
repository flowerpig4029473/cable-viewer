param([int]$Port = 8765, [switch]$NoBrowser)
# Local preview server for the cable viewer.
# "/" serves index.html wrapped in the same page skeleton the Claude artifact host adds;
# other paths (report.json, later module files) are served from this folder.
$dir = $PSScriptRoot
$types = @{ '.json' = 'application/json; charset=utf-8'; '.js' = 'text/javascript; charset=utf-8'; '.css' = 'text/css; charset=utf-8'; '.html' = 'text/html; charset=utf-8' }

$listener = $null
for ($p = $Port; $p -lt $Port + 20; $p++) {
  try {
    $l = New-Object System.Net.HttpListener
    $l.Prefixes.Add("http://localhost:$p/")
    $l.Start()
    $listener = $l; $Port = $p; break
  } catch { }
}
if (-not $listener) { Write-Host "No free port found."; exit 1 }

$url = "http://localhost:$Port/"
Write-Host "Cable viewer preview: $url"
Write-Host "Close this window to stop."
if (-not $NoBrowser) { Start-Process $url }

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  try {
    $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
    if ($ctx.Request.HttpMethod -eq 'PUT') {
      # 뷰어의 "확인 완료 · 게시" → cables/<id>.json (QR 주소) + report.json (최신 보고) 저장 후 GitHub에 올림
      $reader = New-Object System.IO.StreamReader($ctx.Request.InputStream, [System.Text.Encoding]::UTF8)
      $text = $reader.ReadToEnd()
      $m = [regex]::Match($path, '^cables/([a-z0-9]{4,16})\.json$')
      if (-not $m.Success -or -not $text.TrimStart().StartsWith('{')) { $ctx.Response.StatusCode = 400; $ctx.Response.Close(); continue }
      $utf8 = New-Object System.Text.UTF8Encoding $false
      New-Item -ItemType Directory -Force (Join-Path $dir 'cables') | Out-Null
      [System.IO.File]::WriteAllText((Join-Path $dir $path), $text, $utf8)
      [System.IO.File]::WriteAllText((Join-Path $dir 'report.json'), $text, $utf8)
      Write-Host "게시: $path"
      Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$dir\tools\publish-push.ps1`"", '-Id', $m.Groups[1].Value
      $ctx.Response.StatusCode = 204; $ctx.Response.Close(); continue
    }
    if ($path -eq '' -or $path -eq 'index.html') {
      $body = [System.IO.File]::ReadAllText((Join-Path $dir 'index.html'), [System.Text.Encoding]::UTF8)
      $html = '<!doctype html><html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"><style>:root{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}body{margin:0}[hidden]{display:none!important}</style></head><body>' + $body + '</body></html>'
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($html)
      $ctx.Response.ContentType = 'text/html; charset=utf-8'
    } else {
      $full = [System.IO.Path]::GetFullPath((Join-Path $dir $path))
      if (-not $full.StartsWith($dir) -or -not (Test-Path -LiteralPath $full -PathType Leaf)) {
        $ctx.Response.StatusCode = 404; $ctx.Response.Close(); continue
      }
      $bytes = [System.IO.File]::ReadAllBytes($full)
      $ext = [System.IO.Path]::GetExtension($full).ToLower()
      $ctx.Response.ContentType = if ($types.ContainsKey($ext)) { $types[$ext] } else { 'application/octet-stream' }
    }
    $ctx.Response.Headers.Add('Cache-Control', 'no-store')
    $ctx.Response.ContentLength64 = $bytes.Length
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  } catch { Write-Host $_ }
  $ctx.Response.Close()
}
