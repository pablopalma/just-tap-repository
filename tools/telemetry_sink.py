"""Local stand-in for the Google Apps Script that receives the beta play data.

Appends every received event to a CSV with the same columns as the sheet, so the game's sending
and tools/beta_report.py can be tested without the real sheet.

    python tools/telemetry_sink.py 8770 Builds/telemetry_test.csv
    godot --path . -- --telemetry-url=http://localhost:8770/
"""
import csv
import datetime
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

COLUMNS = ["received", "uid", "session", "version", "platform", "lang", "t", "event", "barrier", "data"]
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8770
OUT = sys.argv[2] if len(sys.argv) > 2 else "telemetry_test.csv"


class Sink(BaseHTTPRequestHandler):
    def do_POST(self):
        raw = self.rfile.read(int(self.headers.get("Content-Length", 0))).decode("utf-8")
        try:
            b = json.loads(raw)
        except ValueError:
            self.send_response(400)
            self.end_headers()
            return
        now = datetime.datetime.now().isoformat(timespec="seconds")
        new = False
        try:
            open(OUT).close()
        except FileNotFoundError:
            new = True
        with open(OUT, "a", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            if new:
                w.writerow(COLUMNS)
            for x in b.get("ev", []):
                w.writerow([now, b.get("uid"), b.get("sid"), b.get("v"), b.get("plat"), b.get("lang"),
                            x.get("t"), x.get("e"), x.get("n"), json.dumps(x.get("d", {}))])
                print(f"{b.get('plat')} {x.get('e'):9} n={x.get('n')} {json.dumps(x.get('d', {}))}", flush=True)
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("", PORT), Sink).serve_forever()
