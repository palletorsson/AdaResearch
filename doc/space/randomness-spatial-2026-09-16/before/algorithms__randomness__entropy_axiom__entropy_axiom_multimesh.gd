extends Node3D

# Entropy Visualization: Order → Chaos (MultiMesh Version)
# Static visualization - much more efficient than individual instances
# 10x10x40 grid = 4000 instances in a single draw call
#
# @identity
# essence: S = -Σ p_i log p_i — Shannon entropy as spatial gradient
# desire: walk along the z-axis and watch order dissolve into chaos before your eyes
# critical_parameter: max_randomness — controls displacement amplitude at the chaos end
# triggers: z-position of each sphere determines its entropy factor via exponential curve
# emerges: the blue-to-red color gradient makes the arrow of entropy visible as a thermodynamic landscape
# needs: VR walkthrough [has via grid placement]; no controls needed — it is contemplative
# relationships: anchors random_butterflies (they land on its grid); unlocks entropy_jar
# truth: Entropy is not disorder — it is the number of ways a system can be without you noticing.

@export var grid_size_x: int = 10
@export var grid_size_y: int = 10
@export var grid_size_z: int = 40
@export var base_spacing: float = 0.2
@export var max_randomness: float = 0.5
@export var min_randomness: float = 0.0
@export var point_radius: float = 0.018
@export var show_bounds_frame: bool = true
@export var frame_thickness: float = 0.012
@export var frame_padding: float = 0.05
@export var frame_color: Color = Color(0.95, 0.98, 1.0, 0.8)
@export var frame_emission_color: Color = Color(0.6, 0.8, 1.0, 1.0)
@export var frame_emission_energy: float = 1.6

# --- DNA (stage 2, promoted 2026-08-03) -------------------------------------
# onset: WHERE along the corridor order gives way. pow(entropy_factor, 2.0) was
#   a bare literal with the comment "for dramatic increase toward the end", and
#   that exponent is not a styling choice - it is the artifact's whole claim
#   about how entropy arrives. At "late" the lattice holds for two thirds of the
#   walk and then collapses; at "even" disorder accrues at a constant rate and
#   there is no moment; at "early" the grid is lost in the first few steps and
#   the rest of the corridor is already cloud; at "phase" order holds, snaps
#   through a narrow band and saturates - a transition rather than a slope. The
#   same curve drives the hue ramp, so the colour moves with the drift.
# bounds: what the container claims. The shipped frame is ONE box sized to the
#   worst case, which quietly asserts that the ordered end lives in the same
#   volume as the chaotic end - a fair reading of the truth line (the number of
#   ways the system could be), but the only reading on offer. "slabs" draws the
#   volume the points ACTUALLY occupy band by band, so the phase space is seen
#   widening; "none" removes the claim entirely and leaves the points to argue
#   alone.
# random_seed is NOT an axis - it is the fixture knob. The jitter is drawn from
#   the global unseeded RNG, so two renders of the same value are two different
#   objects and any sweep of onset would be measuring the draw as much as the
#   curve. 0 keeps the shipped unseeded behaviour; the gallery pins it.
const ONSETS := ["late", "even", "early", "phase"]
const BOUNDS_MODES := ["box", "none", "slabs"]
const SLAB_COUNT := 8

@export_enum("late", "even", "early", "phase") var onset: String = "late"
@export_enum("box", "none", "slabs") var bounds: String = "box"
@export var random_seed: int = 0

var multimesh_instance: MultiMeshInstance3D
var frame_root: Node3D

# True once _ready has built. apply_grid_config must never rebuild before that,
# and never when nothing changed - the 9 shipped placements must not be rebuilt
# by this function merely existing.
var _built: bool = false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("entropy_axiom")
	create_multimesh()
	generate_entropy_grid()
	create_bounds_frame()
	_built = true

func create_multimesh() -> void:
	# Create MultiMeshInstance3D node
	multimesh_instance = MultiMeshInstance3D.new()
	add_child(multimesh_instance)

	# Create MultiMesh resource
	var multimesh = MultiMesh.new()
	multimesh_instance.multimesh = multimesh

	# IMPORTANT: Set transform format to 3D BEFORE setting instance count
	multimesh.transform_format = MultiMesh.TRANSFORM_3D

	# Enable per-instance colors BEFORE setting instance count
	multimesh.use_colors = true

	# Create sphere mesh
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = point_radius
	sphere_mesh.height = point_radius * 2.0
	sphere_mesh.radial_segments = 16
	sphere_mesh.rings = 8

	# Assign mesh to multimesh
	multimesh.mesh = sphere_mesh

	# Set instance count (must be done AFTER transform_format and use_colors)
	var total_instances = grid_size_x * grid_size_y * grid_size_z
	multimesh.instance_count = total_instances

	# Create emissive material for visibility
	var material = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission_energy_multiplier = 0.8
	multimesh_instance.material_override = material

func _entropy_curve(factor: float) -> float:
	# How the entropy factor rises with z. "late" is the shipped literal.
	match onset:
		"even":
			return factor
		"early":
			return sqrt(factor)
		"phase":
			return smoothstep(0.4, 0.6, factor)
	return pow(factor, 2.0)

func _jitter(amount: float) -> float:
	# random_seed = 0 keeps the shipped global-RNG draw untouched, so a placement
	# that says nothing about the seed scatters exactly as it always has.
	if random_seed != 0:
		return _rng.randf_range(-amount, amount)
	return randf_range(-amount, amount)

func generate_entropy_grid() -> void:
	var multimesh = multimesh_instance.multimesh
	var instance_index = 0

	if random_seed != 0:
		_rng.seed = random_seed

	for z in range(grid_size_z):
		for y in range(grid_size_y):
			for x in range(grid_size_x):
				# Calculate entropy factor (0.0 at z=0, 1.0 at z=max)
				var entropy_factor = float(z) / float(grid_size_z - 1)

				# Apply the onset curve. "late" is pow(entropy_factor, 2.0) —
				# the original exponential increase toward the end.
				var curved_entropy = _entropy_curve(entropy_factor)

				# Base grid position
				var base_x = (x - grid_size_x / 2.0) * base_spacing
				var base_y = (y - grid_size_y / 2.0) * base_spacing
				var base_z = z * base_spacing

				# Randomness scales from 0 (perfect order) to max (chaos)
				var randomness_amount = lerp(min_randomness, max_randomness, curved_entropy)
				var random_offset_x = _jitter(randomness_amount)
				var random_offset_y = _jitter(randomness_amount)

				# Final position
				var position = Vector3(
					base_x + random_offset_x,
					base_y + random_offset_y,
					base_z
				)

				# Create transform for this instance
				var transform = Transform3D()
				transform.origin = position
				multimesh.set_instance_transform(instance_index, transform)

				# Set color for this instance
				var color = get_entropy_color(curved_entropy)
				multimesh.set_instance_color(instance_index, color)

				instance_index += 1

func get_entropy_color(entropy_factor: float) -> Color:
	# Color gradient representing entropy increase
	# Low entropy (0.0) = Blue (cold, ordered, low energy)
	# Mid entropy (0.5) = Magenta (transition)
	# High entropy (1.0) = Red (hot, chaotic, high energy)

	# Use HSV: Hue from 240° (blue) through 300° (magenta) to 0° (red)
	var hue = lerp(0.66, 0.0, entropy_factor)  # 0.66 = blue, 0.0 = red
	var saturation = 1.0
	var value = 1.0

	return Color.from_hsv(hue, saturation, value)

func create_bounds_frame() -> void:
	# show_bounds_frame stays the master switch it always was; bounds says which
	# claim the frame makes when it is on.
	if not show_bounds_frame or bounds == "none":
		return

	frame_root = Node3D.new()
	frame_root.name = "EntropyBoundsFrame"
	add_child(frame_root)

	if bounds == "slabs":
		_build_slab_frames()
		return

	var min_corner = _get_bounds_min()
	var max_corner = _get_bounds_max()
	_build_frame_edges(min_corner, max_corner)

func _build_slab_frames() -> void:
	# One box per z-band, each only as wide as the drift the points at that band
	# are actually allowed. The single shipped box is the union of these; drawn
	# separately they show the accessible volume opening along the corridor.
	var span: float = float(grid_size_z - 1) * base_spacing
	for i in SLAB_COUNT:
		var near_factor: float = float(i) / float(SLAB_COUNT)
		var far_factor: float = float(i + 1) / float(SLAB_COUNT)
		var drift: float = lerp(min_randomness, max_randomness, _entropy_curve(far_factor))
		var pad: float = drift + point_radius + frame_padding
		var min_corner := Vector3(
			(0.0 - grid_size_x / 2.0) * base_spacing - pad,
			(0.0 - grid_size_y / 2.0) * base_spacing - pad,
			near_factor * span - point_radius - frame_padding
		)
		var max_corner := Vector3(
			((grid_size_x - 1) - grid_size_x / 2.0) * base_spacing + pad,
			((grid_size_y - 1) - grid_size_y / 2.0) * base_spacing + pad,
			far_factor * span + point_radius + frame_padding
		)
		_build_frame_edges(min_corner, max_corner)

func _get_bounds_min() -> Vector3:
	var min_x = (0.0 - grid_size_x / 2.0) * base_spacing - max_randomness - point_radius - frame_padding
	var min_y = (0.0 - grid_size_y / 2.0) * base_spacing - max_randomness - point_radius - frame_padding
	var min_z = -point_radius - frame_padding
	return Vector3(min_x, min_y, min_z)

func _get_bounds_max() -> Vector3:
	var max_x = ((grid_size_x - 1) - grid_size_x / 2.0) * base_spacing + max_randomness + point_radius + frame_padding
	var max_y = ((grid_size_y - 1) - grid_size_y / 2.0) * base_spacing + max_randomness + point_radius + frame_padding
	var max_z = (grid_size_z - 1) * base_spacing + point_radius + frame_padding
	return Vector3(max_x, max_y, max_z)

func _build_frame_edges(min_corner: Vector3, max_corner: Vector3) -> void:
	var thickness = max(frame_thickness, 0.001)
	var size_x = max(max_corner.x - min_corner.x, thickness)
	var size_y = max(max_corner.y - min_corner.y, thickness)
	var size_z = max(max_corner.z - min_corner.z, thickness)

	var edge_mesh = BoxMesh.new()
	edge_mesh.size = Vector3.ONE

	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = frame_color
	material.emission_enabled = true
	material.emission = frame_emission_color
	material.emission_energy_multiplier = frame_emission_energy
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if frame_color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var cx = (min_corner.x + max_corner.x) * 0.5
	var cy = (min_corner.y + max_corner.y) * 0.5
	var cz = (min_corner.z + max_corner.z) * 0.5

	# 4 edges along X
	_add_frame_edge(edge_mesh, material, Vector3(cx, min_corner.y, min_corner.z), Vector3(size_x, thickness, thickness))
	_add_frame_edge(edge_mesh, material, Vector3(cx, min_corner.y, max_corner.z), Vector3(size_x, thickness, thickness))
	_add_frame_edge(edge_mesh, material, Vector3(cx, max_corner.y, min_corner.z), Vector3(size_x, thickness, thickness))
	_add_frame_edge(edge_mesh, material, Vector3(cx, max_corner.y, max_corner.z), Vector3(size_x, thickness, thickness))

	# 4 edges along Y
	_add_frame_edge(edge_mesh, material, Vector3(min_corner.x, cy, min_corner.z), Vector3(thickness, size_y, thickness))
	_add_frame_edge(edge_mesh, material, Vector3(min_corner.x, cy, max_corner.z), Vector3(thickness, size_y, thickness))
	_add_frame_edge(edge_mesh, material, Vector3(max_corner.x, cy, min_corner.z), Vector3(thickness, size_y, thickness))
	_add_frame_edge(edge_mesh, material, Vector3(max_corner.x, cy, max_corner.z), Vector3(thickness, size_y, thickness))

	# 4 edges along Z
	_add_frame_edge(edge_mesh, material, Vector3(min_corner.x, min_corner.y, cz), Vector3(thickness, thickness, size_z))
	_add_frame_edge(edge_mesh, material, Vector3(min_corner.x, max_corner.y, cz), Vector3(thickness, thickness, size_z))
	_add_frame_edge(edge_mesh, material, Vector3(max_corner.x, min_corner.y, cz), Vector3(thickness, thickness, size_z))
	_add_frame_edge(edge_mesh, material, Vector3(max_corner.x, max_corner.y, cz), Vector3(thickness, thickness, size_z))

func _add_frame_edge(mesh: Mesh, material: Material, center: Vector3, size: Vector3) -> void:
	var edge = MeshInstance3D.new()
	edge.mesh = mesh
	edge.material_override = material
	edge.position = center
	edge.scale = size
	frame_root.add_child(edge)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	# Guarded on both sides: a declared value has to actually differ, and _ready
	# has to have built once. A placement token naming none of these never
	# reaches _rebuild, so the 9 shipped placements are unaffected.
	var changed: bool = false

	if config.has("onset"):
		var want_onset: String = str(config["onset"]).strip_edges().to_lower()
		if ONSETS.has(want_onset) and want_onset != onset:
			onset = want_onset
			changed = true

	if config.has("bounds"):
		var want_bounds: String = str(config["bounds"]).strip_edges().to_lower()
		if BOUNDS_MODES.has(want_bounds) and want_bounds != bounds:
			bounds = want_bounds
			changed = true

	if config.has("random_seed"):
		var want_seed: int = int(config["random_seed"])
		if want_seed != random_seed:
			random_seed = want_seed
			changed = true

	if changed and _built:
		_rebuild()

func _rebuild() -> void:
	if is_instance_valid(multimesh_instance):
		multimesh_instance.queue_free()
	multimesh_instance = null
	if is_instance_valid(frame_root):
		frame_root.queue_free()
	frame_root = null

	create_multimesh()
	generate_entropy_grid()
	create_bounds_frame()
