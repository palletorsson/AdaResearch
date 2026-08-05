extends Node3D

# Recursive Table - Subdivision-based table construction
# Starts with one cube, subdivides it, keeps tabletop and legs
# Similar approach to recursive_chair but for a table form

# @identity
# essence: table = subdivide_3x2(cube) -> keep(top_layer, corner_legs) -> flatten(top) -> stretch(legs)
# desire: To stand beside in VR — a table that assembled itself from a single cube through pure subtraction
# critical_parameter: the top-layer vs bottom-layer role split — one layer becomes surface, four corners become legs
# triggers: Each step refines: merge tabletop into single slab, thin the legs, add apron supports
# emerges: Structural apron supports arise from the need to connect legs to tabletop — engineering from aesthetics
# needs: VR place-objects-on-top [missing], construction replay [missing]
# relationships: Sibling to recursive_chair; together they prove furniture is a family of subdivision strategies
# truth: A table is a cube that kept its top layer and four corners — everything else was excess.

# --- DNA (stage 2, promoted 2026-08-05) --------------------------------------
# keep: WHICH CELLS of the subdivided bottom layer survive to become legs. The
#   essence line is literally `keep(top_layer, corner_legs)` and the
#   critical_parameter is named as "the top-layer vs bottom-layer role split" —
#   but the split was four hard-coded corner tests inside _step_1, so the one
#   choice this artifact declares as its own subject was the one thing no
#   placement could vary. Every rung is the SAME 3x3x2 subdivision with a
#   different survival rule, which is the sibling claim in the @identity
#   ("furniture is a family of subdivision strategies") made testable:
#     corners  — the four corner cells (what this always built).
#     edges    — the four mid-edge cells: a trestle, legs under the middles.
#     ring     — all eight perimeter cells: a plinth, the table as a solid base.
#     pedestal — the centre cell alone: one column, cantilevered top.
# assembly: how much of the derivation is standing. The four steps ran
#   unconditionally, so the truth line ("everything else was excess") could only
#   ever be shown as its finished result — the excess was never on view. The
#   rungs are cumulative and are the artifact's own steps:
#     cells    — step 1 only: the kept cells, still separate blocks in the air.
#     slab     — + step 2: the nine top cells merged into one thin surface.
#     legs     — + step 3: the leg cells stretched down to the floor.
#     full     — + step 4: the apron braces (what this always built).
#   `assembly` is cube_staircase's word, one folder over and one rung along the
#   same sequence, with its terminal value `full` — the same question (how much
#   of the built object is standing) with this object's own part names.
const ASSEMBLY_VALUES: Array = ["cells", "slab", "legs", "full"]
const KEEP_VALUES: Array = ["corners", "edges", "ring", "pedestal"]

@export var table_size: float = 2.5
@export_enum("cells", "slab", "legs", "full") var assembly: String = "full"
@export_enum("corners", "edges", "ring", "pedestal") var keep: String = "corners"
@export var show_animation: bool = true
@export var step_delay: float = 0.4

# Colors for different generations - light plastic look
var generation_colors: Array[Color] = [
	Color(0.9, 0.9, 0.92, 1.0),    # Gen 0 - White plastic (tabletop)
	Color(0.8, 0.82, 0.85, 1.0),   # Gen 1 - Light gray
	Color(0.7, 0.72, 0.75, 1.0),   # Gen 2 - Medium gray (legs)
	Color(0.6, 0.62, 0.65, 1.0),   # Gen 3 - Darker (apron)
	Color(0.5, 0.52, 0.55, 1.0),   # Gen 4 - Darkest
]

var all_cubes: Array[Dictionary] = []  # {node, generation, role}
var step: int = 0
var timer: float = 0.0
var is_animating: bool = false

# True once _ready has built (or started building) once, so apply_grid_config
# knows whether a changed value needs a rebuild or will be picked up by the
# first build that has not happened yet.
var _built: bool = false


func _ready() -> void:
	if show_animation:
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
		1:
			_step_1_first_subdivision()
		2:
			if _shows_slab():
				_step_2_shape_tabletop()
		3:
			if _shows_legs():
				_step_3_create_legs()
		4:
			if _shows_apron():
				_step_4_add_supports()
		_:
			is_animating = false
			print("Recursive table complete! Total parts: %d" % all_cubes.size())


func _build_instant() -> void:
	_step_0_initial_cube()
	_step_1_first_subdivision()
	if _shows_slab():
		_step_2_shape_tabletop()
	if _shows_legs():
		_step_3_create_legs()
	if _shows_apron():
		_step_4_add_supports()


# ── assembly gates ───────────────────────────────────────────────────────────
# At "full" — the default, and the only thing this artifact could ever build —
# all three return true, so every existing placement runs the identical steps in
# the identical order over the identical geometry.

func _shows_slab() -> bool:
	return assembly != "cells"


func _shows_legs() -> bool:
	return assembly == "legs" or assembly == "full"


func _shows_apron() -> bool:
	return assembly == "full"


## The keep rule: does this bottom-layer cell survive as a leg? At "corners" this
## is the shipped test, character for character.
func _is_leg_cell(x: int, z: int) -> bool:
	match keep:
		"edges":
			return (x == 1) != (z == 1)
		"ring":
			return x != 1 or z != 1
		"pedestal":
			return x == 1 and z == 1
	return (x == 0 or x == 2) and (z == 0 or z == 2)


func _step_0_initial_cube() -> void:
	# Create the initial cube that will become the table
	_create_cube(Vector3(0, table_size * 0.4, 0), Vector3(table_size, table_size * 0.8, table_size), 0, "base")
	print("Step 0: Initial cube")


func _step_1_first_subdivision() -> void:
	# Subdivide into 3x3x2 grid (3 wide, 3 deep, 2 tall)
	# Top layer = tabletop, bottom corners = legs
	var base = _find_cubes_by_role("base")
	if base.is_empty():
		return

	var base_cube = base[0]
	var center = base_cube.node.position
	var size_x = table_size / 3.0
	var size_z = table_size / 3.0
	var size_y = table_size * 0.4  # Half height for 2 layers

	# Remove original
	_remove_cube(base_cube)

	# Create 3x3x2 grid
	# Bottom layer (y=0): only corners are legs
	# Top layer (y=1): entire layer is tabletop

	for y in range(2):
		for x in range(3):
			for z in range(3):
				var offset = Vector3(
					(x - 1) * size_x,
					y * size_y + size_y * 0.5,
					(z - 1) * size_z
				)
				var pos = center + offset - Vector3(0, table_size * 0.2, 0)

				# Determine role based on position
				var role = "remove"

				if y == 0:  # Bottom layer - the cells the keep rule selects
					if _is_leg_cell(x, z):
						role = "leg_top"
				elif y == 1:  # Top layer - entire tabletop
					role = "tabletop"

				if role != "remove":
					_create_cube(pos, Vector3(size_x * 0.95, size_y * 0.95, size_z * 0.95), 1, role)

	print("Step 1: Subdivided into table shape")


func _step_2_shape_tabletop() -> void:
	# Remove the 9 individual tabletop cubes and replace with single solid piece
	var tabletops = _find_cubes_by_role("tabletop")

	# Get the Y position from first tabletop piece before removing
	var tabletop_y = table_size * 0.48
	if not tabletops.is_empty():
		tabletop_y = tabletops[0].node.position.y

	# Remove all individual tabletop pieces
	for cube_data in tabletops:
		if cube_data.node and is_instance_valid(cube_data.node):
			cube_data.node.queue_free()
		all_cubes.erase(cube_data)

	# Create single solid tabletop - thin plastic
	var tabletop_thickness = table_size * 0.04
	_create_cube(
		Vector3(0, tabletop_y + table_size * 0.08, 0),
		Vector3(table_size * 0.95, tabletop_thickness, table_size * 0.95),
		0, "tabletop_solid"
	)

	print("Step 2: Shaped tabletop (thin plastic)")


func _step_3_create_legs() -> void:
	# Extend the leg cubes to meet tabletop - thinner plastic legs
	var legs = _find_cubes_by_role("leg_top")

	# Find actual tabletop position to calculate proper leg height
	# Tabletop is created at: tabletop_y + table_size * 0.08, with thickness table_size * 0.04
	# So bottom of tabletop is at: tabletop_y + table_size * 0.08 - (table_size * 0.04 / 2)
	var tabletop_solid = _find_cubes_by_role("tabletop_solid")
	var tabletop_bottom_y = table_size * 0.5  # Default fallback
	if not tabletop_solid.is_empty():
		var tabletop_node = tabletop_solid[0].node as MeshInstance3D
		if tabletop_node and tabletop_node.mesh:
			var tabletop_box = tabletop_node.mesh as BoxMesh
			if tabletop_box:
				tabletop_bottom_y = tabletop_node.position.y - tabletop_box.size.y / 2.0

	for cube_data in legs:
		var node = cube_data.node as MeshInstance3D
		if node and node.mesh:
			var box = node.mesh as BoxMesh
			if box:
				# Calculate leg dimensions to bridge gap
				var leg_bottom_y = 0.0  # Floor
				var leg_top_y = tabletop_bottom_y
				var leg_height = leg_top_y - leg_bottom_y
				var leg_center_y = leg_height / 2.0

				# Make legs thinner - slim plastic
				box.size.x *= 0.35
				box.size.z *= 0.35
				box.size.y = leg_height

				# Position leg to touch floor and reach tabletop
				node.position.y = leg_center_y

				# Update color to leg color
				_apply_color(node, generation_colors[2])

		cube_data.role = "leg"

	print("Step 3: Extended legs (thin plastic, bridging gap)")


func _step_4_add_supports() -> void:
	# A single central column has no second leg to brace against — an apron ring
	# around it would be four bars floating in air, so there is nothing to add.
	if keep == "pedestal":
		print("Step 4: pedestal keeps no apron (one leg, nothing to brace)")
		return

	# Add cross supports between legs (apron) - thinner plastic
	var apron_thickness = table_size * 0.025
	var apron_height = table_size * 0.05

	# Find actual tabletop position to place apron just below it
	var tabletop_solid = _find_cubes_by_role("tabletop_solid")
	var apron_y = table_size * 0.42  # Default fallback
	if not tabletop_solid.is_empty():
		var tabletop_node = tabletop_solid[0].node as MeshInstance3D
		if tabletop_node and tabletop_node.mesh:
			var tabletop_box = tabletop_node.mesh as BoxMesh
			if tabletop_box:
				# Position apron just below tabletop
				apron_y = tabletop_node.position.y - tabletop_box.size.y / 2.0 - apron_height

	# SHORT-CIRCUIT at the shipped rule rather than deriving. The literal 0.35 is
	# NOT where the corner legs actually stand — those sit at table_size / 3 —
	# so deriving the inset for every keep would move the apron of the three
	# existing placements by 0.017 * table_size. The other keeps have no shipped
	# number to preserve, so they read theirs off the legs they actually have.
	var leg_inset = table_size * 0.35
	if keep != "corners":
		var placed_legs = _find_cubes_by_role("leg")
		if placed_legs.is_empty():
			placed_legs = _find_cubes_by_role("leg_top")
		var reach: float = 0.0
		for cube_data in placed_legs:
			var leg_node = cube_data.node as Node3D
			if leg_node:
				reach = maxf(reach, maxf(absf(leg_node.position.x), absf(leg_node.position.z)))
		if reach > 0.001:
			leg_inset = reach

	# Front apron
	_create_cube(
		Vector3(0, apron_y, leg_inset),
		Vector3(table_size * 0.65, apron_height, apron_thickness),
		3, "apron"
	)

	# Back apron
	_create_cube(
		Vector3(0, apron_y, -leg_inset),
		Vector3(table_size * 0.65, apron_height, apron_thickness),
		3, "apron"
	)

	# Left apron
	_create_cube(
		Vector3(-leg_inset, apron_y, 0),
		Vector3(apron_thickness, apron_height, table_size * 0.65),
		3, "apron"
	)

	# Right apron
	_create_cube(
		Vector3(leg_inset, apron_y, 0),
		Vector3(apron_thickness, apron_height, table_size * 0.65),
		3, "apron"
	)

	print("Step 4: Added apron supports (thin plastic)")


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
	step = 0
	timer = 0.0

	# Follow the flag in BOTH directions. Leaving is_animating true after a rebuild
	# into the instant path would let _process re-run steps 1-4 from step 0 on top
	# of an already-finished table and double every part.
	is_animating = show_animation
	if show_animation:
		_step_0_initial_cube()
	else:
		_build_instant()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Map tokens reach the DNA through here. Nothing is torn down unless a value
## this table owns ACTUALLY changed and _ready has already built once — the bare
## `recursive_table` tokens in Fractal_Recursion, Hangar_Fractals_Walk and
## Proto_Fractal_Recursion never get past the first line.
func apply_grid_config(config: Dictionary) -> void:
	if config == null or config.is_empty():
		return

	var changed: bool = false

	if config.has("keep"):
		var want_keep: String = str(config["keep"]).strip_edges().to_lower()
		if KEEP_VALUES.has(want_keep) and want_keep != keep:
			keep = want_keep
			changed = true

	if config.has("assembly"):
		var want: String = str(config["assembly"]).strip_edges().to_lower()
		if ASSEMBLY_VALUES.has(want) and want != assembly:
			assembly = want
			changed = true

	if config.has("table_size"):
		var s: float = float(config["table_size"])
		if s > 0.0 and not is_equal_approx(s, table_size):
			table_size = s
			changed = true

	if config.has("step_delay"):
		var d: float = maxf(0.0, float(config["step_delay"]))
		if not is_equal_approx(d, step_delay):
			step_delay = d
			# Pure timing — nothing standing has to be torn down for it.

	if config.has("show_animation"):
		var raw: Variant = config["show_animation"]
		var flag: bool = false
		if raw is String:
			flag = str(raw).strip_edges().to_lower() in ["true", "1", "yes"]
		else:
			flag = bool(raw)
		if flag != show_animation:
			show_animation = flag
			changed = true

	if changed and _built:
		reset()
