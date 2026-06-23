extends Node3D
class_name CurationStation

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const StationStageScene := preload("res://commons/artifacts/station/station_stage.tscn")
const StationPlinthScene := preload("res://commons/artifacts/station/station_plinth.tscn")
const StationWallScene := preload("res://commons/artifacts/station/station_wall.tscn")
const StationPillarScene := preload("res://commons/artifacts/station/station_pillar.tscn")
const StationCabinetScene := preload("res://commons/artifacts/station/station_cabinet.tscn")
const StationBarrierScene := preload("res://commons/artifacts/station/station_barrier.tscn")
const StationCratesScene := preload("res://commons/artifacts/station/station_crates.tscn")
const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the COMPOSER — give it 1 to 5 artifact lookup-names and it assembles a whole curation bay on the 1 m grid: a step-stage sized to the set, a plinth per item in an even row, a tiling backing wall with end caps, framing pillars, and each artifact grounded inert on its plinth. Origin at the stage centre on the floor.
# desire: to turn a loose handful of artifacts into a presented set — to place them, lift them, back them, and frame them so a viewer reads "these belong together, here, on purpose", with everything landing on grid lines.
# critical_parameter: artifacts (1..5) — the set being curated; their count drives the stage width, the plinth row, and the wall length, all snapped to whole cells.
# triggers: _ready builds the kit, then defers artifact loading so each item enters a settled tree; apply_grid_config re-curates with a new set.
# emerges: one item reads "a single specimen on show"; five read "a collection, a comparison, a shelf made architecture"; the tiling wall + pillars turn the floor into a bay.
# needs: a [[station_stage]] [present]; N [[station_plinth]] columns [present]; a [[station_wall]] backing [present]; framing [[station_pillar]] uprights [present]; the artifacts themselves, inert and grounded [present].
# relationships: the assembler of the whole station family; loads any registered artifact by lookup_name the way [[artifact_review_station]] does; the multi-item sibling of that single-item review tool.
# truth: curation is an argument made with placement. To choose five things, raise them to a line, and put a wall behind is to say they share a question. The grid keeps the argument honest — measured, repeatable, buildable.

@export_group("Set")
## 1 to 5 artifact lookup-names to curate. Missing names leave an empty plinth.
## Default set is INTERACTIVE (buttons + sliders) so you can test the desktop crosshair / VR
## interaction out of the box — swap in any registered artifact.
@export var artifacts: Array[String] = ["ca_rule_explorer", "distribution_sampler", "decision_boundary_viewer"]

@export_group("Layout (grid cells)")
## Cells between plinth centres along the row.
@export var plinth_spacing_cells: int = 2
## Stage depth in cells (front-to-back).
@export var stage_depth_cells: int = 3
## Extra cells of stage margin each side of the plinth row.
@export var stage_margin_cells: int = 2

@export_group("Heights (m)")
@export var plinth_height: float = 1.0
@export var stage_step_height: float = 0.22
@export var wall_height: float = 2.6

@export_group("Pieces")
@export var with_wall: bool = true
@export var with_pillars: bool = true
## A low front barrier (threshold) across the stage front. Open "rail" by default so it never blocks the set.
@export var with_barrier: bool = true
@export var barrier_style: String = "rail"
## Flank the back wall with storage/display cabinets (the "archive behind" read).
@export var with_cabinets: bool = false
## Drop supply crates in the back corners (lived-in dressing).
@export var with_crates: bool = false
@export var with_wall_screen: bool = true
@export var label_plinths: bool = true
## Hide the loaded artifacts' floating billboard Label3D text, so the only text on show is the
## station's own 2D-in-3D plates/screens (surface-pinned). Surface-baked artifact text is kept.
@export var hide_floating_labels: bool = true

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const CELL := 1.0

var _name_scene: Dictionary = {}
var _name_disp: Dictionary = {}   # lookup_name -> human display name
var _plinth_tops: Array = []   # [{x, z, top_y}] per item, set during kit build
var _built := false

func _ready() -> void:
	_read_overrides()
	_build_name_index()
	_build_kit()
	# Load artifacts after the kit is in a settled tree (grounding reads global AABBs).
	call_deferred("_load_artifacts")


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_plinth_tops.clear()
		_built = false
		_build_kit()
		call_deferred("_load_artifacts")


func _read_overrides() -> void:
	if has_meta("config_artifacts"):
		var raw = get_meta("config_artifacts")
		if raw is Array:
			artifacts = []
			for a in raw:
				artifacts.append(str(a))
		elif raw is String and str(raw).strip_edges() != "":
			artifacts = []
			for a in str(raw).split(","):
				artifacts.append(a.strip_edges())
	if has_meta("config_plinth_spacing_cells"): plinth_spacing_cells = int(str(get_meta("config_plinth_spacing_cells")))
	if has_meta("config_plinth_height"): plinth_height = float(str(get_meta("config_plinth_height")))
	if has_meta("config_with_wall"): with_wall = _b(get_meta("config_with_wall"))
	if has_meta("config_with_pillars"): with_pillars = _b(get_meta("config_with_pillars"))
	if has_meta("config_with_barrier"): with_barrier = _b(get_meta("config_with_barrier"))
	if has_meta("config_barrier_style"): barrier_style = str(get_meta("config_barrier_style")).to_lower()
	if has_meta("config_with_cabinets"): with_cabinets = _b(get_meta("config_with_cabinets"))
	if has_meta("config_with_crates"): with_crates = _b(get_meta("config_with_crates"))


func _count() -> int:
	return clampi(artifacts.size(), 1, 5)


func _build_kit() -> void:
	_built = true
	var n: int = _count()
	var spacing: float = float(maxi(plinth_spacing_cells, 1)) * CELL
	# Plinth row, centred on origin.
	var xs: Array = []
	for i in range(n):
		xs.append((float(i) - float(n - 1) * 0.5) * spacing)
	var row_span: float = float(n - 1) * spacing
	# Stage footprint (whole cells), wide enough for the row + margin.
	var stage_w_cells: int = int(ceil(row_span)) + maxi(stage_margin_cells, 1) * 2 + 1
	var depth_cells: int = maxi(stage_depth_cells, 2)
	var plinth_z: float = float(depth_cells) * 0.5 * CELL - 1.1   # toward the front of the deck
	var back_z: float = -float(depth_cells) * 0.5 * CELL

	# Stage.
	var stage: Node3D = StationStageScene.instantiate()
	add_child(stage)
	stage.apply_grid_config({
		"width_cells": stage_w_cells, "depth_cells": depth_cells,
		"step_height": stage_step_height, "hazard_edge": true, "edge_light": true,
		"stencil_text": "CURATION", "body_color": _cs(body_color),
		"panel_color": _cs(panel_color), "accent_color": _cs(accent_color),
	})

	# Plinths + record where each artifact sits.
	for i in range(n):
		var nm := str(artifacts[i]) if i < artifacts.size() else ""
		var p: Node3D = StationPlinthScene.instantiate()
		add_child(p)
		p.position = Vector3(xs[i], stage_step_height, plinth_z)
		p.apply_grid_config({
			"footprint_cells": 1, "top_height": plinth_height, "top_style": "tray",
			"edge_light": true, "stencil_text": "", "three_bar": false, "body_color": _cs(body_color),
			"panel_color": _cs(panel_color), "accent_color": _cs(accent_color),
		})
		_plinth_tops.append({"x": xs[i], "z": plinth_z, "top_y": stage_step_height + plinth_height})
		# Framed, multi-line 2D-in-3D name plaque mounted PROUD of the plinth front (no z-fighting
		# with the body panel; catalogue number + wrapped name in one bezelled caption).
		if label_plinths:
			var disp: String = _clean_name(str(_name_disp.get(nm, nm))) if nm != "" else "ITEM-%d" % (i + 1)
			var plaque := _make_label_plaque(disp, "%02d" % (i + 1))
			plaque.position = Vector3(xs[i], stage_step_height + plinth_height * 0.42, plinth_z + 0.32)
			add_child(plaque)

	# Backing wall — tiling run with end caps, length = stage width.
	if with_wall:
		var wall: Node3D = StationWallScene.instantiate()
		add_child(wall)
		wall.position = Vector3(0, 0, back_z - 0.12)
		wall.apply_grid_config({
			"length_cells": stage_w_cells, "start_cap": true, "end_cap": true,
			"height": wall_height, "panel_style": "panel", "screen_slot": with_wall_screen,
			"screen_header": "CURATION", "screen_lines": ["%d ON SHOW" % n, "LINK  OK"],
			"lit_seam": true, "body_color": _cs(body_color), "panel_color": _cs(panel_color),
			"accent_color": _cs(accent_color),
		})

	# Framing pillars at the two front corners of the stage.
	if with_pillars:
		var half_w: float = float(stage_w_cells) * 0.5 * CELL
		var front_z: float = float(depth_cells) * 0.5 * CELL
		for sx in [-1.0, 1.0]:
			var pil: Node3D = StationPillarScene.instantiate()
			add_child(pil)
			pil.position = Vector3(sx * (half_w - 0.45), 0, front_z - 0.45)
			pil.apply_grid_config({
				"height": wall_height, "lit_groove": true, "body_color": _cs(body_color),
				"panel_color": _cs(panel_color), "accent_color": _cs(accent_color),
			})

	var half_w: float = float(stage_w_cells) * 0.5 * CELL
	var front_z: float = float(depth_cells) * 0.5 * CELL

	# Front barrier — a low threshold across the stage front (open rail = never blocks the set).
	if with_barrier:
		var bar: Node3D = StationBarrierScene.instantiate()
		add_child(bar)
		bar.position = Vector3(0, 0, front_z + 0.05)
		bar.apply_grid_config({
			"length_cells": stage_w_cells, "height": 1.0, "style": barrier_style,
			"hazard_base": true, "panel_color": _cs(body_color), "post_color": _cs(panel_color),
			"accent_color": _cs(accent_color),
		})

	# Flanking storage/display cabinets against the back wall (the "archive behind" read).
	if with_cabinets:
		for sx in [-1.0, 1.0]:
			var cab: Node3D = StationCabinetScene.instantiate()
			add_child(cab)
			cab.position = Vector3(sx * (half_w - 1.0), 0, back_z + 0.45)
			cab.apply_grid_config({
				"width_cells": 2, "shelf_count": 4, "front_style": "glass",
				"body_color": _cs(body_color), "panel_color": _cs(panel_color), "accent_color": _cs(accent_color),
			})

	# Supply crates in the back corners (lived-in dressing).
	if with_crates:
		for sx2 in [-1.0, 1.0]:
			var cr: Node3D = StationCratesScene.instantiate()
			add_child(cr)
			cr.position = Vector3(sx2 * (half_w - 0.55), 0, back_z + 0.6)
			cr.apply_grid_config({"footprint_cells": 1, "crate_count": 4, "palette": "metal", "seed_index": int(sx2) + 3})


func _load_artifacts() -> void:
	var n: int = _count()
	for i in range(n):
		if i >= _plinth_tops.size():
			break
		var nm := str(artifacts[i]) if i < artifacts.size() else ""
		if nm == "" or not _name_scene.has(nm):
			continue
		var packed = load(_name_scene[nm])
		if packed == null:
			continue
		var inst = packed.instantiate()
		if inst == null:
			continue
		var slot: Dictionary = _plinth_tops[i]
		add_child(inst)   # enters a settled tree -> its _ready builds before we measure
		_make_inert(inst)
		if hide_floating_labels:
			_hide_labels(inst)
		if inst.has_method("apply_grid_config"):
			inst.apply_grid_config({"emissive": false})
		# Ground the artifact so its base sits on the plinth cap.
		var aabb := _combined_aabb(inst)
		var base_y: float = aabb.position.y if aabb.size.length() > 0.0 else 0.0
		if inst is Node3D:
			inst.position = Vector3(slot["x"], float(slot["top_y"]) - base_y, slot["z"])


# ---------------------------------------------------------------- registry + helpers
func _build_name_index() -> void:
	var dir := DirAccess.open("res://commons/artifacts/registry")
	if dir == null:
		return
	for fn in dir.get_files():
		if not fn.ends_with(".json"):
			continue
		var f := FileAccess.open("res://commons/artifacts/registry/" + fn, FileAccess.READ)
		if f == null:
			continue
		var data = JSON.parse_string(f.get_as_text())
		if not (data is Dictionary):
			continue
		for k in (data.get("artifacts", {}) as Dictionary).keys():
			var v = data["artifacts"][k]
			if v is Dictionary and v.has("scene") and ResourceLoader.exists(str(v["scene"])):
				var ln := str(v.get("lookup_name", k))
				_name_scene[ln] = str(v["scene"])
				_name_disp[ln] = str(v.get("name", ln))


# Layers an artifact KEEPS even when made inert, so its controls stay usable:
# 3 (pickable) + 19 (grab handles) + 21 (area buttons). World/body layers are dropped.
const INTERACT_LAYERS := 1310724

func _make_inert(node: Node) -> void:
	# Non-blocking + non-falling, but PRESERVE interaction layers so the artifact's
	# buttons / sliders / knobs / grab still respond — you can test them with the desktop
	# crosshair (LMB press / drag, RMB grab) or in VR, instead of just looking at them.
	if node is CollisionObject3D:
		node.collision_layer = node.collision_layer & INTERACT_LAYERS
		node.collision_mask = 0
		if node is RigidBody3D:
			node.freeze = true
	elif node is SoftBody3D:
		node.collision_layer = node.collision_layer & INTERACT_LAYERS
		node.collision_mask = 0
	for c in node.get_children():
		_make_inert(c)


func _combined_aabb(node: Node) -> AABB:
	var out := AABB()
	var got := false
	if node is VisualInstance3D:
		out = (node as VisualInstance3D).global_transform * (node as VisualInstance3D).get_aabb()
		got = true
	for c in node.get_children():
		var ca := _combined_aabb(c)
		if ca.size.length() > 0.0:
			out = out.merge(ca) if got else ca
			got = true
	return out


func _short_label(nm: String, i: int) -> String:
	if nm == "":
		return "ITEM-%d" % (i + 1)
	var up := nm.to_upper()
	return up.substr(0, 14)


# Hide the artifact's floating billboard text (Label3D) so the station's 2D-in-3D
# plates are the only captions; surface-baked text (MeshInstance3D) is untouched.
func _hide_labels(node: Node) -> void:
	if node is Label3D:
		(node as Label3D).visible = false
	for c in node.get_children():
		_hide_labels(c)


# Strip a leading curriculum number prefix (e.g. "1.0 a Point" -> "Point") for clean plates.
func _clean_name(s: String) -> String:
	var re := RegEx.new()
	re.compile("^\\s*\\d+(\\.\\d+)?\\s+([a-zA-Z]\\s+)?")
	var out := re.sub(s, "", false)
	out = out.strip_edges()
	return out if out != "" else s


# A framed, multi-line 2D-in-3D caption plaque (museum label) that stands PROUD of a surface:
# a light bezel + a dark emissive screen + an accent catalogue number + the wrapped name.
# Origin at the plaque centre on the mounting plane; it builds forward (+Z).
func _make_label_plaque(name_text: String, number: String) -> Node3D:
	var root := Node3D.new()
	var name_lines: Array = _wrap(name_text.to_upper(), 11)
	if name_lines.is_empty():
		name_lines = [name_text.to_upper()]
	var num_h := 0.034
	var name_h := 0.052
	var pad := 0.03
	var pw := 0.5
	var ph: float = pad * 2.0 + num_h + name_h * float(name_lines.size())
	var depth := 0.03
	# Light bezel frame.
	root.add_child(_box(Vector3(0, 0, depth * 0.5), Vector3(pw + 0.05, ph + 0.05, depth), HangarKit.rams_body(panel_color.lightened(0.06), 0.05)))
	# Dark emissive screen face, proud of the frame.
	root.add_child(_box(Vector3(0, 0, depth + 0.005), Vector3(pw, ph, 0.008), _emi(Color(0.09, 0.10, 0.12), 0.3)))
	# Accent groove under the number line.
	root.add_child(_box(Vector3(0, ph * 0.5 - pad - num_h - 0.004, depth + 0.01), Vector3(pw * 0.82, 0.006, 0.006), _emi(accent_color, 0.7)))
	# Text — number then wrapped name, stacked top-down, all crisp 2D-in-3D.
	var tz: float = depth + 0.014
	var ty: float = ph * 0.5 - pad
	var num: MeshInstance3D = BakedText.make_label_mesh(number, accent_color, Vector2(pw * 0.5, num_h * 0.85), 1400, true)
	if num:
		num.position = Vector3(0, ty - num_h * 0.5, tz)
		root.add_child(num)
	ty -= num_h
	for ln in name_lines:
		var q: MeshInstance3D = BakedText.make_label_mesh(str(ln), Color(0.94, 0.92, 0.87), Vector2(pw * 0.92, name_h * 0.82), 1400, true)
		if q:
			q.position = Vector3(0, ty - name_h * 0.5, tz)
			root.add_child(q)
		ty -= name_h
	return root


# Word-wrap a string to lines of at most max_chars (keeps whole words).
func _wrap(s: String, max_chars: int) -> Array:
	var lines: Array = []
	var cur := ""
	for w in s.split(" "):
		var word := str(w)
		if word == "":
			continue
		if cur == "":
			cur = word
		elif cur.length() + 1 + word.length() <= max_chars:
			cur += " " + word
		else:
			lines.append(cur)
			cur = word
	if cur != "":
		lines.append(cur)
	return lines


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _emi(c: Color, energy: float) -> StandardMaterial3D:
	return HangarKit.emissive(c, energy)


func _cs(c: Color) -> String:
	return "%f,%f,%f" % [c.r, c.g, c.b]


func _b(v) -> bool:
	return str(v).to_lower() in ["true", "1", "yes", "on"]
