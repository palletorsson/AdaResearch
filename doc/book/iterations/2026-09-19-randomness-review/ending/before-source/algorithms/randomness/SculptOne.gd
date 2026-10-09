# @identity
# essence: random material composition — glossy liquids and grainy fabrics arranged by noise
# desire: lean into texture as substance, see how surface roughness narrates a soft-randomness aesthetic
# critical_parameter: noise — the FastNoiseLite seed that determines where each shape lands and how it deforms
# triggers: _ready() builds materials, samples noise to place a curated palette of glossy/fabric/granular blobs
# emerges: an Omoss-style still-life — pinks and yellows soft against glossy red and clear, a tactile composition rendered procedurally
# needs: palette swap dial [has: substance]; reseed button [has: sculpt_seed]; gloss-to-fabric ratio slider [has: substance]
# relationships: cousin of softbodies sequence (material as actor); contrast to deterministic still-lifes
# truth: Materials are choices, not surfaces. Glossy plastic is a different randomness than woven cotton, even at the same noise seed.

extends Node3D

# Liquid Fabric Composition inspired by Albert Omoss style
# A 3D composition mixing glossy liquid surfaces with fabric-like materials

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA (promoted 2026-08-03) — two axes, both already in this file as
# hard-coded constants, neither reachable from a map token until now.
#
#   hand        WHICH sculpting move constitutes the piece. create_composition()
#               ran five moves unconditionally — pour a fluid mass, drape three
#               cloth cones, stipple a bumped sphere, spatter drips, grow bubble
#               extensions. Each is a different randomness doing a different
#               thing to the same block, and the piece was the sum with no way
#               to see any one of them. The word is maze_generation's `hand`:
#               which procedure makes the form. Its value list is this
#               artifact's own moves, the way maze_generation's is its own
#               algorithms.
#   substance   WHAT the piece is made of, colour held constant. Same word as
#               rainbow's `substance` (light|glass|solid) and the same question;
#               a different rung list, because a still-life of cloth and liquid
#               has no "light" rung. This is the truth line above, turned into a
#               knob: identical geometry rendered as one material register
#               instead of a curated mix, so gloss and weave can be compared at
#               the same seed rather than described.
#
# NOT TOUCHED: the geometry every move builds, the noise that deforms it, the
# palette's hues. `substance` rewrites roughness/metallic/clearcoat/normal only
# — every blob keeps the colour create_materials() gave it.
#
# THE SHARED NOISE. All four normal maps hold a reference to ONE FastNoiseLite
# that create_materials() and create_fabric_layer() both mutate, and
# NoiseTexture2D bakes late, so the maps see whatever state the build LEAVES.
# That is pre-existing and deliberately left alone — but it means dropping the
# drape move would silently change every fabric material too, so
# create_composition() now pins that end state for every value of `hand`. The
# axis moves the geometry; it must not move the surfaces underneath it.
# ─────────────────────────────────────────────────────────────────────────────

## THE FIRST AXIS — which sculpting move makes the piece. "composition" is the
## legacy value: all five moves, in the order they have always run.
@export_enum("composition", "pour", "drape", "stipple", "spatter") var hand: String = "composition"

## THE SECOND AXIS — what the piece is made of. "mixed" is the legacy value: the
## curated palette untouched, gloss next to weave next to grain.
@export_enum("mixed", "glossy", "fabric", "granular") var substance: String = "mixed"

## 0 keeps the original behaviour — a fresh composition every launch, which is
## what three rooms have always shown. A positive value pins the whole piece so
## a sweep photographs ONE object under different axes instead of five objects.
@export var sculpt_seed: int = 0

const HANDS: PackedStringArray = ["composition", "pour", "drape", "stipple", "spatter"]
const SUBSTANCES: PackedStringArray = ["mixed", "glossy", "fabric", "granular"]

# Materials
var materials = {
	"glossy_purple": null,
	"glossy_red": null,
	"glossy_clear": null,
	"fabric_pink": null,
	"fabric_yellow": null,
	"fabric_purple": null,
	"granular_orange": null,
	"bubble_material": null
}

# Shape generators
var noise = FastNoiseLite.new()
var rng = RandomNumberGenerator.new()

## Everything this script adds to itself. The .tscn also carries a Camera3D that
## this script must never free, so a rebuild tears down THIS list and nothing else.
var _owned: Array[Node] = []
var _built: bool = false

func _ready() -> void:
	_build_all()


func _build_all() -> void:
	# Seeded FIRST: create_materials() draws from it too.
	if sculpt_seed > 0:
		rng.seed = sculpt_seed
	else:
		rng.randomize()
	# Set up scene
	setup_environment()
	create_materials()
	create_composition()
	_built = true


## add_child + remember, so a rebuild can undo exactly what a build did.
func _own(node: Node) -> void:
	add_child(node)
	_owned.append(node)


func setup_environment() -> void:
	# Create environment with soft pink background
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	
	# Pink background
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.98, 0.78, 0.85)
	
	# Ambient light
	env.ambient_light_color = Color(0.9, 0.8, 0.9)
	env.ambient_light_energy = 0.8
	
	# SSAO for depth
	env.ssao_enabled = true
	env.ssao_radius = 1.0
	env.ssao_intensity = 1.0
	
	# SSR for reflections
	env.ssr_enabled = true
	env.ssr_max_steps = 64
	env.ssr_fade_in = 0.15
	env.ssr_fade_out = 2.0
	env.ssr_depth_tolerance = 0.2
	
	# Enable glow
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_bloom = 0.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	
	# Apply environment
	environment.environment = env
	_own(environment)

	# Add lighting
	setup_lighting()

func setup_lighting() -> void:
	# Create soft key light
	var key_light = DirectionalLight3D.new()
	key_light.light_color = Color(1.0, 0.98, 0.95)
	key_light.light_energy = 2.0
	key_light.shadow_enabled = true
	key_light.rotation_degrees = Vector3(-45, 30, 0)
	_own(key_light)
	
	# Create rim light
	var rim_light = DirectionalLight3D.new()
	rim_light.light_color = Color(0.9, 0.8, 1.0)
	rim_light.light_energy = 1.0
	rim_light.shadow_enabled = false
	rim_light.rotation_degrees = Vector3(-20, -140, 0)
	_own(rim_light)
	
	# Create fill light
	var fill_light = OmniLight3D.new()
	fill_light.light_color = Color(0.95, 0.85, 0.9)
	fill_light.light_energy = 1.5
	fill_light.shadow_enabled = true
	fill_light.position = Vector3(-2, 0, 3)
	fill_light.omni_range = 8.0
	_own(fill_light)

func create_materials() -> void:
	# Initialize noise for materials
	noise.seed = int(rng.randi())
	noise.fractal_octaves = 4
	noise.frequency = 0.1
	
	# Glossy purple material (main dripping surface)
	materials.glossy_purple = StandardMaterial3D.new()
	materials.glossy_purple.albedo_color = Color(0.85, 0.45, 0.95)
	materials.glossy_purple.metallic = 0.2
	materials.glossy_purple.roughness = 0.1
	materials.glossy_purple.clearcoat_enabled = true
	materials.glossy_purple.clearcoat = 1.0
	materials.glossy_purple.clearcoat_roughness = 0.05
	
	# Glossy red material
	materials.glossy_red = StandardMaterial3D.new()
	materials.glossy_red.albedo_color = Color(0.95, 0.2, 0.3)
	materials.glossy_red.metallic = 0.2
	materials.glossy_red.roughness = 0.15
	materials.glossy_red.clearcoat_enabled = true
	materials.glossy_red.clearcoat = 1.0
	materials.glossy_red.clearcoat_roughness = 0.05
	
	# Clear glossy material for drips
	materials.glossy_clear = StandardMaterial3D.new()
	materials.glossy_clear.albedo_color = Color(0.9, 0.9, 0.95, 0.6)
	materials.glossy_clear.metallic = 0.3
	materials.glossy_clear.roughness = 0.05
	materials.glossy_clear.refraction_enabled = true
	materials.glossy_clear.refraction_scale = 0.05
	materials.glossy_clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# Pink fabric material
	materials.fabric_pink = StandardMaterial3D.new()
	materials.fabric_pink.albedo_color = Color(0.95, 0.6, 0.75)
	materials.fabric_pink.roughness = 0.9
	materials.fabric_pink.metallic = 0.0
	
	# Add fabric normal map
	var pink_normal = NoiseTexture2D.new()
	pink_normal.noise = noise
	pink_normal.as_normal_map = true
	pink_normal.bump_strength = 2.0
	materials.fabric_pink.normal_enabled = true
	materials.fabric_pink.normal_texture = pink_normal
	
	# Yellow fabric material
	materials.fabric_yellow = StandardMaterial3D.new()
	materials.fabric_yellow.albedo_color = Color(0.95, 0.8, 0.2)
	materials.fabric_yellow.roughness = 0.85
	materials.fabric_yellow.metallic = 0.0
	
	# Add fabric normal map
	var yellow_normal = NoiseTexture2D.new()
	yellow_normal.noise = noise
	yellow_normal.as_normal_map = true
	yellow_normal.bump_strength = 2.0
	materials.fabric_yellow.normal_enabled = true
	materials.fabric_yellow.normal_texture = yellow_normal
	
	# Purple fabric material
	materials.fabric_purple = StandardMaterial3D.new()
	materials.fabric_purple.albedo_color = Color(0.75, 0.5, 0.95)
	materials.fabric_purple.roughness = 0.8
	materials.fabric_purple.metallic = 0.0
	
	# Add fabric normal map
	var purple_normal = NoiseTexture2D.new()
	purple_normal.noise = noise
	purple_normal.as_normal_map = true
	purple_normal.bump_strength = 2.5
	materials.fabric_purple.normal_enabled = true
	materials.fabric_purple.normal_texture = purple_normal
	
	# Granular orange material (for the bumpy sphere)
	materials.granular_orange = StandardMaterial3D.new()
	materials.granular_orange.albedo_color = Color(0.95, 0.6, 0.2)
	materials.granular_orange.roughness = 0.7
	materials.granular_orange.metallic = 0.2
	
	# Add granular normal map
	var granular_normal = NoiseTexture2D.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	noise.cellular_jitter = 1.0
	noise.frequency = 10.0
	granular_normal.noise = noise
	granular_normal.as_normal_map = true
	granular_normal.bump_strength = 5.0
	materials.granular_orange.normal_enabled = true
	materials.granular_orange.normal_texture = granular_normal
	
	# Bubble material (for small transparent elements)
	materials.bubble_material = StandardMaterial3D.new()
	materials.bubble_material.albedo_color = Color(0.85, 0.95, 0.85, 0.7)
	materials.bubble_material.metallic = 0.2
	materials.bubble_material.roughness = 0.0
	materials.bubble_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	materials.bubble_material.refraction_enabled = true
	materials.bubble_material.refraction_scale = 0.05

	# substance != "mixed" re-registers every one of the eight above. Colour is
	# kept; only the surface is re-argued.
	_apply_substance()


## A dedicated noise for a substance normal map. NOT the shared `noise` object —
## that one is mutated during the build and must be left exactly as the legacy
## path leaves it (see the header note). Unseeded on purpose: a fixed normal map
## across all four values keeps `substance` a claim about surface and nothing else.
func _substance_normal(cellular: bool, bump: float) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	if cellular:
		n.noise_type = FastNoiseLite.TYPE_CELLULAR
		n.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
		n.cellular_jitter = 1.0
		n.frequency = 10.0
	else:
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX
		n.frequency = 2.0
	var tex := NoiseTexture2D.new()
	tex.noise = n
	tex.as_normal_map = true
	tex.bump_strength = bump
	return tex


## Rewrite the whole palette into ONE material register. "mixed" returns before
## touching anything, which is why the three shipped placements are untouched.
func _apply_substance() -> void:
	if substance == "mixed":
		return
	for key in materials.keys():
		var raw = materials[key]
		if not (raw is StandardMaterial3D):
			continue
		var m: StandardMaterial3D = raw
		# The hue survives; everything that makes it a SUBSTANCE is replaced.
		var albedo: Color = m.albedo_color
		albedo.a = 1.0
		m.albedo_color = albedo
		m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		m.refraction_enabled = false
		m.clearcoat_enabled = false
		m.normal_enabled = false
		m.normal_texture = null
		match substance:
			"glossy":
				m.metallic = 0.2
				m.roughness = 0.1
				m.clearcoat_enabled = true
				m.clearcoat = 1.0
				m.clearcoat_roughness = 0.05
			"fabric":
				m.metallic = 0.0
				m.roughness = 0.9
				m.normal_enabled = true
				m.normal_texture = _substance_normal(false, 2.0)
			"granular":
				m.metallic = 0.2
				m.roughness = 0.7
				m.normal_enabled = true
				m.normal_texture = _substance_normal(true, 5.0)


func create_composition() -> void:
	# Root node for the composition
	var composition = Node3D.new()
	composition.name = "LiquidComposition"
	_own(composition)

	# PIN THE SHARED NOISE. create_fabric_layer() sets exactly this, three times,
	# on the legacy path — so the state it leaves behind for the late-baking
	# normal maps is unchanged here, and now it is the SAME state for every value
	# of `hand`, including the ones that never drape a cloth. Without this line
	# dropping the drape move would also change how every fabric material looks,
	# and the axis would be measuring two things at once.
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 2.0

	# The block the sculptor works. Present under every hand — what varies is
	# what is DONE to it, not whether there is anything there.
	var base = create_fluid_mass(materials.glossy_purple, Vector3(0, 0, 0), Vector3(2.0, 0.8, 2.0))
	composition.add_child(base)

	var every: bool = hand == "composition"

	# Add fabric layers
	if every or hand == "drape":
		create_fabric_layer(composition, materials.fabric_pink, Vector3(0, 0.4, 0), 0.8, 0.2)
		create_fabric_layer(composition, materials.fabric_yellow, Vector3(0, 0.75, 0), 1.0, 0.15)
		create_fabric_layer(composition, materials.fabric_purple, Vector3(0, 1.0, 0), 0.7, 0.2)

	# Add red glossy blob
	if every or hand == "pour":
		var red_blob = create_fluid_mass(materials.glossy_red, Vector3(0.5, 1.2, -0.3), Vector3(0.7, 0.5, 0.7))
		composition.add_child(red_blob)

	# Add textured orange sphere at top
	if every or hand == "stipple":
		var orange_sphere = create_textured_sphere(materials.granular_orange, Vector3(-0.3, 1.8, 0.2), 0.5)
		composition.add_child(orange_sphere)

	if every or hand == "spatter":
		# Add clear drips
		create_drip_elements(composition, 15)
		# Add green bubble extensions (similar to the green tentacle-like elements)
		create_bubble_extensions(composition, Vector3(-0.3, 2.0, 0.2), 8)

func create_fluid_mass(material, position, scale_vec):
	var fluid = Node3D.new()
	fluid.position = position
	
	# Create base mesh
	var base_mesh = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 1.0
	sphere_mesh.height = 2.0
	base_mesh.mesh = sphere_mesh
	base_mesh.scale = scale_vec
	base_mesh.material_override = material
	
	# Add some deformations to make it look more fluid-like
	var deform_count = rng.randi() % 5 + 5
	for i in range(deform_count):
		var deform = MeshInstance3D.new()
		var deform_mesh = SphereMesh.new()
		deform_mesh.radius = rng.randf_range(0.3, 0.7)
		deform_mesh.height = deform_mesh.radius * 2
		deform.mesh = deform_mesh
		
		# Random position on the surface
		var angle = rng.randf_range(0, TAU)
		var elevation = rng.randf_range(-1.0, 1.0)
		var radius = rng.randf_range(0.7, 1.1)
		deform.position = Vector3(
			cos(angle) * radius * scale_vec.x,
			elevation * scale_vec.y,
			sin(angle) * radius * scale_vec.z
		)
		
		deform.material_override = material
		fluid.add_child(deform)
	
	return fluid

func create_fabric_layer(parent, material, position, radius, height) -> void:
	var fabric = Node3D.new()
	fabric.position = position
	
	# Create base cloth-like shape using many small quads with noise-based displacement
	var segments = 12
	var cloth_shape = ImmediateMesh.new()
	var cloth_instance = MeshInstance3D.new()
	cloth_instance.mesh = cloth_shape
	
	# Reset noise for fabric
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 2.0
	
	# Generate fabric mesh
	cloth_shape.clear_surfaces()
	cloth_shape.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	
	for i in range(segments):
		var angle1 = TAU * i / segments
		var angle2 = TAU * (i + 1) / segments
		
		for j in range(segments):
			var radius1 = radius * (1.0 - 0.2 * sin(j * 0.5))
			var radius2 = radius * (1.0 - 0.2 * sin((j + 1) * 0.5))
			
			var height_factor1 = j / float(segments)
			var height_factor2 = (j + 1) / float(segments)
			
			var y1 = -height * height_factor1
			var y2 = -height * height_factor2
			
			# Add noise for more organic cloth-like shape
			var noise_val1 = noise.get_noise_2d(cos(angle1) * 10, sin(angle1) * 10) * 0.2
			var noise_val2 = noise.get_noise_2d(cos(angle2) * 10, sin(angle2) * 10) * 0.2
			
			var v1 = Vector3(cos(angle1) * radius1, y1 + noise_val1, sin(angle1) * radius1)
			var v2 = Vector3(cos(angle2) * radius1, y1 + noise_val2, sin(angle2) * radius1)
			var v3 = Vector3(cos(angle2) * radius2, y2 + noise_val2, sin(angle2) * radius2)
			var v4 = Vector3(cos(angle1) * radius2, y2 + noise_val1, sin(angle1) * radius2)
			
			# Calculate normal for proper lighting
			var normal1 = (v2 - v1).cross(v3 - v1).normalized()
			var normal2 = (v3 - v1).cross(v4 - v1).normalized()
			
			# Create quad (two triangles)
			# Triangle 1
			cloth_shape.surface_set_normal(normal1)
			cloth_shape.surface_set_uv(Vector2(i / float(segments), j / float(segments)))
			cloth_shape.surface_add_vertex(v1)
			
			cloth_shape.surface_set_normal(normal1)
			cloth_shape.surface_set_uv(Vector2((i + 1) / float(segments), j / float(segments)))
			cloth_shape.surface_add_vertex(v2)
			
			cloth_shape.surface_set_normal(normal1)
			cloth_shape.surface_set_uv(Vector2((i + 1) / float(segments), (j + 1) / float(segments)))
			cloth_shape.surface_add_vertex(v3)
			
			# Triangle 2
			cloth_shape.surface_set_normal(normal2)
			cloth_shape.surface_set_uv(Vector2(i / float(segments), j / float(segments)))
			cloth_shape.surface_add_vertex(v1)
			
			cloth_shape.surface_set_normal(normal2)
			cloth_shape.surface_set_uv(Vector2((i + 1) / float(segments), (j + 1) / float(segments)))
			cloth_shape.surface_add_vertex(v3)
			
			cloth_shape.surface_set_normal(normal2)
			cloth_shape.surface_set_uv(Vector2(i / float(segments), (j + 1) / float(segments)))
			cloth_shape.surface_add_vertex(v4)
	
	cloth_shape.surface_end()
	
	fabric.add_child(cloth_instance)
	parent.add_child(fabric)

func create_textured_sphere(material, position, radius):
	var sphere_node = Node3D.new()
	sphere_node.position = position
	
	# Base sphere
	var sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	sphere_mesh.radial_segments = 32
	sphere_mesh.rings = 24
	sphere.mesh = sphere_mesh
	sphere.material_override = material
	
	# Add bumps to the sphere
	var bump_count = 40
	for i in range(bump_count):
		var bump = MeshInstance3D.new()
		var bump_mesh = SphereMesh.new()
		var bump_size = rng.randf_range(0.05, 0.15) * radius
		bump_mesh.radius = bump_size
		bump_mesh.height = bump_size * 2.0
		bump.mesh = bump_mesh
		
		# Position on sphere surface
		var angle1 = rng.randf_range(0, TAU)
		var angle2 = rng.randf_range(0, PI)
		var pos = Vector3(
			sin(angle2) * cos(angle1),
			sin(angle2) * sin(angle1),
			cos(angle2)
		) * radius
		
		bump.position = pos
		bump.material_override = material
		sphere_node.add_child(bump)
	
	sphere_node.add_child(sphere)
	return sphere_node

func create_drip_elements(parent, count) -> void:
	for i in range(count):
		var drip = MeshInstance3D.new()
		
		# Create different drip shapes
		var drip_type = rng.randi() % 3
		
		match drip_type:
			0:  # Droplet
				var droplet_mesh = SphereMesh.new()
				droplet_mesh.radius = rng.randf_range(0.05, 0.15)
				droplet_mesh.height = droplet_mesh.radius * 2.0
				drip.mesh = droplet_mesh
			1:  # Elongated drip
				var drip_mesh = CapsuleMesh.new()
				drip_mesh.radius = rng.randf_range(0.03, 0.08)
				drip_mesh.height = rng.randf_range(0.2, 0.5)
				drip.mesh = drip_mesh
			2:  # Small puddle
				var puddle_mesh = SphereMesh.new()
				puddle_mesh.radius = rng.randf_range(0.1, 0.2)
				puddle_mesh.height = puddle_mesh.radius * 0.5  # Flattened
				drip.mesh = puddle_mesh
				drip.rotation_degrees.x = 90  # Lie flat
		
		# Random position around the composition
		var angle = rng.randf_range(0, TAU)
		var radius = rng.randf_range(0.5, 1.5)
		var height = rng.randf_range(0.0, 1.5)
		
		drip.position = Vector3(
			cos(angle) * radius,
			height,
			sin(angle) * radius
		)
		
		drip.material_override = materials.glossy_clear
		parent.add_child(drip)

func create_bubble_extensions(parent, origin_position, count) -> void:
	for i in range(count):
		var extension = Node3D.new()
		var extension_length = rng.randf_range(0.3, 0.8)
		var segment_count = 5
		
		# Direction from origin with randomness
		var angle_horizontal = rng.randf_range(0, TAU)
		var angle_vertical = rng.randf_range(-PI/3, PI/3)
		
		var direction = Vector3(
			cos(angle_horizontal) * cos(angle_vertical),
			sin(angle_vertical),
			sin(angle_horizontal) * cos(angle_vertical)
		).normalized()
		
		# Create segments
		var prev_pos = origin_position
		for j in range(segment_count):
			var segment = MeshInstance3D.new()
			var segment_size = rng.randf_range(0.05, 0.1) * (1.0 - j / float(segment_count))
			
			var segment_mesh = SphereMesh.new()
			segment_mesh.radius = segment_size
			segment_mesh.height = segment_size * 2
			segment.mesh = segment_mesh
			
			# Add some noise to the direction
			var noise_factor = 0.3
			var noise_direction = Vector3(
				rng.randf_range(-noise_factor, noise_factor),
				rng.randf_range(-noise_factor, noise_factor),
				rng.randf_range(-noise_factor, noise_factor)
			)
			
			direction = (direction + noise_direction * 0.2).normalized()
			
			# Calculate position
			var segment_distance = extension_length / segment_count
			var pos = prev_pos + direction * segment_distance
			segment.position = pos
			prev_pos = pos
			
			segment.material_override = materials.bubble_material
			extension.add_child(segment)
		
		parent.add_child(extension)



# Optional: add subtle animation
func _process(delta: float) -> void:
	# _or_null: during a rebuild the composition is gone for the rest of the
	# frame, and get_node() would log an error every one of them.
	var composition = get_node_or_null("LiquidComposition")
	if composition:
		# Add very subtle movement
		composition.rotate_y(delta * 0.05)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
	_owned.clear()


## Read an axis token the way the rest of the corpus does: strip, lower, and fall
## back to what is already set rather than to silence. A typo must not quietly
## empty a still-life that three rooms expect whole.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	if allowed.has(v):
		return v
	if v != "":
		push_warning("sculpt_one: unknown value '%s' — keeping '%s'" % [v, fallback])
	return fallback


## Map tokens: "sculpt_one#hand:drape", "sculpt_one#substance:fabric",
## "sculpt_one#sculpt_seed:20260803".
##
## THE TWO EARLY RETURNS ARE LOAD-BEARING. curation_station calls this with
## {"emissive": false} on every artifact it curates — a dict carrying none of
## these keys. An unconditional rebuild there would throw away the framing it
## just applied. So: nothing built yet, do nothing (_ready is about to use the
## values); nothing changed, do nothing and say nothing.
func apply_grid_config(config: Dictionary) -> void:
	var before_hand: String = hand
	var before_substance: String = substance
	var before_seed: int = sculpt_seed

	if config.has("hand"):
		hand = _pick_axis(str(config["hand"]), HANDS, hand)
	if config.has("substance"):
		substance = _pick_axis(str(config["substance"]), SUBSTANCES, substance)
	if config.has("sculpt_seed"):
		sculpt_seed = int(config["sculpt_seed"])

	if not _built:
		return
	if hand == before_hand and substance == before_substance and sculpt_seed == before_seed:
		return
	_rebuild_now()


## Tear down exactly what this script built, then build it again INLINE. No
## call_deferred: a deferred rebuild leaves the node empty for a frame, and the
## grid's auto-grounding pass — later in the same deferred queue — would measure
## a zero AABB and leave the piece floating.
func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	for key in materials.keys():
		materials[key] = null
	_built = false
	_build_all()
