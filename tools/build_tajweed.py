"""Builds app/assets/quran/hafs_tajweed.json: tajweed colouring for the Hafs text.

The rules are the decision trees of cpfair/quran-tajweed (data under CC BY 4.0),
run on the KFGQPC Hafs text. Those trees were trained on the Tanzil Uthmani
text, which writes a few marks with other code points, so each aya is first
rewritten into Tanzil's conventions and the results are mapped back onto the
original KFGQPC string.

Usage: python3 tools/build_tajweed.py <path to cpfair/quran-tajweed>
"""

import glob
import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "app" / "assets" / "quran" / "hafs_tajweed.json"

# KFGQPC code point -> Tanzil code point. None drops the character.
TO_TANZIL = {
    "\u06e1": "\u0652",  # sukun, drawn by KFGQPC as a dotless khah head
    "\u0652": "\u06df",  # round zero over a silent letter
    "\u0657": "\u064b",  # open fathatan
    "\u065e": "\u064c",  # open dammatan
    "\u0656": "\u064d",  # open kasratan
    "\u06e7": "\u06e6",  # small yeh, as in «إِبۡرَٰهِـۧمَ»
    "\u00a0": " ",
    "\u06e4": None,  # small madda before a sajdah mark
    "\u06de": None,  # rub el hizb
    "\u06e9": None,  # place of sajdah
    # Pause marks: the trees were trained without them, and one glued to
    # «ٱللَّهِۚ» hides the name of Allah from the lam rule.
    **dict.fromkeys("\u06d6\u06d7\u06d8\u06d9\u06da\u06db"),
}

TANWEEN_OF = {"\u064e": "\u064b", "\u064f": "\u064c", "\u0650": "\u064d"}

# Order matters: the index is what the app stores.
RULES = [
    "hamzat_wasl", "silent", "lam_shamsiyyah",
    "madd_2", "madd_246", "madd_muttasil", "madd_munfasil", "madd_6",
    "qalqalah", "ghunnah",
    "ikhfa", "ikhfa_shafawi", "iqlab",
    "idghaam_ghunnah", "idghaam_no_ghunnah", "idghaam_shafawi",
    "idghaam_mutajanisayn", "idghaam_mutaqaribayn",
]


def to_tanzil(text):
    """Returns the converted text and, for each of its characters, the index
    of the character it came from in [text]."""
    out, src = [], []
    for i, ch in enumerate(text):
        # KFGQPC writes a tanween turned into meem (iqlab) as a single vowel
        # with a small meem; Tanzil keeps the tanween before the meem.
        if ch in TANWEEN_OF and text[i + 1:i + 2] in ("\u06e2", "\u06ed"):
            ch = TANWEEN_OF[ch]
        if ch == "\u0640" and text[i + 1:i + 2] == "\u06e7":
            continue  # the tatweel only carries the small yeh
        ch = TO_TANZIL.get(ch, ch)
        if ch is None:
            continue
        out.append(ch)
        src.append(i)
    # Collapse the double space a dropped mark can leave behind.
    s, m = [], []
    for ch, i in zip(out, src):
        if ch == " " and (not s or s[-1] == " "):
            continue
        s.append(ch)
        m.append(i)
    while s and s[-1] == " ":
        s.pop()
        m.pop()
    return "".join(s), m


def main():
    repo = Path(sys.argv[1]).resolve()
    sys.path.insert(0, str(repo))
    from tree import json2tree  # noqa: E402

    # The classifier asserts that no rule is left open at the end of an aya.
    # KFGQPC marks iqlab across an aya break (4:137 «سَبِيلَۢا» before «بَشِّرِ»),
    # where the next letter is in the next aya; such an open rule is dropped.
    src = (repo / "tajweed_classifier.py").read_text()
    src = src.replace("assert all(len(q) == 0", "assert True or all(len(q) == 0")
    classifier = {"__name__": "tajweed_classifier"}
    exec(compile(src, "tajweed_classifier.py", "exec"), classifier)
    label_ayah = classifier["label_ayah"]

    trees = {}
    for start in glob.glob(str(repo / "rule_trees" / "*.start.json")):
        name = os.path.basename(start).partition(".")[0]
        trees[name] = {
            "start": json2tree(json.load(open(start))),
            "end": json2tree(json.load(open(start.replace(".start.", ".end.")))),
        }
    assert set(trees) == set(RULES), sorted(set(trees) ^ set(RULES))

    data = json.load(open(ROOT / "app" / "assets" / "quran" / "hafs.json"))
    bare = [a[7].rstrip("0123456789٠١٢٣٤٥٦٧٨٩  ") for a in data["ayat"]]
    basmala, basmala_map = to_tanzil(bare[0])  # 1:1 is the basmala in Hafs

    ayat = []
    for a, text in zip(data["ayat"], bare):
        sura, aya = a[0], a[1]
        t, m = to_tanzil(text)
        # The classifier expects Tanzil's layout, where each sura's first aya
        # starts with the basmala, and cuts it off itself.
        prefixed = sura not in (1, 9) and aya == 1
        if prefixed:
            t = basmala + " " + t
        res = label_ayah((sura, aya, t, trees))
        shift = len(basmala) + 1 if prefixed else 0
        spans = []
        for an in res["annotations"]:
            s, e = an["start"] - shift, an["end"] - shift
            if s < 0:
                continue
            # Map back; the end is exclusive, and a swapped shadda can put
            # the original characters out of order.
            spans.append([RULES.index(an["rule"]), min(m[s:e]), max(m[s:e]) + 1])
        ayat.append(spans)

    OUT.write_text(json.dumps({
        "source": "cpfair/quran-tajweed decision trees (CC BY 4.0) on KFGQPC Hafs text",
        "rules": RULES,
        "ayat": ayat,
    }, ensure_ascii=False, separators=(",", ":")))
    print(f"{OUT}: {sum(map(len, ayat))} spans over {len(ayat)} ayat")


if __name__ == "__main__":
    main()
