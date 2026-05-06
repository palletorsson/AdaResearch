# MolecularDesigner.gd
# JSON-driven molecular morphology framework
# Spawns floating parts and assembles them into VR bodies or furniture
extends Node3D
class_name MolecularDesigner

# @identity
# essence: catalog(parts) + assembly(bonds, positions) -> molecular morphology
# desire: watch scattered atoms find each other and snap into bodies
# critical_parameter: assembly_name — switches between VRBody, Chair, entirely different topologies
# triggers: auto_cycle timer alternates float/assemble; JSON hot-reload rebuilds catalog live
# emerges: the moment of recognition when disordered parts coalesce into a legible form
# needs: VR grab on parts [missing], keyboard controls [has], auto-cycle [has]
# relationships: unlocks post-reductionist design thinking; depends on Part.tscn/assemblies.json; contrasts snap_cube_puzzle (fixed vs fluid assembly)
# truth: form is not imposed on matter — it is a conversation between catalog and constraint

@export_group("Configuration")
@export var json_path: String = "res://algorithms/computationalbiology/molecular_framework/assemblies.json"
@export_file("*.tscn") var part_scene_path: String = "res://algorithms/computationalbiology/molecular_framework/Part.tscn"

@export_group("Inventory Settings")
@export var inventory_count: int = 40
@export var inventory_box: Vector3 = Vector3(3, 2, 3)
@export var inventory_center: Vector3 = Vector3(0, 1, 0)

@export_group("Assembly Settings")
@export var assemble_height: float = 0.0
@export var bond_radius: float = 0.02
@export var bond_color: Color = Color(0.9, 0.9, 1.0, 1.0)

@export_group("Hot Reload")
@export var enable_hot_reload: bool = true
@export var reload_check_interval: float = 1.0

@export_group("Auto Cycle (VR Mode)")
@export var enable_auto_cycle: bool = true
@export var float_duration: float = 10.0
@export var assemble_duration: float = 10.0
@export var cycle_assemblies: bool = true  # Cycle through different assemblies

# Data
var data: Dictionary = {}
var catalog: Dictionary = {}
var assemblies: Dictionary = {}

# Scene objects
var parts: Array[MolecularPart] = []
var bonds: Array[MeshInstance3D] = []
var bond_pairs: Array[Array] = []  # [[partA, partB], ...]

# State
var current_assembly: String = "VRBody"
var assembled: bool = false
var part_scene: PackedScene = null

# Hot reload
var last_mtime: int = 0
var reload_check_accum: float = 0.0

# Auto cycle
var auto_cycle_timer: float = 0.0
var current_cycle_assembly_index: int = 0
var available_assembly_names: Array[String] = []

func _ready() -> void:
	_load_part_scene()
	_load_json()
	_spawn_inventory()
	_setup_auto_cycle()
	_log_info("Molecular Designer Ready")
	if enable_auto_cycle:
		_log_info("Auto-cycle enabled: %ds float, %ds assemble" % [float_duration, assemble_duration])
	else:
		_log_info("Controls: [F]loat / [A]ssemble, [1]=VRBody, [2]=Chair, [R]eload JSON")

func _process(delta: float) -> void:
	if enable_hot_reload:
		_live_reload_tick(delta)

	if enable_auto_cycle:
		_auto_cycle_tick(delta)

	if assembled:
		_update_bonds()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event = event as InputEventKey
	if not key_event.pressed:
		return

	match key_event.keycode:
		KEY_F:
			_set_float_mode()
		KEY_A:
			_assemble(current_assembly)
		KEY_1:
			_assemble("VRBody")
		KEY_2:
			_assemble("Chair")
		KEY_R:
			_load_json()

func _load_part_scene() -> void:
	"""Load the Part scene"""
	if part_scene_path.is_empty():
		_log_warn("Part scene path is empty")
		return

	part_scene = load(part_scene_path)
	if part_scene == null:
		_log_warn("Failed to load part scene: " + part_scene_path)

func _load_json() -> void:
	"""Load assemblies JSON file"""
	var file := FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		_log_warn("Cannot open JSON: " + json_path)
		return

	var txt := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		_log_warn("JSON parse error in: " + json_path)
		return

	data = parsed
	catalog = data.get("catalog", {})
	assemblies = data.get("assemblies", {})
	last_mtime = FileAccess.get_modified_time(json_path)

	_log_info("Loaded JSON: " + json_path)
	_log_info("Catalog parts: " + str(catalog.keys()))
	_log_info("Assemblies: " + str(assemblies.keys()))

func _spawn_inventory() -> void:
	"""Spawn floating inventory of parts"""
	_clear_scene()

	if part_scene == null:
		_log_warn("No part scene loaded, cannot spawn inventory")
		return

	var half = inventory_box * 0.5
	var catalog_keys = catalog.keys()

	if catalog_keys.is_empty():
		_log_warn("Catalog is empty, cannot spawn parts")
		return

	for i in range(inventory_count):
		var part: MolecularPart = part_scene.instantiate()
		add_child(part)
		parts.append(part)

		# Random part type from catalog
		var key = catalog_keys[randi() % catalog_keys.size()]
		_apply_mesh_from_catalog(part, key)

		# Random position in inventory box
		var rnd = Vector3(
			randf_range(-half.x, half.x),
			randf_range(0.1, inventory_box.y),
			randf_range(-half.z, half.z)
		)
		part.global_position = inventory_center + rnd
		part.clear_target()

	_log_info("Spawned %d parts" % inventory_count)

func _set_float_mode() -> void:
	"""Clear assembly and return to floating mode"""
	assembled = false

	for p in parts:
		if is_instance_valid(p):
			p.clear_target()

	_clear_bonds()
	_log_info("Float mode activated")

func _assemble(assembly_name: String) -> void:
	"""Assemble parts into specified structure"""
	if not assemblies.has(assembly_name):
		_log_warn("Assembly not found: " + assembly_name)
		return

	current_assembly = assembly_name
	assembled = true

	var asm: Dictionary = assemblies[assembly_name]
	var nodes: Array = asm.get("nodes", [])
	var scale_factor: float = float(asm.get("scale", 1.0))

	# Ensure we have enough parts
	while parts.size() < nodes.size():
		var part: MolecularPart = part_scene.instantiate()
		add_child(part)
		parts.append(part)
		_apply_mesh_from_catalog(part, "SphereSmall")

	# Set up assembly base position
	var base = global_position + Vector3(0, assemble_height, 0)

	# Assign parts to nodes
	for i in range(nodes.size()):
		var node: Dictionary = nodes[i]
		var node_id = String(node.get("id", "node_%d" % i))
		var node_part_type = String(node.get("part", "SphereSmall"))
		var node_pos_array = node.get("pos", [0, 0, 0])
		var node_pos = Vector3(node_pos_array[0], node_pos_array[1], node_pos_array[2])

		var target_pos = base + (node_pos * scale_factor)

		# Get part and configure
		var part: MolecularPart = parts[i]
		part.set_part_info(node_id, node_part_type)
		_apply_mesh_from_catalog(part, node_part_type)
		part.set_target(target_pos)

	# Build bonds
	_build_bonds_for(asm, base, scale_factor)

	_log_info("Assembled: " + assembly_name + " (%d nodes, %d bonds)" % [nodes.size(), bonds.size()])

func _build_bonds_for(asm: Dictionary, base: Vector3, scale: float) -> void:
	"""Create bond cylinders between connected nodes"""
	_clear_bonds()

	var nodes: Array = asm.get("nodes", [])
	var bond_defs: Array = asm.get("bonds", [])

	# Build ID to index mapping
	var id_to_index: Dictionary = {}
	for i in range(nodes.size()):
		var node_id = String(nodes[i].get("id", ""))
		id_to_index[node_id] = i

	# Create bonds
	for bond_def in bond_defs:
		if bond_def.size() != 2:
			continue

		var id_a = String(bond_def[0])
		var id_b = String(bond_def[1])

		if not id_to_index.has(id_a) or not id_to_index.has(id_b):
			_log_warn("Bond references unknown node: [%s, %s]" % [id_a, id_b])
			continue

		var idx_a = int(id_to_index[id_a])
		var idx_b = int(id_to_index[id_b])

		var part_a: MolecularPart = parts[idx_a]
		var part_b: MolecularPart = parts[idx_b]

		# Create bond cylinder
		var bond_mesh = _make_bond_cylinder()
		add_child(bond_mesh)
		bonds.append(bond_mesh)
		bond_pairs.append([part_a, part_b])

		# Initial position
		_position_cylinder_between(bond_mesh, part_a.global_position, part_b.global_position)

func _update_bonds() -> void:
	"""Update bond positions to follow parts"""
	for i in range(bonds.size()):
		if not is_instance_valid(bonds[i]):
			continue

		var pair = bond_pairs[i]
		var part_a: MolecularPart = pair[0]
		var part_b: MolecularPart = pair[1]

		if not is_instance_valid(part_a) or not is_instance_valid(part_b):
			continue

		_position_cylinder_between(bonds[i], part_a.global_position, part_b.global_position)

func _apply_mesh_from_catalog(part: MolecularPart, catalog_key: String) -> void:
	"""Apply mesh and material from catalog definition"""
	if not catalog.has(catalog_key):
		_log_warn("Missing catalog part: " + catalog_key)
		return

	var def: Dictionary = catalog[catalog_key]
	var mesh_node := part.mesh_node

	if mesh_node == null:
		_log_warn("Part has no mesh node")
		return

	var mesh_type := String(def.get("mesh", "sphere_small"))
	var color_array = def.get("color", [0.8, 0.8, 0.8, 1.0])
	var color := Color(color_array[0], color_array[1], color_array[2], color_array[3])

	var mesh: PrimitiveMesh = null

	match mesh_type:
		"sphere_small", "sphere_med":
			var sphere := SphereMesh.new()
			var radius = float(def.get("radius", 0.08 if mesh_type == "sphere_small" else 0.12))
			sphere.radius = radius
			sphere.height = radius * 2.0
			mesh = sphere

		"cylinder":
			var cyl := CylinderMesh.new()
			cyl.top_radius = float(def.get("r", 0.05))
			cyl.bottom_radius = cyl.top_radius
			cyl.height = float(def.get("h", 0.4))
			mesh = cyl

		"box":
			var box := BoxMesh.new()
			var size_array = def.get("size", [0.3, 0.02, 0.3])
			box.size = Vector3(size_array[0], size_array[1], size_array[2])
			mesh = box

		_:
			mesh = SphereMesh.new()

	mesh_node.mesh = mesh

	# Apply material
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.3
	mat.metallic = 0.3
	mat.roughness = 0.6
	mesh_node.material_override = mat

	# Set part mass
	part.part_mass = float(def.get("mass", 0.5))

func _make_bond_cylinder() -> MeshInstance3D:
	"""Create a cylinder mesh for bonds"""
	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = bond_radius
	cyl.bottom_radius = bond_radius
	cyl.height = 1.0
	mesh_inst.mesh = cyl

	var mat := StandardMaterial3D.new()
	mat.albedo_color = bond_color
	mat.emission_enabled = true
	mat.emission = bond_color * 0.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat

	return mesh_inst

func _position_cylinder_between(cylinder: MeshInstance3D, pos_a: Vector3, pos_b: Vector3) -> void:
	"""Position and orient cylinder between two points"""
	var mid := (pos_a + pos_b) * 0.5
	var direction := (pos_b - pos_a)
	var length := direction.length()

	if length < 0.0001:
		cylinder.visible = false
		return

	cylinder.visible = true
	cylinder.global_position = mid

	# Orient cylinder along direction
	var up := Vector3.UP
	if abs(direction.normalized().dot(up)) > 0.99:
		up = Vector3.RIGHT

	var basis := Basis.looking_at(direction.normalized(), up)
	# Rotate to align Y axis with direction (cylinder's default orientation)
	basis = basis * Basis(Vector3.RIGHT, PI / 2)

	cylinder.global_transform.basis = basis

	# Scale to match length
	var cyl_mesh := cylinder.mesh as CylinderMesh
	if cyl_mesh:
		cyl_mesh.height = length

func _clear_bonds() -> void:
	"""Remove all bond cylinders"""
	for bond in bonds:
		if is_instance_valid(bond):
			bond.queue_free()

	bonds.clear()
	bond_pairs.clear()

func _clear_scene() -> void:
	"""Clear all parts and bonds"""
	for part in parts:
		if is_instance_valid(part):
			part.queue_free()

	parts.clear()
	_clear_bonds()

func _setup_auto_cycle() -> void:
	"""Setup auto-cycle system"""
	available_assembly_names.clear()
	for key in assemblies.keys():
		available_assembly_names.append(key)

	if available_assembly_names.is_empty():
		_log_warn("No assemblies available for auto-cycle")
		enable_auto_cycle = false
		return

	# Start in float mode
	auto_cycle_timer = 0.0
	assembled = false
	_log_info("Auto-cycle assemblies: " + str(available_assembly_names))

func _auto_cycle_tick(delta: float) -> void:
	"""Handle automatic cycling between float and assemble"""
	auto_cycle_timer += delta

	if assembled:
		# Currently assembled, wait for assemble_duration
		if auto_cycle_timer >= assemble_duration:
			_set_float_mode()
			auto_cycle_timer = 0.0
			_log_info("Auto-cycle: Floating for %ds" % float_duration)
	else:
		# Currently floating, wait for float_duration
		if auto_cycle_timer >= float_duration:
			# Pick next assembly
			if cycle_assemblies and available_assembly_names.size() > 1:
				current_cycle_assembly_index = (current_cycle_assembly_index + 1) % available_assembly_names.size()

			var assembly_name = available_assembly_names[current_cycle_assembly_index]
			_assemble(assembly_name)
			auto_cycle_timer = 0.0
			_log_info("Auto-cycle: Assembling '%s' for %ds" % [assembly_name, assemble_duration])

func _live_reload_tick(delta: float) -> void:
	"""Check for JSON file changes and reload"""
	reload_check_accum += delta

	if reload_check_accum < reload_check_interval:
		return

	reload_check_accum = 0.0

	var current_mtime = FileAccess.get_modified_time(json_path)
	if current_mtime != 0 and current_mtime != last_mtime:
		_log_info("JSON file changed, reloading...")
		_load_json()
		_setup_auto_cycle()  # Re-setup cycle with new assemblies

		if assembled and not enable_auto_cycle:
			_assemble(current_assembly)

# Helper functions
func _log_info(message: String) -> void:
	print_rich("[color=cyan][MolecularDesigner][/color] " + message)

func _log_warn(message: String) -> void:
	push_warning("[MolecularDesigner] " + message)

# Public API
func assemble_structure(structure_name: String) -> void:
	"""Public method to assemble a structure"""
	_assemble(structure_name)

func return_to_float_mode() -> void:
	"""Public method to return to float mode"""
	_set_float_mode()

func get_available_assemblies() -> Array:
	"""Get list of available assembly names"""
	return assemblies.keys()

func get_assembly_info(assembly_name: String) -> Dictionary:
	"""Get information about a specific assembly"""
	return assemblies.get(assembly_name, {})

func is_assembled() -> bool:
	"""Check if currently in assembled state"""
	return assembled

func get_current_assembly_name() -> String:
	"""Get the name of the current assembly"""
	return current_assembly if assembled else ""

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
