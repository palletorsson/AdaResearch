"""Read-only source survey; writes only its dated report directory."""
from pathlib import Path
import collections
import hashlib
import html
import json
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "doc/book/iterations/2026-10-10-shader-pattern-survey"
PUBLIC = ROOT.parent / "ada_encyclopedia/public"


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def sequence(key):
    return read_json(ROOT / f"commons/maps/sequences/{key}.json")["sequences"][key]


# Destination, evidence-led reading, proposed use, boundary.
NOTES = {
    "Shader_01_Shaping": ("Already in Shaders", "Five function/graph panels, including step and smoothstep.", "Bring the spare Shapes hall's circle mask here: the point and distance return as a surface boundary.", "The current full tutorial is absent; the sequence JSON describes a proposed focus, not a verified learner chain."),
    "Shader_02_Colors": ("Reference", "Gradient, HSB, mix and rainbow panels with parameter controls.", "A small reference beside Shaping can recall colour interpolation.", "Colour already has its own sequence. A second compulsory colour hall would repeat that work."),
    "Shader_03_Shapes": ("Borrow for Shaders", "Circle, rectangle, boolean-combination and polygon masks; radius, softness and sides controls.", "Use one circle-to-boundary comparison in Shader_01_Shaping. Keep the existing sphere or cube as receiver.", "These are surface masks, not new collision bodies. Boolean composition can stay optional."),
    "Shader_04_Matrices": ("Borrow for Shaders", "Separate translation, rotation, scale and combined-coordinate panels.", "Use one transformed sampling coordinate in Shader_05_Patterns. Reconnect to Transformation without rebuilding a cube.", "Moving a sampling coordinate and moving a Node3D are different operations. The full four-panel gallery need not become another lesson."),
    "Shader_05_Patterns": ("Already in Shaders", "Classic tile/Truchet/offset/brick modes plus Wang-labelled, Voronoi and noise modes; the map also contains a garden and camera study.", "Carry one motif through address, local coordinate and orientation. Other modes can remain museum encounters.", "Already dense. Its tutorial explicitly says its proposed focus still needs alignment. The Wang-labelled shader blends neighbouring edge colours; it is not a constraint solver or an aperiodicity proof."),
    "Shader_06_Random": ("Reference", "Coordinate hash, random-grid and animated-static panels.", "Recall the difference between a fixed result at an address and a clock-changing input when randomising tile orientation.", "Keep Randomness as the place where sampling is learned. Do not imply bit-exact GPU replay across all devices."),
    "Shader_07_Noise": ("Reference", "Value, gradient, simplex and domain-warp panels.", "A comparison source for Shader_09_FBM; revisit a known noise input at a new surface.", "Noise already has a sequence. Choose one return, not another survey of every noise algorithm."),
    "Shader_08_CellularNoise": ("Borrow for Shaders", "Nearest-point, Worley F1 and F2-F1/crackle display definitions.", "Use one nearest-point comparison if it makes the transition from a regular grid to irregular cells clearer.", "Optional after the established coordinate lesson; compare with Voronoi already in Shader_05_Patterns before adding another artifact."),
    "Shader_09_FBM": ("Already in Shaders", "Layered-noise displays and a separate water basin under glass.", "Borrow a controlled normal/displacement comparison from Fabrics. Connect the familiar wave and field to surface appearance.", "The supporting glass and collision are separate from the visible wave. Current final.md already makes that distinction."),
    "Shader_10_ReactionDiffusion": ("Already in Shaders", "A reaction-diffusion material whose previous texture is not connected; a separate analytic frost image labelled DLA.", "Keep the question of retained state explicit before Cellular Automata.", "Do not present the panels as working growth simulations. The current reflection already identifies the missing input."),
    "Shader_11_QueerRubber": ("Already in Shaders", "Material studies on staged primitive bodies; view-dependent rims, surface response and lighting.", "A strong place for the returning sphere: compare colour, normal response and actual silhouette change.", "Use a controlled comparison; a library of spectacular materials alone does not establish what changed."),
    "Shader_12_PinkExtravaganza": ("Already in Shaders", "Pink material compositions and a plural-body study.", "Borrow one animal-pattern skin as a composition of known masks, noise, palette and material response.", "These shaders make designed resemblances, not biological explanations. Keep the composition lesson bounded."),
    "Pattern_Generation_One": ("Borrow for Shaders", "tiles_explained, gridscheckers and degrading_shader_demo.", "The five-stage UV → tiling → rotation → tile orientation → final pattern display is the strongest opening bridge from Tiling to Shaders.", "tiles_explained is marked map_ready=false. The degrading scene does not attach its manager; touch memory is not ready as placed."),
    "Pattern_Generation_Two": ("Optional Shaders", "A glass-divider shader scene and WFCSculptureGenerator.", "Use the divider to compare object UV with sampling the scene behind a surface.", "Screen/depth sampling needs renderer and headset checks. Keep the WFC sculpture outside the minimal shader lesson."),
    "Pattern_Generation_Three": ("Borrow for Tiling", "A Truchet-family surface scene plus WFC3DGenerator.", "In Tutorial_Pattern, show a small deterministic 4×4 orientation comparison: one diagonal source, several turns, a different global reading.", "Borrow the motif/orientation idea. Random flips and WFC belong later. The file quarterarcs.gdshader actually draws a diagonal threshold, despite its name."),
    "Pattern_Generation_Four": ("Borrow for Shaders", "The fabrics scene binds wallpaper, normal, terrain, displacement and tartan shaders.", "Use one known sphere to separate an image, a perturbed normal and vertex displacement in Shader_11_QueerRubber or Shader_09_FBM.", "This is not a woven-thread simulation. Preserve the distinction between the physical handloom, a depicted textile and shader geometry."),
    "Pattern_Generation_Five": ("Optional Shaders", "Shader_Gallery materials and a waves scene containing water shaders.", "A reserve for material and water comparisons in the existing body/basin halls.", "Both already have strong examples. Four-wave water with depth, normals and refraction is too much as the first printed shader."),
    "Pattern_Generation_Six": ("Keep for later", "A TileMate scene generating and mirroring coloured line paths, with a timed pattern update.", "Potential return to Trace and symmetry, or a later lesson on changing a stored pattern.", "It uses line geometry rather than just a fragment shader. Random path generation and timed changes add a different teaching problem."),
    "Pattern_Generation_Seven": ("Borrow for Shaders", "Animal-pattern materials: spots, stripes, scales, eyes and moiré; a mode-driven shader combines noise and masks.", "One selected skin in Pink Extravaganza could let the student compose earlier operations on their own sphere.", "Do not assign the entire material library. File names can mislead: popleopard.gdshader is a hex/stitch appearance, while the multi-animal modes live in neontigerstripes.gdshader."),
    "PatternGeneration_Diffusion_Limited_Aggregation_DLA": ("Repair before teaching", "The map places self_organizing_patterns, not the separately named DLA artifact.", "Keep as a candidate for a later growth/state sequence after checking the actual simulation.", "The map title alone cannot establish diffusion-limited aggregation. Do not import its stated lesson unchanged."),
    "PatternGeneration_Narrative_Generation": ("Keep for later", "The map places markov_chains.", "A later probability/language comparison may be useful.", "It does not strengthen the present tiling-to-surface-rule progression."),
    "PatternGeneration_Penrose_Tilings": ("Repair before teaching", "The placed artifact is koch_curve. A separate PenroseTilings.gd implementation exists elsewhere.", "Order without simple repetition is an interesting future encounter.", "Neither the map name nor a finite illustrated patch proves the property. The separate implementation needs a geometric audit before teaching from it."),
    "PatternGeneration_Typography_Generation": ("Repair before teaching", "The map places env_one, a random environment generator.", "Letter/motif relationships could be useful, but this room is not evidence for an implemented typography lesson.", "A relevant artifact would need to be selected and verified first."),
    "PatternGeneration_Wang_Tiles": ("Repair before teaching", "The map places env_one, not a Wang tile solver.", "Edge compatibility could become a later constraint lesson; compare the real wfc_tile_mosaic instead.", "The similarly named shader in Shader_05_Patterns averages edge colours rather than selecting tiles from a constrained tile set."),
    "Pattern_Maker_Workshop": ("Already represented", "One pattern_maker_station with an editable source and carpet receiver.", "Useful as a quieter test room for the same station already used in Foundry and Tutorial_Pattern.", "It is not a new learning operation merely because it has another map."),
    "Pattern_Maker_Showcase": ("Reference", "Tile puzzle, 4×4/8×8/mirror/brick/herringbone/cube variants, carpet, editor and WFC mosaic.", "A useful artifact-selection shelf. Compare one carrier or one copying rule at a time.", "Most of the family is already represented in Tiling. WFC adds neighbour constraints and should be a separate later step."),
    "Cove_Display_Gallery": ("Optional Tiling", "wall_pattern_gallery overlays wallpaper materials on grid architecture.", "Borrow a single wall-to-ceiling return or a controlled crop/seam comparison for Array_Patterns or Pattern_Temple.", "The same gallery artifact is already in Symmetry_Seventeen. Its grid-system assumptions need checking in a different museum shell."),
    "Wallpaper_Groups_Gallery": ("Reference", "A floor-plan-driven collection of named group bays and decorative floor presets.", "A spatial catalogue to consult when choosing a contrast for Symmetry_Seventeen.", "Names and floor presets do not prove the assigned groups. The floor plan does not even enumerate all 17 group names; do not import its census claim."),
    "Shader_Arch_Gallery": ("Optional Tiling", "A tunnel of cube receivers with independently generated domain textures, palettes, scales and wallpaper-group settings.", "An optional exuberant destination: one rule can dress an enclosure.", "Changing many parameters at once obscures causality. Pattern_Temple already supplies the controlled architectural lesson."),
    "Tile_Shapes_Gallery": ("Reference", "Fifteen floor-plan rooms including entrance; square/diagonal/hexagonal/radial and other named floor patterns.", "Take one contrast between carrier/lattice arrangements for an optional tile study.", "A catalogue of presets is not yet a lesson explaining their construction. Tiling need not teach every tile family."),
    "Pixel_Art_Gallery": ("Optional Tiling", "An eight-room floor plan with pixel-invader, neon, glitch and Memphis areas plus corridors.", "A visual return to the small stored source and nearest sampling, if we need an optional walk.", "It adds atmosphere more readily than a new core operation; the complete gallery need not enter the spine."),
}

SHORTLIST = [
    ("Borrow first", "UV made visible", "Pattern_Generation_One → Shader_01_Shaping", "Keep the learner's panel and motif. Show its UV colours, repeat the coordinates, turn a cell, then use those coordinates to evaluate a shape. The five stages already exist in TilesExplained.gd.", "Predict which four positions will sample the same local coordinate; change the repeat count and check them.", "algorithms/shaders/tilesexplained/TilesExplained.gd", "const STAGES"),
    ("Small Tiling addition", "One tile, several turns", "Pattern_Generation_Three → Tutorial_Pattern", "Keep one asymmetric diagonal tile. Compare a 4×4 field with all cells facing one way against a fixed orientation rule. Let the global pattern change while the source stays the same. This extends the current reflection lesson rather than replacing it.", "Change only one orientation entry and identify exactly which cell changes; then alter the repeated rule and follow every affected copy.", "algorithms/patterngeneration/truchettiles/quarterarcs.gdshader", "vec2 rotateTilePattern"),
    ("Borrow first", "The familiar form becomes a test", "Shader_03_Shapes + Shader_04_Matrices → Shaping / Patterns", "A radius produces a boundary; translated or rotated sampling coordinates change where it appears. Bring back the point, line and transformed cube through one surface rule.", "Separate a transformed Node3D from a transformed UV: predict what moves on the surface and what stays fixed in the room.", "algorithms/shaders/book_of_shaders/shader_03_shapes.gd", "var shader_defs"),
    ("Borrow first", "A bump, or a changed body?", "Pattern_Generation_Four → QueerRubber / FBM", "Put a field on the same sphere. Compare colour only, normal response, then vertex displacement. The normalstone shader has an explicit vertex-displacement switch. This is a strong return to primitive resolution.", "Predict which mode changes the silhouette. Check collision separately; a displaced visible mesh does not establish a changed physical collider.", "algorithms/patterngeneration/fabrics/normalstone.gdshader", "void vertex()"),
    ("Optional composition", "A skin made from known decisions", "Pattern_Generation_Seven → PinkExtravaganza", "Compose one stripe or spot mask with a palette and material response. A personal skin can carry earlier colour, noise and form work without making all animal modes compulsory.", "Hold the mask fixed and change the palette; hold the palette fixed and change mask scale. Explain the two results separately.", "algorithms/patterngeneration/animalpatterns/neontigerstripes.gdshader", "void fragment()"),
    ("Later, after repair", "A surface that keeps an encounter", "Pattern_Generation_One → Shader_10_ReactionDiffusion", "The unused degradation manager sketches a CPU image that accumulates imprints and is uploaded as a texture. This could contrast a retained record with a pattern recalculated from TIME.", "Leave a mark, stop input and verify the stored record persists; reset it deliberately. First connect the manager, material and actual museum hands and validate the code.", "algorithms/shaders/degrading_shader/DegradingShaderManager.gd", "func _apply_imprint"),
]

ADJACENT = [
    ("Symmetry_Motif · Symmetry_Translation · Symmetry_Mirror_Rotor · Symmetry_Glide · Symmetry_Group · Chamber_Symmetry", "A separate symmetry proposal still exists. Its tile, loom/mill, mirror and group operations overlap the present Tiling sequence. Keep it as a source catalogue; Chamber_Symmetry is a catalyst/synthesis room, not another pattern algorithm."),
    ("Pattern_Loom_Gallery · Pattern_Tunnel · Pattern_Walls_Pearl", "Six loom variants; a pattern tunnel; mosaic floors and a WFC mosaic. Useful form and display alternatives. Check what each 'loom' actually makes: the recent thread_loom is the explicit warp/weft artifact."),
    ("Grand_Pattern_Museum · Mega_Pattern_Museum · Immersive_Pattern_Rooms · Pattern_Showcase · Pattern_Walls_Gallery", "These contain substantial floor-plan JSON, not just empty floor_plan_space tokens. They supply room arrangements, borders, architectural skins and preset comparisons. Select an encounter rather than importing another large gallery."),
    ("Gallery_Shaders", "A broad sixteen-artifact shelf including a pattern compositor, cubemap, transmission, carpet and material galleries. The compositor assigns different patterns to field, border and medallion zones: useful if Pattern_Temple needs clearer compositional parts. Several placements are aliases or alternate versions; count functions rather than names."),
    ("Mosaic_Pattern_Maker · PG_Mirrored_Patterns · ProceduralGenerationBooleanPatterns", "Adjacent work connects painted motifs to tessellation, procedural mirroring and constraints. These belong to other routes; useful references, not automatically missing Tiling chapters."),
    ("Pattern_pt01_p1_bauhaus … Pattern_pt10_p3m1_alhambra", "Ten preview maps use gallery_marker_pattern. Treat them as visual variants and locate their configuration before calling them ten new lessons."),
]


def relative_link(path):
    # The read-only book server permits evidence files, not arbitrary source paths.
    # Preserve a dated source snapshot so these links also work over HTTP.
    target = OUT / "sources" / path
    if target.suffix == ".gdshader":
        target = target.with_suffix(".gdshader.txt")
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / path, target)
    return target.relative_to(OUT).as_posix()


def source_link(path, needle=None):
    p = ROOT / path
    assert p.is_file(), path
    line = 1
    if needle:
        line = next(i for i, text in enumerate(p.read_text(encoding="utf-8-sig").splitlines(), 1) if needle in text)
    return {"path": path, "line": line, "href": relative_link(path)}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "images").mkdir(exist_ok=True)
    memberships = collections.defaultdict(list)
    for p in (ROOT / "commons/maps/sequences").glob("*.json"):
        try:
            for key, seq in read_json(p).get("sequences", {}).items():
                for name in seq.get("maps", []):
                    if isinstance(name, str):
                        memberships[name].append(key)
        except (ValueError, AttributeError):
            pass
    registry = collections.defaultdict(list)
    for p in (ROOT / "commons/artifacts/registry").glob("*.json"):
        try:
            for key, val in read_json(p).get("artifacts", {}).items():
                registry[key].append({"registry": p.relative_to(ROOT).as_posix(), "scene": val.get("scene", val.get("scene_path", "")), "map_ready": val.get("map_ready")})
        except (ValueError, AttributeError):
            pass

    core = sequence("patterngeneration")["maps"]
    old = ["Pattern_Generation_" + n for n in ["One", "Two", "Three", "Four", "Five", "Six", "Seven"]]
    ids = list(dict.fromkeys(core + old))
    assert len(ids) == 31 and set(ids) == set(NOTES)
    rows = []
    for name in ids:
        path = f"commons/maps/{name}/map_data.json"
        data = read_json(ROOT / path)
        tokens = collections.Counter()
        placements = []
        for row in data.get("layers", {}).get("interactables", []):
            for value in row:
                if str(value).strip() and str(value).strip() != "0":
                    placements.append(value)
                    tokens[str(value).split(":")[0].split("#")[0].strip()] += 1
        status, found, use, boundary = NOTES[name]
        docs = [f for f in ["tutorial.md", "final.md"] if (ROOT / f"commons/maps/{name}/{f}").is_file()]
        floorplan = ROOT / f"commons/maps/{name}/floor_plan.json"
        rows.append({"map": name, "status": status, "found": found, "use": use, "boundary": boundary,
                     "memberships": memberships[name], "texts_present": docs, "tokens": dict(tokens), "placements": placements,
                     "floorplan_rooms": len(read_json(floorplan).get("rooms", [])) if floorplan.is_file() else None,
                     "artifacts": {key: registry.get(key, []) for key in tokens}, "source": source_link(path)})

    shortlist = [dict(zip(["priority", "title", "route", "proposal", "check", "path", "needle"], row)) for row in SHORTLIST]
    for item in shortlist:
        item["source"] = source_link(item.pop("path"), item.pop("needle"))

    # Existing engine previews, explicitly not new captures or placement evidence.
    images = []
    for name, caption in [
        ("truchet_live", "Truchet-family artifact: existing isolated render. The source files include deterministic rotations, diagonal splits, dots and zigzags."),
        ("fabrics_weave", "The capture is named fabrics_weave; inspected code includes textile-like colour, normal and displacement studies. This image does not show simulated interlaced threads."),
    ]:
        src = PUBLIC / f"pattern-research-gallery/{name}.png"
        meta = PUBLIC / f"pattern-research-gallery/{name}.json"
        assert src.is_file() and meta.is_file()
        shutil.copy2(src, OUT / f"images/{name}.png")
        images.append({"file": f"images/{name}.png", "caption": caption, "source": str(src), "capture_spec": read_json(meta), "sha256": hashlib.sha256(src.read_bytes()).hexdigest()})

    # Broad discovery index: useful for finding variants without overstating the depth of this review.
    discovered = []
    names = set(ids) | set(sequence("symmetry")["maps"])
    for p in (ROOT / "commons/maps").iterdir():
        if p.is_dir() and re.search(r"pattern|shader|wallpaper|tile.shape|pixel.art|cove.display", p.name, re.I):
            names.add(p.name)
    for name in sorted(names):
        p = ROOT / f"commons/maps/{name}/map_data.json"
        if p.is_file():
            discovered.append({"map": name, "sequences": memberships[name], "source": source_link(p.relative_to(ROOT).as_posix())})

    evidence_paths = {
        "commons/maps/sequences/patterngeneration.json", "commons/maps/sequences/shaders.json", "commons/maps/sequences/tiling.json", "commons/maps/sequences/symmetry.json",
        "algorithms/shaders/book_of_shaders/shader_04_matrices.gd", "algorithms/shaders/book_of_shaders/patterns_wang.gdshader",
        "algorithms/shaders/book_of_shaders/shader_10_reactiondiffusion.gd", "algorithms/shaders/degrading_shader/degrading_shader_demo.tscn",
        "commons/maps/Wallpaper_Groups_Gallery/floor_plan.json", "commons/artifacts/pattern_compositor/pattern_compositor.gd",
    }
    evidence_paths.update(row["source"]["path"] for row in rows)
    evidence_paths.update(item["source"]["path"] for item in shortlist)
    for row in rows:
        for matches in row["artifacts"].values():
            for entry in matches:
                evidence_paths.add(entry["registry"])
                if entry["scene"].startswith("res://") and (ROOT / entry["scene"][6:]).is_file():
                    evidence_paths.add(entry["scene"][6:])
    manifest = {"date": "2026-10-10", "scope": "Source inspection and curriculum recommendations, no runtime or headset validation", "core_maps": 25,
                "unique_maps_in_main_review": len(rows), "already_in_shaders": len(sequence("shaders")["maps"]), "broader_discovery_count": len(discovered),
                "source_hashes": {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in sorted(evidence_paths)}, "images": images}
    (OUT / "inventory.json").write_text(json.dumps({"reviewed": rows, "shortlist": shortlist, "broader_discovery": discovered}, indent=2, ensure_ascii=False), encoding="utf-8")
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")

    md = ["# Shader and pattern maps: what is worth carrying forward", "", "10 October 2026 · source survey and teaching proposal", "",
          "There is useful material here. The strongest gain is a clearer return from stored motifs to coordinate rules, then from surface appearance to visible geometry. Tiling already has a coherent nine-hall route; most additions should be selected encounters inside its current halls or inside the six shader halls.", "",
          "The separate `patterngeneration` route contains 25 maps. Six are already in `shaders`. The seven older `Pattern_Generation_*` maps overlap it at Five, giving **31 unique maps** in this review. A broader discovery index is included separately; those extra names have not all received a code-level audit.", "",
          "This report does not change map order, artifacts, tutorial.md or final.md. Findings come from map JSON, registry resolution, scene references and selected implementation code. The two images are existing isolated engine previews, not fresh captures of the current museum placement. Source links open dated snapshots. No runtime, ghost-student or headset pass was performed for this survey.", "",
          "## What I would borrow", ""]
    for item in shortlist:
        ref = item["source"]
        md += [f"### {item['title']} — {item['priority']}", "", f"**{item['route']}**", "", item["proposal"], "", "Proposed learner check: " + item["check"], "", f"Source: [{ref['path']}, line {ref['line']}]({ref['href']}).", ""]
    md += ["## Keep the teaching line clear", "", "**Tiling:** a small stored motif → a copying rule → a receiving surface → a worn recipe. Add one controlled orientation comparison if it helps; keep the real loom and the distinction between making thread and depicting cloth.", "", "**Shaders:** the same receiver → coordinates → a form mask → transformed/repeated sampling → material response → layered fields → composition → the need for retained state. Return to the student's familiar sphere or cube. The new operation belongs in a small script or shader; the museum supplies the host.", "", "The shader sequence's form-based plan exists, but four of its six maps currently lack tutorial.md, and Shader_05_Patterns calls its own learning focus proposed. This is not another finished, tested teaching sequence waiting to be concatenated. Its existing reflections and working exhibits are the starting material for a proper pass.", "", "## Full map list", "", "| Map | Fit | What is actually placed / implemented | Proposed use and limit |", "|---|---|---|---|"]
    for row in rows:
        md.append(f"| [{row['map']}]({row['source']['href']}) | {row['status']} | {row['found']} | {row['use']} {row['boundary']} |")
    md += ["", "## Nearby collections", ""]
    for names, note in ADJACENT:
        md += [f"**{names}**", "", note, ""]
    md += ["## Specific cautions before teaching from this material", "",
           "- The Penrose, Wang and Typography map names currently point to different artifacts. A title is not implementation evidence.",
           "- `patterns_wang.gdshader` blends independently assigned edge colours. At full blending adjacent sides share an average, but this does not implement tile-set constraint solving or prove aperiodicity.",
           "- `quarterarcs.gdshader` in the old Truchet scene uses `step(st.x, st.y)`: its source mark is diagonal. The Book of Shaders `patterns_truchet.gdshader` is the separate actual arc implementation.",
           "- The degradation manager is not attached by its demo scene and uses fixed hand paths plus Image lock/unlock calls that need a Godot 4.6 compatibility check. It is a promising repair candidate, not a verified touch-memory artifact.",
           "- The named wallpaper-group floor bays use decorative floor presets. The current floor-plan list omits PMG and PGG; it cannot stand in for a complete or verified classification.",
           "- Procedural textile appearance, interlaced yarn geometry, cloth motion and skin pattern formation are different subjects. An attractive resemblance can support reflection without being a simulation of the referenced process.", "",
           "## Next concrete pass", "", "Start with the shader opening. Use the five-stage coordinate display and one circle mask on a familiar receiver. Write one complete minimal example, reconstruct it from the printed text, and test a predicted change. Then choose whether the small 4×4 tile-orientation study adds enough to Tiling to earn its place. No new hall is required by these recommendations.", ""]
    (OUT / "REPORT.md").write_text("\n".join(md), encoding="utf-8")

    esc = html.escape
    def src_anchor(ref):
        return f'<a href="{esc(ref["href"], quote=True)}">Source · {esc(ref["path"])}:{ref["line"]}</a>'
    proposals = "".join(f'<article class="proposal"><span class="tag">{esc(s["priority"])}</span><h3>{esc(s["title"])}</h3><p class="route">{esc(s["route"])}</p><p>{esc(s["proposal"])}</p><p><b>Learner check:</b> {esc(s["check"])}</p><small>{src_anchor(s["source"])}</small></article>' for s in shortlist)
    cards = []
    for row in rows:
        tokens = ", ".join(row["tokens"])
        cards.append(f'<article class="map" data-status="{esc(row["status"])}" id="{esc(row["map"])}"><span class="tag">{esc(row["status"])}</span><h3>{esc(row["map"])}</h3><p>{esc(row["found"])}</p><p><b>Possible use:</b> {esc(row["use"])}</p><p class="limit">{esc(row["boundary"])}</p><details><summary>Placement and source</summary><p>{esc(tokens)}</p><p>Sequences: {esc(", ".join(row["memberships"]))}</p><p>Book texts present: {esc(", ".join(row["texts_present"]) or "neither tutorial.md nor final.md")}</p>{src_anchor(row["source"])}</details></article>')
    figures = "".join(f'<figure><a href="{i["file"]}"><img src="{i["file"]}" loading="lazy" alt="{esc(i["caption"], quote=True)}"></a><figcaption>{esc(i["caption"])}</figcaption></figure>' for i in images)
    adjacent = "".join(f'<p><b>{esc(a)}</b><br>{esc(b)}</p>' for a,b in ADJACENT)
    discovery = "".join(f'<li><a href="{r["source"]["href"]}">{esc(r["map"])}</a> <small>{esc(", ".join(r["sequences"]) or "no sequence membership found")}</small></li>' for r in discovered)
    options = "".join(f'<option>{esc(s)}</option>' for s in sorted({r["status"] for r in rows}))
    page = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Patterns waiting in the museum</title><style>
    :root{color-scheme:light;--ink:#232326;--paper:#f4f0e8;--pink:#a73167;--line:#d6cdc2}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.55 system-ui,sans-serif}main{max-width:1370px;margin:auto;padding:44px 4vw 90px}header{max-width:1000px}h1{font:clamp(40px,6vw,78px)/1.05 Georgia,serif;letter-spacing:-.025em;margin:20px 0}h2{font:32px/1.2 Georgia,serif;margin:48px 0 20px}h3{margin:12px 0;font-size:22px;overflow-wrap:anywhere}a{color:var(--pink);text-underline-offset:3px}.eyebrow,.tag{font-size:12px;letter-spacing:.06em;text-transform:uppercase}.tag{display:inline-block;border:1px solid var(--line);border-radius:30px;padding:4px 10px;background:#fff8}.lead{font:24px/1.45 Georgia,serif}.note{padding:16px 20px;border-left:3px solid var(--pink);background:#fff8;font-size:15px}nav{display:flex;gap:18px;flex-wrap:wrap;margin:22px 0}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:20px}.proposal,.map{padding:25px;border:1px solid var(--line);background:#fff9}.proposal{border-top:3px solid var(--pink)}.route{font-size:14px;font-weight:600}.map h3{font-size:19px}.limit{color:#66594f;font-size:15px;border-left:2px solid #d7bca9;padding-left:12px}small{font-size:12px;overflow-wrap:anywhere}details{font-size:14px;border-top:1px solid var(--line);padding-top:10px}summary{cursor:pointer}figure{margin:0}img{width:100%;display:block;aspect-ratio:1800/1061;object-fit:contain;background:#dfe6da}figcaption{font-size:13px;padding:10px 0 20px;max-width:620px}.controls{display:flex;flex-wrap:wrap;gap:12px;position:sticky;top:0;padding:12px 0;background:var(--paper);z-index:1}input,select{font:inherit;padding:10px;border:1px solid #aaa;background:white}input{flex:1;min-width:220px}.lineage{background:#22232b;color:#faf4ea;padding:25px;margin:30px 0}.lineage p{max-width:1000px}.count{font-size:14px;align-self:center}.nearby{max-width:1000px}.inventory{columns:2;overflow-wrap:anywhere}li{break-inside:avoid;margin:0 0 9px}article[hidden]{display:none}@media(max-width:750px){.grid{grid-template-columns:1fr}.inventory{columns:1}main{padding:25px 20px}.controls{position:static}h1{font-size:43px}}
    </style></head><body><main><header><p class="eyebrow">Endless Museum · source survey · 10 October 2026</p><h1>Patterns waiting<br>in the museum</h1><p class="lead">A useful reserve of artifacts. The strongest additions bring the student's familiar motif and body into a new operation.</p><p>The separate pattern-generation route has <b>25 maps</b>; six already belong to Shaders. Adding the older numbered pattern rooms gives <b>31 unique maps</b> in this review.</p><nav><a href="#shortlist">What to borrow</a><a href="#list">All 31 maps</a><a href="#images">Existing previews</a><a href="#nearby">Nearby collections</a><a href="REPORT.md">Full written report</a><a href="inventory.json">Editable inventory</a></nav><p class="note">Recommendations only. Map order, museum code and book texts are unchanged. Evidence: map placements, resolved scenes and selected source code. Images are existing isolated engine previews. This survey is not a fresh runtime or VR test.</p></header>
    <section class="lineage"><p><b>Tiling:</b> stored motif → copying rule → receiving surface → worn recipe.</p><p><b>Shaders:</b> same receiver → coordinates → form mask → transformed / repeated sampling → material response → layered fields → composition → retained state.</p><p>Keep one tutorial operation legible in each hall. Other artifacts can remain experiments, comparisons and reflective encounters.</p></section>
    <section id="shortlist"><h2>What I would borrow</h2><div class="grid">PROPOSALS</div></section>
    <section id="images"><h2>Existing artifact previews</h2><p>These show the available material, not its current placement inside Endless Museum.</p><div class="grid">FIGURES</div></section>
    <section id="list"><h2>The maps, with different jobs</h2><p>The current shader halls have strong reflective material, but four lack tutorial.md. The existing six-hall teaching plan is still marked proposed. More artifacts will not by themselves complete that work.</p><div class="controls"><input id="search" aria-label="Search maps" placeholder="Search map, operation or artifact"><select id="filter" aria-label="Filter by recommendation"><option value="">Every recommendation</option>OPTIONS</select><span class="count" id="count">31 maps</span></div><div class="grid" id="cards">CARDS</div></section>
    <section class="nearby" id="nearby"><h2>Nearby collections worth knowing</h2>ADJACENT<h2>Where names overpromise</h2><p>Penrose currently places a Koch curve; Wang and Typography place a random environment generator. The Wang-labelled shader blends edge colours rather than solving a tile set. The old quarter-arcs file actually thresholds a diagonal. The fabrics collection includes normal and vertex work, not an interlaced-thread simulation.</p><p>The degradation manager could supply a retained encounter, but the demo scene does not attach it. Treat that as a repair proposal. The existing Shader_10 reflection already makes its missing previous-state input explicit.</p><h2>My next choice</h2><p>Begin Shaders with the five-stage coordinate display and one circle mask on the student's familiar receiver. Reconstruct and test one complete printed example. Then decide whether the 4×4 tile-orientation comparison earns a small place in Tiling. These recommendations do not require new halls.</p><details><summary>Broader discovery index — DISCOVERY_COUNT names, including variants and scaffolds</summary><p>This is an inventory, not a claim that every entry has been audited.</p><ul class="inventory">DISCOVERY</ul></details></section>
    </main><script>const cards=[...document.querySelectorAll('.map')];const search=document.querySelector('#search'),filter=document.querySelector('#filter');function update(){let n=0;for(const c of cards){const visible=(!filter.value||c.dataset.status===filter.value)&&c.textContent.toLowerCase().includes(search.value.toLowerCase());c.hidden=!visible;n+=visible;}document.querySelector('#count').textContent=n+' maps';}search.addEventListener('input',update);filter.addEventListener('change',update);</script></body></html>'''
    for key,val in {"PROPOSALS":proposals,"FIGURES":figures,"OPTIONS":options,"CARDS":"".join(cards),"ADJACENT":adjacent,"DISCOVERY_COUNT":str(len(discovered)),"DISCOVERY":discovery}.items():
        page = page.replace(key, val)
    # The book server intentionally disallows scripts. Use normal anchors/details;
    # do not leave controls that appear usable but cannot execute there.
    page = re.sub(r'<div class="controls">.*?</div>', '<p class="count">31 maps · Sources open dated snapshots; expand a card for its placed artifacts.</p>', page, flags=re.S)
    page = re.sub(r'<script>.*?</script>', '', page, flags=re.S)
    page = page.replace('Editable inventory', 'Inventory JSON')
    if (OUT / 'gallery.html').is_file():
        page = page.replace('<nav>', '<nav><a href="gallery.html">Visual artifact gallery</a>', 1)
    (OUT / "index.html").write_text(page, encoding="utf-8")
    print(json.dumps({"report":str(OUT / 'index.html'),"reviewed":len(rows),"discovered":len(discovered),"source_files":len(evidence_paths),"images":len(images)}))


if __name__ == "__main__":
    main()
