#!/usr/bin/env python3
"""iec-tables.json → 규격값_확인표.csv (엑셀에서 열어 규격 원문과 대조). Mac 용 make-checklist.ps1
  tools/규격값_확인표_만들기.command 더블클릭
"""
import csv
import json
import os
from decimal import Decimal

ROOT = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
STATUS = {'verified': '원문 확인', 'crosschecked': '공개자료 일치', 'unverified': '원문 대조 필요'}
MAT = {'CU': '연동', 'AL': '알루미늄', 'XLPE': 'XLPE', 'PVC': 'PVC', 'EPR': 'EPR'}
TYPE = {'round': '원형 비압축', 'compact': '원형 압축'}


def num(v):
    return str(v)   # Decimal 로 읽어 원문 표기(0.0470 등)를 그대로 유지


def cond_of(r):
    if r.get('cond'):
        return r['cond']
    parts = []
    if r.get('mat'):
        parts.append(MAT.get(r['mat'], r['mat']))
    if r.get('type'):
        parts.append(TYPE.get(r['type'], ''))
    if r.get('cls'):
        parts.append('%s kV' % r['cls'])
    if r.get('maxSize') is not None:
        parts.append('%s mm² 이하 구간' % num(r['maxSize']))
    if r.get('size') is not None:
        parts.append('%s mm²' % num(r['size']))
    if 'maxD' in r:
        parts.append('하부 직경 그 이상' if r['maxD'] is None else '하부 직경 %s mm 이하' % num(r['maxD']))
    return ' · '.join(parts)


def main():
    with open(os.path.join(ROOT, 'iec-tables.json'), encoding='utf-8-sig') as f:
        data = json.load(f, parse_float=Decimal)
    rows = []
    for it in data['items']:
        for r in it['rows']:
            st = r.get('status') or it['status']
            rows.append([it['title'], it['key'], r['id'], it['source'], it['ref'], cond_of(r), num(r['value']), it.get('unit', ''),
                         STATUS[st], '', '', r.get('verifiedBy') or '', r.get('verifiedAt') or '', r.get('note') or it.get('checked') or ''])
    path = os.path.join(ROOT, '규격값_확인표.csv')
    with open(path, 'w', encoding='utf-8-sig', newline='') as f:
        w = csv.writer(f, quoting=csv.QUOTE_ALL, lineterminator='\n')
        w.writerow(['구분', '항목키', '행ID', '규격', '표·조항', '조건', '현재값', '단위', '상태', '원문값', '일치(O/X)', '확인자', '확인일', '비고'])
        w.writerows(rows)
    print('완료: %s (%d행)' % (path, len(rows)))


if __name__ == '__main__':
    main()
