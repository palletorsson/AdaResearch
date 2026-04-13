extends Node3D
class_name EurorackRack

## Eurorack-style modular synthesizer rack frame.
## Holds EurorackModule panels in HP-based horizontal slots across one or more rows.
## Creates chrome rails, side panels, and positions modules left-to-right.

const HP_METERS: float = 0.018
const ROW_HEIGHT: float = 0.450
const RAIL_HEIGHT: float = 0.014
const RAIL_DEPTH: float = 0.022
const SIDE_PANEL_WIDTH: float = 0.014
const SIDE_PANEL_DEPTH: float = 0.024
const ROW_GAP: float = 0.006       # Small gap between rows
const MODULE_GAP_HP: float = 0.0   # No gap between modules (Eurorack standard)

const EurorackModuleScript = preload("res://commons/audio/EurorackModule.gd")

var modules: Array = []  # Array of EurorackModule instances
var row_count: int = 1
var row_hp_totals: Array = []  # HP used per row
var _uvac: Node3D = null  # Reference to UVAC for control creation
var _rails: Array = []
var _side_panels: Array = []
var cable_manager: SynthCableManager = null  # Public: UVAC reads this for routing
const CABLE_TRAY_DEPTH: float = 0.05
const CABLE_TRAY_HEIGHT: float = 0.02
const CABLE_POOL_SIZE: int = 6

# Materials
var _rail_material: StandardMaterial3D
var _side_material: StandardMaterial3D


func _init_materials() -> void:
	_rail_material = StandardMaterial3D.new()
	_rail_material.albedo_color = Color(0.70, 0.70, 0.74)
	_rail_material.metallic = 0.94
	_rail_material.roughness = 0.14

	_side_material = StandardMaterial3D.new()
	_side_material.albedo_color = Color(0.15, 0.12, 0.1)
	_side_material.metallic = 0.3
	_side_material.roughness = 0.6


## Load a preset from the module library JSON.
func load_preset(preset_name: String, uvac: Node3D) -> void:
	_uvac = uvac
	_init_materials()

	var lib := _load_module_library()
	if lib.is_empty():
		push_error("EurorackRack: Failed to load module library")
		return

	var presets: Dictionary = lib.get("rack_presets", {})
	if not presets.has(preset_name):
		push_error("EurorackRack: Preset '%s' not found" % preset_name)
		return

	var preset: Dictionary = presets[preset_name]
	var module_defs: Dictionary = lib.get("modules", {})
	row_count = int(preset.get("rows", 1))

	# Initialize HP tracking per row
	row_hp_totals.clear()
	for i in row_count:
		row_hp_totals.append(0)

	# Sort module entries by row then slot
	var entries: Array = preset.get("modules", [])
	entries.sort_custom(func(a, b):
		if int(a.get("row", 0)) != int(b.get("row", 0)):
			return int(a.get("row", 0)) < int(b.get("row", 0))
		return int(a.get("slot", 0)) < int(b.get("slot", 0))
	)

	# Instantiate modules
	for entry in entries:
		var mod_key: String = str(entry.get("module", ""))
		var row_idx: int = int(entry.get("row", 0))

		if not module_defs.has(mod_key):
			push_warning("EurorackRack: Unknown module '%s'" % mod_key)
			continue

		var mod_def: Dictionary = module_defs[mod_key]
		var mod: Node3D = EurorackModuleScript.new()
		mod.build_from_definition(mod_def, uvac)

		add_child(mod)
		modules.append(mod)

		# Position: accumulate HP offset for this row
		var mod_hp: int = int(mod_def.get("hp_width", 8))
		var mod_row_span: int = int(mod_def.get("row_span", 1))
		var current_hp: float = row_hp_totals[row_idx]

		var x_pos: float = current_hp * HP_METERS + (mod_hp * HP_METERS * 0.5)
		var y_pos: float = -row_idx * (ROW_HEIGHT + ROW_GAP + RAIL_HEIGHT * 2)

		# For multi-row modules, offset Y to center across spanned rows
		if mod_row_span > 1:
			var span_height: float = mod_row_span * ROW_HEIGHT + (mod_row_span - 1) * (ROW_GAP + RAIL_HEIGHT * 2)
			y_pos = -row_idx * (ROW_HEIGHT + ROW_GAP + RAIL_HEIGHT * 2) - (span_height - ROW_HEIGHT) * 0.5

		mod.transform.origin = Vector3(x_pos, y_pos, 0)

		# Track HP usage
		row_hp_totals[row_idx] += mod_hp
		# Multi-row modules also consume HP in subsequent rows
		for r in range(1, mod_row_span):
			if row_idx + r < row_count:
				row_hp_totals[row_idx + r] += mod_hp

	# Build frame after all modules are placed
	_build_frame()

	# Set up cable system
	_setup_cable_system()

	# Center the entire rack at origin
	_center_rack()

	print("EurorackRack: Loaded preset '%s' — %d modules across %d rows" % [preset_name, modules.size(), row_count])


func _build_frame() -> void:
	var max_hp: float = 0
	for hp in row_hp_totals:
		max_hp = max(max_hp, hp)

	var rack_width: float = max_hp * HP_METERS

	if rack_width <= 0:
		return

	# Build rails for each row (top and bottom)
	for row_idx in row_count:
		var row_y: float = -row_idx * (ROW_HEIGHT + ROW_GAP + RAIL_HEIGHT * 2)

		# Top rail
		_add_rail(rack_width, row_y + ROW_HEIGHT * 0.5 + RAIL_HEIGHT * 0.5)
		# Bottom rail
		_add_rail(rack_width, row_y - ROW_HEIGHT * 0.5 - RAIL_HEIGHT * 0.5)

	# Side panels
	var total_height: float = row_count * ROW_HEIGHT + (row_count - 1) * ROW_GAP + row_count * 2 * RAIL_HEIGHT
	var center_y: float = -(total_height - ROW_HEIGHT - RAIL_HEIGHT * 2) * 0.5

	_add_side_panel(-SIDE_PANEL_WIDTH * 0.5, center_y, total_height)
	_add_side_panel(rack_width + SIDE_PANEL_WIDTH * 0.5, center_y, total_height)


func _add_rail(width: float, y: float) -> void:
	var rail := MeshInstance3D.new()
	rail.name = "Rail"
	var box := BoxMesh.new()
	box.size = Vector3(width + SIDE_PANEL_WIDTH * 2, RAIL_HEIGHT, RAIL_DEPTH)
	rail.mesh = box
	rail.material_override = _rail_material
	rail.transform.origin = Vector3(width * 0.5, y, 0)
	add_child(rail)
	_rails.append(rail)

	# Add screw holes along the rail (decorative circles)
	_add_rail_holes(rail, width, y)


func _add_rail_holes(rail: MeshInstance3D, width: float, y: float) -> void:
	var hole_mesh := CylinderMesh.new()
	hole_mesh.top_radius = 0.002
	hole_mesh.bottom_radius = 0.002
	hole_mesh.height = 0.001
	hole_mesh.radial_segments = 12

	var hole_mat := StandardMaterial3D.new()
	hole_mat.albedo_color = Color(0.45, 0.45, 0.48)
	hole_mat.metallic = 0.92
	hole_mat.roughness = 0.15
	hole_mat.emission_enabled = true
	hole_mat.emission = Color(0.2, 0.2, 0.22)
	hole_mat.emission_energy_multiplier = 0.05

	# Holes every ~2 HP along the rail
	var hole_spacing: float = 2.0 * HP_METERS
	var num_holes: int = int(width / hole_spacing)
	for i in num_holes:
		var hx: float = (i + 0.5) * hole_spacing
		var mi := MeshInstance3D.new()
		mi.name = "RailHole_%d" % i
		mi.mesh = hole_mesh
		mi.material_override = hole_mat
		mi.transform.origin = Vector3(hx, y, RAIL_DEPTH * 0.5 + 0.0005)
		mi.rotation_degrees.x = 90
		add_child(mi)


func _add_side_panel(x: float, center_y: float, total_height: float) -> void:
	var panel := MeshInstance3D.new()
	panel.name = "SidePanel"
	var box := BoxMesh.new()
	box.size = Vector3(SIDE_PANEL_WIDTH, total_height, SIDE_PANEL_DEPTH)
	panel.mesh = box
	panel.material_override = _side_material
	panel.transform.origin = Vector3(x, center_y, 0)
	add_child(panel)
	_side_panels.append(panel)


func _setup_cable_system() -> void:
	# Skip entire cable system on desktop (avoids RigidBody errors)
	var xr_active: bool = XRServer.primary_interface != null and XRServer.primary_interface.is_initialized()
	if not xr_active:
		print("EurorackRack: Desktop mode — cable system skipped")
		return

	# Create cable manager
	cable_manager = SynthCableManager.new()
	cable_manager.name = "CableManager"
	add_child(cable_manager)

	# Register all jacks from all modules
	var jack_count: int = 0
	for mod in modules:
		if mod.has_method("build_from_definition"):
			for jack_id in mod.jacks:
				var jack: SynthJack = mod.jacks[jack_id]
				cable_manager.register_jack(jack)
				jack_count += 1

	# Build cable tray below the rack
	_build_cable_tray()

	# Spawn cable pool
	if true:  # Only reached when XR is active (early return above for desktop)
		var rack_width: float = get_rack_width()
		var tray_y: float = -(row_count - 1) * (ROW_HEIGHT + ROW_GAP + RAIL_HEIGHT * 2) - ROW_HEIGHT * 0.5 - RAIL_HEIGHT - CABLE_TRAY_HEIGHT - 0.03
		for i in CABLE_POOL_SIZE:
			var cable_x: float = (float(i) / float(CABLE_POOL_SIZE - 1)) * rack_width * 0.8 + rack_width * 0.1
			var spawn_pos := Vector3(cable_x, tray_y, 0.02)
			cable_manager.spawn_cable(spawn_pos)
		print("EurorackRack: Cable system — %d jacks, %d cables" % [jack_count, CABLE_POOL_SIZE])
	else:
		print("EurorackRack: Desktop mode — %d jacks registered, cables skipped" % jack_count)


func _build_cable_tray() -> void:
	var rack_width: float = get_rack_width()
	var tray_y: float = -(row_count - 1) * (ROW_HEIGHT + ROW_GAP + RAIL_HEIGHT * 2) - ROW_HEIGHT * 0.5 - RAIL_HEIGHT - CABLE_TRAY_HEIGHT * 0.5 - 0.01

	var tray := MeshInstance3D.new()
	tray.name = "CableTray"
	var box := BoxMesh.new()
	box.size = Vector3(rack_width + SIDE_PANEL_WIDTH * 2, CABLE_TRAY_HEIGHT, CABLE_TRAY_DEPTH)
	tray.mesh = box
	tray.material_override = _side_material
	tray.transform.origin = Vector3(rack_width * 0.5, tray_y, 0)
	add_child(tray)


func _center_rack() -> void:
	var max_hp: float = 0
	for hp in row_hp_totals:
		max_hp = max(max_hp, hp)
	var rack_width: float = max_hp * HP_METERS
	var total_height: float = row_count * ROW_HEIGHT + (row_count - 1) * ROW_GAP + row_count * 2 * RAIL_HEIGHT

	# Offset all children so the rack is centered at origin
	var offset := Vector3(-rack_width * 0.5, total_height * 0.5 - ROW_HEIGHT * 0.5 - RAIL_HEIGHT, 0)
	for child in get_children():
		if child is Node3D:
			child.transform.origin += offset


func _load_module_library() -> Dictionary:
	var path := "res://commons/audio/eurorack_modules/module_library.json"
	if not FileAccess.file_exists(path):
		push_error("EurorackRack: Module library not found at %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("EurorackRack: Failed to parse module library: %s" % json.get_error_message())
		return {}

	return json.data


## Get the total rack width in meters.
func get_rack_width() -> float:
	var max_hp: float = 0
	for hp in row_hp_totals:
		max_hp = max(max_hp, hp)
	return max_hp * HP_METERS


## Get the total rack height in meters.
func get_rack_height() -> float:
	return row_count * ROW_HEIGHT + (row_count - 1) * ROW_GAP + row_count * 2 * RAIL_HEIGHT
