"""Serves Builds/web like itch.io does with "SharedArrayBuffer support" on: with the
cross-origin isolation headers a threaded Godot web build needs.
Usage: python tools/serve_web.py [port]   (default 8767)"""
import http.server
import os
import sys


class Isolated(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8767
    os.chdir(os.path.join(os.path.dirname(__file__), "..", "Builds", "web"))
    http.server.ThreadingHTTPServer(("", port), Isolated).serve_forever()