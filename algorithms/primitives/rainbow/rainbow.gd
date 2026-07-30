extends Node3D

# @identity
# essence: ROYGBIV arc(inner_radius + i*thickness) — concentric half-circle bands from ArrayMesh, primary + fainter secondary
# desire: to stand beneath a double rainbow and feel the scale of spectral order arching overhead
# critical_parameter: SECONDARY_FADE — controls how visible the second rainbow is, teaching that double rainbows exist with reversed color order
# triggers: atmospheric particles drift with sin(time); no interaction triggers — the rainbow simply is
# emerges: the reversed color order of the secondary rainbow is physically accurate and usually surprises people
# needs: atmospheric particles [has]; VR scale [has]; interactive angle control [missing]; Label3D [missing]
# relationships: echoes mario_cube (reveals rainbow); contrasts with dark_side_prism (arc vs linear); precedes rainbow_hallway (static vs immersive)
# truth: a rainbow has no location — it exists only in the geometry between sun, water, and eye

# Local debug flag to gate prints (default off)
@export var debug: bool = false

# ═══════════════════════════════════════════
#  DNA (stage 2 — variation)
# ═══════════════════════════════════════════
# banding: how many colours the spectrum is cut into. Newton cut it into seven
#   to make it rhyme with the diatonic scale; the light itself has no seams.
#   The arc keeps the SAME total width under every setting — only the
#   quantisation changes, so the knob argues about naming, not size.
#   "roygbiv" = the pre-promotion seven bands.
# substance: what the rainbow is made of. "light" = the pre-promotion
#   material — unshaded, transparent, an optical event with no location.
#   "glass"/"solid" reify it into a thing that could hold a shadow, which
#   contradicts the truth line above. That contradiction is the point.
@export_enum("roygbiv", "six", "continuous", "two") var banding: String = "roygbiv"
@export_enum("light", "glass", "solid") var substance: String = "light"

# Rainbow parameters
const RAINBOW_RADIUS = 15.0
const RAINBOW_HEIGHT = 8.0
const RAINBOW_SEGMENTS = 64
const RAINBOW_THICKNESS = 0.8

# Double rainbow parameters
const SECONDARY_OFFSET = 3.0
const SECONDARY_FADE = 0.4

# Rainbow colors (ROYGBIV)
var rainbow_colors = [
	Color(1.0, 0.0, 0.0, 1.0),    # Red
	Color(1.0, 0.5, 0.0, 1.0),    # Orange  
	Color(1.0, 1.0, 0.0, 1.0),    # Yellow
	Color(0.0, 1.0, 0.0, 1.0),    # Green
	Color(0.0, 0.0, 1.0, 1.0),    # Blue
	Color(0.3, 0.0, 0.5, 1.0),    # Indigo
	Color(0.5, 0.0, 1.0, 1.0)     # Violet
]

var _arc_roots: Array[Node3D] = []
var _built: bool = false

func _ready() -> void:
	_build_arcs()

	# Add some atmospheric effects
	create_atmosphere()
	_built = true

func _build_arcs() -> void:
	rainbow_colors = _band_colors(banding)

	# Create the primary rainbow
	create_rainbow(Vector3.ZERO, 1.0, false)

	# Create the secondary rainbow (larger, fainter, reversed colors)
	create_rainbow(Vector3(0, 1, 0), SECONDARY_FADE, true)

func _band_colors(mode: String) -> Array:
	match mode:
		"six":
			# The modern convention: indigo dropped. Newton's seventh band was
			# fitted to the octave, not to the eye.
			return [
				Color(1.0, 0.0, 0.0, 1.0),
				Color(1.0, 0.5, 0.0, 1.0),
				Color(1.0, 1.0, 0.0, 1.0),
				Color(0.0, 1.0, 0.0, 1.0),
				Color(0.0, 0.0, 1.0, 1.0),
				Color(0.5, 0.0, 1.0, 1.0),
			]
		"two":
			# Many languages cut the spectrum into a warm half and a cool half
			# and stop there. Fewer names, same light.
			return [
				Color(1.0, 0.3, 0.0, 1.0),
				Color(0.15, 0.15, 0.9, 1.0),
			]
		"continuous":
			# No seams at all — the spectrum as it physically is, cut only by
			# the resolution of the mesh.
			var out: Array = []
			var count: int = 48
			for i in range(count):
				var t: float = float(i) / float(count - 1)
				out.append(Color.from_hsv(t * 0.78, 1.0, 1.0, 1.0))
			return out
		_:
			return [
				Color(1.0, 0.0, 0.0, 1.0),    # Red
				Color(1.0, 0.5, 0.0, 1.0),    # Orange
				Color(1.0, 1.0, 0.0, 1.0),    # Yellow
				Color(0.0, 1.0, 0.0, 1.0),    # Green
				Color(0.0, 0.0, 1.0, 1.0),    # Blue
				Color(0.3, 0.0, 0.5, 1.0),    # Indigo
				Color(0.5, 0.0, 1.0, 1.0)     # Violet
			]

func _band_thickness() -> float:
	# The arc's total width is held at the pre-promotion 7 x 0.8, whatever the
	# band count. Seven bands reproduces RAINBOW_THICKNESS exactly.
	return (RAINBOW_THICKNESS * 7.0) / float(maxi(1, rainbow_colors.size()))


func create_rainbow(offset: Vector3, alpha_multiplier: float, reverse_colors: bool) -> void:
	var rainbow_node = Node3D.new()
	rainbow_node.name = "Rainbow_" + str(randf())
	add_child(rainbow_node)
	_arc_roots.append(rainbow_node)

	# Create each color band of the rainbow
	for color_index in range(rainbow_colors.size()):
		var color_band = create_color_band(color_index, alpha_multiplier, reverse_colors, offset)
		rainbow_node.add_child(color_band)

func create_color_band(color_index: int, alpha_multiplier: float, reverse_colors: bool, offset: Vector3) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "ColorBand_" + str(color_index)
	
	# Create the arc geometry
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
	
	# Calculate radius for this color band
	var band_t: float = _band_thickness()
	var inner_radius = RAINBOW_RADIUS + (color_index * band_t) + (offset.length() * SECONDARY_OFFSET)
	var outer_radius = inner_radius + band_t
	
	# Get the color for this band
	var actual_color_index = color_index if not reverse_colors else (rainbow_colors.size() - 1 - color_index)
	var band_color = rainbow_colors[actual_color_index]
	band_color.a *= alpha_multiplier * 0.7  # Make more transparent
	
	# Create arc vertices
	for i in range(RAINBOW_SEGMENTS + 1):
		var angle = PI * (float(i) / float(RAINBOW_SEGMENTS))  # Half circle
		var cos_a = cos(angle)
		var sin_a = sin(angle)
		
		# Inner vertex
		var inner_pos = Vector3(inner_radius * cos_a, inner_radius * sin_a, 0) + offset
		vertices.append(inner_pos)
		normals.append(Vector3(0, 0, 1))
		colors.append(band_color)
		
		# Outer vertex  
		var outer_pos = Vector3(outer_radius * cos_a, outer_radius * sin_a, 0) + offset
		vertices.append(outer_pos)
		normals.append(Vector3(0, 0, 1))
		colors.append(band_color)
	
	# Create triangles
	for i in range(RAINBOW_SEGMENTS):
		var base_index = i * 2
		
		# First triangle
		indices.append(base_index)
		indices.append(base_index + 1)
		indices.append(base_index + 2)
		
		# Second triangle
		indices.append(base_index + 1)
		indices.append(base_index + 3)
		indices.append(base_index + 2)
	
	# Assign arrays to mesh
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = array_mesh
	
	mesh_instance.material_override = _make_band_material()
	
	return mesh_instance

func _make_band_material() -> StandardMaterial3D:
	# Create material with transparency
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = false
	match substance:
		"solid":
			# An arch, not an event: opaque, lit, casting and taking shadow.
			material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			material.metallic = 0.0
			material.roughness = 0.6
		"glass":
			# Halfway: still see-through, but it has a surface that catches light.
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.metallic = 0.35
			material.roughness = 0.15
		_:
			# "light" — the pre-promotion material, unshaded and alpha-blended.
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.flags_unshaded = true
	return material

func create_atmosphere() -> void:
	# Add some atmospheric particles/effects
	var particles = GPUParticles3D.new()
	particles.name = "AtmosphereParticles"
	add_child(particles)
	
	# Create particle material
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, 1, 0)
	particle_material.initial_velocity_min = 0.5
	particle_material.initial_velocity_max = 2.0
	particle_material.gravity = Vector3(0, -0.5, 0)
	particle_material.scale_min = 0.1
	particle_material.scale_max = 0.3
	particle_material.color = Color(0.8, 0.9, 1.0, 0.3)
	
	particles.process_material = particle_material
	particles.emitting = true
	particles.amount = 100
	particles.position = Vector3(0, -5, 0)
	
	# Create a simple quad mesh for particles
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.2, 0.2)
	particles.draw_pass_1 = quad_mesh
	
	# Particle material
	var draw_material = StandardMaterial3D.new()
	draw_material.albedo_color = Color(1, 1, 1, 0.5)
	draw_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	particles.material_override = draw_material



func _process(_delta):
	# Add some color cycling for extra effect
	var time = Time.get_time_dict_from_system()
	var time_factor = (time.second + time.minute * 60) * 0.01
	
	# Animate the atmosphere particles
	var particles = get_node_or_null("AtmosphereParticles")
	if particles:
		particles.position.x = sin(time_factor) * 2.0

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	# Guarded: only rebuild the arcs when a value actually changed, and only
	# after _ready has built them once. If config arrives first, _ready picks
	# the new values up on its own pass.
	var changed := false
	if config.has("banding"):
		var mode: String = str(config["banding"])
		if mode != banding:
			banding = mode
			changed = true
	if config.has("substance"):
		var subst: String = str(config["substance"])
		if subst != substance:
			substance = subst
			changed = true
	if changed and _built:
		_rebuild_arcs()

func _rebuild_arcs() -> void:
	for arc in _arc_roots:
		if is_instance_valid(arc):
			arc.queue_free()
	_arc_roots.clear()
	_build_arcs()
