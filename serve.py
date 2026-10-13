#!/usr/bin/env python3
"""Local preview server for the cable viewer (Mac version of serve.ps1).

"/" serves index.html wrapped in the same page skeleton the Claude artifact host adds;
other paths (report.json, later module files) are served from this folder.
  python3 serve.py [--port 8765] [--no-browser]
"""
import argparse
import os
import re
import subprocess
import sys
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote, urlsplit

ROOT = os.path.dirname(os.path.realpath(__file__))
TYPES = {'.json': 'application/json; charset=utf-8', '.js': 'text/javascript; charset=utf-8',
         '.css': 'text/css; charset=utf-8', '.html': 'text/html; charset=utf-8'}
HEAD = ('<!doctype html><html lang="ko"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">'
        '<style>:root{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}'
        'body{margin:0}[hidden]{display:none!important}</style></head><body>')
CABLE_PATH = re.compile(r'^cables/([a-z0-9]{4,16})\.json$')


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass

    def path_in_root(self):
        return unquote(urlsplit(self.path).path).lstrip('/')

    def send(self, status, body=b'', ctype=None):
        self.send_response(status)
        if ctype:
            self.send_header('Content-Type', ctype)
        self.send_header('Cache-Control', 'no-store')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        if body and self.command != 'HEAD':
            self.wfile.write(body)

    def do_GET(self):
        path = self.path_in_root()
        if path in ('', 'index.html'):
            with open(os.path.join(ROOT, 'index.html'), encoding='utf-8-sig') as f:
                html = HEAD + f.read() + '</body></html>'
            return self.send(200, html.encode('utf-8'), 'text/html; charset=utf-8')
        full = os.path.realpath(os.path.join(ROOT, path))
        if os.path.commonpath([full, ROOT]) != ROOT or not os.path.isfile(full):
            return self.send(404)
        with open(full, 'rb') as f:
            body = f.read()
        self.send(200, body, TYPES.get(os.path.splitext(full)[1].lower(), 'application/octet-stream'))

    do_HEAD = do_GET

    def do_PUT(self):
        # 뷰어의 "확인 완료 · 게시" → cables/<id>.json (QR 주소) + report.json (최신 보고) 저장 후 GitHub에 올림
        path = self.path_in_root()
        text = self.rfile.read(int(self.headers.get('Content-Length') or 0)).decode('utf-8')
        m = CABLE_PATH.match(path)
        if not m or not text.lstrip().startswith('{'):
            return self.send(400)
        os.makedirs(os.path.join(ROOT, 'cables'), exist_ok=True)
        for name in (path, 'report.json'):
            with open(os.path.join(ROOT, name), 'w', encoding='utf-8', newline='') as f:
                f.write(text)
        print('게시: ' + path, flush=True)
        subprocess.Popen(['/bin/bash', os.path.join(ROOT, 'tools', 'publish-push.sh'), m.group(1)],
                         stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                         start_new_session=True)
        self.send(204)


def start(port, handler=Handler):
    """port 부터 20개 번호 중 비어 있는 곳에 서버를 연다."""
    for p in range(port, port + 20):
        try:
            return ThreadingHTTPServer(('127.0.0.1', p), handler)
        except OSError:
            pass
    return None


def main():
    ap = argparse.ArgumentParser(description='케이블 뷰어 미리보기 서버')
    ap.add_argument('--port', type=int, default=8765)
    ap.add_argument('--no-browser', action='store_true')
    args = ap.parse_args()
    server = start(args.port)
    if not server:
        print('No free port found.')
        sys.exit(1)
    url = 'http://localhost:%d/' % server.server_address[1]
    print('케이블 뷰어 미리보기: ' + url)
    print('이 창을 닫으면 종료됩니다.', flush=True)
    if not args.no_browser:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    main()
