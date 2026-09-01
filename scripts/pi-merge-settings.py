#!/usr/bin/env python3
"""Merge a curated pi settings source into the live settings file.

Usage: pi-merge-settings.py <source.json> <dest.json>

Merges `source.json` (curated dotfiles values) into `dest.json` (pi's live
settings). Rules:
  - `packages` arrays are unioned (deduped, order-preserving: source first).
  - All other keys from `source` override `dest`.
  - Pi auto-managed keys (lastChangelogVersion, etc.) in `dest` are preserved
    since they aren't present in `source`.
  - The live file is written with 2-space indent + trailing newline.
"""

import json
import os
import sys


def load(path: str) -> dict:
    if not os.path.exists(path):
        return {}
    with open(path, "r", encoding="utf-8") as f:
        text = f.read().strip()
    if not text:
        return {}
    try:
        return json.loads(text)
    except json.JSONDecodeError as e:
        print(f"pi: warning: {path} is not valid JSON ({e}); skipping", file=sys.stderr)
        return {}


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2

    src_path, dst_path = sys.argv[1], sys.argv[2]
    src = load(src_path)
    dst = load(dst_path)

    if not src:
        return 0

    # Merge packages: union, source order first, deduped.
    if "packages" in src:
        src_pkgs = [p for p in src["packages"] if isinstance(p, str)]
        dst_pkgs = [
            p for p in dst.get("packages", []) if isinstance(p, str) and p not in src_pkgs
        ]
        # Only touch `packages` if there's something to add (preserve object-form
        # entries like {"source": ...} already present in dest).
        obj_pkgs = [p for p in dst.get("packages", []) if not isinstance(p, str)]
        merged_pkgs = src_pkgs + obj_pkgs + dst_pkgs
        dst["packages"] = merged_pkgs

    # Other curated keys override dest.
    for key, value in src.items():
        if key == "packages":
            continue
        dst[key] = value

    os.makedirs(os.path.dirname(dst_path) or ".", exist_ok=True)
    with open(dst_path, "w", encoding="utf-8") as f:
        json.dump(dst, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"  merged settings -> {dst_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
