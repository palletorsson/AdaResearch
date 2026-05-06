extends Node3D

## Equipment Assembly Puzzle - Level 2 Compositional Assembly
##
## Combines assembled equipment (microscope, scales, etc.) into workstations.
## Each workstation requires specific equipment types placed in designated slots.
## Equipment is sourced from the EquipmentRegistry (built by assembly_line_puzzle).
##
## This is the second level of the compositional assembly hierarchy:
## Level 1: Primitives â†’ Equipment (assembly_line_puzzle)
## Level 2: Equipment â†’ Workstations (this puzzle)
## Level 3: Workstations â†’ Labs (future)

signal equipment_placed(equipment_type: String, slot_index: int)
signal workstation_completed(workstation_type: String)
signal workstation_ready(workstation: Node3D)

enum WorkstationType {
	ANALYSIS_STATION,      # microscope + scales + specimen_jar
	MEASUREMENT_STATION,   # multimeter + scales
	STORAGE_STATION,       # specimen_jar + specimen_jar + specimen_jar
	DIAGNOSTIC_STATION     # microscope + multimeter
}

# Workstation definition - what equipment is needed and where
class WorkstationDef:
	var required_equipment: Array[String] = []  # Equipment types needed
	var slot_offsets: Array[Vector3] = []       # Where each piece goes
	var slot_rotations: Array[float] = []       # Y rotation for each slot (degrees)
	var name: String = ""
	var output_type: String = ""

	func _init(equipment: Array[String], offsets: Array[Vector3], rotations: Array[float], station_name: String, output: String):
		for e in equipment:
			required_equipment.append(e)
		for o in offsets:
			slot_offsets.append(o)
		for r in rotations:
			slot_rotations.append(r)
		name = station_name
		output_type = output

@export var workstation_type: WorkstationType = WorkstationType.ANALYSIS_STATION

## Single workstation filter - if set, only build this specific workstation
var _single_workstation_filter: String = ""

@export_group("Assembly Platform")
@export var platform_position: Vector3 = Vector3(0, 0.5, 0)
@export var platform_size: Vector3 = Vector3(1.0, 0.05, 0.8)
@export var platform_color: Color = Color(0.3, 0.35, 0.4)

@export_group("Ghost System")
@export var ghost_color: Color = Color(0.3, 0.8, 1.0, 0.35)
@export var ghost_pulse_speed: float = 2.0
@export var slot_match_distance: float = 0.2
@export var snap_duration: float = 0.3

@export_group("Labels")
@export var show_labels: bool = true
@export var label_height: float = 0.4

# Workstation sequence
var _workstation_sequence: Array[WorkstationDef] = []
var _current_workstation_index: int = 0

# Ghost and slots
var _ghost_container: Node3D
var _ghost_meshes: Array[MeshInstance3D] = []
var _slot_labels: Array[Label3D] = []
var _slot_filled: Array[bool] = []
var _slot_equipment: Array[Node3D] = []

# Platform
var _platform_mesh: MeshInstance3D

# Score
var _workstations_completed: int = 0

# Label
var _main_label: Label3D

func _ready() -> void:
	_setup_workstation_sequence()
	_create_assembly_platform()
	_setup_current_workstation_ghost()
	_create_main_label()

func _process(_delta: float) -> void:
	_check_equipment_placement()
	_update_ghost_pulse(_delta)

func _setup_workstation_sequence() -> void:
	match workstation_type:
		WorkstationType.ANALYSIS_STATION:
			_setup_analysis_station()
		WorkstationType.MEASUREMENT_STATION:
			_setup_measurement_station()
		WorkstationType.STORAGE_STATION:
			_setup_storage_station()
		WorkstationType.DIAGNOSTIC_STATION:
			_setup_diagnostic_station()

func _setup_analysis_station() -> void:
	var filter = _single_workstation_filter.to_lower()

	if filter == "" or filter == "analysis" or filter == "analysis_station":
		var ws = WorkstationDef.new(
			["microscope", "electronicscales", "specimen_jar"],
			[Vector3(0, 0.1, 0), Vector3(0.35, 0.05, 0), Vector3(-0.25, 0.08, 0.1)],
			[0.0, 0.0, 0.0],
			"Analysis Station",
			"analysis_workstation"
		)
		_workstation_sequence.append(ws)

func _setup_measurement_station() -> void:
	var filter = _single_workstation_filter.to_lower()

	if filter == "" or filter == "measurement" or filter == "measurement_station":
		var ws = WorkstationDef.new(
			["multimeter", "electronicscales"],
			[Vector3(0, 0.1, 0), Vector3(0.3, 0.05, 0)],
			[0.0, 0.0],
			"Measurement Station",
			"measurement_workstation"
		)
		_workstation_sequence.append(ws)

func _setup_storage_station() -> void:
	var filter = _single_workstation_filter.to_lower()

	if filter == "" or filter == "storage" or filter == "storage_station":
		var ws = WorkstationDef.new(
			["specimen_jar", "specimen_jar", "specimen_jar"],
			[Vector3(-0.2, 0.08, 0), Vector3(0, 0.08, 0), Vector3(0.2, 0.08, 0)],
			[0.0, 0.0, 0.0],
			"Storage Station",
			"storage_workstation"
		)
		_workstation_sequence.append(ws)

func _setup_diagnostic_station() -> void:
	var filter = _single_workstation_filter.to_lower()

	if filter == "" or filter == "diagnostic" or filter == "diagnostic_station":
		var ws = WorkstationDef.new(
			["microscope", "multimeter"],
			[Vector3(-0.15, 0.1, 0), Vector3(0.15, 0.08, 0)],
			[0.0, 0.0],
			"Diagnostic Station",
			"diagnostic_workstation"
		)
		_workstation_sequence.append(ws)

func _create_assembly_platform() -> void:
	_platform_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = platform_size
	_platform_mesh.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = platform_color
	mat.metallic = 0.3
	mat.roughness = 0.7
	_platform_mesh.material_override = mat

	_platform_mesh.position = platform_position
	add_child(_platform_mesh)

	# Add edge trim
	_create_platform_trim()

func _create_platform_trim() -> void:
	var trim_color = Color(0.5, 0.55, 0.6)
	var trim_height = 0.02

	# Four edges
	var edges = [
		Vector3(0, platform_size.y / 2 + trim_height / 2, platform_size.z / 2),  # Front
		Vector3(0, platform_size.y / 2 + trim_height / 2, -platform_size.z / 2), # Back
		Vector3(platform_size.x / 2, platform_size.y / 2 + trim_height / 2, 0),  # Right
		Vector3(-platform_size.x / 2, platform_size.y / 2 + trim_height / 2, 0)  # Left
	]
	var sizes = [
		Vector3(platform_size.x, trim_height, 0.02),
		Vector3(platform_size.x, trim_height, 0.02),
		Vector3(0.02, trim_height, platform_size.z),
		Vector3(0.02, trim_height, platform_size.z)
	]

	for i in edges.size():
		var trim = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = sizes[i]
		trim.mesh = box

		var mat = StandardMaterial3D.new()
		mat.albedo_color = trim_color
		mat.metallic = 0.5
		mat.roughness = 0.4
		trim.material_override = mat

		trim.position = edges[i]
		_platform_mesh.add_child(trim)

func _setup_current_workstation_ghost() -> void:
	# Clear previous ghost
	if _ghost_container:
		_ghost_container.queue_free()
	_ghost_meshes.clear()
	_slot_labels.clear()
	_slot_filled.clear()
	_slot_equipment.clear()

	if _workstation_sequence.is_empty():
		return

	var ws = _workstation_sequence[_current_workstation_index]

	_ghost_container = Node3D.new()
	_ghost_container.name = "GhostContainer"
	_ghost_container.position = platform_position + Vector3(0, platform_size.y / 2, 0)
	add_child(_ghost_container)

	# Create ghost for each required equipment
	for i in ws.required_equipment.size():
		var eq_type = ws.required_equipment[i]
		var offset = ws.slot_offsets[i] if i < ws.slot_offsets.size() else Vector3.ZERO
		var rotation = ws.slot_rotations[i] if i < ws.slot_rotations.size() else 0.0

		var ghost = _create_equipment_ghost(eq_type)
		ghost.position = offset
		ghost.rotation_degrees.y = rotation
		_ghost_container.add_child(ghost)
		_ghost_meshes.append(ghost)

		# Create slot label
		if show_labels:
			var label = Label3D.new()
			label.text = eq_type.capitalize()
			label.font_size = 24
			label.position = offset + Vector3(0, label_height, 0)
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.modulate = Color(0.8, 0.9, 1.0, 0.8)
			_ghost_container.add_child(label)
			_slot_labels.append(label)

		_slot_filled.append(false)
		_slot_equipment.append(null)

func _create_equipment_ghost(equipment_type: String) -> MeshInstance3D:
	var ghost = MeshInstance3D.new()

	# Create appropriate ghost mesh based on equipment type
	match equipment_type.to_lower():
		"microscope":
			ghost.mesh = _create_microscope_ghost_mesh()
		"electronicscales", "scales":
			ghost.mesh = _create_scales_ghost_mesh()
		"multimeter":
			ghost.mesh = _create_multimeter_ghost_mesh()
		"specimen_jar", "jar":
			ghost.mesh = _create_jar_ghost_mesh()
		_:
			# Default: simple box
			var box = BoxMesh.new()
			box.size = Vector3(0.15, 0.2, 0.15)
			ghost.mesh = box

	# Ghost material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = ghost_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ghost.material_override = mat

	return ghost

func _create_microscope_ghost_mesh() -> Mesh:
	# Simplified microscope silhouette
	var box = BoxMesh.new()
	box.size = Vector3(0.12, 0.25, 0.1)
	return box

func _create_scales_ghost_mesh() -> Mesh:
	# Simplified scales silhouette
	var box = BoxMesh.new()
	box.size = Vector3(0.15, 0.08, 0.12)
	return box

func _create_multimeter_ghost_mesh() -> Mesh:
	# Simplified multimeter silhouette
	var box = BoxMesh.new()
	box.size = Vector3(0.08, 0.15, 0.03)
	return box

func _create_jar_ghost_mesh() -> Mesh:
	# Simplified jar silhouette
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.04
	cylinder.bottom_radius = 0.04
	cylinder.height = 0.12
	return cylinder

func _check_equipment_placement() -> void:
	if _workstation_sequence.is_empty():
		return

	var ws = _workstation_sequence[_current_workstation_index]

	# Find all registered equipment in the scene
	var registered_equipment = get_tree().get_nodes_in_group("registered_equipment")

	for equipment in registered_equipment:
		if not is_instance_valid(equipment):
			continue

		var eq_type = equipment.get_meta("equipment_type", "")
		var eq_id = equipment.get_meta("equipment_id", "")

		# Check if this equipment is already placed in a slot
		if _slot_equipment.has(equipment):
			continue

		# Check if equipment is available in registry
		if EquipmentRegistry and not _is_equipment_available(eq_id):
			continue

		# Check each unfilled slot
		for i in ws.required_equipment.size():
			if _slot_filled[i]:
				continue

			var required_type = ws.required_equipment[i]

			# Check if equipment type matches
			if not _equipment_type_matches(eq_type, required_type):
				continue

			# Check distance to slot
			var slot_world_pos = _ghost_container.global_position + ws.slot_offsets[i]
			var distance = equipment.global_position.distance_to(slot_world_pos)

			if distance < slot_match_distance:
				_snap_equipment_to_slot(equipment, i)
				break

func _equipment_type_matches(actual: String, required: String) -> bool:
	actual = actual.to_lower()
	required = required.to_lower()

	if actual == required:
		return true

	# Handle aliases
	match required:
		"electronicscales":
			return actual in ["electronicscales", "scales", "electronic_scales"]
		"scales":
			return actual in ["electronicscales", "scales", "electronic_scales"]
		"specimen_jar":
			return actual in ["specimen_jar", "jar", "specimenjar"]
		"jar":
			return actual in ["specimen_jar", "jar", "specimenjar"]

	return false

func _is_equipment_available(eq_id: String) -> bool:
	if not EquipmentRegistry:
		return true  # If no registry, assume available

	var info = EquipmentRegistry.get_info(eq_id)
	return info.get("available", false)

func _snap_equipment_to_slot(equipment: Node3D, slot_index: int) -> void:
	var ws = _workstation_sequence[_current_workstation_index]
	var slot_world_pos = _ghost_container.global_position + ws.slot_offsets[slot_index]
	var slot_rotation = ws.slot_rotations[slot_index] if slot_index < ws.slot_rotations.size() else 0.0

	# Mark slot as filled
	_slot_filled[slot_index] = true
	_slot_equipment[slot_index] = equipment

	# Consume from registry
	var eq_id = equipment.get_meta("equipment_id", "")
	if EquipmentRegistry and eq_id != "":
		EquipmentRegistry.consume(eq_id)

	# Disable pickable behavior during snap
	if equipment.has_method("set_pickable"):
		equipment.set_pickable(false)

	# Animate snap
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(equipment, "global_position", slot_world_pos, snap_duration)
	tween.tween_property(equipment, "rotation_degrees:y", slot_rotation, snap_duration)
	tween.tween_callback(_on_equipment_snapped.bind(equipment, slot_index))

	# Hide ghost for this slot
	if slot_index < _ghost_meshes.size():
		_ghost_meshes[slot_index].visible = false

	# Update label
	if show_labels and slot_index < _slot_labels.size():
		_slot_labels[slot_index].modulate = Color(0.3, 1.0, 0.5, 0.9)
		_slot_labels[slot_index].text = ws.required_equipment[slot_index].capitalize() + " [OK]"

	equipment_placed.emit(ws.required_equipment[slot_index], slot_index)

func _on_equipment_snapped(_equipment: Node3D, slot_index: int) -> void:
	# Check if all slots are filled
	var all_filled = true
	for filled in _slot_filled:
		if not filled:
			all_filled = false
			break

	if all_filled:
		_on_workstation_complete()

func _on_workstation_complete() -> void:
	var ws = _workstation_sequence[_current_workstation_index]

	print("Equipment Assembly: Workstation complete - %s" % ws.name)

	# Create workstation container
	var workstation = Node3D.new()
	workstation.name = ws.output_type

	# Reparent all equipment to workstation
	for equipment in _slot_equipment:
		if is_instance_valid(equipment):
			var world_pos = equipment.global_position
			var world_rot = equipment.global_rotation
			equipment.reparent(workstation)
			equipment.global_position = world_pos
			equipment.global_rotation = world_rot

	# Position workstation
	workstation.global_position = _ghost_container.global_position
	get_parent().add_child(workstation)

	# Register as higher-level artifact
	var ws_id = "ws_%s_%d" % [ws.output_type, Time.get_ticks_msec()]
	if EquipmentRegistry:
		EquipmentRegistry.register(ws_id, workstation, ws.output_type, {
			"source": "equipment_assembly",
			"workstation_type": WorkstationType.keys()[workstation_type],
			"components": ws.required_equipment.duplicate()
		})

	_workstations_completed += 1
	workstation_completed.emit(ws.output_type)
	workstation_ready.emit(workstation)

	# Update label
	_update_main_label()

	# Setup next workstation (endless mode)
	_current_workstation_index = (_current_workstation_index + 1) % _workstation_sequence.size()
	_setup_current_workstation_ghost()

func _update_ghost_pulse(_delta: float) -> void:
	if _ghost_meshes.is_empty():
		return

	var pulse = (sin(Time.get_ticks_msec() * 0.001 * ghost_pulse_speed) + 1.0) * 0.5
	var alpha = lerp(0.2, 0.5, pulse)

	for i in _ghost_meshes.size():
		if _slot_filled[i]:
			continue

		var ghost = _ghost_meshes[i]
		if is_instance_valid(ghost) and ghost.material_override:
			ghost.material_override.albedo_color.a = alpha

func _create_main_label() -> void:
	if not show_labels:
		return

	_main_label = Label3D.new()
	_main_label.font_size = 32
	_main_label.position = platform_position + Vector3(0, 0.6, -platform_size.z / 2 - 0.1)
	_main_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_main_label.modulate = Color(1.0, 1.0, 1.0, 0.9)
	add_child(_main_label)

	_update_main_label()

func _update_main_label() -> void:
	if not _main_label or _workstation_sequence.is_empty():
		return

	var ws = _workstation_sequence[_current_workstation_index]
	_main_label.text = "%s | Built: %d" % [ws.name, _workstations_completed]


## Apply configuration from grid system
func apply_grid_config(config_data: Dictionary) -> void:
	for key in config_data:
		var val = config_data[key]

		# Check for shorthand (just the key, no value)
		var is_shorthand = val == null or (val is bool and val == true) or (val is String and val == "")

		match key:
			# Workstation type shortcuts
			"analysis", "analysis_station":
				workstation_type = WorkstationType.ANALYSIS_STATION
				if is_shorthand:
					_single_workstation_filter = "analysis"
			"measurement", "measurement_station":
				workstation_type = WorkstationType.MEASUREMENT_STATION
				if is_shorthand:
					_single_workstation_filter = "measurement"
			"storage", "storage_station":
				workstation_type = WorkstationType.STORAGE_STATION
				if is_shorthand:
					_single_workstation_filter = "storage"
			"diagnostic", "diagnostic_station":
				workstation_type = WorkstationType.DIAGNOSTIC_STATION
				if is_shorthand:
					_single_workstation_filter = "diagnostic"

			# Generic workstation filter
			"workstation_type":
				if val is String:
					_single_workstation_filter = val

			# Visual options
			"ghost_color":
				if val is Color:
					ghost_color = val
			"show_labels":
				if val is bool:
					show_labels = val
			"slot_distance":
				if val is float or val is int:
					slot_match_distance = float(val)

	# Re-setup if configuration changed
	_setup_workstation_sequence()
	_setup_current_workstation_ghost()
	_update_main_label()


## Debug: Show available equipment in registry
func debug_show_available() -> void:
	if not EquipmentRegistry:
		print("EquipmentRegistry not available")
		return

	print("=== Available Equipment ===")
	var ws = _workstation_sequence[_current_workstation_index] if not _workstation_sequence.is_empty() else null

	if ws:
		print("Required for %s:" % ws.name)
		for eq_type in ws.required_equipment:
			var available = EquipmentRegistry.get_available(eq_type)
			print("  %s: %d available" % [eq_type, available.size()])

	EquipmentRegistry.debug_print()
