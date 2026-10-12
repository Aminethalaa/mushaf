#!/usr/bin/env python3
"""Converts the KFGQPC data for each riwaya into the compact assets the app loads.

Usage: python3 tools/build_quran_data.py <path to quran-data-kfgqpc checkout>

The Quran text is copied byte for byte from the source; this script only
restructures it. Run it again whenever the source publishes a new version.
"""
import hashlib
import json
import sys
from pathlib import Path

SOURCES = {
    "hafs": ("hafs/data/hafsData_v18.json", "hafs/font/hafs.18.ttf", "sora", "sora_name_ar", 6236),
    "warsh": ("warsh/data/warshData_v10.json", "warsh/font/warsh.10.ttf", "sura_no", "sura_name_ar", 6214),
    "qalon": ("qaloon/data/QaloonData_v10.json", "qaloon/font/qaloon.10.ttf", "sura_no", "sura_name_ar", 6214),
    "douri": ("doori/data/DooriData_v09.json", "doori/font/doori.9.ttf", "sura_no", "sura_name_ar", 6217),
    "shubah": ("shouba/data/ShoubaData08.json", "shouba/font/shouba.8.ttf", "sura_no", "sura_name_ar", 6236),
}
PAGES = 604
SURAS = 114


def build(src: Path, out: Path, riwaya: str) -> dict:
    data_file, font_file, sura_key, name_key, expected = SOURCES[riwaya]
    raw = (src / data_file).read_bytes()
    rows = json.loads(raw.decode("utf-8-sig"))
    assert len(rows) == expected, f"{riwaya}: {len(rows)} ayat, expected {expected}"

    suras, ayat = [], []
    for row in rows:
        pages = [int(p) for p in str(row["page"]).split("-")]
        sura = int(row[sura_key])
        aya = int(row["aya_no"])
        if aya == 1:
            assert len(suras) == sura - 1, f"{riwaya}: sura {sura} out of order"
            suras.append({
                "no": sura,
                "nameAr": row[name_key].strip(),
                "nameEn": row["sora_name_en" if riwaya == "hafs" else "sura_name_en"].strip(),
                "page": pages[0],
                "ayat": 0,
            })
        suras[-1]["ayat"] += 1
        ayat.append([
            sura, aya, pages[0], pages[-1], int(row["jozz"]),
            int(row["line_start"]), int(row["line_end"]),
            row["aya_text"],
            row.get("aya_text_emlaey", ""),
        ])

    assert len(suras) == SURAS, f"{riwaya}: {len(suras)} suras"
    first_pages = {a[2] for a in ayat}
    # A page can be entirely the tail of an aya begun on the page before.
    missing = set(range(1, PAGES + 1)) - first_pages
    assert all(any(a[2] < p <= a[3] for a in ayat) for p in missing), f"{riwaya}: page gaps"
    assert max(a[3] for a in ayat) == PAGES

    payload = {
        "riwaya": riwaya,
        "source": f"KFGQPC {data_file}",
        "sourceSha1": hashlib.sha1(raw).hexdigest(),
        "pages": PAGES,
        "suras": suras,
        "fields": ["sura", "aya", "page", "pageEnd", "juz", "lineStart", "lineEnd", "text", "plain"],
        "ayat": ayat,
    }
    (out / "quran").mkdir(parents=True, exist_ok=True)
    (out / "quran" / f"{riwaya}.json").write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    (out / "fonts").mkdir(parents=True, exist_ok=True)
    (out / "fonts" / f"{riwaya}.ttf").write_bytes((src / font_file).read_bytes())
    return {"riwaya": riwaya, "ayat": len(ayat), "suras": len(suras), "sha1": payload["sourceSha1"]}


if __name__ == "__main__":
    src = Path(sys.argv[1])
    out = Path(__file__).resolve().parent.parent / "app" / "assets"
    for name in SOURCES:
        print(build(src, out, name))
