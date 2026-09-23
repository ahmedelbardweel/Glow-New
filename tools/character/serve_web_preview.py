"""Serve the Flutter web preview without browser asset caching.

This is only a local development helper.  It makes every refresh request the
current character model, which is important while iterating on GLB assets.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import re
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit


class PreviewRevision:
    """Give both Flutter and its assets a fresh URL when the build changes."""

    def __init__(self, root: Path) -> None:
        self.files = [root / name for name in (
            "index.html", "flutter_bootstrap.js", "main.dart.js",
            "assets/assets/3d/glow_mascot.glb",
        )]
        self.signature = None

    def refresh(self) -> None:
        signature = tuple((path.stat().st_mtime_ns, path.stat().st_size)
                          for path in self.files)
        if signature != self.signature:
            digest = hashlib.sha256()
            for path in self.files:
                digest.update(hashlib.sha256(path.read_bytes()).digest())
            self.revision = digest.hexdigest()[:12]
            self.model_revision = hashlib.sha256(self.files[-1].read_bytes()).hexdigest()
            self.prefix = f"/preview/{self.revision}/"
            self.signature = signature


class NoCacheHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, revision: PreviewRevision, **kwargs) -> None:
        self.preview = revision
        super().__init__(*args, **kwargs)

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        self.send_header("X-Preview-Revision", self.preview.revision)
        self.send_header("X-Character-Revision", self.preview.model_revision)
        super().end_headers()

    def translate_path(self, path: str) -> str:
        # The prefix isolates every asset, including rootBundle's GLB request,
        # from previously cached URLs without modifying compiled Flutter code.
        path = re.sub(r"^/preview/[0-9a-f]{12}/", "/", path)
        return super().translate_path(path)

    def send_head(self):
        self.preview.refresh()
        path = urlsplit(self.path).path
        if path in ("/", "/index.html"):
            self.send_response(307)
            self.send_header("Location", self.preview.prefix)
            self.send_header("Content-Length", "0")
            self.end_headers()
            return None

        match = re.fullmatch(r"(/preview/[0-9a-f]{12}/)(?:index.html)?", path)
        if match:
            if match[1] != self.preview.prefix:
                self.send_response(307)
                self.send_header("Location", self.preview.prefix)
                self.send_header("Content-Length", "0")
                self.end_headers()
                return None
            html = (Path(self.directory) / "index.html").read_text(encoding="utf-8")
            html, count = re.subn(r'<base\s+href="[^"]*"\s*/?>',
                                 f'<base href="{self.preview.prefix}">', html, count=1)
            if count != 1:
                self.send_error(500, "Flutter index.html must contain a base href")
                return None
            badge = (
                '<div id="glow-preview-revision" lang="ar" dir="rtl" '
                'style="position:fixed;left:12px;bottom:12px;z-index:2147483647;'
                'pointer-events:none;padding:6px 10px;border-radius:8px;'
                'background:#173c32;color:white;font:12px sans-serif">'
                f'نسخة الشخصية: {self.preview.model_revision[:8]}</div>'
            )
            body = html.replace("</body>", badge + "</body>").encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            return io.BytesIO(body)
        return super().send_head()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default="build/web")
    parser.add_argument("--port", type=int, default=8766)
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if not root.is_dir():
        raise SystemExit(f"Preview directory does not exist: {root}")

    revision = PreviewRevision(root)
    revision.refresh()
    address = ("127.0.0.1", args.port)
    handler = partial(NoCacheHandler, directory=str(root), revision=revision)
    server = ThreadingHTTPServer(address, handler)
    print(f"Serving {root} on http://{address[0]}:{address[1]}{revision.prefix}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
