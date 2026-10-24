"""modular_scan.py — what every registry artifact is made of, read off its scene and script.

The modular class system (commons/modular/terms.json) names things as expressions over
primitives: point, mesh, collider, body, grabbable, label, light, behaviour. Most of the
corpus is not written that way: ~770 of the spine's 1078 scene files are one scripted
root that builds itself in _ready(). This scanner reads BOTH the .tscn (node types,
sub-scene preloads) and the script(s) (the classes it instantiates, the scenes it
preloads) and writes one signature per artifact — which primitives it contains, which
other scenes it is made from — into commons/data/modular_signatures.json, then tries to
match each signature to a term by its primitive set. A match is a hypothesis, printed
as such; the authored terms carry the meaning, the signature carries the evidence.

  python tools/modular_scan.py              # all registry artifacts
  python tools/modular_scan.py --spine      # only artifacts standing in a spine map
  python tools/modular_scan.py --token X    # one, verbosely
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "commons" / "data" / "modular_signatures.json"
TERMS = ROOT / "commons" / "modular" / "terms.json"

# Godot classes → the grammar's primitives
PRIMITIVE_OF = {
    "MeshInstance3D": "mesh", "MultiMeshInstance3D": "mesh", "CSGBox3D": "mesh", "CSGSphere3D": "mesh", "CSGCylinder3D": "mesh",
    "CSGMesh3D": "mesh", "CSGPolygon3D": "mesh", "CSGTorus3D": "mesh", "ImmediateMesh": "mesh", "ArrayMesh": "mesh", "SurfaceTool": "mesh",
    "BoxMesh": "mesh", "SphereMesh": "mesh", "CylinderMesh": "mesh", "PlaneMesh": "mesh", "PrismMesh": "mesh", "TorusMesh": "mesh", "QuadMesh": "mesh",
    "CollisionShape3D": "collider", "CollisionPolygon3D": "collider", "BoxShape3D": "collider", "SphereShape3D": "collider", "CapsuleShape3D": "collider", "ConvexPolygonShape3D": "collider",
    "StaticBody3D": "body", "RigidBody3D": "body", "CharacterBody3D": "body", "Area3D": "body", "SoftBody3D": "body", "AnimatableBody3D": "body",
    "XRToolsPickable": "grabbable", "XRToolsInteractableHandle": "grabbable", "XRToolsInteractableAreaButton": "grabbable", "XRToolsInteractableSlider": "grabbable",
    "Label3D": "label", "Label": "label", "RichTextLabel": "label",
    "OmniLight3D": "light", "SpotLight3D": "light", "DirectionalLight3D": "light",
    "AudioStreamPlayer3D": "sound", "AudioStreamPlayer": "sound",
    "GPUParticles3D": "particles", "CPUParticles3D": "particles",
    "SubViewport": "screen", "Camera3D": "camera", "Timer": "behaviour", "Tween": "behaviour", "AnimationPlayer": "behaviour",
    "ShaderMaterial": "shader", "StandardMaterial3D": "surface",
}
SCENE_PRIMITIVE = {  # a preloaded sub-scene that IS a primitive
    "pickable.tscn": "grabbable", "highlight_ring.tscn": "grabbable", "line_static.tscn": "line", "line_body.gd": "line",
}
NODE_RE = re.compile(r'\[node [^\]]*type="([A-Za-z0-9_]+)"')
EXT_RE = re.compile(r'\[ext_resource type="(PackedScene|Script)"[^\]]*path="([^"]+)"')
NEW_RE = re.compile(r'\b([A-Z][A-Za-z0-9]+)\.new\(\)')
PRELOAD_RE = re.compile(r'(?:preload|load)\("([^"]+\.(?:tscn|gd))"\)')
PROCESS_RE = re.compile(r'func _(?:physics_)?process\(')
SIGNAL_RE = re.compile(r'\.(?:button_pressed|picked_up|dropped|body_entered|area_entered)\b')


def catalog() -> dict:
    r = subprocess.run([sys.executable, str(ROOT / "tools/validate_void_rooms.py"), "--catalog"], capture_output=True, text=True, encoding="utf-8")
    return json.loads(r.stdout) if r.returncode == 0 else {}


def read(p: Path) -> str:
    try:
        return p.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def scan_scene(scene: str, seen: set, depth: int = 0) -> dict:
    """Primitives and sub-scenes of one scene, following scripts and preloads one level down each."""
    prims: Counter = Counter()
    parts: list[str] = []
    behaviour = False
    interaction = False
    path = ROOT / scene.removeprefix("res://")
    if scene in seen or depth > 3 or not path.exists():
        return {"primitives": prims, "parts": parts, "behaviour": behaviour, "interaction": interaction}
    seen.add(scene)
    text = read(path)
    if path.suffix == ".tscn":
        for t in NODE_RE.findall(text):
            p = PRIMITIVE_OF.get(t)
            if p:
                prims[p] += 1
        for kind, ext in EXT_RE.findall(text):
            name = ext.split("/")[-1]
            if name in SCENE_PRIMITIVE:
                prims[SCENE_PRIMITIVE[name]] += 1
                parts.append(name)
            elif kind == "PackedScene":
                parts.append(name)
                sub = scan_scene(ext, seen, depth + 1)
                prims.update(sub["primitives"])
                behaviour = behaviour or sub["behaviour"]
            else:
                sub = scan_scene(ext, seen, depth + 1)
                prims.update(sub["primitives"])
                parts.extend(sub["parts"])
                behaviour = behaviour or sub["behaviour"]
                interaction = interaction or sub["interaction"]
    else:  # .gd
        for cls in NEW_RE.findall(text):
            p = PRIMITIVE_OF.get(cls)
            if p:
                prims[p] += 1
        for pre in PRELOAD_RE.findall(text):
            name = pre.split("/")[-1]
            if name in SCENE_PRIMITIVE:
                prims[SCENE_PRIMITIVE[name]] += 1
                parts.append(name)
            elif pre.endswith(".tscn"):
                parts.append(name)
                sub = scan_scene(pre, seen, depth + 1)
                prims.update(sub["primitives"])
        behaviour = behaviour or bool(PROCESS_RE.search(text))
        interaction = interaction or bool(SIGNAL_RE.search(text))
        if "extends RigidBody3D" in text or "extends XRToolsPickable" in text:
            prims["body"] += 1
        if "extends XRToolsPickable" in text:
            prims["grabbable"] += 1
    return {"primitives": prims, "parts": parts, "behaviour": behaviour, "interaction": interaction}


def term_sets(terms: dict) -> dict[str, set]:
    """The primitive set each term is made of, by walking its build expression."""
    out: dict[str, set] = {}

    def walk(e, acc: set, depth=0):
        if depth > 24 or not isinstance(e, dict):
            return
        if "t" in e:
            acc.add(e["t"]) if e["t"] in ("grabbable",) else None
            t = terms.get(e["t"])
            if t:
                walk(t.get("build"), acc, depth + 1)
        if "p" in e:
            acc.add(e["p"] if e["p"] != "point" else "mesh")
        if e.get("op") == "engine":
            acc.add("behaviour")
        if e.get("op") == "associate" and e.get("story"):
            acc.add("label")
        for k in ("of",):
            if k in e:
                walk(e[k], acc, depth + 1)
        for part in e.get("parts", []) or []:
            walk(part.get("of", part) if isinstance(part, dict) and "of" in part else part, acc, depth + 1)

    for tid, t in terms.items():
        s: set = set()
        walk(t.get("build"), s)
        out[tid] = s
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--spine", action="store_true")
    ap.add_argument("--token", default="")
    a = ap.parse_args()
    cat = catalog()
    terms = json.loads(TERMS.read_text(encoding="utf-8"))["terms"]
    tsets = term_sets(terms)
    tokens = [a.token] if a.token else sorted(cat)
    if a.spine and not a.token:
        sl = json.loads((ROOT / "commons/data/void_spawnlists.json").read_text(encoding="utf-8"))["items"]
        tokens = [t for t in tokens if t in sl and not t.startswith("mod_")]
    sigs = {}
    matched = Counter()
    for tok in tokens:
        scene = cat.get(tok, {}).get("scene", "")
        if not scene:
            continue
        sig = scan_scene(scene, set())
        prims = {k: v for k, v in sig["primitives"].items()}
        pset = set(prims)
        if sig["behaviour"]:
            pset.add("behaviour")
        # best term: the largest term set contained in the signature's set, ties to the deeper term
        best, best_n = "", 0
        for tid, ts in tsets.items():
            if ts and ts <= pset and len(ts) > best_n:
                best, best_n = tid, len(ts)
        sigs[tok] = {"scene": scene, "primitives": prims, "parts": sorted(set(sig["parts"])), "behaviour": sig["behaviour"],
                     "interaction": sig["interaction"], "term": best or None}
        if best:
            matched[best] += 1
    if a.token:
        print(json.dumps(sigs, indent=1))
        return 0
    doc = {"_doc": "GENERATED by tools/modular_scan.py: primitives and parts read off each artifact's scene + script; `term` is the best-matching term of commons/modular/terms.json (a hypothesis).",
           "count": len(sigs), "signatures": sigs,
           "summary": {"with_mesh": sum(1 for s in sigs.values() if "mesh" in s["primitives"]), "with_collider": sum(1 for s in sigs.values() if "collider" in s["primitives"]),
                       "grabbable": sum(1 for s in sigs.values() if "grabbable" in s["primitives"]), "behaviour": sum(1 for s in sigs.values() if s["behaviour"]),
                       "matched": sum(matched.values()), "by_term": dict(matched.most_common())}}
    OUT.write_text(json.dumps(doc, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    s = doc["summary"]
    print(f"wrote {OUT.relative_to(ROOT)}: {len(sigs)} artifacts — mesh {s['with_mesh']}, collider {s['with_collider']}, grabbable {s['grabbable']}, behaviour {s['behaviour']}; {s['matched']} matched a term")
    for tid, n in matched.most_common(12):
        print(f"  {tid:18s} {n}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
