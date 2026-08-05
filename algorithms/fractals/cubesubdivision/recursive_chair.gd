extends Node3D

# Recursive Chair - True subdivision-based chair construction
# Starts with one cube, subdivides it, keeps some parts, removes others,
# then recursively subdivides remaining parts with non-uniform scaling

# @identity
# essence: chair = subdivide_3x3x3(cube) -> keep(legs, seat, back) -> deform(stretch, flatten)
# desire: To prove that a chair lives inside every cube — subdivision as revelation, not construction
# critical_parameter: the 3x3x3 role assignment — which subcubes become seat vs leg vs back determines the entire form
# triggers: Each step transforms role-tagged subcubes: flatten seat, stretch legs, extend back, add armrests
# emerges: A recognizable chair from pure subdivision logic — no chair blueprint, only cube-cutting rules
# needs: VR sit detection [missing], construction replay [missing]
# relationships: Sibling to recursive_table and cube_desk; demonstrates that furniture is latent in geometry
# truth: The chair was always inside the cube — subdivision merely removed what was not chair.

@export var chair_size: float = 1.5
@export var show_animation: bool = true
@export var step_delay: float = 0.4

## STAGE-2 DNA — AXIS: WHAT THE CUT DOES WITH WHAT IT CUT AWAY.
##
## This file's own truth statement is "the chair was always inside the cube — subdivision
## merely removed what was not chair", and until now the removal had no representation at
## all. _step_1_first_subdivision walks a 3x3x3 lattice and tags each of the 27 subcubes
## seat, leg_top, back or "remove"; sixteen are built and ELEVEN — the five non-corner
## cells of the bottom layer and the six front cells of the top layer — are simply never
## created. Nothing in the picture says they were ever there, so the claim that a chair is
## what is LEFT of a cube is made by an object that shows no cube.
##
##   gone    the eleven cells are not drawn. The shipped silence, and what all four
##           placements have always shown.
##   ghost   each is restored as a pale unshaded volume at its lattice cell, so the whole
##           3x3x3 cube reads again with the chair standing solid inside it. The claim
##           and its evidence in one frame.
##   scar    a small dark core is left at each cell's centre — the removals read as a
##           lattice of markers rather than a solid, so the cut is legible without the
##           block closing back up around the chair.
##
## The word and both material recipes are cantor_set's, character for character (same
## registry file, promoted 2026-08-03): the same question about the same kind of deletion.
## It fits here for the reason sierpinski_pyramid refused it — those children's volumes
## interpenetrate and have no complement to draw, whereas these 27 cells partition one
## cube exactly, so kept and removed are disjoint and the removed set is a real shape.
@export_enum("gone", "ghost", "scar") var removal: String = "gone"

## NOT an axis — the fixture. The shipped chair assembles itself one step every
## `step_delay` seconds (0.5 in the .tscn), so a still taken at the harness's 1.1 s settle
## catches it at step 2, seatless and legless, one frame away from step 3. "instant" runs
## the same five steps in _ready with the same numbers. Default "grow" is the shipped
## behaviour, line for line, and the legacy `show_animation = false` still forces instant
## wherever a scene or map already set it.
@export_enum("grow", "instant") var build_mode: String = "grow"

const REMOVALS: PackedStringArray = ["gone", "ghost", "scar"]
const BUILD_MODES: PackedStringArray = ["grow", "instant"]

# Colors for different generations - light plastic look
var generation_colors: Array[Color] = [
	Color(0.85, 0.85, 0.9, 1.0),   # Gen 0 - Light gray plastic (seat)
	Color(0.75, 0.8, 0.85, 1.0),   # Gen 1 - Slightly darker
	Color(0.65, 0.7, 0.75, 1.0),   # Gen 2 - Medium gray (legs)
	Color(0.55, 0.6, 0.65, 1.0),   # Gen 3 - Darker accent
	Color(0.45, 0.5, 0.55, 1.0),   # Gen 4 - Darkest (details)
]

var all_cubes: Array[Dictionary] = []  # {node, generation, role}
var step: int = 0
var timer: float = 0.0
var is_animating: bool = false

## The markers standing in for the eleven deleted cells. Kept OUT of all_cubes on purpose:
## _find_cubes_by_role drives every deform step, and a ghost that answered to a role would
## be flattened into a seat or stretched into a leg.
var _removed_nodes: Array[Node3D] = []
## False until _ready has built once, so apply_grid_config can record a value without
## rebuilding a chair that does not exist yet.
var _built: bool = false


## "grow" honours the legacy show_animation flag; "instant" overrides it. Both defaults
## together are exactly the shipped `if show_animation:` test.
func _wants_instant() -> bool:
	return build_mode == "instant" or not show_animation


func _ready() -> void:
	if not _wants_instant():
		is_animating = true
		_step_0_initial_cube()
	else:
		_build_instant()
	_built = true


func _process(delta: float) -> void:
	if not is_animating:
		return

	timer += delta
	if timer >= step_delay:
		timer = 0.0
		step += 1
		_execute_step(step)


func _execute_step(s: int) -> void:
	match s:
		1: _step_1_first_subdivision()
		2: _step_2_shape_seat()
		3: _step_3_create_legs()
		4: _step_4_create_back()
		5: _step_5_add_details()
		_:
			is_animating = false
			print("Recursive chair complete! Total parts: %d" % all_cubes.size())


func _build_instant() -> void:
	_step_0_initial_cube()
	_step_1_first_subdivision()
	_step_2_shape_seat()
	_step_3_create_legs()
	_step_4_create_back()
	_step_5_add_details()


func _step_0_initial_cube() -> void:
	# Create the initial cube that will become the chair
	_create_cube(Vector3(0, chair_size * 0.5, 0), Vector3(chair_size, chair_size, chair_size), 0, "base")
	print("Step 0: Initial cube")


func _step_1_first_subdivision() -> void:
	# Subdivide into 3x3x3 = 27 parts (like a Rubik's cube)
	# Remove original, create grid
	var base = _find_cubes_by_role("base")
	if base.is_empty():
		return

	var base_cube = base[0]
	var center = base_cube.node.position
	var size = chair_size / 3.0

	# Remove original
	_remove_cube(base_cube)

	# Create 3x3x3 grid, but we'll selectively keep parts
	# Bottom layer (y=0): legs corners, empty middle
	# Middle layer (y=1): seat
	# Top layer (y=2): back (only back row)

	for y in range(3):
		for x in range(3):
			for z in range(3):
				var offset = Vector3(
					(x - 1) * size,
					(y - 1) * size + chair_size * 0.5,
					(z - 1) * size
				)
				var pos = center + offset

				# Determine role based on position
				var role = "remove"

				if y == 0:  # Bottom layer - legs
					if (x == 0 or x == 2) and (z == 0 or z == 2):
						role = "leg_top"
				elif y == 1:  # Middle layer - seat
					role = "seat"
				elif y == 2:  # Top layer - back
					if z == 2:  # Back row only
						role = "back"

				if role != "remove":
					_create_cube(pos, Vector3(size * 0.95, size * 0.95, size * 0.95), 1, role)
				else:
					# The cell the role rule threw away. Drawn only when `removal` asks
					# for it; at the default "gone" this call returns immediately and the
					# lattice cell stays as empty as it has always been.
					_spawn_removed_cell(pos, size * 0.95)

	print("Step 1: Subdivided into chair shape")


func _step_2_shape_seat() -> void:
	# Flatten the seat cubes - make thinner for plastic look
	var seats = _find_cubes_by_role("seat")
	for cube_data in seats:
		var node = cube_data.node as MeshInstance3D
		if node and node.mesh:
			var box = node.mesh as BoxMesh
			if box:
				# Flatten the seat - thinner for plastic
				box.size.y *= 0.15
				node.position.y -= chair_size / 3.0 * 0.42

	print("Step 2: Shaped seat (thin plastic)")


func _step_3_create_legs() -> void:
	# Extend the leg cubes downward - thinner for plastic
	var legs = _find_cubes_by_role("leg_top")
	for cube_data in legs:
		var node = cube_data.node as MeshInstance3D
		if node and node.mesh:
			var box = node.mesh as BoxMesh
			if box:
				# Make legs taller and thinner - slim plastic legs
				var old_height = box.size.y
				box.size.x *= 0.4
				box.size.z *= 0.4
				box.size.y *= 2.5
				node.position.y -= old_height * 0.75

				# Update color to leg color
				_apply_color(node, generation_colors[2])

		cube_data.role = "leg"

	print("Step 3: Extended legs (thin plastic)")


func _step_4_create_back() -> void:
	# Make back taller - thinner for plastic
	var backs = _find_cubes_by_role("back")
	for cube_data in backs:
		var node = cube_data.node as MeshInstance3D
		if node and node.mesh:
			var box = node.mesh as BoxMesh
			if box:
				# Make back taller and thinner - slim plastic back
				box.size.y *= 2.0
				box.size.z *= 0.2
				node.position.y += chair_size / 3.0 * 0.5
				node.position.z += chair_size / 3.0 * 0.4

				# Update color
				_apply_color(node, generation_colors[1])

	print("Step 4: Extended back (thin plastic)")


func _step_5_add_details() -> void:
	# Add armrests by creating new small cubes - thinner for plastic
	var arm_size = chair_size * 0.04
	var arm_length = chair_size * 0.5

	# Left armrest
	_create_cube(
		Vector3(-chair_size * 0.4, chair_size * 0.5, 0),
		Vector3(arm_size, arm_size, arm_length),
		3, "armrest"
	)

	# Right armrest
	_create_cube(
		Vector3(chair_size * 0.4, chair_size * 0.5, 0),
		Vector3(arm_size, arm_size, arm_length),
		3, "armrest"
	)

	# Armrest supports - thin plastic tubes
	_create_cube(
		Vector3(-chair_size * 0.4, chair_size * 0.4, chair_size * 0.15),
		Vector3(arm_size * 0.8, chair_size * 0.12, arm_size * 0.8),
		4, "support"
	)
	_create_cube(
		Vector3(chair_size * 0.4, chair_size * 0.4, chair_size * 0.15),
		Vector3(arm_size * 0.8, chair_size * 0.12, arm_size * 0.8),
		4, "support"
	)

	print("Step 5: Added armrests (thin plastic)")


func _create_cube(pos: Vector3, size: Vector3, generation: int, role: String) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos

	var color = generation_colors[generation % generation_colors.size()]
	_apply_color(mesh_instance, color)

	add_child(mesh_instance)
	all_cubes.append({"node": mesh_instance, "generation": generation, "role": role})


# One of the eleven subcubes the role rule deleted. `gone` draws nothing at all, which is
# what this artifact has always done; `ghost` restores the cell as a pale full-size volume
# so the row of empties reads as the cube it was cut from; `scar` leaves a small dark core
# at the cell's centre so the removals read as markers and not as a solid.
#
# Both material recipes are cantor_set's _spawn_removed(), value for value — the shared
# word is only honest if the two artifacts LOOK alike answering it.
func _spawn_removed_cell(pos: Vector3, cell: float) -> void:
	if removal == "gone":
		return
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	var extent: float = cell if removal == "ghost" else cell * 0.22
	box.size = Vector3(extent, extent, extent)
	mesh_instance.mesh = box

	var material := StandardMaterial3D.new()
	if removal == "ghost":
		material.albedo_color = Color(0.86, 0.88, 0.96, 0.16)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	else:
		material.albedo_color = Color(0.09, 0.09, 0.11)
		material.metallic = 0.0
		material.roughness = 1.0
	mesh_instance.material_override = material

	mesh_instance.position = pos
	add_child(mesh_instance)
	_removed_nodes.append(mesh_instance)


func _apply_color(mesh: MeshInstance3D, color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	# Light plastic look - slightly shiny, smooth
	material.metallic = 0.15
	material.roughness = 0.35
	material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mesh.material_override = material


func _find_cubes_by_role(role: String) -> Array:
	var result = []
	for cube in all_cubes:
		if cube.role == role:
			result.append(cube)
	return result


func _remove_cube(cube_data: Dictionary) -> void:
	if cube_data.node and is_instance_valid(cube_data.node):
		cube_data.node.queue_free()
	all_cubes.erase(cube_data)


func reset() -> void:
	for cube_data in all_cubes:
		if cube_data.node and is_instance_valid(cube_data.node):
			cube_data.node.queue_free()
	all_cubes.clear()
	# The removal markers are not in all_cubes, so they have to be swept separately or a
	# rebuild leaves the previous value's ghosts standing inside the new chair.
	for node in _removed_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_removed_nodes.clear()
	step = 0
	timer = 0.0

	if not _wants_instant():
		is_animating = true
		_step_0_initial_cube()
	else:
		_build_instant()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Config from map_data.json tokens:  recursive_chair#removal:ghost
##
## GUARDED TWICE. A word is taken only when it validates AND differs, and the rebuild runs
## only after _ready has built once — so the four existing placements, which are bare
## tokens carrying no keys at all, never reach reset() and assemble on their own clock
## exactly as before. Before _ready the value is only recorded, which is also the path the
## capture harness takes when it sets the export directly.
func apply_grid_config(config: Dictionary) -> void:
	var changed: bool = false
	if config.has("removal"):
		var r: String = str(config["removal"]).strip_edges().to_lower()
		if REMOVALS.has(r) and r != removal:
			removal = r
			changed = true
	if config.has("build_mode"):
		var b: String = str(config["build_mode"]).strip_edges().to_lower()
		if BUILD_MODES.has(b) and b != build_mode:
			build_mode = b
			changed = true
	if changed and _built:
		reset()
