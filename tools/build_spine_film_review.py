"""Build the portable review page from the film catalog and current evidence files.

No server or fetch is needed: catalog/evidence are embedded for file:// reading.
Run again after renders finish to refresh availability and verification statuses.
"""
from __future__ import annotations

import html
import json
import os
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "doc/book/iterations/2026-10-04-spine-films"
CATALOG = ROOT / "commons/artifacts/spine_films/catalog.json"

SEQUENCES = {
    "primitives": "Primitives", "transformation": "Transformation",
    "array_tutorial": "Arrays", "color": "Colour", "tiling": "Patterns",
    "change": "Change", "forces": "Forces", "formfinding": "Form finding",
    "wavefunctions": "Wave functions", "randomness": "Randomness", "noise": "Noise",
    "shaders": "Shaders", "cellularautomata": "Cellular automata", "fractals": "Fractals",
    "lsystems": "L-systems", "proceduralgeneration": "Procedural generation",
    "softbodies": "Soft bodies", "isosurfaces": "Isosurfaces",
    "boolean_surfaces": "Boolean surfaces", "swarmintelligence": "Swarm intelligence",
    "machinelearning": "Machine learning", "graphtheory": "Graph theory",
    "foundationscrisis": "Foundations crisis", "qfeplaboratory": "QFEP laboratory",
    "postfoundationscrisis": "After foundations",
}
QUESTIONS = {
    "profile_travels": "What stays open when an outline becomes a body?",
    "transformation_order": "What changes when the same operations exchange places?",
    "array_address": "What belongs to the address, and what can change inside it?",
    "tiling_rule": "How far can one small rule travel?",
    "colour_edge": "Can an edge disappear while the geometry stays?",
    "pattern_symmetry": "What returns when one fragment changes?",
    "directional_slope": "Can the same point be uphill and downhill?",
    "force_motion": "What does a force change about a body already moving?",
    "form_relaxation": "Which relations allow a body to settle?",
    "wave_neighbours": "How does a local movement reach another body?",
    "chance_passage": "When does a collection of choices become a place?",
    "noise_layers": "Which smaller variations make this height?",
    "shader_view": "How much of a surface depends on where we stand?",
    "cellular_history": "What happens when we give a past state a place?",
    "menger_twenty": "What does the same removal leave at another scale?",
    "grammar_forward": "Which way is forward after a turn?",
    "branch_decision": "Which requests get a say in the next branch?",
    "cloth_relations": "How can one held point move a whole sheet?",
    "iso_cell": "What surface can we infer between the samples?",
    "boolean_room": "Can a removed volume become a room?",
    "boid_neighbour": "Which neighbours enter this body's next decision?",
    "learning_step": "What does one step down a chosen loss surface achieve?",
    "graph_layout": "What changes when a graph moves but its connections remain?",
    "curvature_triangle": "What does a triangle borrow from its surface?",
    "shannon_threshold": "What changes when the threshold moves but the draws stay?",
    "rhizome_routes": "Does having no named root make the connections equal?",
    "cube_corner": "Which faces share this corner?",
    "door_routes": "How many journeys can reach the same position?",
    "scale_children": "Which parts grow with the room?",
    "body_aperture": "Can the opening follow the approaching body?",
    "gradient_paths": "Can the same endpoints produce different colours between?",
    "rainbow_partitions": "What changes when the same arc receives more bands?",
    "disco_phase": "Which floor cell receives the next turn?",
    "flow_lookup": "Which arrow does this point read next?",
    "torque_purchase": "Where can the same push turn a body?",
    "catenoid_sections": "How does a changing radius build a surface?",
    "circle_projection": "How does a turn become a wave?",
    "prng_register": "What returns when the seed returns?",
    "noise_relief": "What happens when a colour value becomes a distance?",
    "shader_repeat": "Where does the shader start counting again?",
    "ca_triplet": "How do three states decide the next one?",
    "cantor_thirds": "What remains when each middle third leaves?",
    "jelly_skin": "Which connections make the visible skin?",
    "metaball_sum": "Where do two contributions become one surface?",
    "boolean_overlap": "Which volume belongs to both bodies?",
    "spanning_choice": "Which connection adds a route, and which closes a cycle?",
    "foundation_point": "Which frame gives this height its meaning?",
    "foundation_trace": "Which movements enter the record?",
    "foundation_state": "What remains after you leave?",
    "foundation_function": "Which input changes which part of the result?",
    "foundation_array": "What remains when a slot becomes empty?",
    "foundation_class": "Do these two references lead to one state or two?",
}


def load_json(path: Path):
    if not path.is_file():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except (ValueError, OSError):
        return None  # A concurrently written report is still pending.


def relative(path: Path) -> str:
    return os.path.relpath(path, OUT).replace(os.sep, "/")


def resource(path: str) -> dict:
    resolved = ROOT / path.removeprefix("res://")
    return {"label": resolved.name, "path": path, "href": relative(resolved) if resolved.is_file() else None}


def exists_url(path: Path) -> str | None:
    return relative(path) if path.is_file() and path.stat().st_size > 0 else None


def report_status(report, kind: str, asset: bool = True) -> str:
    if not isinstance(report, dict):
        return "pending"
    if kind == "film":
        if "decode_exit" not in report:
            return "pending"
        return "passed" if asset and report.get("decode_exit") == 0 and report.get("frames", 0) > 0 and report.get("bytes", 0) > 0 else "failed"
    if report.get("passed") is False:
        return "failed"
    if report.get("passed") is True and asset:
        return "passed"
    return "pending"


def collect() -> tuple[list[dict], dict]:
    catalog = load_json(CATALOG)
    if not isinstance(catalog, list):
        raise RuntimeError("Film catalog is missing or invalid")
    films = []
    for order, entry in enumerate(catalog, 1):
        folder = OUT / entry["id"]
        stage = load_json(folder / "report.json")
        movie = load_json(folder / "film-report.json")
        museum = load_json(folder / "museum-report.json")
        phases = stage.get("phases", []) if isinstance(stage, dict) else []
        phase_images = []
        for n, path in enumerate(sorted(folder.glob("phase-*.png"))):
            phase_images.append({"src": relative(path), "label": phases[n] if n < len(phases) else f"Phase {n + 1}", "index": n})
        scene = resource(entry["scene"])
        film_url = exists_url(folder / "film.mp4")
        museum_url = exists_url(folder / "museum.png")
        sources = [resource(path) for path in entry.get("source_paths", [])]
        sources.append(scene)
        if entry.get("monitor_scene"):
            sources.append(resource(entry["monitor_scene"]))
        reports = []
        for name, label in [("report.json", "Stage checks"), ("film-report.json", "Video checks"), ("museum-report.json", "Museum checks")]:
            link = exists_url(folder / name)
            if link:
                reports.append({"label": label, "href": link})
        checks = stage.get("checks", []) if isinstance(stage, dict) else []
        failures = [row.get("test", "Unnamed check") for row in checks if isinstance(row, dict) and row.get("passed") is False]
        duration = stage.get("duration") if isinstance(stage, dict) else None
        if isinstance(movie, dict) and movie.get("fps", 0) > 0:
            duration = movie.get("frames", 0) / movie["fps"]
        map_dir = ROOT / "commons/maps" / entry["map"]
        map_links = []
        for name, label in [("map_data.json", "Hall arrangement"), ("final.md", "Reflective text"), ("tutorial.md", "Tutorial")]:
            if (map_dir / name).is_file():
                map_links.append({"label": label, "href": relative(map_dir / name)})
        films.append({**entry, "number": order, "sequence_label": SEQUENCES.get(entry["sequence"], entry["sequence"]),
            "question": QUESTIONS.get(entry["id"], entry["title"]), "poster": exists_url(folder / "poster.png"),
            "video": film_url, "museum": museum_url, "phase_images": phase_images,
            "phase_count": len(phases) or len(phase_images), "duration": duration, "sources": sources,
            "reports": reports, "map_links": map_links, "build": bool(scene["href"]),
            "stage_status": report_status(stage, "stage"),
            "film_status": report_status(movie, "film", bool(film_url)),
            "museum_status": report_status(museum, "museum", bool(museum_url)),
            "check_count": len(checks), "failed_checks": failures,
            "evidence": stage.get("evidence", {}) if isinstance(stage, dict) else {}})
    summary = {"total": len(films), "built": sum(f["build"] for f in films),
        "stages": sum(f["stage_status"] == "passed" for f in films),
        "videos": sum(f["film_status"] == "passed" for f in films),
        "museums": sum(f["museum_status"] == "passed" for f in films),
        "generated": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")}
    return films, summary


TEMPLATE = r'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Operations, made visible — Ada / Endless Museum</title>
<meta name="description" content="Short Godot films reveal the operations inside the Endless Museum's artifacts. Watch each film beside its museum setting and source notes.">
<style>
:root{color-scheme:light;--paper:#f4f1eb;--white:#fffdf9;--ink:#232a2e;--muted:#626b6f;--line:#d8d8d0;--accent:#8b4057;--green:#326752;--dark:#141b24;--mono:ui-monospace,SFMono-Regular,Consolas,monospace;font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;font-synthesis:none}*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:var(--paper);color:var(--ink)}button,input,select{font:inherit}button,a,input,select,summary{touch-action:manipulation}button{cursor:pointer}a{color:var(--accent);text-underline-offset:.22em}button:focus-visible,a:focus-visible,input:focus-visible,select:focus-visible,summary:focus-visible{outline:3px solid #a7647c;outline-offset:4px}button[disabled]{cursor:default;opacity:.38}h1,h2,h3,p{margin:0}p{line-height:1.65}small{font-size:12px}.masthead{padding:25px 36px 21px;border-bottom:1px solid var(--line);display:flex;justify-content:space-between;gap:24px;align-items:center}.wordmark{font-family:Georgia,serif;font-size:36px;letter-spacing:-.055em;line-height:1}.masthead span{display:block;font-size:11px;text-transform:uppercase;letter-spacing:.17em;color:var(--muted);margin-top:8px}.topnote{max-width:385px;font-size:13px;color:var(--muted);text-align:right}.shell{display:grid;grid-template-columns:286px minmax(0,1fr);max-width:1760px;margin:0 auto}.route{border-right:1px solid var(--line);padding:25px 16px 24px 22px;position:sticky;top:0;height:100vh;overflow:auto;scrollbar-width:thin}.eyebrow{font-family:var(--mono);font-size:10px;letter-spacing:.11em;text-transform:uppercase;color:var(--muted)}.route-top{display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;padding:0 9px}.route-count{font-family:var(--mono);font-size:11px;color:var(--muted)}.filters{display:grid;gap:8px;padding:0 5px 18px}.filters label{font-size:11px;color:var(--muted)}.filters input,.filters select{min-width:0;width:100%;padding:10px 11px;border:1px solid var(--line);border-radius:5px;background:var(--white);font-size:12px;color:var(--ink)}.route-list{display:grid;gap:4px}.route-item{border:1px solid transparent;background:none;border-radius:6px;width:100%;text-align:left;display:grid;grid-template-columns:26px 1fr;gap:10px;padding:12px 10px;color:var(--ink)}.route-item:hover{background:#eae7e1}.route-item[aria-current=true]{background:var(--white);border-color:#cbb7bb;box-shadow:0 3px 10px #29242a06}.route-number{font-family:var(--mono);font-size:11px;padding-top:2px;color:#777d7e}.route-copy{min-width:0}.route-copy strong{display:block;font-size:13px;line-height:1.35;font-weight:550}.route-copy span{font-size:10px;letter-spacing:.02em;color:var(--muted);display:block;margin-top:5px}.route-item[aria-current=true] .route-number{color:var(--accent)}.empty-route{font-size:13px;color:var(--muted);padding:15px 10px}.route-footer{margin:25px 10px 0;border-top:1px solid var(--line);padding-top:17px;font-size:11px;line-height:1.6;color:var(--muted)}main{min-width:0;padding:43px clamp(24px,4vw,64px) 56px}.intro{max-width:830px;margin-bottom:29px}.intro h1{font-family:Georgia,"Times New Roman",serif;font-weight:400;letter-spacing:-.045em;font-size:clamp(35px,3.3vw,58px);line-height:1.08;margin:8px 0 16px}.intro p{font-size:14px;color:var(--muted);max-width:700px}.summary{display:flex;gap:10px 22px;flex-wrap:wrap;border-block:1px solid var(--line);padding:13px 0;margin:25px 0 35px;font-size:11px;color:var(--muted)}.summary strong{font-family:var(--mono);color:var(--ink);font-weight:500}.selected-head{display:flex;justify-content:space-between;gap:20px;align-items:flex-end;margin:0 0 20px}.selected-head h2{font-size:clamp(25px,2.6vw,39px);font-weight:500;letter-spacing:-.035em;line-height:1.13;margin-top:10px}.selected-head .question{font-family:Georgia,serif;font-size:20px;line-height:1.4;color:var(--muted);margin-top:13px;max-width:800px}.step-nav{display:flex;gap:7px;flex-shrink:0}.step-nav button{width:36px;height:36px;border:1px solid var(--line);border-radius:50%;background:var(--white);font-size:18px}.theatre{background:var(--dark);border:1px solid #202b35;border-radius:8px;overflow:hidden;margin:0}.theatre video{width:100%;aspect-ratio:16/9;display:block;background:var(--dark)}.theatre .still{width:100%;aspect-ratio:16/9;object-fit:contain;display:block}.pending-view{aspect-ratio:16/9;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:13px;color:#aebbc8;padding:30px;text-align:center}.pending-view strong{font-family:Georgia,serif;font-size:28px;font-weight:400;color:#dedbd8}.theatre figcaption{border-top:1px solid #2b3743;padding:13px 18px;color:#bbc7d2;display:flex;align-items:center;justify-content:space-between;gap:15px;font-size:11px;line-height:1.5}.theatre a{color:#efbccd}.status-dot{display:inline-block;width:6px;height:6px;border-radius:50%;background:currentColor;margin:0 7px 1px 0}.theatre .verified{color:#b4d8c5}.theatre .pending{color:#c8ba9e}.theatre .failed{color:#ffbab2}.description{font-size:15px;max-width:875px;margin:22px 0 0;line-height:1.75}.phase-strip{display:grid;grid-template-columns:repeat(auto-fit,minmax(135px,1fr));gap:12px;margin-top:22px}.phase-card{min-width:0}.phase-card a{display:block;border-radius:4px;overflow:hidden;border:1px solid var(--line);background:var(--dark)}.phase-card img{display:block;width:100%;aspect-ratio:16/9;object-fit:cover}.phase-card div{padding:9px 1px 0;font-size:11px;color:var(--muted);line-height:1.5}.phase-card b{font-family:var(--mono);font-size:10px;font-weight:400;color:var(--accent);margin-right:7px}.phase-card button{font-size:10px;background:none;border:0;color:var(--accent);padding:5px 0;text-decoration:underline;text-underline-offset:3px}.section-label{font-size:11px;letter-spacing:.1em;text-transform:uppercase;color:var(--muted);font-weight:500;margin-bottom:13px}.context-grid{display:grid;grid-template-columns:minmax(0,1.35fr) minmax(260px,1fr);gap:26px;margin-top:35px;padding-top:30px;border-top:1px solid var(--line)}.museum-figure{margin:0}.museum-figure img{display:block;width:100%;aspect-ratio:16/9;object-fit:cover;border-radius:5px;border:1px solid var(--line)}.museum-figure figcaption{font-size:11px;color:var(--muted);line-height:1.6;margin-top:10px}.museum-pending{border:1px dashed #c1c5c1;border-radius:5px;aspect-ratio:16/9;display:flex;align-items:center;justify-content:center;padding:24px;color:var(--muted);font-size:13px;text-align:center}.hall-name{font-family:var(--mono);font-size:11px;overflow-wrap:anywhere;line-height:1.7;display:block;margin:4px 0 13px}.limit-note{font-size:13px;line-height:1.65;color:var(--muted)}.link-row{display:flex;flex-wrap:wrap;gap:8px 16px;margin-top:17px;font-size:11px}.context-note{font-size:12px;color:var(--muted);margin-top:20px;line-height:1.65}.evidence-panel{margin-top:28px;border:1px solid var(--line);border-radius:6px;background:#ffffff45}.evidence-panel summary{cursor:pointer;display:flex;align-items:center;justify-content:space-between;gap:15px;padding:17px 19px;font-size:12px;list-style:none}.evidence-panel summary::-webkit-details-marker{display:none}.evidence-panel summary::after{content:"+";font-size:20px;color:var(--muted)}.evidence-panel[open] summary::after{content:"−"}.evidence-content{padding:0 19px 20px}.verification{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;padding:3px 0 18px;border-bottom:1px solid var(--line)}.verification div{padding:8px 0;display:flex;flex-direction:column;gap:6px}.verification span{font-size:10px;color:var(--muted)}.verification strong{font-size:11px;font-weight:550}.passed{color:var(--green)}.failed{color:#aa3434}.pending{color:#87734a}.sources{display:grid;gap:9px;margin-top:19px}.sources a{font-family:var(--mono);font-size:11px;overflow-wrap:anywhere}.source-path{font-size:10px;color:var(--muted);overflow-wrap:anywhere;margin-top:3px}.reports{padding-top:14px}.record{font-family:var(--mono);font-size:10px;line-height:1.6;white-space:pre-wrap;word-break:break-word;color:var(--muted);max-height:230px;overflow:auto;background:var(--paper);padding:12px;border-radius:4px;margin-top:16px}.footer{border-top:1px solid var(--line);margin-top:38px;padding-top:19px;display:flex;justify-content:space-between;gap:20px;color:var(--muted);font-size:11px;line-height:1.65}.footer span{max-width:630px}.screen-reader{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}.skip{position:absolute;left:20px;top:-70px;padding:12px 18px;background:var(--white);z-index:9}.skip:focus{top:10px}.noscript{display:grid;gap:24px}.noscript article{border-top:1px solid var(--line);padding-top:25px}.noscript h2{margin-bottom:10px}.noscript img{width:100%;max-width:800px;margin:15px 0}.noscript p{margin-top:10px;font-size:13px}.noscript video{width:100%;max-width:800px}dialog{border:0;border-radius:8px;padding:0;background:var(--dark);color:white;max-width:94vw}dialog::backdrop{background:#101820c9}@media(min-width:1800px){.masthead{padding-inline:max(36px,calc((100vw - 1688px)/2))}}@media(max-width:1000px){.shell{grid-template-columns:230px minmax(0,1fr)}.route{padding-left:12px;padding-right:10px}main{padding:35px 24px}.context-grid{grid-template-columns:1fr}.intro h1{font-size:42px}.verification{grid-template-columns:repeat(2,1fr)}}@media(max-width:700px){.masthead{padding:20px}.wordmark{font-size:30px}.topnote{display:none}.shell{display:block}.route{position:relative;height:auto;max-height:none;border-right:0;border-bottom:1px solid var(--line);padding:20px}.route-top{padding:0}.filters{grid-template-columns:1fr 1fr;padding:0 0 13px}.route-list{display:flex;overflow-x:auto;gap:8px;padding:0 0 8px}.route-item{min-width:215px;max-width:215px}.route-footer{display:none}main{padding:29px 20px 38px}.intro h1{font-size:38px}.intro p{font-size:13px}.summary{gap:9px 17px;margin-bottom:26px}.selected-head{align-items:flex-start}.selected-head h2{font-size:28px}.selected-head .question{font-size:18px}.step-nav{padding-top:23px}.step-nav button{width:31px;height:31px}.phase-strip{grid-template-columns:repeat(2,1fr)}.context-grid{margin-top:28px;padding-top:24px}.theatre figcaption{align-items:flex-start;font-size:10px}.footer{display:block}.footer time{display:block;margin-top:12px}}@media(prefers-reduced-motion:reduce){html{scroll-behavior:auto}}@media print{.route,.filters,.step-nav,.phase-card button,.masthead,.summary,.footer{display:none}.shell{display:block}main{padding:0}.theatre{break-inside:avoid}.evidence-panel{display:block}.intro{margin-bottom:20px}.context-grid{grid-template-columns:1fr 1fr}.phase-strip{grid-template-columns:repeat(4,1fr)}body{background:white}}
</style></head><body>
<a class="skip" href="#film-detail">Skip to the film</a>
<header class="masthead"><div class="wordmark">ada<span>Endless Museum / Construction films</span></div><p class="topnote">A body is present. A short film opens the operations that make it possible.</p></header>
<div class="shell"><aside class="route" aria-label="Museum film route"><div class="route-top"><span class="eyebrow">Walk the spine</span><span class="route-count" id="route-count">__COUNT__ films</span></div>
<div class="filters"><div><label class="screen-reader" for="search">Search films, halls or operations</label><input id="search" type="search" placeholder="Find a film or operation" autocomplete="off"></div><div><label class="screen-reader" for="sequence">Filter by sequence</label><select id="sequence"><option value="">All sequences</option></select></div></div>
<div class="filters"><label for="collection">Collection</label><select id="collection"><option value="">All films</option><option value="more">The 20 additional films</option><option value="foundation">Six foundation studies · interactive monitors</option></select></div>
<nav class="route-list" id="route-list" aria-label="Films in spine order"></nav><p class="route-footer">The numbering follows the museum spine. Select a film, then use its native playback controls to pause, replay or inspect a moment.</p></aside>
<main><section class="intro"><div class="eyebrow">__COUNT__ short films / built in Godot</div><h1>Operations, made visible.</h1><p>Watch a form assemble, a rule travel, or a relation change. These camera views come from separate 3D stages built around the museum’s existing source code. Each film is shown beside its hall and the limits of its demonstration.</p></section>
<div class="summary" aria-label="Current build and verification summary"><span><strong>__BUILT__/__COUNT__</strong> scenes built</span><span><strong>__STAGES__/__COUNT__</strong> stages checked</span><span><strong>__VIDEOS__/__COUNT__</strong> videos checked</span><span><strong>__MUSEUMS__/__COUNT__</strong> museum views checked</span></div>
<div id="film-detail" tabindex="-1" aria-label="Selected film"><p>Choose a film from the museum route.</p></div>
<noscript><p>This page also works as a reading list. Enable JavaScript for filtering and the selected-film view.</p><div class="noscript">__FALLBACK__</div></noscript>
<footer class="footer"><span>Verification describes the saved desktop checks and captures. Headset readability, reach and performance remain to be tested.</span><time>Evidence snapshot<br>__GENERATED__</time></footer>
</main></div><div class="screen-reader" id="announcement" aria-live="polite"></div>
<script id="film-data" type="application/json">__DATA__</script>
<script>
'use strict';
const DATA=JSON.parse(document.getElementById('film-data').textContent);
const films=DATA.films, route=document.getElementById('route-list'), search=document.getElementById('search'), sequence=document.getElementById('sequence'), collection=document.getElementById('collection'), detail=document.getElementById('film-detail');
const esc=value=>String(value??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
collection.value=new URLSearchParams(location.hash.slice(1)).get('collection')||'';
let selected=films[0].id;
const unique=new Map(films.map(f=>[f.sequence,f.sequence_label]));
for(const [value,label] of unique){const option=document.createElement('option');option.value=value;option.textContent=label;sequence.append(option);}
function filtered(){const words=search.value.trim().toLocaleLowerCase().split(/\s+/).filter(Boolean);return films.filter(f=>(!collection.value||f.collection===collection.value)&&(!sequence.value||sequence.value===f.sequence)&&words.every(w=>[f.title,f.question,f.map,f.description,f.sequence_label].join(' ').toLocaleLowerCase().includes(w)));}
function renderRoute(){const shown=filtered();document.getElementById('route-count').textContent=`${shown.length} / ${films.length}`;route.innerHTML=shown.map(f=>`<button class="route-item" data-film="${esc(f.id)}" aria-current="${f.id===selected}"><span class="route-number">${String(f.number).padStart(2,'0')}</span><span class="route-copy"><strong>${esc(f.title)}</strong><span>${esc(f.sequence_label)}${f.collection==='foundation'?' · Interactive study':f.collection==='more'?' · Additional':''}</span></span></button>`).join('')||'<p class="empty-route">No films match. Try another operation or sequence.</p>';}
function stateLabel(status,success){return status==='passed'?success:status==='failed'?'Needs attention':'Pending';}
function links(rows){return rows.map(x=>`<a href="${esc(x.href)}">${esc(x.label)}</a>`).join('');}
function renderFilm(f){
 const prior=detail.querySelector('video');if(prior){prior.pause();prior.removeAttribute('src');prior.load();}
 const shown=filtered(), filteredIndex=shown.findIndex(x=>x.id===f.id), duration=f.duration?`${Number(f.duration).toFixed(1)} seconds`:'';
 const media=f.video?`<video id="film-video" controls playsinline preload="none" ${f.poster?`poster="${esc(f.poster)}"`:''} src="${esc(f.video)}" aria-label="${esc(f.title)} — Godot construction film">Your browser cannot play this film. <a href="${esc(f.video)}">Open the video</a>.</video>`:f.poster?`<img class="still" src="${esc(f.poster)}" alt="Godot stage capture: ${esc(f.title)}"><span class="screen-reader">The video is not yet available.</span>`:'<div class="pending-view"><strong>The stage is built.</strong><span>Its render is still being prepared.</span></div>';
 const movieState=f.video?stateLabel(f.film_status,'Rendered and decode checked'):'Video render pending';
 const stageSummary=f.stage_status==='passed'?`${f.check_count} stage checks passed`:f.stage_status==='failed'?'Stage checks need attention':'Stage checks pending';
 const phases=f.phase_images.length?`<div class="phase-strip" aria-label="Construction phases">${f.phase_images.map(p=>`<div class="phase-card"><a href="${esc(p.src)}" aria-label="Open ${esc(p.label)} still"><img src="${esc(p.src)}" alt="${esc(p.label)} — ${esc(f.title)}" loading="lazy"></a><div><b>${String(p.index+1).padStart(2,'0')}</b>${esc(p.label)}</div>${f.video?`<button data-seek="${p.index}" aria-label="Seek to ${esc(p.label)}">Watch this phase</button>`:''}</div>`).join('')}</div>`:'';
 const museum=f.museum?`<a href="${esc(f.museum)}" aria-label="Open the museum screenshot"><img src="${esc(f.museum)}" alt="The ${esc(f.title)} monitor inside ${esc(f.map)}" loading="lazy"></a>`:'<div class="museum-pending">Museum screenshot pending.</div>';
 const evidence=Object.keys(f.evidence).length?`<details><summary style="padding:16px 0 0;font-size:11px">Source-specific record</summary><pre class="record">${esc(JSON.stringify(f.evidence,null,2))}</pre></details>`:'';
 detail.innerHTML=`<section aria-labelledby="selected-title"><div class="selected-head"><div><div class="eyebrow">${String(f.number).padStart(2,'0')} / ${esc(f.sequence_label)}</div><h2 id="selected-title">${esc(f.title)}</h2><p class="question">${esc(f.question)}</p></div><div class="step-nav"><button data-move="-1" aria-label="Previous matching film" ${filteredIndex<=0?'disabled':''}>←</button><button data-move="1" aria-label="Next matching film" ${filteredIndex<0||filteredIndex>=shown.length-1?'disabled':''}>→</button></div></div><figure class="theatre">${media}<figcaption><span class="${f.film_status==='passed'?'verified':f.film_status}"><i class="status-dot" aria-hidden="true"></i>${esc(movieState)}${duration?' · '+duration:''}</span>${f.video?`<a href="${esc(f.video)}">Open film ↗</a>`:'<span>Native Godot scene available below</span>'}</figcaption></figure><p class="description">${esc(f.description)}</p>${f.collection==='foundation'?'<p class="context-note">In the museum, the lower row lets you try the comparison. A change pauses the demonstration and keeps your state. DEMO starts the demonstration again. This page shows a recording of the native 3D scene.</p>':''}${phases}<div class="context-grid"><div><h3 class="section-label">Inside the museum</h3><figure class="museum-figure">${museum}<figcaption>${esc(stateLabel(f.museum_status,'Desktop museum placement checked'))}. ${esc(f.map)}</figcaption></figure></div><div><h3 class="section-label">What this film can show</h3><p class="limit-note">${esc(f.limitation)}</p><p class="context-note">The hall belongs to ${esc(f.sequence_label)}.</p><span class="hall-name">${esc(f.map)}</span><div class="link-row">${links(f.map_links)}</div></div></div><details class="evidence-panel"><summary><span>Sources & verification <span style="color:var(--muted);margin-left:8px">${esc(stageSummary)}</span></span></summary><div class="evidence-content"><div class="verification"><div><span>Native scene</span><strong class="${f.build?'passed':'pending'}">${f.build?'Built':'Pending'}</strong></div><div><span>Stage / controls</span><strong class="${f.stage_status}">${esc(stateLabel(f.stage_status,'Checked'))}</strong></div><div><span>Rendered video</span><strong class="${f.film_status}">${esc(stateLabel(f.film_status,'Decode checked'))}</strong></div><div><span>Museum placement</span><strong class="${f.museum_status}">${esc(stateLabel(f.museum_status,'Desktop checked'))}</strong></div></div>${f.failed_checks.length?`<p class="context-note failed">${esc(f.failed_checks.join('; '))}</p>`:''}<div class="sources">${f.sources.map(s=>`<div>${s.href?`<a href="${esc(s.href)}">${esc(s.label)}</a>`:`<span>${esc(s.label)} — unavailable</span>`}<div class="source-path">${esc(s.path.replace('res://',''))}</div></div>`).join('')}</div><div class="link-row reports">${links(f.reports)}</div>${evidence}</div></details></section>`;
 document.getElementById('announcement').textContent=`${f.number} of ${films.length}: ${f.title}`;
 const video=detail.querySelector('video');if(video){video.addEventListener('error',()=>{const caption=detail.querySelector('.theatre figcaption span');caption.textContent='The browser could not load the film. Use Open film or refresh this generated page.';caption.className='failed';});}
}
function selectFilm(id,changeHash=true){const f=films.find(x=>x.id===id)||films[0];selected=f.id;renderRoute();renderFilm(f);if(changeHash)history.replaceState(null,'','#film='+encodeURIComponent(f.id)+(collection.value?'&collection='+encodeURIComponent(collection.value):''));}
function move(direction){const shown=filtered(),i=shown.findIndex(f=>f.id===selected),next=shown[i+direction];if(next)selectFilm(next.id);}
function readHash(){const args=new URLSearchParams(location.hash.slice(1));return args.get('film')||(collection.value?films.find(f=>f.collection===collection.value)?.id:null)||films[0].id;}
route.addEventListener('click',e=>{const button=e.target.closest('[data-film]');if(button)selectFilm(button.dataset.film);});
detail.addEventListener('click',e=>{const moveButton=e.target.closest('[data-move]');if(moveButton){move(Number(moveButton.dataset.move));return;}const seek=e.target.closest('[data-seek]');if(seek){const f=films.find(x=>x.id===selected),video=detail.querySelector('video'),target=Number(seek.dataset.seek)*(f.duration||24)/Math.max(f.phase_count,1);if(video.readyState>=1)video.currentTime=Math.min(target,Math.max(0,video.duration-.05));else{video.addEventListener('loadedmetadata',()=>{video.currentTime=Math.min(target,Math.max(0,video.duration-.05));},{once:true});video.load();}}});
function applyFilters(){renderRoute();const shown=filtered();if(shown.length&&!shown.some(f=>f.id===selected))selectFilm(shown[0].id);else renderFilm(films.find(f=>f.id===selected));}
search.addEventListener('input',applyFilters);sequence.addEventListener('change',applyFilters);collection.addEventListener('change',applyFilters);
window.addEventListener('hashchange',()=>{collection.value=new URLSearchParams(location.hash.slice(1)).get('collection')||'';selectFilm(readHash(),false);});
document.addEventListener('visibilitychange',()=>{if(document.hidden)detail.querySelector('video')?.pause();});
document.addEventListener('keydown',e=>{if(e.target.closest('input,select,textarea,video')||e.altKey||e.ctrlKey||e.metaKey)return;if(e.key==='ArrowRight'){e.preventDefault();move(1);}if(e.key==='ArrowLeft'){e.preventDefault();move(-1);}});
selectFilm(readHash(),false);
</script></body></html>
'''


def fallback(films: list[dict]) -> str:
    result = []
    for film in films:
        e = html.escape
        movie = f'<video controls preload="none" src="{e(film["video"])}"' + (f' poster="{e(film["poster"])}"' if film["poster"] else "") + '></video>' if film["video"] else (f'<img src="{e(film["poster"])}" alt="{e(film["title"])}" loading="lazy">' if film["poster"] else "")
        result.append(f'<article id="reading-{e(film["id"])}"><div class="eyebrow">{film["number"]:02d} / {e(film["sequence_label"])}</div><h2>{e(film["title"])}</h2>{movie}<p>{e(film["description"])}</p><p>{e(film["limitation"])}</p></article>')
    return "\n".join(result)


class PageParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.ids = []
        self.links = []
        self.videos = 0
        self.bad_preload = []

    def handle_starttag(self, tag, attrs):
        row = dict(attrs)
        if "id" in row:
            self.ids.append(row["id"])
        for name in ("href", "src", "poster"):
            if row.get(name):
                self.links.append(row[name])
        if tag == "video":
            self.videos += 1
            if row.get("preload") != "none":
                self.bad_preload.append(row)


def validate(page: str, films: list[dict]) -> dict:
    parser = PageParser()
    parser.feed(page)
    errors = []
    if len(parser.ids) != len(set(parser.ids)):
        errors.append("Duplicate HTML id")
    if parser.bad_preload:
        errors.append("A fallback video does not use preload=none")
    links = parser.links[:]
    for film in films:
        links.extend(x for x in [film["poster"], film["video"], film["museum"]] if x)
        links.extend(x["src"] for x in film["phase_images"])
        links.extend(x["href"] for key in ["sources", "reports", "map_links"] for x in film[key] if x.get("href"))
    for link in set(links):
        parts = urlsplit(link)
        if parts.scheme or parts.netloc:
            errors.append("Nonlocal link: " + link)
        elif not parts.path:
            if parts.fragment and parts.fragment not in parser.ids:
                errors.append("Missing fragment: " + link)
        elif not (OUT / unquote(parts.path)).resolve().is_file():
            errors.append("Missing linked file: " + link)
    if len(films) != len({film["id"] for film in films}):
        errors.append("Duplicate catalog film")
    if errors:
        raise RuntimeError("Review page QA failed:\n" + "\n".join(errors))
    return {"films": len(films), "unique_links_checked": len(set(links)), "html_ids": len(parser.ids), "failures": errors}


def main():
    films, summary = collect()
    payload = json.dumps({"films": films, "summary": summary}, ensure_ascii=False).replace("<", "\\u003c")
    substitutions = {"__DATA__": payload, "__FALLBACK__": fallback(films), "__COUNT__": str(summary["total"]),
        "__BUILT__": str(summary["built"]), "__STAGES__": str(summary["stages"]),
        "__VIDEOS__": str(summary["videos"]), "__MUSEUMS__": str(summary["museums"]), "__GENERATED__": summary["generated"]}
    page = TEMPLATE
    for key, value in substitutions.items():
        page = page.replace(key, value)
    qa = validate(page, films)
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "index.html").write_text(page, encoding="utf-8")
    print(json.dumps({"page": str(OUT / "index.html"), "summary": summary, "qa": qa}, indent=2))


if __name__ == "__main__":
    main()
