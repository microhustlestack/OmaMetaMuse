#!/usr/bin/env python3
"""Check local Markdown links in the project documentation."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FILES = [
    ROOT / "README.md",
    ROOT / "SECURITY.md",
    ROOT / "DISCLAIMER.md",
    *sorted((ROOT / "docs").glob("*.md")),
    ROOT / "plugin" / "README.md",
]
LINK = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")


def main() -> int:
    missing: list[str] = []
    for path in FILES:
        if not path.exists():
            missing.append(f"{path.relative_to(ROOT)}: file does not exist")
            continue
        text = path.read_text(encoding="utf-8")
        for match in LINK.finditer(text):
            link = match.group(1).strip()
            if not link or link.startswith(("http://", "https://", "mailto:", "#")):
                continue
            target = link.split("#", 1)[0]
            if not target:
                continue
            resolved = (path.parent / target).resolve()
            if not resolved.exists():
                missing.append(f"{path.relative_to(ROOT)}: {link}")
    if missing:
        print("Broken local links:", file=sys.stderr)
        for item in missing:
            print(f"  {item}", file=sys.stderr)
        return 1
    print(f"  checked {len(FILES)} documents")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
