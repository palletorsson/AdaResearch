# MobiusSpace.gd - Non-orientable topology as walkable surface
# A Möbius strip projected into a walkable terrain. The surface
# that has only one side — walk far enough and your "up" has
# rotated 180°. Orientation is an illusion the surface lets you keep.
#
# "You thought you were walking forward. You were walking upside down."

extends TopologySpace
class_name MobiusSpace

@export var strip_radius: float = 8.0      # Radius of the central ring
@export var strip_width: float = 4.0       # Width of the strip
@export var twist_count: int = 1           # 1 = Möbius, 2 = full twist, 3 = trefoil-like
@export var height_amplitude: float = 0.5  # Additional wave on the surface
@export var flatten_factor: float = 0.3    # How much to flatten for walkability (0=true Möbius, 1=flat ring)

# The Möbius strip is inherently 3D — we project it onto a height field
# by sampling the strip's Z coordinate as height, and X/Y as position.
# This loses the non-orientability but preserves the topology's feel.
@export var projection_mode: ProjectionMode = ProjectionMode.HEIGHT_MAP

enum ProjectionMode {
	HEIGHT_MAP,        # Project Z → height, distort for walkability
	UNROLLED,          # Unroll the strip flat with twist visible as height ripples
	CYLINDRICAL,       # Embed as a bumpy cylinder
}

func generate_space():
	var heights: Array = []
	var gs = resolution + 1

	match projection_mode:
		ProjectionMode.HEIGHT_MAP:
			heights = _generate_height_map(gs)
		ProjectionMode.UNROLLED:
			heights = _generate_unrolled(gs)
		ProjectionMode.CYLINDRICAL:
			heights = _generate_cylindrical(gs)

	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	_setup_material()

func _generate_height_map(gs: int) -> Array:
	"""Project the Möbius strip as a height field over the XZ plane"""
	var heights: Array = []

	for z in range(gs):
		for x in range(gs):
			var u = (x / float(resolution)) * space_size.x - space_size.x / 2.0
			var v = (z / float(resolution)) * space_size.y - space_size.y / 2.0

			# Convert to polar-ish coordinates
			var angle = atan2(v, u)  # -PI to PI
			var dist = sqrt(u * u + v * v)

			# Distance from the strip's center ring
			var ring_dist = abs(dist - strip_radius)

			if ring_dist < strip_width:
				# On the strip — compute Möbius height
				var s = (ring_dist / strip_width) * 2.0 - 1.0  # -1 to 1 across width
				var twist_angle = angle * float(twist_count) / 2.0

				# Möbius parametric Z
				var mobius_height = s * sin(twist_angle) * strip_width * 0.5

				# Flatten for walkability
				mobius_height = lerpf(mobius_height, 0.0, flatten_factor)

				# Add surface detail
				mobius_height += sin(angle * 3.0 + s * 2.0) * height_amplitude

				heights.append(mobius_height * height_scale)
			else:
				# Off the strip — gentle slope down
				var falloff = (ring_dist - strip_width) / strip_width
				heights.append(-falloff * height_scale * 0.5)

	return heights

func _generate_unrolled(gs: int) -> Array:
	"""Unroll the strip — X is angle around the loop, Z is width.
	   The twist appears as a height wave that's out of phase by half a period."""
	var heights: Array = []

	for z in range(gs):
		for x in range(gs):
			var theta = (x / float(resolution)) * TAU  # Full loop
			var s = (z / float(resolution)) * 2.0 - 1.0  # -1 to 1 width

			# The twist: at theta=0, s maps normally. At theta=2PI, s is inverted.
			var twist_angle = theta * float(twist_count) / 2.0
			var twisted_s = s * cos(twist_angle)

			var h = twisted_s * strip_width * 0.3
			h += sin(theta * 2.0) * height_amplitude * 0.5

			heights.append(h * height_scale)

	return heights

func _generate_cylindrical(gs: int) -> Array:
	"""Cylindrical projection — like walking around a bumpy ring"""
	var heights: Array = []

	for z in range(gs):
		for x in range(gs):
			var theta = (x / float(resolution)) * TAU
			var s = (z / float(resolution)) * 2.0 - 1.0

			# Base cylinder profile
			var h = cos(theta) * 0.2  # Gentle undulation around the ring

			# Möbius twist contribution
			var twist_angle = theta * float(twist_count) / 2.0
			h += s * sin(twist_angle) * 0.5

			# Detail
			h += sin(theta * 5.0 + s * 3.0) * height_amplitude * 0.3

			heights.append(h * height_scale)

	return heights

func _setup_material():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.7, 0.8)  # Cool steel blue
	material.roughness = 0.35
	material.metallic = 0.5
	material.emission_enabled = true
	material.emission = Color(0.3, 0.4, 0.5) * 0.2

	# Cull disabled — appropriate for a non-orientable surface
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	mesh_instance.material_override = material

# Public API
func set_twist_count(count: int):
	twist_count = clampi(count, 1, 5)
	generate_space()

func set_projection(mode: ProjectionMode):
	projection_mode = mode
	generate_space()
