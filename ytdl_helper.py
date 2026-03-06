#!/usr/bin/env python3
"""
ytdl_helper.py — Advanced helper for AW Downloader
Handles: playlist extraction, metadata, JSON output
"""

import sys
import json
import subprocess
import os
from pathlib import Path


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


def main():
    if len(sys.argv) < 2:
        print("Usage: ytdl_helper.py <command> [args]")
        print("Commands: check-deps, get-info <url>, get-playlists <url>")
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
