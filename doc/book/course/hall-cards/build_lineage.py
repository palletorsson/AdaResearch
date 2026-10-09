"""Validate and publish authored teaching choices. Does not select or edit lessons."""
from collections import Counter
from hashlib import sha256
from html import escape
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def main():
    spine = read(ROOT / "commons/maps/curriculum_spine.json")["spine"]["sequences"]
    sequences = []
    for entry in sorted(spine, key=lambda s: s["order"]):
        name = entry["name"]
        data = read(ROOT / "commons/maps/sequences" / (name + ".json"))["sequences"][name]
        sequences.append({"id": name, "title": data.get("name", name), "maps": data["maps"]})
    ordered = [m for s in sequences for m in s["maps"]]
    positions = {m: i for i, m in enumerate(ordered)}
    records = {}
    for name in ["lineage-opening.json", "lineage-middle.json", "lineage-later.json"]:
        for row in read(HERE / name)["halls"]:
            assert row["map"] not in records, f"Duplicate: {row['map']}"
            records[row["map"]] = row
    assert set(records) == set(ordered), {"missing": sorted(set(ordered) - records.keys()), "extra": sorted(records.keys() - set(ordered))}
    order_issues = []
    for map_id in ordered:
        row = records[map_id]
        assert 1 <= len(row["subjects"]) <= 5, map_id
        assert len(set(row["subjects"])) == len(row["subjects"]), map_id
        assert all(len(s) <= 120 for s in row["subjects"]), map_id
        assert row["status"] in ["aligned", "needs_revision", "missing"], map_id
        for prior in row["builds_on"]:
            assert prior["map"] in positions, (map_id, prior["map"])
            if positions[prior["map"]] >= positions[map_id]:
                order_issues.append({"map": map_id, "prior": prior["map"], "why": prior["why"]})
        tutorial = ROOT / "commons/maps" / map_id / "tutorial.md"
        if tutorial.exists():
            raw = tutorial.read_bytes()
            assert sha256(raw).hexdigest() == row["tutorial_sha256_after"], f"Source changed: {map_id}"
            text = raw.decode("utf-8-sig")
            assert "**Learning elements" in text[:900], f"Missing header: {map_id}"
            assert all("- " + s in text[:1800] for s in row["subjects"]), f"Labels differ: {map_id}"
        else:
            assert row["status"] == "missing" and row["tutorial_sha256_after"] is None, map_id
    states = read(HERE / "state.json")["cards"] if (HERE / "state.json").exists() else {}
    totals = Counter(row["status"] for row in records.values())
    md = ["# The tutorial lineage", "", "5 October 2026. A teaching route read against the current tutorials. Selected lessons are revised in the eight-interaction pass; the rest retain their review status. Learning-element lists select the teaching; they do not inventory the artifact's code.", "", f"{len(ordered)} halls · {len(sequences)} sequences · {totals['aligned']} focus/text matches · {totals['needs_revision']} need revision · {totals['missing']} tutorials missing.", "", "**Builds on → adds or deepens → carries forward.** Aligned means the focus is supported by the inspected text. It does not mean author approval, implemented museum transfer or demonstrated learner competence. Saved author decisions override these proposals.", "", "[Five revised halls, eight interaction topics: images and full lessons](../../iterations/2026-10-05-eight-interaction-lessons/index.html).", ""]
    sections = []
    for index, sequence in enumerate(sequences, 1):
        md.extend(["## " + sequence["title"], ""])
        cards = []
        counts = Counter(records[m]["status"] for m in sequence["maps"])
        for map_id in sequence["maps"]:
            row = records[map_id]
            choice = states.get(map_id, row)
            subjects = choice["subjects"]
            title = map_id.replace("_", " ")
            url = f"http://localhost:3003/tutorial-cards?map={map_id}"
            status = {"aligned": "Focus fits the text", "needs_revision": "Focus needs revision", "missing": "Tutorial missing"}[row["status"]]
            inherited = "; ".join(f"{b['map'].replace('_', ' ')}: {b['why']}" for b in row["builds_on"]) or "Prepared museum and supplied player"
            md.extend([f"### [{title}]({url})", "", " · ".join(subjects), "", f"- **Builds on:** {inherited}", f"- **Adds/deepens:** {row['adds']}", f"- **Carries:** {row['carries']}", f"- **Review:** {status}. {row['review']}", ""])
            subject_html = "".join(f"<li>{escape(s)}</li>" for s in subjects)
            prior_html = "; ".join(f"<a href='#{escape(b['map'])}'>{escape(b['map'].replace('_', ' '))}</a>: {escape(b['why'])}" for b in row["builds_on"]) or "Prepared museum and supplied player"
            note = f"<p class='review'>{escape(row['review'])}</p>" if row["review"] else ""
            tutorial = f"<a href='/book-review/commons/maps/{map_id}/tutorial.md'>Read tutorial.md ↗</a>" if row["status"] != "missing" else ""
            cards.append(f"<article id='{map_id}' class='{row['status']}'><header><h3><a href='{url}'>{escape(title)}</a></h3><span>{status}</span></header><ul class='subjects'>{subject_html}</ul><p class='focus'>{escape(choice['focus'])}</p><dl><dt>Builds on</dt><dd>{prior_html}</dd><dt>Adds / deepens</dt><dd>{escape(row['adds'])}</dd><dt>Carries forward</dt><dd>{escape(row['carries'])}</dd></dl>{note}<footer><a href='{url}'>Edit this hall's focus ↗</a>{tutorial}</footer></article>")
        sections.append(f"<section id='{sequence['id']}'><p class='number'>{index:02d} / {len(sequences)}</p><h2>{escape(sequence['title'])}</h2><p class='counts'>{counts['aligned']} focus/text matches · {counts['needs_revision']} to revise · {counts['missing']} missing</p>{''.join(cards)}</section>")
    nav = "".join(f"<li><a href='#{s['id']}'>{escape(s['title'])}</a></li>" for s in sequences)
    css = """*{box-sizing:border-box}html{scroll-padding-top:20px}body{margin:0;color:#293d34;background:#f4f2eb;font:15px/1.6 Arial,sans-serif}a{color:inherit;text-underline-offset:3px}nav{position:fixed;inset:0 auto 0 0;width:265px;overflow:auto;padding:28px 22px;background:#e9ece0;border-right:1px solid #ced5c5;font-size:12px}nav ol{padding-left:17px}nav li{margin:10px 0}main{margin-left:265px;padding:46px;max-width:1270px}h1,h2,h3{font-family:Georgia,serif;font-weight:400;line-height:1.2}h1{font-size:48px}h2{font-size:34px}h3{font-size:25px;margin:0}main>header{padding-bottom:30px;border-bottom:2px solid #293d34}.lead{max-width:65ch;font-size:18px}.number,.counts{font-size:11px;color:#6d766a}section{padding-top:48px}article{background:#fffdf7;border:1px solid #d4d9cd;border-radius:7px;margin:18px 0;padding:24px;scroll-margin-top:20px}article header{display:flex;justify-content:space-between;gap:20px}article header span{font-size:11px;color:#68765a}article.needs_revision header span,article.missing header span{color:#95572c}.subjects{display:flex;gap:8px;flex-wrap:wrap;list-style:none;padding:0}.subjects li{background:#f3e4e7;border:1px solid #dec4cf;border-radius:5px;padding:5px 10px;font-size:13px}.focus{font:18px/1.6 Georgia,serif}dl{display:grid;grid-template-columns:112px 1fr;gap:12px;font-size:13px}dt{font-weight:600}dd{margin:0}.review{border-left:2px solid #b4875e;padding:10px 13px;background:#f8f0e1;font-size:13px}footer{display:flex;gap:24px;font-size:11px}a:focus-visible{outline:2px solid #b26786;outline-offset:3px}@media(max-width:800px){nav{position:static;width:100%;max-height:200px}main{margin:0;padding:24px}h1{font-size:37px}article{padding:18px}article header{display:block}article header span{display:block;margin-top:8px}dl{grid-template-columns:1fr;gap:4px}dd{margin-bottom:10px}}"""
    html = f"<!doctype html><html lang='en'><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>Ada · The tutorial lineage</title><style>{css}</style><body><nav><a href='http://localhost:3003/tutorial-cards'>← Tutorial hall cards</a><h3>Across the museum</h3><ol>{nav}</ol></nav><main><header><p class='number'>ADA / TEACHING SELECTION / 5 OCTOBER 2026</p><h1>What can the learner carry onward?</h1><p class='lead'>One teaching focus per hall, connected to earlier work. The museum supplies more than each lesson needs to teach.</p><p>{len(ordered)} halls · {totals['aligned']} focus/text matches · {totals['needs_revision']} need revision · {totals['missing']} tutorials missing</p><p>This is a proposed lineage. A match with the text does not establish learner competence. The short lists select the learning. Five lessons now have a source-checked interaction revision; the remaining bodies stay open for review, one hall at a time.</p><a href='LINEAGE.md'>Markdown outline</a> · <a href='REVIEW.md'>Where to revise next</a></header>{''.join(sections)}</main></body></html>"
    (HERE / "LINEAGE.md").write_text("\n".join(md), encoding="utf-8")
    (HERE / "index.html").write_text(html, encoding="utf-8")
    result = {"date": "2026-10-05", "halls": len(ordered), "sequences": len(sequences), "statuses": dict(totals), "order_issues": order_issues, "tutorial_hashes_match": True, "header_labels_match": True, "source_scope": "Authored teaching selections checked against written lessons, not runtime or learner verification"}
    (HERE / "lineage-verification.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
