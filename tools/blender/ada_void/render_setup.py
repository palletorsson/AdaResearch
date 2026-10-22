"""render_setup.py — one click from an imported floor to a Cycles render.

  * Cycles, GPU when one is configured (OPTIX, else CUDA, else CPU), denoised
  * world: the Void's baked evening sky (public/void-models/evening-sky.exr, the
    export's `lighting.sky_url`) as an environment texture, or the ambient colour
    when the bake is absent; the sun from `lighting.sun_matrix`
  * two cameras: 'Arrival' at the floor's route waypoint of that name (eye height
    1.6 m) looking along the route to the next waypoint, 28 mm; and 'Overview', a
    raised three-quarter view from the Arrival side aimed at the middle of the works
    (the Arrival point of floor 10 stands inside a large part); 1920x1080
  * optional fog as a thin world volume in the export's fog colour

What does NOT survive the glTF export (and so is not in a Blender render):
procedural shaders (`shader_material_previews` in the manifest: a static colour
stands in), Label3D text (re-created here as Blender text objects from the
manifest's label data, in a Blender font), particles, animation and every
behaviour; a glb carries the geometry and PBR materials of one moment.
"""
from __future__ import annotations

import json
import math

import bpy
from mathutils import Matrix, Vector

from . import frames
from .floor_import import RX90, floor_collection, hex_rgb, m3_to_matrix, resolve_public, sub_collection, new_empty, KIND


def _gpu(scene) -> str:
    prefs = bpy.context.preferences.addons.get("cycles")
    if not prefs:
        return "CPU"
    cp = prefs.preferences
    for kind in ("OPTIX", "CUDA", "HIP", "ONEAPI", "METAL"):
        try:
            cp.compute_device_type = kind
        except TypeError:
            continue
        devices = cp.get_devices_for_type(kind)
        if devices:
            for d in devices:
                d.use = True
            scene.cycles.device = "GPU"
            return kind
    cp.compute_device_type = "NONE"
    scene.cycles.device = "CPU"
    return "CPU"


def setup_world(scene, lighting: dict, fog: bool) -> str:
    world = scene.world or bpy.data.worlds.new("Void evening")
    scene.world = world
    world.use_nodes = True
    nt = world.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputWorld")
    bg = nt.nodes.new("ShaderNodeBackground")
    nt.links.new(bg.outputs[0], out.inputs["Surface"])
    note = "ambient colour"
    sky = lighting.get("sky_url")
    if sky:
        try:
            path = resolve_public(sky)
            img = bpy.data.images.load(path, check_existing=True)
            env = nt.nodes.new("ShaderNodeTexEnvironment")
            env.image = img
            nt.links.new(env.outputs[0], bg.inputs["Color"])
            bg.inputs["Strength"].default_value = 1.0
            note = "sky bake " + sky
        except Exception as e:  # noqa: BLE001
            note = f"ambient colour (sky bake unavailable: {e})"
    if note.startswith("ambient"):
        r, g, b = hex_rgb(str(lighting.get("ambient_color", "aeaccd")))
        bg.inputs["Color"].default_value = (r, g, b, 1.0)
        bg.inputs["Strength"].default_value = float(lighting.get("ambient_energy", 0.3)) * 2.0
    if fog:
        vol = nt.nodes.new("ShaderNodeVolumeScatter")
        r, g, b = hex_rgb(str(lighting.get("fog_color", "574e6c")))
        vol.inputs["Color"].default_value = (r, g, b, 1.0)
        vol.inputs["Density"].default_value = 0.012
        nt.links.new(vol.outputs[0], out.inputs["Volume"])
        note += " + fog volume"
    return note


def setup_sun(scene, lighting: dict, coll) -> None:
    for o in list(coll.objects):
        if o.get(KIND) == "sun":
            bpy.data.objects.remove(o, do_unlink=True)
    m16 = lighting.get("sun_matrix")
    if not m16:
        return
    data = bpy.data.lights.new("Void sun", "SUN")
    data.color = hex_rgb(str(lighting.get("sun_color", "ffffff")))
    data.energy = float(lighting.get("sun_energy", 0.2)) * 5.0
    data.angle = math.radians(1.5)
    o = bpy.data.objects.new(data.name, data)
    coll.objects.link(o)
    b3, _loc = frames.godot_matrix16_to_blender(m16)
    o.matrix_world = m3_to_matrix(b3, [0.0, 0.0, 30.0]) @ RX90
    o[KIND] = "sun"


def arrival_camera(scene, index: int, rooms: dict, coll) -> dict:
    """A camera at the route's 'Arrival' waypoint looking along the route."""
    rec = rooms["floors"][index]
    route = rec.get("route") or []
    if not route:
        start = [0.0, 1.6, 8.0]
        target = [0.0, 1.4, 0.0]
        label = "no route: default"
    else:
        i0 = next((i for i, w in enumerate(route) if str(w.get("label", "")).lower().startswith("arrival")), 0)
        w0 = route[i0]
        w1 = route[i0 + 1] if i0 + 1 < len(route) else (route[i0 - 1] if i0 > 0 else None)
        p0 = w0.get("position", [0, 0])
        start = [float(p0[0]), float(w0.get("height", 0.0)) + 1.6, float(p0[1])]
        if w1 is None:
            target = [0.0, 1.4, 0.0]
        else:
            p1 = w1.get("position", [0, 0])
            target = [float(p1[0]), float(w1.get("height", 0.0)) + 1.4, float(p1[1])]
        label = f"'{w0.get('label', '')}' -> '{(w1 or {}).get('label', '')}'"
    for o in list(coll.objects):
        if o.get(KIND) == "camera":
            bpy.data.objects.remove(o, do_unlink=True)
    cam = bpy.data.cameras.new(f"Arrival camera floor {index}")
    cam.lens = 28.0
    cam.clip_end = 400.0
    o = bpy.data.objects.new(cam.name, cam)
    coll.objects.link(o)
    loc = Vector(frames.godot_to_blender_point(start))
    tgt = Vector(frames.godot_to_blender_point(target))
    o.location = loc
    d = tgt - loc
    if d.length < 1e-6:
        d = Vector((0, 1, 0))
    o.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    o[KIND] = "camera"
    scene.camera = o
    return {"camera": o.name, "from": start, "to": target, "route": label}


def overview_camera(scene, index: int, rooms: dict, coll) -> dict:
    """A raised three-quarter view from the Arrival side of the floor, aimed at the
    middle of what stands on it — for a floor whose Arrival waypoint is inside or
    behind a large work (floor 10's is)."""
    rec = rooms["floors"][index]
    pts = []
    for coll_key in ("artifacts", "copies", "props"):
        for it in rec.get(coll_key, []) or []:
            p = it.get("position") if isinstance(it, dict) else None
            if isinstance(p, list) and len(p) >= 2:
                pts.append((float(p[0]), float(p[1])))
    cx = sum(p[0] for p in pts) / len(pts) if pts else 0.0
    cz = sum(p[1] for p in pts) / len(pts) if pts else 0.0
    route = rec.get("route") or []
    arr = next((w for w in route if str(w.get("label", "")).lower().startswith("arrival")), route[0] if route else None)
    ax, az = (float(arr["position"][0]), float(arr["position"][1])) if arr else (cx + 20.0, cz + 8.0)
    dx, dz = ax - cx, az - cz
    n = math.hypot(dx, dz) or 1.0
    dx, dz = dx / n, dz / n
    # keep the camera on the arrival side but let it see across the floor
    dist = 34.0
    start = [cx + dx * dist + dz * 6.0, 13.0, cz + dz * dist - dx * 6.0]
    target = [cx, 1.2, cz]
    for o in list(coll.objects):
        if o.get(KIND) == "camera_overview":
            bpy.data.objects.remove(o, do_unlink=True)
    cam = bpy.data.cameras.new(f"Overview camera floor {index}")
    cam.lens = 35.0
    cam.clip_end = 500.0
    o = bpy.data.objects.new(cam.name, cam)
    coll.objects.link(o)
    loc = Vector(frames.godot_to_blender_point(start))
    tgt = Vector(frames.godot_to_blender_point(target))
    o.location = loc
    o.rotation_euler = (tgt - loc).to_track_quat("-Z", "Y").to_euler()
    o[KIND] = "camera_overview"
    return {"camera_overview": o.name, "overview_from": [round(v, 2) for v in start], "overview_to": [round(v, 2) for v in target]}


SEPIA = (0.16, 0.10, 0.06)        # line colour (linear)
OFF_WHITE = (0.93, 0.90, 0.84)    # architecture and works
PAPER = (0.91, 0.87, 0.79)        # the page behind


def apply_book_style(scene) -> str:
    """Palle 2026-10-22: 'outline render looking like sepia black and off white
    architecture — the kind of renders I want for the book'. Everything is one flat
    off-white matte (a view-layer material override), the world is a plain paper tone
    (soft even light, no sky bake), and Freestyle draws silhouettes, creases and
    borders in sepia; Standard view transform so the paper stays paper."""
    mat = bpy.data.materials.get("Book off-white")
    if mat is None:
        mat = bpy.data.materials.new("Book off-white")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (*OFF_WHITE, 1.0)
        bsdf.inputs["Roughness"].default_value = 1.0
        for name in ("Specular IOR Level", "Specular"):
            if name in bsdf.inputs:
                bsdf.inputs[name].default_value = 0.0
    vl = scene.view_layers[0]
    vl.material_override = mat
    # world: paper, even light
    world = scene.world or bpy.data.worlds.new("Book paper")
    scene.world = world
    world.use_nodes = True
    nt = world.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputWorld")
    bg = nt.nodes.new("ShaderNodeBackground")
    bg.inputs["Color"].default_value = (*PAPER, 1.0)
    bg.inputs["Strength"].default_value = 1.0
    nt.links.new(bg.outputs[0], out.inputs["Surface"])
    # lamps: keep the sun soft for a little shading, switch the Void's lamps off
    for o in bpy.data.objects:
        if o.type == "LIGHT":
            if o.get(KIND) == "sun":
                o.data.energy = 1.2
                o.data.color = (1.0, 1.0, 1.0)
                o.data.angle = math.radians(12.0)
                o.hide_render = False
            else:
                o.hide_render = True
    # freestyle lines
    scene.render.use_freestyle = True
    scene.render.line_thickness_mode = "ABSOLUTE"
    scene.render.line_thickness = 1.0
    vl.use_freestyle = True
    fs = vl.freestyle_settings
    fs.crease_angle = math.radians(125.0)
    fs.use_culling = True
    fs.use_smoothness = True
    for ls in list(fs.linesets):
        fs.linesets.remove(ls)
    ls = fs.linesets.new("Book lines")
    ls.select_silhouette = True
    ls.select_border = True
    ls.select_crease = True
    ls.select_contour = False
    ls.select_external_contour = True
    ls.select_material_boundary = False
    ls.select_edge_mark = False
    st = ls.linestyle
    st.name = "Book sepia"
    st.color = SEPIA
    st.thickness = 1.6
    st.alpha = 1.0
    st.thickness_position = "CENTER"
    st.chaining = "PLAIN"
    st.use_same_object = False
    st.caps = "ROUND"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure = 0.0
    scene.cycles.max_bounces = 4
    return "book: off-white override, paper world, Freestyle sepia lines"


def clear_book_style(scene) -> None:
    scene.view_layers[0].material_override = None
    scene.render.use_freestyle = False
    for o in bpy.data.objects:
        if o.type == "LIGHT":
            o.hide_render = False


def setup_render(context, samples: int = 256, fog: bool = False, resolution=(1920, 1080), camera: str = "arrival", style: str = "evening") -> dict:
    scene = context.scene
    s = scene.ada_void
    from .floor_import import get_rooms
    rooms = get_rooms()
    if rooms is None:
        raise RuntimeError("import a floor first")
    try:
        lighting = json.loads(scene.get("ada_void_lighting", "{}"))
    except json.JSONDecodeError:
        lighting = {}
    root = floor_collection(s.floor)
    rig = sub_collection(root, "Render")
    scene.render.engine = "CYCLES"
    device = _gpu(scene)
    scene.cycles.samples = int(samples)
    scene.cycles.use_denoising = True
    scene.cycles.use_adaptive_sampling = True
    scene.cycles.max_bounces = 8
    scene.render.resolution_x, scene.render.resolution_y = resolution
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "AgX" if "AgX" in [i.identifier for i in scene.view_settings.bl_rna.properties["view_transform"].enum_items] else "Filmic"
    scene.view_settings.look = "AgX - Medium High Contrast" if scene.view_settings.view_transform == "AgX" else "None"
    scene.view_settings.exposure = 0.6
    clear_book_style(scene)
    world_note = setup_world(scene, lighting, fog)
    setup_sun(scene, lighting, rig)
    cam = arrival_camera(scene, s.floor, rooms, rig)
    ov = overview_camera(scene, s.floor, rooms, rig)
    if camera == "overview":
        scene.camera = bpy.data.objects[ov["camera_overview"]]
    if style == "book":
        world_note = apply_book_style(scene)
    info = {"engine": "CYCLES", "device": device, "samples": samples, "world": world_note, "active": camera, "style": style, **cam, **ov}
    s.status = f"render ready: Cycles/{device}, {samples} spp, {world_note}, camera {camera} ({cam['route']})"
    return info


def render_still(context, filepath: str) -> str:
    scene = context.scene
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = filepath
    bpy.ops.render.render(write_still=True)
    return filepath
