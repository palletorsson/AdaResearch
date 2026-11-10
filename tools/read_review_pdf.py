#!/usr/bin/env python3
"""Read back a review PDF made by tools/timeline_review_pdf.py and filled in offline (Palle, 2026-11-10: "... where we
can comment on the artifacts and you can read later").

Reads the form fields (each work's comment box and keep / improve / remove / move ticks, and the general notes) and,
for readers that save annotations instead, every sticky note / free-text / highlight comment, mapped to its work by
the page list the PDF carries in its metadata. Writes <pdf>.comments.json and prints the answers as markdown.

    python tools/read_review_pdf.py ada_run/reviews/fractals/fractals_review.pdf [--all]   # --all: list blank works too
"""
from __future__ import annotations

import json
import sys
from collections import defaultdict
from pathlib import Path


def read(path: Path) -> dict:
    from pypdf import PdfReader
    pdf = PdfReader(str(path))
    meta = {}
    try:
        meta = json.loads((pdf.metadata or {}).get("/Subject") or "{}")
    except (TypeError, ValueError):
        pass
    pages = meta.get("pages", {})
    works: dict = defaultdict(lambda: {"verdicts": [], "comment": "", "notes": []})
    for name, f in (pdf.get_fields() or {}).items():
        if "__" not in name:
            continue
        key, what = name.rsplit("__", 1)
        value = f.get("/V")
        if what == "comment":
            text = str(value or "").strip()
            if text:
                works[key]["comment"] = text
        elif value not in (None, "", "/Off", "Off"):
            works[key]["verdicts"].append(what)
    for i, page in enumerate(pdf.pages, start=1):
        for a in page.get("/Annots") or []:
            a = a.get_object()
            if a.get("/Subtype") in ("/Widget", "/Link"):
                continue
            text = str(a.get("/Contents") or "").strip()
            if text:
                works[pages.get(str(i), f"_page_{i}")]["notes"].append(text)
    return {"pdf": str(path), "sequence": meta.get("ada_review"), "made": meta.get("made"),
            "order": list(pages.values()), "works": {k: v for k, v in works.items()}}


def main(argv: list) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    args = [a for a in argv[1:] if not a.startswith("--")]
    if not args:
        raise SystemExit(__doc__)
    path = Path(args[0])
    r = read(path)
    out = path.with_suffix(".comments.json")
    out.write_text(json.dumps(r, ensure_ascii=False, indent=1), encoding="utf-8")
    said = {k: v for k, v in r["works"].items() if v["comment"] or v["verdicts"] or v["notes"]}
    print(f"## Review of {r['sequence']} (made {r['made']}): {len([k for k in said if not k.startswith('_')])} works "
          f"answered of {len([k for k in r['order'] if not k.startswith('_')])}")
    for key in r["order"] + [k for k in said if k not in r["order"]]:
        v = said.get(key)
        if not v and "--all" not in argv:
            continue
        v = v or {"verdicts": [], "comment": "", "notes": []}
        print(f"\n### {key}" + (f"  [{', '.join(v['verdicts'])}]" if v["verdicts"] else ""))
        if v["comment"]:
            print(v["comment"])
        for n in v["notes"]:
            print(f"- note: {n}")
    print(f"\n(saved {out})")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
