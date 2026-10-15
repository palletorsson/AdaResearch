"""Build portable full-chapter comparisons without adopting any chapter."""
from pathlib import Path
import hashlib
import html
import json
import re
import shutil
import zipfile

import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
BANK = "commons/maps/Random_Definition/composition/ideas.json"
ROUTE = ["random_touch", "random_number_book_page_1955", "geiger_counter", "seed_replay_demo/movement_sampler", "random_return"]
FORMS = {
    "a": ("Continuous observation", "Attention begins with marks after withdrawal and ends with a record the apparatus could make.", "Different operations of keeping may become too similar."),
    "b": ("Documentary montage", "Readouts, procedural descriptions and the dated receipt interrupt the present account.", "The registers may break the spatial continuity."),
    "c": ("Investigation", "A suspicion about the drawing becomes questions about selection, measurement and rules.", "Explanations may settle what could remain interesting."),
    "d": ("Temporal composition", "Different durations organize the sequence, including waiting and an acquisition date.", "Printed pacing may promise a sensation it cannot establish."),
    "e": ("Speculative constitution", "Clauses about permitted actions accumulate and need amendment as the body enters.", "The analogy may make the apparatus illustrate a predetermined argument."),
    "f": ("Composed candidate (after a reading of A-E)", "D's durations carry C's refining suspicion from stop to stop; A's unkept release point and B's receipt sentence are folded in; E's constitutional exit opens the door out.", "A composition of favourites may inherit three intentions without any single form's discipline, and its seams may show to a reader who knows the five."),
}
NOTE = "Composed candidate, not a field report. All candidates rehearse the same selected route. MOVE / KEEP is currently removed from the saved room; its restoration or a reviewed route revision is required before adoption as an installed walk."


def sha(data):
    return hashlib.sha256(data).hexdigest()


def md(text):
    return markdown.markdown(text, extensions=["tables", "fenced_code"])


def page(title, body, extra=""):
    styles = (HERE / "style.css").read_text(encoding="utf-8")
    return f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>{html.escape(title)} · Ada Research</title><style>{styles}</style></head><body><nav aria-label="Reading collection"><a href="index.html">Six readings</a><a href="compare.html">Compare two</a><a href="ideas.html">Keep an idea</a><a href="handoff.html">Handoff</a><a href="full-drafts-and-ideas.zip">Download all</a></nav>{body}{extra}</body></html>'''


def capture():
    previous = json.loads((HERE.parent / "2026-10-15-independent-writer/manifest.json").read_text(encoding="utf-8"))
    paths = [x["path"] for x in previous["sources"] if not x["path"].endswith(".png")]
    paths += [BANK] + [f"doc/book/iterations/2026-10-15-ink-wall/{name}" for name in ["README.md", "ink-test.log", "hand-test.log", "hall-seed-test.log"]]
    sources, drift = [], []
    for path in dict.fromkeys(paths):
        target = HERE / "inputs" / path
        if not target.exists():
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / path, target)
        digest = sha(target.read_bytes())
        sources.append({"path": path, "snapshot": target.relative_to(HERE).as_posix(), "sha256": digest})
        if sha((ROOT / path).read_bytes()) != digest:
            drift.append(path)
    return sources, drift


def main():
    sources, drift = capture()
    bank = json.loads((HERE / "inputs" / BANK).read_text(encoding="utf-8"))
    (HERE / "ideas.json").write_text(json.dumps(bank, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    records = []
    for key in FORMS:
        path = HERE / "drafts" / f"{key}.md"
        text = path.read_text(encoding="utf-8")
        assert re.findall(r"<!-- @([^ >]+) -->", text) == ROUTE, f"Route mismatch: {key}"
        plain = re.sub(r"<!--.*?-->", "", text, flags=re.S)
        plain = re.sub(r"\[([^]]+)\]\([^)]+\)", r"\1", plain)
        plain = "\n".join(plain.splitlines()[1:])
        count = len(re.findall(r"\b\w+(?:['’-]\w+)*\b", plain))
        assert 600 <= count <= 1500, (key, count)
        title = text.splitlines()[0].removeprefix("# ")
        rendered = md(text)
        records.append({"id": key, "title": title, "words": count, "sha256": sha(path.read_bytes()), "form": FORMS[key][0], "proposed_effect": FORMS[key][1], "risk": FORMS[key][2], "route": ROUTE, "body": rendered})
        method = f'<details><summary>Composition note · after reading</summary><p>{FORMS[key][0]}. {FORMS[key][1]}</p><p>Risk: {FORMS[key][2]}</p></details>'
        body = f'<main class="reading"><p class="eyebrow">Candidate {key.upper()} · {count} prose words · same situated author</p><p class="status">{NOTE}</p><article>{rendered}</article>{method}<p><a href="ideas.html?draft={key}">Retain a sentence, question or objection</a> · <a href="drafts/{key}.md">Markdown source</a></p></main>'
        (HERE / f"{key}.html").write_text(page(title, body), encoding="utf-8")

    cards = ''.join(f'<a class="card" href="{r["id"]}.html"><span class="eyebrow">{r["id"].upper()} · {r["words"]} words</span><h2>{html.escape(r["title"])}</h2><span>Read the complete text →</span></a>' for r in records)
    overview = '<main class="wide"><h1>Six ways through the same room</h1><p class="intro">Complete Random Definition candidates — five formal alternatives and one composed from a reading of them. Read one before opening its composition note. Keep a useful idea even when its chapter fails.</p><p class="status">'+NOTE+'</p><div class="cards">'+cards+'</div><p>The texts share one author, current apparatus and encounter order. These are exploratory alternatives, not independent judgements; F was composed after reading A-E and names its sources. No candidate has been adopted.</p><p><a href="compare.html">Compare complete texts side by side</a> · <a href="ideas.html">Read the 11 retained ideas or save a new note</a> · <a href="evidence.html">Check the apparatus</a></p></main>'
    (HERE / "index.html").write_text(page("Six ways through the same room", overview), encoding="utf-8")
    options = ''.join(f'<option value="{r["id"]}">{r["id"].upper()} · {html.escape(r["title"])}</option>' for r in records)
    compare = '<main class="comparison"><h1>Two complete readings</h1><p class="status">'+NOTE+'</p><div class="columns">'+''.join(f'<section><label for="{side}">{name}</label><select id="{side}">{options}</select><div class="scroll-text" id="{side}-text" tabindex="0" aria-label="{name} chapter"></div></section>' for side,name in [("left","Left reading"),("right","Right reading")])+'</div><p><a href="ideas.html">Keep an idea or reading response</a>. Each column scrolls independently. Record the order in which you read.</p></main>'
    data = json.dumps({r["id"]:{"body":r["body"],"words":r["words"]} for r in records}, ensure_ascii=False).replace("<", "\\u003c")
    js = '<script>const readings='+data+';function show(side){const id=document.getElementById(side).value;document.getElementById(side+"-text").innerHTML=readings[id].body;document.getElementById(side+"-text").scrollTop=0;}document.getElementById("right").value="b";["left","right"].forEach(side=>{document.getElementById(side).addEventListener("change",()=>show(side));show(side);});</script>'
    (HERE / "compare.html").write_text(page("Compare two full readings",compare,js),encoding="utf-8")

    idea_cards = ''.join(f'<details class="idea"><summary>{x["id"]} · {html.escape(x["title"])}</summary><p>{html.escape(x["idea"])}</p><p><strong>Status:</strong> {html.escape(x["status"])}</p><p><strong>Evidence:</strong> {html.escape(x["evidence"])}</p><p><strong>Risk:</strong> {html.escape(x["risk"])}</p><p><strong>Next test:</strong> {html.escape(x["next_test"])}</p><p>Used in: {", ".join(x["used_in"]).upper() or "calibration only"}</p></details>' for x in bank["ideas"])
    form = '''<section class="capture"><h2>Keep a new idea or response</h2><p>Notes are saved in this browser. Export them to hand over; they become repository ideas only after review.</p><form id="idea-form"><label for="origin">Source or draft</label><input id="origin" name="origin" placeholder="A, paragraph 3; or another encounter" required><label for="kind">Kind of note</label><select id="kind"><option>Idea to keep</option><option>Literary response</option><option>Technical question</option><option>Reason to reject</option></select><label for="quote">Exact sentence or observed detail</label><textarea id="quote" rows="3" required></textarea><label for="meaning">Why keep it, or what should change?</label><textarea id="meaning" rows="3" required></textarea><button type="submit">Save note in this browser</button></form><p id="save-status" role="status"></p><button type="button" id="export">Export notes as JSON</button><div id="saved-notes"></div></section>'''
    idea_body = '<main class="reading"><h1>Ideas can outlive their drafts</h1><p>Eleven retained ideas with provenance and limits. Reported attention, technical support and adoption are separate. The bank is a research record, not an argument every chapter must follow.</p>'+form+'<h2>Retained idea bank</h2>'+idea_cards+'<p><a href="ideas.json">Bank snapshot as JSON</a></p></main>'
    notes_script = '<script>' + (HERE / "notes.js").read_text(encoding="utf-8") + '</script>'
    (HERE / "ideas.html").write_text(page("Keep an idea",idea_body,notes_script),encoding="utf-8")
    for stem in ["handoff","evidence"]:
        text=(HERE/f"{stem}.md").read_text(encoding="utf-8")
        (HERE/f"{stem}.html").write_text(page(stem.capitalize(),'<main class="reading">'+md(text)+'<p><a href="full-drafts-and-ideas.zip">Full texts and ideas ZIP</a> · <a href="evidence-only.zip">Evidence-only ZIP for a fresh writer</a></p></main>'),encoding="utf-8")
    checks={"date":"2026-10-15","type":"author_preflight_not_reader_verdict","all_full_drafts":True,"route_matches_all":True,"range_words":[600,1500],"count_method":"Unicode word tokens; excludes title, artifact markers and link URLs; includes quoted documents and section labels.","drafts":[{k:v for k,v in r.items() if k!='body'} for r in records],"source_drift":drift,"reader_responses":[],"canonical_adoption":False,"technical_limits":["MOVE / KEEP placement unresolved","Composed accounts are not participant reports","No new headset session or independent reconstruction"],"author_factual_check":"Compared all five drafts with evidence.md and retained sources; public REPLAY-only abacus, hand/body distinction, seed/provenance, clock/event distinction and conditional collision claim retained."}
    (HERE/"verification.json").write_text(json.dumps(checks,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    full_files=["index.html","compare.html","ideas.html","ideas.json","notes.js","style.css","handoff.html","handoff.md","evidence.html","evidence.md","README.md","verification.json"]+[f"{k}.html" for k in FORMS]+[f"drafts/{k}.md" for k in FORMS]
    # Normal files inside each archive; no dependency on the localhost server.
    for archive_name,names in [("full-drafts-and-ideas.zip",full_files),("evidence-only.zip",["evidence.md","fresh-writer-brief.md"])]:
        with zipfile.ZipFile(HERE/archive_name,"w",zipfile.ZIP_DEFLATED) as archive:
            for name in names:archive.write(HERE/name,name)
    manifest={"schema":"ada-five-readings/1","date":"2026-10-15","sources":sources,"source_drift":drift,"outputs":[{"path":name,"sha256":sha((HERE/name).read_bytes())} for name in full_files+["full-drafts-and-ideas.zip","evidence-only.zip"]]}
    (HERE/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"words":{r["id"]:r["words"] for r in records},"route":"PASS","ideas":len(bank["ideas"]),"source_drift":drift}))


if __name__=="__main__":main()
