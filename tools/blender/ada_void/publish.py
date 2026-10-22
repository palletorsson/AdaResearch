"""publish.py — read the mounts back into the floor's records and save through the
web editor's own route, so the running desktop and Quest take it live.

    read back  mounts (Empties named by record id) -> position/height/facing (+scale)
    save       POST /api/void-layout {rooms, revision}   (409 -> re-GET, retry once)
    report     the route's `live` entries + the acks the bridge's ledger holds

Only values that actually changed are written (frames.settle), so an untouched
record stays byte-for-byte what the file had, and a move out and back leaves
rooms.json identical.

Live mode: a depsgraph_update_post handler notes the time of the last transform
change on a mount; a timer publishes ~0.5 s after the last change, never while a
request is in flight (the HTTP runs in a thread; bpy is touched only on the main
thread), and refreshes the revision from the server after a 409.
"""
from __future__ import annotations

import json
import threading
import time

import bpy
from mathutils import Matrix

from . import chain, frames
from .floor_import import COLL, KIND, PART, RID, enc_url, floor_mounts, get_rooms, set_rooms_text

DEBOUNCE = 0.5
TICK = 0.2
ACK_WAIT = 4.0   # a silent device (a paused headset) holds a publish this long at most


# ── read back ──────────────────────────────────────────────────────────────

def _find(items, rid: str):
    if not isinstance(items, list):
        return None
    for it in items:
        if isinstance(it, dict) and str(it.get("id", "")) == rid:
            return it
    return None


def read_back(index: int, rooms: dict) -> list[str]:
    """Mutate rooms['floors'][index] from the mounts. Returns one line per changed record."""
    floors = rooms.get("floors", [])
    if index < 0 or index >= len(floors):
        raise ValueError(f"floor {index} is not in the rooms document")
    rec = floors[index]
    changes: list[str] = []
    for o in floor_mounts(index):
        kind = o.get(KIND)
        rid = str(o.get(RID, ""))
        coll_key = str(o.get(COLL, ""))
        if kind in ("artifact", "copy", "prop"):
            item = _find(rec.get(coll_key), rid)
            if item is None:
                continue
            loc = o.matrix_basis.to_translation()
            rot = o.matrix_basis.to_euler("XYZ")
            scl = o.matrix_basis.to_scale()
            pos, height, facing, scale = frames.mount_from_blender(loc, rot.z, scl.x)
            before = json.dumps(item, sort_keys=True)
            item["position"] = frames.settle_list(pos, item.get("position"))
            if kind != "prop":
                item["height"] = frames.settle(height, item.get("height"))
            item["facing"] = frames.settle_facing(facing, item.get("facing"))
            if "scale" in item or abs(scale - 1.0) > 1e-3:
                item["scale"] = frames.settle(scale, item.get("scale", 1))
            if json.dumps(item, sort_keys=True) != before:
                changes.append(f"{coll_key}/{rid}: position {item['position']}"
                               + (f" height {item.get('height')}" if kind != "prop" else "")
                               + f" facing {item['facing']}" + (f" scale {item['scale']}" if "scale" in item else ""))
        elif kind == "part":
            item = _find(rec.get(coll_key), rid)
            if item is None:
                continue
            pname = str(o.get(PART, ""))
            loc = o.matrix_basis.to_translation()
            b = o.matrix_basis.to_3x3()
            b3 = [[b[i][j] for j in range(3)] for i in range(3)]
            lpos, lrot = frames.part_from_blender(loc, b3)
            try:
                pos0 = json.loads(o.get("ada_void_pose_position", "null"))
                rot0 = json.loads(o.get("ada_void_pose_rotation", "null"))
            except json.JSONDecodeError:
                pos0, rot0 = None, None
            new_pos = frames.settle_list(lpos, pos0)
            new_rot = frames.settle_angles(lrot, rot0)
            if new_pos == pos0 and new_rot == rot0:
                continue  # the part stands where it was imported
            cfg = item.setdefault("config", {})
            parts = cfg.setdefault("parts", {})
            pose = parts.setdefault(pname, {})
            pose["position"] = new_pos
            if new_rot != rot0 or "rotation" in pose:
                pose["rotation"] = new_rot
            changes.append(f"{coll_key}/{rid} part {pname}: position {new_pos} rotation {pose.get('rotation', rot0)}")
        elif kind == "route":
            route = rec.get("route")
            try:
                i = int(rid)
            except ValueError:
                continue
            if not isinstance(route, list) or i >= len(route):
                continue
            w = route[i]
            p = frames.blender_to_godot_point(o.matrix_basis.to_translation())
            before = json.dumps(w, sort_keys=True)
            w["position"] = frames.settle_list([p[0], p[2]], w.get("position"))
            h = max(0.0, p[1] - 0.035)
            if "height" in w or h > 1e-3:
                w["height"] = frames.settle(h, w.get("height", 0))
            if json.dumps(w, sort_keys=True) != before:
                changes.append(f"route/{i} ({w.get('label', '')}): position {w['position']}")
    return changes


# ── publish (synchronous; the operator and the headless test call this) ────

def prepare(context) -> tuple[dict, list[str]] | None:
    """Main thread: the rooms document with the floor read back, and the change list."""
    s = context.scene.ada_void
    rooms = get_rooms()
    if rooms is None:
        raise RuntimeError("no floor imported in this scene (import one first)")
    changes = read_back(s.floor, rooms)
    return rooms, changes


def publish(context, wait_acks: float = ACK_WAIT, force: bool = False, log=print) -> dict:
    """Read back, save, wait for acks. Returns a result dict and leaves the scene's
    revision + rooms text at what was saved."""
    s = context.scene.ada_void
    rooms, changes = prepare(context)
    if not changes and not force:
        s.status = "nothing changed on floor %d" % s.floor
        return {"ok": True, "saved": False, "changes": [], "live": [], "acks": {}, "status": s.status}
    result = _save(rooms, s.revision, s.trial, s.floor, wait_acks, log)
    _apply_result(context, result, changes)
    return result


def _save(rooms: dict, revision: str, trial: str, floor: int, wait_acks: float, log=print) -> dict:
    """Thread-safe half: HTTP only, no bpy."""
    enc = enc_url()
    out: dict = {"ok": False, "saved": False, "live": [], "acks": {}, "retried": False}
    try:
        try:
            resp = chain.save_layout(rooms, revision, enc, trial)
        except chain.ChainError as e:
            if e.status != 409:
                raise
            # the file changed elsewhere: take the server's current document and put
            # this floor's read-back on top of it, once
            fresh = chain.get_layout(enc, trial)
            base = fresh["rooms"]
            if floor < len(base.get("floors", [])) and floor < len(rooms.get("floors", [])):
                base["floors"][floor] = rooms["floors"][floor]
            rooms = base
            out["retried"] = True
            resp = chain.save_layout(rooms, fresh["revision"], enc, trial)
        out["saved"] = True
        out["revision"] = str(resp.get("revision", ""))
        out["rooms"] = rooms
        out["warnings"] = resp.get("warnings") or []
        live = [l for l in (resp.get("live") or []) if int(l.get("floor", -1)) == floor]
        out["live"] = live
        for l in live:
            rid = str(l.get("revision_id", ""))
            if rid and l.get("sent"):
                expect = max(1, int(l.get("transmitted") or 1))
                out["acks"][rid] = chain.wait_acks(rid, enc, wait=wait_acks, expect=expect)
        out["ok"] = True
    except chain.ChainError as e:
        out["error"] = str(e)
        out["status_code"] = e.status
    except Exception as e:  # noqa: BLE001
        out["error"] = repr(e)
    return out


def _apply_result(context, result: dict, changes: list[str]) -> None:
    s = context.scene.ada_void
    if result.get("saved"):
        s.revision = result.get("revision", s.revision)
        if result.get("rooms") is not None:
            set_rooms_text(result["rooms"])
        lines = [chain.format_live(l, result["acks"].get(str(l.get("revision_id", "")), [])) for l in result.get("live", [])]
        if not lines:
            lines = ["saved, no floor changed on the wire"]
        s.status = "; ".join(lines) + (" (after a 409, on the server's newer file)" if result.get("retried") else "")
        s.last_publish = time.time()
    else:
        s.status = "publish failed: " + str(result.get("error", "?"))
    result["changes"] = changes
    result["status"] = s.status


# ── live mode ──────────────────────────────────────────────────────────────

class _Live:
    enabled = False
    dirty_at = 0.0
    inflight: threading.Thread | None = None
    pending: dict | None = None
    pending_changes: list[str] = []
    suppress = False
    last_matrices: dict[str, Matrix] = {}

LIVE = _Live()


def _is_mount(o) -> bool:
    return isinstance(o, bpy.types.Object) and o.get(KIND) in ("artifact", "copy", "prop", "part", "route")


def _on_depsgraph(scene, depsgraph):
    if not LIVE.enabled or LIVE.suppress:
        return
    for u in depsgraph.updates:
        o = u.id
        if u.is_updated_transform and _is_mount(o):
            # the depsgraph reports a transform update generously; compare the matrix
            name = o.name
            m = o.matrix_basis.copy()
            if LIVE.last_matrices.get(name) != m:
                LIVE.last_matrices[name] = m
                LIVE.dirty_at = time.time()


def _tick():
    if not LIVE.enabled:
        return None
    now = time.time()
    # a finished request: take its result on the main thread
    if LIVE.inflight is not None and not LIVE.inflight.is_alive():
        LIVE.inflight = None
        res = LIVE.pending or {}
        LIVE.pending = None
        try:
            _apply_result(bpy.context, res, LIVE.pending_changes)
        except Exception as e:  # noqa: BLE001
            print("[ada_void] live result:", repr(e))
        _redraw()
    if LIVE.inflight is None and LIVE.dirty_at and now - LIVE.dirty_at >= DEBOUNCE:
        LIVE.dirty_at = 0.0
        try:
            rooms, changes = prepare(bpy.context)
        except Exception as e:  # noqa: BLE001
            bpy.context.scene.ada_void.status = "live: " + repr(e)
            return TICK
        if changes:
            s = bpy.context.scene.ada_void
            s.status = "live: publishing %d change(s)…" % len(changes)
            LIVE.pending_changes = changes
            holder: dict = {}
            LIVE.pending = holder
            args = (rooms, s.revision, s.trial, s.floor, ACK_WAIT)
            def run():
                holder.update(_save(*args))
            LIVE.inflight = threading.Thread(target=run, daemon=True)
            LIVE.inflight.start()
            _redraw()
    return TICK


def _redraw():
    try:
        for w in bpy.context.window_manager.windows:
            for a in w.screen.areas:
                if a.type == "VIEW_3D":
                    a.tag_redraw()
    except Exception:  # noqa: BLE001
        pass


def set_live(enabled: bool) -> None:
    LIVE.enabled = enabled
    h = bpy.app.handlers.depsgraph_update_post
    if enabled:
        LIVE.last_matrices = {o.name: o.matrix_basis.copy() for o in bpy.data.objects if _is_mount(o)}
        LIVE.dirty_at = 0.0
        if _on_depsgraph not in h:
            h.append(_on_depsgraph)
        if not bpy.app.timers.is_registered(_tick):
            bpy.app.timers.register(_tick, first_interval=TICK, persistent=True)
    else:
        if _on_depsgraph in h:
            h.remove(_on_depsgraph)
        if bpy.app.timers.is_registered(_tick):
            bpy.app.timers.unregister(_tick)
