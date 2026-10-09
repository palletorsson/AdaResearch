"""Publish a bounded tutorial revision, with unchanged archival museum captures."""
from pathlib import Path
from hashlib import sha256
from html import escape
from urllib.parse import quote
import difflib
import json
import re
import shutil
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]


def picture(source, name, date, caption, evidence):
    return dict(source=source, file=f"figures/{name}", date=date,
                caption=caption, evidence=evidence, kind="Existing museum capture")


HALLS = [
    dict(map="Point_Coordinates", title="Carry a position", topics=["Pickup / release"],
         before="The lesson already followed the black sphere and compared local with world coordinates. Release was mentioned without explaining what happens to the body.",
         change="Keep that focus. Explain that releasing ends the hold and restores this point's frozen state. The sphere stays in the room; its own held-state guide disappears.",
         exercise="Disable pickup, restore it, choose another starting position, then carry and release the point while naming each coordinate frame.",
         carry="A held body and a position can be connected without treating the hand, mesh, collider and coordinate frame as one thing.",
         sources=["commons/primitives/point/point_condition.gd", "commons/primitives/point/interactive_point_origin.gd", "commons/primitives/point/interactive_point_origin.tscn", "addons/godot-xr-tools/objects/pickable.gd", "algorithms/vectors/00_coordinates/CoordinateSystem3M.gd"],
         images=[picture("doc/book/iterations/2026-10-03-coordinates-existing-point/held-point.png", "coordinates.png", "2026-10-03", "The black held point is in the foreground. Its coordinate frame and LOCAL readout remain in the room.", "doc/book/iterations/2026-10-03-coordinates-existing-point/source_manifest.json")]),
    dict(map="Point_Trace", title="A grip, a tip, a retained line", topics=["Grip alignment"],
         before="The earlier lesson taught a portable starter and a different persistence arrangement. The museum pen's grip and shaped, cumulative record were not the teaching host.",
         change="Follow the existing red pen: movement gate, shaped world position, ordered list and neighbour traversal. Distinguish WritingGrip from WritingTip; release copies the retained record into session storage.",
         exercise="Move the grip three centimetres towards the nib, compare the held reach with each hand, then restore it. Draw and release a bend for Grid.",
         carry="A relation between hand and tool, and the student's cumulative ordered drawing. The list is bounded and lasts for this game session.",
         sources=["commons/primitives/point/draw_dot.gd", "commons/primitives/point/draw_dot.tscn", "commons/primitives/point/drawing_pen.gd", "commons/primitives/point/player_trace.gd", "commons/globals/trace_data.gd"],
         images=[picture("doc/book/iterations/2026-09-29-trace-clean-room/clean-hall.png", "trace.png", "2026-09-29", "The museum's pens and plinth readouts. The lesson follows the red pen and its retained positions; the other exhibits remain part of the encounter.", "doc/book/iterations/2026-09-29-trace-clean-room/source_manifest.json")]),
    dict(map="Point_Line_Grid", title="One record, another spacing", topics=["Snapping"],
         before="The starter-based account rounded source coordinates before display fitting and described persistence across runs.",
         change="Use the actual museum handoff: preserve the released world-position list, fit it for the display, then snap XYZ display positions. An index names a sample; a spatial address names a place.",
         exercise="Set three display subdivisions before starting a new run. Draw and release a fresh trace; compare its fitted pink and snapped green versions beside the unchanged source rows.",
         carry="Source and derived data remain separate. Snapping here is coordinate quantization, not an XR docking zone; finer pitch cannot recover unrecorded movement.",
         sources=["commons/globals/trace_data.gd", "commons/primitives/line/grid_lines.gd", "commons/primitives/line/grid_lines.tscn"],
         images=[picture("doc/book/iterations/2026-09-21-interface-spine-primitives-review/after-grid-encounter.png", "grid.png", "2026-09-21", "The ruled basin, pink and green trace display, and source readout inside the museum. This older capture includes an earlier plinth design.", "doc/book/iterations/2026-09-21-interface-spine-primitives-review/sources.json"),
                 picture("doc/book/iterations/2026-09-21-interface-spine-primitives-review/after-grid-reading.png", "grid-reading.png", "2026-09-21", "The panel separates source world positions from the centred, scaled display and its 0.1667 m snap pitch. This is an archived demonstration record.", "doc/book/iterations/2026-09-21-interface-spine-primitives-review/after-grid-checks.json")]),
    dict(map="Trans_Introduction", title="Ask the bank to move", topics=["Interaction states", "Feedback"],
         before="The intended event/reset focus was not yet anchored to the installed MOVE THE BANK controls.",
         change="Trace the slider and RESET signals into one shared setter. Separate requested from current displacement; explain the physics update and feedback of actual motion.",
         exercise="Double SPEED and predict a full journey of about two seconds instead of four. RESET returns gradually to the same home position. Restore the original value.",
         carry="A request can change immediately while the body takes time to fulfil it. A readout must say which state it reports.",
         sources=["commons/artifacts/adjustable_landing/adjustable_landing.gd", "commons/interactables/slider_horizontal.gd", "commons/audio/rack_templates/RackTemplates.gd"],
         images=[picture("doc/book/iterations/2026-09-27-crossings-fire-and-fit/bank-control-close.png", "bank.png", "2026-09-28", "MOVE THE BANK and its readout beside the crossing, captured in the Endless Museum. The triangulated floor belongs to this hall's existing scene.", "doc/book/iterations/2026-09-27-crossings-fire-and-fit/source_manifest.json")]),
    dict(map="Color_Paint", title="Aim, activate, leave a mark", topics=["Named actions", "Interaction states", "Targeting", "Feedback", "Surface painting"],
         before="The automatic UV path led the lesson. The hand's route from pickup through activation to a valid receiving surface was secondary.",
         change="Start with the manual can. Distinguish trigger_click events from trigger pressure, held from active, and mist from a successful hit. Convert world hit to local surface UV and return to the shared draw_spray method.",
         exercise="Halve manual spray reach. From beyond and within that range, predict when mist becomes a canvas deposit; restore the original reach.",
         carry="A reusable input-to-receiver chain. Manual and automatic callers share an operation, while the image they alter is not a recoverable list of gestures.",
         sources=["commons/context/drawingboard/spray_can.gd", "commons/context/drawingboard/paper_draw_surface.gd", "commons/context/drawingboard/ball_painting_automation.gd", "commons/context/drawingboard/ball_painting_demo_v2.tscn", "addons/godot-xr-tools/functions/function_pickup.gd", "openxr_action_map.tres"],
         images=[picture("doc/book/iterations/2026-09-28-paint-aerosol-and-runs/shared-aerosol.png", "paint.png", "2026-09-28", "The manual cans, their tray and shared canvas in the museum. Mist, deposits and accumulated colour are different stages of the interaction.", "doc/book/iterations/2026-09-28-paint-aerosol-and-runs/source_manifest.json")]),
]

TOPICS = [
    ("Pickup / release", "Point_Coordinates", "Separate the body from its connection to the hand; release restores this sphere's frozen state."),
    ("Grip alignment", "Point_Trace", "Move the grip relative to the nib, keeping the recorded tip explicit."),
    ("Named actions", "Color_Paint", "Follow trigger_click press/release and trigger pressure through the supplied input route."),
    ("Interaction states", "Trans_Introduction", "Introduce target/current state; Paint returns to held, active and receiving states."),
    ("Targeting", "Color_Paint", "Follow the nozzle ray, first eligible collision, receiving surface and range checks."),
    ("Snapping", "Point_Line_Grid", "Round fitted display coordinates in XYZ while preserving the source drawing."),
    ("Feedback", "Trans_Introduction", "Read actual bank motion; Paint distinguishes valve feedback from successful deposition."),
    ("Surface painting", "Color_Paint", "Convert a world hit into surface UV and call the existing shared drawing operation."),
]


def render(text):
    return markdown.markdown(text, extensions=["fenced_code", "tables"])


def source_link(path):
    return "../../../../" + quote(path, safe="/")


def main():
    for folder in ["figures", "after", "diffs"]:
        (HERE / folder).mkdir(exist_ok=True)
    intro = "Eight interaction topics are now taught through five existing halls. Each lesson selects a small operation, names the supplied machinery and carries a usable distinction onward. The complete revised tutorial text follows each hall image."
    method = "This pass changes tutorial.md and its teaching metadata. It leaves final.md and museum runtime code intact. The images are earlier captures from inside the Endless Museum, with dates and provenance; they are not new playtests. Student code edits are exercises described in the lessons, not changes applied to the museum. Source reading supports the explanations; hands-on learning and headset comfort still need a trial."
    md = ["# Eight interactions through the museum", "", "5 October 2026 · Five revised tutorials", "", intro, "", method, "", "## The eight topics", "", "| Topic | Hall | Teaching choice |", "|---|---|---|"]
    rows = []
    for topic, hall, choice in TOPICS:
        md.append(f"| {topic} | {hall} | {choice} |")
        rows.append(f"<tr><th scope='row'>{escape(topic)}</th><td><a href='#{hall}'>{escape(hall.replace('_',' '))}</a></td><td>{escape(choice)}</td></tr>")
    nav = []
    sections = []
    for number, h in enumerate(HALLS, 1):
        map_id = h["map"]
        live = ROOT / "commons/maps" / map_id / "tutorial.md"
        before = (HERE / "before" / f"{map_id}.md").read_text(encoding="utf-8-sig")
        after = live.read_text(encoding="utf-8-sig")
        shutil.copy2(live, HERE / "after" / f"{map_id}.md")
        diff = "".join(difflib.unified_diff(before.splitlines(keepends=True), after.splitlines(keepends=True), fromfile=f"before/{map_id}.md", tofile=f"after/{map_id}.md"))
        (HERE / "diffs" / f"{map_id}.diff").write_text(diff, encoding="utf-8")
        h["tutorial_sha256"] = sha256(live.read_bytes()).hexdigest()
        h["words"] = len(after.split())
        h["subjects"] = re.findall(r"^- (.+)$", after.split("**Learning elements**",1)[1].split("\n\n",2)[1], re.M)
        h["source_hashes"] = {s: sha256((ROOT/s).read_bytes()).hexdigest() for s in h["sources"]}
        figures = []
        md += ["", f"## {number}. {map_id} — {h['title']}", "", f"**Before:** {h['before']}", "", f"**Changed:** {h['change']}", "", f"**Try:** {h['exercise']}", "", f"**Carries forward:** {h['carry']}", ""]
        for img in h["images"]:
            assert (ROOT/img["evidence"]).exists(), img["evidence"]
            shutil.copy2(ROOT/img["source"], HERE/img["file"])
            img["sha256"] = sha256((HERE/img["file"]).read_bytes()).hexdigest()
            caption = f"{img['caption']} Archive: {img['date']}."
            figures.append(f"<figure><a href='{img['file']}'><img src='{img['file']}' alt='{escape(img['caption'], quote=True)}' loading='lazy'></a><figcaption>{escape(caption)} <a href='{source_link(img['evidence'])}'>Capture record</a></figcaption></figure>")
            md += [f"![{img['caption']}]({img['file']})", "", caption, ""]
        sources = "".join(f"<li><a href='{source_link(s)}'>{escape(s)}</a></li>" for s in h["sources"])
        live_url = source_link(f"commons/maps/{map_id}/tutorial.md")
        prev = f"<a href='#{HALLS[number-2]['map']}'>← Previous hall</a>" if number > 1 else "<a href='#overview'>← Overview</a>"
        nxt = f"<a href='#{HALLS[number]['map']}'>Next hall →</a>" if number < len(HALLS) else "<a href='#overview'>Back to overview ↑</a>"
        nav.append(f"<a href='#{map_id}'><small>0{number}</small>{escape(map_id.replace('_',' '))}</a>")
        # The canonical lesson is embedded verbatim in a separate reading area.
        lesson_html = render(after).replace("<h1>", "<h3>").replace("</h1>", "</h3>").replace("<h2>", "<h4>").replace("</h2>", "</h4>")
        sections.append(f"""<section class='hall' id='{map_id}'>
          <header><p class='eyebrow'>0{number} / {escape(map_id)}</p><h2>{escape(h['title'])}</h2><p class='topics'>{escape(' · '.join(h['topics']))}</p></header>
          {''.join(figures)}
          <div class='change'><p><b>Changed.</b> {escape(h['change'])}</p><p><b>Try.</b> {escape(h['exercise'])}</p><p><b>Carries forward.</b> {escape(h['carry'])}</p></div>
          <div class='reading'><p class='eyebrow'>NEW TUTORIAL · {h['words']} words · <a href='{live_url}'>Open current tutorial.md</a></p>{lesson_html}</div>
          <details><summary>Before this pass and exact text changes</summary><p>{escape(h['before'])}</p><p><a href='before/{map_id}.md'>Before</a> · <a href='after/{map_id}.md'>Revised snapshot</a> · <a href='diffs/{map_id}.diff'>Text diff</a></p><pre class='diff'>{escape(diff)}</pre></details>
          <details><summary>Inspected museum sources</summary><ul class='sources'>{sources}</ul></details>
          <footer>{prev}{nxt}</footer></section>""")
        md += ["### New tutorial text", "", after.replace("# ", "### ", 1), "", f"[Before](before/{map_id}.md) · [Exact changes](diffs/{map_id}.diff) · [Current tutorial]({live_url})", ""]
    css = """*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:24px}body{margin:0;background:#f4f1ea;color:#292b2d;font:16px/1.65 system-ui,sans-serif}a{color:inherit;text-underline-offset:4px}a:focus-visible,summary:focus-visible{outline:3px solid #c04775;outline-offset:4px}nav{position:fixed;width:250px;inset:0 auto 0 0;padding:36px 22px;background:#242a2c;color:#f7f3e9;overflow:auto}nav>p{font:24px/1.25 Georgia,serif;margin-bottom:30px}nav a{display:block;text-decoration:none;padding:13px 0;border-top:1px solid #50565a;font-size:13px}nav small{display:block;color:#dda2b6;letter-spacing:.15em}nav .meta{font-size:11px;color:#c0c2bd;margin-top:32px}main{margin-left:250px;padding:54px 5vw;max-width:1550px}h1,h2,h3{font-family:Georgia,serif;font-weight:400;line-height:1.14;letter-spacing:-.025em}h1{font-size:clamp(40px,5vw,76px);max-width:13ch;margin:20px 0}h2{font-size:clamp(32px,4vw,53px);margin:10px 0}h3{font-size:32px}h4{font-size:21px;line-height:1.3;margin:32px 0 14px}.eyebrow{font-size:11px;letter-spacing:.12em;text-transform:uppercase;color:#726565}.lead{font:23px/1.5 Georgia,serif;max-width:58ch}.method{max-width:86ch;font-size:13px;color:#63666a;border-left:3px solid #c69bae;padding-left:18px;margin:28px 0 42px}table{border-collapse:collapse;width:100%;font-size:13px;margin:32px 0 48px}th,td{text-align:left;vertical-align:top;padding:13px;border-bottom:1px solid #d6d0c9}th{font-weight:600}table th:first-child{min-width:145px}.hall{border-top:2px solid #3b4445;padding-top:32px;margin-top:70px}.topics{color:#934563;font-size:14px}figure{margin:28px 0}figure img{width:100%;height:auto;display:block;background:#262c33}figcaption{font-size:12px;line-height:1.55;color:#696766;margin-top:10px;max-width:95ch}.change{padding:18px 28px;background:#ebe5db;border-left:3px solid #ab7a8d;font-size:14px}.change p{margin:12px 0}.reading{max-width:77ch;margin:45px auto;padding:35px 44px;background:#fffdf8;border:1px solid #dfdad0}.reading p,.reading li{font-family:Georgia,serif;font-size:18px;line-height:1.75}.reading .eyebrow{font-family:system-ui,sans-serif;font-size:10px}.reading code{font:13px/1.6 Consolas,monospace;overflow-wrap:anywhere;background:#f0ede7;padding:1px 3px}.reading pre{background:#222b2e;color:#f0f0e7;overflow:auto;padding:18px;max-width:100%;border-left:3px solid #d291ab}.reading pre code{background:none;color:inherit;padding:0;overflow-wrap:normal}.reading ul{padding-left:24px}details{border-top:1px solid #cfc9c2;padding:15px 0;font-size:13px}summary{cursor:pointer;font-weight:600}.sources{overflow-wrap:anywhere}.diff{white-space:pre-wrap;overflow-wrap:anywhere;font-size:11px;max-height:580px;overflow:auto;padding:18px;background:#e9e7e2}.hall footer{display:flex;justify-content:space-between;margin:26px 0;font-size:13px}.end{margin-top:65px;border-top:1px solid #aaa;padding:28px 0;font-size:13px}@media(max-width:850px){nav{position:static;width:100%;padding:22px}nav a{display:inline-block;margin:5px 14px 5px 0;padding:8px 0}nav small{display:inline;margin-right:7px}nav>p{margin:0 0 16px}nav .meta{display:none}main{margin:0;padding:28px 18px}.reading{padding:22px}table{display:block;overflow:auto}.change{padding:14px 18px}}@media print{nav,details,.hall footer{display:none}main{margin:0;padding:0;max-width:none}.hall{break-before:page}.reading{border:0;padding:0;margin:25px auto}.reading pre{white-space:pre-wrap}figure{break-inside:avoid}h2,h3,h4{break-after:avoid}body{background:white}a{text-decoration:none}}"""
    html = f"""<!doctype html><html lang='en'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>Ada — Eight interactions through the museum</title><style>{css}</style></head><body>
    <nav aria-label='Report chapters'><p>Ada /<br>Eight interactions</p><a href='#overview'>Overview and placement</a>{''.join(nav)}<a href='README.md'>Complete Markdown report</a><p class='meta'>5 October 2026<br>Five tutorials · eight topics<br>Existing museum · selected learning</p></nav>
    <main><header id='overview'><p class='eyebrow'>ENDLESS MUSEUM / TUTORIAL REVISION / 05 OCTOBER 2026</p><h1>From carrying a point to leaving a mark.</h1><p class='lead'>{escape(intro)}</p><p class='method'>{escape(method)}</p></header>
    <table><caption class='eyebrow'>Where each requested topic is taught</caption><thead><tr><th>Topic</th><th>Hall</th><th>Teaching choice</th></tr></thead><tbody>{''.join(rows)}</tbody></table>
    {''.join(sections)}<div class='end'><p>The next useful trial is a learner carrying these skills through the rooms: draw a bend, find its retained source in Grid, distinguish a requested movement from the current one, and make paint reach a chosen surface.</p><p><a href='report.json'>Revision and image provenance</a> · <a href='checks.json'>Verification record</a> · <a href='../../course/hall-cards/index.html'>Whole tutorial lineage</a></p></div></main></body></html>"""
    (HERE/"index.html").write_text(html, encoding="utf-8")
    (HERE/"README.md").write_text("\n".join(md), encoding="utf-8")
    (HERE/"report.json").write_text(json.dumps(dict(date="2026-10-05", scope=method, topics=TOPICS, halls=HALLS),ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(f"Built {len(HALLS)} complete lessons; {sum(len(h['images']) for h in HALLS)} museum images; {len(TOPICS)} topics.")


if __name__ == "__main__":
    main()
