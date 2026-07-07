"""mine_construction_edges.py — the construction DAG: what is each artifact BUILT FROM?

The strongest ordering principle in the book's lineage (Nature of Code) is
compositional: B is made of A, so A comes first. That order is not a score —
it is a fact recoverable from code. This tool mines every artifact's .gd for:

  · ATOMS   — the Godot primitives it instantiates (BoxMesh -> cube,
              ImmediateMesh -> line, MultiMesh -> field, ...)
  · USES    — other ARTIFACTS it preloads / instantiates / references by
              class_name (artifact -> artifact construction edges)

From the artifact->artifact edges it derives a CONSTRUCTION DEPTH:
  depth 1 = built from atoms only; depth n = 1 + max(depth of parts).
Depth is a partial order — the mineable half of "what order do we teach in".

Validation: per spine sequence, Spearman rank correlation between construction
depth and the three-orders consensus position (do the two orders agree?).

Output:
  doc/book/construction_edges.json
  <encyclopedia>/public/construction-edges.json

Usage:
  python tools/mine_construction_edges.py [--seq=<id>] [--top=N]
"""

import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENC = Path(os.environ.get("ADA_ENCYCLOPEDIA_PATH", ROOT.parent / "ada_encyclopedia"))
REG_DIR = ROOT / "commons" / "artifacts" / "registry"
THREE_ORDERS = ENC / "public" / "three-orders.json"
CHAPTER_MAPS = ROOT / "doc" / "book" / "chapter_maps.json"
OUT_BOOK = ROOT / "doc" / "book" / "construction_edges.json"
OUT_WEB = ENC / "public" / "construction-edges.json"

# Godot primitive/node classes -> concept atoms. The atom names are the
# book's vocabulary: what the walker would call the part.
ATOM_MAP = {
    "BoxMesh": "cube", "CSGBox3D": "cube",
    "SphereMesh": "sphere", "CSGSphere3D": "sphere", "PointMesh": "point",
    "CylinderMesh": "cylinder", "CSGCylinder3D": "cylinder",
    "CapsuleMesh": "capsule",
    "PlaneMesh": "plane", "QuadMesh": "plane", "CSGMesh3D": "csg",
    "PrismMesh": "prism", "TorusMesh": "torus", "CSGTorus3D": "torus",
    "TextMesh": "text", "Label3D": "text",
    "ImmediateMesh": "line", "Curve3D": "line", "Path3D": "line",
    "SurfaceTool": "generated_mesh", "ArrayMesh": "generated_mesh",
    "MultiMesh": "field", "MultiMeshInstance3D": "field",
    "GPUParticles3D": "particles", "CPUParticles3D": "particles",
    "ShaderMaterial": "shader", "SubViewport": "screen_2d",
    "RigidBody3D": "physics_body", "SoftBody3D": "soft_body",
    "Area3D": "touch", "GridMap": "grid",
}
ATOM_RE = re.compile(r"\b(" + "|".join(ATOM_MAP) + r")\b")
EXTENDS_PATH_RE = re.compile(r"^extends\s+[\"']res://([^\"']+)[\"']", re.M)
IDENT_RE = re.compile(r"\b[A-Z][A-Za-z0-9_]{2,}\b")

GODOT_TREE = ROOT / "commons" / "data" / "godot_class_tree.json"

# The Godot DOCS order, as ancestor-class -> (stage_rank, stage_name).
# Ranks follow the official tutorial TOC: nodes/scenes -> scripting -> 2D ->
# 3D -> animation/UI -> physics/particles -> soft-body/shaders/viewports ->
# low-level rendering/audio/networking. First matching ancestor wins, so the
# specific (SoftBody3D) is checked before the general (MeshInstance3D).
DOCS_STAGE = [
    ("SoftBody3D", 6, "soft_body"),
    ("GPUParticles3D", 5, "particles"), ("CPUParticles3D", 5, "particles"),
    ("Joint3D", 5, "physics"), ("PhysicsBody3D", 5, "physics"),
    ("Area3D", 5, "physics"), ("CollisionObject3D", 5, "physics"),
    ("RayCast3D", 5, "physics"), ("ShapeCast3D", 5, "physics"),
    ("VisualShader", 6, "shaders"), ("ShaderMaterial", 6, "shaders"), ("Shader", 6, "shaders"),
    ("SubViewport", 6, "viewports"), ("Viewport", 6, "viewports"),
    ("RenderingDevice", 7, "low_level_rendering"), ("RenderingServer", 7, "low_level_rendering"),
    ("AudioStreamPlayer", 7, "audio"), ("AudioStream", 7, "audio"),
    ("MultiplayerAPI", 7, "networking"), ("MultiplayerPeer", 7, "networking"),
    ("AnimationMixer", 4, "animation"), ("Tween", 4, "animation"),
    ("Control", 4, "ui"),
    ("Camera3D", 3, "3d"), ("Light3D", 3, "3d"),
    ("GeometryInstance3D", 3, "3d"), ("VisualInstance3D", 3, "3d"), ("Node3D", 3, "3d"),
    ("CanvasItem", 2, "2d"),
    ("Node", 1, "nodes_scenes"),
    ("Resource", 1, "scripting"), ("RefCounted", 1, "scripting"), ("Object", 1, "scripting"),
]

# The atom LADDER — a design claim, kept visible: how "advanced" is each part?
# point/sphere before line before surface before volume before aggregate
# before generated/simulated. Grade = the highest rung an artifact stands on.
ATOM_RANK = {
    "point": 1, "sphere": 1,
    "line": 2, "text": 2, "touch": 2,
    "plane": 3, "cube": 3, "cylinder": 3, "capsule": 3, "prism": 3, "torus": 3,
    "grid": 4, "csg": 4,
    "field": 5, "particles": 5, "screen_2d": 5, "generated_mesh": 5,
    "physics_body": 6, "soft_body": 6, "shader": 6,
}
PRELOAD_RE = re.compile(r"(?:preload|load)\(\s*[\"']res://([^\"']+)[\"']\s*\)")
EXTENDS_RE = re.compile(r"^extends\s+([A-Za-z_][\w]*)", re.M)
SHADER_RE = re.compile(r"\.gdshader$")


def jload(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def load_registry():
    """lookup -> {scene, class_name}; plus class_name -> lookup."""
    meta, by_class = {}, {}
    for f in REG_DIR.glob("*.json"):
        try:
            d = jload(f)
        except Exception:
            continue
        for lk, m in (d.get("artifacts") or {}).items():
            meta.setdefault(lk, m)
            cn = (m or {}).get("class_name")
            if cn:
                by_class.setdefault(cn, lk)
    return meta, by_class


def index_gd():
    idx = {}
    for base in (ROOT / "commons", ROOT / "algorithms"):
        for p in base.rglob("*.gd"):
            idx.setdefault(p.stem, p)
    return idx


def gd_path_for(lookup, meta, gd_idx):
    m = meta.get(lookup) or {}
    scene = m.get("scene") or ""
    if scene.startswith("res://"):
        p = ROOT / scene[len("res://"):]
        gd = p.with_suffix(".gd")
        if gd.exists():
            return gd
    return gd_idx.get(lookup)


class EngineTree:
    """Godot's ClassDB inheritance map (dumped by dump_godot_class_tree.gd)."""

    def __init__(self):
        self.parent = {}
        if GODOT_TREE.exists():
            self.parent = jload(GODOT_TREE)
        self.classes = set(self.parent)
        self._stage = {a: (r, n) for a, r, n in DOCS_STAGE}

    def chain(self, cls):
        out = []
        while cls and cls in self.parent:
            out.append(cls)
            cls = self.parent.get(cls) or None
        return out

    def depth(self, cls):
        return len(self.chain(cls))

    def stage(self, cls):
        for anc in self.chain(cls):
            if anc in self._stage:
                return self._stage[anc]
        return (0, None)


def script_engine_base(gd, gd_idx, by_class_path, tree, _memo={}):
    """Follow a .gd's extends chain (scripts included) to its engine base.
    Returns (engine_class, script_hops)."""
    key = str(gd)
    if key in _memo:
        return _memo[key]
    _memo[key] = (None, 0)  # cycle guard
    try:
        src = gd.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return _memo[key]
    base, hops = None, 0
    m = EXTENDS_PATH_RE.search(src)
    if m:
        nxt = ROOT / m.group(1)
        if nxt.exists():
            base, hops = script_engine_base(nxt, gd_idx, by_class_path, tree)
            hops += 1
    else:
        m = EXTENDS_RE.search(src)
        if m:
            name = m.group(1)
            if name in tree.classes:
                base, hops = name, 0
            else:
                nxt = by_class_path.get(name) or gd_idx.get(name)
                if nxt and nxt.exists() and nxt != gd:
                    base, hops = script_engine_base(nxt, gd_idx, by_class_path, tree)
                    hops += 1
    _memo[key] = (base, hops)
    return _memo[key]


def mine(lookup, meta, gd_idx, by_class, stem_to_lookup):
    gd = gd_path_for(lookup, meta, gd_idx)
    if gd is None or not gd.exists():
        return None
    try:
        src = gd.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return None

    atoms = {}
    for m in ATOM_RE.finditer(src):
        a = ATOM_MAP[m.group(1)]
        atoms[a] = atoms.get(a, 0) + 1

    uses = set()
    for m in PRELOAD_RE.finditer(src):
        res = m.group(1)
        stem = Path(res).stem
        if SHADER_RE.search(res):
            atoms["shader"] = atoms.get("shader", 0) + 1
            continue
        tgt = stem_to_lookup.get(stem)
        if tgt and tgt != lookup:
            uses.add(tgt)

    # class_name references to other artifacts (instantiation or typing)
    for cn, tgt in by_class.items():
        if tgt == lookup:
            continue
        if re.search(r"\b" + re.escape(cn) + r"\b", src):
            uses.add(tgt)

    ext = EXTENDS_RE.search(src)
    base = ext.group(1) if ext else None
    if base in by_class and by_class[base] != lookup:
        uses.add(by_class[base])

    return {"gd": str(gd.relative_to(ROOT)), "atoms": atoms, "uses": sorted(uses)}


def depths(nodes):
    """construction depth: 1 = atoms only; 1 + max(depth of used artifacts)."""
    depth = {}

    def visit(lk, stack):
        if lk in depth:
            return depth[lk]
        if lk in stack:  # cycle guard: mutual references count as siblings
            return 1
        node = nodes.get(lk)
        if not node:
            return 0
        stack.add(lk)
        used = [visit(u, stack) for u in node["uses"] if u in nodes]
        stack.discard(lk)
        depth[lk] = 1 + max(used) if used else 1
        return depth[lk]

    for lk in nodes:
        visit(lk, set())
    return depth


def spearman(xs, ys):
    n = len(xs)
    if n < 3:
        return None
    def ranks(v):
        order = sorted(range(n), key=lambda i: v[i])
        r = [0.0] * n
        i = 0
        while i < n:
            j = i
            while j + 1 < n and v[order[j + 1]] == v[order[i]]:
                j += 1
            avg = (i + j) / 2 + 1
            for k in range(i, j + 1):
                r[order[k]] = avg
            i = j + 1
        return r
    rx, ry = ranks(xs), ranks(ys)
    mx, my = sum(rx) / n, sum(ry) / n
    cov = sum((rx[i] - mx) * (ry[i] - my) for i in range(n))
    vx = sum((rx[i] - mx) ** 2 for i in range(n)) ** 0.5
    vy = sum((ry[i] - my) ** 2 for i in range(n)) ** 0.5
    return cov / (vx * vy) if vx and vy else None


def main():
    only, top = None, 12
    for a in sys.argv[1:]:
        if a.startswith("--seq="):
            only = a.split("=", 1)[1]
        if a.startswith("--top="):
            top = int(a.split("=", 1)[1])

    meta, by_class = load_registry()
    gd_idx = index_gd()
    stem_to_lookup = {}
    for lk, m in meta.items():
        scene = (m or {}).get("scene") or ""
        stem_to_lookup.setdefault(Path(scene).stem or lk, lk)
        stem_to_lookup.setdefault(lk, lk)

    tree = EngineTree()
    by_class_path = {}
    for cn, lk in by_class.items():
        p = gd_path_for(lk, meta, gd_idx)
        if p:
            by_class_path[cn] = p

    nodes = {}
    for lk in meta:
        node = mine(lk, meta, gd_idx, by_class, stem_to_lookup)
        if node:
            nodes[lk] = node
            # ── engine view: real extends chain + docs-order stage ─────────
            gd = ROOT / node["gd"]
            base, hops = script_engine_base(gd, gd_idx, by_class_path, tree)
            try:
                src = gd.read_text(encoding="utf-8", errors="replace")
            except Exception:
                src = ""
            used = sorted(set(IDENT_RE.findall(src)) & tree.classes)
            stage_rank, stage_name = tree.stage(base) if base else (0, None)
            for cls in used:
                r, n = tree.stage(cls)
                if r > stage_rank:
                    stage_rank, stage_name = r, n
            node["engine"] = {
                "base": base,
                "engine_depth": tree.depth(base) if base else 0,
                "script_hops": hops,
                "stage": stage_rank,
                "stage_name": stage_name,
                "classes_used": used[:12],
            }

    depth = depths(nodes)
    for lk, d in depth.items():
        nodes[lk]["depth"] = d

    # construction GRADE: highest atom rung + a rung per level of artifact
    # composition — orderable even where artifact->artifact edges are absent.
    grade = {}
    for lk, n in nodes.items():
        rung = max((ATOM_RANK.get(a, 3) for a in n["atoms"]), default=0)
        grade[lk] = rung + (n["depth"] - 1)
        n["grade"] = grade[lk]

    # validation: depth vs three-orders consensus, per spine sequence
    orders = {s["seq"]: s for s in jload(THREE_ORDERS).get("sequences", [])}
    chapters = jload(CHAPTER_MAPS)["chapters"]
    agreement = {}
    for seq in chapters:
        if only and seq != only:
            continue
        entry = orders.get(seq)
        if not entry:
            continue
        pearls, ped = entry.get("pearls", []), entry.get("ped", [])
        onto, crit = entry.get("onto", []), entry.get("crit", [])
        cons, dep, grd, stg = [], [], [], []
        for i, name in enumerate(pearls):
            if name in depth:
                vals = [ax[i] for ax in (ped, onto, crit) if i < len(ax)]
                cons.append(sum(vals) / len(vals))
                dep.append(depth[name])
                grd.append(grade.get(name, 0))
                eng = nodes[name].get("engine", {})
                stg.append(eng.get("stage", 0) * 100 + eng.get("engine_depth", 0)
                           + eng.get("script_hops", 0))
        rho_d = spearman(cons, dep)
        rho_g = spearman(cons, grd)
        rho_s = spearman(cons, stg)
        agreement[seq] = {"n": len(cons),
                          "spearman_depth": round(rho_d, 3) if rho_d is not None else None,
                          "spearman_grade": round(rho_g, 3) if rho_g is not None else None,
                          "spearman_engine": round(rho_s, 3) if rho_s is not None else None}

    edge_count = sum(len(n["uses"]) for n in nodes.values())
    out = {
        "generated_by": "tools/mine_construction_edges.py",
        "note": "atoms = Godot primitives as concept parts; uses = artifact->artifact construction edges; depth = 1 + max(depth of parts)",
        "nodes": nodes,
        "consensus_agreement": agreement,
    }
    for path in (OUT_BOOK, OUT_WEB):
        with open(path, "w", encoding="utf-8") as f:
            json.dump(out, f, ensure_ascii=False, indent=1)

    hist = {}
    for d in depth.values():
        hist[d] = hist.get(d, 0) + 1
    print(f"construction: {len(nodes)} artifacts mined, {edge_count} artifact->artifact edges")
    print(f"depth histogram: {dict(sorted(hist.items()))}")
    deep = sorted(nodes, key=lambda k: -nodes[k]["depth"])[:top]
    print("deepest constructions:")
    for lk in deep:
        n = nodes[lk]
        print(f"  d{n['depth']} {lk} <- {', '.join(n['uses'][:5]) or 'atoms only'}")
    ghist = {}
    for g in grade.values():
        ghist[g] = ghist.get(g, 0) + 1
    print(f"grade histogram (atom rung + composition): {dict(sorted(ghist.items()))}")
    shist = {}
    for n in nodes.values():
        s = n.get("engine", {}).get("stage_name")
        shist[s] = shist.get(s, 0) + 1
    print(f"engine stage histogram (Godot docs order): {dict(sorted(shist.items(), key=lambda kv: -kv[1]))}")
    print("construction vs consensus (spearman, per spine seq):")
    for seq, a in sorted(agreement.items(),
                         key=lambda kv: -(kv[1]['spearman_engine'] if kv[1]['spearman_engine'] is not None else -2)):
        print(f"  {seq}: engine rho={a['spearman_engine']}  grade rho={a['spearman_grade']}  "
              f"depth rho={a['spearman_depth']} (n={a['n']})")
    print(f"-> {OUT_BOOK}\n-> {OUT_WEB}")


if __name__ == "__main__":
    main()
