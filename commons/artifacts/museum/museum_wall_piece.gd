extends Node3D
class_name MuseumWallPiece

## One typed span in the one-metre museum wall kit. Every piece claims an integer
## width, exposes compatible flat-wall sockets, and keeps its visible work inside
## that claim so pieces can butt together without scaling.

@export_enum("solid", "feature", "window", "vitrine", "service", "portal", "endcap")
var kind: String = "solid"
@export_range(1, 4, 1) var width_cells: int = 1
@export_range(3.0, 6.0, 0.25) var height: float = 4.0
@export var finish: String = "uffizi_stone"
@export var flip: bool = false
@export var enable_collision: bool = true
@export var quality_tier: String = "aaa"
@export var detail_seed: int = 4067
@export_range(0, 2, 1) var lod_level: int = 0

const DEPTH := 0.15
const FRONT_Z := DEPTH * 0.5
const PHYSICS_CONTRACT := "res://commons/data/museum_wall_physics_contract.json"
const ARCHITECTURAL_SPANS := preload("res://commons/artifacts/museum/museum_wall_architectural_spans.gd")
const OPENING_SPANS := preload("res://commons/artifacts/museum/museum_wall_opening_spans.gd")
const ALLOWED_KINDS := [&"solid", &"feature", &"window", &"vitrine", &"service", &"portal", &"endcap"]

var _built := false
var _stone: Material = StandardMaterial3D.new()
var _stone_alt: Material = StandardMaterial3D.new()
var _trim: Material = StandardMaterial3D.new()
var _bronze: Material = StandardMaterial3D.new()
var _glass: Material = StandardMaterial3D.new()
var _dark := StandardMaterial3D.new()

static var _shared_unit_box: BoxMesh
static var _shared_collision_shapes: Dictionary = {}
static var _shared_emissive_materials: Dictionary = {}
static var _shared_physics_materials: Dictionary = {}
static var _physics_contract_cache: Dictionary = {}


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for key in config_data:
		set_meta("config_%s" % str(key), config_data[key])
	_read_metadata_overrides()
	if _built:
		for child in get_children():
			child.queue_free()
		_built = false
	_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_kind"): kind = str(get_meta("config_kind")).to_lower()
	if has_meta("config_width_cells"): width_cells = int(str(get_meta("config_width_cells")))
	elif has_meta("config_length_cells"): width_cells = int(str(get_meta("config_length_cells")))
	if has_meta("config_height"): height = float(str(get_meta("config_height")))
	if has_meta("config_finish"): finish = str(get_meta("config_finish"))
	if has_meta("config_flip"): flip = _bool(get_meta("config_flip"))
	if has_meta("config_enable_collision"): enable_collision = _bool(get_meta("config_enable_collision"))
	if has_meta("config_quality_tier"): quality_tier = str(get_meta("config_quality_tier")).to_lower()
	if has_meta("config_detail_seed"): detail_seed = int(str(get_meta("config_detail_seed")))
	elif has_meta("config_seed"): detail_seed = int(str(get_meta("config_seed")))
	if has_meta("config_lod_level"): lod_level = clampi(int(str(get_meta("config_lod_level"))), 0, 2)


func _build() -> void:
	_built = true
	width_cells = clampi(width_cells, 1, 4)
	height = clampf(height, 3.0, 6.0)
	if not ALLOWED_KINDS.has(StringName(kind)):
		kind = "solid"
	if kind == "portal":
		width_cells = maxi(width_cells, 2)
	_build_materials()

	var contract := Node3D.new()
	contract.name = "PieceContract"
	contract.set_meta("kind", kind)
	contract.set_meta("width_m", float(width_cells))
	contract.set_meta("height_m", height)
	contract.set_meta("grid_m", 1.0)
	contract.set_meta("left_socket", "museum_wall_flat_v1")
	contract.set_meta("right_socket", "museum_wall_flat_v1")
	contract.set_meta("feature_safe", kind in ["solid", "feature"])
	contract.set_meta("quality_tier", quality_tier)
	contract.set_meta("detail_seed", detail_seed)
	contract.set_meta("lod_levels", 3)
	contract.set_meta("lod_level", lod_level)
	contract.set_meta("physics_contract", PHYSICS_CONTRACT)
	contract.set_meta("physics_profile", kind)
	var terminal_side := "none"
	if kind == "endcap":
		terminal_side = "right" if flip else "left"
	contract.set_meta("terminal_side", terminal_side)
	contract.set_meta("seam_owner_policy", "left_boundary_owns_join")
	contract.set_meta("datums_m", {"wall_face_z": FRONT_Z, "skirting_y": 0.14, "picture_rail_y": 2.85, "cornice_y": height - 0.17})
	add_child(contract)

	_add_socket(contract, "SocketLeft", -float(width_cells) * 0.5, Vector3.LEFT, terminal_side == "left", true)
	_add_socket(contract, "SocketRight", float(width_cells) * 0.5, Vector3.RIGHT, terminal_side == "right", false)

	match kind:
		"feature": _build_feature(contract)
		"window":
			if width_cells >= 2: _build_opening_span(contract)
			else: _build_window(contract)
		"vitrine":
			if width_cells >= 2: _build_opening_span(contract)
			else: _build_vitrine(contract)
		"service": _build_service(contract)
		"portal": _build_opening_span(contract)
		"endcap": _build_endcap(contract)
		_: _build_solid(contract)
	if kind in ["solid", "feature", "service", "endcap"]:
		var architectural_report: Dictionary = ARCHITECTURAL_SPANS.decorate(contract, {
			"family": kind, "width_cells": width_cells, "height": height,
			"finish": finish, "flip": flip, "seed": detail_seed,
			"wear_state": "lived_in", "quality_tier": 2,
			# Collision is owned here so every canonical surface has one truthful
			# body and the helper cannot add duplicate protrusion coverage.
			"enable_collision": false,
			"canonical_collision_owner": enable_collision,
		})
		if enable_collision:
			var collision_report := _build_architectural_collision_zones(contract)
			architectural_report["collision_scope"] = "piece_canonical_surface_zones"
			architectural_report["collision_shapes"] = int(collision_report["shape_count"])
			architectural_report["collision_bodies"] = int(collision_report["body_count"])
			contract.set_meta("collision_report", collision_report)
		contract.set_meta("architectural_report", architectural_report)


func _build_opening_span(parent: Node3D) -> void:
	var palette: Dictionary = OPENING_SPANS.default_palette(finish)
	var result: Dictionary = OPENING_SPANS.build(parent, kind, width_cells, height, palette, {
		"enable_collision": enable_collision,
		"enable_interaction_hooks": enable_collision,
		"enable_local_lights": false,
		"detail_tier": lod_level,
		"seed": detail_seed,
		"flip": flip,
	})
	parent.set_meta("opening_report", result.get("contract", {}))
	parent.set_meta("opening_metrics", result.get("metrics", {}))
	# A tiny edge inspection witness carries visible deterministic variation
	# without changing the architectural aperture or its collision.
	var witness_side := -1.0 if posmod(detail_seed, 2) == 0 else 1.0
	var witness_y := 0.44 + float(posmod(detail_seed, 5)) * 0.045
	parent.add_child(_box("SeededMaintenanceWitness", Vector3(witness_side * (float(width_cells) * 0.5 - 0.105), witness_y, 0.325), Vector3(0.11, 0.028, 0.018), _bronze))


func _build_materials() -> void:
	var shared_palette: Dictionary = OPENING_SPANS.default_palette(finish)
	if finish == "white_gallery":
		_stone = ARCHITECTURAL_SPANS.create_pbr_material("stone", Color(0.92, 0.91, 0.88), Vector2(1.1, 3.8), detail_seed)
		_stone_alt = ARCHITECTURAL_SPANS.create_pbr_material("stone", Color(0.78, 0.76, 0.71), Vector2(1.0, 3.8), detail_seed + 1)
	else:
		_stone = ARCHITECTURAL_SPANS.create_pbr_material("stone", Color(0.83, 0.78, 0.68), Vector2(1.1, 3.8), detail_seed)
		_stone_alt = ARCHITECTURAL_SPANS.create_pbr_material("stone", Color(0.7, 0.64, 0.55), Vector2(1.0, 3.8), detail_seed + 1)
	_trim = shared_palette.get("trim") as Material
	_bronze = ARCHITECTURAL_SPANS.create_pbr_material("bronze", Color(0.52, 0.38, 0.22), Vector2(1.2, 2.5), detail_seed + 2)
	_dark = shared_palette.get("dark") as StandardMaterial3D
	_glass = shared_palette.get("glass") as Material
	if _glass == null:
		_glass = _mat(Color(0.56, 0.7, 0.76, 0.18), 0.16, 0.05)
		(_glass as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		(_glass as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED


func _build_solid(parent: Node3D) -> void:
	var w := float(width_cells)
	_add_wall_body(parent, w)
	_add_gallery_trim(parent, w, true)


func _build_feature(parent: Node3D) -> void:
	var w := float(width_cells)
	_add_wall_body(parent, w)
	_add_gallery_trim(parent, w, false)
	# A quiet, unbroken hanging field. The thin bronze corners declare its reserve
	# without putting geometry behind the painting-like feature.
	var field_w := maxf(0.6, w - 0.42)
	var field_h := minf(2.8, height - 0.9)
	var cy := 1.85
	for sx in [-1.0, 1.0]:
		parent.add_child(_box("FeatureEdge", Vector3(sx * field_w * 0.5, cy, FRONT_Z + 0.018), Vector3(0.025, field_h, 0.018), _bronze))
	parent.set_meta("reserved_field_m", Vector2(field_w, field_h))


func _build_window(parent: Node3D) -> void:
	var w := float(width_cells)
	var jamb := 0.18
	var sill_y := 0.82
	var head_y := height - 0.35
	parent.add_child(_box("WindowApron", Vector3(0, sill_y * 0.5, 0), Vector3(w, sill_y, DEPTH), _stone))
	parent.add_child(_box("WindowHead", Vector3(0, (head_y + height) * 0.5, 0), Vector3(w, height - head_y, DEPTH), _stone_alt))
	for sx in [-1.0, 1.0]:
		parent.add_child(_box("WindowJamb", Vector3(sx * (w * 0.5 - jamb * 0.5), (sill_y + head_y) * 0.5, 0), Vector3(jamb, head_y - sill_y, DEPTH + 0.06), _stone_alt))
	parent.add_child(_box("WindowGlass", Vector3(0, (sill_y + head_y) * 0.5, 0), Vector3(w - jamb * 2.0, head_y - sill_y, 0.025), _glass))
	for seam in range(1, width_cells):
		var x := -w * 0.5 + float(seam)
		parent.add_child(_box("WindowMullion", Vector3(x, (sill_y + head_y) * 0.5, FRONT_Z), Vector3(0.045, head_y - sill_y, 0.06), _trim))
	_add_gallery_trim(parent, w, true)
	_add_full_collision(parent, w)


func _build_vitrine(parent: Node3D) -> void:
	var w := float(width_cells)
	_add_wall_body(parent, w)
	_add_gallery_trim(parent, w, true)
	var niche_w := maxf(0.55, w - 0.42)
	var niche_h := minf(2.25, height - 1.25)
	var cy := 1.75
	parent.add_child(_box("VitrineVoid", Vector3(0, cy, FRONT_Z + 0.035), Vector3(niche_w, niche_h, 0.07), _dark))
	for sx in [-1.0, 1.0]:
		parent.add_child(_box("VitrineSide", Vector3(sx * niche_w * 0.5, cy, FRONT_Z + 0.075), Vector3(0.07, niche_h + 0.14, 0.15), _bronze))
	for sy in [-1.0, 1.0]:
		parent.add_child(_box("VitrineRail", Vector3(0, cy + sy * niche_h * 0.5, FRONT_Z + 0.075), Vector3(niche_w, 0.07, 0.15), _bronze))
	parent.add_child(_box("VitrineGlass", Vector3(0, cy, FRONT_Z + 0.15), Vector3(niche_w - 0.06, niche_h - 0.06, 0.018), _glass))
	parent.add_child(_box("VitrineLight", Vector3(0, cy + niche_h * 0.42, FRONT_Z + 0.09), Vector3(niche_w * 0.84, 0.035, 0.035), _emissive(Color(1.0, 0.82, 0.55), 1.4)))
	_add_full_collision(parent, w)


func _build_service(parent: Node3D) -> void:
	var w := float(width_cells)
	_add_wall_body(parent, w)
	_add_gallery_trim(parent, w, true)
	var side := -1.0 if not flip else 1.0
	var cabinet_w := minf(0.72, w * 0.42)
	parent.add_child(_solid_box("ServiceCabinet", Vector3(side * (w * 0.5 - cabinet_w * 0.62), 1.05, FRONT_Z + 0.11), Vector3(cabinet_w, 1.15, 0.22), _trim, "painted_metal", "CollisionPaintedMetal", "PaintedMetalShape00"))
	parent.add_child(_solid_box("ServiceDoor", Vector3(side * (w * 0.5 - cabinet_w * 0.62), 1.05, FRONT_Z + 0.23), Vector3(cabinet_w - 0.08, 1.04, 0.025), _stone_alt, "painted_metal", "CollisionPaintedMetal", "PaintedMetalShape01"))
	parent.add_child(_box("ServiceMark", Vector3(side * (w * 0.5 - cabinet_w * 0.62), 1.33, FRONT_Z + 0.25), Vector3(cabinet_w * 0.52, 0.07, 0.025), _emissive(Color(0.86, 0.34, 0.11), 0.8)))
	var pipe_x := -side * (w * 0.5 - 0.28)
	parent.add_child(_solid_box("ServiceDrop", Vector3(pipe_x, 1.9, FRONT_Z + 0.12), Vector3(0.055, height - 0.55, 0.07), _bronze, "bronze", "CollisionBronze", "BronzeShape00"))
	parent.set_meta("prop_zone", "edge")


func _build_portal(parent: Node3D) -> void:
	var w := float(width_cells)
	var opening_w := maxf(1.2, w - 0.6)
	var opening_h := minf(3.0, height - 0.45)
	var pier_w := (w - opening_w) * 0.5
	for sx in [-1.0, 1.0]:
		parent.add_child(_box("PortalPier", Vector3(sx * (opening_w * 0.5 + pier_w * 0.5), height * 0.5, 0), Vector3(pier_w, height, DEPTH + 0.08), _stone_alt))
	parent.add_child(_box("PortalLintel", Vector3(0, opening_h + (height - opening_h) * 0.5, 0), Vector3(opening_w, height - opening_h, DEPTH + 0.08), _stone_alt))
	parent.add_child(_box("PortalThreshold", Vector3(0, 0.025, FRONT_Z), Vector3(opening_w, 0.05, 0.26), _bronze))
	parent.add_child(_box("PortalHeadLine", Vector3(0, opening_h - 0.04, FRONT_Z + 0.06), Vector3(opening_w, 0.06, 0.08), _bronze))
	if enable_collision:
		_add_collision(parent, "PierLeftCollision", Vector3(-opening_w * 0.5 - pier_w * 0.5, height * 0.5, 0), Vector3(pier_w, height, DEPTH))
		_add_collision(parent, "PierRightCollision", Vector3(opening_w * 0.5 + pier_w * 0.5, height * 0.5, 0), Vector3(pier_w, height, DEPTH))
		_add_collision(parent, "LintelCollision", Vector3(0, opening_h + (height - opening_h) * 0.5, 0), Vector3(opening_w, height - opening_h, DEPTH))
	parent.set_meta("opening_m", Vector2(opening_w, opening_h))


func _build_endcap(parent: Node3D) -> void:
	var w := float(width_cells)
	_add_wall_body(parent, w)
	var cap_x := (-w * 0.5 + 0.13) if not flip else (w * 0.5 - 0.13)
	parent.add_child(_solid_box("TerminalPilaster", Vector3(cap_x, height * 0.5, FRONT_Z + 0.035), Vector3(0.26, height, 0.22), _stone_alt, "stone", "CollisionStone", "StoneShape03"))
	parent.add_child(_solid_box("TerminalBronze", Vector3(cap_x, height * 0.5, FRONT_Z + 0.16), Vector3(0.055, height * 0.82, 0.035), _bronze, "bronze", "CollisionBronze", "BronzeShape00"))
	_add_gallery_trim(parent, w, false)


func _add_wall_body(parent: Node3D, w: float) -> void:
	for cell in range(width_cells):
		var x := -w * 0.5 + float(cell) + 0.5
		var wall_cell := _box("WallCell_%02d" % cell, Vector3(x, height * 0.5, 0), Vector3(1.0, height, DEPTH), _stone if cell % 2 == 0 else _stone_alt)
		if kind in ["solid", "feature", "service", "endcap"]:
			_mark_collision_mesh(wall_cell, "stone", "CollisionStone", "StoneShape00")
		parent.add_child(wall_cell)


func _add_gallery_trim(parent: Node3D, w: float, show_pilasters: bool) -> void:
	var skirting := _box("Skirting", Vector3(0, 0.14, FRONT_Z + 0.045), Vector3(w, 0.28, 0.13), _stone_alt)
	if kind in ["solid", "feature", "service", "endcap"]:
		_mark_collision_mesh(skirting, "stone", "CollisionStone", "StoneShape01")
	parent.add_child(skirting)
	var picture_rail := _box("PictureRail", Vector3(0, 2.85, FRONT_Z + 0.045), Vector3(w, 0.11, 0.1), _bronze)
	if kind == "feature":
		_mark_collision_mesh(picture_rail, "bronze", "CollisionBronze", "BronzeShape00")
	parent.add_child(picture_rail)
	var cornice := _box("Cornice", Vector3(0, height - 0.17, FRONT_Z + 0.04), Vector3(w, 0.34, 0.2), _stone_alt)
	if kind in ["solid", "feature", "service", "endcap"]:
		_mark_collision_mesh(cornice, "stone", "CollisionStone", "StoneShape02")
	parent.add_child(cornice)
	if show_pilasters:
		for sx in [-1.0, 1.0]:
			parent.add_child(_box("EdgePilaster", Vector3(sx * (w * 0.5 - 0.06), height * 0.5, FRONT_Z + 0.05), Vector3(0.12, height, 0.22), _stone_alt))


func _add_socket(parent: Node3D, socket_name: String, x: float, facing: Vector3, terminal: bool, seam_owner: bool) -> void:
	var marker := Marker3D.new()
	marker.name = socket_name
	marker.position = Vector3(x, 0, 0)
	marker.set_meta("port", "museum_wall_terminal_v1" if terminal else "museum_wall_flat_v1")
	marker.set_meta("socket_id", "museum_wall_terminal_v1" if terminal else "museum_wall_flat_v1")
	marker.set_meta("profile_id", "museum_wall_150mm_v1")
	marker.set_meta("grid_m", 1.0)
	marker.set_meta("facing", facing)
	marker.set_meta("terminal", terminal)
	marker.set_meta("seam_owner", seam_owner and not terminal)
	parent.add_child(marker)


func _add_full_collision(parent: Node3D, w: float) -> void:
	if enable_collision:
		_add_collision(parent, "WallCollision", Vector3(0, height * 0.5, 0), Vector3(w, height, DEPTH))


func _add_collision(parent: Node3D, node_name: String, at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = at
	var shape := BoxShape3D.new()
	var shape_key := "%.4f|%.4f|%.4f" % [size.x, size.y, size.z]
	if _shared_collision_shapes.has(shape_key):
		shape = _shared_collision_shapes[shape_key]
	else:
		shape.size = size
		_shared_collision_shapes[shape_key] = shape
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)


## Builds the collision truth for architectural families. One StaticBody3D owns
## each canonical PhysicsMaterial route, with shared primitive Shape3D resources
## so collision stays identical across LOD levels and repeated rebuilds.
func _build_architectural_collision_zones(parent: Node3D) -> Dictionary:
	var zones := _architectural_collision_specs()
	var body_count := 0
	var shape_count := 0
	var surfaces: Array[String] = []
	for surface_id in ["stone", "painted_metal", "bronze"]:
		var shape_specs: Array = zones.get(surface_id, [])
		if shape_specs.is_empty():
			continue
		var body := StaticBody3D.new()
		body.name = _collision_body_name(surface_id)
		_configure_collision_body(body, surface_id)
		for index in range(shape_specs.size()):
			var shape_spec: Dictionary = shape_specs[index]
			var collision := CollisionShape3D.new()
			collision.name = _collision_shape_name(surface_id, index)
			collision.position = shape_spec["position"]
			collision.shape = _shared_box_collision_shape(shape_spec["size"])
			body.add_child(collision)
			shape_count += 1
		parent.add_child(body)
		body_count += 1
		surfaces.append(surface_id)
	return {
		"owner": "MuseumWallPiece",
		"profile": "museum_surface_zones_v2",
		"family": kind,
		"body_count": body_count,
		"shape_count": shape_count,
		"surfaces": surfaces,
		"shared_shape_resources": true,
		"decorative_colliders": 0,
	}


func _architectural_collision_specs() -> Dictionary:
	var w := float(width_cells)
	var zones := {
		"stone": [
			{"position": Vector3(0, height * 0.5, 0), "size": Vector3(w, height, DEPTH)},
			{"position": Vector3(0, 0.14, FRONT_Z + 0.045), "size": Vector3(w, 0.28, 0.13)},
			{"position": Vector3(0, height - 0.17, FRONT_Z + 0.04), "size": Vector3(w, 0.34, 0.2)},
		],
		"painted_metal": [],
		"bronze": [],
	}
	match kind:
		"solid":
			zones["stone"].append({"position": Vector3(0, height * 0.5, FRONT_Z + 0.018), "size": Vector3(w - 0.014, height - 0.4, 0.034)})
		"feature":
			var field_w := maxf(0.48, w - 0.52)
			var field_h := minf(2.72, height - 1.05)
			var cy := minf(2.05, 1.02 + field_h * 0.5)
			zones["bronze"].append({"position": Vector3(0, 2.85, FRONT_Z + 0.045), "size": Vector3(w, 0.11, 0.1)})
			zones["bronze"].append({"position": Vector3(0, minf(height - 0.58, cy + field_h * 0.5 + 0.22), FRONT_Z + 0.13), "size": Vector3(field_w * 0.84, 0.075, 0.105)})
		"service":
			var side := -1.0 if not flip else 1.0
			var cabinet_w := minf(0.72, w * 0.42)
			var cabinet_x := side * (w * 0.5 - cabinet_w * 0.62)
			zones["painted_metal"].append({"position": Vector3(cabinet_x, 1.05, FRONT_Z + 0.11), "size": Vector3(cabinet_w, 1.15, 0.22)})
			zones["painted_metal"].append({"position": Vector3(cabinet_x, 1.05, FRONT_Z + 0.23), "size": Vector3(cabinet_w - 0.08, 1.04, 0.025)})
			zones["painted_metal"].append({"position": Vector3(0, height - 0.54, FRONT_Z + 0.12), "size": Vector3(w - 0.12, 0.18, 0.14)})
			var pipe_x := -side * (w * 0.5 - 0.28)
			zones["bronze"].append({"position": Vector3(pipe_x, 1.9, FRONT_Z + 0.12), "size": Vector3(0.055, height - 0.55, 0.07)})
		"endcap":
			var side := 1.0 if flip else -1.0
			var edge_x := side * (w * 0.5 - 0.105)
			var cap_x := (-w * 0.5 + 0.13) if not flip else (w * 0.5 - 0.13)
			zones["stone"].append({"position": Vector3(cap_x, height * 0.5, FRONT_Z + 0.035), "size": Vector3(0.26, height, 0.22)})
			zones["stone"].append({"position": Vector3(edge_x, height * 0.5, -0.17), "size": Vector3(0.21, height - 0.08, 0.5)})
			zones["bronze"].append({"position": Vector3(cap_x, height * 0.5, FRONT_Z + 0.16), "size": Vector3(0.055, height * 0.82, 0.035)})
			zones["bronze"].append({"position": Vector3(edge_x, 0.24, FRONT_Z + 0.12), "size": Vector3(0.2, 0.48, 0.17)})
			# A tight box proxy stays within 10.8 mm of the ten-sided guard,
			# retaining a simple, shared VR collision primitive.
			zones["bronze"].append({"position": Vector3(edge_x - side * 0.07, 0.92, FRONT_Z + 0.225), "size": Vector3(0.052, 0.82, 0.052)})
	return zones


func _configure_collision_body(body: StaticBody3D, surface_id: String) -> void:
	var surface := _physics_surface_spec(surface_id)
	body.physics_material_override = _shared_physics_material(surface_id, surface)
	body.set_meta("museum_physics_profile", "museum_surface_zones_v2")
	body.set_meta("physics_profile", "museum_surface_zones_v2")
	body.set_meta("physics_surface_id", surface_id)
	body.set_meta("surface_id", surface_id)
	body.set_meta("surface_type", surface_id)
	body.set_meta("surface_audio", surface_id)
	body.set_meta("friction", float(surface.get("friction", 0.5)))
	body.set_meta("bounce", float(surface.get("bounce", 0.0)))
	body.set_meta("impact", str(surface.get("impact", "")))
	body.set_meta("decal", str(surface.get("decal", "")))
	body.set_meta("breakability", str(surface.get("breakability", "none")))
	body.set_meta("collision_scope", "canonical_surface_zone")


func _physics_surface_spec(surface_id: String) -> Dictionary:
	if _physics_contract_cache.is_empty():
		var file := FileAccess.open(PHYSICS_CONTRACT, FileAccess.READ)
		if file != null:
			var decoded: Variant = JSON.parse_string(file.get_as_text())
			if decoded is Dictionary:
				_physics_contract_cache = decoded
	return (_physics_contract_cache.get("surfaces", {}) as Dictionary).get(surface_id, {})


func _shared_physics_material(surface_id: String, spec: Dictionary) -> PhysicsMaterial:
	if _shared_physics_materials.has(surface_id):
		return _shared_physics_materials[surface_id]
	var material := PhysicsMaterial.new()
	material.friction = float(spec.get("friction", 0.5))
	material.bounce = float(spec.get("bounce", 0.0))
	_shared_physics_materials[surface_id] = material
	return material


func _shared_box_collision_shape(size: Vector3) -> BoxShape3D:
	var shape_key := "box|%.4f|%.4f|%.4f" % [size.x, size.y, size.z]
	if _shared_collision_shapes.has(shape_key):
		return _shared_collision_shapes[shape_key]
	var shape := BoxShape3D.new()
	shape.size = size
	_shared_collision_shapes[shape_key] = shape
	return shape


func _collision_body_name(surface_id: String) -> String:
	match surface_id:
		"painted_metal": return "CollisionPaintedMetal"
		"bronze": return "CollisionBronze"
		_: return "CollisionStone"


func _collision_shape_name(surface_id: String, index: int) -> String:
	var prefix := "Stone"
	if surface_id == "bronze":
		prefix = "Bronze"
	elif surface_id == "painted_metal":
		prefix = "PaintedMetal"
	return "%sShape%02d" % [prefix, index]


func _box(node_name: String, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	if _shared_unit_box == null:
		_shared_unit_box = BoxMesh.new()
		_shared_unit_box.size = Vector3.ONE
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = at
	instance.scale = size
	instance.mesh = _shared_unit_box
	instance.material_override = material
	instance.set_meta("collision_role", "visual_only")
	instance.set_meta("physics_surface_id", "")
	instance.set_meta("collision_target", "")
	instance.set_meta("collision_shape_targets", PackedStringArray())
	return instance


func _solid_box(node_name: String, at: Vector3, size: Vector3, material: Material, surface_id: String, collision_target: String, collision_shape_target: String) -> MeshInstance3D:
	var instance := _box(node_name, at, size, material)
	_mark_collision_mesh(instance, surface_id, collision_target, collision_shape_target)
	return instance


func _mark_collision_mesh(instance: MeshInstance3D, surface_id: String, collision_target: String, collision_shape_target: String) -> void:
	instance.set_meta("collision_role", "solid")
	instance.set_meta("physics_surface_id", surface_id)
	instance.set_meta("collision_target", collision_target)
	instance.set_meta("collision_shape_targets", PackedStringArray([collision_shape_target]))


func _mat(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var key := "%s|%.3f" % [color.to_html(), energy]
	if _shared_emissive_materials.has(key):
		return _shared_emissive_materials[key]
	var material := _mat(color, 0.4, 0.05)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	_shared_emissive_materials[key] = material
	return material


func _bool(value: Variant) -> bool:
	return str(value).strip_edges().to_lower() in ["1", "true", "yes", "on"]
