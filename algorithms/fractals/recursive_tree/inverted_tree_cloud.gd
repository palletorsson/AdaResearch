extends Node3D

## Inverted Recursive Tree - Geometric blocks pointing down with animated cube cloud
## Uses the same geometric style as the original tree but inverted
## Animated rectangular cube cloud appears above in a timeline

# @identity
# essence: tree(depth) = trunk_down + branches_down(random_angle, shrink) + cube_cloud(orbit, fade_timeline)
# desire: To unsettle — roots reaching down from the sky while a cloud of cubes orbits and pulses above
# critical_parameter: vertical_tilt range (-0.5 to -0.2) — controls how steeply branches plunge downward
# triggers: Recursive branch generation with random angles; cube cloud timeline loops with fade-in/out per cube
# emerges: The cube cloud feels alive — independent orbit speeds and fade offsets create the illusion of breathing
# needs: VR gravity toggle [missing], cloud interaction [missing]
# relationships: Inverts recursive_tree; the cloud above mirrors what roots extract below — visual metaphor for data flow
# truth: An inverted tree is not wrong — it is a root system, and roots are where the real computation happens.

@export_category("Inverted Tree Structure")
@export var num_main_branches: int = 5
@export var max_sub_branches: int = 4
@export var branch_length_min: float = 1.5
@export var branch_length_max: float = 4.0
@export var branch_width_min: float = 0.8
@export var branch_width_max: float = 2.5
@export var branch_height_min: float = 0.8
@export var branch_height_max: float = 2.5
@export var trunk_height: float = 5.0
@export var trunk_width: float = 1.5

@export_category("Tree Appearance")
@export_color_no_alpha var primary_color: Color = Color(0.95, 0.3, 0.3)
@export_color_no_alpha var secondary_color: Color = Color(0.85, 0.2, 0.2)
@export_color_no_alpha var trunk_color: Color = Color(0.8, 0.3, 0.3)
@export var metallic: float = 0.1
@export var roughness: float = 0.7
@export var emission_strength: float = 0.2

@export_category("Cube Cloud")
@export var cloud_start_height: float = 8.0
@export var cloud_center_cube_size: float = 2.0
@export var cloud_sub_cubes: int = 12
@export var cloud_sub_cube_size_min: float = 0.5
@export var cloud_sub_cube_size_max: float = 1.5
@export var cloud_orbit_radius: float = 4.0
@export var cloud_animation_duration: float = 8.0  # Timeline duration in seconds
@export var cloud_color: Color = Color(0.7, 0.85, 1.0, 0.8)

@export_category("Settings")
@export var random_seed: int = 42

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `aftermath`
# ═══════════════════════════════════════════════════════════════════════════
#
# Growth is a process and a still cannot hold a process. What a still CAN hold
# is what the growing LEFT. This tree's growing is a recursion that runs
# DOWNWARD — a call that forks into calls until the depth runs out, plunging
# instead of reaching — so what it leaves is a stack of generations and a volume
# it happened to occupy under the ground it hangs from. The axis is how much of
# that the finished sculpture is still willing to show.
#
# ADOPTED WORD FOR WORD, AND FROM THE SAME FOLDER: recursive_tree.gd sits beside
# this file and already carries `aftermath` with exactly these four values in
# exactly this order. The two artifacts are one recursion and its inversion, so
# a room can ask them the same question and read the two answers against each
# other. branching_growth_algorithm and space_colonization_algorithm carry the
# five-value form of the same word; like recursive_tree this one has no attractor
# cloud to show, so it takes the four-value list rather than inventing a fifth
# meaning for `field`.
#
#   form       the root system alone, in its own three reds, with the cube cloud
#              breathing above it. A result, not a record.
#              (DEFAULT — today's picture, unchanged)
#   strata     nothing added: every box repainted by the recursion depth that
#              made it — trunk, first fork, second, tips — so the call stack is
#              legible as colour running DOWN the object instead of up it.
#   envelope   the tree plus a wire box on the volume its branches actually
#              reached, drawn as a claim about extent. The cloud is deliberately
#              outside it: the cloud was placed, not grown.
#   apparatus  the envelope plus a mark where the trunk hands off to the first
#              fork and a mark at every terminal the recursion could not continue
#              past. The sculpture staged as a demonstration of where the calls
#              stopped.
#
# STRICTLY ADDITIVE and RNG-FREE. _apply_aftermath() runs at the END of _ready(),
# after every rng call in build_inverted_tree(), reads the finished scene graph
# by node name, and returns immediately at `form`. It draws no random number, so
# the seeded tree is bit-identical at all four values.
const AFTERMATH_VALUES := ["form", "strata", "envelope", "apparatus"]
@export_enum("form", "strata", "envelope", "apparatus") var aftermath: String = "form"

## Untyped and NOT exported on purpose: sweep fixtures assign this directly
## pre-_ready as the string "true", and a typed bool silently rejects that.
##
## false (the default, and what every existing placement gets) = today exactly:
## the cube cloud keeps orbiting and fading on its 8 s timeline. true runs the
## timeline ONCE at FREEZE_PHASE and then leaves it alone. A sweep must pin this:
## which of the thirteen cubes is lit, and where each has orbited to, depends
## entirely on when the shutter fired, and four captures of the SAME aftermath
## taken a second apart are four different clouds. The critic would report the
## wall clock as an axis.
var freeze_cloud = false

## 2.0 s into the 8 s timeline: the centre cube and roughly five orbiters are at
## or near full opacity, with two mid-fade. Picked because t = 0 has every cube
## at the START of its fade-in, which is opacity 0 — a frozen cloud at zero
## phase is no cloud at all.
const FREEZE_PHASE := 2.0

const AFT_WIRE := Color(0.45, 0.70, 1.0)
const AFT_JOINT := Color(1.0, 0.90, 0.35)
const AFT_TERMINAL := Color(0.30, 1.0, 0.62)
## Trunk, first fork, second, tips — read downward, the direction this one grows.
const STRATA_BANDS := [
	Color(0.16, 0.14, 0.38),
	Color(0.28, 0.46, 0.86),
	Color(0.35, 0.86, 0.72),
	Color(1.0, 0.86, 0.28),
]
## The tree spans roughly 9 m by 13 m, so a 0.15 m mark of the kind
## branching_growth_algorithm uses in a 3 m field would cover well under a
## percent of the frame and a real axis would be reported as decoration.
const MARK_RADIUS := 0.35

## Marks and cages built by the non-default values, freed before a rebuild.
var _aftermath_parts: Array[Node3D] = []
## instance_id -> the material_override a box had at `form`, populated only when
## `strata` paints over them.
var _original_mats: Dictionary = {}

# Materials
var primary_material: StandardMaterial3D
var secondary_material: StandardMaterial3D
var trunk_material: StandardMaterial3D
var cloud_material: StandardMaterial3D

# Internal state
var rng: RandomNumberGenerator
var cloud_cubes: Array = []
var animation_time: float = 0.0
## True once the frozen cloud has been placed at FREEZE_PHASE.
var _cloud_frozen: bool = false

func _ready() -> void:
	_read_dna()
	rng = RandomNumberGenerator.new()
	rng.seed = random_seed

	create_materials()
	build_inverted_tree()

	# APPENDED LAST, after every rng call in build_inverted_tree(). Reads the
	# finished scene graph and draws nothing of its own at the default.
	_apply_aftermath()

func create_materials() -> void:
	"""Create materials matching the original tree style"""
	# Primary material
	primary_material = StandardMaterial3D.new()
	primary_material.albedo_color = primary_color
	primary_material.metallic = metallic
	primary_material.roughness = roughness
	primary_material.emission_enabled = true
	primary_material.emission = primary_color
	primary_material.emission_energy_multiplier = emission_strength

	# Secondary material
	secondary_material = StandardMaterial3D.new()
	secondary_material.albedo_color = secondary_color
	secondary_material.metallic = metallic
	secondary_material.roughness = roughness
	secondary_material.emission_enabled = true
	secondary_material.emission = secondary_color
	secondary_material.emission_energy_multiplier = emission_strength * 0.7

	# Trunk material
	trunk_material = StandardMaterial3D.new()
	trunk_material.albedo_color = trunk_color
	trunk_material.metallic = metallic
	trunk_material.roughness = roughness + 0.1
	trunk_material.emission_enabled = true
	trunk_material.emission = trunk_color
	trunk_material.emission_energy_multiplier = emission_strength * 0.5

	# Cloud material
	cloud_material = StandardMaterial3D.new()
	cloud_material.albedo_color = cloud_color
	cloud_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud_material.emission_enabled = true
	cloud_material.emission = Color(cloud_color.r, cloud_color.g, cloud_color.b)
	cloud_material.emission_energy_multiplier = 1.0
	cloud_material.cull_mode = BaseMaterial3D.CULL_DISABLED

func build_inverted_tree() -> void:
	"""Build the inverted tree structure"""
	var tree_root = Node3D.new()
	tree_root.name = "InvertedGeometricTree"
	add_child(tree_root)

	# Create trunk pointing down
	var trunk = create_inverted_trunk()
	tree_root.add_child(trunk)

	# Generate branches pointing downward
	var branch_origin = Vector3(0, 0, 0)  # Start at top
	generate_inverted_branches(tree_root, branch_origin, num_main_branches, 0, 3)

	# Create animated cube cloud above
	create_cube_cloud()

func create_inverted_trunk() -> Node3D:
	"""Create trunk pointing downward with geometric blocks"""
	var trunk_node = Node3D.new()
	trunk_node.name = "InvertedTrunk"

	# Main trunk block pointing down
	var trunk_mesh = BoxMesh.new()
	trunk_mesh.size = Vector3(trunk_width, trunk_height, trunk_width)

	var trunk_instance = MeshInstance3D.new()
	trunk_instance.mesh = trunk_mesh
	trunk_instance.material_override = trunk_material
	trunk_instance.position.y = -trunk_height / 2  # Pointing down

	trunk_node.add_child(trunk_instance)

	# Add detail blocks to trunk
	var num_details = rng.randi() % 4 + 1
	for i in range(num_details):
		var detail = MeshInstance3D.new()
		var detail_mesh = BoxMesh.new()

		var detail_size = Vector3(
			trunk_width * rng.randf_range(0.3, 0.6),
			trunk_width * rng.randf_range(0.3, 0.6),
			trunk_width * rng.randf_range(0.3, 0.6)
		)
		detail_mesh.size = detail_size
		detail.mesh = detail_mesh

		# Position on trunk
		var height_pos = rng.randf_range(-trunk_height + trunk_width, -trunk_width)
		var angle = rng.randf_range(0, TAU)
		var radius = trunk_width / 2 * 0.9

		detail.position = Vector3(
			cos(angle) * radius,
			height_pos,
			sin(angle) * radius
		)

		detail.material_override = primary_material if rng.randf() > 0.3 else secondary_material
		trunk_node.add_child(detail)

	return trunk_node

func generate_inverted_branches(parent: Node, origin_point: Vector3, num_branches: int, current_depth: int, max_depth: int) -> void:
	"""Recursively generate branches pointing downward"""
	if current_depth >= max_depth:
		return

	for i in range(num_branches):
		var branch = Node3D.new()
		branch.name = "InvertedBranch_" + str(current_depth) + "_" + str(i)
		parent.add_child(branch)

		# Branch dimensions (shrinking with depth)
		var branch_width = rng.randf_range(branch_width_min, branch_width_max) * (1.0 - current_depth * 0.2)
		var branch_height = rng.randf_range(branch_height_min, branch_height_max) * (1.0 - current_depth * 0.2)
		var branch_length = rng.randf_range(branch_length_min, branch_length_max) * (1.0 - current_depth * 0.15)

		# Create branch mesh
		var branch_mesh = BoxMesh.new()
		branch_mesh.size = Vector3(branch_width, branch_height, branch_length)

		var branch_instance = MeshInstance3D.new()
		branch_instance.mesh = branch_mesh
		branch_instance.material_override = primary_material if rng.randf() > 0.3 else secondary_material

		# Direction pointing downward and outward
		var angle = rng.randf_range(0, TAU)
		var vertical_tilt = rng.randf_range(-0.5, -0.2)  # Negative for downward

		var direction = Vector3(
			cos(angle),
			vertical_tilt,
			sin(angle)
		).normalized()

		# Position branch
		var distance_from_origin = branch_length / 2
		var position = origin_point + direction * distance_from_origin
		branch_instance.position = position

		# Orient branch
		branch_instance.look_at_from_position(branch_instance.position, position + direction, Vector3.UP)

		branch.add_child(branch_instance)

		# Add detail blocks
		if rng.randf() > 0.4:
			add_inverted_detail_blocks(branch, branch_instance, branch_mesh.size)

		# Calculate end point for sub-branches
		var end_point = position + direction * (branch_length / 2)

		# Generate sub-branches
		var num_sub = rng.randi() % (max_sub_branches - current_depth) + 1
		if current_depth < 2:
			num_sub = rng.randi() % max_sub_branches + 2

		generate_inverted_branches(branch, end_point, num_sub, current_depth + 1, max_depth)

func add_inverted_detail_blocks(parent_node: Node, branch_instance: MeshInstance3D, branch_size: Vector3) -> void:
	"""Add detail blocks to inverted branches"""
	var num_details = rng.randi() % 3 + 1

	for i in range(num_details):
		var detail = MeshInstance3D.new()
		var detail_mesh = BoxMesh.new()

		var scale_factor = rng.randf_range(0.2, 0.5)
		var detail_size = Vector3(
			branch_size.x * scale_factor,
			branch_size.y * scale_factor,
			branch_size.z * scale_factor
		)
		detail_mesh.size = detail_size
		detail.mesh = detail_mesh

		# Position on branch surface
		var axis = rng.randi() % 3
		var sign_factor = 1 if rng.randf() > 0.5 else -1
		var relative_position = Vector3.ZERO

		match axis:
			0:
				relative_position.x = sign_factor * (branch_size.x / 2 + detail_size.x / 2 * 0.8)
				relative_position.y = rng.randf_range(-0.4, 0.4) * branch_size.y
				relative_position.z = rng.randf_range(-0.4, 0.4) * branch_size.z
			1:
				relative_position.x = rng.randf_range(-0.4, 0.4) * branch_size.x
				relative_position.y = sign_factor * (branch_size.y / 2 + detail_size.y / 2 * 0.8)
				relative_position.z = rng.randf_range(-0.4, 0.4) * branch_size.z
			2:
				relative_position.x = rng.randf_range(-0.4, 0.4) * branch_size.x
				relative_position.y = rng.randf_range(-0.4, 0.4) * branch_size.y
				relative_position.z = sign_factor * (branch_size.z / 2 + detail_size.z / 2 * 0.8)

		var global_transform = branch_instance.global_transform
		detail.position = branch_instance.to_local(global_position + global_transform.basis * relative_position)
		detail.rotation = branch_instance.rotation

		detail.material_override = secondary_material if rng.randf() > 0.4 else primary_material
		parent_node.add_child(detail)

func create_cube_cloud() -> void:
	"""Create animated cube cloud above the tree"""
	var cloud_root = Node3D.new()
	cloud_root.name = "CubeCloud"
	cloud_root.position.y = cloud_start_height
	add_child(cloud_root)

	# Center cube
	var center_cube = create_cloud_cube(cloud_center_cube_size)
	center_cube.position = Vector3.ZERO
	cloud_root.add_child(center_cube)

	cloud_cubes.append({
		"node": center_cube,
		"start_time": 0.0,
		"duration": cloud_animation_duration,
		"orbit_radius": 0.0,
		"orbit_angle": 0.0,
		"is_center": true
	})

	# Orbiting sub-cubes
	for i in range(cloud_sub_cubes):
		var cube_size = rng.randf_range(cloud_sub_cube_size_min, cloud_sub_cube_size_max)
		var cube = create_cloud_cube(cube_size)

		var orbit_angle = (i / float(cloud_sub_cubes)) * TAU
		var orbit_radius = cloud_orbit_radius * rng.randf_range(0.6, 1.0)

		# Timeline start offset
		var start_time = (i / float(cloud_sub_cubes)) * cloud_animation_duration

		cube.position = Vector3(
			cos(orbit_angle) * orbit_radius,
			rng.randf_range(-1.0, 1.0),
			sin(orbit_angle) * orbit_radius
		)

		cloud_root.add_child(cube)

		cloud_cubes.append({
			"node": cube,
			"start_time": start_time,
			"duration": cloud_animation_duration,
			"orbit_radius": orbit_radius,
			"orbit_angle": orbit_angle,
			"is_center": false,
			"base_y": cube.position.y
		})

func create_cloud_cube(size: float) -> MeshInstance3D:
	"""Create a rectangular cube for the cloud"""
	var cube = MeshInstance3D.new()

	var box = BoxMesh.new()
	box.size = Vector3(size, size, size)

	cube.mesh = box
	cube.material_override = cloud_material

	return cube

func _process(delta: float) -> void:
	# A frozen cloud is placed once at FREEZE_PHASE and then left alone, so a
	# still of it is the same still whenever the shutter fires.
	if freeze_cloud:
		if _cloud_frozen:
			return
		_cloud_frozen = true
		animation_time = FREEZE_PHASE
	else:
		animation_time += delta

	# Animate cube cloud with timeline
	for cube_data in cloud_cubes:
		var node = cube_data["node"]
		var start_time = cube_data["start_time"]
		var duration = cube_data["duration"]

		# Calculate timeline progress (loops)
		var timeline_time = fmod(animation_time, duration)

		# Calculate visibility based on timeline
		var time_since_start = timeline_time - start_time
		if time_since_start < 0:
			time_since_start += duration

		# Fade in/out window
		var fade_duration = duration * 0.15  # 15% of timeline for fade
		var visible_duration = duration * 0.5  # Visible for 50% of timeline

		var opacity = 0.0
		if time_since_start < fade_duration:
			# Fade in
			opacity = time_since_start / fade_duration
		elif time_since_start < visible_duration:
			# Fully visible
			opacity = 1.0
		elif time_since_start < visible_duration + fade_duration:
			# Fade out
			opacity = 1.0 - ((time_since_start - visible_duration) / fade_duration)
		else:
			# Invisible
			opacity = 0.0

		# Apply opacity to material
		if node.material_override and opacity > 0:
			var mat = node.material_override as StandardMaterial3D
			mat.albedo_color.a = cloud_color.a * opacity
			mat.emission_energy_multiplier = 1.0 * opacity
			node.visible = true
		else:
			node.visible = false

		# Animate position for non-center cubes
		if not cube_data["is_center"]:
			var orbit_radius = cube_data["orbit_radius"]
			var base_angle = cube_data["orbit_angle"]
			var base_y = cube_data["base_y"]

			# Orbit animation
			var orbit_speed = 0.3
			var current_angle = base_angle + animation_time * orbit_speed

			node.position = Vector3(
				cos(current_angle) * orbit_radius,
				base_y + sin(animation_time * 0.5) * 0.5,
				sin(current_angle) * orbit_radius
			)

func rebuild() -> void:
	"""Clear and rebuild the entire structure"""
	for child in get_children():
		child.queue_free()

	cloud_cubes.clear()
	animation_time = 0.0

	create_materials()
	build_inverted_tree()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	var was: String = aftermath
	_read_dna()
	if aftermath != was:
		_apply_aftermath()


# ═══════════════════════════════════════════════════════════════════════════
# aftermath — everything below is new and nothing above it moved.
# ═══════════════════════════════════════════════════════════════════════════

## Map tokens arrive as config_<key> metadata. An unreadable word keeps the
## shipped root system rather than staging an exhibit nobody asked for.
func _read_dna() -> void:
	if has_meta("config_aftermath"):
		var v: String = str(get_meta("config_aftermath")).strip_edges().to_lower()
		if AFTERMATH_VALUES.has(v):
			aftermath = v
	if has_meta("config_freeze_cloud"):
		var f: String = str(get_meta("config_freeze_cloud")).strip_edges().to_lower()
		freeze_cloud = f == "true" or f == "1" or f == "yes"


func _apply_aftermath() -> void:
	for part in _aftermath_parts:
		if is_instance_valid(part):
			part.queue_free()
	_aftermath_parts.clear()
	_restore_form_materials()

	var key: String = str(aftermath).strip_edges().to_lower()
	if not AFTERMATH_VALUES.has(key):
		key = "form"
	if key == "form":
		return

	if key == "strata":
		_paint_strata()
		return

	# envelope and apparatus both draw the cage.
	_draw_envelope()
	if key == "apparatus":
		_draw_marks()


## Every branch box repainted by the recursion depth that made it. Depth is read
## off the node names build_inverted_tree already writes — "InvertedBranch_<d>_<i>"
## and "InvertedTrunk" — so the build path is untouched and nothing has to be
## threaded through the recursion.
func _paint_strata() -> void:
	for entry in _walk_boxes():
		var mi: MeshInstance3D = entry["mesh"]
		var depth: int = entry["depth"]
		if not _original_mats.has(mi.get_instance_id()):
			_original_mats[mi.get_instance_id()] = mi.material_override
		var band: Color = STRATA_BANDS[mini(depth, STRATA_BANDS.size() - 1)]
		var mat := StandardMaterial3D.new()
		mat.albedo_color = band
		mat.metallic = metallic
		mat.roughness = roughness
		mat.emission_enabled = true
		mat.emission = band
		mat.emission_energy_multiplier = emission_strength
		mi.material_override = mat


func _restore_form_materials() -> void:
	if _original_mats.is_empty():
		return
	for id in _original_mats.keys():
		var obj = instance_from_id(id)
		if obj != null and is_instance_valid(obj) and obj is MeshInstance3D:
			var mi: MeshInstance3D = obj
			mi.material_override = _original_mats[id]
	_original_mats.clear()


## A wire box on the volume the branches actually reached. The cube cloud is
## excluded on purpose: the cloud was placed at a declared height, it was not
## grown, and a cage that swallowed it would be a claim about the wrong thing.
func _draw_envelope() -> void:
	var bounds: AABB = _branch_bounds()
	if bounds.size.length() <= 0.001:
		return

	var mat := StandardMaterial3D.new()
	mat.albedo_color = AFT_WIRE
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	var corners: Array[Vector3] = []
	for i in range(8):
		corners.append(bounds.position + Vector3(
			bounds.size.x * float(i & 1),
			bounds.size.y * float((i >> 1) & 1),
			bounds.size.z * float((i >> 2) & 1)))
	# The twelve edges of a box: each pair of corners differing in one bit.
	for a in range(8):
		for b in range(a + 1, 8):
			var diff: int = a ^ b
			if diff == 1 or diff == 2 or diff == 4:
				im.surface_add_vertex(corners[a])
				im.surface_add_vertex(corners[b])
	im.surface_end()

	var mi := MeshInstance3D.new()
	mi.name = "AftermathEnvelope"
	mi.mesh = im
	mi.material_override = mat
	add_child(mi)
	_aftermath_parts.append(mi)


## The handoff and the stops: one big mark at the origin where the trunk gives
## the recursion to its first fork, and one at every box the recursion could not
## continue past — the deepest generation in the tree.
func _draw_marks() -> void:
	var boxes: Array = _walk_boxes()
	var deepest: int = 0
	for entry in boxes:
		deepest = maxi(deepest, entry["depth"])

	_add_mark(Vector3.ZERO, MARK_RADIUS * 1.8, AFT_JOINT)
	for entry in boxes:
		# rank 0 only: the branch block itself, not the decorative cubes bolted
		# to it. Marking every box would put a few hundred spheres on the tips
		# and the picture would be of the marks, not of where the calls stopped.
		if entry["depth"] != deepest or entry["rank"] != 0:
			continue
		var mi: MeshInstance3D = entry["mesh"]
		_add_mark(to_local(mi.global_position), MARK_RADIUS, AFT_TERMINAL)


func _add_mark(local_pos: Vector3, radius: float, tint: Color) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = 0.8
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mi := MeshInstance3D.new()
	mi.name = "AftermathMark"
	mi.mesh = sphere
	mi.material_override = mat
	mi.position = local_pos
	add_child(mi)
	_aftermath_parts.append(mi)


## Every branch/trunk box with the recursion depth that made it. Depth 0 is the
## trunk; an "InvertedBranch_<d>_<i>" ancestor contributes depth d + 1.
func _walk_boxes() -> Array:
	var out: Array = []
	var tree_root: Node = get_node_or_null("InvertedGeometricTree")
	if tree_root == null:
		return out
	_collect_boxes(tree_root, 0, out)
	return out


func _collect_boxes(node: Node, depth: int, out: Array) -> void:
	var next_depth: int = depth
	# StringName, not String — converted so begins_with/split are available.
	var raw_name: String = String(node.name)
	if raw_name.begins_with("InvertedBranch_"):
		var parts: PackedStringArray = raw_name.split("_")
		if parts.size() >= 2 and parts[1].is_valid_int():
			next_depth = int(parts[1]) + 1
	# `rank` is the order among a node's own mesh children: build order puts the
	# branch block first and its detail cubes after it, so rank 0 is the branch.
	var rank: int = 0
	for child in node.get_children():
		if child is MeshInstance3D:
			out.append({"mesh": child, "depth": next_depth, "rank": rank})
			rank += 1
		_collect_boxes(child, next_depth, out)


## The AABB of the built branches, in this node's local space.
func _branch_bounds() -> AABB:
	var bounds := AABB()
	var first := true
	for entry in _walk_boxes():
		var mi: MeshInstance3D = entry["mesh"]
		var local_aabb: AABB = mi.get_aabb()
		var basis_world: Transform3D = global_transform.affine_inverse() * mi.global_transform
		for i in range(8):
			var corner: Vector3 = basis_world * (local_aabb.position + Vector3(
				local_aabb.size.x * float(i & 1),
				local_aabb.size.y * float((i >> 1) & 1),
				local_aabb.size.z * float((i >> 2) & 1)))
			if first:
				bounds = AABB(corner, Vector3.ZERO)
				first = false
			else:
				bounds = bounds.expand(corner)
	return bounds
