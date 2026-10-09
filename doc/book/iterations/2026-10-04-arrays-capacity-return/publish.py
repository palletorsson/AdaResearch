"""Publish a script-free before/after review of the five Arrays teaching plans.

Writes only index.html and README.md beside this file. Canonical plans, the
saved before snapshot, museum captures, runtime files and manuscripts are read-only.
"""
from __future__ import annotations

import hashlib
import html
import json
import re
from pathlib import Path, PurePosixPath
from urllib.parse import quote


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
CURRENT = ROOT / "doc/book/course/storyboards/early.json"
BEFORE = HERE / "before/doc/book/course/storyboards/early.json"
CAPTURES = ROOT / "doc/book/iterations/2026-10-04-museum-tutorial-storyboards/route.json"
DATE = "2026-10-04"
CAPTURE_OVERRIDES = {
    "Tutorial_Tiling_Floor": {
        "src": "../2026-09-28-tiling-rule-study/floor-rule-after.png",
        "date": "2026-09-28",
        "label": "Standing view of the existing 4×4 rule-study controls",
        "note": "The BEFORE / AFTER labels inside this photograph belong to the existing rule demonstration, not to today's summary revision.",
        "evidence": ["../2026-09-28-tiling-rule-study/floor-source_manifest.json", "../2026-09-28-tiling-rule-study/floor-report.json"],
        "width": 1800,
        "height": 1200,
    },
    "Tutorial_Tiling_Walls": {
        "src": "../2026-09-28-tiling-rule-study/wall-eye-chart.png",
        "date": "2026-09-28",
        "label": "Standing view of the existing rule eye chart",
        "evidence": ["../2026-09-28-tiling-rule-study/wall-source_manifest.json"],
        "width": 1800,
        "height": 1200,
    },
}
STAGES = [
    ("Array", "Address"),
    ("Tutorial_3D", "Depth"),
    ("Tutorial_Tiling_Floor", "Rule"),
    ("Tutorial_Tiling_Walls", "Surface"),
    ("Tutorial_Disco", "Score"),
]
LEARNING_FIELDS = [
    ("brings", "Bring from earlier encounters"),
    ("learns", "Develop here"),
    ("supplied", "Supplied for the learner"),
    ("carries", "Carry forward"),
]


def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


def text(value: object) -> str:
    if value is None:
        return ""
    if isinstance(value, list):
        return "; ".join(text(item) for item in value)
    if isinstance(value, dict):
        return "; ".join(f"{key}: {text(item)}" for key, item in value.items())
    return str(value)


def inline(value: object) -> str:
    parts = re.split(r"(`[^`\n]+`)", text(value))
    return "".join(f"<code>{esc(part[1:-1])}</code>" if part.startswith("`") and part.endswith("`") else esc(part) for part in parts)


def paragraphs(value: object) -> str:
    return "".join(f"<p>{inline(part)}</p>" for part in text(value).split("\n\n") if part.strip())


def items(value: object) -> str:
    if not value:
        return '<p class="muted">No field supplied.</p>'
    values = value if isinstance(value, list) else [value]
    return "<ul>" + "".join(f"<li>{inline(item)}</li>" for item in values) + "</ul>"


def memory(scope: str) -> str:
    return "/project-memory?scope=" + quote(scope, safe="")


def get_sequence(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    sequence = next(item for item in data if item["sequence"] == "array_tutorial")
    if [hall["id"] for hall in sequence["halls"]] != [item[0] for item in STAGES]:
        raise ValueError(f"Five-hall order changed in {path}; review stage labels before publishing.")
    return sequence


def prior_maps(values: list) -> str:
    result = []
    for item in values:
        if isinstance(item, dict):
            map_id = str(item.get("id", item.get("map", item.get("map_id", ""))))
            label = str(item.get("title", map_id))
            note = item.get("purpose", item.get("contribution", item.get("note", "")))
        else:
            map_id, label, note = str(item), str(item), ""
        link = f'<a href="{esc(memory("map:" + map_id))}">{esc(label)}</a>' if re.fullmatch(r"[A-Za-z0-9_]+", map_id) else inline(label)
        result.append(f"<li>{link}{' — ' + inline(note) if note else ''}</li>")
    return "<ul>" + "".join(result) + "</ul>"


def source_list(values: list) -> str:
    result = []
    for item in values:
        if isinstance(item, dict):
            path = item.get("path", item.get("source", ""))
            note = item.get("purpose", item.get("note", item.get("role", "")))
        else:
            path, note = item, ""
        result.append(f"<li><code>{esc(path)}</code>{'<span>' + inline(note) + '</span>' if note else ''}</li>")
    return '<ul class="sources">' + "".join(result) + "</ul>"


def capture_html(capture: dict, index: int) -> str:
    if capture["id"] in CAPTURE_OVERRIDES:
        photo = CAPTURE_OVERRIDES[capture["id"]]
        src = photo["src"]
        for relative in [src, *photo.get("evidence", [])]:
            path = (HERE / relative).resolve()
            if not path.is_relative_to(ROOT / "doc/book/iterations") or not path.is_file():
                raise ValueError(f"Invalid review capture or evidence path: {relative}")
    else:
        photos = capture.get("images", [])
        if not photos:
            raise ValueError(f"No capture for {capture['id']}")
        photo = photos[0]
        path = PurePosixPath(photo["src"])
        if path.is_absolute() or ".." in path.parts or not (CAPTURES.parent / str(path)).is_file():
            raise ValueError(f"Invalid capture path: {path}")
        src = "../2026-10-04-museum-tutorial-storyboards/" + str(path)
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", photo.get("date", "")):
        raise ValueError(f"Missing original capture date for {capture['id']}")
    note = "<br>" + esc(photo["note"]) if photo.get("note") else ""
    evidence = photo.get("evidence", [])
    evidence_links = '<br>Capture evidence: ' + ' · '.join(f'<a href="{esc(item)}">{esc(PurePosixPath(item).name)}</a>' for item in evidence) if isinstance(evidence, list) and evidence else ""
    return f'''<figure><a class="image-link" href="{esc(src)}" aria-label="Open prior museum capture of {esc(capture['id'])}"><img src="{esc(src)}" alt="Prior Endless Museum capture: {esc(photo.get('label', capture['id']))}" width="{photo.get('width', 1280)}" height="{photo.get('height', 720)}" loading="{'eager' if index == 1 else 'lazy'}"></a><figcaption><strong>Prior museum capture · <time datetime="{photo['date']}">{photo['date']}</time></strong><br>{esc(photo.get('label', 'Museum encounter'))}. The same existing exhibit supports both texts. This is not a capture of a newly implemented lesson.{note}{evidence_links}</figcaption></figure>'''


def changes(before: dict, after: dict) -> str:
    labels = [("title", "Title"), ("storyboard", "Full summary"), ("storyboard_short", "Compact summary"), ("brings", "Prior capacity"), ("learns", "Learning aim"), ("supplied", "Supplied support"), ("carries", "Reusable result"), ("review_note", "Review note")]
    changed = [label for key, label in labels if before.get(key) != after.get(key)]
    return '<ul class="change-tags" aria-label="Revised fields">' + "".join(f"<li>{esc(label)}</li>" for label in changed) + "</ul>"


def compare(before: object, after: object, title_before: str = "", title_after: str = "", extra: str = "") -> str:
    return f'''<div class="comparison {extra}"><section class="before"><p class="label">Before · saved plan</p>{'<h3>' + esc(title_before) + '</h3>' if title_before else ''}{paragraphs(before)}</section><section class="after"><p class="label">After · revised proposal</p>{'<h3>' + esc(title_after) + '</h3>' if title_after else ''}{paragraphs(after)}</section></div>'''


def hall_html(before: dict, after: dict, capture: dict, index: int, stage: str) -> str:
    map_id = after["id"]
    contract = "".join(f'<div class="field"><h4>{esc(label)}</h4><div class="comparison"><section class="before"><p class="label">Before</p>{items(before.get(key))}</section><section class="after"><p class="label">After</p>{items(after.get(key))}</section></div></div>' for key, label in LEARNING_FIELDS)
    contradiction = '''<aside class="contradiction"><strong>Open contradiction · full tutorial still awaits rewrite</strong><p><code>commons/maps/Tutorial_Disco/tutorial.md</code> describes a footstep-recording floor. The current encounter has separate floor and score clocks. This update changes the teaching summary; it neither rewrites that tutorial nor implements footstep recording.</p></aside>''' if map_id == "Tutorial_Disco" else ""
    return f'''<article class="hall" id="{stage.lower()}" aria-labelledby="title-{esc(map_id)}">
<header class="hall-header"><div><p class="eyebrow">{index:02d} / {esc(stage)}</p><h2 id="title-{esc(map_id)}">{esc(after['title'])}</h2><p class="map-id">{esc(map_id)}</p></div><a class="hall-memory" href="{esc(memory('map:' + map_id))}">Open hall in memory ↗</a></header>
<div class="context-row">{capture_html(capture, index)}<div class="change-reason"><p class="eyebrow">Why this selection changed</p>{paragraphs(after['change_reason'])}{changes(before, after)}<p class="scope-note">These labels identify changes to the written plan. Existing geometry, controls and runtime logic are unchanged.</p></div></div>
<div class="full-text"><h3 class="section-label">The complete summary, before and after</h3>{compare(before['storyboard'], after['storyboard'], before['title'], after['title'], 'full-summary')}</div>
<div class="checks"><section><p class="eyebrow">Try it independently</p>{paragraphs(after['independent_check'])}</section><section><p class="eyebrow">A question to keep open</p>{paragraphs(after['critical_question'])}</section></div>
{contradiction}
<div class="details-stack"><details><summary>Compact summaries · before &amp; after</summary><div class="details-content">{compare(before['storyboard_short'], after['storyboard_short'])}</div></details>
<details><summary>What comes in, what develops, what carries forward</summary><div class="details-content">{contract}</div></details>
<details><summary>Earlier halls, exact sources &amp; remaining work</summary><div class="details-content"><div class="sources-grid"><section><h3>Earlier encounters</h3>{prior_maps(after['prior_maps'])}<h3>Remaining work and evidence limits</h3>{paragraphs(after['review_note'])}<p class="muted">Sources support a teaching proposal. An independent check is a proposed task, not a recorded learner result. Prior captures establish the visual context, not completion of a lesson adapter.</p></section><section><h3>Existing source paths</h3><p class="muted">Exact repository paths for inspection; no runtime sources were changed by this review.</p>{source_list(after['source_refs'])}</section></div></div></details></div></article>'''


CSS = """
:root{--paper:#f5f3ed;--card:#fffefb;--ink:#28332e;--muted:#64706a;--line:#d7ddd3;--green:#315a49;--soft:#edf2e9;--rose:#884763;--pink:#f4e8ed;--old:#f1eee8}*{box-sizing:border-box}html{scroll-padding-top:85px}body{margin:0;background:var(--paper);color:var(--ink);font:16px/1.65 system-ui,-apple-system,'Segoe UI',sans-serif}a{color:var(--green);text-underline-offset:.2em}a:hover{text-decoration-thickness:2px}a:focus-visible,summary:focus-visible{outline:3px solid var(--rose);outline-offset:5px}p{margin:0 0 1em}p:last-child{margin-bottom:0}h1,h2,h3,h4{margin:0;font-weight:550;line-height:1.16}h1,h2{font-family:Georgia,'Times New Roman',serif}h1{font-size:clamp(42px,6vw,78px);letter-spacing:-.045em;max-width:850px}h2{font-size:clamp(28px,3.5vw,40px);letter-spacing:-.03em}h3{font-size:16px;margin-bottom:12px}h4{font-size:14px;margin:0 0 12px}code{font:.86em/1.6 ui-monospace,Consolas,monospace;overflow-wrap:anywhere}ul{padding-left:1.2em;margin:0 0 1em}li+li{margin-top:.35em}.container{max-width:1260px;padding:0 36px;margin:auto}.skip{position:absolute;top:-100px;left:15px;background:var(--card);padding:10px;z-index:10}.skip:focus{top:10px}.topbar{border-bottom:1px solid var(--line);padding:16px 0}.topbar .container{display:flex;justify-content:space-between;gap:25px;align-items:center}.brand{font-size:20px;font-weight:750;letter-spacing:-.04em;text-decoration:none}.top-links{display:flex;gap:24px;font-size:13px;flex-wrap:wrap}.hero{padding-top:50px;padding-bottom:33px}.eyebrow,.label,.section-label{font:700 11px/1.5 system-ui,sans-serif;text-transform:uppercase;letter-spacing:.12em}.eyebrow{color:var(--green);margin-bottom:13px}.deck{font:21px/1.55 Georgia,serif;max-width:850px;margin:24px 0}.status{border-left:3px solid var(--rose);background:var(--pink);padding:15px 20px;max-width:1000px;font-size:14px}.status strong{display:block;color:#67314b}.arc{margin-top:30px}.arc>h2{font:700 12px/1.5 system-ui,sans-serif;text-transform:uppercase;letter-spacing:.12em;margin-bottom:13px}.comparison{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:0;border:1px solid var(--line);border-radius:2px;overflow:hidden}.comparison>section{padding:22px 24px;min-width:0}.before{background:var(--old)}.after{background:var(--soft)}.comparison>.before{border-right:1px solid var(--line)}.label{color:var(--muted);margin-bottom:12px}.after>.label{color:var(--green)}.arc .comparison{font-size:14px}.route-nav{position:sticky;top:0;z-index:3;background:#f5f3edf8;backdrop-filter:blur(10px);border-block:1px solid var(--line)}.route-nav ol{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));list-style:none;margin:0;padding:0}.route-nav li{margin:0;border-right:1px solid var(--line)}.route-nav li:first-child{border-left:1px solid var(--line)}.route-nav a{display:flex;gap:12px;padding:15px 18px;font-size:14px;font-weight:650;text-decoration:none}.route-nav a:hover{background:var(--soft)}.route-nav span{font-size:12px;font-weight:400;color:var(--muted)}main{padding-top:32px;padding-bottom:14px}.hall{border:1px solid var(--line);border-radius:3px;background:var(--card);margin-bottom:32px;scroll-margin-top:85px}.hall:target{outline:2px solid var(--green);outline-offset:4px}.hall-header{padding:25px 29px 22px;display:flex;justify-content:space-between;align-items:flex-start;gap:25px;border-bottom:1px solid var(--line)}.hall-header .eyebrow{margin-bottom:9px}.map-id{font:11px/1.5 ui-monospace,Consolas,monospace;color:var(--muted);margin-top:11px;overflow-wrap:anywhere}.hall-memory{font-size:12px;white-space:nowrap;margin-top:4px}.context-row{display:grid;grid-template-columns:minmax(0,1.05fr) minmax(0,1fr);gap:28px;padding:26px 29px}.context-row figure{margin:0;align-self:start}.image-link{display:block;background:#25362d;border:1px solid #c9d0c5}img{display:block;width:100%;height:auto;aspect-ratio:16/9;object-fit:contain}figcaption{font-size:12px;line-height:1.55;color:var(--muted);margin-top:10px}figcaption strong{font-weight:600;color:var(--ink)}.change-reason{font-size:15px;align-self:center}.change-reason>.eyebrow{color:var(--rose)}.change-tags{list-style:none;margin:17px 0 12px;padding:0;display:flex;gap:6px;flex-wrap:wrap}.change-tags li{font-size:10px;line-height:1.6;margin:0;padding:3px 7px;border:1px solid #cbd7c5;background:var(--soft);border-radius:3px;color:var(--green)}.scope-note,.muted{font-size:12px;color:var(--muted)}.full-text{padding:0 29px 25px}.section-label{margin:0 0 12px;color:var(--muted)}.full-summary{font:18px/1.7 Georgia,serif}.full-summary h3{font:650 14px/1.4 system-ui,sans-serif;color:var(--ink);margin-bottom:15px}.checks{display:grid;grid-template-columns:1fr 1fr;gap:26px;margin:0 29px 24px;padding:18px 0;border-top:1px solid var(--line);border-bottom:1px solid var(--line);font-size:14px}.checks .eyebrow{margin-bottom:7px}.checks section+section{border-left:1px solid var(--line);padding-left:26px}.checks section+section .eyebrow{color:var(--rose)}.contradiction{margin:0 29px 25px;border:1px solid #d9bccb;background:var(--pink);padding:16px 18px;font-size:14px}.contradiction strong{color:#713950;display:block;margin-bottom:6px}.details-stack{padding:0 29px 20px}.details-stack details{border-top:1px solid var(--line)}summary{cursor:pointer;padding:14px 0;font-size:14px;font-weight:650;list-style-position:outside;margin-left:17px}summary::marker{color:var(--green)}.details-content{padding:0 0 22px;font-size:14px}.details-content .comparison>section{padding:17px 19px}.field+.field{margin-top:20px}.field ul{margin:0}.sources-grid{display:grid;grid-template-columns:1fr 1fr;gap:28px}.sources-grid h3{margin-top:16px;font-size:14px}.sources-grid h3:first-child{margin-top:0}.sources{list-style:none;padding:0}.sources li{padding:7px 0;border-bottom:1px solid var(--line)}.sources code{font-size:12px}.sources span{display:block;font-size:12px;color:var(--muted)}.footer{border-top:1px solid var(--line);padding:27px 0 38px;font-size:13px;color:var(--muted)}.footer-links{display:flex;gap:22px;flex-wrap:wrap;margin-bottom:18px}.footer p{max-width:920px}.provenance{font-size:11px;overflow-wrap:anywhere}
@media(min-width:1500px){.container{max-width:1380px}.full-summary{font-size:19px}}
@media(max-width:900px){.container{padding:0 23px}.context-row{grid-template-columns:1fr}.context-row figure{max-width:750px}.change-reason{max-width:760px}.route-nav a{padding:13px 10px;gap:8px}.comparison>section{padding:18px}.full-summary{font-size:17px}.hero{padding-top:35px}}
@media(max-width:650px){html{scroll-padding-top:75px}.container{padding:0 15px}.topbar .container{align-items:flex-start}.top-links{justify-content:flex-end;gap:8px 14px;font-size:12px}.hero{padding-top:28px}.deck{font-size:19px}.comparison,.checks,.sources-grid{grid-template-columns:1fr}.comparison>.before{border-right:0;border-bottom:1px solid var(--line)}.route-nav a{display:block;padding:11px 6px;font-size:11px;text-align:center}.route-nav span{display:block;font-size:10px}.hall-header{display:block;padding:22px 18px 19px}.hall-memory{display:inline-block;margin-top:12px}.context-row{padding:20px 18px;gap:20px}.full-text{padding:0 18px 21px}.full-summary{font-size:18px}.checks{margin:0 18px 21px;gap:16px}.checks section+section{border-left:0;border-top:1px solid var(--line);padding:16px 0 0}.contradiction{margin:0 18px 21px}.details-stack{padding:0 18px 18px}.sources-grid{gap:16px}.hall{scroll-margin-top:82px}.status{padding:13px 15px}}
@media(prefers-reduced-motion:no-preference){html{scroll-behavior:smooth}}
@media print{.topbar,.route-nav,.hall-memory,.skip{display:none}.container{padding:0;max-width:none}.hero{padding-top:0}.hall{break-inside:avoid}.full-summary{font-size:11pt}.context-row{grid-template-columns:1fr 1fr}.comparison{grid-template-columns:1fr 1fr}.comparison>.before{border-right:1px solid var(--line);border-bottom:0}h1{font-size:36pt}h2{font-size:23pt}a{color:inherit}}
"""


def publish() -> None:
    before, after = get_sequence(BEFORE), get_sequence(CURRENT)
    required = ["storyboard", "storyboard_short", "change_reason", "independent_check", "critical_question", "prior_maps", "source_refs", "review_note"]
    for hall in after["halls"]:
        missing = [key for key in required if key not in hall or hall[key] is None]
        if missing:
            raise ValueError(f"Revised teaching data not ready for {hall['id']}: {', '.join(missing)}")
    route = json.loads(CAPTURES.read_text(encoding="utf-8-sig"))
    capture_by_id = {hall["id"]: hall for hall in route["halls"]}
    nav = "".join(f'<li><a href="#{stage.lower()}"><span>{index:02d}</span>{esc(stage)}</a></li>' for index, (_, stage) in enumerate(STAGES, 1))
    halls = "\n".join(hall_html(old, new, capture_by_id[new["id"]], index, STAGES[index - 1][1]) for index, (old, new) in enumerate(zip(before["halls"], after["halls"]), 1))
    before_hash = hashlib.sha256(BEFORE.read_bytes()).hexdigest()
    after_hash = hashlib.sha256(CURRENT.read_bytes()).hexdigest()
    route_hash = hashlib.sha256(CAPTURES.read_bytes()).hexdigest()
    report_link = '<a href="REPORT.md">Read the editorial report</a>' if (HERE / "REPORT.md").is_file() else ""
    diff_link = '<a href="summaries.diff">Exact summary diff</a>' if (HERE / "summaries.diff").is_file() else ""
    memory_link = f'<a href="{esc(memory("sequence:array_tutorial"))}">Project memory ↗</a>'
    page = f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="color-scheme" content="light"><meta name="description" content="Before and after teaching plans for Ada's five Arrays halls, alongside dated images of the existing Endless Museum."><title>Ada · Arrays, capacity carried forward</title><style>{CSS}</style></head>
<body id="top"><a class="skip" href="#review">Skip to the five comparisons</a><div class="topbar"><div class="container"><a class="brand" href="{esc(memory('sequence:array_tutorial'))}">Ada / Arrays</a><div class="top-links">{report_link}{diff_link}{memory_link}</div></div></div>
<header class="hero container"><p class="eyebrow">Before / after review · {DATE} · Five existing halls</p><h1>Keep the address.<br>Carry the capability.</h1><p class="deck">From an indexed arrangement to a rule, a surface and a score. This review compares the saved teaching plans with their revised proposals, beside images of the existing museum encounters.</p><div class="status"><strong>Summary metadata updated. Implementation remains unchanged.</strong>Full tutorials, final manuscripts, artifacts, room geometry and runtime logic are outside this change. Images are dated prior captures, shared by both versions. The Disco tutorial contradiction remains open pending a full rewrite.</div><section class="arc" aria-labelledby="arc-heading"><h2 id="arc-heading">The sequence arc</h2>{compare(before['arc'], after['arc'])}</section></header>
<nav class="route-nav" aria-label="Five Arrays encounters"><div class="container"><ol>{nav}</ol></div></nav><main id="review" class="container">{halls}</main>
<footer class="footer"><div class="container"><div class="footer-links">{report_link}{diff_link}{memory_link}<a href="before/doc/book/course/storyboards/early.json">Saved before text</a><a href="#top">Back to top ↑</a></div><p>The route stays open to change. These comparisons make the revised selection and its reasons reviewable; they do not prescribe a new room order or claim that a learner has already acquired the proposed capacity. Keep alternative selections, questions and reasons in project memory.</p><p class="provenance">Canonical source: <code>doc/book/course/storyboards/early.json</code><br>Saved before SHA-256 <code>{before_hash[:16]}</code> · After SHA-256 <code>{after_hash[:16]}</code><br>Prior capture metadata: <code>doc/book/iterations/2026-10-04-museum-tutorial-storyboards/route.json</code>. No new capture or runtime test is implied.</p></div></footer></body></html>'''
    (HERE / "index.html").write_text(page, encoding="utf-8")
    report_note = "- Editorial report: [REPORT.md](REPORT.md).\n" if report_link else "- No `REPORT.md` was present at generation. Regenerate after it is added to expose its review link.\n"
    if diff_link:
        report_note += "- Exact text changes: [summaries.diff](summaries.diff).\n"
    readme = f'''# Arrays: capacity carried forward — before/after review

Review date: {DATE}. Five existing halls, in canonical order.

Open [index.html](index.html) through `/book-review/doc/book/iterations/2026-10-04-arrays-capacity-return/index.html`.

The review shows the complete before and after summary for every hall, both sequence arcs, each authored change reason, proposed independent check and critical question. Native disclosures contain compact summaries, comparisons of the learning fields, prior hall links, source paths and remaining work.

- Editable working memory: `/project-memory?scope=sequence%3Aarray_tutorial`.
{report_note}- The page uses native anchors and `<details>` with no scripts, event handlers, remote fonts or external dependencies.
- Existing museum images are reference captures shared by the two texts; they are not before/after geometry comparisons or proof that a revised lesson is implemented.
- The old `commons/maps/Tutorial_Disco/tutorial.md` footstep-recording account remains an explicit open contradiction awaiting a full tutorial rewrite.

## Inputs and provenance

- Before: `before/doc/book/course/storyboards/early.json`, SHA-256 `{before_hash}`.
- After: canonical `doc/book/course/storyboards/early.json`, SHA-256 `{after_hash}`.
- Prior captures: `doc/book/iterations/2026-10-04-museum-tutorial-storyboards/route.json`, SHA-256 `{route_hash}`, with two review-only overrides below. Each image retains its original metadata date. The publisher links the existing image files and copies none; the global route payload is unchanged.
- Floor uses `../2026-09-28-tiling-rule-study/floor-rule-after.png`, dated 2026-09-28, showing the existing 4×4 rule-study controls. Evidence: `floor-source_manifest.json` and `floor-report.json` in that folder. BEFORE / AFTER labels inside the photograph refer to the old rule demonstration, not this summary revision.
- Walls uses `../2026-09-28-tiling-rule-study/wall-eye-chart.png`, dated 2026-09-28, showing the existing eye chart. Evidence: `wall-source_manifest.json` in that folder.
- Runtime source paths are displayed as plain repository paths because those files are outside the review server's supported document roots. Prior halls link to their selected map scope in project memory.

## Regenerate

From the repository root, after the revised canonical teaching data is ready:

```powershell
python -X utf8 doc/book/iterations/2026-10-04-arrays-capacity-return/publish.py
```

The publisher validates the expected five-hall order, revised fields and original capture paths/dates. It writes only `index.html` and this README. It does not change the canonical plans, before snapshot, full tutorials, final manuscripts, museum order or runtime files; it does not run Godot or establish the implementation of proposed learning tasks.
'''
    (HERE / "README.md").write_text(readme, encoding="utf-8")
    print("Published five complete before/after comparisons with original capture dates.")


if __name__ == "__main__":
    publish()
