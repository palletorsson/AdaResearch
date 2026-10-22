"""Ada Void — Blender as a third live editor for The Void.

Import a floor from the Void's glTF export and the layout the web editor serves,
move the mounts (Empties named by record id), publish through the same
POST /api/void-layout the web editor uses; the running desktop game and the Quest
take the revision over the live update bridge and answer, and the answer shows in
the panel. A Cycles setup renders the floor from the route's Arrival point.

Install: Blender 4.2 › Edit › Preferences › Add-ons › Install from Disk… with a zip
of this folder (tools/blender/build_zip.py makes one), or copy the folder into
scripts/addons. bpy only; the encyclopedia dev server (localhost:3003) and
tools/vr_link.py must be running for the live half. Record:
doc/LIVE_UPDATE_BRIDGE.md § Blender.
"""
from __future__ import annotations

bl_info = {
    "name": "Ada Void (live editor)",
    "author": "Ada Research",
    "version": (0, 1, 0),
    "blender": (4, 2, 0),
    "location": "3D Viewport › Sidebar (N) › Ada Void",
    "description": "Import a Void floor from the glTF export, publish transforms through the live update chain, render with Cycles",
    "category": "Import-Export",
}

import importlib
import os

import bpy

from . import chain, frames, floor_import, publish, render_setup

for _m in (chain, frames, floor_import, publish, render_setup):
    importlib.reload(_m)


class AdaVoidPreferences(bpy.types.AddonPreferences):
    bl_idname = __package__

    enc_url: bpy.props.StringProperty(
        name="Encyclopedia URL", default=chain.DEFAULT_ENC,
        description="The ada_encyclopedia dev server (GET/POST /api/void-layout, GET /api/live-update)")
    public_dir: bpy.props.StringProperty(
        name="public/ folder", subtype="DIR_PATH", default="",
        description="ada_encyclopedia/public (models read from disk). Empty: found beside the Ada repo, else fetched over HTTP")

    def draw(self, context):
        col = self.layout.column()
        col.prop(self, "enc_url")
        col.prop(self, "public_dir")
        col.label(text=f"models: {floor_import.public_dir() or 'fetched from ' + self.enc_url}")


def _live_update(self, context):
    publish.set_live(bool(self.live))
    self.status = "live: on — a change publishes %.1f s after you stop moving" % publish.DEBOUNCE if self.live else "live: off"


class AdaVoidSceneProps(bpy.types.PropertyGroup):
    floor: bpy.props.IntProperty(name="Floor", default=10, min=0, max=400)
    trial: bpy.props.StringProperty(name="Trial", default="", description="empty = the main tower (commons/void/rooms.json)")
    revision: bpy.props.StringProperty(name="Revision", default="")
    map: bpy.props.StringProperty(name="Map", default="")
    models: bpy.props.StringProperty(name="Manifest", default="/void-models/manifest.json")
    status: bpy.props.StringProperty(name="Status", default="")
    live: bpy.props.BoolProperty(name="Live", default=False, update=_live_update,
                                 description="Publish automatically ~0.5 s after the last move")
    labels: bpy.props.BoolProperty(name="Import labels", default=True, description="Re-create Label3D text as Blender text objects")
    samples: bpy.props.IntProperty(name="Samples", default=256, min=8, max=4096)
    fog: bpy.props.BoolProperty(name="Fog volume", default=False, description="A thin world volume in the export's fog colour (slower)")
    camera: bpy.props.EnumProperty(name="Camera", items=[("arrival", "Arrival (route eye)", "At the route's Arrival waypoint, looking along the route"),
                                                         ("overview", "Overview", "Raised three-quarter view from the Arrival side")], default="overview")
    style: bpy.props.EnumProperty(name="Style", items=[("evening", "Evening (the Void's sky)", "The export's sky bake, sun and materials"),
                                                       ("book", "Book (sepia outline)", "Off-white matte, paper world, Freestyle lines in sepia")], default="evening")
    last_publish: bpy.props.FloatProperty(default=0.0)


class ADAVOID_OT_import_floor(bpy.types.Operator):
    bl_idname = "ada_void.import_floor"
    bl_label = "Import floor"
    bl_description = "GET /api/void-layout + the glTF export; rebuilds the floor's collection"
    bl_options = {"REGISTER", "UNDO"}

    def execute(self, context):
        s = context.scene.ada_void
        was_live = s.live
        if was_live:
            s.live = False
        publish.LIVE.suppress = True
        try:
            stats = floor_import.build_floor(context, s.floor, s.trial, labels=s.labels, log=lambda m: self.report({"INFO"}, m))
        except Exception as e:  # noqa: BLE001
            self.report({"ERROR"}, f"import failed: {e}")
            return {"CANCELLED"}
        finally:
            publish.LIVE.suppress = False
        self.report({"INFO"}, f"floor {s.floor} ({stats['map']}): {stats['artifacts']} artifacts, {stats['parts']} parts, {stats['props']} props at {stats['revision'][:12]}")
        return {"FINISHED"}


class ADAVOID_OT_publish(bpy.types.Operator):
    bl_idname = "ada_void.publish"
    bl_label = "Publish"
    bl_description = "Read the mounts back into the floor's records and POST /api/void-layout; shows each game's ack"

    force: bpy.props.BoolProperty(default=False)

    def execute(self, context):
        try:
            res = publish.publish(context, force=self.force, log=lambda m: self.report({"INFO"}, m))
        except Exception as e:  # noqa: BLE001
            self.report({"ERROR"}, f"publish failed: {e}")
            return {"CANCELLED"}
        for c in res.get("changes", []):
            self.report({"INFO"}, c)
        self.report({"INFO" if res.get("ok") else "ERROR"}, res.get("status", ""))
        return {"FINISHED"} if res.get("ok") else {"CANCELLED"}


class ADAVOID_OT_reload_revision(bpy.types.Operator):
    bl_idname = "ada_void.reload_revision"
    bl_label = "Reload revision"
    bl_description = "Take the server's current rooms document and revision without rebuilding the scene (after a save elsewhere)"

    def execute(self, context):
        s = context.scene.ada_void
        try:
            layout = chain.get_layout(floor_import.enc_url(), s.trial)
        except Exception as e:  # noqa: BLE001
            self.report({"ERROR"}, str(e))
            return {"CANCELLED"}
        floor_import.set_rooms_text(layout["rooms"])
        s.revision = str(layout.get("revision", ""))
        s.status = f"revision reloaded: {s.revision[:12]} (the scene's mounts are not moved; publish puts them on top)"
        self.report({"INFO"}, s.status)
        return {"FINISHED"}


class ADAVOID_OT_render_setup(bpy.types.Operator):
    bl_idname = "ada_void.render_setup"
    bl_label = "Cycles setup"
    bl_description = "Cycles on the GPU, the evening sky, the sun, a camera at the route's Arrival waypoint"

    def execute(self, context):
        s = context.scene.ada_void
        try:
            info = render_setup.setup_render(context, samples=s.samples, fog=s.fog, camera=s.camera, style=s.style)
        except Exception as e:  # noqa: BLE001
            self.report({"ERROR"}, str(e))
            return {"CANCELLED"}
        self.report({"INFO"}, f"{info['engine']} on {info['device']}, {info['world']}, camera {info['active']} ({info['route']})")
        return {"FINISHED"}


class ADAVOID_PT_panel(bpy.types.Panel):
    bl_label = "Ada Void"
    bl_idname = "ADAVOID_PT_panel"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category = "Ada Void"

    def draw(self, context):
        s = context.scene.ada_void
        col = self.layout.column(align=True)
        col.prop(s, "floor")
        col.prop(s, "trial")
        col.prop(s, "labels")
        col.operator("ada_void.import_floor", icon="IMPORT")
        self.layout.separator()
        box = self.layout.box()
        box.label(text=f"{s.map or '—'}  rev {s.revision[:12] or '—'}")
        row = box.row(align=True)
        row.operator("ada_void.publish", icon="EXPORT")
        row.prop(s, "live", toggle=True, icon="REC")
        box.operator("ada_void.reload_revision", icon="FILE_REFRESH")
        self.layout.separator()
        rb = self.layout.box()
        rb.prop(s, "samples")
        rb.prop(s, "fog")
        rb.prop(s, "camera")
        rb.prop(s, "style")
        rb.operator("ada_void.render_setup", icon="RESTRICT_RENDER_OFF")
        self.layout.separator()
        for line in _wrap(s.status, 38):
            self.layout.label(text=line)


def _wrap(text: str, width: int) -> list[str]:
    words, lines, cur = text.split(), [], ""
    for w in words:
        if len(cur) + len(w) + 1 > width and cur:
            lines.append(cur)
            cur = w
        else:
            cur = (cur + " " + w).strip()
    if cur:
        lines.append(cur)
    return lines[:8]


CLASSES = (AdaVoidPreferences, AdaVoidSceneProps, ADAVOID_OT_import_floor, ADAVOID_OT_publish,
           ADAVOID_OT_reload_revision, ADAVOID_OT_render_setup, ADAVOID_PT_panel)


def register():
    for c in CLASSES:
        bpy.utils.register_class(c)
    bpy.types.Scene.ada_void = bpy.props.PointerProperty(type=AdaVoidSceneProps)


def unregister():
    publish.set_live(False)
    del bpy.types.Scene.ada_void
    for c in reversed(CLASSES):
        bpy.utils.unregister_class(c)
