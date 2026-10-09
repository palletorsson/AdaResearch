"""Publish the six authored shader plans as a script-free, source-linked review.

Reads canonical storyboards and prior capture metadata. Writes only index.html,
README.md and an exact teaching-guide.md snapshot beside this script; never
rewrites canonical content or captures.
"""
from __future__ import annotations

import hashlib
import html
import json
import re
from pathlib import Path, PurePosixPath
from urllib.parse import quote, urlparse


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
STORYBOARD = ROOT / "doc/book/course/storyboards/growth.json"
TEACHING_GUIDE = ROOT / "doc/book/course/storyboards/SHADERS.md"
CAPTURES = ROOT / "doc/book/iterations/2026-10-04-museum-tutorial-storyboards/route.json"
REVIEW_DATE = "2026-10-04"
STAGES = [
    ("Shader_01_Shaping", "Form", "A mark receives a boundary"),
    ("Shader_05_Patterns", "Repeat", "One form, many addresses"),
    ("Shader_11_QueerRubber", "Body", "A surface meets the viewer"),
    ("Shader_09_FBM", "Field", "Variation finds a recipient"),
    ("Shader_12_PinkExtravaganza", "Composition", "Choose what belongs together"),
    ("Shader_10_ReactionDiffusion", "Memory", "What must the next image keep?"),
]


def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


def readable(value: object) -> str:
    if isinstance(value, dict):
        return "; ".join(f"{key}: {readable(item)}" for key, item in value.items())
    if isinstance(value, list):
        return "; ".join(readable(item) for item in value)
    return str(value or "")


def inline(value: object) -> str:
    """Escape all authored text; render only paired inline-code delimiters."""
    parts = re.split(r"(`[^`\n]+`)", readable(value))
    return "".join(f"<code>{esc(p[1:-1])}</code>" if p.startswith("`") and p.endswith("`") else esc(p) for p in parts)


def paragraphs(value: object) -> str:
    return "".join(f"<p>{inline(p)}</p>" for p in readable(value).split("\n\n") if p.strip())


def items(value: object) -> str:
    values = value if isinstance(value, list) else [value]
    return "<ul>" + "".join(f"<li>{inline(v)}</li>" for v in values if v) + "</ul>"


def memory(scope: str) -> str:
    return "/project-memory?scope=" + quote(scope, safe="")


def prior_maps(value: object) -> str:
    values = value if isinstance(value, list) else [value]
    result = []
    for item in values:
        if isinstance(item, dict):
            map_id = str(item.get("id", item.get("map", item.get("map_id", ""))))
            label = str(item.get("title", map_id))
            note = str(item.get("purpose", item.get("contribution", item.get("note", ""))))
        else:
            map_id, label, note = str(item), str(item), ""
        if re.fullmatch(r"[A-Za-z0-9_]+", map_id):
            label_html = f'<a href="{esc(memory("map:" + map_id))}">{esc(label)}</a>'
        else:
            label_html = inline(label)
        result.append(f"<li>{label_html}{' — ' + inline(note) if note else ''}</li>")
    return '<ul class="prior-maps">' + "".join(result) + "</ul>"


def source_list(value: object) -> str:
    values = value if isinstance(value, list) else [value]
    result = []
    for item in values:
        if isinstance(item, dict):
            path = item.get("path", item.get("source", ""))
            note = item.get("purpose", item.get("note", item.get("role", "")))
            result.append(f"<li><code>{esc(path)}</code>{'<span>' + inline(note) + '</span>' if note else ''}</li>")
        else:
            result.append(f"<li><code>{esc(item)}</code></li>")
    return '<ul class="source-list">' + "".join(result) + "</ul>"


def references(value: object) -> str:
    result = []
    for item in value if isinstance(value, list) else []:
        title, url = str(item.get("title", "Reference")), str(item.get("url", ""))
        if urlparse(url).scheme != "https":
            raise ValueError(f"Tutorial reference must use HTTPS: {url}")
        purpose = item.get("purpose", "")
        result.append(f'<li><a href="{esc(url)}">{esc(title)} <span aria-hidden="true">↗</span></a>{paragraphs(purpose)}</li>')
    if not result:
        return '<p class="small-note">No additional tutorial reference is supplied for this reflective encounter.</p>'
    return '<ul class="references">' + "".join(result) + "</ul>"


CSS = """
:root{--paper:#f5f3ec;--card:#fffef9;--ink:#222d29;--muted:#64716b;--line:#d8ddd4;--green:#2f584a;--soft:#e8eee5;--rose:#854360;--pink:#f3e7ed}
*{box-sizing:border-box}html{scroll-padding-top:96px}body{margin:0;background:var(--paper);color:var(--ink);font:16px/1.65 system-ui,-apple-system,'Segoe UI',sans-serif}a{color:var(--green);text-underline-offset:.2em}a:hover{text-decoration-thickness:2px}a:focus-visible,summary:focus-visible{outline:3px solid var(--rose);outline-offset:5px}img{display:block;width:100%;height:auto}code{font: .88em/1.6 ui-monospace,SFMono-Regular,Consolas,monospace;overflow-wrap:anywhere}p{margin:0 0 1em}h1,h2,h3{font-weight:500;line-height:1.12;margin:0}h1,h2{font-family:Georgia,'Times New Roman',serif}h1{font-size:clamp(43px,6vw,80px);letter-spacing:-.055em;max-width:850px}h2{font-size:clamp(28px,3.2vw,40px);letter-spacing:-.035em}h3{font-size:14px;line-height:1.4;margin:0 0 .6em;font-weight:700}ul{padding-left:1.2em;margin:0 0 1em}li+li{margin-top:.4em}.skip{position:absolute;top:-100px;left:16px;z-index:10;background:var(--card);padding:12px}.skip:focus{top:10px}.container{max-width:1260px;margin:auto;padding:0 38px}.topbar{border-bottom:1px solid var(--line);padding:17px 0}.topbar .container{display:flex;align-items:center;justify-content:space-between;gap:20px}.brand{font-weight:750;letter-spacing:-.04em;font-size:20px;text-decoration:none}.toplinks{display:flex;gap:22px;flex-wrap:wrap;font-size:13px}.eyebrow{font-size:11px;font-weight:750;text-transform:uppercase;letter-spacing:.15em}.hero{padding-top:62px;padding-bottom:38px}.hero .eyebrow{color:var(--green);margin-bottom:20px}.deck{font:21px/1.55 Georgia,serif;max-width:820px;margin:23px 0 27px}.status{display:flex;align-items:flex-start;gap:12px;max-width:970px;padding:17px 19px;border:1px solid #d7c1cc;background:var(--pink);font-size:14px}.status strong{display:block;color:#643048}.status p{margin:0}.status-dot{width:8px;height:8px;border-radius:50%;background:var(--rose);flex:none;margin-top:8px}.arc{max-width:930px;margin-top:24px;color:var(--muted);font-size:14px}.arc p{margin:0}.route-nav{position:sticky;top:0;z-index:3;border-top:1px solid var(--line);border-bottom:1px solid var(--line);background:#f5f3ecf7;backdrop-filter:blur(10px)}.route-nav ol{list-style:none;margin:0;padding:0;display:grid;grid-template-columns:repeat(6,minmax(0,1fr))}.route-nav li{margin:0;border-right:1px solid var(--line)}.route-nav li:first-child{border-left:1px solid var(--line)}.route-nav a{display:flex;gap:10px;align-items:center;padding:16px 13px;text-decoration:none;font-size:14px;font-weight:650}.route-nav a:hover{background:var(--soft)}.route-nav span{font:12px ui-monospace,monospace;color:var(--muted)}main{padding-top:40px;padding-bottom:30px}.encounter{background:var(--card);border:1px solid var(--line);border-radius:3px;margin-bottom:32px;scroll-margin-top:102px}.encounter:target{outline:2px solid var(--green);outline-offset:4px}.hall-heading{display:flex;justify-content:space-between;align-items:flex-start;gap:24px;padding:27px 30px 23px;border-bottom:1px solid var(--line)}.hall-heading .eyebrow{color:var(--green);margin-bottom:9px}.hall-id{color:var(--muted);font:11px/1.5 ui-monospace,monospace;overflow-wrap:anywhere;margin-top:12px}.hall-link{font-size:12px;white-space:nowrap;margin-top:4px}.hall-body{display:grid;grid-template-columns:minmax(0,.95fr) minmax(0,1.05fr);gap:30px;padding:28px 30px}.capture{margin:0;align-self:start}.image-link{display:block;background:#17251e;border:1px solid #c8cfc5}.capture img{aspect-ratio:16/9;object-fit:contain}.capture figcaption{margin-top:10px;font-size:12px;line-height:1.55;color:var(--muted)}.capture figcaption strong{color:var(--ink);font-weight:600}.capture-note{display:block}.story .eyebrow{color:var(--rose);margin-bottom:10px}.story .story-text{font:19px/1.68 Georgia,serif}.story-text p:last-child{margin-bottom:0}.carry{margin-top:22px;border-left:3px solid var(--green);padding:10px 0 10px 16px;background:linear-gradient(90deg,var(--soft),transparent);font-size:14px}.carry strong{display:block;font-size:11px;letter-spacing:.09em;text-transform:uppercase;color:var(--green);margin-bottom:4px}.details-stack{padding:0 30px 23px}.details-stack details{border-top:1px solid var(--line)}summary{cursor:pointer;font-size:14px;font-weight:600;padding:15px 0;list-style-position:outside;margin-left:17px}summary::marker{color:var(--green)}.details-content{padding:0 0 19px;font-size:14px}.details-content>p:last-child{margin-bottom:0}.contract{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:25px;margin-bottom:15px}.check{border:1px solid #cfdccb;background:#f1f5ed;padding:15px 18px}.check p:last-child{margin:0}.question{margin-top:18px;font:18px/1.55 Georgia,serif}.question-label{font:11px/1.5 system-ui,sans-serif;text-transform:uppercase;letter-spacing:.1em;color:var(--rose);display:block;margin-bottom:5px}.source-columns{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:30px}.source-list{list-style:none;padding:0}.source-list li{padding:7px 0;border-bottom:1px solid #e9ece5}.source-list span{display:block;color:var(--muted);font-size:12px}.source-list code{font-size:12px}.references{list-style:none;padding:0}.references li{margin:0 0 15px}.references p{font-size:13px;color:var(--muted);margin:3px 0 0}.small-note{font-size:12px;color:var(--muted)}.compact{border-left:2px solid var(--line);padding-left:17px}.footer{border-top:1px solid var(--line);padding:27px 0 40px;font-size:13px;color:var(--muted)}.footer-row{display:flex;justify-content:space-between;gap:30px}.footer p{max-width:820px}.footer-links{display:flex;gap:20px;flex-wrap:wrap}.provenance{margin-top:18px;font-size:11px;overflow-wrap:anywhere}
@media(min-width:1500px){.container{max-width:1390px}.story .story-text{font-size:20px}.hall-body{gap:39px}}
@media(max-width:920px){.container{padding:0 24px}.hall-body{grid-template-columns:1fr}.capture{max-width:760px}.story .story-text{max-width:760px}.route-nav a{gap:6px;padding:13px 8px;font-size:12px}.route-nav span{font-size:10px}.hero{padding-top:40px}.contract{gap:15px}}
@media(max-width:600px){html{scroll-padding-top:116px}.container{padding:0 17px}.topbar .container{align-items:flex-start}.toplinks{gap:8px 15px;justify-content:flex-end;font-size:12px}.hero{padding-top:32px;padding-bottom:26px}.deck{font-size:19px}.status{padding:14px}.route-nav ol{grid-template-columns:repeat(3,minmax(0,1fr))}.route-nav li:nth-child(4){border-left:1px solid var(--line)}.route-nav li:nth-child(-n+3){border-bottom:1px solid var(--line)}.route-nav a{font-size:13px;padding:10px}.hall-heading{display:block;padding:22px 19px 20px}.hall-link{display:inline-block;margin-top:13px}.hall-body{padding:20px 19px;gap:22px}.story .story-text{font-size:18px}.details-stack{padding:0 19px 17px}.contract,.source-columns{grid-template-columns:1fr;gap:14px}.contract ul{margin-bottom:0}.footer-row{display:block}.footer-links{margin-top:18px}.encounter{scroll-margin-top:116px}}
@media(prefers-reduced-motion:no-preference){html{scroll-behavior:smooth}}
@media print{.topbar,.route-nav,.hall-link,.skip{display:none}.container{max-width:none;padding:0}.hero{padding-top:0}.encounter{break-inside:avoid;box-shadow:none}.hall-body{grid-template-columns:1fr 1fr}.story .story-text{font-size:11pt}.capture figcaption{font-size:9pt}.status{background:white}.footer{font-size:9pt}h1{font-size:36pt}h2{font-size:22pt}a{color:inherit}}
"""


def hall_html(hall: dict, capture: dict, index: int, stage: str) -> str:
    map_id = hall["id"]
    images = capture.get("images", [])
    if not images:
        raise ValueError(f"No prior capture for {map_id}")
    photo = images[0]
    relative = PurePosixPath(photo["src"])
    if relative.is_absolute() or ".." in relative.parts:
        raise ValueError(f"Unexpected capture path: {relative}")
    if not (CAPTURES.parent / str(relative)).is_file():
        raise FileNotFoundError(CAPTURES.parent / str(relative))
    date = photo.get("date")
    if not date:
        raise ValueError(f"No original capture date for {map_id}")
    image_src = "../2026-10-04-museum-tutorial-storyboards/" + str(relative)
    contract = "".join(f"<div><h3>{label}</h3>{items(hall.get(key))}</div>" for key, label in [("brings", "Bring from earlier halls"), ("learns", "Develop here"), ("supplied", "Supplied for the learner")])
    return f"""<article class="encounter" id="{esc(stage.lower())}" aria-labelledby="heading-{esc(map_id)}">
<header class="hall-heading"><div><p class="eyebrow">{index:02d} / {esc(stage)}</p><h2 id="heading-{esc(map_id)}">{esc(hall['title'])}</h2><p class="hall-id">{esc(map_id)}</p></div><a class="hall-link" href="{esc(memory('map:' + map_id))}">Open this hall in memory ↗</a></header>
<div class="hall-body"><figure class="capture"><a class="image-link" href="{esc(image_src)}" aria-label="Open prior museum capture for {esc(hall['title'])}"><img src="{esc(image_src)}" alt="Prior Endless Museum capture: {esc(photo.get('label', 'museum encounter'))}, {esc(map_id)}" loading="{'eager' if index == 1 else 'lazy'}" width="1280" height="720"></a><figcaption><strong>Prior museum capture · <time datetime="{esc(date)}">{esc(date)}</time></strong><br>{esc(photo.get('label', 'Museum encounter'))}<span class="capture-note">Existing exhibit; this image does not show implementation of the revised teaching plan.</span></figcaption></figure>
<div class="story"><p class="eyebrow">Proposed teaching plan</p><div class="story-text">{paragraphs(hall['storyboard'])}</div><div class="carry"><strong>Carry forward</strong>{inline(hall.get('carries', ''))}</div></div></div>
<div class="details-stack"><details><summary>Learning contract &amp; independent check</summary><div class="details-content"><div class="contract">{contract}</div><div class="check"><h3>Try it independently</h3>{paragraphs(hall.get('independent_check'))}</div><p class="question"><span class="question-label">A question to keep open</span>{inline(hall.get('critical_question'))}</p></div></details>
<details><summary>Compact storyboard &amp; open questions</summary><div class="details-content"><div class="compact">{paragraphs(hall.get('storyboard_short'))}</div><h3>What still needs resolving</h3>{paragraphs(hall.get('review_note'))}</div></details>
<details><summary>Earlier halls, exact sources &amp; tutorial references</summary><div class="details-content"><div class="source-columns"><div><h3>Earlier encounters</h3>{prior_maps(hall.get('prior_maps', []))}<h3>Existing source paths</h3><p class="small-note">Repository paths for inspection. These are existing sources, not newly connected lesson adapters.</p>{source_list(hall.get('source_refs', []))}</div><div><h3>Tutorial references &amp; inspiration</h3>{references(hall.get('tutorial_references', []))}<p class="small-note">References inform the teaching proposal. The supplied Godot host and museum encounter remain explicit.</p></div></div></div></details></div></article>"""


def publish() -> None:
    data = json.loads(STORYBOARD.read_text(encoding="utf-8-sig"))
    sequence = next(item for item in data if item["sequence"] == "shaders")
    halls = sequence["halls"]
    expected_ids = [item[0] for item in STAGES]
    if [h["id"] for h in halls] != expected_ids:
        raise ValueError("The canonical six-hall order changed; review the publisher's stage labels.")
    required = ["storyboard", "storyboard_short", "prior_maps", "independent_check", "critical_question", "source_refs", "tutorial_references"]
    for hall in halls:
        missing = [key for key in required if key not in hall or hall[key] is None]
        if missing:
            raise ValueError(f"Updated teaching data not ready for {hall['id']}: {', '.join(missing)}")
    captures = json.loads(CAPTURES.read_text(encoding="utf-8-sig"))
    capture_by_id = {item["id"]: item for item in captures["halls"]}
    nav = "".join(f'<li><a href="#{stage.lower()}" title="{esc(note)}"><span>{i:02d}</span>{esc(stage)}</a></li>' for i, (_, stage, note) in enumerate(STAGES, 1))
    rendered = "\n".join(hall_html(h, capture_by_id[h["id"]], i, STAGES[i - 1][1]) for i, h in enumerate(halls, 1))
    source_hash = hashlib.sha256(STORYBOARD.read_bytes()).hexdigest()
    guide_bytes = TEACHING_GUIDE.read_bytes()
    guide_hash = hashlib.sha256(guide_bytes).hexdigest()
    guide = "teaching-guide.md"
    memory_url = memory("sequence:shaders")
    page = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="color-scheme" content="light"><meta name="description" content="Six proposed shader teaching plans, grounded in earlier form-making and existing Endless Museum encounters."><title>Ada · Shaders, form &amp; surface</title><style>{CSS}</style></head>
<body id="top"><a class="skip" href="#review">Skip to the six teaching plans</a><div class="topbar"><div class="container"><a class="brand" href="{esc(memory_url)}">Ada / Shaders</a><div class="toplinks"><a href="{guide}">Teaching guide snapshot</a><a href="{esc(memory_url)}">Project memory ↗</a></div></div></div>
<header class="hero container"><p class="eyebrow">Teaching proposal · {REVIEW_DATE} · Six existing halls</p><h1>Form becomes<br>a surface rule.</h1><p class="deck">A point, a line, a face. Then a repeated mark, a material on a body, a field across a room. Shaders extend the forms and relationships already encountered in Ada.</p><div class="status"><span class="status-dot" aria-hidden="true"></span><p><strong>Teaching plans updated. Lesson adapters remain proposed.</strong>Exhibit geometry and logic are unchanged. The existing route stays images → bodies → rooms; the final encounter asks what a changing image must remember.</p></div><div class="arc">{paragraphs(sequence['arc'])}</div></header>
<nav class="route-nav" aria-label="Six shader encounters"><div class="container"><ol>{nav}</ol></div></nav><main class="container" id="review">{rendered}</main>
<footer class="footer"><div class="container"><div class="footer-row"><div><h3>Keep the route open to change.</h3><p>These are teaching proposals beside existing museum encounters. Reflection and composition can deepen a capability without introducing new syntax. Use project memory to keep alternatives, questions and reasons alongside the plan.</p></div><div class="footer-links"><a href="{guide}">Read the teaching guide snapshot</a><a href="{esc(memory_url)}">Review in project memory</a><a href="#top">Back to top ↑</a></div></div><p class="provenance">Canonical plans: <code>doc/book/course/storyboards/growth.json</code> · SHA-256 <code>{source_hash[:16]}</code><br>Teaching guide: exact snapshot dated {REVIEW_DATE} of <code>doc/book/course/storyboards/SHADERS.md</code> · SHA-256 <code>{guide_hash[:16]}</code>.<br>Images reused from the prior museum route publication; each caption retains its original capture date. No new exhibit captures or runtime validation are implied.</p></div></footer></body></html>"""
    (HERE / "teaching-guide.md").write_bytes(guide_bytes)
    (HERE / "index.html").write_text(page, encoding="utf-8")
    readme = f"""# Shaders: form and surface — teaching review

Review date: {REVIEW_DATE}. Six existing halls, in canonical order.

The authored teaching plans are updated; lesson adapters are proposed. Exhibit geometry, runtime logic, map order and final manuscripts are unchanged by this publisher.

- Open `index.html` through `/book-review/doc/book/iterations/2026-10-04-shaders-form-and-surface/index.html`.
- Teaching guide snapshot: [teaching-guide.md](teaching-guide.md), served beside this review.
- Editable working memory: `{memory_url}`.
- The page uses native anchors and `<details>`; it has no scripts, event handlers, remote fonts or external dependencies.

## Inputs and provenance

- `doc/book/course/storyboards/growth.json`: the six shader summaries, learning fields and references. SHA-256: `{source_hash}`.
- `teaching-guide.md`: an exact byte-for-byte snapshot dated {REVIEW_DATE} of canonical `doc/book/course/storyboards/SHADERS.md`. SHA-256: `{guide_hash}`. The canonical source is preserved; this copy makes the guide available within the review server's supported document roots.
- `doc/book/iterations/2026-10-04-museum-tutorial-storyboards/route.json`: first existing capture for each hall, including original capture date.
- Images are linked from that publication's `images/` directory; none are copied or represented as captures of the revised teaching plans.
- Exact implementation paths are plain text because `commons/` source links do not resolve through `/book-review`. No source snapshots are created.
- Prior hall links target `/project-memory?scope=map%3A…`. Tutorial reference links use HTTPS.

## Regenerate

From the repository root:

```powershell
python -X utf8 doc/book/iterations/2026-10-04-shaders-form-and-surface/publish.py
```

The publisher validates the six-hall order, the revised teaching fields, reference schemes and capture paths/dates. It writes only `index.html`, this README and the exact `teaching-guide.md` snapshot in its own directory. It does not run Godot, change canonical teaching plans or validate implementation of proposed adapters.
"""
    (HERE / "README.md").write_text(readme, encoding="utf-8")
    print(f"Published {len(halls)} shader teaching plans; preserved original dates on six prior captures.")


if __name__ == "__main__":
    publish()
