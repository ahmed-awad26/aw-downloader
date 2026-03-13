#!/usr/bin/env python3
"""
ytdl_helper.py — Advanced helper for AW Downloader
Handles: playlist extraction, metadata, JSON output
"""

import sys
import json
import subprocess
import os
import re
from pathlib import Path
from urllib.parse import urlparse, parse_qs, unquote


def run_yt_dlp(args: list, capture=True) -> tuple[int, str, str]:
    """Run yt-dlp with given arguments."""
    cmd = ["yt-dlp"] + args
    if capture:
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=300
        )
        return result.returncode, result.stdout, result.stderr
    else:
        result = subprocess.run(cmd)
        return result.returncode, "", ""


def get_channel_info(url: str) -> dict:
    """Extract channel metadata."""
    code, out, err = run_yt_dlp([
        "--flat-playlist",
        "--print", "%(channel)s\t%(channel_id)s\t%(uploader_url)s",
        "--playlist-items", "1",
        url
    ])
    if code != 0 or not out.strip():
        return {"name": "Unknown", "id": "", "url": url}

    parts = out.strip().split("\t")
    return {
        "name": parts[0] if len(parts) > 0 else "Unknown",
        "id": parts[1] if len(parts) > 1 else "",
        "url": parts[2] if len(parts) > 2 else url,
    }


def get_playlists(channel_url: str) -> list[dict]:
    """Get all playlists from a channel."""
    playlists_url = channel_url.rstrip("/") + "/playlists"
    code, out, err = run_yt_dlp([
        "--flat-playlist",
        "--print", "%(playlist_id)s|||%(playlist_title)s|||%(playlist_count)s",
        playlists_url
    ])

    playlists = []
    seen = set()
    for line in out.strip().splitlines():
        parts = line.split("|||")
        if len(parts) >= 2:
            pl_id = parts[0].strip()
            pl_title = parts[1].strip()
            pl_count = parts[2].strip() if len(parts) > 2 else "?"
            if pl_id and pl_id not in seen and pl_id != "NA":
                seen.add(pl_id)
                playlists.append({
                    "id": pl_id,
                    "title": pl_title,
                    "count": pl_count,
                    "url": f"https://www.youtube.com/playlist?list={pl_id}"
                })
    return playlists


def sanitize_filename(name: str, max_len: int = 80) -> str:
    """Sanitize string for use as directory name."""
    import re
    # Keep Arabic, English, numbers, common symbols
    safe = re.sub(r'[<>:"/\\|?*]', '_', name)
    safe = safe.strip('. ')
    return safe[:max_len] or "Unknown"


def create_channel_structure(base_dir: str, channel_name: str, playlists: list) -> dict:
    """Create folder structure for channel."""
    safe_name = sanitize_filename(channel_name)
    channel_dir = Path(base_dir) / safe_name
    channel_dir.mkdir(parents=True, exist_ok=True)

    structure = {
        "channel_dir": str(channel_dir),
        "playlists": {}
    }

    # Create playlist subdirs
    pl_base = channel_dir / "Playlists"
    pl_base.mkdir(exist_ok=True)

    for pl in playlists:
        safe_pl = sanitize_filename(pl["title"])
        pl_dir = pl_base / safe_pl
        pl_dir.mkdir(exist_ok=True)
        structure["playlists"][pl["id"]] = str(pl_dir)

    # Create standard subdirs
    for subdir in ["Uploads", "Uncategorized", "Latest"]:
        (channel_dir / subdir).mkdir(exist_ok=True)

    return structure


def save_channel_metadata(channel_dir: str, info: dict, playlists: list):
    """Save channel info to JSON file."""
    meta = {
        "channel": info,
        "playlists": playlists,
        "downloaded_at": __import__("datetime").datetime.now().isoformat()
    }
    meta_file = Path(channel_dir) / "channel_metadata.json"
    with open(meta_file, "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)
    print(f"[INFO] Metadata saved: {meta_file}")


def check_dependencies() -> dict:
    """Check all required tools."""
    tools = {
        "yt-dlp": ["yt-dlp", "--version"],
        "ffmpeg": ["ffmpeg", "-version"],
        "python3": ["python3", "--version"],
        "curl": ["curl", "--version"],
        "git": ["git", "--version"],
    }
    results = {}
    for name, cmd in tools.items():
        try:
            out = subprocess.check_output(cmd, stderr=subprocess.STDOUT,
                                          text=True, timeout=5)
            results[name] = {"ok": True, "version": out.splitlines()[0]}
        except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
            results[name] = {"ok": False, "version": None}
    return results



def _fmt_size(num):
    try:
        n = int(num or 0)
    except Exception:
        return None
    units = ["B", "KB", "MB", "GB", "TB"]
    size = float(n)
    idx = 0
    while size >= 1024 and idx < len(units) - 1:
        size /= 1024.0
        idx += 1
    return f"{size:.1f} {units[idx]}" if idx else f"{int(size)} B"


def _extract_redirect_target(url: str) -> str:
    try:
        q = parse_qs(urlparse(url).query)
        for key in ("url", "u", "target", "dest", "destination", "redirect", "redirect_url", "r"):
            if key in q and q[key]:
                cand = unquote(q[key][0]).strip()
                if cand.startswith(("http://", "https://")):
                    return cand
    except Exception:
        pass
    return url


MIME_TO_EXT = {
    "application/zip": "zip",
    "application/x-rar-compressed": "rar",
    "application/rar": "rar",
    "application/vnd.rar": "rar",
    "application/x-7z-compressed": "7z",
    "application/pdf": "pdf",
    "application/epub+zip": "epub",
    "application/vnd.android.package-archive": "apk",
    "application/x-msdownload": "exe",
    "application/x-bittorrent": "torrent",
    "video/mp4": "mp4",
    "video/mpeg": "mp4",
    "video/x-matroska": "mkv",
    "video/webm": "webm",
    "video/x-msvideo": "avi",
    "video/quicktime": "mov",
    "audio/mpeg": "mp3",
    "audio/mp4": "m4a",
    "audio/x-m4a": "m4a",
    "audio/ogg": "ogg",
    "audio/flac": "flac",
    "audio/x-flac": "flac",
    "audio/wav": "wav",
    "audio/aac": "aac",
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/gif": "gif",
    "image/webp": "webp",
    "text/plain": "txt",
    "application/json": "json",
    "application/msword": "doc",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "docx",
    "application/vnd.ms-excel": "xls",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": "xlsx",
}


def _ensure_extension(filename: str, content_type: str) -> str:
    """Add extension to filename if it has none, based on content-type."""
    if not filename:
        return filename
    p = Path(filename)
    if p.suffix:
        return filename
    # Normalize content-type (strip params)
    ct = (content_type or "").split(";")[0].strip().lower()
    ext = MIME_TO_EXT.get(ct, "")
    if ext:
        return f"{filename}.{ext}"
    return filename


def probe_file_url(url: str) -> dict:
    url = _extract_redirect_target(url.strip())
    data = {
        "ok": False,
        "url": url,
        "final_url": url,
        "filename": "",
        "filesize": None,
        "filesize_human": None,
        "content_type": "",
        "extractor": "",
    }

    try:
        code, out, err = run_yt_dlp([
            "--dump-single-json",
            "--skip-download",
            "--no-warnings",
            url,
        ])
        if code == 0 and out.strip():
            meta = json.loads(out)
            direct = meta.get("url") or meta.get("webpage_url") or url
            fsize = meta.get("filesize") or meta.get("filesize_approx")
            ext = meta.get("ext")
            title = meta.get("title") or meta.get("filename") or ""
            if title and ext and not str(title).lower().endswith(f".{ext}".lower()):
                title = f"{title}.{ext}"
            data.update({
                "ok": True,
                "final_url": direct,
                "filename": title or data["filename"],
                "filesize": fsize,
                "filesize_human": _fmt_size(fsize) if fsize else None,
                "content_type": meta.get("http_headers", {}).get("Content-Type", ""),
                "extractor": meta.get("extractor_key") or meta.get("extractor") or "",
            })
    except Exception:
        pass

    try:
        import requests
        headers = {"User-Agent": "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36"}
        r = requests.head(data.get("final_url") or url, allow_redirects=True, timeout=20, headers=headers)
        disp = r.headers.get("content-disposition", "")
        m = re.search(r'filename\*?=(?:UTF-8\'\')?"?([^";]+)', disp, re.I)
        fname = unquote(m.group(1)).strip() if m else ""
        clen = r.headers.get("content-length")
        ctype = (r.headers.get("content-type") or "").split(";")[0].strip()
        final = getattr(r, "url", data.get("final_url") or url)
        data["final_url"] = final
        if fname and not data.get("filename"):
            data["filename"] = fname
        if clen and str(clen).isdigit() and not data.get("filesize"):
            data["filesize"] = int(clen)
            data["filesize_human"] = _fmt_size(clen)
        if ctype and not data.get("content_type"):
            data["content_type"] = ctype
        if not data.get("filename"):
            tail = Path(urlparse(final).path).name
            data["filename"] = tail or Path(urlparse(url).path).name or f"download_{os.getpid()}"
        data["ok"] = True
    except Exception:
        if not data.get("filename"):
            tail = Path(urlparse(url).path).name
            data["filename"] = tail or f"download_{os.getpid()}"

    # Ensure the filename has a proper extension
    data["filename"] = _ensure_extension(
        data.get("filename", ""),
        data.get("content_type", "")
    )

    return data

def main():
    if len(sys.argv) < 2:
        print("Usage: ytdl_helper.py <command> [args]")
        print("Commands: check-deps, get-info <url>, get-playlists <url>, probe-file <url>")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "check-deps":
        deps = check_dependencies()
        for name, info in deps.items():
            status = "✔" if info["ok"] else "✘"
            ver = info["version"] or "NOT FOUND"
            print(f"  {status} {name}: {ver}")

    elif cmd == "get-info" and len(sys.argv) >= 3:
        info = get_channel_info(sys.argv[2])
        print(json.dumps(info, ensure_ascii=False))

    elif cmd == "get-playlists" and len(sys.argv) >= 3:
        pls = get_playlists(sys.argv[2])
        print(json.dumps(pls, ensure_ascii=False, indent=2))

    elif cmd == "probe-file" and len(sys.argv) >= 3:
        print(json.dumps(probe_file_url(sys.argv[2]), ensure_ascii=False))

    elif cmd == "setup-dirs" and len(sys.argv) >= 5:
        base_dir = sys.argv[2]
        channel_name = sys.argv[3]
        pls_json = sys.argv[4]
        pls = json.loads(pls_json)
        struct = create_channel_structure(base_dir, channel_name, pls)
        print(json.dumps(struct, ensure_ascii=False))

    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)


if __name__ == "__main__":
    main()
