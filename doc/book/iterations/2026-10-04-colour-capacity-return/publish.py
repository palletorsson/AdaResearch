"""Publish eight concise Colour change cards with existing museum photographs.

Reads changes.json and capture metadata; writes only index.html and README.md.
No canonical content, runtime state, finding or approval is changed here.
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
CHANGES = HERE / "changes.json"
ROUTE = ROOT / "doc/book/iterations/2026-10-04-museum-tutorial-storyboards/route.json"
DATE = "2026-10-04"
MAP_IDS = [
    "Color_Context_Placed", "Color_Flashlight", "Color_Nails", "Color_Rainbow",
    "Color_Pillar", "Color_Grid_Pallet", "Color_Paint", "Color_Walls",
]
# These images are already embedded in the current final texts. The dates refer
# to their earlier capture publications, not this teaching-summary revision.
PHOTO_OVERRIDES = {
    "Color_Flashlight": {
        "src": "../2026-10-02-light-an-opening/figures/pink-threshold.png",
        "date": "2026-10-02", "label": "The installed light-room recess",
        "evidence": "doc/book/iterations/2026-10-02-light-an-opening/VALIDATION.json",
    },
    "Color_Pillar": {
        "src": "../2026-09-28-pillar-colour-ceiling/ceiling-and-column.png",
        "date": "2026-09-28", "label": "Colour above the museum pillars",
        "evidence": "doc/book/iterations/2026-09-28-pillar-colour-ceiling/source_manifest.json",
    },
    "Color_Walls": {
        "src": "../2026-10-01-office-open-colour/layers-glass.png",
        "date": "2026-10-01", "label": "Overlapping panes inside the museum",
        "evidence": "doc/book/iterations/2026-10-01-office-open-colour/source_manifest.json",
    },
}
# Prefer a single museum view over a composite or an isolated canvas texture.
ROUTE_IMAGE_INDEX = {"Color_Grid_Pallet": 1, "Color_Paint": 1}


def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


def inline(value: str) -> str:
    parts = re.split(r"(`[^`\n]+`)", value)
    return "".join(f"<code>{esc(part[1:-1])}</code>" if part.startswith("`") and part.endswith("`") else esc(part) for part in parts)


def memory(scope: str) -> str:
    return "/project-memory?scope=" + quote(scope, safe="") + "&detail=1&view=focused"


def photo_for(map_id: str, capture: dict) -> dict:
    if map_id in PHOTO_OVERRIDES:
        photo = dict(PHOTO_OVERRIDES[map_id])
        path = (HERE / photo["src"]).resolve()
        if not path.is_relative_to(ROOT / "doc/book/iterations") or not path.is_file():
            raise ValueError(f"Missing museum photograph: {photo['src']}")
        if not (ROOT / photo["evidence"]).is_file():
            raise ValueError(f"Missing capture evidence: {photo['evidence']}")
    else:
        images = capture.get("images", [])
        index = ROUTE_IMAGE_INDEX.get(map_id, 0)
        if len(images) <= index:
            raise ValueError(f"Missing museum capture {index + 1} for {map_id}")
        photo = dict(images[index])
        path = PurePosixPath(photo["src"])
        if path.is_absolute() or ".." in path.parts or not (ROUTE.parent / str(path)).is_file():
            raise ValueError(f"Invalid route image path: {path}")
        photo["src"] = "../2026-10-04-museum-tutorial-storyboards/" + str(path)
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", photo.get("date", "")):
        raise ValueError(f"Missing original capture date for {map_id}")
    return photo


def card(change: dict, photo: dict, number: int) -> str:
    map_id = change["id"]
    return f'''<article class="card" id="{esc(map_id)}" aria-labelledby="title-{esc(map_id)}">
<figure><a href="{esc(photo['src'])}" aria-label="Open earlier museum capture for {esc(change['title'])}"><img src="{esc(photo['src'])}" alt="{esc(photo['label'])}" loading="{'eager' if number <= 2 else 'lazy'}"></a><figcaption>Earlier museum capture · <time datetime="{photo['date']}">{photo['date']}</time></figcaption></figure>
<div class="card-body"><p class="map-id"><span>{number:02d}</span> {esc(map_id)}</p><h2 id="title-{esc(map_id)}">{esc(change['title'])}</h2><dl class="changes"><div class="before"><dt>Before</dt><dd>{inline(change['before'])}</dd></div><div class="after"><dt>After</dt><dd>{inline(change['after'])}</dd></div></dl><p class="reason"><strong>Why</strong> {inline(change['reason'])}</p><a class="review-link" href="{esc(memory('map:' + map_id))}">Review this map’s proposal <span aria-hidden="true">↗</span></a></div></article>'''


CSS = """
:root{--paper:#f5f3ed;--card:#fffefb;--ink:#26352d;--muted:#647269;--green:#315a49;--line:#d7ddd3;--rose:#8a4560;--soft:#edf2e9}*{box-sizing:border-box}html{scroll-padding-top:20px}body{margin:0;background:var(--paper);color:var(--ink);font:15px/1.6 system-ui,-apple-system,'Segoe UI',sans-serif}a{color:var(--green);text-underline-offset:.2em}a:hover{text-decoration-thickness:2px}a:focus-visible{outline:3px solid var(--rose);outline-offset:4px}p{margin:0}h1,h2{font:500 46px/1.12 Georgia,'Times New Roman',serif;letter-spacing:-.035em;margin:0}h2{font-size:27px;line-height:1.17;letter-spacing:-.025em}code{font:.85em/1.5 ui-monospace,Consolas,monospace;overflow-wrap:anywhere}.container{max-width:1140px;margin:auto;padding:0 28px}.skip{position:absolute;top:-100px;left:12px;background:var(--card);padding:10px;z-index:5}.skip:focus{top:12px}.topbar{padding:16px 0;border-bottom:1px solid var(--line);font-size:12px}.topbar .container{display:flex;justify-content:space-between;gap:20px}.brand{font-weight:750;text-decoration:none;letter-spacing:.05em}.top-links{display:flex;gap:20px;flex-wrap:wrap}.hero{padding-top:38px;padding-bottom:27px}.eyebrow{font-size:10px;font-weight:700;letter-spacing:.14em;text-transform:uppercase;color:var(--muted);margin-bottom:13px}.intro{margin-top:18px;max-width:760px;font-size:16px}.capture-note{margin-top:12px;color:var(--muted);font-size:12px}.cards{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px;padding-bottom:32px}.card{background:var(--card);border:1px solid var(--line);border-radius:3px;overflow:hidden;min-width:0;display:flex;flex-direction:column}.card:target{outline:2px solid var(--green);outline-offset:4px}figure{margin:0}figure a{display:block;background:#24322b}img{display:block;width:100%;height:auto;aspect-ratio:16/10;object-fit:contain}figcaption{padding:8px 21px;border-bottom:1px solid var(--line);font-size:11px;color:var(--muted)}.card-body{padding:19px 21px 22px;display:flex;flex:1;flex-direction:column}.map-id{font:10px/1.5 ui-monospace,Consolas,monospace;color:var(--muted);margin-bottom:9px;overflow-wrap:anywhere}.map-id span{color:var(--rose);font-weight:700;margin-right:5px}.changes{margin:19px 0 0;display:grid;gap:12px}.changes>div{display:grid;grid-template-columns:45px minmax(0,1fr);gap:9px}.changes dt{font-size:10px;font-weight:750;text-transform:uppercase;letter-spacing:.07em;line-height:1.8;padding-top:2px;color:var(--muted)}.changes dd{margin:0;font-size:14px;line-height:1.6}.changes .after dt{color:var(--green)}.after dd{color:#263f31}.reason{margin:16px 0 18px;padding-top:13px;border-top:1px solid var(--line);font-size:12px;color:var(--muted)}.reason strong{color:var(--rose);font-size:10px;text-transform:uppercase;letter-spacing:.06em;margin-right:5px}.review-link{font-size:12px;margin-top:auto;align-self:flex-start}.acceptance{margin-bottom:34px;padding:19px 22px;border-left:3px solid var(--green);background:var(--soft);font-size:13px}.acceptance strong{font-weight:650}.acceptance p+p{margin-top:8px}.acceptance .meaning{font-size:12px;color:var(--muted)}footer{border-top:1px solid var(--line);padding:20px 0 29px;font-size:11px;color:var(--muted)}footer .container{display:flex;justify-content:space-between;gap:18px}.footer-links{display:flex;gap:20px;flex-wrap:wrap}
@media(max-width:740px){.container{padding:0 17px}.cards{grid-template-columns:1fr;gap:22px}.hero{padding-top:28px}h1{font-size:37px}h2{font-size:26px}.top-links{gap:12px}.card-body{padding:19px 19px 21px}figcaption{padding-inline:19px}.changes dd{font-size:15px}.acceptance{padding:17px}footer .container{display:block}.footer-links{margin-top:9px}}
@media print{.skip,.topbar,.review-link,.acceptance,.footer-links{display:none}.container{padding:0;max-width:none}.hero{padding-top:0}.card{break-inside:avoid}.cards{gap:15px}.card-body{padding:12px}.changes dd{font-size:10pt}.reason{font-size:9pt}h1{font-size:27pt}h2{font-size:18pt}img{max-height:180px}a{color:inherit}}
"""


def publish() -> None:
    changes = json.loads(CHANGES.read_text(encoding="utf-8-sig"))
    if not isinstance(changes, list) or [item.get("id") for item in changes] != MAP_IDS:
        raise ValueError("changes.json must contain the eight Colour maps in their existing order.")
    for change in changes:
        for key in ["id", "title", "before", "after", "reason"]:
            if not isinstance(change.get(key), str) or not change[key].strip():
                raise ValueError(f"Missing concise {key} for {change.get('id', 'map')}")
    route = json.loads(ROUTE.read_text(encoding="utf-8-sig"))
    by_id = {hall["id"]: hall for hall in route["halls"]}
    photos = [photo_for(change["id"], by_id[change["id"]]) for change in changes]
    cards = "\n".join(card(change, photo, number) for number, (change, photo) in enumerate(zip(changes, photos), 1))
    digest = hashlib.sha256(CHANGES.read_bytes()).hexdigest()
    diff = '<a href="summaries.diff">Exact text diff</a>' if (HERE / "summaries.diff").is_file() else ""
    plan = f'<a href="{esc(memory("sequence:color"))}">Colour plan</a>'
    page = f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="color-scheme" content="light"><meta name="description" content="Eight short before-and-after teaching changes for Colour, with earlier Endless Museum photographs."><title>Colour · what changes</title><style>{CSS}</style></head>
<body><a class="skip" href="#changes">Skip to the eight map summaries</a><div class="topbar"><div class="container"><a class="brand" href="{esc(memory('sequence:color'))}">ADA / COLOUR</a><div class="top-links">{diff}{plan}</div></div></div>
<header class="hero container"><p class="eyebrow">Eight map summaries · {DATE}</p><h1>Colour · what changes</h1><p class="intro">A short comparison for each map: what the plan said, what is proposed now, and why.</p><p class="capture-note">All images are earlier museum captures. This update changes teaching plans; there are no new visual or runtime changes.</p></header>
<main class="container"><div id="changes" class="cards">{cards}</div><aside class="acceptance" aria-label="How to accept a proposal"><p><strong>To accept:</strong> open a map’s proposal, find <strong>Findings</strong>, open <strong>Review or recheck this finding</strong>, add a <strong>Review note</strong> and choose <strong>Accept</strong>.</p><p>Or say “Accept Colour” or “Accept Colour except [map name]” in chat.</p><p class="meaning">Acceptance records that you want to retain the teaching plan. It does not implement code or lessons. This review page itself saves no approval.</p></aside></main>
<footer><div class="container"><p>Concise change record · source SHA-256 <code>{digest[:16]}</code></p><div class="footer-links">{diff}{plan}</div></div></footer></body></html>'''
    (HERE / "index.html").write_text(page, encoding="utf-8")
    image_lines = "\n".join(f"| `{change['id']}` | `{photo['src']}` | {photo['date']} |" for change, photo in zip(changes, photos))
    evidence_lines = "\n".join(f"- `{map_id}`: `{record['evidence']}`." for map_id, record in PHOTO_OVERRIDES.items())
    readme = f'''# Colour · what changes

Compact review dated {DATE}. [Open index.html](index.html) through `/book-review/doc/book/iterations/2026-10-04-colour-capacity-return/index.html`.

Eight cards show only the short before, after and reason strings in `changes.json`. Full storyboards and implementation detail stay out of the review. Each card links to the selected map's open, focused project-memory workspace; the reader reviews its finding there. This page has no approval action. Acceptance retains a teaching plan and does not implement code or full lessons.

## Publish

After `changes.json` and `summaries.diff` are final, run from the repository root:

```powershell
python -X utf8 doc/book/iterations/2026-10-04-colour-capacity-return/publish.py
```

The publisher writes only `index.html` and this README. It validates eight map IDs in the existing order, required short strings, image files and original capture dates. The exact-diff link appears when `summaries.diff` exists. There are no scripts, remote fonts, external dependencies or approval requests.

## Text provenance

- Input: `changes.json`, SHA-256 `{digest}`.
- The source is the author's compact before/after account; it is not a verbatim display of complete storyboards.
- Map links use `/project-memory?scope=map%3A<id>&detail=1&view=focused`. They open the selected workspace; they do not target a finding ID or save an acceptance.

## Earlier museum images

All photographs are reused; none depict a visual change made by this summary update. Default images and dates come from `doc/book/iterations/2026-10-04-museum-tutorial-storyboards/route.json`. Grid and Paint use the second route image to show the museum view rather than a composite or isolated texture. Three local review overrides follow photographs embedded in the current final texts and preserve their earlier publication dates. The global route metadata is unchanged.

| Map | Image | Original date |
| --- | --- | --- |
{image_lines}

Evidence for the three review-only overrides:

{evidence_lines}
'''
    (HERE / "README.md").write_text(readme, encoding="utf-8")
    print("Published eight concise Colour change cards with dated museum images.")


if __name__ == "__main__":
    publish()
