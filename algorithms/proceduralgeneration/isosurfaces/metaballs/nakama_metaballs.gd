# Metaball System for Godot 4
# This implementation creates a Kouhei Nakama-inspired organic surface using metaballs

extends Node3D

# @identity
# essence: Kouhei-Nakama-inspired organic metaball field — 60 spheres arranged in a circular distribution drift through Perlin-driven motion, their summed radial falloffs producing a clustered creature-like surface
# desire: to render the soft-body aesthetic of organic clusters — not a tree, not a crowd, but a single moving organism made of many bodies that have not quite separated from each other
# critical_parameter: surface_threshold — controls where the iso-level is read; lower thresholds make the field bleed wider (one creature), higher thresholds reveal individual spheres (many creatures)
# triggers: time advancement moves each metaball along its noise-driven trajectory; new metaball positions push the iso-surface into different shapes each frame; movement_speed scales the temporal evolution
# emerges: 60 independent moving spheres look like one breathing creature — the metaball summation hides the discrete origins, producing the visual signature of organic-but-artificial that defines the Nakama aesthetic
# needs: FastNoiseLite [resolved], ShaderMaterial [resolved], DirectionalLight3D [resolved]
# relationships: artistic counterpart to raymarched_metaballs — same metaball math, but the parameter choices target an organic aesthetic rather than a clean mathematical demonstration; sibling to metaball_world and metaball_generator
# truth: a single organism is what a crowd looks like when the field between bodies is dense enough — bodies stop being separate things and become one thing made of many positions

# ─────────────────────────────────────────────────────────────────────
# ARTIFACT DNA — axis: `imprint`
#
#  THE FINDING FIRST, because the axis only makes sense after it: this
#  artifact does not extract an isosurface. create_metaball_proxy_mesh
#  builds a SphereMesh of radius 3.0 at 64 radial segments and 32 rings,
#  walks it with a MeshDataTool, and displaces each vertex along its own
#  normal by (field_value - surface_threshold) * 0.2, plus a noise
#  wrinkle of 0.1. Its own comment says so — "a workaround to avoid
#  implementing full marching cubes". The genus is PINNED AT 0 by the
#  proxy: this surface can never split, never merge and never open a
#  hole, whatever the field does. The field is a readout painted onto a
#  fixed shape.
#
#  `imprint` lifts that 0.2 — how deep the field is pressed into a
#  surface that was never derived from it.
#     blank   0.0  the field does not reach the skin at all. A 3 m
#                  sphere carrying only the 0.1 wrinkle: the one frame
#                  in the corpus showing a metaball artifact's surface
#                  with its metaballs removed, and the evidence for
#                  everything above.
#     relief  0.2  SHIPPED. Short-circuits to the literal.
#     swollen 0.6
#     flayed  1.2  the sixty sources push the skin into spikes and the
#                  flat ring they are arranged in becomes legible.
#
#  NOT `fusion`, NOT `metaball_count` — both taken by metaballs.tscn and
#  both about a raymarched SDF that sums nothing. imprint is a third
#  question only this artifact can ask, because only this artifact has a
#  surface that exists independently of its field.
#
#  DECLINED: `surface_threshold`, and THE DECLINE IS THE RESULT. The
#  @identity below advertises it as the critical_parameter — "lower
#  thresholds make the field bleed wider (one creature), higher
#  thresholds reveal individual spheres (many creatures)". The
#  arithmetic refuses it. In `vertex += normal * (field_value -
#  surface_threshold) * 0.2` the threshold enters only as
#  -T * 0.2 * normal — a constant displacement along each vertex's own
#  outward normal, which on a sphere is exactly a change of RADIUS.
#  Sweeping T gives spheres of different sizes carrying identical lumps.
#  It cannot separate a body or merge one, because the proxy's genus is
#  fixed. Filed as a defect in the @identity, not swept.
#
#  DEAD EXPORT, reported and left alone: `movement_speed` is written
#  into each metaball's `velocity` field in create_metaballs and
#  `velocity` is read by NOTHING. All motion comes from the noise term,
#  the centre attraction and the radius sine in update_metaballs.
#  Wiring it now would change what the one live room draws.
#
#  metaball_seed and pose_time are the FIXTURE, not axes — same names
#  and same sentinels as metaballs.gd. This artifact is
#  non-deterministic twice over and animated on top. See _seed_rng and
#  _run_pose.
# ─────────────────────────────────────────────────────────────────────

## Depth of the field's imprint on the proxy skin. `relief` is never read
## from here — it short-circuits to the shipped literal. See _imprint_depth.
const IMPRINT_DEPTH := {"blank": 0.0, "relief": 0.2, "swollen": 0.6, "flayed": 1.2}
## The fixed step _run_pose replays. Not a tuning choice: it is the frame
## time the shipped _process is written against.
const POSE_STEP: float = 1.0 / 60.0

# Configuration
@export var num_metaballs = 60
@export var container_size = Vector3(5.0, 5.0, 5.0)
@export var surface_threshold = 1.0
@export var base_radius = 0.4
@export var radius_variation = 0.3
@export var movement_speed = 0.5
@export var material_color: Color = Color(0.95, 0.85, 0.85)

## How deep the summed field is pressed into the proxy sphere.
@export_enum("blank", "relief", "swollen", "flayed") var imprint: String = "relief"
## 0 keeps the shipped global RNG, draw for draw. Non-zero seeds a local one.
@export var metaball_seed: int = 0
## Below zero keeps the shipped wall clock and the per-frame rebuild. Zero or
## above replays that many seconds synchronously in _ready, then freezes.
@export var pose_time: float = -1.0

# Metaball properties
var metaballs = []
var time = 0.0

# Node references
var mesh_instance: MeshInstance3D
var noise: FastNoiseLite

## Non-null only when metaball_seed != 0. See _seed_rng.
var _rng: RandomNumberGenerator = null
## Every node this script added, and the only nodes it may free.
var _owned: Array[Node] = []
var _built: bool = false

func _ready() -> void:
	# Must run BEFORE the first draw below: at seed 0 it leaves _rng null and
	# every draw falls through to the global RNG in the order it always used.
	_seed_rng()

	# Initialize noise for organic movement
	noise = FastNoiseLite.new()
	noise.seed = _rand_int()
	noise.frequency = 0.5

	# Create metaballs
	create_metaballs()

	# Create the mesh instance
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	_owned.append(mesh_instance)

	# Create shader material
	var material = create_shader_material()
	mesh_instance.material_override = material

	# Set up lighting
	setup_lighting()

	# pose_time below zero is the shipped path: no mesh is built here, and the
	# first _process generates one, exactly as before.
	if pose_time >= 0.0:
		_run_pose(pose_time)

	_built = true


## seed 0 is the shipped path. Leaving _rng NULL is the whole trick: _rand_range
## and _rand_int then call the global randf_range/randi with the same arguments
## in the same order, so the one live placement draws the identical sequence it
## always drew. Non-zero routes every draw through a local generator seeded
## BEFORE the first sample — including noise.seed, which on the shipped path is
## `randi()`, the literal opposite of seeded.
func _seed_rng() -> void:
	_rng = null
	if metaball_seed != 0:
		_rng = RandomNumberGenerator.new()
		_rng.seed = metaball_seed


func _rand_range(from_value: float, to_value: float) -> float:
	if _rng == null:
		return randf_range(from_value, to_value)
	return _rng.randf_range(from_value, to_value)


func _rand_int() -> int:
	if _rng == null:
		return randi()
	return _rng.randi()


## The imprint depth handed to the displacement. `relief` SHORT-CIRCUITS to the
## bare literal 0.2 rather than to IMPRINT_DEPTH's copy of it, so the shipped
## path does not depend on a dictionary lookup at all.
func _imprint_depth() -> float:
	if imprint == "relief":
		return 0.2
	return float(IMPRINT_DEPTH.get(imprint, 0.2))


## Replay `seconds` of animation synchronously, then build once and stop.
##
## SPELL IT OUT OR IT WILL NOT REPRODUCE. update_metaballs early-returns on even
## Engine.get_frames_drawn() and advances only thirty of the sixty balls per
## call, from a start index derived from `time` — so the state at t is a function
## of how many discrete update calls happened, not a closed form. A synchronous
## loop cannot read a frame counter that is not advancing, so the parity is
## replayed here on the virtual step index instead. That reproduces the DENSITY
## of updates, not any particular live frame: the real counter's value at spawn
## is arbitrary, which is precisely why the pose has to be pinned by fixture
## rather than sampled.
func _run_pose(seconds: float) -> void:
	var steps: int = int(round(seconds / POSE_STEP))
	for f in range(steps):
		time += POSE_STEP
		if f % 2 == 1:
			_advance_metaballs(POSE_STEP)
	generate_mesh()
	if mesh_instance.material_override is ShaderMaterial:
		mesh_instance.material_override.set_shader_parameter("time", time)
	# One frame, held. The shipped path rebuilds a 64x32 MeshDataTool sphere
	# every frame; a pinned pose must not.
	set_process(false)

func create_metaballs() -> void:
	# Create the metaballs with random positions and radii
	for i in range(num_metaballs):
		# Create a pattern similar to the reference image
		# Concentrate balls in a circular pattern
		# SEVEN draws per ball, in this order — not five. At seed 0 each of these
		# is the identical global call it always was; the wrapper only chooses
		# the generator.
		var distance_from_center = _rand_range(1.0, 3.0)
		var angle = _rand_range(0.0, TAU)
		var position = Vector3(
			cos(angle) * distance_from_center,
			sin(angle) * distance_from_center,
			_rand_range(-0.5, 0.5)
		)

		var metaball = {
			"position": position,
			"radius": base_radius + _rand_range(-radius_variation, radius_variation),
			# DEAD: `velocity` is written here and read nowhere. Kept, and kept
			# drawing, because removing the three draws would shift the RNG
			# stream and change what the live room draws.
			"velocity": Vector3(
				_rand_range(-1.0, 1.0),
				_rand_range(-1.0, 1.0),
				_rand_range(-1.0, 1.0)
			).normalized() * movement_speed
		}
		
		metaballs.append(metaball)

func create_shader_material() -> ShaderMaterial:
	# Create a shader material for the metaball surface
	var material = ShaderMaterial.new()
	
	# Create the shader
	var shader = Shader.new()
	shader.code = """
shader_type spatial;

// Surface properties
uniform vec4 albedo : source_color = vec4(0.95, 0.85, 0.85, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.2;
uniform float metallic : hint_range(0.0, 1.0) = 0.1;
uniform float specular : hint_range(0.0, 1.0) = 0.6;

// Subsurface scattering
uniform float subsurface_scatter : hint_range(0.0, 1.0) = 0.3;
uniform vec4 subsurface_color : source_color = vec4(0.95, 0.75, 0.75, 1.0);

// Detail noise
uniform sampler2D noise_texture;
uniform float noise_scale = 10.0;
uniform float noise_strength = 0.05;

// Displacement
uniform float displacement_amount = 0.03;

// Use built-in TIME instead of custom uniform
// uniform float time = 0.0; // Remove this line

varying vec3 world_normal;
varying vec3 world_tangent;
varying vec3 world_binormal;

void vertex() {
	// Calculate world space TBN matrix
	world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	world_tangent = (MODEL_MATRIX * vec4(TANGENT, 0.0)).xyz;
	world_binormal = (MODEL_MATRIX * vec4(BINORMAL, 0.0)).xyz;
	
	// Add subtle displacement along normal for surface details
	float noise_value = texture(noise_texture, UV * noise_scale + vec2(TIME * 0.05)).r;
	VERTEX += NORMAL * noise_value * displacement_amount;
}

void fragment() {
	// Base surface properties
	ALBEDO = albedo.rgb;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = specular;
	
	// Sample noise for normal perturbation
	vec2 uv_offset = UV * noise_scale + vec2(TIME * 0.05);
	float noise_x = texture(noise_texture, uv_offset + vec2(0.01, 0.0)).r - 
				   texture(noise_texture, uv_offset - vec2(0.01, 0.0)).r;
	float noise_y = texture(noise_texture, uv_offset + vec2(0.0, 0.01)).r - 
				   texture(noise_texture, uv_offset - vec2(0.0, 0.01)).r;
				   
	vec3 normal_map = vec3(noise_x, noise_y, 1.0) * noise_strength;
	normal_map = normalize(normal_map);
	
	// Apply normal mapping
	NORMAL_MAP = normal_map;
	
	// In Godot 4, subsurface scattering is handled differently
	// Use BACKLIGHT for translucent effects instead
	BACKLIGHT = subsurface_color.rgb * subsurface_scatter;
}

	"""
	material.shader = shader
	
	# Set shader parameters
	material.set_shader_parameter("albedo", material_color)
	material.set_shader_parameter("roughness", 0.2)
	material.set_shader_parameter("metallic", 0.1)
	material.set_shader_parameter("specular", 0.6)
	material.set_shader_parameter("subsurface_scatter", 0.3)
	material.set_shader_parameter("subsurface_color", Color(0.95, 0.75, 0.75))
	material.set_shader_parameter("displacement_amount", 0.03)
	
	# Create noise texture for the details
	var noise_texture = NoiseTexture2D.new()
	noise_texture.noise = FastNoiseLite.new()
	noise_texture.noise.frequency = 0.8
	noise_texture.noise.fractal_octaves = 4
	noise_texture.width = 512
	noise_texture.height = 512
	material.set_shader_parameter("noise_texture", noise_texture)
	material.set_shader_parameter("noise_scale", 10.0)
	material.set_shader_parameter("noise_strength", 0.05)
	material.set_shader_parameter("time", 0.0)
	
	return material

func _process(delta: float) -> void:
	time += delta
	
	# Update metaball positions
	update_metaballs(delta)
	
	# Generate the mesh
	generate_mesh()
	
	# Update shader time parameter
	if mesh_instance.material_override is ShaderMaterial:
		mesh_instance.material_override.set_shader_parameter("time", time)

func update_metaballs(delta) -> void:
	# Move metaballs in organic patterns, but skip every other frame for performance
	if Engine.get_frames_drawn() % 2 == 0:
		return

	_advance_metaballs(delta)


## The body of update_metaballs with the frame-parity gate lifted off it, so
## _run_pose can drive the same arithmetic without a frame counter. The live
## path still reaches it only through update_metaballs above, unchanged.
func _advance_metaballs(delta) -> void:
	# Only update a portion of metaballs each frame
	var update_count = min(30, metaballs.size())
	var start_idx = int(fmod(time * 5, metaballs.size()))
	
	for i in range(update_count):
		var idx = (start_idx + i) % metaballs.size()
		var mb = metaballs[idx]
		
		# Use noise to create organic movement - simplified for performance
		var noise_offset = time * 0.1 + idx * 0.05
		
		# Only calculate one noise value per frame and distribute it
		var noise_value = noise.get_noise_3d(noise_offset, 0, idx * 0.1) * delta
		mb.position.x += noise_value
		mb.position.y += noise_value * 0.8
		mb.position.z += noise_value * 0.6
		
		# Keep within bounds with a soft boundary - vectorized for better performance
		mb.position = mb.position.clamp(
			Vector3(-container_size.x/2, -container_size.y/2, -container_size.z/2),
			Vector3(container_size.x/2, container_size.y/2, container_size.z/2)
		)
		
		# Apply a mild attraction to the center to maintain the circular pattern
		var center_dir = -mb.position.normalized()
		mb.position += center_dir * delta * 0.1
		
		# Optimize the sin calculation - only update radius every few frames
		if i % 3 == 0:  
			mb.radius = base_radius + sin(time * 0.5 + idx * 0.2) * radius_variation * 0.5

func generate_mesh() -> void:
	# Generate a mesh based on metaballs using the marching cubes algorithm
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create a simplified proxy mesh for the metaballs
	create_metaball_proxy_mesh(st)
	
	st.generate_normals()
	st.generate_tangents()
	
	# Assign the mesh
	mesh_instance.mesh = st.commit()

func create_metaball_proxy_mesh(st) -> void:
	# Create a surface that approximates what metaballs would look like
	# This is a workaround to avoid implementing full marching cubes
	
	# Create a sphere that will be our base shape
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 3.0
	sphere_mesh.height = 6.0
	sphere_mesh.radial_segments = 64
	sphere_mesh.rings = 32
	
	# Create an array mesh from the sphere
	var array_mesh = ArrayMesh.new()
	var temp_st = SurfaceTool.new()
	temp_st.create_from(sphere_mesh, 0)
	temp_st.commit(array_mesh)
	
	# Create a mesh data tool to modify the sphere mesh
	var mdt = MeshDataTool.new()
	var err = mdt.create_from_surface(array_mesh, 0)
	if err != OK:
		print("Failed to create MeshDataTool: ", err)
		# Fallback to a simple sphere if we can't modify the mesh
		st.create_from(sphere_mesh, 0)
		return
	
	# Hoisted: constant across the ~2048 vertices, and this runs per frame on
	# the live path.
	var depth: float = _imprint_depth()

	# Modify each vertex based on metaball field
	for i in range(mdt.get_vertex_count()):
		var vertex = mdt.get_vertex(i)
		
		# Calculate metaball field influence at this point
		var field_value = calculate_metaball_field(vertex)
		
		# Get normal for this vertex
		var normal = mdt.get_vertex_normal(i)
		
		# Offset the vertex based on the field and add some noise
		# for organic detail.
		# THE AXIS. Was the literal 0.2; `relief` returns exactly that.
		vertex += normal * (field_value - surface_threshold) * depth
		vertex += normal * noise.get_noise_3d(
			vertex.x * 2.0, 
			vertex.y * 2.0, 
			vertex.z * 2.0
		) * 0.1
		
		# Set the modified vertex
		mdt.set_vertex(i, vertex)
	
	# Create a new mesh from our modified data
	var output_mesh = ArrayMesh.new()
	mdt.commit_to_surface(output_mesh)
	
	# Add the output mesh to our surface tool
	st.append_from(output_mesh, 0, Transform3D.IDENTITY)

func calculate_metaball_field(point):
	# Calculate the metaball field value at a given point
	var field_value = 0.0
	
	for mb in metaballs:
		var distance = point.distance_to(mb.position)
		
		# Metaball field function (inverse square)
		if distance < mb.radius * 3.0:
			field_value += pow(mb.radius / max(distance, 0.001), 2)
	
	return field_value

func setup_lighting() -> void:
	# Set up lighting to highlight the organic forms
	
	# Main directional light
	var dir_light = DirectionalLight3D.new()
	dir_light.position = Vector3(5, 5, 5)
	dir_light.light_color = Color(1.0, 0.95, 0.9)
	dir_light.shadow_enabled = true
	add_child(dir_light)
	_owned.append(dir_light)
	dir_light.look_at(Vector3.ZERO, Vector3.UP)
	
	# Fill light
	var fill_light = DirectionalLight3D.new()
	fill_light.position = Vector3(-5, -2, 3)
	fill_light.light_color = Color(0.9, 0.8, 0.85)
	fill_light.light_energy = 0.5
	add_child(fill_light)
	_owned.append(fill_light)
	fill_light.look_at(Vector3.ZERO, Vector3.UP)
	
	# Rim light for the organic highlights
	var rim_light = OmniLight3D.new()
	rim_light.position = Vector3(0, 0, -5)
	rim_light.light_color = Color(1.0, 0.9, 0.9)
	rim_light.light_energy = 0.8
	rim_light.omni_range = 10
	add_child(rim_light)
	_owned.append(rim_light)
	
	# Set up environment
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	
	# Sky settings
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.9, 0.8, 0.8)
	
	# Ambient light
	env.ambient_light_color = Color(0.9, 0.8, 0.8)
	env.ambient_light_energy = 0.2
	
	# Fog for depth
	env.fog_enabled = true
	env.fog_density = 0.01
	
	# Post-processing effects
	env.ssao_enabled = true
	env.ssao_radius = 0.5
	env.ssao_intensity = 2.0
	env.glow_enabled = true
	
	environment.environment = env
	# EMBEDDED CHROME, left alone deliberately. This WorldEnvironment (pale pink
	# background, fog, SSAO, glow) is a standalone-demo habit: an artifact that
	# ships its own sky clobbers the room it is placed in. Removing it would
	# change what the live placement draws, so it stays and is reported instead.
	# It does not reach the DNA sweep: capture_config_sweep puts the look on
	# Camera3D.environment, a per-camera override that wins over any
	# WorldEnvironment, and creates no such node of its own.
	add_child(environment)
	_owned.append(environment)


## Rebuild from the current values. Frees nothing: the body is one MeshInstance3D
## and three lights, all reused. Nodes this script created are tracked in _owned
## and freed only at teardown.
func _rebuild() -> void:
	_seed_rng()
	noise.seed = _rand_int()
	metaballs.clear()
	create_metaballs()
	time = 0.0
	if pose_time >= 0.0:
		_run_pose(pose_time)
	else:
		set_process(true)
		generate_mesh()


func _exit_tree() -> void:
	# Free ONLY what this script created. Was `for child in get_children(): if
	# not child.owner: child.queue_free()` — the same set for this scene, since
	# the .tscn's Camera3D and OmniLight3D both carry an owner, but that version
	# would also have taken an ownerless node added by anything else.
	for n in _owned:
		if is_instance_valid(n):
			n.queue_free()
	_owned.clear()


## Config from a map token. Guarded twice — a value is taken only when it
## validates AND differs, and _rebuild() fires only after _ready has built once.
## The single placement is `nakama_metaballs:0:0:0.2` in ISO_Metaballs — rotation,
## y_offset and scale, no config key — and the registry declares no
## default_params, so this is handed an empty dictionary and returns on line one.
## The two curation_station rosters that name this token pass nothing either.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return

	var changed: bool = false

	if config.has("imprint"):
		var v: String = str(config["imprint"]).to_lower()
		if IMPRINT_DEPTH.has(v) and v != imprint:
			imprint = v
			changed = true

	if config.has("metaball_seed"):
		var s: int = int(config["metaball_seed"])
		if s != metaball_seed:
			metaball_seed = s
			changed = true

	if config.has("pose_time"):
		var p: float = float(config["pose_time"])
		if not is_equal_approx(p, pose_time):
			pose_time = p
			changed = true

	if not changed:
		return
	# Before the first build there is nothing to redraw — _ready will pick the
	# new values up when it runs.
	if not _built:
		return
	_rebuild()
