#!/usr/bin/env python3
"""자동 검사 (Mac 용 run-tests.ps1): 미리보기 서버를 띄우고 브라우저로 tests/test.html 을 열어 결과를 받는다.
  tools/자동검사.command          검사 실행
  tools/기준결과_갱신.command     지금 결과를 기준 결과(tests/expected.json)로 저장

Mac 에는 Edge 가 없으므로 화면 없는 실행 대신 기본 브라우저(Safari)에 검사 탭을 열고,
검사 페이지가 ?send 로 결과를 보내오면 받아서 표시한다.
"""
import argparse
import json
import os
import subprocess
import sys
import threading

ROOT = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
sys.path.insert(0, ROOT)
import serve  # noqa: E402

GREEN, RED, RESET = '\033[32m', '\033[31m', '\033[0m'
TIMEOUT = 180


def main():
    ap = argparse.ArgumentParser(description='케이블 뷰어 자동 검사')
    ap.add_argument('--update', action='store_true', help='지금 결과를 기준 결과로 저장')
    ap.add_argument('--port', type=int, default=8799)
    args = ap.parse_args()

    got, done = {}, threading.Event()

    class Handler(serve.Handler):
        def do_POST(self):
            if self.path_in_root() != '__test-result':
                return self.send(404)
            got['text'] = self.rfile.read(int(self.headers.get('Content-Length') or 0)).decode('utf-8')
            self.send(204)
            done.set()

    server = serve.start(args.port, Handler)
    if not server:
        print('미리보기 서버를 시작하지 못했습니다.')
        return 2
    threading.Thread(target=server.serve_forever, daemon=True).start()
    try:
        url = 'http://localhost:%d/tests/test.html?send%s' % (server.server_address[1], '&update' if args.update else '')
        print('검사 중… (%s)' % url)
        print('브라우저에 검사 탭이 열립니다. 끝날 때까지 그 탭을 닫지 마세요.', flush=True)
        subprocess.run(['open', url], check=False)
        if not done.wait(TIMEOUT):
            print('검사 페이지 결과를 %d초 안에 받지 못했습니다.' % TIMEOUT)
            return 2
        text = got['text']
        try:
            res = json.loads(text)
        except ValueError:
            print('검사 페이지 결과를 읽지 못했습니다.')
            return 2
        if res.get('error'):
            print('실행 실패: ' + res['error'])
            return 2

        if args.update:
            path = os.path.join(ROOT, 'tests', 'expected.json')
            with open(path, 'w', encoding='utf-8', newline='\n') as f:
                f.write(text.strip() + '\n')
            print('기준 결과 저장: ' + path)
            return 0

        print()
        for r in res['results']:
            if r['ok']:
                print('  %s통과%s  %s' % (GREEN, RESET, r['name']))
            else:
                print('  %s실패%s  %s' % (RED, RESET, r['name']))
                for e in r['errs']:
                    print('        - ' + e)
        print()
        if res['ok']:
            print('%s모두 통과 (%d/%d)%s' % (GREEN, res['pass'], res['total'], RESET))
            return 0
        print('%s실패 %d건 (%d/%d)%s' % (RED, res['total'] - res['pass'], res['pass'], res['total'], RESET))
        return 1
    finally:
        server.shutdown()


if __name__ == '__main__':
    sys.exit(main())
