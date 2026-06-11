extends Node3D
## Isometric room line sketcher (desktop tool).
##
## A room is a box of tiles. Pick a face (1-6 or the right-side menu); its
## tile-corner lattice becomes the snap targets. Move the mouse — the cursor
## jumps to the nearest corner; left-click two corners to draw a line that
## sticks to the grid. Scrub the drawing plane through depth and flip it
## inward/outward: the same sketch on the inner or outer side of the plane.
##
## Committed lines render as fat glowing tubes (bloomed). Save writes to the
## repo (commons/tools/room_sketcher/sketches/) AND user://; Load reads it back.
## room_sketch_render.gd renders a saved sketch inside the actual game.
##
## Run it directly (open this scene, press F6). Orthographic iso camera.

const SketchMeshLib := preload("res://commons/tools/room_sketcher/sketch_mesh.gd")
const SKETCH_DIR := "res://commons/tools/room_sketcher/sketches/"
const SKETCH_FILE := "room_sketch.json"
const USER_PATH := "user://room_sketch.json"

@export var room_w: int = 8       # cells along X
@export var room_d: int = 8       # cells along Z
@export var room_h: int = 4       # cells along Y
@export var cell_size: float = 1.0
@export var line_radius: float = 0.022
@export var line_color: Color = Color(0.20, 0.90, 1.0)

# ── State ───────────────────────────────────────────────────────────────────
var _faces: Array = []
var _active_face: int = 0             # 0..5
var _depth: float = 0.0               # cells along the face normal (+ inward / - outward)
var _pending: Vector3 = Vector3.INF   # first corner of the segment being drawn
var _cursor: Vector3 = Vector3.ZERO
var _has_cursor: bool = false
var _segments: Array = []             # [{a: Vector3, b: Vector3, face: int}]
var _fills: Array = []                # [{p: [Vector3 x4], color: Color}]
var _prims: Array = []                # [{type: String, pos: Vector3, size: float, color: Color}]
var _history: Array = []              # element kinds in add-order, for Undo
var _status: String = ""
var _show_backing: bool = true
var _tool: String = "line"            # line / free / fill / cube / sphere / cylinder / pyramid
var _drawing_stroke: bool = false
var _stroke: Array = []               # in-progress freehand points (Vector3)
var _fill_pending: Vector3 = Vector3.INF
var _raw_hit: Vector3 = Vector3.INF   # unsnapped mouse hit on the active plane
var _prim_size: float = 0.8
var _moving_prim: int = -1            # primitive being dragged (Move tool)
var _moving_fill: int = -1            # fill being dragged (Move tool)
var _move_anchor: Vector3 = Vector3.INF
var _snapped_existing: bool = false   # cursor is snapped to an existing vertex
var _grad_near: float = 0.0           # camera distance range for the depth gradient
var _grad_far: float = 1.0

var _cam: Camera3D
var _env: Environment
var _cam_yaw: float = 45.0            # free orbit
var _cam_pitch: float = 35.264
var _orbiting: bool = false
var _panning: bool = false
var _pan_offset: Vector3 = Vector3.ZERO
var _cam_size_default: float = 0.0
var _im: ImmediateMesh
var _tubes_root: Node3D
var _fills_root: Node3D
var _prims_root: Node3D

# UI
var _help: Label
var _face_buttons: Array = []
var _tool_buttons: Dictionary = {}
var _depth_label: Label
var _depth_slider: VSlider
var _seg_label: Label

# ── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_faces()
	_build_environment()
	_build_camera()
	_build_mesh()
	_build_ui()
	get_viewport().msaa_3d = Viewport.MSAA_4X

func _build_faces() -> void:
	var ww := float(room_w) * cell_size
	var hh := float(room_h) * cell_size
	var dd := float(room_d) * cell_size
	var c := cell_size
	# origin = the face's (0,0) corner; u,v = per-cell span dirs; normal = inward
	_faces = [
		{"name": "FLOOR",   "origin": Vector3(0, 0, 0),  "u": Vector3(c, 0, 0), "v": Vector3(0, 0, c), "nu": room_w, "nv": room_d, "normal": Vector3(0, 1, 0)},
		{"name": "CEILING", "origin": Vector3(0, hh, 0), "u": Vector3(c, 0, 0), "v": Vector3(0, 0, c), "nu": room_w, "nv": room_d, "normal": Vector3(0, -1, 0)},
		{"name": "WEST",    "origin": Vector3(0, 0, 0),  "u": Vector3(0, c, 0), "v": Vector3(0, 0, c), "nu": room_h, "nv": room_d, "normal": Vector3(1, 0, 0)},
		{"name": "EAST",    "origin": Vector3(ww, 0, 0), "u": Vector3(0, c, 0), "v": Vector3(0, 0, c), "nu": room_h, "nv": room_d, "normal": Vector3(-1, 0, 0)},
		{"name": "SOUTH",   "origin": Vector3(0, 0, 0),  "u": Vector3(c, 0, 0), "v": Vector3(0, c, 0), "nu": room_w, "nv": room_h, "normal": Vector3(0, 0, 1)},
		{"name": "NORTH",   "origin": Vector3(0, 0, dd), "u": Vector3(c, 0, 0), "v": Vector3(0, c, 0), "nu": room_w, "nv": room_h, "normal": Vector3(0, 0, -1)},
	]

func _center() -> Vector3:
	return Vector3(room_w, room_h, room_d) * cell_size * 0.5

func _build_environment() -> void:
	# Attached to the CAMERA (not a WorldEnvironment node) so it overrides the
	# project's global environment/fog — otherwise the tool renders washed grey.
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.05, 0.06, 0.09)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.70, 0.78, 0.92)
	_env.ambient_light_energy = 1.0
	_env.fog_enabled = false
	_env.glow_enabled = false
	_env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	# Soft key light gives the tubes some form (they are emissive + lit).
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -40, 0)
	sun.light_energy = 0.5
	add_child(sun)

func _build_camera() -> void:
	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = maxf(float(room_w), float(room_d)) * cell_size * 1.7 + 4.0
	_cam_size_default = _cam.size
	_cam.near = 0.1
	_cam.far = 1000.0
	_cam.environment = _env  # override any global WorldEnvironment for this view
	add_child(_cam)
	_position_camera()
	_cam.current = true

func _position_camera() -> void:
	var center := _center() + _pan_offset
	var yaw := deg_to_rad(_cam_yaw)
	var pitch := deg_to_rad(_cam_pitch)
	var dir := Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw))
	_cam.position = center + dir * 200.0
	_cam.look_at(center, Vector3.UP)

func _build_mesh() -> void:
	# Live overlay (plane fill, room box, grid, cursor, preview) — per-frame.
	_im = ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = _im
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED  # plane fill visible from both iso sides
	mi.material_override = m
	add_child(mi)
	# Committed geometry — rebuilt only when it changes.
	_rebuild_tubes()
	_rebuild_fills()
	_rebuild_prims()

# ── Per-frame ───────────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	var hit := _mouse_plane_hit()
	_raw_hit = hit
	_snapped_existing = false
	if hit != Vector3.INF:
		# Primitive tools (and dragging a primitive) snap to the cell CENTRE so the
		# solid sits in the grid; line/fill keep snapping to tile corners.
		if _is_prim_tool() or (_tool == "move" and _moving_prim >= 0):
			_cursor = _snap_cell_center(hit)
		else:
			_cursor = _snap_corner(hit)
		_has_cursor = true
	else:
		_has_cursor = false
	# Line tool also snaps to existing points — segment endpoints, primitive
	# corners, fill corners — even off the current plane. Lets you build lines
	# between existing vertices and draw on primitives.
	if _tool == "line":
		var sp := _nearest_existing_point()
		if sp != Vector3.INF:
			_cursor = sp
			_has_cursor = true
			_snapped_existing = true
	_rebuild_overlay()

## Nearest existing vertex to the mouse in screen space (or INF if none close).
func _nearest_existing_point() -> Vector3:
	if _cam == null:
		return Vector3.INF
	var mp := get_viewport().get_mouse_position()
	var best := Vector3.INF
	var best_d := 12.0
	for p in _collect_snap_points():
		var d := mp.distance_to(_cam.unproject_position(p))
		if d < best_d:
			best_d = d
			best = p
	return best

## All snappable vertices: line endpoints, fill corners, primitive box-corners.
func _collect_snap_points() -> Array:
	var pts := []
	for s in _segments:
		pts.append(s["a"])
		pts.append(s["b"])
	for f in _fills:
		for p in f["p"]:
			pts.append(p)
	for pr in _prims:
		var c: Vector3 = pr["pos"]
		var h := float(pr["size"]) * 0.5
		pts.append(c)
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					pts.append(c + Vector3(sx * h, sy * h, sz * h))
	return pts

func _mouse_plane_hit() -> Vector3:
	if _cam == null:
		return Vector3.INF
	var f: Dictionary = _faces[_active_face]
	var n: Vector3 = f["normal"]
	var o: Vector3 = (f["origin"] as Vector3) + n * (_depth * cell_size)
	var plane := Plane(n, o.dot(n))
	var mp := get_viewport().get_mouse_position()
	var from := _cam.project_ray_origin(mp)
	var dir := _cam.project_ray_normal(mp)
	var hit = plane.intersects_ray(from, dir)
	if hit == null:
		return Vector3.INF
	return hit

func _snap_corner(hit: Vector3) -> Vector3:
	var f: Dictionary = _faces[_active_face]
	var n: Vector3 = f["normal"]
	var o: Vector3 = (f["origin"] as Vector3) + n * (_depth * cell_size)
	var u: Vector3 = f["u"]
	var v: Vector3 = f["v"]
	var rel := hit - o
	var iu := clampi(int(round(rel.dot(u.normalized()) / cell_size)), 0, int(f["nu"]))
	var jv := clampi(int(round(rel.dot(v.normalized()) / cell_size)), 0, int(f["nv"]))
	return o + u * iu + v * jv

## Tools that drop a solid into the grid snap to the cell CENTRE, not a corner.
func _is_prim_tool() -> bool:
	return _tool == "cube" or _tool == "sphere" or _tool == "cylinder" or _tool == "pyramid"

## Snap to the CENTRE of the grid cell the hit falls in, so a primitive sits IN a
## cell (like a placed cube) instead of straddling the corner between four cells.
func _snap_cell_center(hit: Vector3) -> Vector3:
	var f: Dictionary = _faces[_active_face]
	var n: Vector3 = f["normal"]
	var o: Vector3 = (f["origin"] as Vector3) + n * (_depth * cell_size)
	var u: Vector3 = f["u"]
	var v: Vector3 = f["v"]
	var rel := hit - o
	var iu := clampi(int(floor(rel.dot(u.normalized()) / cell_size)), 0, int(f["nu"]) - 1)
	var jv := clampi(int(floor(rel.dot(v.normalized()) / cell_size)), 0, int(f["nv"]) - 1)
	return o + u * (float(iu) + 0.5) + v * (float(jv) + 0.5)

# ── Input ───────────────────────────────────────────────────────────────────
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		_handle_mouse_button(e)
	elif e is InputEventMouseMotion:
		if _orbiting:
			_cam_yaw -= e.relative.x * 0.3
			_cam_pitch = clampf(_cam_pitch + e.relative.y * 0.3, -85.0, 85.0)
			_position_camera()
		elif _panning:
			_pan(e.relative)
		elif _moving_prim >= 0 and _has_cursor:
			var n := _faces[_active_face]["normal"] as Vector3
			var newpos := _cursor + n * (float(_prims[_moving_prim]["size"]) * 0.5)
			_prims[_moving_prim]["pos"] = newpos
			if _prims_root != null and _moving_prim < _prims_root.get_child_count():
				_prims_root.get_child(_moving_prim).position = newpos
		elif _moving_fill >= 0 and _has_cursor and _move_anchor != Vector3.INF:
			var delta := _cursor - _move_anchor
			var p = _fills[_moving_fill]["p"]
			for j in p.size():
				p[j] = (p[j] as Vector3) + delta
			_move_anchor = _cursor
			_rebuild_fills()
		elif _drawing_stroke and _raw_hit != Vector3.INF:
			if _stroke.is_empty() or (_stroke[-1] as Vector3).distance_to(_raw_hit) > 0.06:
				_stroke.append(_raw_hit)
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_1: _set_face(0)
			KEY_2: _set_face(1)
			KEY_3: _set_face(2)
			KEY_4: _set_face(3)
			KEY_5: _set_face(4)
			KEY_6: _set_face(5)
			KEY_Q: _orbit_yaw(45.0)
			KEY_E: _orbit_yaw(-45.0)
			KEY_BRACKETLEFT: _depth_step(-1.0)
			KEY_BRACKETRIGHT: _depth_step(1.0)
			KEY_F: _flip_depth()
			KEY_Z: _undo()
			KEY_C: _clear()
			KEY_ENTER, KEY_KP_ENTER: _save()
			KEY_L: _load()
			KEY_R: _reset_view()

func _orbit_yaw(d: float) -> void:
	_cam_yaw += d
	_position_camera()
	_rebuild_tubes()

func _handle_mouse_button(e: InputEventMouseButton) -> void:
	if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
		_cam.size = maxf(_cam.size * 0.9, 2.0)
		return
	if e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
		_cam.size = minf(_cam.size * 1.1, 300.0)
		return
	if e.button_index == MOUSE_BUTTON_MIDDLE:
		if e.pressed:
			_panning = e.shift_pressed     # Shift+MMB pans, MMB orbits
			_orbiting = not e.shift_pressed
		else:
			_orbiting = false
			_panning = false
			_rebuild_tubes()               # refresh depth gradient for the new view
		return
	if e.button_index == MOUSE_BUTTON_RIGHT and e.pressed:
		_pending = Vector3.INF
		_fill_pending = Vector3.INF
		_drawing_stroke = false
		_stroke = []
		_moving_prim = -1
		_moving_fill = -1
		_move_anchor = Vector3.INF
		_refresh()
		return
	if e.button_index != MOUSE_BUTTON_LEFT:
		return
	if e.pressed:
		if e.double_click:
			_drawing_stroke = false
			_stroke = []
			_delete_at_mouse()
			return
		match _tool:
			"free":
				if _raw_hit != Vector3.INF:
					_drawing_stroke = true
					_stroke = [_raw_hit]
			"fill":
				_fill_click()
			"line":
				_line_click()
			"move":
				_grab_for_move()
			"paint":
				_paint_face()
			_:
				_place_primitive()
	else:
		if _drawing_stroke:
			_finish_stroke()
		elif _moving_prim >= 0 or _moving_fill >= 0:
			_moving_prim = -1
			_moving_fill = -1
			_move_anchor = Vector3.INF
			_status = "moved"
			_refresh()

## Move tool: grab the primitive nearest the click, else a fill the cursor is
## inside, so motion drags it.
func _grab_for_move() -> void:
	if _cam == null:
		return
	var mp := get_viewport().get_mouse_position()
	var best := -1
	var best_d := 26.0
	for i in _prims.size():
		var d := mp.distance_to(_cam.unproject_position(_prims[i]["pos"]))
		if d < best_d:
			best_d = d
			best = i
	if best >= 0:
		_moving_prim = best
		_move_anchor = _cursor
		_status = "moving primitive"
		_refresh()
		return
	for i in _fills.size():
		if _point_in_fill(mp, _fills[i]):
			_moving_fill = i
			_move_anchor = _cursor
			_status = "moving fill"
			_refresh()
			return

func _line_click() -> void:
	if not _has_cursor:
		return
	if _pending == Vector3.INF:
		_pending = _cursor
	else:
		if _pending.distance_to(_cursor) > 0.001:
			_segments.append({"a": _pending, "b": _cursor, "face": _active_face})
			_history.append("seg")
			_rebuild_tubes()
		_pending = Vector3.INF
	_refresh()

func _fill_click() -> void:
	if not _has_cursor:
		return
	if _fill_pending == Vector3.INF:
		_fill_pending = _cursor
		_refresh()
		return
	_add_fill(_fill_pending, _cursor)
	_fill_pending = Vector3.INF
	_refresh()

func _add_fill(a: Vector3, b: Vector3) -> void:
	var f: Dictionary = _faces[_active_face]
	var u := (f["u"] as Vector3).normalized()
	var v := (f["v"] as Vector3).normalized()
	var rel := b - a
	var pu := rel.dot(u)
	var pv := rel.dot(v)
	if absf(pu) < 0.001 or absf(pv) < 0.001:
		return  # zero-area rectangle
	var col := Color(line_color.r, line_color.g, line_color.b, 0.45)
	_fills.append({"p": [a, a + u * pu, b, a + v * pv], "color": col})
	_history.append("fill")
	_rebuild_fills()

func _place_primitive() -> void:
	if not _has_cursor:
		return
	var n := _faces[_active_face]["normal"] as Vector3
	var center := _cursor + n * (_prim_size * 0.5)
	var base := Color(line_color.r, line_color.g, line_color.b, 1.0)
	var fcount := 6 if _tool == "cube" else 1
	var fcols := []
	for k in fcount:
		fcols.append(base)
	_prims.append({"type": _tool, "pos": center, "size": _prim_size, "color": base, "faces": fcols})
	_history.append("prim")
	_rebuild_prims()
	_refresh()

## Paint tool — ray-pick the primitive under the mouse and colour the hit face with
## line_color (cubes: the specific face; other solids: the whole surface).
func _paint_face() -> void:
	var pick := _pick_prim_face()
	var idx: int = pick.get("idx", -1)
	if idx < 0 or idx >= _prims.size():
		return
	var col := Color(line_color.r, line_color.g, line_color.b, 1.0)
	var is_cube := String(_prims[idx].get("type", "cube")) == "cube"
	var fcount := 6 if is_cube else 1
	var faces = _prims[idx].get("faces", [])
	if not (faces is Array) or faces.size() < fcount:
		faces = []
		for k in fcount:
			faces.append(_prims[idx].get("color", col))
	var face: int = pick.get("face", -1)
	if is_cube and face >= 0 and face < faces.size():
		faces[face] = col
	else:
		for j in faces.size():
			faces[j] = col
	_prims[idx]["faces"] = faces
	_rebuild_prims()
	_status = "painted face"
	_refresh()

## Ray from the mouse vs every primitive's box; returns {idx, face} of the nearest
## hit (face 0..5 = +X,-X,+Y,-Y,+Z,-Z for cubes; -1 otherwise), idx -1 if none.
func _pick_prim_face() -> Dictionary:
	if _cam == null:
		return {"idx": -1, "face": -1}
	var mp := get_viewport().get_mouse_position()
	var ro := _cam.project_ray_origin(mp)
	var rd := _cam.project_ray_normal(mp)
	var best_t := INF
	var best := {"idx": -1, "face": -1}
	for i in _prims.size():
		var c: Vector3 = _prims[i]["pos"]
		var h := float(_prims[i]["size"]) * 0.5
		var res := _ray_box(ro, rd, c - Vector3(h, h, h), c + Vector3(h, h, h))
		if res.get("hit", false) and float(res["t"]) < best_t:
			best_t = float(res["t"])
			best = {"idx": i, "face": int(res["face"])}
	return best

## Slab ray/AABB intersection → {hit, t, face}; face order +X,-X,+Y,-Y,+Z,-Z.
func _ray_box(ro: Vector3, rd: Vector3, bmin: Vector3, bmax: Vector3) -> Dictionary:
	var tmin := -INF
	var tmax := INF
	var axis := 0
	for a in 3:
		if absf(rd[a]) < 1e-9:
			if ro[a] < bmin[a] or ro[a] > bmax[a]:
				return {"hit": false, "t": 0.0, "face": -1}
		else:
			var t1 := (bmin[a] - ro[a]) / rd[a]
			var t2 := (bmax[a] - ro[a]) / rd[a]
			if t1 > t2:
				var tmp := t1; t1 = t2; t2 = tmp
			if t1 > tmin:
				tmin = t1
				axis = a
			tmax = minf(tmax, t2)
			if tmin > tmax:
				return {"hit": false, "t": 0.0, "face": -1}
	if tmax < 0.0:
		return {"hit": false, "t": 0.0, "face": -1}
	var t: float = tmin if tmin >= 0.0 else tmax
	var face := axis * 2 + (1 if rd[axis] > 0.0 else 0)
	return {"hit": true, "t": t, "face": face}

func _finish_stroke() -> void:
	_drawing_stroke = false
	for i in range(_stroke.size() - 1):
		var a: Vector3 = _stroke[i]
		var b: Vector3 = _stroke[i + 1]
		if a.distance_to(b) > 0.001:
			_segments.append({"a": a, "b": b, "face": _active_face})
			_history.append("seg")
	_stroke = []
	_rebuild_tubes()
	_refresh()

## Double-click near a line / primitive / fill removes it (screen-space pick).
func _delete_at_mouse() -> void:
	if _cam == null:
		return
	var mp := get_viewport().get_mouse_position()
	var best_kind := ""
	var best_idx := -1
	var best_d := 18.0
	for i in _segments.size():
		var a2 := _cam.unproject_position(_segments[i]["a"])
		var b2 := _cam.unproject_position(_segments[i]["b"])
		var d := _dist_point_seg2(mp, a2, b2)
		if d < best_d:
			best_d = d; best_kind = "seg"; best_idx = i
	for i in _prims.size():
		var d := mp.distance_to(_cam.unproject_position(_prims[i]["pos"]))
		if d < best_d:
			best_d = d; best_kind = "prim"; best_idx = i
	for i in _fills.size():
		if _point_in_fill(mp, _fills[i]):
			best_d = 0.0; best_kind = "fill"; best_idx = i  # clicking inside wins
			break
		var d := mp.distance_to(_cam.unproject_position(_fill_center(_fills[i])))
		if d < best_d:
			best_d = d; best_kind = "fill"; best_idx = i
	if best_idx < 0:
		return
	match best_kind:
		"seg": _segments.remove_at(best_idx); _rebuild_tubes()
		"prim": _prims.remove_at(best_idx); _rebuild_prims()
		"fill": _fills.remove_at(best_idx); _rebuild_fills()
	_history_remove_last(best_kind)
	_pending = Vector3.INF
	_status = "deleted a " + best_kind
	_refresh()

func _fill_center(f: Dictionary) -> Vector3:
	var p = f["p"]
	return ((p[0] as Vector3) + (p[2] as Vector3)) * 0.5

## Is the mouse inside the fill quad (projected to screen)?
func _point_in_fill(mp: Vector2, f: Dictionary) -> bool:
	if _cam == null:
		return false
	var p = f["p"]
	var s := []
	for i in 4:
		s.append(_cam.unproject_position(p[i]))
	return _pt_in_tri(mp, s[0], s[1], s[2]) or _pt_in_tri(mp, s[0], s[2], s[3])

func _pt_in_tri(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var d1 := _edge_sign(p, a, b)
	var d2 := _edge_sign(p, b, c)
	var d3 := _edge_sign(p, c, a)
	var has_neg := d1 < 0.0 or d2 < 0.0 or d3 < 0.0
	var has_pos := d1 > 0.0 or d2 > 0.0 or d3 > 0.0
	return not (has_neg and has_pos)

func _edge_sign(p: Vector2, a: Vector2, b: Vector2) -> float:
	return (p.x - b.x) * (a.y - b.y) - (a.x - b.x) * (p.y - b.y)

## Slide the whole view in its own screen plane (Shift+MMB).
func _pan(rel: Vector2) -> void:
	if _cam == null:
		return
	var vp := get_viewport().get_visible_rect().size.y
	if vp <= 0.0:
		return
	var k := _cam.size / vp
	var right := _cam.global_transform.basis.x
	var up := _cam.global_transform.basis.y
	_pan_offset += (-right * rel.x + up * rel.y) * k
	_position_camera()

func _reset_view() -> void:
	_pan_offset = Vector3.ZERO
	_cam_yaw = 45.0
	_cam_pitch = 35.264
	if _cam_size_default > 0.0:
		_cam.size = _cam_size_default
	_position_camera()
	_rebuild_tubes()
	_status = "view reset"
	_refresh()

func _history_remove_last(kind: String) -> void:
	for i in range(_history.size() - 1, -1, -1):
		if _history[i] == kind:
			_history.remove_at(i)
			return

func _dist_point_seg2(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 0.0001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * t)

# ── Actions (shared by keyboard + menu) ───────────────────────────────────────
func _set_face(i: int) -> void:
	_active_face = i
	_depth = 0.0
	_pending = Vector3.INF
	if _depth_slider != null:
		var ext := _face_depth_extent()
		_depth_slider.min_value = -ext
		_depth_slider.max_value = ext
		_depth_slider.tick_count = ext * 2 + 1
	_refresh()

func _depth_step(d: float) -> void:
	_depth += d
	_refresh()

func _flip_depth() -> void:
	_depth = -_depth
	_refresh()

func _set_depth(v: float) -> void:
	_depth = v
	_refresh()

## Room dimension along the active face's normal — how far the plane can scrub.
func _face_depth_extent() -> int:
	var n: Vector3 = _faces[_active_face]["normal"]
	if absf(n.y) > 0.5:
		return room_h
	if absf(n.x) > 0.5:
		return room_w
	return room_d

func _undo() -> void:
	if _history.is_empty():
		return
	var kind: String = _history.pop_back()
	match kind:
		"seg":
			if not _segments.is_empty():
				_segments.pop_back()
				_rebuild_tubes()
		"fill":
			if not _fills.is_empty():
				_fills.pop_back()
				_rebuild_fills()
		"prim":
			if not _prims.is_empty():
				_prims.pop_back()
				_rebuild_prims()
	_refresh()

func _clear() -> void:
	_segments.clear()
	_fills.clear()
	_prims.clear()
	_history.clear()
	_pending = Vector3.INF
	_fill_pending = Vector3.INF
	_rebuild_tubes()
	_rebuild_fills()
	_rebuild_prims()
	_refresh()

func _set_line_color(c: Color) -> void:
	line_color = c
	_rebuild_tubes()

func _set_line_radius(v: float) -> void:
	line_radius = v
	_rebuild_tubes()

func _toggle_backing(on: bool) -> void:
	_show_backing = on

func _set_tool(tool_name: String) -> void:
	_tool = tool_name
	_pending = Vector3.INF
	_fill_pending = Vector3.INF
	_status = "tool: " + tool_name
	_refresh()

## Per-endpoint colour: full line_color near the camera, fading grey deeper in.
func _tube_color(p: Vector3) -> Color:
	if _cam == null:
		return line_color
	var d := _cam.global_position.distance_to(p)
	var t := clampf((d - _grad_near) / (_grad_far - _grad_near), 0.0, 1.0)
	return line_color.lerp(Color(0.34, 0.37, 0.44), t * 0.95)

func _compute_gradient_range() -> void:
	if _cam == null:
		return
	var ww := float(room_w) * cell_size
	var hh := float(room_h) * cell_size
	var dd := float(room_d) * cell_size
	var corners := [
		Vector3(0, 0, 0), Vector3(ww, 0, 0), Vector3(ww, 0, dd), Vector3(0, 0, dd),
		Vector3(0, hh, 0), Vector3(ww, hh, 0), Vector3(ww, hh, dd), Vector3(0, hh, dd),
	]
	var cp := _cam.global_position
	var dmin := INF
	var dmax := -INF
	for c in corners:
		var d := cp.distance_to(c)
		dmin = minf(dmin, d)
		dmax = maxf(dmax, d)
	_grad_near = dmin
	_grad_far = maxf(dmax, dmin + 0.001)

# ── Render ──────────────────────────────────────────────────────────────────
func _rebuild_overlay() -> void:
	_im.clear_surfaces()
	if _show_backing:
		_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		_backing_quad(Color(0.12, 0.32, 0.52, 0.18))
		_im.surface_end()
	_im.surface_begin(Mesh.PRIMITIVE_LINES)
	_box_edges(Color(0.55, 0.62, 0.78, 0.95))
	_depth_viz(Color(1.0, 0.62, 0.18, 1.0))
	_plane_grid(Color(0.45, 0.88, 1.0, 1.0))
	if _pending != Vector3.INF and _has_cursor:
		_line(_pending, _cursor, Color(1.0, 0.82, 0.20, 1.0))
	# Fill rectangle preview (first corner placed, hovering the second).
	if _tool == "fill" and _fill_pending != Vector3.INF and _has_cursor:
		_rect_outline(_fill_pending, _cursor, Color(1.0, 0.82, 0.20, 1.0))
	# Free-form stroke in progress.
	if _drawing_stroke and _stroke.size() >= 2:
		for i in range(_stroke.size() - 1):
			_line(_stroke[i], _stroke[i + 1], Color(1.0, 0.82, 0.20, 1.0))
	# Cursor: raw point in free-form, magenta on an existing vertex, else green.
	if _tool == "free":
		if _raw_hit != Vector3.INF:
			_cursor_marker(_raw_hit, Color(1.0, 0.7, 0.3, 1.0))
	elif _has_cursor:
		var ccol := Color(1.0, 0.35, 1.0, 1.0) if _snapped_existing else Color(0.45, 1.0, 0.6, 1.0)
		_cursor_marker(_cursor, ccol)
	# Primitive tools: outline the cell the solid will occupy.
	if _has_cursor and (_is_prim_tool() or (_tool == "move" and _moving_prim >= 0)):
		_cell_outline(_cursor, Color(0.45, 1.0, 0.6, 0.85))
	_im.surface_end()

func _rect_outline(a: Vector3, b: Vector3, col: Color) -> void:
	var f: Dictionary = _faces[_active_face]
	var u := (f["u"] as Vector3).normalized()
	var v := (f["v"] as Vector3).normalized()
	var rel := b - a
	var p1 := a + u * rel.dot(u)
	var p3 := a + v * rel.dot(v)
	_line(a, p1, col)
	_line(p1, b, col)
	_line(b, p3, col)
	_line(p3, a, col)

func _rebuild_tubes() -> void:
	if _tubes_root != null and is_instance_valid(_tubes_root):
		_tubes_root.queue_free()
	_compute_gradient_range()
	_tubes_root = SketchMeshLib.build_tubes_gradient(_segments, line_radius, _tube_color)
	add_child(_tubes_root)

func _rebuild_fills() -> void:
	if _fills_root != null and is_instance_valid(_fills_root):
		_fills_root.queue_free()
	_fills_root = SketchMeshLib.build_fills(_fills)
	add_child(_fills_root)

func _rebuild_prims() -> void:
	if _prims_root != null and is_instance_valid(_prims_root):
		_prims_root.queue_free()
	_prims_root = SketchMeshLib.build_prims(_prims)
	add_child(_prims_root)

func _line(a: Vector3, b: Vector3, col: Color) -> void:
	_im.surface_set_color(col)
	_im.surface_add_vertex(a)
	_im.surface_set_color(col)
	_im.surface_add_vertex(b)

func _tri(a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	_im.surface_set_color(col); _im.surface_add_vertex(a)
	_im.surface_set_color(col); _im.surface_add_vertex(b)
	_im.surface_set_color(col); _im.surface_add_vertex(c)

func _depth_viz(col: Color) -> void:
	# Shows how far the painting plane floats off its base face: a dim outline at
	# depth 0, bright posts rising to the plane, and the plane's own outline.
	# This is "the depth we are painting on" made visible.
	if absf(_depth) < 0.001:
		return
	var f: Dictionary = _faces[_active_face]
	var n: Vector3 = f["normal"]
	var u: Vector3 = f["u"]
	var v: Vector3 = f["v"]
	var nu := int(f["nu"])
	var nv := int(f["nv"])
	var base: Vector3 = f["origin"]
	var top: Vector3 = base + n * (_depth * cell_size)
	var corners := [Vector3.ZERO, u * nu, u * nu + v * nv, v * nv]
	var dim := Color(col.r, col.g, col.b, 0.4)
	for k in 4:
		var k2 := (k + 1) % 4
		_line(base + corners[k], base + corners[k2], dim)   # base (depth 0) outline
		_line(top + corners[k], top + corners[k2], col)     # painting-plane outline
		_line(base + corners[k], top + corners[k], col)     # vertical depth post

func _backing_quad(col: Color) -> void:
	var f: Dictionary = _faces[_active_face]
	var n: Vector3 = f["normal"]
	var o: Vector3 = (f["origin"] as Vector3) + n * (_depth * cell_size) - n * 0.01
	var u: Vector3 = f["u"]
	var v: Vector3 = f["v"]
	var nu := int(f["nu"])
	var nv := int(f["nv"])
	var p00 := o
	var p10 := o + u * nu
	var p11 := o + u * nu + v * nv
	var p01 := o + v * nv
	_tri(p00, p10, p11, col)
	_tri(p00, p11, p01, col)

func _box_edges(col: Color) -> void:
	var ww := float(room_w) * cell_size
	var hh := float(room_h) * cell_size
	var dd := float(room_d) * cell_size
	var c := [
		Vector3(0, 0, 0), Vector3(ww, 0, 0), Vector3(ww, 0, dd), Vector3(0, 0, dd),
		Vector3(0, hh, 0), Vector3(ww, hh, 0), Vector3(ww, hh, dd), Vector3(0, hh, dd),
	]
	var edges := [[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]]
	for e in edges:
		_line(c[e[0]], c[e[1]], col)

func _plane_grid(col: Color) -> void:
	var f: Dictionary = _faces[_active_face]
	var n: Vector3 = f["normal"]
	var o: Vector3 = (f["origin"] as Vector3) + n * (_depth * cell_size)
	var u: Vector3 = f["u"]
	var v: Vector3 = f["v"]
	var nu := int(f["nu"])
	var nv := int(f["nv"])
	for i in range(nu + 1):
		_line(o + u * i, o + u * i + v * nv, col)
	for j in range(nv + 1):
		_line(o + v * j, o + v * j + u * nu, col)

func _cursor_marker(p: Vector3, col: Color) -> void:
	var s := cell_size * 0.3
	_line(p - Vector3(s, 0, 0), p + Vector3(s, 0, 0), col)
	_line(p - Vector3(0, s, 0), p + Vector3(0, s, 0), col)
	_line(p - Vector3(0, 0, s), p + Vector3(0, 0, s), col)

## Square outline of the grid cell at `center` on the active plane (primitive ghost).
func _cell_outline(center: Vector3, col: Color) -> void:
	var f: Dictionary = _faces[_active_face]
	var u := (f["u"] as Vector3).normalized() * cell_size
	var v := (f["v"] as Vector3).normalized() * cell_size
	var p00 := center - u * 0.5 - v * 0.5
	var p10 := center + u * 0.5 - v * 0.5
	var p11 := center + u * 0.5 + v * 0.5
	var p01 := center - u * 0.5 + v * 0.5
	_line(p00, p10, col); _line(p10, p11, col); _line(p11, p01, col); _line(p01, p00, col)

# ── UI ────────────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	_help = Label.new()
	_help.add_theme_color_override("font_color", Color(0.78, 0.9, 1.0))
	_help.add_theme_font_size_override("font_size", 15)
	_help.position = Vector2(16, 12)
	cl.add_child(_help)
	_build_panel(cl)
	_refresh()

func _build_panel(cl: CanvasLayer) -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -272.0
	panel.offset_right = -14.0
	panel.offset_top = 14.0
	panel.offset_bottom = 14.0
	panel.grow_vertical = Control.GROW_DIRECTION_END
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.09, 0.13, 0.95)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.25, 0.35, 0.5, 0.85)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	cl.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 7)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "ROOM SKETCHER"
	title.add_theme_color_override("font_color", Color(0.85, 0.93, 1.0))
	title.add_theme_font_size_override("font_size", 16)
	vb.add_child(title)

	_seg_label = Label.new()
	_seg_label.add_theme_color_override("font_color", Color(0.55, 0.95, 1.0))
	vb.add_child(_seg_label)

	# Faces
	vb.add_child(_section("DRAW ON FACE"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for i in 6:
		var b := Button.new()
		b.text = String(_faces[i]["name"]).capitalize()
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(112, 30)
		b.pressed.connect(_set_face.bind(i))
		_face_buttons.append(b)
		grid.add_child(b)
	vb.add_child(grid)

	# Depth — drag the slider ↕ to raise / lower the plane you paint on
	vb.add_child(_section("DRAWING PLANE DEPTH  ↕"))
	_depth_label = Label.new()
	vb.add_child(_depth_label)
	var ext := _face_depth_extent()
	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 12)
	_depth_slider = VSlider.new()
	_depth_slider.custom_minimum_size = Vector2(28, 124)
	_depth_slider.min_value = -ext
	_depth_slider.max_value = ext
	_depth_slider.step = 1.0
	_depth_slider.value = _depth
	_depth_slider.tick_count = ext * 2 + 1
	_depth_slider.ticks_on_borders = true
	_depth_slider.value_changed.connect(_set_depth)
	drow.add_child(_depth_slider)
	var dcol := VBoxContainer.new()
	dcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dcol.add_theme_constant_override("separation", 6)
	dcol.add_child(_mkbtn("Flip in / out", _flip_depth))
	dcol.add_child(_mkbtn("Reset to 0", _set_depth.bind(0.0)))
	var hint := Label.new()
	hint.text = "drag ↕ to move the\npainting plane up / down"
	hint.add_theme_color_override("font_color", Color(0.5, 0.6, 0.72))
	hint.add_theme_font_size_override("font_size", 11)
	dcol.add_child(hint)
	drow.add_child(dcol)
	vb.add_child(drow)

	# Line width
	vb.add_child(_section("LINE WIDTH"))
	var wslider := HSlider.new()
	wslider.min_value = 0.008
	wslider.max_value = 0.06
	wslider.step = 0.002
	wslider.value = line_radius
	wslider.custom_minimum_size = Vector2(0, 20)
	wslider.value_changed.connect(_set_line_radius)
	vb.add_child(wslider)

	# Colors
	vb.add_child(_section("LINE COLOR"))
	var crow := HBoxContainer.new()
	crow.add_theme_constant_override("separation", 6)
	for col in [Color(0.2, 0.9, 1.0), Color(0.4, 1.0, 0.5), Color(1.0, 0.8, 0.25), Color(0.95, 0.95, 1.0)]:
		var cb := Button.new()
		cb.custom_minimum_size = Vector2(50, 26)
		var csb := StyleBoxFlat.new()
		csb.bg_color = col
		csb.set_corner_radius_all(5)
		cb.add_theme_stylebox_override("normal", csb)
		cb.add_theme_stylebox_override("hover", csb)
		cb.add_theme_stylebox_override("pressed", csb)
		cb.pressed.connect(_set_line_color.bind(col))
		crow.add_child(cb)
	vb.add_child(crow)

	# Plane fill toggle
	var chk := CheckButton.new()
	chk.text = "Show plane fill"
	chk.button_pressed = _show_backing
	chk.toggled.connect(_toggle_backing)
	vb.add_child(chk)

	# Tool — what a left-click does
	vb.add_child(_section("TOOL"))
	var trow := GridContainer.new()
	trow.columns = 2
	trow.add_theme_constant_override("h_separation", 6)
	trow.add_theme_constant_override("v_separation", 6)
	trow.add_child(_tool_btn("line", "Line"))
	trow.add_child(_tool_btn("free", "Free"))
	trow.add_child(_tool_btn("fill", "Fill"))
	trow.add_child(_tool_btn("move", "Move"))
	trow.add_child(_tool_btn("paint", "Paint"))
	vb.add_child(trow)

	# Primitives — click a grid corner to drop a solid
	vb.add_child(_section("ADD PRIMITIVE"))
	var prow := GridContainer.new()
	prow.columns = 2
	prow.add_theme_constant_override("h_separation", 6)
	prow.add_theme_constant_override("v_separation", 6)
	prow.add_child(_tool_btn("cube", "Cube"))
	prow.add_child(_tool_btn("sphere", "Sphere"))
	prow.add_child(_tool_btn("cylinder", "Cylinder"))
	prow.add_child(_tool_btn("pyramid", "Pyramid"))
	vb.add_child(prow)

	# Actions
	vb.add_child(_section("ACTIONS"))
	var arow := HBoxContainer.new()
	arow.add_theme_constant_override("separation", 6)
	var undo := _mkbtn("Undo", _undo)
	var clearb := _mkbtn("Clear", _clear)
	undo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clearb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arow.add_child(undo)
	arow.add_child(clearb)
	vb.add_child(arow)
	var arow2 := HBoxContainer.new()
	arow2.add_theme_constant_override("separation", 6)
	var saveb := _mkbtn("Save", _save)
	var loadb := _mkbtn("Load", _load)
	saveb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loadb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arow2.add_child(saveb)
	arow2.add_child(loadb)
	vb.add_child(arow2)

	# Legend
	var legend := Label.new()
	legend.text = "MMB orbit · Shift+MMB pan · wheel zoom · R reset · Line snaps to existing points (magenta) · Move drags a primitive or fill · double-click deletes"
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	legend.add_theme_color_override("font_color", Color(0.5, 0.6, 0.72))
	legend.add_theme_font_size_override("font_size", 11)
	vb.add_child(legend)

func _section(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_color_override("font_color", Color(0.52, 0.68, 0.84))
	l.add_theme_font_size_override("font_size", 12)
	return l

func _mkbtn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	return b

func _tool_btn(tool_name: String, label: String) -> Button:
	var b := Button.new()
	b.text = label
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(0, 28)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(_set_tool.bind(tool_name))
	_tool_buttons[tool_name] = b
	return b

func _refresh() -> void:
	_update_help()
	_update_panel()

func _update_help() -> void:
	if _help == null:
		return
	var f: Dictionary = _faces[_active_face]
	var status_line := ("   " + _status) if _status != "" else ""
	_help.text = "Face: %s   depth %+.0f%s" % [String(f["name"]), _depth, status_line]

func _update_panel() -> void:
	for i in _face_buttons.size():
		_face_buttons[i].button_pressed = (i == _active_face)
	for k in _tool_buttons:
		(_tool_buttons[k] as Button).button_pressed = (k == _tool)
	if _depth_label != null:
		var io := "inward" if _depth >= 0.0 else "outward"
		_depth_label.text = "Depth %+.0f cells  (%s)" % [_depth, io]
	if _seg_label != null:
		_seg_label.text = "lines %d · fills %d · prims %d" % [_segments.size(), _fills.size(), _prims.size()]
	if _depth_slider != null:
		_depth_slider.set_value_no_signal(_depth)

# ── Save / Load ───────────────────────────────────────────────────────────────
func _save() -> void:
	var d := SketchMeshLib.to_dict(Vector3i(room_w, room_h, room_d), cell_size, _segments, _fills, _prims)
	var repo_path := SKETCH_DIR + SKETCH_FILE
	var saved_repo := SketchMeshLib.save_json(repo_path, d)
	SketchMeshLib.save_json(USER_PATH, d)
	var where := ProjectSettings.globalize_path(repo_path if saved_repo else USER_PATH)
	print("[Sketcher] saved %d/%d/%d (lines/fills/prims) -> %s" % [_segments.size(), _fills.size(), _prims.size(), where])
	_status = "SAVED %d/%d/%d" % [_segments.size(), _fills.size(), _prims.size()]
	_refresh()

func _load() -> void:
	var d := SketchMeshLib.load_json(SKETCH_DIR + SKETCH_FILE)
	if d.is_empty():
		d = SketchMeshLib.load_json(USER_PATH)
	if d.is_empty():
		_status = "no saved sketch to load"
		_refresh()
		return
	_segments = SketchMeshLib.segments_from_dict(d)
	_fills = SketchMeshLib.fills_from_dict(d)
	_prims = SketchMeshLib.prims_from_dict(d)
	_history.clear()
	for s in _segments:
		_history.append("seg")
	for f in _fills:
		_history.append("fill")
	for p in _prims:
		_history.append("prim")
	_pending = Vector3.INF
	_fill_pending = Vector3.INF
	_rebuild_tubes()
	_rebuild_fills()
	_rebuild_prims()
	_status = "loaded %d/%d/%d" % [_segments.size(), _fills.size(), _prims.size()]
	_refresh()
