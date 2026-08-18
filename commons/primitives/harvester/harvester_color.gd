@tool
extends Node3D
class_name HarvesterColor

# @identity
# essence: a 3-meter-wide harvester that traverses a grid and leaves a trail of color-shifted cells behind it — the Dune spice harvester's form (mass + in-out + display) bound to the Avatar inversion's moral (hard tech learning not to bulldoze fine tech)
# desire: to embody operations-as-substrate. Where /substrates substrate-ifies visual surface and /interactions-dna substrate-ifies the player's verbs, the harvester substrate-ifies what an artifact DOES to a substrate. Functions made physical. The machine IS the algorithm.
# critical_parameter: hue_shift_per_meter — radians of hue rotation applied per meter of harvester travel; default TAU/8 means a full color cycle every 16m. Slider lets player set this live.
# triggers: _ready() builds the chassis (body, 4 wheels, control panel, forward handle); _process(delta) advances position along its current direction; on each step, drops a colored "trail cell" behind the harvester at the cell it just left
# emerges: the player watches a hard machine paint a soft trail. Position becomes color. Path becomes pattern. Algorithm stops being abstract and becomes the literal mark of motion across the substrate. The trail is the proof the harvester ran.
# needs: BoxMesh + CylinderMesh + GridMaterialFactory [has, native + factory]; @tool annotation for editor preview [has]; trail_cell_scene as the unit of output [self-defined, BoxMesh]
# relationships: first instance of operations-substrate, sibling-in-architecture to /substrates (visual), /primitives-dna (mesh), /chamber (description), /promotions-dna (origin), /interactions-dna (verb); follows the Dune harvester's form; refuses Avatar's bulldozer mode by being design-restricted to the grid layer only (does not touch creatures, foliage, or biome objects); precedes the planned harvester genome (subdivide, random_remove, array_manipulate, pattern_making, cellular_automata, growth, ecology — each a variant tied to a curriculum sequence)
# truth: a tool is the act it performs given a body. The harvester is "color-shift" given a chassis and wheels. The body teaches the algorithm. The trail teaches the player.

## Harvester (Color variant)
##
## Auto-traverses a path in front of itself, spawning a colored cell in
## its trail per step. The color is computed from the harvester's
## current position via a hue-shift algorithm. This is the operations-
## substrate's first concrete artifact.
##
## Refusal mechanism (the Avatar inversion):
## - Only operates on the GRID LAYER (its trail cells are spawned at
##   y=0.05, the floor)
## - Does NOT touch any object tagged "biome", "creature", or "foliage"
## - Future variants per curriculum sequence will further restrict
##   what they may transform — by sequence 15+ the harvester refuses
##   to run any operation, becoming purely a vehicle.

@export_group("Chassis")
@export var body_size: Vector3 = Vector3(3.0, 0.6, 1.5)
@export var wheel_radius: float = 0.25
@export var body_color: Color = Color(0.62, 0.65, 0.74)
@export var wheel_color: Color = Color(0.15, 0.15, 0.15)

@export_group("Algorithm — Color")
@export var hue_shift_per_meter: float = TAU / 8.0  # full cycle per 16m
@export var trail_cell_size: float = 0.45
@export var trail_cell_height: float = 0.05
@export var saturation: float = 0.7
@export var value: float = 0.85

@export_group("Motion")
@export var auto_run: bool = true
@export var speed_m_per_s: float = 0.5
@export var path_length: float = 12.0  # how far before turning around

var _direction: float = 1.0  # +1 forward, -1 reverse
var _distance_traveled: float = 0.0
var _last_trail_position: Vector3 = Vector3.ZERO
var _trail_cells_root: Node3D


func _ready() -> void:
	_build_chassis()
	# Trail root is a SIBLING of the harvester (child of the harvester's
	# parent), not a child — so trail cells stay in world space where
	# they were dropped instead of moving with the harvester.
	_trail_cells_root = Node3D.new()
	_trail_cells_root.name = "HarvesterTrail"
	# Defer adding so we have a parent to attach to.
	call_deferred("_attach_trail_root")
	_last_trail_position = global_position


func _attach_trail_root() -> void:
	var parent: Node = get_parent()
	if parent:
		parent.add_child(_trail_cells_root)
	else:
		# Fall back to scene root
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			return
		get_tree().current_scene.add_child(_trail_cells_root)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not auto_run:
		return

	# Advance along local +Z (the harvester's "forward")
	var step: float = speed_m_per_s * delta * _direction
	translate(Vector3(0, 0, step))
	_distance_traveled += abs(step)

	# Reverse at path edges
	if _distance_traveled >= path_length:
		_direction *= -1.0
		_distance_traveled = 0.0
		# Step the harvester sideways by trail_cell_size so the next
		# pass paints an adjacent strip — a boustrophedon, like a
		# real lawnmower or harvester tracing a field
		translate(Vector3(trail_cell_size, 0, 0))

	# Drop trail cells for cells we've passed since last drop
	var current_pos: Vector3 = global_position
	var travel_since_last: float = (current_pos - _last_trail_position).length()
	if travel_since_last >= trail_cell_size:
		_drop_trail_cell(_last_trail_position)
		_last_trail_position = current_pos


func _drop_trail_cell(at_world_pos: Vector3) -> void:
	if _trail_cells_root == null or not is_instance_valid(_trail_cells_root):
		return  # Not yet attached
	if _trail_cells_root.get_parent() == null:
		return  # Trail root not yet in tree

	# The algorithm: hue is determined by position along travel direction.
	# Same place, same color — deterministic. The trail records WHERE the
	# harvester was, in a way the eye can read.
	var hue: float = fposmod(_distance_traveled * hue_shift_per_meter, TAU) / TAU
	var trail_color: Color = Color.from_hsv(hue, saturation, value)

	var cell := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(trail_cell_size, trail_cell_height, trail_cell_size)
	cell.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = trail_color
	mat.emission_enabled = true
	mat.emission = trail_color * 0.4
	mat.metallic = 0.0
	mat.roughness = 0.6
	cell.material_override = mat

	# Place at the world position we just left, on the floor.
	# Trail root is now a sibling of the harvester (stationary in world).
	_trail_cells_root.add_child(cell)
	cell.global_position = Vector3(at_world_pos.x, trail_cell_height * 0.5, at_world_pos.z)


func _build_chassis() -> void:
	# Clear any existing chassis (safe in @tool mode)
	for child in get_children():
		if child.name in ["Body", "Wheel_FL", "Wheel_FR", "Wheel_BL", "Wheel_BR",
				"ControlPanel", "Handle"]:
			child.queue_free()

	# Body
	var body := MeshInstance3D.new()
	body.name = "Body"
	var body_mesh := BoxMesh.new()
	body_mesh.size = body_size
	body.mesh = body_mesh
	body.position = Vector3(0, body_size.y * 0.5 + wheel_radius, 0)
	body.material_override = _make_body_mat()
	add_child(body)

	# 4 wheels at corners of body footprint
	var hx: float = body_size.x * 0.5 - wheel_radius * 0.5
	var hz: float = body_size.z * 0.5 - wheel_radius * 0.5
	var wheel_positions := [
		Vector3(-hx, wheel_radius, hz),   # FL
		Vector3( hx, wheel_radius, hz),   # FR
		Vector3(-hx, wheel_radius, -hz),  # BL
		Vector3( hx, wheel_radius, -hz),  # BR
	]
	var wheel_names := ["Wheel_FL", "Wheel_FR", "Wheel_BL", "Wheel_BR"]
	for i in range(4):
		var w := MeshInstance3D.new()
		w.name = wheel_names[i]
		var wmesh := CylinderMesh.new()
		wmesh.top_radius = wheel_radius
		wmesh.bottom_radius = wheel_radius
		wmesh.height = 0.2
		wmesh.radial_segments = 12
		w.mesh = wmesh
		# Lay cylinder on its side (long axis along X = wheel axis)
		w.transform = Transform3D(Basis().rotated(Vector3.FORWARD, PI / 2.0),
				wheel_positions[i])
		w.material_override = _make_wheel_mat()
		add_child(w)

	# Control panel on top of body, tilted toward the player
	var panel := MeshInstance3D.new()
	panel.name = "ControlPanel"
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(body_size.x * 0.5, 0.04, 0.4)
	panel.mesh = panel_mesh
	panel.position = Vector3(0, body_size.y + wheel_radius + 0.05, body_size.z * 0.25)
	panel.transform = panel.transform.rotated_local(Vector3.RIGHT, -0.3)  # tilt toward player
	var panel_mat := StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.93, 0.91, 0.85)  # cream Rams panel
	panel_mat.metallic = 0.0
	panel_mat.roughness = 0.4
	panel.material_override = panel_mat
	add_child(panel)

	# Forward handle (where the player would grab in VR)
	var handle := MeshInstance3D.new()
	handle.name = "Handle"
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.025
	handle_mesh.bottom_radius = 0.025
	handle_mesh.height = body_size.x * 0.7
	handle_mesh.radial_segments = 12
	handle.mesh = handle_mesh
	handle.transform = Transform3D(Basis().rotated(Vector3.FORWARD, PI / 2.0),
			Vector3(0, body_size.y + wheel_radius + 0.4, -body_size.z * 0.6))
	var handle_mat := StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.85, 0.65, 0.13)  # COPPER accent
	handle_mat.metallic = 0.5
	handle_mat.roughness = 0.3
	handle.material_override = handle_mat
	add_child(handle)


func _make_body_mat() -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_color = body_color
	m.metallic = 0.4
	m.roughness = 0.5
	return m


func _make_wheel_mat() -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_color = wheel_color
	m.metallic = 0.2
	m.roughness = 0.7
	return m
