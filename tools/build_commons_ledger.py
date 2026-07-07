"""build_commons_ledger.py — the commons ledger beside the dig ledger.

The standing fourth question made into data: whose knowledge is each artifact's
form pressed from, and does the walk RETURN it (credit a source) or ENCLOSE it
(use a form whose makers stay nameless)?

Reads doc/book/commons_sources.json (the authored taxonomy of sources) and
matches every artifact — its registry description + name + @identity essence/
lineage + the baseline VOLTAGE prose that cites it — against each source's match
terms. Produces:
  · per-artifact: which sources it draws on
  · per-source: which artifacts lean on it (the debt owed to each maker)
  · summary: named vs collective vs mathematical vs nature vs institutional;
    the RETURN LINE — how much of the book's form is credited vs anonymous.

Output:
  doc/book/commons_ledger.json
  <encyclopedia>/public/commons-ledger.json

Usage: python tools/build_commons_ledger.py
"""

import glob
import json
import os
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent.parent
ENC = Path(os.environ.get("ADA_ENCYCLOPEDIA_PATH", ROOT.parent / "ada_encyclopedia"))
SOURCES = ROOT / "doc" / "book" / "commons_sources.json"
REG_DIR = ROOT / "commons" / "artifacts" / "registry"
BASE_DIR = ROOT / "doc" / "book" / "baselines"
OUT_BOOK = ROOT / "doc" / "book" / "commons_ledger.json"
OUT_WEB = ENC / "public" / "commons-ledger.json"


def jload(p):
    return json.loads(Path(p).read_text(encoding="utf-8"))


def gd_path(scene: str) -> Path | None:
    if not scene.startswith("res://"):
        return None
    p = ROOT / scene[len("res://"):]
    gd = p.with_suffix(".gd")
    return gd if gd.exists() else None


def identity_text(gd: Path | None) -> str:
    """@identity essence + lineage + relationships lines — where the artifact
    names its own inheritance."""
    if gd is None or not gd.exists():
        return ""
    try:
        src = gd.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""
    out = []
    for key in ("essence", "lineage", "relationships", "truth", "critical"):
        m = re.search(r"#\s*%s:\s*(.+)" % key, src)
        if m:
            out.append(m.group(1))
    return " ".join(out)


def main():
    sources = jload(SOURCES)["sources"]

    # registry: lookup -> (description, name, scene)
    reg = {}
    for f in glob.glob(str(REG_DIR / "*.json")):
        try:
            d = jload(f)
        except Exception:
            continue
        for lk, m in (d.get("artifacts") or {}).items():
            if isinstance(m, dict):
                reg.setdefault(lk, (str(m.get("description", "")),
                                    str(m.get("name", "")), str(m.get("scene", ""))))

    # baseline voltage prose per cast piece (the book's own attribution layer)
    voltage_text = defaultdict(str)
    for f in glob.glob(str(BASE_DIR / "*.json")):
        if f.endswith(("_briefing.json", "thegame.json")):
            continue
        try:
            d = jload(f)
        except Exception:
            continue
        for v in d.get("voltage", []):
            voltage_text[v.get("piece", "")] += " " + str(v.get("why", ""))

    # match each artifact against each source
    per_artifact = {}
    per_source = defaultdict(list)
    for lk, (desc, name, scene) in reg.items():
        blob = " ".join([desc, name, voltage_text.get(lk, ""),
                         identity_text(gd_path(scene))])
        low = blob.lower()
        drawn = []
        for sid, s in sources.items():
            for term in s["match"]:
                if term.lower() in low:
                    drawn.append(sid)
                    per_source[sid].append(lk)
                    break
        if drawn:
            per_artifact[lk] = drawn

    # summary
    kind_counts = Counter()
    return_counts = Counter()
    for sid, arts in per_source.items():
        s = sources[sid]
        kind_counts[s["kind"]] += len(arts)
        return_counts[s["return"]] += len(arts)

    n_reg = len(reg)
    n_attributed = len(per_artifact)
    anon_sources = sorted(
        [(sid, len(per_source[sid]), sources[sid]) for sid in per_source
         if sources[sid]["return"] == "anonymous"],
        key=lambda x: -x[1])

    out = {
        "generated_by": "tools/build_commons_ledger.py",
        "question": "whose knowledge is this pressed from, and does the walk return it or enclose it?",
        "totals": {
            "registry_artifacts": n_reg,
            "attributed_artifacts": n_attributed,
            "unattributed_artifacts": n_reg - n_attributed,
            "sources_drawn_on": len([s for s in per_source if per_source[s]]),
            "by_kind": dict(kind_counts),
            "by_return": dict(return_counts),
        },
        "return_line": {
            "credited": return_counts.get("credited", 0),
            "commons": return_counts.get("commons", 0),
            "anonymous": return_counts.get("anonymous", 0),
            "reading": "credited = the walk names the source; commons = already common by nature; "
                       "anonymous = the form is used but its makers stay nameless — the debt this ledger surfaces",
        },
        # every taxonomy source appears, including zero-artifact ones — a
        # credited maker with no in-game artifact yet (e.g. paid via the
        # /pattern-atlas reproduction) is still part of the ledger's truth
        "sources": {sid: {**{k: sources[sid][k] for k in
                             ("kind", "tradition", "era", "pressed", "return")},
                          **({"credited_in": sources[sid]["credited_in"]}
                             if "credited_in" in sources[sid] else {}),
                          "artifacts": sorted(set(per_source.get(sid, []))),
                          "count": len(set(per_source.get(sid, [])))}
                    for sid in sorted(sources, key=lambda s: -len(set(per_source.get(s, []))))},
        "artifacts": {lk: sorted(set(v)) for lk, v in sorted(per_artifact.items())},
    }
    for path in (OUT_BOOK, OUT_WEB):
        path.write_text(json.dumps(out, ensure_ascii=False, indent=1), encoding="utf-8")

    print(f"commons ledger: {n_attributed}/{n_reg} artifacts attributed to "
          f"{out['totals']['sources_drawn_on']} sources")
    print(f"  by kind: {dict(kind_counts)}")
    print(f"  RETURN LINE — credited {return_counts.get('credited',0)} · "
          f"commons {return_counts.get('commons',0)} · "
          f"ANONYMOUS {return_counts.get('anonymous',0)}")
    print("  the anonymous debt (form used, makers unnamed):")
    for sid, n, s in anon_sources:
        print(f"    {n:3}  {sid}  [{s['tradition']}]")
    print(f"-> {OUT_BOOK}\n-> {OUT_WEB}")


if __name__ == "__main__":
    main()
