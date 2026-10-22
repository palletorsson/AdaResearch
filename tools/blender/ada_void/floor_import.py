"""floor_import.py — build one Void floor in Blender from the glTF export + the layout.

Sources (both already exist, nothing new is derived here):
  * GET /api/void-layout     — rooms.json (+ revision, catalog, frame, models URL)
  * public/void-models/manifest.json — per floor: structure glb, each artifact's glb
    (or its parts' glbs with their default poses), prop glbs, lamps, Label3D text

Conventions in the .blend
  * a Collection `Void floor <n>` holds sub-collections Architecture, Artifacts,
    Props, Route, Lights
  * every record is a mount Empty NAMED BY ITS RECORD ID carrying the record transform
    (frames.mount_to_blender); the glb meshes hang under it, so moving the Empty is
    the edit and the meshes are the model. Custom props on the Empty say what it is:
    ada_void_kind artifact|copy|prop|part|route, ada_void_id, ada_void_collection
  * a composite artifact's parts are child Empties `<artifact id>/<part>` at the
    part's pose (config.parts[name] or the exported default)
  * the floor's revision, index, trial and map live on the scene (scene.ada_void) and
    the whole rooms document in the scene ID property `ada_void_rooms.json`
"""
from __future__ import annotations

import json
import math
import os
import tempfile
import urllib.request

import bpy
from mathutils import Matrix, Vector

from . import chain, frames

ROOMS_TEXT = "ada_void_rooms.json"
KIND = "ada_void_kind"
RID = "ada_void_id"
COLL = "ada_void_collection"
PART = "ada_void_part"
PARENT = "ada_void_parent"
FLOOR = "ada_void_floor"

# Godot "forward -Z / up +Y" conventions (lights, cameras, Label3D planes) land in
# Blender's "-Z forward / +Y up" after the change of basis plus this quarter turn.
RX90 = Matrix.Rotation(math.radians(90.0), 4, "X")


# ── files ──────────────────────────────────────────────────────────────────

def _prefs():
    ad = bpy.context.preferences.addons.get(__package__)
    return ad.preferences if ad else None


def enc_url() -> str:
    p = _prefs()
    if p and p.enc_url:
        return p.enc_url.rstrip("/")
    return os.environ.get("ADA_ENC_URL", chain.DEFAULT_ENC).rstrip("/")


def public_dir() -> str:
    """The encyclopedia's public/ folder when the add-on runs from the Ada repo (or the
    preference says where it is); empty when the models must be fetched over HTTP."""
    p = _prefs()
    if p and p.public_dir and os.path.isdir(p.public_dir):
        return p.public_dir
    env = os.environ.get("ADA_PUBLIC_DIR", "")
    if env and os.path.isdir(env):
        return env
    here = os.path.dirname(os.path.abspath(__file__))
    guess = os.path.normpath(os.path.join(here, "..", "..", "..", "..", "ada_encyclopedia", "public"))
    return guess if os.path.isdir(guess) else ""


def resolve_public(url: str) -> str:
    """`/void-models/x.glb` -> a local file path (the public folder, or a download)."""
    rel = url.lstrip("/")
    d = public_dir()
    if d:
        p = os.path.join(d, *rel.split("/"))
        if os.path.exists(p):
            return p
    cache = os.path.join(tempfile.gettempdir(), "ada_void_models", *rel.split("/"))
    os.makedirs(os.path.dirname(cache), exist_ok=True)
    if not os.path.exists(cache):
        urllib.request.urlretrieve(enc_url() + "/" + rel, cache)
    return cache


def load_manifest(models_url: str) -> dict:
    with open(resolve_public(models_url), "r", encoding="utf-8") as f:
        return json.load(f)


# ── helpers ────────────────────────────────────────────────────────────────

def hex_rgb(h: str, linear: bool = True):
    h = (h or "ffffff").lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    if not linear:
        return (r, g, b)
    def lin(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (lin(r), lin(g), lin(b))


def m3_to_matrix(b3, loc) -> Matrix:
    m = Matrix.Identity(4)
    for i in range(3):
        for j in range(3):
            m[i][j] = b3[i][j]
    m[0][3], m[1][3], m[2][3] = loc
    return m


def sub_collection(parent: bpy.types.Collection, name: str) -> bpy.types.Collection:
    for c in parent.children:
        if c.name == name:
            return c
    c = bpy.data.collections.new(name)
    parent.children.link(c)
    return c


def link_only(obj: bpy.types.Object, coll: bpy.types.Collection) -> None:
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    coll.objects.link(obj)


def new_empty(name: str, coll: bpy.types.Collection, display="PLAIN_AXES", size=0.5) -> bpy.types.Object:
    o = bpy.data.objects.new(name, None)
    o.empty_display_type = display
    o.empty_display_size = size
    coll.objects.link(o)
    return o


def floor_collection(index: int, create: bool = True) -> bpy.types.Collection | None:
    name = f"Void floor {index}"
    for c in bpy.data.collections:
        if c.name == name:
            return c
    if not create:
        return None
    c = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(c)
    return c


def clear_floor(index: int) -> None:
    root = floor_collection(index, create=False)
    if root is None:
        return
    def wipe(coll):
        for ch in list(coll.children):
            wipe(ch)
        for o in list(coll.objects):
            bpy.data.objects.remove(o, do_unlink=True)
        bpy.data.collections.remove(coll)
    wipe(root)
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.lights, bpy.data.curves, bpy.data.images):
        for d in list(block):
            if d.users == 0:
                block.remove(d)


# ── glb import with a per-file cache ───────────────────────────────────────

class GlbCache:
    def __init__(self):
        self.templates: dict[str, list[bpy.types.Object]] = {}

    def instance(self, url: str, parent: bpy.types.Object, coll: bpy.types.Collection) -> list[bpy.types.Object]:
        """Import `url` once; every later use is a linked-data copy of the hierarchy."""
        path = resolve_public(url)
        if path not in self.templates:
            before = set(bpy.data.objects)
            bpy.ops.import_scene.gltf(filepath=path)
            new = [o for o in bpy.data.objects if o not in before]
            roots = [o for o in new if o.parent is None or o.parent not in new]
            self.templates[path] = new
            self._attach(roots, new, parent, coll)
            return new
        src = self.templates[path]
        mapping: dict[bpy.types.Object, bpy.types.Object] = {}
        for o in src:
            c = o.copy()
            mapping[o] = c
        for o, c in mapping.items():
            if o.parent in mapping:
                c.parent = mapping[o.parent]
                c.matrix_parent_inverse = o.matrix_parent_inverse.copy()
            coll.objects.link(c)
        roots = [mapping[o] for o in src if o.parent is None or o.parent not in src]
        for r in roots:
            r.parent = parent
            r.matrix_parent_inverse = Matrix.Identity(4)
        return list(mapping.values())

    @staticmethod
    def _attach(roots, objs, parent, coll):
        for o in objs:
            link_only(o, coll)
            o.select_set(False)
        for r in roots:
            local = r.matrix_world.copy()
            r.parent = parent
            r.matrix_parent_inverse = Matrix.Identity(4)
            r.matrix_basis = local


# ── lamps and labels (from the manifest, in the mount's frame) ─────────────

def add_lamps(lamps: list, parent: bpy.types.Object, coll: bpy.types.Collection, prefix: str) -> None:
    for i, lamp in enumerate(lamps or []):
        if lamp.get("visible") is False:
            continue
        kind = "SPOT" if lamp.get("type") == "spot" else "POINT"
        data = bpy.data.lights.new(f"{prefix}/{lamp.get('name', kind.lower())}", kind)
        data.color = hex_rgb(str(lamp.get("color", "ffffff")))
        energy = float(lamp.get("energy", 1.0))
        data.energy = energy * (150.0 if kind == "SPOT" else 100.0)
        data.use_shadow = bool(lamp.get("shadow", True))
        rng = float(lamp.get("range", 10.0))
        data.use_custom_distance = True
        data.cutoff_distance = max(0.5, rng)
        data.shadow_soft_size = 0.15
        if kind == "SPOT":
            data.spot_size = math.radians(min(179.0, 2.0 * float(lamp.get("angle", 45.0))))
            data.spot_blend = float(lamp.get("feather", 0.35))
        o = bpy.data.objects.new(data.name, data)
        coll.objects.link(o)
        b3, loc = frames.godot_matrix16_to_blender(lamp["matrix"])
        o.parent = parent
        o.matrix_parent_inverse = Matrix.Identity(4)
        o.matrix_basis = m3_to_matrix(b3, loc) @ RX90
        o[KIND] = "lamp"


def add_labels(labels: list, parent: bpy.types.Object, coll: bpy.types.Collection, prefix: str) -> None:
    for i, lab in enumerate(labels or []):
        text = str(lab.get("text", "")).strip()
        if not text:
            continue
        cu = bpy.data.curves.new(f"{prefix}/label{i}", "FONT")
        cu.body = text
        cu.size = float(lab.get("font_size", 32.0)) * float(lab.get("pixel_size", 0.005))
        cu.align_x = "CENTER"
        cu.align_y = "CENTER"
        mat = bpy.data.materials.new(f"{prefix}/label{i}")
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            r, g, b = hex_rgb(str(lab.get("color", "ffffff"))[:6])
            bsdf.inputs["Base Color"].default_value = (r, g, b, 1.0)
            bsdf.inputs["Emission Color"].default_value = (r, g, b, 1.0)
            bsdf.inputs["Emission Strength"].default_value = 0.6
        cu.materials.append(mat)
        o = bpy.data.objects.new(cu.name, cu)
        coll.objects.link(o)
        b3, loc = frames.godot_matrix16_to_blender(lab["matrix"])
        o.parent = parent
        o.matrix_parent_inverse = Matrix.Identity(4)
        o.matrix_basis = m3_to_matrix(b3, loc) @ RX90
        o[KIND] = "label"


# ── the floor ──────────────────────────────────────────────────────────────

def set_rooms_text(rooms: dict) -> None:
    """The whole rooms document, kept on the scene as an ID property string (a Text
    datablock takes tens of seconds to write and read an 800 KB single line)."""
    bpy.context.scene[ROOMS_TEXT] = json.dumps(rooms)


def get_rooms() -> dict | None:
    raw = bpy.context.scene.get(ROOMS_TEXT)
    if not raw:
        return None
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return None


def mount(name: str, coll: bpy.types.Collection, rec: dict, kind: str, collection_key: str,
          index: int, catalog: dict, display="PLAIN_AXES") -> bpy.types.Object:
    pos = rec.get("position")
    if not (isinstance(pos, list) and len(pos) >= 2):
        pos = (catalog.get("stations") or {}).get(str(rec.get("station", "")), [0, 0])
    height = float(rec.get("height", 0.0)) if kind != "prop" else 0.0
    loc, rot, scl = frames.mount_to_blender(pos, height, rec.get("facing", 0.0), rec.get("scale", 1.0))
    o = new_empty(name, coll, display, 0.6 if kind != "part" else 0.3)
    o.location = loc
    o.rotation_mode = "XYZ"
    o.rotation_euler = rot
    o.scale = scl
    o[KIND] = kind
    o[RID] = str(rec.get("id", name))
    o[COLL] = collection_key
    o[FLOOR] = index
    return o


def build_floor(context, index: int, trial: str = "", labels: bool = True, log=print) -> dict:
    """Import floor `index`. Returns {'map', 'revision', 'artifacts', 'props', 'parts', 'checks'}."""
    enc = enc_url()
    layout = chain.get_layout(enc, trial)
    rooms = layout["rooms"]
    floors = rooms.get("floors", [])
    if index < 0 or index >= len(floors):
        raise ValueError(f"floor {index} is not one of the {len(floors)} floors")
    rec = floors[index]
    manifest = load_manifest(layout.get("models") or "/void-models/manifest.json")
    mf = (manifest.get("floors") or {}).get(str(index), {})
    catalog = layout.get("catalog") or {}

    clear_floor(index)
    root = floor_collection(index)
    arch = sub_collection(root, "Architecture")
    arts = sub_collection(root, "Artifacts")
    props = sub_collection(root, "Props")
    route = sub_collection(root, "Route")
    lights = sub_collection(root, "Lights")
    cache = GlbCache()
    stats = {"map": rec.get("map", ""), "revision": layout.get("revision", ""), "artifacts": 0, "props": 0,
             "parts": 0, "models_missing": [], "checks": {}}

    # architecture: the floor's structure glb, in the floor's own frame
    arch_mount = new_empty(f"floor-{index}", arch, "CUBE", 1.0)
    arch_mount[KIND] = "architecture"
    arch_mount[FLOOR] = index
    structure = mf.get("structure") or {}
    if structure.get("url"):
        cache.instance(structure["url"], arch_mount, arch)
    if labels:
        add_labels(structure.get("labels") or [], arch_mount, arch, f"floor-{index}")
    add_lamps(structure.get("lights") or [], arch_mount, lights, f"floor-{index}")

    # artifacts and copies
    for coll_key in ("artifacts", "copies"):
        for a in rec.get(coll_key, []) or []:
            if not isinstance(a, dict) or "id" not in a:
                continue
            aid = str(a["id"])
            cfg = a.get("config") or {}
            src = cfg.get("editor_source") or {}
            exported = (manifest.get("floors") or {}).get(str(src.get("floor", index)), {}).get("artifacts", {}).get(str(src.get("id", aid)))
            actual = exported if exported and exported.get("artifact") == a.get("artifact") else None
            kind = "copy" if coll_key == "copies" else "artifact"
            m = mount(aid, arts, a, kind, coll_key, index, catalog, "PLAIN_AXES")
            stats["artifacts"] += 1
            only = cfg.get("only_parts")
            if actual is None:
                stats["models_missing"].append(aid)
                continue
            model = actual.get("model")
            if model and not only:
                if model.get("url"):
                    cache.instance(model["url"], m, arts)
                if labels:
                    add_labels(model.get("labels") or [], m, arts, aid)
                add_lamps(model.get("lights") or [], m, lights, aid)
            for pname, pmodel in (actual.get("parts") or {}).items():
                if not pmodel.get("default"):
                    continue
                if only and pname not in only:
                    continue
                pose = (cfg.get("parts") or {}).get(pname) or {}
                lpos = pose.get("position") or pmodel["default"].get("position", [0, 0, 0])
                lrot = pose.get("rotation") or pmodel["default"].get("rotation", [0, 0, 0])
                loc, b3 = frames.part_to_blender(lpos, lrot)
                pm = new_empty(f"{aid}/{pname}", arts, "SPHERE", 0.25)
                pm.parent = m
                pm.matrix_parent_inverse = Matrix.Identity(4)
                pm.matrix_basis = m3_to_matrix(b3, loc)
                pscale = pmodel.get("scale") or [1, 1, 1]
                pm[KIND] = "part"
                pm[RID] = aid
                pm[PART] = pname
                pm[PARENT] = aid
                pm[COLL] = coll_key
                pm[FLOOR] = index
                pm["ada_void_pose_position"] = json.dumps(lpos)
                pm["ada_void_pose_rotation"] = json.dumps(lrot)
                stats["parts"] += 1
                if pmodel.get("url"):
                    objs = cache.instance(pmodel["url"], pm, arts)
                    # the exporter wrote the part in its own frame but recorded the part's scale
                    for o in objs:
                        if o.parent is pm:
                            o.scale = Vector(o.scale) * Vector(pscale)
                if labels:
                    add_labels(pmodel.get("labels") or [], pm, arts, f"{aid}/{pname}")
                add_lamps(pmodel.get("lights") or [], pm, lights, f"{aid}/{pname}")

    # props: catalog glb per kind, lamps per floor and kind
    for p in rec.get("props", []) or []:
        if not isinstance(p, dict) or "id" not in p:
            continue
        pid = str(p["id"])
        kind = str(p.get("kind", ""))
        m = mount(pid, props, p, "prop", "props", index, catalog, "CIRCLE")
        stats["props"] += 1
        base = (mf.get("interface_models") or {}).get(kind + "|" + str(p.get("target", ""))) or (manifest.get("props") or {}).get(kind)
        if base and base.get("url"):
            cache.instance(base["url"], m, props)
        elif base is None:
            stats["models_missing"].append(pid)
        lamps = (mf.get("prop_lights") or {}).get(kind) or (base or {}).get("lights") or []
        add_lamps(lamps, m, lights, pid)

    # route waypoints: small empties, read back as the viewer does (+0.035 over height)
    for i, w in enumerate(rec.get("route", []) or []):
        pos = w.get("position", [0, 0])
        h = float(w.get("height", 0.0)) + 0.035
        o = new_empty(f"route/{i} {w.get('label', '')}".strip(), route, "SPHERE", 0.12)
        o.location = frames.godot_to_blender_point([pos[0], h, pos[1]])
        o[KIND] = "route"
        o[RID] = str(i)
        o[COLL] = "route"
        o[FLOOR] = index

    # the scene remembers what it imported
    s = context.scene.ada_void
    s.floor = index
    s.trial = trial
    s.revision = str(layout.get("revision", ""))
    s.map = str(rec.get("map", ""))
    s.models = str(layout.get("models") or "/void-models/manifest.json")
    s.status = f"imported floor {index} ({rec.get('map', '')}) at revision {s.revision[:12]}"
    set_rooms_text(rooms)
    context.scene["ada_void_lighting"] = json.dumps(manifest.get("lighting") or {})
    log(f"[ada_void] {s.status}: {stats['artifacts']} artifact(s), {stats['parts']} part(s), {stats['props']} prop(s)")
    if stats["models_missing"]:
        log(f"[ada_void] no exported model for: {', '.join(stats['models_missing'])}")
    return stats


def floor_mounts(index: int) -> list[bpy.types.Object]:
    """Every mount Empty of a floor that a publish reads back."""
    root = floor_collection(index, create=False)
    if root is None:
        return []
    out = []
    def walk(coll):
        for o in coll.objects:
            if o.get(KIND) in ("artifact", "copy", "prop", "part", "route"):
                out.append(o)
        for ch in coll.children:
            walk(ch)
    walk(root)
    return out
