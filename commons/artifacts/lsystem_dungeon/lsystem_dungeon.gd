# lsystem_dungeon.gd
# Generates a small dungeon floor plan using L-system grammar rules.
# Rooms and corridors emerge from string rewriting, then render as
# 3D architectural geometry on the XZ plane — a top-down view.
#
# Axiom: "F"
# Rules: F -> "F+RF-FF-FR+F", R -> "RFRFRF"
# Turtle: F = corridor forward, R = room marker, + = left 90, - = right 90
#
# @identity
# essence: F → F+RF-FF-FR+F, R → RFRFRF — corridor grammar with room markers at 90° turns
# desire: To generate a dungeon you can look down on — corridors and rooms from two rewriting rules
# critical_parameter: iterations — controls dungeon complexity from a single corridor to a labyrinthine floor plan
# triggers: Iteration 1 → simple L-shaped corridor; iteration 4 → dense maze with many rooms and walled passages
# emerges: Spatial variety from two rules — rooms appear at grammatical intersections, not placed by a designer
# needs: VR iteration control [missing], Label3D [has]
# relationships: Feeds into LSystems_Architecture. Contrasts with CityGenerator (2D plan vs 3D growth). Bridges to proceduralgeneration.
# truth: Two rules and a turtle — the dungeon writes itself.

extends Node3D

class_name LSystemDungeon

## Display scale — bounding box fits within this size
@export var display_size: float = 0.7

## L-system iteration count
@export_range(1, 5) var iterations: int = 3

## Colors
@export var corridor_color: Color = Color(0.35, 0.3, 0.28)
@export var room_color: Color = Color(0.5, 0.4, 0.35)
@export var wall_color: Color = Color(0.2, 0.18, 0.16)

# L-system config
var _axiom: String = "F"
var _rules: Dictionary = {
	"F": "F+RF-FF-FR+F",
	"R": "RFRFRF"
}

# Geometry containers
var _dungeon_root: Node3D
var _info_label: Label3D

# Stats
var _corridor_count: int = 0
var _room_count: int = 0
var _wall_count: int = 0

func _ready() -> void:
	_create_base()
	_create_labels()
	_generate_dungeon()

func _create_base() -> void:
	var base = MeshInstance3D.new()
	base.name = "Base"

	var cylinder = CylinderMesh.new()
	cylinder.top_radius = display_size * 0.55
	cylinder.bottom_radius = display_size * 0.6
	cylinder.height = 0.03
	base.mesh = cylinder

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.12)
	mat.metallic = 0.5
	mat.roughness = 0.5
	base.material_override = mat

	base.position = Vector3(0, -0.015, 0)
	add_child(base)

func _create_labels() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 20
	_info_label.position = Vector3(0, display_size * 0.6, 0)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_info_label)

func _generate_dungeon() -> void:
	# Clear previous geometry
	if _dungeon_root:
		_dungeon_root.queue_free()

	_dungeon_root = Node3D.new()
	_dungeon_root.name = "DungeonGeometry"
	add_child(_dungeon_root)

	_corridor_count = 0
	_room_count = 0
	_wall_count = 0

	# Step 1: Produce L-system string
	var lstring = _produce_string()

	# Step 2: Turtle interpretation to get segments and room positions
	var segments: Array = []  # [[from, to], ...]
	var rooms: Array = []     # [pos, ...]
	_interpret_turtle(lstring, segments, rooms)

	if segments.is_empty() and rooms.is_empty():
		_update_label()
		return

	# Step 3: Compute bounding box and scale factor
	var min_bounds = Vector3(INF, 0, INF)
	var max_bounds = Vector3(-INF, 0, -INF)

	for seg in segments:
		var p0: Vector3 = seg[0]
		var p1: Vector3 = seg[1]
		min_bounds.x = minf(min_bounds.x, minf(p0.x, p1.x))
		min_bounds.z = minf(min_bounds.z, minf(p0.z, p1.z))
		max_bounds.x = maxf(max_bounds.x, maxf(p0.x, p1.x))
		max_bounds.z = maxf(max_bounds.z, maxf(p0.z, p1.z))

	for rpos in rooms:
		var rp: Vector3 = rpos
		min_bounds.x = minf(min_bounds.x, rp.x)
		min_bounds.z = minf(min_bounds.z, rp.z)
		max_bounds.x = maxf(max_bounds.x, rp.x)
		max_bounds.z = maxf(max_bounds.z, rp.z)

	var bounds_size = max_bounds - min_bounds
	var max_dim = maxf(bounds_size.x, bounds_size.z)
	if max_dim < 0.001:
		max_dim = 1.0

	var scale_factor = display_size * 0.75 / max_dim
	var center = Vector3(
		(min_bounds.x + max_bounds.x) / 2.0,
		0,
		(min_bounds.z + max_bounds.z) / 2.0
	)

	# Step 4: Create shared materials
	var corridor_mat = StandardMaterial3D.new()
	corridor_mat.albedo_color = corridor_color
	corridor_mat.roughness = 0.8

	var room_mat = StandardMaterial3D.new()
	room_mat.albedo_color = room_color
	room_mat.roughness = 0.7

	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = wall_color
	wall_mat.roughness = 0.9

	# Corridor tile dimensions
	var tile_thickness = 0.008  # floor slab height
	var corridor_width = scale_factor * 0.4  # width of corridor slabs
	var wall_height = 0.04
	var wall_thickness = 0.004

	# Step 5: Draw corridor segments as flat BoxMesh slabs
	for seg in segments:
		var p0: Vector3 = (seg[0] - center) * scale_factor
		var p1: Vector3 = (seg[1] - center) * scale_factor
		var mid = (p0 + p1) / 2.0
		var length = p0.distance_to(p1)

		if length < 0.0001:
			continue

		# Floor slab
		var floor_mi = MeshInstance3D.new()
		var floor_box = BoxMesh.new()
		floor_box.size = Vector3(length, tile_thickness, corridor_width)
		floor_mi.mesh = floor_box
		floor_mi.material_override = corridor_mat

		# Compute rotation from direction
		var dir = (p1 - p0).normalized()
		var angle = atan2(dir.x, dir.z)
		floor_mi.position = Vector3(mid.x, tile_thickness / 2.0, mid.z)
		floor_mi.rotation.y = -angle + PI / 2.0

		_dungeon_root.add_child(floor_mi)
		_corridor_count += 1

		# Walls on both sides of the corridor
		for side in [-1.0, 1.0]:
			var wall_mi = MeshInstance3D.new()
			var wall_box = BoxMesh.new()
			wall_box.size = Vector3(length, wall_height, wall_thickness)
			wall_mi.mesh = wall_box
			wall_mi.material_override = wall_mat

			# Offset perpendicular to corridor direction
			var perp = Vector3(-dir.z, 0, dir.x) * (corridor_width / 2.0) * side
			wall_mi.position = Vector3(
				mid.x + perp.x,
				tile_thickness + wall_height / 2.0,
				mid.z + perp.z
			)
			wall_mi.rotation.y = -angle + PI / 2.0

			_dungeon_root.add_child(wall_mi)
			_wall_count += 1

	# Step 6: Draw room markers as larger floor tiles
	var room_tile_size = corridor_width * 2.0
	var room_tile_thickness = tile_thickness * 1.2

	for rpos in rooms:
		var rp: Vector3 = (rpos - center) * scale_factor

		var room_mi = MeshInstance3D.new()
		var room_box = BoxMesh.new()
		room_box.size = Vector3(room_tile_size, room_tile_thickness, room_tile_size)
		room_mi.mesh = room_box
		room_mi.material_override = room_mat
		room_mi.position = Vector3(rp.x, room_tile_thickness / 2.0, rp.z)

		_dungeon_root.add_child(room_mi)
		_room_count += 1

	_update_label()

func _produce_string() -> String:
	var current = _axiom

	for _i in range(iterations):
		var next = ""
		for c in current:
			if _rules.has(c):
				next += _rules[c]
			else:
				next += c
		current = next
		# Safety limit
		if current.length() > 50000:
			break

	return current

func _interpret_turtle(lstring: String, segments: Array, rooms: Array) -> void:
	var pos = Vector3.ZERO
	var dir = Vector3(1, 0, 0)  # Start facing +X on XZ plane
	var step = 1.0
	var stack: Array = []

	for c in lstring:
		match c:
			"F":
				# Draw corridor segment and move forward
				var new_pos = pos + dir * step
				segments.append([pos, new_pos])
				pos = new_pos
			"R":
				# Mark room at current position (no movement)
				rooms.append(pos)
			"+":
				# Turn left 90 degrees (counterclockwise on XZ)
				dir = Vector3(-dir.z, 0, dir.x)
			"-":
				# Turn right 90 degrees (clockwise on XZ)
				dir = Vector3(dir.z, 0, -dir.x)
			"[":
				stack.append([pos, dir])
			"]":
				if stack.size() > 0:
					var state = stack.pop_back()
					pos = state[0]
					dir = state[1]

func _update_label() -> void:
	if not _info_label:
		return

	_info_label.text = "L-System Dungeon\nIter: %d | Corridors: %d | Rooms: %d | Walls: %d" % [
		iterations, _corridor_count, _room_count, _wall_count
	]

## Grid system integration hook
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("iterations"):
		iterations = clampi(int(config_data["iterations"]), 1, 5)
		_generate_dungeon()
