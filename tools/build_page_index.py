"""Builds app/assets/pages/<riwaya>.json: where each aya sits on the printed pages.

The printed pages are the KFGQPC Madinah Mushaf artwork published as SVG by
quran-ws/quran-svg. The app downloads the artwork itself on demand; this index
is small enough to bundle, so the app knows which aya was touched before any
page is on the device.

Usage: python3 tools/build_page_index.py <path to quran-svg checkout>
(a sparse checkout of mushafs/*/kfqc/json is enough)
"""

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "app" / "assets" / "pages"
RIWAYAT = ["warsh", "hafs", "qalon", "douri", "shubah"]
PAGES = 604
NUMBER = re.compile(r"-?\d+(?:\.\d+)?")


def polygons(shape):
    """Each ring of an aya's hit region as a flat [x, y, x, y, ...] list.

    The source ships two shapes: SVG path data on page 3 onwards, one
    rectangular subpath per printed line, and a bare "x,y x,y" point list on
    the opening pages."""
    rings = shape.split("M")[1:] if shape.lstrip().startswith("M") else [shape]
    out = []
    for ring in rings:
        n = [round(float(v), 1) for v in NUMBER.findall(ring)]
        out.append(n)
    return out


def main():
    src = Path(sys.argv[1]).resolve()
    commit = subprocess.run(["git", "-C", str(src), "rev-parse", "HEAD"],
                            capture_output=True, text=True, check=True).stdout.strip()
    OUT.mkdir(parents=True, exist_ok=True)
    for riwaya in RIWAYAT:
        pages = []
        for p in range(1, PAGES + 1):
            ayat = json.loads((src / "mushafs" / riwaya / "kfqc" / "json" / f"{p:03d}.json").read_text())
            pages.append([[a["surahNumber"], a["ayahNumber"], polygons(a["polygon"])] for a in ayat])
        out = OUT / f"{riwaya}.json"
        out.write_text(json.dumps({
            "source": "quran-ws/quran-svg (KFGQPC Madinah Mushaf artwork; index CC BY 4.0)",
            "commit": commit,
            "artwork": f"mushafs/{riwaya}/kfqc/svg-br/{{page}}.svg.br",
            "pages": pages,
        }, separators=(",", ":")))
        print(f"{out}: {sum(map(len, pages))} aya regions, {out.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
