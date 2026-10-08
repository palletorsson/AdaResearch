extends Node3D
class_name MuseumWallPieceIdealContext

## Capture-only ideal placement for one modular museum wall span.
##
## The subject remains the production MuseumWallPiece. This wrapper owns only the
## architectural evidence around it: one-metre floor datums, abutting wall wings,
## short returns, a ceiling reveal, controlled wall-wash lights, and restrained
## family-specific context. Nothing in this file participates in run assembly.

const WALL_PIECE_SCENE := preload("res://commons/artifacts/museum/museum_wall_piece.tscn")
const ARCH := preload("res://commons/artifacts/museum/museum_wall_architectural_spans.gd")
const OPENINGS := preload("res://commons/artifacts/museum/museum_wall_opening_spans.gd")

@export_enum("solid", "feature", "window", "vitrine", "service", "portal", "endcap")
var kind: String = "solid"
@export_range(1, 4, 1) var width_cells: int = 1
@export_range(3.0, 6.0, 0.25) var height: float = 4.0
@export var finish: String = "uffizi_stone"
@export var flip: bool = false
@export var enable_collision: bool = true
@export var quality_tier: String = "aaa"
@export var detail_seed: int = 13249
@export_range(0, 2, 1) var lod_level: int = 0
@export var enable_context_lights: bool = true

var _stone: Material
var _stone_dark: Material
var _bronze: Material
var _bronze_dark: Material
var _datum: StandardMaterial3D
var _floor_a: StandardMaterial3D
var _floor_b: StandardMaterial3D
var _shadow: StandardMaterial3D
var _ceiling: StandardMaterial3D
var _red: StandardMaterial3D
var _green_emissive: StandardMaterial3D
var _warm_emissive: StandardMaterial3D
var _blue_depth: StandardMaterial3D


func _ready() -> void:
	_build()


func _build() -> void:
	width_cells = clampi(width_cells, 1, 4)
	height = clampf(height, 3.0, 6.0)
	if kind == "portal":
		width_cells = maxi(width_cells, 2)
	_build_materials()

	var bay := Node3D.new()
	bay.name = "IdealPlacementBay"
	bay.set_meta("capture_only", true)
	bay.set_meta("context_contract", "museum_wall_ideal_context_v1")
	bay.set_meta("subject_kind", kind)
	bay.set_meta("owned_width_m", float(width_cells))
	bay.set_meta("grid_m", 1.0)
	bay.set_meta("module_unobscured", true)
	add_child(bay)

	_build_floor(bay)
	_build_shell(bay)
	_build_width_datum(bay)
	_build_role_context(bay)
	_build_subject(bay)
	if enable_context_lights:
		_build_lighting(bay)


func _build_materials() -> void:
	_stone = ARCH.create_pbr_material("stone", Color(0.78, 0.73, 0.65), Vector2(1.2, 2.4), detail_seed + 11)
	_stone_dark = ARCH.create_pbr_material("stone", Color(0.57, 0.52, 0.46), Vector2(1.15, 2.5), detail_seed + 17)
	_bronze = ARCH.create_pbr_material("bronze", Color(0.51, 0.35, 0.17), Vector2(1.4, 2.1), detail_seed + 23)
	_bronze_dark = ARCH.create_pbr_material("bronze", Color(0.26, 0.18, 0.1), Vector2(1.6, 2.2), detail_seed + 29)
	_datum = _emissive(Color(0.66, 0.39, 0.13), 0.22)
	_datum.metallic = 0.72
	_datum.roughness = 0.38
	_floor_a = _mat(Color(0.225, 0.235, 0.244), 0.72, 0.02)
	_floor_b = _mat(Color(0.285, 0.295, 0.302), 0.65, 0.025)
	_floor_a.emission_enabled = true
	_floor_a.emission = Color(0.225, 0.235, 0.244)
	_floor_a.emission_energy_multiplier = 0.18
	_floor_b.emission_enabled = true
	_floor_b.emission = Color(0.285, 0.295, 0.302)
	_floor_b.emission_energy_multiplier = 0.15
	_shadow = _mat(Color(0.034, 0.036, 0.04), 0.86, 0.06)
	_ceiling = _mat(Color(0.3, 0.295, 0.282), 0.82, 0.0)
	_red = _mat(Color(0.56, 0.025, 0.014), 0.32, 0.28)
	_green_emissive = _emissive(Color(0.24, 0.95, 0.57), 3.2)
	_warm_emissive = _emissive(Color(1.0, 0.68, 0.32), 2.1)
	_blue_depth = _mat(Color(0.055, 0.09, 0.13), 0.45, 0.08)


func _build_subject(parent: Node3D) -> void:
	var subject: Node3D = WALL_PIECE_SCENE.instantiate()
	subject.name = "Subject_MuseumWallPiece_%s_%dm" % [kind.capitalize(), width_cells]
	subject.set("kind", kind)
	subject.set("width_cells", width_cells)
	subject.set("height", height)
	subject.set("finish", finish)
	subject.set("flip", flip)
	subject.set("enable_collision", enable_collision)
	subject.set("quality_tier", quality_tier)
	subject.set("detail_seed", detail_seed)
	subject.set("lod_level", lod_level)
	subject.set_meta("ideal_context_subject", true)
	parent.add_child(subject)


func _build_floor(parent: Node3D) -> void:
	var floor := Node3D.new()
	floor.name = "Floor_OneMetreGrid"
	parent.add_child(floor)
	var first_x := -float(width_cells) * 0.5 - 2.0
	for x_index in range(width_cells + 4):
		for z_index in range(4):
			var centre := Vector3(first_x + float(x_index) + 0.5, -0.018, 0.5 + float(z_index))
			var material: Material = _floor_a if (x_index + z_index) % 2 == 0 else _floor_b
			floor.add_child(_box("FloorTile_%02d_%02d" % [x_index, z_index], centre, Vector3(0.982, 0.036, 0.982), material, 0.006))
	# The dark under-slab closes tiny grout gaps and gives contact shadows a stable base.
	floor.add_child(_box("FloorUnderSlab", Vector3(0, -0.043, 2.0), Vector3(float(width_cells) + 4.0, 0.05, 4.0), _shadow, 0.008))
	for x_index in range(width_cells + 5):
		var grout_x := first_x + float(x_index)
		floor.add_child(_box("LongGrout_%02d" % x_index, Vector3(grout_x, 0.005, 2.0), Vector3(0.012, 0.012, 3.96), _shadow, 0.002))
	for z_index in range(5):
		floor.add_child(_box("CrossGrout_%02d" % z_index, Vector3(0, 0.005, float(z_index)), Vector3(float(width_cells) + 3.98, 0.012, 0.012), _shadow, 0.002))


func _build_shell(parent: Node3D) -> void:
	var shell := Node3D.new()
	shell.name = "ArchitecturalBayShell"
	parent.add_child(shell)
	var w := float(width_cells)
	var terminal_left := kind == "endcap" and not flip
	var terminal_right := kind == "endcap" and flip
	if not terminal_left:
		_build_abutment(shell, -1.0)
	if not terminal_right:
		_build_abutment(shell, 1.0)

	# A shallow soffit and black reveal imply the rest of the ceiling without turning
	# the capture into a room-wide establishing shot.
	shell.add_child(_box("CeilingShadowReveal", Vector3(0, height + 0.075, 0.31), Vector3(w + 1.12, 0.07, 0.78), _shadow, 0.012))
	shell.add_child(_box("CeilingSoffit", Vector3(0, height + 0.18, 0.45), Vector3(w + 1.08, 0.14, 1.02), _ceiling, 0.018))
	shell.add_child(_box("LightingTrack", Vector3(0, height + 0.055, 0.82), Vector3(w + 0.42, 0.045, 0.055), _bronze_dark, 0.009))
	# This shadow line belongs to the placement bay, not to the module. It makes the
	# contact plane legible while leaving the production skirting untouched.
	shell.add_child(_box("WallFloorContact", Vector3(0, 0.018, -0.097), Vector3(w + 1.0, 0.036, 0.045), _shadow, 0.006))


func _build_abutment(parent: Node3D, side: float) -> void:
	var w := float(width_cells)
	var side_name := "Left" if side < 0.0 else "Right"
	var wing_x := side * (w * 0.5 + 0.25)
	parent.add_child(_box("%sAbuttingWall" % side_name, Vector3(wing_x, height * 0.5, 0), Vector3(0.5, height, 0.15), _stone_dark, 0.014))
	# Boundary reveal is wholly outside the owned span: it proves the join without
	# hiding or artificially improving the wall piece's terminal edge.
	parent.add_child(_box("%sOwnershipReveal" % side_name, Vector3(side * (w * 0.5 + 0.012), height * 0.5, 0.091), Vector3(0.018, height - 0.18, 0.025), _shadow, 0.004))
	parent.add_child(_box("%sReturnWall" % side_name, Vector3(side * (w * 0.5 + 0.46), height * 0.5, 0.43), Vector3(0.16, height, 0.96), _stone_dark, 0.014))
	parent.add_child(_box("%sReturnSkirting" % side_name, Vector3(side * (w * 0.5 + 0.365), 0.14, 0.43), Vector3(0.05, 0.27, 0.92), _bronze_dark, 0.007))


func _build_width_datum(parent: Node3D) -> void:
	var datum := Node3D.new()
	datum.name = "OwnedWidthDatum_OneMetre"
	datum.set_meta("segment_count", width_cells)
	datum.set_meta("segment_length_m", 1.0)
	datum.set_meta("owned_width_m", float(width_cells))
	parent.add_child(datum)
	var w := float(width_cells)
	var datum_z := 2.08
	for cell in range(width_cells):
		var x := -w * 0.5 + float(cell) + 0.5
		var material: Material = _datum if cell % 2 == 0 else _bronze
		datum.add_child(_box("OneMetreSegment_%02d" % cell, Vector3(x, 0.018, datum_z), Vector3(0.965, 0.025, 0.038), material, 0.006))
	for tick in range(width_cells + 1):
		var x := -w * 0.5 + float(tick)
		var endpoint := tick == 0 or tick == width_cells
		datum.add_child(_box("MetreTick_%02d" % tick, Vector3(x, 0.026, datum_z), Vector3(0.028 if endpoint else 0.018, 0.045, 0.24 if endpoint else 0.16), _datum, 0.005))
		# Boundary pins tie the ruler to the wall face without drawing over it.
		if endpoint:
			datum.add_child(_cylinder("BoundaryPin_%02d" % tick, Vector3(x, 0.036, 0.32), 0.045, 0.07, _datum, 20))

	# A separate one-metre vertical witness gives human-scale intuition even on the
	# one-cell module, where the horizontal datum is visually short.
	var gauge_x := w * 0.5 + 0.35
	datum.add_child(_box("VerticalOneMetreGauge", Vector3(gauge_x, 0.56, 0.49), Vector3(0.035, 1.0, 0.035), _datum, 0.006))
	for quarter in range(5):
		datum.add_child(_box("QuarterMetreTick_%02d" % quarter, Vector3(gauge_x - 0.06, 0.06 + float(quarter) * 0.25, 0.49), Vector3(0.13 if quarter in [0, 4] else 0.09, 0.018, 0.025), _datum, 0.004))


func _build_role_context(parent: Node3D) -> void:
	var context := Node3D.new()
	context.name = "RoleContext_%s" % kind.capitalize()
	context.set_meta("context_is_non_contract_geometry", true)
	parent.add_child(context)
	match kind:
		"feature": _build_feature_context(context)
		"window": _build_window_context(context)
		"vitrine": _build_vitrine_context(context)
		"service": _build_service_context(context)
		"portal": _build_portal_context(context)
		"endcap": _build_endcap_context(context)
		_: _build_solid_context(context)


func _build_solid_context(parent: Node3D) -> void:
	# The uninterrupted wall remains the hero. A slim conservation sensor on the
	# abutting wing is enough to establish a functioning museum without dressing it.
	var x := float(width_cells) * 0.5 + 0.29
	parent.add_child(_box("ConservationSensor", Vector3(x, 2.25, 0.19), Vector3(0.13, 0.22, 0.08), _shadow, 0.014))
	parent.add_child(_cylinder("SensorLens", Vector3(x, 2.25, 0.238), 0.026, 0.018, _warm_emissive, 18, Vector3(90, 0, 0)))


func _build_feature_context(parent: Node3D) -> void:
	var w := float(width_cells)
	# Nothing occupies the hanging field. The U-shaped floor inlay is a readable
	# viewing distance and a promise that the centre stays reserved for the work.
	var zone_w := maxf(0.72, w - 0.28)
	parent.add_child(_box("ReservedViewingLine", Vector3(0, 0.022, 1.34), Vector3(zone_w, 0.018, 0.028), _bronze, 0.005))
	for side in [-1.0, 1.0]:
		parent.add_child(_box("ReservedViewingReturn", Vector3(side * zone_w * 0.5, 0.022, 1.08), Vector3(0.028, 0.018, 0.52), _bronze_dark, 0.005))
	parent.set_meta("feature_field_left_empty", true)
	parent.set_meta("ideal_viewing_distance_m", 1.34)


func _build_window_context(parent: Node3D) -> void:
	var w := float(width_cells)
	# A cool, recessed architectural layer gives the glass parallax and transmission
	# evidence. It is behind the wall and never touches the aperture assembly.
	parent.add_child(_box("WindowDepthWall", Vector3(0, 2.0, -1.12), Vector3(maxf(1.2, w - 0.48), 3.55, 0.1), _blue_depth, 0.015))
	for index in range(width_cells):
		var x := -w * 0.5 + 0.5 + float(index)
		parent.add_child(_box("WindowDepthPier_%02d" % index, Vector3(x, 1.65, -1.03), Vector3(0.12, 2.65, 0.08), _bronze_dark, 0.012))
	parent.add_child(_box("WindowFarLight", Vector3(0, 3.27, -1.045), Vector3(maxf(0.8, w - 0.62), 0.045, 0.022), _warm_emissive, 0.007))
	parent.set_meta("depth_context_m", 1.12)


func _build_vitrine_context(parent: Node3D) -> void:
	var w := float(width_cells)
	var zone_w := maxf(1.0, w - 0.38)
	# The floor zone states where a visitor can inspect the case while leaving a
	# clean circulation lane behind it.
	parent.add_child(_box("VitrineViewingFront", Vector3(0, 0.024, 1.28), Vector3(zone_w, 0.02, 0.035), _bronze, 0.006))
	for side in [-1.0, 1.0]:
		parent.add_child(_box("VitrineViewingSide", Vector3(side * zone_w * 0.5, 0.024, 0.87), Vector3(0.035, 0.02, 0.82), _bronze_dark, 0.006))
		parent.add_child(_cylinder("VitrineFloorMarker", Vector3(side * zone_w * 0.36, 0.026, 1.48), 0.055, 0.018, _bronze, 24))
	parent.set_meta("viewing_zone_depth_m", 1.28)


func _build_service_context(parent: Node3D) -> void:
	var w := float(width_cells)
	var side := -1.0 if not flip else 1.0
	var x := side * (w * 0.5 + 0.3)
	# Safety equipment stays on the peripheral abutment, outside the module's owned
	# width and away from any feature field.
	parent.add_child(_box("ExtinguisherRecess", Vector3(x, 0.74, 0.2), Vector3(0.34, 0.82, 0.09), _shadow, 0.018))
	parent.add_child(_cylinder("FireExtinguisher", Vector3(x, 0.63, 0.3), 0.105, 0.54, _red, 28))
	parent.add_child(_box("ExtinguisherNeck", Vector3(x, 0.94, 0.3), Vector3(0.09, 0.13, 0.08), _bronze_dark, 0.012))
	parent.add_child(_torus("ExtinguisherHose", Vector3(x - side * 0.12, 0.76, 0.31), 0.075, 0.012, _shadow))
	var sign_x := -side * (w * 0.5 + 0.28)
	parent.add_child(_box("ExitSignHousing", Vector3(sign_x, 3.42, 0.2), Vector3(0.42, 0.2, 0.085), _shadow, 0.014))
	parent.add_child(_box("ExitSignFace", Vector3(sign_x, 3.42, 0.249), Vector3(0.33, 0.11, 0.02), _green_emissive, 0.004))
	parent.set_meta("safety_prop_zone", "peripheral_outside_owned_span")


func _build_portal_context(parent: Node3D) -> void:
	var w := float(width_cells)
	var corridor_w := maxf(1.15, w - 0.72)
	# The open span now demonstrably leads somewhere: two one-metre floor cells,
	# wall returns, a back reveal, and a low-glare route light remain visible through it.
	for z_index in range(2):
		var material: Material = _floor_b if z_index % 2 == 0 else _floor_a
		parent.add_child(_box("CorridorFloor_%02d" % z_index, Vector3(0, -0.045, -0.5 - float(z_index)), Vector3(corridor_w, 0.09, 0.98), material, 0.006))
	parent.add_child(_box("CorridorBackWall", Vector3(0, 1.65, -2.02), Vector3(corridor_w, 3.3, 0.1), _blue_depth, 0.014))
	for side in [-1.0, 1.0]:
		parent.add_child(_box("CorridorReveal", Vector3(side * corridor_w * 0.5, 1.65, -1.0), Vector3(0.08, 3.3, 2.0), _stone_dark, 0.012))
	parent.add_child(_box("CorridorLight", Vector3(0, 2.96, -1.55), Vector3(corridor_w * 0.54, 0.035, 0.08), _green_emissive, 0.007))
	parent.add_child(_box("CorridorWayfinding", Vector3(0, 2.25, -1.955), Vector3(minf(0.62, corridor_w * 0.62), 0.19, 0.025), _green_emissive, 0.006))
	parent.set_meta("corridor_continuation_m", 2.0)


func _build_endcap_context(parent: Node3D) -> void:
	var w := float(width_cells)
	var terminal_side := -1.0 if not flip else 1.0
	var terminal_x := terminal_side * w * 0.5
	# A floor line turns away from the wall at the declared terminal socket. The open
	# side remains empty, so the cap reads as an end rather than another internal join.
	parent.add_child(_box("TerminalFloorTrace", Vector3(terminal_x, 0.02, 1.33), Vector3(0.032, 0.02, 2.62), _bronze, 0.006))
	parent.add_child(_cylinder("TerminalDatum", Vector3(terminal_x, 0.045, 2.52), 0.075, 0.035, _bronze, 24))
	parent.set_meta("open_terminal_side", "left" if terminal_side < 0.0 else "right")


func _build_lighting(parent: Node3D) -> void:
	var rig := Node3D.new()
	rig.name = "ControlledGrazingLightRig"
	rig.set_meta("light_count", 2)
	rig.set_meta("lighting_intent", "grazing_edge_and_contact_proof")
	parent.add_child(rig)
	var w := float(width_cells)

	var key := SpotLight3D.new()
	key.name = "WarmWallWash"
	key.position = Vector3(-w * 0.5 - 0.52, height - 0.34, 2.15)
	key.light_color = Color(1.0, 0.79, 0.61)
	key.light_energy = 3.2
	key.spot_range = 6.2
	key.spot_angle = 37.0
	key.shadow_enabled = true
	key.shadow_bias = 0.04
	rig.add_child(key)
	key.look_at(Vector3(0, height * 0.52, 0.08), Vector3.UP)

	var fill := SpotLight3D.new()
	fill.name = "CoolRakingFill"
	fill.position = Vector3(w * 0.5 + 0.3, height * 0.68, 1.65)
	fill.light_color = Color(0.55, 0.69, 0.93)
	fill.light_energy = 1.2
	fill.spot_range = 5.0
	fill.spot_angle = 43.0
	fill.shadow_enabled = false
	rig.add_child(fill)
	fill.look_at(Vector3(0, height * 0.42, 0.08), Vector3.UP)


func _box(node_name: String, at: Vector3, size: Vector3, material: Material, bevel: float = 0.0) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = at
	instance.mesh = OPENINGS._shared_chamfer_mesh(size, maxf(0.0005, bevel))
	instance.material_override = material
	instance.set_meta("capture_context", true)
	return instance


func _cylinder(node_name: String, at: Vector3, radius: float, cylinder_height: float, material: Material, segments: int = 24, rotation_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = cylinder_height
	mesh.radial_segments = segments
	mesh.rings = 2
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = at
	instance.rotation_degrees = rotation_deg
	instance.mesh = mesh
	instance.material_override = material
	instance.set_meta("capture_context", true)
	return instance


func _torus(node_name: String, at: Vector3, radius: float, tube_radius: float, material: Material) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = maxf(0.001, radius - tube_radius)
	mesh.outer_radius = radius + tube_radius
	mesh.rings = 24
	mesh.ring_segments = 10
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = at
	instance.mesh = mesh
	instance.material_override = material
	instance.set_meta("capture_context", true)
	return instance


func _mat(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var material := _mat(color, 0.3, 0.05)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
