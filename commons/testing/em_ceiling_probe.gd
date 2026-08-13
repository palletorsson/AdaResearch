## em_ceiling_probe.gd — the counterfactual that answers "can the museum use the
## grid ceiling system?" by BUILDING it and photographing the result.
##
## This is an EXPERIMENT, not a feature. It edits nothing on disk and it is not
## reachable from any shipped code path: `endless_museum.tscn` is instantiated
## unmodified, allowed to run its own `_ready()` (which builds the corridor and
## schedules its own composed proof shot 90 frames out), and then — inside that
## 90-frame window, before the shutter — this script optionally swaps em_detail's
## coffered roof for GridCeilingComponent's suspended drop ceiling.
##
## That window is why the BEFORE and AFTER frames are strictly comparable: the
## standpoint is chosen by the museum's own `_compose_auto_shot`, from the same
## seed, on the same building, with the same rig. The ONLY difference between the
## two images is which ceiling is in the room.
##
##   --probe=none   leave the museum alone (BEFORE; must equal a plain run)
##   --probe=grid   hide em_detail's Ceiling/ArrisCeiling, install
##                  GridCeilingComponent per segment over the same footprint
##   --report=<path>  write the geometry census as JSON
##   --pitch=<rad>  tilt the composed camera up by this much, keeping its
##                  standpoint. The museum's own proof frame is composed to hold
##                  a foreground wall plane, which leaves the ceiling a corner of
##                  the picture — fine for "did the room change", useless for
##                  "did the CEILING change". The override is a constant applied
##                  identically in both modes, so the pair stays comparable.
##
## Run (both modes, one at a time — never two Godot instances):
##   python tools/godot_watchdog.py --expect=<png> -- \
##     "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . \
##     --xr-mode off --no-window \
##     --script res://commons/testing/em_ceiling_probe.gd -- \
##     --probe=grid --em-seed=46 --em-shot=user://em_after.png --em-segments=1 \
##     --report=user://em_ceiling_after.json
extends SceneTree

const MUSEUM_SCENE := "res://commons/scenes/endless_museum.tscn"
const CEILING_COMPONENT := "res://commons/grid/GridCeilingComponent.gd"

# duplicated from em_detail.gd / endless_museum.gd rather than imported — this
# script must not create a preload edge into the scene it is probing.
const VESTIBULE_H := 4
const LOBBY_W := 17

var _mode: String = "none"
var _report_path: String = ""
var _pitch: float = 0.0
var _pitch_set: bool = false
var _overhead: bool = false
var _stand: Vector3 = Vector3.ZERO
var _stand_set: bool = false
var _census: Dictionary = {}


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		args = OS.get_cmdline_args()
	for a in args:
		if a.begins_with("--probe="):
			_mode = a.substr(8)
		elif a.begins_with("--report="):
			_report_path = a.substr(9)
		elif a.begins_with("--pitch="):
			_pitch = float(a.substr(8))
			_pitch_set = true
		elif a == "--overhead":
			_overhead = true
		elif a.begins_with("--stand="):
			var parts: PackedStringArray = a.substr(8).split(",")
			if parts.size() >= 2:
				_stand = Vector3(float(parts[0]), 0.0, float(parts[1]))
				_stand_set = true
	_run.call_deferred()


func _run() -> void:
	var packed: PackedScene = load(MUSEUM_SCENE)
	if packed == null:
		push_error("em_ceiling_probe: cannot load %s" % MUSEUM_SCENE)
		quit(1)
		return

	# add_child runs the museum's _ready() synchronously: corridor built, proof
	# shot composed, shutter armed for 90 frames from now.
	var museum: Node = packed.instantiate()
	get_root().add_child(museum)

	_census = {
		"mode": _mode,
		"museum_ceiling": _survey_museum_ceiling(museum),
	}

	if _mode == "grid" or _mode == "hide":
		_census["grid_ceiling"] = _install_grid_ceiling(museum, _mode == "grid")

	# WHAT IS ACTUALLY OVERHEAD. The hide-only control proved that removing
	# em_detail's roof changes nothing in the top 58% of the ceiling-aimed frame,
	# which means something else is up there. Anything whose world AABB reaches
	# above the museum's wall head and spans more than a few square metres in
	# plan is a candidate, so it gets named rather than guessed at.
	if _overhead:
		_census["overhead"] = _survey_overhead(museum)

	if _stand_set:
		var body: Variant = museum.get("_player")
		if body is Node3D:
			(body as Node3D).position = _stand
			(body as Node3D).rotation = Vector3.ZERO
			_census["stand"] = [_stand.x, _stand.z]

	if _pitch_set:
		var cam: Variant = museum.get("_cam")
		if cam is Camera3D:
			(cam as Camera3D).rotation = Vector3(_pitch, 0.0, 0.0)
			_census["pitch"] = _pitch

	_write_report()
	print("[em_ceiling_probe] mode=%s census=%s" % [_mode, JSON.stringify(_census)])


## What em_detail actually put overhead: the two MultiMeshInstance3D families,
## and their per-instance box counts. Also the lowest and highest y any ceiling
## instance reaches, read off the transforms rather than off the constants — a
## constant is a claim, a transform is the geometry.
func _survey_museum_ceiling(museum: Node) -> Dictionary:
	var out: Dictionary = {
		"nodes": 0, "instances": 0, "mesh_instance_nodes": 0,
		"low_y": 1e9, "high_y": -1e9, "families": [],
	}
	for mmi in _find_all(museum, "MultiMeshInstance3D"):
		var nm: String = String(mmi.name)
		if nm != "Ceiling" and nm != "ArrisCeiling":
			continue
		var mm: MultiMesh = mmi.multimesh
		if mm == null:
			continue
		var n: int = mm.instance_count
		out["nodes"] = int(out["nodes"]) + 1
		out["instances"] = int(out["instances"]) + n
		out["families"].append({"name": nm, "instances": n})
		var seg_y: float = 0.0
		var parent: Node = mmi.get_parent()
		if parent is Node3D:
			seg_y = (parent as Node3D).global_position.y
		for i in range(n):
			var t: Transform3D = mm.get_instance_transform(i)
			# the box is a unit BoxMesh scaled by the basis, so the extent is
			# origin.y +/- half the basis' y column length
			var half: float = t.basis.get_scale().y * 0.5
			var lo: float = seg_y + t.origin.y - half
			var hi: float = seg_y + t.origin.y + half
			out["low_y"] = minf(float(out["low_y"]), lo)
			out["high_y"] = maxf(float(out["high_y"]), hi)
	return out


## Hide em_detail's roof and put GridCeilingComponent in its place, per segment,
## over exactly the footprint em_detail was covering (x -1 .. max(LOBBY_W, w+1),
## z 0 .. VESTIBULE_H + h, segment-local).
## `install = false` is the control: hide em_detail's roof and put NOTHING back.
## It exists because a swap that changes nothing in a region of the frame is
## indistinguishable from a swap that never reached it, and the only way to tell
## those apart is to remove the thing and see whether the picture notices.
func _install_grid_ceiling(museum: Node, install: bool = true) -> Dictionary:
	var out: Dictionary = {
		"hidden_families": 0, "segments": 0, "tiles": 0, "lights": 0,
		"omni_lights": 0, "mesh_instance_nodes": 0, "height": 0.0,
		"tile_size": 0.0, "low_y": 1e9,
	}

	# 1. take em_detail's ceiling out of the picture. layers = 0 is the corpus
	#    rule (per-instance, no propagation, material untouched); cast_shadow off
	#    so it cannot shadow the room it is no longer in.
	for mmi in _find_all(museum, "MultiMeshInstance3D"):
		var nm: String = String(mmi.name)
		if nm != "Ceiling" and nm != "ArrisCeiling":
			continue
		mmi.layers = 0
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visible = false
		out["hidden_families"] = int(out["hidden_families"]) + 1

	if not install:
		return out

	var script: GDScript = load(CEILING_COMPONENT)
	if script == null:
		push_error("em_ceiling_probe: cannot load %s" % CEILING_COMPONENT)
		return out

	var segments: Variant = museum.get("_segments")
	if not (segments is Array) or (segments as Array).is_empty():
		push_error("em_ceiling_probe: museum exposed no _segments")
		return out

	for entry in (segments as Array):
		var seg: Dictionary = entry
		var node: Node3D = seg["node"]
		var w: int = int(seg["w"])
		var h: int = int(round(float(seg["z1"]) - float(seg["z0"]))) - VESTIBULE_H
		var x0: float = -1.0
		var x1: float = float(maxi(LOBBY_W, w + 1))
		var width_m: float = x1 - x0
		var depth_m: float = float(VESTIBULE_H + h)

		# GridCeilingComponent types data_component strictly, so it gets a real
		# GridDataComponent with only grid_dimensions set — the same stub the
		# ceiling DNA gallery uses.
		var stub: GridDataComponent = GridDataComponent.new()
		stub.grid_dimensions = Vector3i(int(width_m), 1, int(depth_m))
		node.add_child(stub)

		var ceiling = script.new()
		ceiling.grid_system = node
		ceiling.data_component = stub
		ceiling.cube_size = 1.0
		ceiling.gutter = 0.0
		node.add_child(ceiling)
		# the shipped default: no preset, no overrides beyond the footprint. This
		# is the honest "just use the grid ceiling" case.
		ceiling.generate_ceiling({
			"width": width_m, "depth": depth_m,
			"offset_x": x0, "offset_z": 0.0,
		})

		out["segments"] = int(out["segments"]) + 1
		var info: Dictionary = ceiling.get_ceiling_info()
		out["tiles"] = int(out["tiles"]) + int(info["tile_count"])
		out["lights"] = int(out["lights"]) + int(info["light_count"])
		out["height"] = float(info["height"])
		out["tile_size"] = float(info["tile_size"])
		out["low_y"] = minf(float(out["low_y"]), float(info["height"]))

	# what the renderer is actually handed, counted on the built tree
	out["mesh_instance_nodes"] = _count_ceiling_mesh_nodes(museum)
	out["omni_lights"] = _find_all(museum, "OmniLight3D").size()
	return out


## Every MeshInstance3D living under a CeilingGrid / CeilingTiles / CeilingLights
## / CeilingFixtures container — i.e. the grid ceiling's true node cost.
func _count_ceiling_mesh_nodes(root: Node) -> int:
	var total: int = 0
	for c in _find_all(root, "Node3D"):
		var nm: String = String(c.name)
		if nm != "CeilingGrid" and nm != "CeilingTiles" and nm != "CeilingLights" \
				and nm != "CeilingFixtures":
			continue
		total += _find_all(c, "MeshInstance3D").size()
	return total


## Every visible GeometryInstance3D whose world AABB reaches above 2.90 m, ranked
## by plan area — i.e. by how much ceiling it could be hiding.
func _survey_overhead(museum: Node) -> Array:
	var rows: Array = []
	for n in _find_all(museum, "GeometryInstance3D"):
		var gi: GeometryInstance3D = n
		if not gi.is_visible_in_tree() or gi.layers == 0:
			continue
		var ab: AABB = gi.get_aabb()
		var g: Transform3D = gi.global_transform
		var top: float = -1e9
		var bottom: float = 1e9
		var minx: float = 1e9
		var maxx: float = -1e9
		var minz: float = 1e9
		var maxz: float = -1e9
		for c in range(8):
			var p: Vector3 = g * ab.get_endpoint(c)
			top = maxf(top, p.y)
			bottom = minf(bottom, p.y)
			minx = minf(minx, p.x); maxx = maxf(maxx, p.x)
			minz = minf(minz, p.z); maxz = maxf(maxz, p.z)
		if top < 2.90:
			continue
		var area: float = (maxx - minx) * (maxz - minz)
		if area < 6.0:
			continue
		rows.append({
			"name": String(gi.name), "class": gi.get_class(),
			"parent": String(gi.get_parent().name),
			"y": [snappedf(bottom, 0.001), snappedf(top, 0.001)],
			"plan_m2": snappedf(area, 0.1),
			"x": [snappedf(minx, 0.1), snappedf(maxx, 0.1)],
			"z": [snappedf(minz, 0.1), snappedf(maxz, 0.1)],
		})
	rows.sort_custom(func(a, b): return float(a["plan_m2"]) > float(b["plan_m2"]))
	return rows.slice(0, 14)


func _find_all(root: Node, cls: String) -> Array:
	var out: Array = []
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.is_class(cls):
			out.append(n)
		for c in n.get_children():
			stack.append(c)
	return out


func _write_report() -> void:
	if _report_path == "":
		return
	var f: FileAccess = FileAccess.open(_report_path, FileAccess.WRITE)
	if f == null:
		push_warning("em_ceiling_probe: cannot write %s" % _report_path)
		return
	f.store_string(JSON.stringify(_census, "\t"))
	f.close()
	print("[em_ceiling_probe] report -> %s" % _report_path)
