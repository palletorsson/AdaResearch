"""Install the cellular/box comparison maps, preserving unrelated authored rows."""
from pathlib import Path
import copy
import json
import em_map_halls
from evidence_root import evidence_dir

ROOT = Path(__file__).resolve().parents[1]
NEW_MAPS = ["Noise_Cellular", "Noise_Box"]
OUT = evidence_dir("cellular-spaces-2026-10-13")


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def insert_maps(items):
    clean = [x for x in items if x not in NEW_MAPS]
    at = clean.index("Noise_Inside_Noise") + 1
    return clean[:at] + NEW_MAPS + clean[at:]


def update_plan_provenance(plan, order):
    metadata = plan.setdefault("_map_halls", {})
    for chapter in metadata.get("chapters", []):
        if chapter.get("chapter") == "noise":
            metadata["halls"] = metadata.get("halls", 0) + len(order) - chapter["halls"]
            chapter.update(halls=len(order), maps=list(order))
            break
    metadata.setdefault("scoped_updates", {})["noise"] = {
        "date": "2026-10-13", "by": "tools/install_cellular_noise_maps.py",
        "maps": list(NEW_MAPS),
        "note": "Added Cellular Noise and Box Noise from their authored maps; retained native room footprints and updated noise sequence indices."
    }


def make_map(box=False):
    name = "Noise_Box" if box else "Noise_Cellular"
    title = "Box Noise" if box else "Cellular Noise"
    width, depth = 69, 49
    structure = [["1"] * width for _ in range(depth)]
    utilities = [[" "] * width for _ in range(depth)]
    artifacts = [[" "] * width for _ in range(depth)]
    for z in range(depth):
        for x in range(width):
            if x in (0, width-1) or z in (0, depth-1):
                structure[z][x] = "w"
    for x in (33, 34, 35):
        structure[0][x] = structure[-1][x] = "1"
    structure[1][34] = "3"
    structure[2][34] = "2"
    utilities[1][34] = "s"
    utilities[2][34] = "wp"
    utilities[3][34] = "wp"
    structure[-1][34] = "0"
    utilities[-1][34] = "t"
    utilities[35][17] = "an"
    utilities[35][51] = "an"
    prefix = "box" if box else "cellular"
    first = "box_shell_space" if box else "cellular_womb_space"
    second = prefix + "_atrium_space"
    artifacts[19][17] = first + "#floor:false#plinth:0#pin:true"
    artifacts[19][51] = second + "#floor:false#plinth:0#pin:true"
    if not box:
        artifacts[40][34] = "voronoi_strands#plinth:0#pin:true"
    description = (
        "Walk the stepped shell on the left and the box-sampled cells on the right. Both read the preceding cellular fields once per box. Square exposed faces retain a block boundary; the flat floors and cut passages remain usable. This map uses box noise to mean piecewise-constant box sampling, not a separate named noise generator."
        if box else
        "Enter the curved womb membrane on the left, then the connected cells on the right. Missing central partitions make a larger shared room. Beyond the entrances, thin strands trace the edges of a three-dimensional Voronoi diagram, with cords attached directly to existing floors, walls and ceilings where present. Compare a boundary as wall, opening and line. The completed net responds to gravity and cable tension through its shared knots."
    )
    data = {
        "map_info": {"name": title, "title": title, "lookup_name": name, "description": description,
                     "version": "1.0", "format": "json", "dimensions": {"width": width, "depth": depth, "max_height": 12},
                     "metadata": {"difficulty": "intermediate", "category": "noise", "estimated_time": "5-8 minutes",
                                  "learning_objectives": (["Compare interpolated surfaces with piecewise-constant occupancy", "Separate visible box boundaries from walkable clearance"] if box else ["Read feature-point distances as walls and edges", "Compare enclosure with a shared clearing", "Distinguish cell edges from connections between feature points"])},
                     "museum": {"wall_height": 4, "gate_depth_rows": 0, "artifact_placement": "map", "open_roof": True,
                                "piers": False, "plinths": False, "floor_cells": [[34,48]],
                                "passage": {"kind": "straight", "width": 3, "depth": 3},
                                "sculpture_clear_rects": [[2,3,32,34],[36,3,66,34],[28,34,40,46]]}},
        "documentation": {"summary": description, "layout": "Two full-scale rooms flank a clear north-south aisle. Their south-facing entrances open onto the cross-aisle at z=34. The exit is centred on the last row.",
                          "size_reason": "A 69 m width preserves the two 28 m room footprints and a shared passage at scale 1."},
        "utility_definitions": {"t": {"type": "teleporter", "properties": {"action": "next_in_sequence"}}},
        "lighting": {"ambient_color": [0.8,0.78,0.76], "ambient_energy": 0.55},
        "settings": {"cube_size": 1.0, "gutter": 0, "show_grid": True, "enable_physics": True,
                     "bare_world": True, "disable_biome": True, "auto_reveal_on_entry": True,
                     "initial_tile_visibility": "all", "grid_animation": {"enabled": False}},
        "layers": {"structure": structure, "utilities": utilities, "interactables": artifacts}}
    target = ROOT / "commons/maps" / name
    write_json(target / "map_data.json", data)
    if box:
        text = {
            "blurb": "The same field arrives in boxes. Corners and stairs appear where the smoother room offered a continuous fold.",
            "summary": "# Box Noise\n\nAfter Cellular Noise, compare a box-sampled shell at (17,19) with box-sampled cells at (51,19). Both have level floors, a south entrance and a common cross-aisle. The right-hand room keeps its central clearing. Continue to Noise_Space_10.\n\nHere 'box noise' is the chosen display: constant occupancy inside each sampled box. The underlying seeded cellular field is retained.",
            "tutorial": "# What does the box keep?\n\nEnter the left room and look along its ceiling. A curved field has become square faces and steps. Cross to the other room and walk through its openings toward the centre.\n\nCompare this with Cellular Noise. The field's values and the geometry that receives them are different choices. A larger box can hide a narrow passage; our openings are checked against a standing body. Next, Noise_Space_10 asks how a sampled ground carries a route.",
            "technical": "# Box samples from a cellular field\n\nCellular Noise used marching tetrahedra to interpolate the zero boundary. Here box_mesher.gd evaluates the same solid field at each box centre. A negative value occupies the whole box; a positive value leaves it empty. Only faces adjacent to empty boxes are emitted.\n\nDefault box_size is 0.65 m. The 27 × 11 × 29 m sample bounds divide each axis into whole intervals, so actual box sides are close to that size. The membrane remains thick enough for this spacing. The resulting axis-aligned triangles supply both rendering and collision. Floors remain level and entrances are cut before sampling.\n\nbox_shell_space and box_atrium_space share cellular_volume.gd. No new stochastic basis is claimed: box noise names a discrete receiving operation. Noise_Space_10 returns to the effect of a sampled surface on movement.",
            "critical": "# What fits between samples?\n\nA box assigns one answer to every position it contains. The finite interval makes the field buildable, but it can erase a distinction that mattered to a body: a narrow gap becomes solid, or a thin divider disappears.\n\nThe two rooms retain wide passages and a level floor. These are design decisions, not properties guaranteed by noise. In the QFEP reading, ask what this representation keeps available and what its resolution withholds; a rougher wall is not itself a measure of greater freedom.",
            "final": "A box holds one sampled decision across a volume. Before treating its edges as a feature of the field, ask which edges came from the receiving grid. Carry that distinction into the next walk."}
    else:
        text = {
            "blurb": "A boundary can wrap a body, divide a room or remain only a line. Walk what changes when a cell wall is opened.",
            "summary": "# Cellular Noise\n\nAfter Noise_Inside_Noise, two full-scale enclosures stand at (17,19) and (51,19). The left is a pink curved membrane; the right holds enterable Voronoi cells around an open centre. Their entrances face south toward the cross-aisle. A suspended edge structure stands at (34,40). The exit leads to Box Noise.\n\nThe strand sculpture draws 3D Voronoi edges as thin tubes. Anchor cords meet existing floors, walls and ceilings at verified surface points. The completed net settles under gravity and cable tension. It has no filled faces or player-blocking line collision. Walk around and through it to inspect depth.\n\nAn enlarged eight-legged spider lays the lines progressively and retraces completed strands to reach new branches. It performs the Voronoi construction as an artwork; its route is not a model of how a real spider chooses where to spin.\n\nThe net is one connected graph. Every finished strand meets a shared 3D junction or a visible fixing on the floor, a wall or the ceiling. Real intersections share vertex IDs; strands passing over or under each other remain separate. Space highlights junctions in the standalone preview.\n\nOnce complete, the net settles under gravity and elastic cable tension. Every knot is one shared moving particle, so a tug passes into neighbouring strands without separating their junction. Room attachments stay fixed. In the standalone preview, F finishes and releases the net, G tugs a knot, P pauses and B replays the construction. The force model is an approximation, with no breaking or strand self-collision.",
            "tutorial": "# What remains of a boundary?\n\nFollow the middle aisle to the entrances. Enter the left enclosure and look upward: cellular distance noise changes the curved shell, including its ceiling. Return to the aisle and enter the right-hand cells. Pass from a smaller chamber into the shared centre. Portions of the dividing walls have been removed.\n\nNow walk around the strand structure. Follow one polygon until an edge carries your eye behind another. These are the edges of cells in a volume; the feature points are not the visible knots. The longer cords attach the cropped network to its surroundings.\n\nThe open lines carry no collision, while the rooms' visible membranes stop the body. Continue to Box Noise to see what changes when the field is sampled as occupied boxes.",
            "technical": "# Distances, membranes and strands\n\nNoise_Inside_Noise changed the address used to sample an enclosing surface. This map takes the nearest-feature construction from [The Book of Shaders, chapter 12](https://thebookofshaders.com/12/) into three dimensions.\n\ncellular_volume.gd uses seeded 3D sites. A cell border is a bisector plane. The distance from p to the plane between its nearest site a and another site b is (|p-b|²-|p-a|²)/(2|b-a|). Finite wall thickness turns the borders into solid partitions. Arched passages are subtracted along routes to the sixteen ground-level sites, and central wall portions are deleted inside a 4.6 m radius. Four upper sites make overhead faces. Marching tetrahedra extracts the resulting boundary and the same mesh creates its collision. The womb variant instead deforms an ellipsoidal shell with 3D Worley noise.\n\nvoronoi_strands.gd tetrahedralizes 150 seeded 3D feature points with Geometry3D.tetrahedralize_delaunay. Adjacent tetrahedra share a triangular face; joining their circumcentres traces a Voronoi edge. Hull faces supply outward rays. The network is clipped to an ellipsoid, unanchored boundary tips are pruned, and retained boundary points receive separate tethers. Every retained cell-edge midpoint is checked for equal distance to at least three nearest sites.\n\nThe sculpture uses batched six-sided tubes and small junction spheres, with no per-frame regeneration or line colliders. The attachment cords connect the Voronoi boundary to actual surrounding floor, wall and ceiling surfaces. The preview's R key changes the seed; Space highlights shared junctions. Box Noise next keeps the field while changing extraction to exposed box faces.\n\nstrand_network.gd splits actual 3D centreline contacts into shared junctions, while strands separated in depth remain separate. Unanchored tips are removed to convergence and only one connected component is retained. Tethers attach directly to existing floors, walls and ceilings. Outward 3D raycasts stop at the first surface; when they miss, lower wall probes locate alternatives and a second raycast checks the complete cord. Mesh endpoints, shared IDs, reachability and surface attachments are checked independently. The completed graph is then released into the tension solver; each junction remains one shared particle as the geometry deforms.\n\nvoronoi_weaver.gd animates an enlarged spider along a depth-first traversal of the retained edge graph, starting at an anchor. A new strand grows to its spinneret; completed lines enter the existing MultiMesh batches. Return trips follow finished strands. The cell geometry remains unchanged. Eight articulated legs move with distance travelled. The standalone preview provides B to replay, P to pause, F to reveal the complete structure and T to change speed. Map exhibits start automatically; #weave:false skips construction; #tension:false disables forces and #weave_speed:2 sets metres per second.\n\nReal spiders also build [three-dimensional tangle webs](https://www.nhm.ac.uk/discover/spider-webs.html). Here the graph comes from Voronoi distances and the spider traces it. The construction animation is artistic, not a biological growth model. The completed net uses an illustrative cable model for gravity, tension and damping.\n\nSurface attachment generation waits for the map build signal and physics synchronization before sampling. It searches visible StaticBody3D surfaces on collision layer 1. Upward normals identify floors, downward normals identify ceilings, and lateral normals identify walls. The standalone preview supplies matching floor, wall and ceiling meshes and collision boxes. The open-roof map uses its existing floor and walls; it never invents a ceiling anchor. #surface_reach:80 sets the maximum search distance in metres; #wall_reach remains a legacy grid alias.\n\nstrand_dynamics.gd gives every shared knot one particle and every strand a tension-only elastic constraint, using [XPBD](https://mmacklin.com/xpbd.pdf). It integrates gravity at 120 Hz with six constraint passes and velocity damping. A stretched cable pulls; a slack cable cannot push. Room anchors have zero inverse mass. The mesh endpoints and junction spheres all read the same particle positions, so existing knots cannot separate. Sweeps against the room prevent moving knots from passing through its surfaces.\n\nConstruction remains an illustration until all strands are laid. The completed net is then released; unbuilt strands never provide invisible support. In the standalone preview, F finishes and releases it, G applies an impulse to a free knot near the centre of the view, P pauses and B restores the undeformed construction. The HUD shows peak cable force and extension. #tension:false disables relaxation; #compliance sets cable compliance in m/N and #knot_mass sets kilograms per free junction. The default values are 0.00002 m/N and 0.02 kg. These are illustrative cord parameters, not measured silk properties.\n\nRelaxation preserves the graph, not the exact nearest-site geometry. The approximation does not model bending, breakage, strand self-collision, distributed strand weight or the spider's weight; new crossings created by motion do not become knots. The checks include an isolated hanging mass with extension mg/k and tension mg, slack cables with zero compression, frame-rate invariance, fixed room anchors and transmission of a tug to neighbouring knots.",
            "critical": "# A cell need not remain a room\n\nNearest-point assignment gives a precise answer to a limited question: which site is closest? Turning that answer into a wall adds another rule. The wall has thickness; an opening has clearance; a body may fail to pass even where the mathematical regions meet.\n\nThe centre here becomes shared because we delete partitions. The strands make a further choice: a boundary stays visible without stopping passage. Neither result follows automatically from the distance rule. QFEP offers a way to ask which relations the enclosure supports and which it withholds, without pretending these rooms measure social freedom or free energy.",
            "final": "The distance rule assigns a cell. Rendering and collision decide what that assignment does to a body. Keep those decisions separate as the next room turns the field into boxes."}
    for key, value in text.items():
        (target / (key + ".md")).write_text(value + "\n", encoding="utf-8")


def main():
    make_map(False)
    make_map(True)
    registry_path = ROOT / "commons/artifacts/registry/cellular_noise_rooms.json"
    registry = json.loads(registry_path.read_text(encoding="utf-8")) if registry_path.exists() else {"artifacts": {}}
    for key, title, description in [
        ("cellular_womb_space", "Cellular Womb Space", "A curved pink cellular enclosure with a continuous rounded ceiling, level floor and wide entrance."),
        ("cellular_atrium_space", "Cellular Open Centre", "Sixteen enterable ground-level Voronoi cells with arched passages and central wall portions removed to create a larger common room.")]:
        registry["artifacts"][key] = {"lookup_name":key, "name":title, "scene":f"res://commons/context/cellular_spaces/{key}.tscn",
            "description":description, "auto_ground":False, "qfep_connection":"Compare a distance boundary with the walls, openings and shared rooms built from it.",
            "category":"procedural", "dev_category":"noise", "complexity":"intermediate", "tags":["cellular","voronoi","walkable","3d"],
            "parameters":{"footprint":[28,11,29], "size_group":"room_scale", "seed":"Reproducible cellular seed", "softness":"Shell deformation from 0 to 0.9", "clearing_radius":"Central opening radius from 3.5 to 5.5 metres"},
            "interactions":["Walk through the entrance", "Compare the enclosure with the open central space"]}
    for key, source, title in [("box_shell_space", "cellular_womb_space", "Box Noise Shell"), ("box_atrium_space", "cellular_atrium_space", "Box Noise Open Centre")]:
        entry = copy.deepcopy(registry["artifacts"][source])
        entry.update(lookup_name=key, name=title, scene=f"res://commons/context/cellular_spaces/{key}.tscn",
                     description="A box-sampled version of the cellular space, with axis-aligned exposed faces, stepped walls and ceilings, level floor and standing-height openings.")
        entry["parameters"]["box_size"] = "Target box side in metres, 0.4 to 0.75"
        entry["tags"] += ["box", "voxel"]
        registry["artifacts"][key] = entry
    registry["artifacts"]["voronoi_strands"] = {
        "auto_ground": False,
        "lookup_name": "voronoi_strands", "name": "Voronoi Strands", "scene": "res://commons/context/cellular_spaces/voronoi_strands.tscn",
        "description": "An open three-dimensional Voronoi edge skeleton drawn in thin charcoal tubes, with shared junctions and cords anchored directly to surrounding floors, walls and ceilings. Seeded sites define the cell geometry. No opaque cell faces or line collision. An enlarged eight-legged spider lays the lines progressively, tracing the mathematical graph as an artwork rather than simulating natural web growth. All strands belong to one connected graph with shared 3D junctions and explicit attachments to room surfaces. The completed net relaxes under gravity with tension-only cables, fixed room anchors and unbreakable shared knots.",
        "qfep_connection": "A partition remains legible as lines while its faces no longer bar passage. The attachment cords depend on the host architecture. Releasing the net distinguishes its distance construction from its shape under load: shared knots transmit a pull while fixed room anchors carry it.",
        "category": "procedural", "dev_category": "noise", "complexity": "intermediate", "tags": ["voronoi", "cellular", "3d", "lines", "strands", "suspension", "spider"],
        "parameters": {"footprint": [10.2,8.7,9.4], "size_group": "room_scale", "seed": "Deterministic seed", "cells": "32–240 feature points", "thickness": "Strand radius in metres", "anchors": "0–64 tethers to existing floors, walls and ceilings", "surface_reach": "Maximum surface search distance in metres, 5 to 100", "wall_reach": "Legacy grid alias for surface_reach", "weave": "Build progressively with a spider; false immediately releases the complete net", "weave_speed": "Spider travel speed in metres per second, 0.1 to 20", "tension": "Release the completed net under gravity; false preserves the Voronoi construction", "compliance": "Cable stretch per newton, 0.000001 to 0.001 m/N", "knot_mass": "Mass per free shared knot, 0.001 to 0.1 kg"},
        "interactions": ["Walk around and through the open structure", "Inspect the polygon edges from different viewpoints", "Watch the spider lay strands and retrace completed branches", "Highlight shared junctions with Space in the standalone preview", "F finishes and releases the net; G tugs a knot; P pauses forces"]}
    for entry in registry["artifacts"].values():
        entry.update(sequence="noise", map_sequences=["noise"], map_ready=True, include_in_map_data=True)
    write_json(registry_path, registry)
    sequence_path = ROOT / "commons/maps/sequences/noise.json"
    source = sequence_path.read_text(encoding="utf-8")
    sequence = json.loads(source)
    noise = sequence["sequences"]["noise"]
    noise["maps"] = insert_maps(noise["maps"])
    content = [x for x in noise["content"] if not x.startswith(("Noise_Cellular:", "Noise_Box:"))]
    at = next(i for i, x in enumerate(content) if x.startswith("Noise_Inside_Noise:")) + 1
    noise["content"] = content[:at] + ["Noise_Cellular: A boundary as membrane, opening and strand", "Noise_Box: The same field received as boxes"] + content[at:]
    groups = [g for g in noise["artifact_groups"] if g["map"] not in NEW_MAPS]
    at = next(i for i, g in enumerate(groups) if g["map"] == "Noise_Inside_Noise") + 1
    groups[at:at] = [
        {"map":"Noise_Cellular", "position":"integration", "artifacts":["cellular_womb_space","cellular_atrium_space","voronoi_strands"], "size_budget":"environment", "rationale":"Compare a curved shell, opened cell partitions and a 3D edge skeleton at body scale."},
        {"map":"Noise_Box", "position":"integration", "artifacts":["box_shell_space","box_atrium_space"], "size_budget":"environment", "rationale":"Keep cellular fields while changing the receiving geometry to occupied boxes."}]
    noise["artifact_groups"] = groups
    write_json(sequence_path, sequence)
    declaration_path = ROOT / "commons/data/map_authored.json"
    declaration = json.loads(declaration_path.read_text(encoding="utf-8"))
    declaration["noise"] = insert_maps(declaration["noise"])
    write_json(declaration_path, declaration)
    # Derive only the new halls; all unrelated authored rows survive unchanged.
    for relative in ["commons/data/museum/em_plan.json", "ada_run/em_plan.json"]:
        path = ROOT / relative
        if not path.exists():
            continue
        raw = path.read_bytes()
        plan = json.loads(raw)
        before = copy.deepcopy(plan)
        noise_rows = {row["map"]: row for row in plan["plans"] if row.get("sequence") == "noise"}
        museum = next(iter(noise_rows.values()))["museum"]
        order = declaration["noise"]
        for name in NEW_MAPS:
            row = em_map_halls.derive_row(name.replace("_", " ").lower(), name, museum, order.index(name), len(order), "noise")
            em_map_halls.normalize_row(row, True, True, width_exempt=True)
            noise_rows[name] = row
        for name, row in noise_rows.items():
            row["pearl_index"] = order.index(name)
            row["pearls_total"] = len(order)
        rows = []
        inserted = False
        for row in plan["plans"]:
            if row.get("sequence") == "noise":
                if not inserted:
                    rows.extend(noise_rows[name] for name in order)
                    inserted = True
            else:
                rows.append(row)
        plan["plans"] = rows
        update_plan_provenance(plan, order)
        assert [r for r in before["plans"] if r.get("sequence") != "noise"] == [r for r in rows if r.get("sequence") != "noise"]
        assert path.read_bytes() == raw, "Plan changed during derivation"
        backup = OUT / (path.parent.name + "-plan-before.json")
        if not backup.exists():
            backup.write_bytes(raw)
        path.write_text(json.dumps(plan, ensure_ascii=False), encoding="utf-8")
    print("Installed Cellular Noise and Box Noise in sequence and museum, with five registered exhibits.")


if __name__ == "__main__":
    main()
