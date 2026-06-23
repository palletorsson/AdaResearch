extends Node3D
class_name CurationStation

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const StationStageScene := preload("res://commons/artifacts/station/station_stage.tscn")
const StationPlinthScene := preload("res://commons/artifacts/station/station_plinth.tscn")
const StationWallScene := preload("res://commons/artifacts/station/station_wall.tscn")
const StationPillarScene := preload("res://commons/artifacts/station/station_pillar.tscn")
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
@export var artifacts: Array[String] = ["point", "csg_union_demo", "game_of_life_petri"]

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
			"edge_light": true, "stencil_text": "%02d" % (i + 1), "body_color": _cs(body_color),
			"panel_color": _cs(panel_color), "accent_color": _cs(accent_color),
		})
		_plinth_tops.append({"x": xs[i], "z": plinth_z, "top_y": stage_step_height + plinth_height})
		# 2D-in-3D name plate pinned to the plinth front — a museum caption, surface-fixed (not a billboard).
		if label_plinths:
			var disp: String = _clean_name(str(_name_disp.get(nm, nm))) if nm != "" else "ITEM-%d" % (i + 1)
			var plate: MeshInstance3D = BakedText.make_panel_mesh(disp.to_upper(), Color(0.10, 0.11, 0.13), Color(0.93, 0.91, 0.86), Vector2(0.56, 0.12), 1400, true)
			if plate:
				plate.position = Vector3(xs[i], stage_step_height + plinth_height * 0.40, plinth_z + 0.31)
				add_child(plate)

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


func _make_inert(node: Node) -> void:
	if node is CollisionObject3D:
		node.collision_layer = 0
		node.collision_mask = 0
		if node is RigidBody3D:
			node.freeze = true
	elif node is SoftBody3D:
		node.collision_layer = 0
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


func _cs(c: Color) -> String:
	return "%f,%f,%f" % [c.r, c.g, c.b]


func _b(v) -> bool:
	return str(v).to_lower() in ["true", "1", "yes", "on"]
