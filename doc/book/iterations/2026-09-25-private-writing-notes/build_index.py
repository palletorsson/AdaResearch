"""Render editable private notes and report coverage; never generate their prose."""
from pathlib import Path
from collections import Counter
from datetime import datetime, timezone
import hashlib
import html
import json
import re
from urllib.parse import quote
import markdown
from prepare_sources import collect

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "commons/maps/curriculum_spine.json").exists())
FIELDS = ("Desire.", "Route / writing move.", "Encounter to lean on.",
          "Explain / linger.", "Rhythm beside its neighbors.")

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None

def main():
    baseline = json.loads((HERE / "sources.json").read_text(encoding="utf-8"))
    current = collect()
    former = {h["id"]: h for s in baseline["sequences"] for h in s["halls"]}
    halls = [(s, h) for s in current["sequences"] for h in s["halls"]]
    ids = [h["id"] for _, h in halls]
    report = {"checked_at": datetime.now(timezone.utc).isoformat(),
              "sequence_count": len(current["sequences"]), "hall_count": len(halls),
              "notes_present": 0, "missing": [], "format_issues": [],
              "grounding_issues": [], "source_changes_since_reading_baseline": [],
              "new_halls": sorted(set(ids) - set(former)),
              "removed_halls": sorted(set(former) - set(ids)),
              "duplicate_spine_halls": [k for k, n in Counter(ids).items() if n > 1],
              "extra_notes": sorted(p.stem for p in (HERE / "halls").glob("*.md") if p.stem not in ids),
              "notes": []}
    sequence_changed = {s["id"] for s in current["sequences"]
                        if next((old["source"]["sha256"] for old in baseline["sequences"]
                                 if old["id"] == s["id"]), None) != s["source"]["sha256"]}
    sections = []
    nav = []
    for seq in current["sequences"]:
        articles = []
        nav.append(f'<a href="#seq-{html.escape(seq["id"])}">{html.escape(seq["name"])} ({len(seq["halls"])})</a>')
        for h in seq["halls"]:
            name = h["id"]
            path = HERE / h["note"]
            if not path.exists():
                report["missing"].append(name)
                continue
            text = path.read_text(encoding="utf-8-sig")
            report["notes_present"] += 1
            if not text.startswith(f"# {name}\n"):
                report["format_issues"].append({"hall": name, "problem": "Map heading differs"})
            for field in FIELDS:
                if f"**{field}**" not in text:
                    report["format_issues"].append({"hall": name, "problem": f"Missing {field}"})
            source = ROOT / h["manuscript"]["path"]
            manuscript = source.read_text(encoding="utf-8-sig") if source.exists() else ""
            quotations = [a or b for a, b in re.findall(r'“([^”\n]{8,})”|"([^"\n]{8,})"', text)]
            exact = [q for q in quotations if q in manuscript]
            mentioned = [a for a in h["anchors"] if a and a in text]
            if manuscript and not exact:
                report["grounding_issues"].append({"hall": name, "problem": "No exact quoted manuscript phrase found"})
            if any(h["anchors"]) and not mentioned:
                report["grounding_issues"].append({"hall": name, "problem": "No manuscript anchor named"})
            changed = [kind for kind in ("manuscript", "map")
                       if h[kind]["sha256"] != former.get(name, {}).get(kind, {}).get("sha256")]
            if seq["id"] in sequence_changed:
                changed.append("sequence")
            if changed:
                report["source_changes_since_reading_baseline"].append({"hall": name, "changed": changed})
            report["notes"].append({"hall": name, "sequence": seq["id"], "path": h["note"],
                                    "sha256": digest(path), "words": len(text.split()),
                                    "matched_quotes": exact, "named_anchors": mentioned})
            i = ids.index(name)
            neighbors = []
            if i > 0:
                neighbors.append(f'<a href="#{ids[i-1]}">← {ids[i-1]}</a>')
            if i + 1 < len(ids):
                neighbors.append(f'<a href="#{ids[i+1]}">{ids[i+1]} →</a>')
            status = ('<p class="changed">Source changed since the reading baseline: '
                      + html.escape(", ".join(changed)) + '. Reconcile before revising.</p>') if changed else ""
            body = markdown.markdown(re.sub(r"^# [^\n]+\n", "", text, count=1), extensions=["tables"])
            links = (f'<a href="halls/{quote(name)}.md">Note Markdown</a>'
                     f'<a href="/compose/sources?map={quote(name)}&amp;doc=final">Read manuscript</a>'
                     f'<a href="/long-museum/encounters?map={quote(name)}">Encounter map</a>')
            articles.append(f'<article id="{name}" data-sequence="{seq["id"]}"><h3>{html.escape(name)}</h3>'
                            f'<nav>{links}</nav>{status}{body}<div class="neighbors">{" · ".join(neighbors)}</div></article>')
        sections.append(f'<section id="seq-{seq["id"]}"><h2>{html.escape(seq["name"])}</h2>{"".join(articles)}</section>')
    report["coverage_complete"] = not (report["missing"] or report["duplicate_spine_halls"] or report["extra_notes"])
    report["editorial_checks_pass"] = report["coverage_complete"] and not (report["format_issues"] or report["grounding_issues"])
    (HERE / "coverage.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    css = '''*{box-sizing:border-box}body{margin:0;background:#f5f2eb;color:#28312e;font:18px/1.75 Georgia,serif}header,main,footer{max-width:940px;margin:auto;padding:28px}h1{font-size:46px;line-height:1.15;font-weight:normal}h2{margin:55px 0 20px;font-size:26px}h3{font:20px/1.4 system-ui;overflow-wrap:anywhere}a{color:#24614d;text-underline-offset:3px}nav,.meta,.neighbors,select,input,label,footer{font:14px/1.6 system-ui}nav{display:flex;gap:16px;flex-wrap:wrap}article{background:#fffdf8;border:1px solid #d9ddd3;border-radius:8px;padding:24px;margin:20px 0;scroll-margin-top:12px}article p{margin:16px 0}code{font-size:.85em;overflow-wrap:anywhere}.filters{display:flex;gap:18px;flex-wrap:wrap;padding:18px 0}label{display:flex;flex-direction:column;gap:5px}input,select{padding:10px;border:1px solid #aebdb4;border-radius:4px;background:white;max-width:100%}input{min-width:260px}.changed{padding:10px;background:#fff0c7;font:14px/1.6 system-ui}.neighbors{border-top:1px solid #d9ddd3;padding-top:12px;overflow-wrap:anywhere}.toc{columns:2;font:14px/1.7 system-ui}.toc a{display:block}.top{position:fixed;right:14px;bottom:14px;background:#fffdf8;padding:8px 12px;border:1px solid #ccc;font:14px system-ui}[hidden]{display:none!important}@media(max-width:600px){h1{font-size:35px}.toc{columns:1}header,main,footer{padding:18px}article{padding:18px}}@media print{.filters,.top{display:none}article{break-inside:avoid}body{font-size:12pt;background:white}}'''
    toc = ''.join(f'<a href="#{h["id"]}">{i+1:03d} · {html.escape(h["id"])}</a>' for i, (_, h) in enumerate(halls))
    combined = ["# Ada Research - private encounter notes", "", "Editorial working notes, not book copy. See README.md for the working agreement.", ""]
    for seq in current["sequences"]:
        combined.extend([f"## {seq['name']}", ""])
        for h in seq["halls"]:
            note = HERE / h["note"]
            if note.exists():
                combined.extend([re.sub(r"^# ", "### ", note.read_text(encoding="utf-8-sig"), count=1), ""])
    (HERE / "all-notes.md").write_text("\n".join(combined), encoding="utf-8", newline="\n")
    page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Ada Research - private encounter notes</title><style>{css}</style></head><body><header id="top"><p class="meta">Ada Research - editorial working notes - begun 25 September 2026</p><h1>Ways through the halls</h1><p>{report['notes_present']} private writing notes across {report['sequence_count']} sequences. Each proposes a route through an encounter: a desire, a discovery, a place to linger. Read it beside the current manuscript and change it when the space suggests something better.</p><p class="meta">Proposals grounded in manuscript and authored map inspection. They are not book copy or runtime acceptance. Private means editorial; this page has no access control.</p><nav><a href="README.md">Working agreement</a><a href="all-notes.md">All notes as Markdown</a><a href="sources.json">Reading baseline</a><a href="coverage.json">Coverage and freshness</a></nav><p class="meta">Use your browser's Find (Ctrl+F) for a hall, artifact or writing move. Choose a sequence below, or open the full list of halls.</p><nav class="toc">{''.join(nav)}</nav><details><summary>All halls in spine order</summary><nav class="toc">{toc}</nav></details></header><main>{''.join(sections)}</main><footer>Edit the individual Markdown note, then run build_index.py to refresh this view. Manuscripts and maps remain the independent source of their encounters.</footer><a class="top" href="#top">Top</a></body></html>'''
    (HERE / "index.html").write_text(page, encoding="utf-8", newline="\n")
    print(json.dumps({k: report[k] for k in ["sequence_count", "hall_count", "notes_present", "coverage_complete", "editorial_checks_pass"]}))
    for key in ["missing", "format_issues", "grounding_issues", "source_changes_since_reading_baseline", "new_halls", "extra_notes"]:
        if report[key]:
            print(key, json.dumps(report[key], ensure_ascii=False))

if __name__ == "__main__":
    main()
