#!/usr/bin/env python
"""
Fetch every Blender Python gist referenced in palle's tutorial doc and
save each under tools/blender/<category>/<name>.py with a standardized
header. Categories mirror the doc's section order.

Usage:
  python tools/blender/fetch_gists.py            # fetch missing only
  python tools/blender/fetch_gists.py --force    # overwrite existing

Gists are fetched from gist.githubusercontent.com/<user>/<id>/raw.
"""
from __future__ import annotations
import argparse
import sys
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
OUT_DIR = REPO_ROOT / "tools" / "blender"
USER = "palletorsson"

# (category, filename, gist_id, one_line_description, doc_section)
GISTS: list[tuple[str, str, str, str, str]] = [
    # ─── Fundamentals ──────────────────────────────────────────
    ("fundamentals", "grid.py",              "863441b938875780c1257105b2404582", "Zigzag patterns with object duplicates in a grid",        "Blender basics"),
    ("fundamentals", "line.py",              "2f2b095f5fb32c9f1ea3ad27f0d8efe3", "Single line of primitives",                                "One line"),
    ("fundamentals", "advanced_grid.py",     "e154b03b4c1efd87b027ba7cbd927b18", "Advanced grid arrangement",                                "Switch to spheres"),
    ("fundamentals", "more_balls.py",        "55bd1129e048e30bfadc63790473216e", "Many balls in a composition",                              "Extra more balls"),
    ("fundamentals", "vert_balls_loft.py",   "301283b44ec0c1742358cc02becdd3ec", "Vertex-positioned ball loft",                              "Vertices ball loft"),
    ("fundamentals", "minecraft.py",         "d0dc3c14e0dc615c3668e2a196488fea", "Minecraft-like world from balls",                          "Create a Minecraft world"),
    ("fundamentals", "keyframes.py",         "0746c4a56835fe92d87319046e5ae2ff", "Simple keyframe animation example",                        "Simple Keyframe animation example"),
    ("fundamentals", "pulsar.py",            "4e8e2f0efd1b766a7083634b9ec489c2", "3D pulsar animation",                                      "Pulsar 3D"),

    # ─── Mathematical surfaces ─────────────────────────────────
    ("math", "mandelbrot.py",                "a786a595af0e45419727c60065080e51", "Mandelbrot set visualization",                             "Mandelbrot"),
    ("math", "klein_bottle.py",              "e18b8ea968f90ac6a6a0d9887ebca646", "Klein bottle parametric surface",                          "Klein Bottle"),
    ("math", "mobius_strip.py",              "eaea436b228796854644e22b80d98137", "Mobius strip",                                             "A Mobius strip"),
    ("math", "wavy_mesh.py",                 "cca09d57ed983bac1e9bc4a9c1ab4de0", "Wavy displaced mesh",                                      "Wavy mesh"),
    ("math", "double_torus.py",              "db831449abdc2417685a7ca49430917a", "Double torus",                                             "Double torus"),
    ("math", "ripple.py",                    "bd27c371c395651b9b9bfb9f380fb544", "Ripple pattern",                                           "Ripple"),
    ("math", "supershape.py",                "c1d4ee77b63b8620126cbb9712957a1e", "Gielis supershape",                                        "Supershape"),
    ("math", "random_circle.py",             "193c4c0b6515dbbe3201ebe5ddd59d2c", "Random circle composition",                                "Use Random"),

    # ─── Fractals + recursive ──────────────────────────────────
    ("fractals", "koch_curve.py",            "7135e4ed0268f3f79cfc85b46c86d1f8", "Koch snowflake curve",                                     "Koch curve"),
    ("fractals", "sierpinski.py",            "36efb65dd34435143aa4f24263d986f5", "Sierpinski pyramid",                                       "Sierpinski pyramid"),
    ("fractals", "branch_tree.py",           "4e3f21422536bf3a920f764d321ff4ff", "Recursive branching tree",                                 "Branch tree"),
    ("fractals", "recursive_balls.py",       "89a2a28a0e41d985ce662b5fa8a60f0e", "Recursive ball subdivision",                               "Recursive Balls"),
    ("fractals", "rhizome.py",               "e0656b60d31729edb69a18005a3ec936", "Rhizome growth pattern",                                   "Rhizome"),

    # ─── Cellular automata ─────────────────────────────────────
    ("cellular_automata", "rule27.py",       "7889a0a45d5df054d44718c4323f6584", "1D Cellular Automaton — Rule 27",                          "Cellular Automata - Rule 27"),
    ("cellular_automata", "gol_metaballs.py","af6003b400cfee950291a447d726c9ff", "Game of Life rendered as metaballs",                       "Game of life metaballs"),
    ("cellular_automata", "gol_portal.py",   "e8ef4dbe22947e328122a0a42a475bbb", "Game of Life as a portal",                                 "Game of life Portal"),

    # ─── Random + walk ─────────────────────────────────────────
    ("random", "random_balls.py",            "1d90fde6f05069aafaa0e4ca53803d42", "Random ball placement",                                    "Use Random"),
    ("random", "random_bw_tiles.py",         "a9f546145b992440bc29418752204078", "Random black-and-white tile pattern",                      "Random tiles"),
    ("random", "random_walk_world.py",       "371d5f1b1fea8a0ebce9d82ba6aeabe8", "Random walk over icosphere for terrain",                   "Random walk world"),

    # ─── Geometry nodes + generators ───────────────────────────
    ("generators", "tri_geo_nodes.py",       "a79c290c679ca44fe9a4b89f210a2fe7", "Create triangle via Geometry Nodes",                       "Create triangle nodes"),
    ("generators", "cone_instance_nodes.py", "d97b43d0bfb93957121b8bd1610907de", "Cone instance via Geometry Nodes",                         "Create Nodes Cone Instance"),
    ("generators", "sladd_generator.py",     "92fbec5b836d94972885ec60583886b9", "Cable/cord path generator",                                "Corded generator"),
    ("generators", "ten_print.py",           "b948fdf5dd3b1c98e26580c7352d0b1f", "3D 10 PRINT maze algorithm",                               "Joy Divisions"),

    # ─── Metaballs + data-driven ───────────────────────────────
    ("metaballs", "metaballs_from_img.py",   "1c8bfd673e2b357a1d4fc3ed0ecf4df8", "Metaballs placed from image data",                         "Metaballs from img"),
    ("metaballs", "metaball_graffiti.py",    "ec08b1b96da179e279dee0413e3f5e98", "Metaball graffiti",                                        "Metaball graffiti"),

    # ─── Data → form ───────────────────────────────────────────
    ("data", "csv_to_space.py",              "c4120dd96cda730647f02fa3633fa5da", "CSV rows → 3D space placement",                            "Use csv to create a room from prefabs"),
    ("data", "img_to_csv.py",                "3c46686bf8a20d1132392a3a766a8f15", "Processing sketch: image → CSV values",                    "Processing sketch"),
    ("data", "monitor_base.py",              "c7afc1a85d8498066a23f51f2bc1e396", "Monitor base",                                             "Monitor base"),

    # ─── Architecture ──────────────────────────────────────────
    ("architecture", "not_stairs.py",        "b9823b4088b2ddf6104d5f26fdb0ddec", "Irregular stair-like structure",                           "Not stairs"),
    ("architecture", "create_pyramid.py",    "85b96757b5afbe00d1320b78a9fd829c", "Pyramid construction",                                     "Create pyramid"),
    ("architecture", "revolving_column.py",  "b5e228dfb585486fa923fab509d3cef0", "Curve for revolving column lathe",                         "Curve for revolving column"),
    ("architecture", "circle_packing.py",    "93d542d8f7a435dd8396f32e4d9a6b40", "2D circle packing",                                        "Circle packing"),

    # ─── Skeletons + bulge ─────────────────────────────────────
    ("skeletons", "icosphere_skips.py",      "14c1216083173683312ea9805c300db9", "Icosphere with parametric bulge spikes",                   "Parameters for the icosphere and the bulge spik"),

    # ─── Physics ───────────────────────────────────────────────
    ("physics", "anim_mat_physics.py",       "c8ddd537a9ab56658c551844b22b56ab", "Animation + material + rigid body physics",                "Animation, Physics and Materials"),
    ("physics", "softbody.py",               "dc2b02252a0d93f94dc8792a45b64096", "Softbody simulation",                                      "Softbody"),
    ("physics", "portal.py",                 "882b69cb32147d6bd6e0e7c774757ab7", "Portal effect",                                            "Create a Portal"),

    # ─── Pathfinding + agents ──────────────────────────────────
    ("pathfinding", "astar.py",              "317a938c2637a5b42fbf1ec2a2768266", "A* pathfinding",                                           "Path finding"),
    ("pathfinding", "pheromone.py",          "9ffd087e58c90793ca3f54da8e87148c", "Ant pheromone trails",                                     "Pheromone trails"),
]


def gist_raw_url(gist_id: str) -> str:
    return f"https://gist.githubusercontent.com/{USER}/{gist_id}/raw"


def fetch(url: str) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": "ada-research-fetch/1.0"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.read().decode("utf-8", errors="replace")


def standard_header(filename: str, description: str, gist_id: str, section: str) -> str:
    return (
        f"# {filename} — {description}\n"
        f"# Source gist: https://gist.github.com/{USER}/{gist_id}\n"
        f"# Doc section: {section}\n"
        f"#\n"
        f"# Fetched from the palletorsson Blender scripting tutorial.\n"
        f"# Paste into Blender's Scripting workspace and press Alt+P.\n\n"
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--category", help="Fetch one category only")
    args = parser.parse_args()

    targets = GISTS
    if args.category:
        targets = [g for g in GISTS if g[0] == args.category]
        if not targets:
            cats = sorted(set(g[0] for g in GISTS))
            print(f"No scripts in category '{args.category}'. Options: {cats}")
            return 1

    ok = 0
    skipped = 0
    failed: list[str] = []
    for category, filename, gist_id, description, section in targets:
        cat_dir = OUT_DIR / category
        cat_dir.mkdir(parents=True, exist_ok=True)
        out_path = cat_dir / filename
        if out_path.exists() and not args.force:
            skipped += 1
            continue
        url = gist_raw_url(gist_id)
        try:
            raw = fetch(url)
        except Exception as e:
            print(f"  FAIL {category}/{filename}: {e}")
            failed.append(f"{category}/{filename}")
            continue
        header = standard_header(filename, description, gist_id, section)
        # Strip any existing module-level docstring or leading whitespace
        body = raw.lstrip("\ufeff").lstrip()
        out_path.write_text(header + body, encoding="utf-8")
        print(f"  OK   {category}/{filename}  ({len(body)} chars)")
        ok += 1

    print()
    print(f"Fetched: {ok}   Skipped: {skipped}   Failed: {len(failed)}")
    if failed:
        for f in failed:
            print(f"  - {f}")
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
