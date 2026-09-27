# iec-tables.json → 규격값_확인표.csv (엑셀에서 열어 규격 원문과 대조)
# 실행: 폴더에서 tools\규격값_확인표_만들기.bat 더블클릭
$root = Split-Path -Parent $PSScriptRoot
$json = [System.IO.File]::ReadAllText((Join-Path $root 'iec-tables.json'), [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$statusText = @{ verified = '원문 확인'; crosschecked = '공개자료 일치'; unverified = '원문 대조 필요' }
$matText = @{ CU = '연동'; AL = '알루미늄'; XLPE = 'XLPE'; PVC = 'PVC'; EPR = 'EPR' }
$typeText = @{ round = '원형 비압축'; compact = '원형 압축' }

$out = foreach ($it in $json.items) {
  foreach ($r in $it.rows) {
    $cond = $r.cond
    if (-not $cond) {
      $parts = @()
      if ($r.mat)  { $parts += $(if ($matText.ContainsKey($r.mat)) { $matText[$r.mat] } else { $r.mat }) }
      if ($r.type) { $parts += $typeText[$r.type] }
      if ($r.cls)  { $parts += "$($r.cls) kV" }
      if ($null -ne $r.maxSize) { $parts += "$($r.maxSize) mm² 이하 구간" }
      if ($null -ne $r.size)    { $parts += "$($r.size) mm²" }
      if ($r.PSObject.Properties.Name -contains 'maxD') {
        $parts += $(if ($null -eq $r.maxD) { '하부 직경 그 이상' } else { "하부 직경 $($r.maxD) mm 이하" })
      }
      $cond = $parts -join ' · '
    }
    $st = if ($r.status) { $r.status } else { $it.status }
    [pscustomobject]@{
      '구분'      = $it.title
      '항목키'    = $it.key
      '행ID'      = $r.id
      '규격'      = $it.source
      '표·조항'   = $it.ref
      '조건'      = $cond
      '현재값'    = $r.value
      '단위'      = $it.unit
      '상태'      = $statusText[$st]
      '원문값'    = ''
      '일치(O/X)' = ''
      '확인자'    = $(if ($r.verifiedBy) { $r.verifiedBy } else { '' })
      '확인일'    = $(if ($r.verifiedAt) { $r.verifiedAt } else { '' })
      '비고'      = $(if ($r.note) { $r.note } else { '' })
    }
  }
}
$csv = Join-Path $root '규격값_확인표.csv'
$out | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8
Write-Host "완료: $csv ($(@($out).Count)행)"
