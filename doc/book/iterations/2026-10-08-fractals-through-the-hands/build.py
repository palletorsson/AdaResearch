"""Publish a source-grounded proposal; never changes the museum or manuscripts."""
from pathlib import Path
import hashlib
import html
import json
import shutil
import markdown

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def main():
    plan = read_json(HERE / "plan.json")
    sequence_path = REPO / "commons/maps/sequences/fractals.json"
    route = read_json(sequence_path)["sequences"]["fractals"]["maps"]
    assert route == [h["map"] for h in plan["halls"]]
    registry = {}
    for path in (REPO / "commons/artifacts/registry").glob("*.json"):
        registry.update(read_json(path).get("artifacts", {}))
    (HERE / "images").mkdir(exist_ok=True)
    audits = []
    provenance = []
    missing = []
    for hall in plan["halls"]:
        folder = REPO / "commons/maps" / hall["map"]
        map_data = read_json(folder / "map_data.json")
        placements = []
        for z, row in enumerate(map_data.get("layers", {}).get("interactables", [])):
            for x, token in enumerate(row):
                if not str(token).strip() or token == "0":
                    continue
                key = token.split(":")[0].split("#")[0]
                scene = registry.get(key, {}).get("scene", "")
                exists = bool(scene) and (REPO / scene.removeprefix("res://")).is_file()
                placements.append({"key": key, "cell": [x, z], "token": token, "scene": scene, "scene_exists": exists})
                if not exists:
                    missing.append([hall["map"], key, scene])
        texts = {}
        for name in ["tutorial.md", "final.md"]:
            data = (folder / name).read_bytes()
            text = data.decode("utf-8-sig")
            texts[name] = {"words": len(text.split()), "gdscript_blocks": text.count("```gdscript"), "sha256": hashlib.sha256(data).hexdigest()}
        audits.append({"map": hall["map"], "placements": placements, "texts": texts})
        image = REPO / hall["image"]
        destination = HERE / "images" / (hall["map"] + ".png")
        shutil.copy2(image, destination)
        assert image.read_bytes() == destination.read_bytes()
        provenance.append({"map": hall["map"], "source": hall["image"], "capture_date": hall["image_date"], "sha256": hashlib.sha256(image.read_bytes()).hexdigest(), "note": "Historical native museum capture; visually inspected. Not a render of the proposed changes."})

    count = sum(len(a["placements"]) for a in audits)
    unique = len({p["key"] for a in audits for p in a["placements"]})
    overview = f'''# Fractals through the hands

8 October 2026 · **Proposal, not an implemented overhaul.**

{plan["thesis"]}

{plan["recommendation"]}

## What the audit found

The live sequence definition contains seven halls, with {count} artifact placements ({unique} distinct keys) in their map data. Their scene references resolve. This is a source audit, not a new runtime verification. The seven photographs below come from saved museum runs on 14 and 25 September; they show our starting material.

Six tutorial.md files have no GDScript blocks: they are useful encounter guides, but not the complete, tested reconstructions now required of the tutorial track. The opening has eight GDScript fragments and undefined drawing helpers; it introduces factorial, memoisation, tail recursion and a complex-to-pixel mapping before giving the student one finished spatial construction. The final.md texts already follow specific encounters and have much more continuity with the rooms. Revise their interfaces and observations after each build; do not discard their reflective argument.

The existing threshold walk, canopy, Cantor gaps, Koch measurement and Menger flight are strong starting points. Most primary lesson controls are console buttons. Hand-led control should change a meaningful geometric quantity or select a particular descendant. A nearby button remains useful for discrete NEXT, UNDO and RESET; replacing it with a meaningless gesture would add work without understanding.

## What should carry the lineage

The familiar **point** can return as a grip, cursor and size probe. The **line** becomes a segment and then a branch. The **cube** returns for volume selection. Reuse their construction and appearance where appropriate; do not force all geometry into a sphere class. Saving one particular recipe or record between rooms is a separate feature that must be implemented and tested before the tutorial promises it.

The student already brings transforms, arrays, functions, seeds and the current/next pattern from the earlier spine. Introduce one new generative operation, then return to those tools. A direct recursive call, a queue that evaluates a branching rule, and a numerical recurrence are distinct implementations. This sequence is well placed to make those distinctions visible.

[The Nature of Code, chapter 8](https://natureofcode.com/fractals/), supplies a useful progression through recursive functions, finite stopping conditions, segment replacement, trees and symbolic rewriting. Ada can add the bodily question: what do those constructions let us enter, hold or traverse? Its existing Cantor grammar already makes a precise handoff to L-systems. Julia and Mandelbrot remain optional extensions; there is no need to add complex-number iteration to this main route now.

## Spatial rhythm

**Unfold → branch → cut → trace → enter → arrange → compose.**

Each hall gets a reachable small model, one large consequence where scale is useful, and an open route to the next encounter. Place optional comparisons along the perimeter. Keep the input visible alongside its result. Highlight one generation or ancestry path before colouring the whole structure. Only one spatial instrument should dominate the first view into a room.

Use the same rose grips and readable state labels developed in Forces. Allow controlled exuberance after the small rule can be read: a canopy above us, a folded route, a porous cube to fly through. Keep stable floors and exits; distinguish a generated surface from its collision. Fractals can be wild through scale, multiplication and exclusion without every example acquiring a physics simulation.

## Tutorial and reflection

For each hall, tutorial.md declares the inherited code, supplies every new dependency and shows one complete minimal working example. A student must be able to make an independent change and predict an observable difference. Geometry, readout and test must evaluate the same rule. final.md can ask what that rule permits or excludes, what an ideal limit promises, and where a bodily limit interrupts it. Neither text has to explain every artifact.

Repeated form is not automatically a fractal. Finite displayed detail is not demonstrated infinity. A branch count is not a measure of entropy or freedom. A golden proportion is not proof of beauty. These are useful distinctions to experience, not a list of caveats to recite at the door.

## First build and acceptance

1. **Repair the opening lesson.** One bounded frame generator from the existing line construction. Declare its base case and test it in Godot; defer unrelated programming topics.
2. **Pilot the canopy.** Two point grips, one fork, one visible generation and one large preview. Preserve the existing console and primary tree until the replacement works. Hold randomness fixed. Make a local edit and show which descendants change.
3. **Run the complete interaction.** Exercise desktop and actual XRTools pickup paths with supplied poses; verify release, reset, subtree isolation and finite allocations. Capture the museum at eye height and from above. Physical headset comfort still needs a human trial.
4. **Extend only after that comparison.** Apply the proven interaction language to Cantor and Koch, then Menger, then the shorter mapping and composition rooms. Test the saved-record handoff before writing it as a learner action.

The suggested assertions below are an implementation contract. They have **not** been run in this proposal pass. Existing September test reports are historical evidence, not a pass for these new designs.
'''
    (HERE / "overview.md").write_text(overview, encoding="utf-8")
    sections = []
    summaries = [overview]
    for index, hall in enumerate(plan["halls"], 1):
        section = f'''## {index}. {hall["map"]} — {hall["title"]}

**Existing anchor:** `{hall["anchor"]}`

![{hall["alt"]}](images/{hall["map"]}.png)

*Existing museum capture · {hall["image_date"]}. The proposal below is not pictured.*

**Keep:** {hall["existing"]}

**Proposed interaction:** {hall["proposal"]}

**Learning elements:** {", ".join(hall["subjects"])}.

**One-paragraph lesson:** {hall["lesson"]}

**Reflection:** {hall["reflection"]}

**Test to write:** {hall["check"]}

**Carry onward:** {hall["carry"]}
'''
        summaries.append(section)
        e = html.escape
        tags = ''.join(f'<span>{e(s)}</span>' for s in hall["subjects"])
        sections.append(f'''<section class="hall" id="{hall['map']}">
<div class="hall-title"><div class="number">{index:02}</div><div><p class="verb">{e(hall['verb'])}</p><h2>{e(hall['title'])}</h2><p class="map">{e(hall['map'])}</p></div></div>
<figure><img loading="lazy" src="images/{hall['map']}.png" alt="{e(hall['alt'])}"><figcaption>Existing museum · {hall['image_date']} · Proposed changes are not pictured</figcaption></figure>
<div class="comparison"><div><h3>What we keep</h3><p>{e(hall['existing'])}</p></div><div><h3>What we could change</h3><p>{e(hall['proposal'])}</p></div></div>
<div class="tags">{tags}</div><h3>The lesson</h3><p>{e(hall['lesson'])}</p><h3>The reflective question</h3><p>{e(hall['reflection'])}</p>
<details><summary>Proposed test and handoff</summary><p>{e(hall['check'])}</p><p><strong>Carry onward:</strong> {e(hall['carry'])}</p><p class="map">Anchor: {e(hall['anchor'])}</p></details></section>''')
    extras = "## Three optional wild encounters\n\n" + '\n\n'.join(f"**{p['name']} — {p['status']}.** {p['idea']}" for p in plan["optional_play"])
    summaries.append(extras)
    (HERE / "PROPOSAL.md").write_text('\n\n'.join(summaries), encoding="utf-8")
    nav = ''.join(f'<a href="#{h["map"]}">{i}. {html.escape(h["verb"])}</a>' for i,h in enumerate(plan["halls"],1))
    overview_html = markdown.markdown(overview[overview.index('## What the audit found'):])
    page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{plan['title']} — Endless Museum</title>
<style>
:root{{color-scheme:light;--ink:#22332c;--muted:#626b62;--line:#d4dccf;--accent:#356b55}}*{{box-sizing:border-box}}body{{margin:0;background:#f5f6ef;color:var(--ink);font:18px/1.65 system-ui,sans-serif}}main{{max-width:1140px;margin:auto;padding:35px}}header{{max-width:920px;margin:35px 0 48px}}.eyebrow,.verb{{font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:var(--accent)}}h1{{font:clamp(42px,6vw,78px)/1.05 Georgia,serif;margin:20px 0 26px}}h2{{font:34px/1.18 Georgia,serif;margin:4px 0 12px}}h3{{font-size:15px;margin:22px 0 8px}}p{{margin:0 0 20px}}.lead{{font:25px/1.5 Georgia,serif}}a{{color:var(--accent);text-underline-offset:3px}}nav{{display:flex;flex-wrap:wrap;gap:10px;margin:25px 0}}nav a{{padding:8px 14px;background:#e7edde;border-radius:4px;font-size:14px;text-decoration:none}}.status{{border-left:4px solid #bb718f;background:#eee7e8;padding:16px 20px;font-size:14px}}.overview{{margin-bottom:50px;padding:25px 32px;background:white;border:1px solid var(--line)}}summary{{cursor:pointer;font-weight:600}}.overview h2{{font:25px/1.3 Georgia,serif;margin-top:38px}}.overview>div{{max-width:850px;margin:auto}}.hall{{padding:38px 0 50px;border-top:1px solid var(--line);scroll-margin-top:25px}}.hall-title{{display:flex;gap:24px;align-items:baseline}}.number{{font:40px Georgia,serif;color:#829d78}}.map{{font-size:13px;color:var(--muted)}}.verb{{margin-bottom:6px}}figure{{margin:26px 0}}img{{width:100%;height:auto;display:block;border:1px solid var(--line)}}figcaption{{font-size:12px;color:var(--muted);margin-top:8px}}.comparison{{display:grid;grid-template-columns:1fr 1fr;gap:32px}}.comparison>div{{padding:8px 22px;background:#eaf0e4}}.comparison>div+div{{background:#f0e8ec}}.tags{{display:flex;gap:8px;flex-wrap:wrap;margin-top:24px}}.tags span{{font-size:12px;border:1px solid #9fb29d;border-radius:20px;padding:4px 11px}}.hall>p{{max-width:900px}}details{{margin-top:25px}}details p{{margin-top:16px}}footer{{font-size:13px;padding:30px 0;border-top:1px solid var(--line)}}.extras{{max-width:900px;margin:30px 0 60px}}
@media(max-width:650px){{main{{padding:22px}}.comparison{{grid-template-columns:1fr;gap:12px}}.overview{{padding:20px}}h2{{font-size:29px}}body{{font-size:16px}}.lead{{font-size:22px}}}}@media print{{nav,details.overview,footer{{display:none}}body{{background:white;font-size:10pt}}.hall{{break-before:page}}figure{{break-inside:avoid}}h1{{font-size:38pt}}}}
</style></head><body><main><header><div class="eyebrow">Endless Museum · Sequence proposal · 8 October 2026</div><h1>{plan['title']}</h1><p class="lead">{plan['thesis']}</p><p>{plan['recommendation']}</p><p class="status">{plan['status']}<br>Seven historical museum captures; no invented after-images.</p><nav>{nav}</nav><p class="map"><a href="PROPOSAL.md">Full proposal</a> · <a href="plan.json">Editable plan</a> · <a href="source-audit.json">Source audit</a></p></header>
<details class="overview"><summary>What needs changing, the teaching lineage and the first build</summary><div>{overview_html}</div></details>
{''.join(sections)}<section class="extras">{markdown.markdown(extras)}</section><footer>Source review only · <a href="image-sources.json">Image provenance</a> · {count} placements / {unique} artifact keys · No engine tests claimed for proposed work.</footer></main></body></html>'''
    (HERE / "index.html").write_text(page, encoding="utf-8")
    (HERE / "source-audit.json").write_text(json.dumps({"date": plan["date"], "kind": "source review, not runtime certification", "sequence_sha256": hashlib.sha256(sequence_path.read_bytes()).hexdigest(), "placement_count": count, "distinct_artifact_keys": unique, "missing_scene_files": missing, "halls": audits}, indent=2), encoding="utf-8")
    (HERE / "image-sources.json").write_text(json.dumps(provenance, indent=2), encoding="utf-8")
    assert not missing, missing
    print(json.dumps({"halls":len(route),"placements":count,"distinct_keys":unique,"missing_scenes":missing,"images":len(provenance)},indent=2))


if __name__ == "__main__":
    main()
