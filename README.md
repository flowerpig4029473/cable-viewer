# 케이블 단면 3D 뷰어

설계자가 확인한 케이블 단면 DXF를 3D와 IEC 60502 판정 요약으로 보여주는 뷰어.

- 게시 주소: https://claude.ai/artifact/PxqBR9SAGmAG24PMjgz39Y

## 파일

| 파일 | 내용 |
|---|---|
| `index.html` | 뷰어 본체 (게시 원본) |
| `report.json` | 게시된 보고 데이터 (설계자가 게시하면 바뀜) |
| `미리보기.bat` | 더블클릭하면 이 PC에서 뷰어가 열림 |
| `serve.ps1` | 미리보기용 로컬 서버 |

## 미리보기

`미리보기.bat`을 더블클릭하면 브라우저가 열린다. 창을 닫으면 종료된다.
`index.html`을 직접 열면 `report.json`을 못 읽어 보고 화면이 비어 보인다.

## 변경 기록 (git)

```
git status                  # 바뀐 파일 확인
git add -A                  # 바뀐 내용 모두 담기
git commit -m "변경 내용"    # 기록 남기기
git log --oneline           # 기록 목록
```
