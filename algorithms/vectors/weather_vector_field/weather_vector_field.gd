extends "res://algorithms/vectors/shared/vector_scene_base.gd"
## Weather Vector Field — Applied Teaching Artifact (Storm Chamber edition)
##
## Two grabbable wind vectors (Wind A, Wind B) combine via vector addition.
## The user drags arrow endpoints in VR to feel how wind directions sum.
## A dense field of display arrows shows the resulting wind field. Real
## GPUParticles3D weather — slanting rain, drifting cloud slabs, swaying ground
## mist, wind-blown debris, and storm lightning — all blow at the true resultant
## angle, demonstrating force superposition visibly.
##
## The space is a walkable STORM CHAMBER (~5x5 m). Real instruments ring the
## perimeter — a windsock, a 3-cup anemometer, a compass rose, and fading wind
## streamlines — every one of them DRIVEN by the live summed wind vector, and so
## is every particle system: rain gravity = down + wind, debris direction =
## wind.normalized(), clouds/mist drift on wind. Change the weather mode (calm /
## breezy / storm / blizzard) or drag the wind handles and the whole chamber
## reacts. The field and ground tint warm/cool with the wind's thermal sign.
##
## @identity
## essence: R = A + B; F_rain = gravity + wind. Vector addition drives the field, the instruments, and every GPU particle system at once. Superposition made meteorological — a whole storm chamber that agrees on one vector.
## desire: To let the learner walk inside a storm, drag two wind arrows, and watch real rain slant, debris streak downwind, clouds and mist drift, lightning strike downwind — all at the resultant angle, while the classic instruments read the same vector.
## critical_parameter: gravity_strength — it competes with wind. High gravity = rain falls nearly vertical; low gravity = rain flies nearly horizontal. The ratio is the slant angle, and the rain emitter's gravity is literally down + wind.
## triggers: Drag wind handles → field arrows reorient, rain re-slants, debris reaims downwind, clouds/mist advect, windsock yaws, anemometer spins, compass swings, ground tints. Mode button → calm/breezy/storm/blizzard palettes (amount, scale, color, drift, lightning). Pressure slider → zones distort the field.
## emerges: Rain streaking diagonally as the decomposition display shows wind + gravity = trajectory. Debris flung downwind as the headline vector in flight. Lightning forking out of a storm sky, biased downwind. A blizzard of slow white snow when the mode flips.
## needs: VR grabbable wind vectors [has], mode/grid/reset buttons [has], gravity/pressure sliders [has], temperature gradient coloring [has], weather instruments [has], GPU particle storm [has].
## relationships: Applied extension of vector_addition_demo and VectorFieldFlow (MultiMesh field). Particle systems built on the GPUParticles3D taxonomy in physicssimulation/particlesystems (rain from snow box-emitter), particle_campfire (cloud color curves), sub_emitters (lightning spark burst), lifetime_curves (flash/fade), NatureRenderer (ambient GPU drift).
## truth: Wind is a vector field. Rain is a particle advected through two fields at once. Every instrument AND every particle in a storm is a different read of the same vector.


# ── Sizing / domain ──
# world_size is the target walkable extent in metres. The base class SCENE_SCALE
# (a const, 0.33) and this node's local scale (0.5) already shrink the scene; we
# fold an extra world_scale multiplier on top so the station can grow without
# touching the shared const. domain_extent is the half-width of the field in the
# scene's *unit* space (pre-scale), used for grid spread, cloud wrap, rain spawn.
@export var world_size: float = 5.0      # target walkable size in metres (~5x5 m)
@export var arrow_grid_size: int = 12    # arrows per side (12x12 = 144) — MultiMesh
@export var rain_count: int = 460        # rain streak particles — GPUParticles3D
@export var cloud_count: int = 26         # cloud wisp quads — GPUParticles3D (fewer = no grey wall)

var world_scale: float = 1.0             # extra multiplier on SCENE_SCALE (derived)
var domain_extent: float = 3.0           # half-extent in unit space (derived)

# Effective scene scale (SCENE_SCALE * world_scale). All world->local placement
# multiplies by this instead of the bare SCENE_SCALE so the station scales whole.
func _sc() -> float:
	return SCENE_SCALE * world_scale

# ── Grabbable wind vectors ──
var wind_a: Node3D
var wind_b: Node3D
var resultant: Node3D
# Soft additive glow halo riding the resultant's tip — the summed wind reads as
# the brightest thing in the chamber. Pulses gently in _process.
var _resultant_glow: MeshInstance3D
var _resultant_glow_mat: StandardMaterial3D
var _glow_pulse_t: float = 0.0

# ── Caching for per-frame reads ──
var _cached_a: Dictionary = {}
var _cached_b: Dictionary = {}
var _cached_sum: Dictionary = {}

# ── Dotted line parallelogram ──
var dotted_line_a: MultiMeshInstance3D
var dotted_line_b: MultiMeshInstance3D
static var _dot_mesh: SphereMesh

# ── Display arrow grid (MultiMesh — shaft + head) ──
var grid_spacing: float = 0.5
var grid_visible := true
var _arrow_origins: PackedVector3Array = PackedVector3Array()
var _arrow_count: int = 0
var _arrow_shaft_mm: MultiMeshInstance3D
var _arrow_head_mm: MultiMeshInstance3D

# ── Rain particles (GPUParticles3D — box emission above the field) ──
var gravity_strength: float = 1.0
var _rain_gpu: GPUParticles3D
var _rain_mat: ParticleProcessMaterial
var _rain_draw_mat: StandardMaterial3D
# Splash sub-emitter — tiny outward flecks where a drop dies near the floor.
var _splash_gpu: GPUParticles3D
var _splash_mat: ParticleProcessMaterial

# ── Cloud slab (GPUParticles3D — big soft drifting billboards) ──
var _cloud_gpu: GPUParticles3D
var _cloud_mat: ParticleProcessMaterial
var _cloud_draw_mat: StandardMaterial3D

# ── Ground mist (GPUParticles3D — wide faint slab swaying with wind) ──
var _mist_gpu: GPUParticles3D
var _mist_mat: ParticleProcessMaterial
var _mist_draw_mat: StandardMaterial3D

# ── Wind-blown debris / leaves (GPUParticles3D — the vector in flight) ──
var _debris_gpu: GPUParticles3D
var _debris_mat: ParticleProcessMaterial
var _debris_draw_mat: StandardMaterial3D

# ── Lightning (emissive zig-zag bolt + spark burst + flash light) ──
var _lightning_root: Node3D
var _lightning_bolt: MeshInstance3D
var _lightning_bolt_mesh: ImmediateMesh
var _lightning_bolt_mat: StandardMaterial3D
var _lightning_sparks: GPUParticles3D
var _lightning_light: OmniLight3D
var _lightning_cooldown: float = 0.0
var _lightning_flash: float = 0.0        # 0..1 decaying flash intensity (bolt visibility)
var _lightning_glow: float = 0.0         # 0..1 slow afterglow that lights the field after the bolt fades
var _thunder_delay: float = 0.0          # seconds until the delayed afterglow swell fires
var _thunder_pending: bool = false

# ── Calm-mode sun shaft (faint cone + rising motes) ──
var _sun_shaft: MeshInstance3D
var _sun_shaft_mat: StandardMaterial3D
var _sun_motes: GPUParticles3D
var _sun_motes_mat: ParticleProcessMaterial
var _sun_pulse_t: float = 0.0

# ── Pressure zones ──
var high_pressure: Node3D
var low_pressure: Node3D
var pressure_intensity: float = 0.5
var pressure_time: float = 0.0

# ── Decomposition display ──
var decomp_wind_arrow: MeshInstance3D
var decomp_gravity_arrow: MeshInstance3D
var decomp_result_arrow: MeshInstance3D
var decomp_label: Label3D
var decomp_root: Node3D

# ── Info panel ──
var info_label: Label3D

# ── Ground (kept for temperature tinting) ──
var ground_mesh: MeshInstance3D
var ground_material: StandardMaterial3D

# ── Weather instruments ──
var windsock_yaw: Node3D                 # rotates to wind heading
var windsock_sleeve: MeshInstance3D      # stretches / lifts with magnitude
var windsock_material: StandardMaterial3D
var anemometer_spinner: Node3D           # spins; rate tracks wind speed
var _anemometer_angle: float = 0.0
var compass_needle: Node3D               # swings to wind heading
const STREAMLINE_COUNT := 5
const STREAMLINE_SEGMENTS := 16
var _streamline_mm: MultiMeshInstance3D
var _streamline_seeds: PackedVector3Array = PackedVector3Array()
static var _stream_dot_mesh: SphereMesh

# ── Weather modes ──
# Each mode preloads a wind pair (A, B) AND a particle palette. The palette is a
# small dict applied to the GPU emitters by _apply_weather_palette(mode):
#   amount      — droplet/debris density multiplier baseline
#   scale       — particle size multiplier
#   color       — base tint for rain/mist
#   drift_gain  — how strongly clouds/mist advect on wind
#   lightning   — whether storm lightning may fire in this mode
var current_mode: int = 0
const MODE_NAMES := ["Calm", "Breezy", "Storm", "Blizzard"]
const MODE_VECTORS_A := [
	Vector3(0.3, 0.0, 0.0),     # Calm: barely east
	Vector3(1.2, 0.0, 0.4),     # Breezy: gentle ESE
	Vector3(2.4, 0.0, 0.8),     # Storm: hard east
	Vector3(2.0, 0.0, -1.0),    # Blizzard: strong cross
]
const MODE_VECTORS_B := [
	Vector3(0.0, 0.05, 0.0),    # Calm: faint updraft
	Vector3(0.3, 0.0, 0.6),     # Breezy: NE component
	Vector3(0.6, 0.0, 1.4),     # Storm: strong N
	Vector3(1.0, 0.0, 1.2),     # Blizzard: more N
]
# Palettes indexed by mode. Plain typed dicts (no const — Color/Vector aren't
# const-foldable inside a const array in 4.x, so build them as a normal var).
var _mode_palettes: Array = []

# ── Floating labels for parallelogram ──
var label_a_copy: Label3D
var label_b_copy: Label3D

# ── Throttle text updates ──
var _text_timer: float = 0.0
const TEXT_INTERVAL: float = 0.1

# ── VR controls ──
var mode_button: Node3D
var grid_button: Node3D
var reset_button: Node3D
var gravity_slider: Node3D
var pressure_slider: Node3D
var status_label: Label3D


func _ready() -> void:
	super._ready()
	scale = Vector3(0.5, 0.5, 0.5)

	_init_mode_palettes()
	_recompute_sizing()
	_build_all()


## Builds the per-mode particle palettes. Called once in _ready (the dicts hold
## Color/Vector3, which can't be const-folded, so they live in a runtime array).
func _init_mode_palettes() -> void:
	# NOTE on cloud/mist alpha: these emitters use additive-style soft quads now,
	# so a LITTLE alpha goes a long way. Cloud alphas are deliberately tiny
	# (~0.05–0.16) — light accumulates where wisps overlap instead of stacking into
	# a grey wall. `ground_tint` drives a per-mode color-grade on the floor sheen.
	_mode_palettes = [
		# Calm — sparse warm light, sun shaft on, no lightning. Golden-hour palette.
		{
			"amount": 0.3, "scale": 0.9, "drift_gain": 0.25, "lightning": false,
			"rain_color": Color(0.6, 0.74, 1.0, 0.45),
			"mist_color": Color(0.78, 0.82, 0.92, 0.05),
			"cloud_color": Color(1.0, 0.93, 0.82, 0.07),
			"ground_tint": Color(0.18, 0.14, 0.11),
			"wet": 0.0,
			"sun": true,
		},
		# Breezy — moderate rain, light drift, cool-neutral, no lightning.
		{
			"amount": 0.62, "scale": 0.95, "drift_gain": 0.45, "lightning": false,
			"rain_color": Color(0.58, 0.74, 1.0, 0.7),
			"mist_color": Color(0.68, 0.76, 0.9, 0.07),
			"cloud_color": Color(0.74, 0.8, 0.92, 0.08),
			"ground_tint": Color(0.1, 0.13, 0.18),
			"wet": 0.45,
			"sun": false,
		},
		# Storm — dense bright rain, strong drift, lightning fires. Deep cool blue.
		{
			"amount": 1.0, "scale": 1.1, "drift_gain": 0.7, "lightning": true,
			"rain_color": Color(0.66, 0.82, 1.0, 0.95),
			"mist_color": Color(0.42, 0.5, 0.68, 0.1),
			"cloud_color": Color(0.4, 0.46, 0.62, 0.14),
			"ground_tint": Color(0.06, 0.1, 0.2),
			"wet": 1.0,
			"sun": false,
		},
		# Blizzard — white snow, low gravity, wide spread, lightning fires.
		{
			"amount": 0.95, "scale": 1.35, "drift_gain": 0.85, "lightning": true,
			"rain_color": Color(0.96, 0.98, 1.0, 0.95),
			"mist_color": Color(0.86, 0.9, 1.0, 0.12),
			"cloud_color": Color(0.82, 0.86, 0.96, 0.13),
			"ground_tint": Color(0.12, 0.15, 0.22),
			"wet": 0.7,
			"sun": false,
			"snow": true,
		},
	]


func _build_all() -> void:
	_build_ground_plane()
	_spawn_wind_vectors()
	_build_parallelogram()
	_build_grid_arrows()
	_build_rain_particles()
	_build_cloud_slab()
	_build_ground_mist()
	_build_debris()
	_build_lightning()
	_build_sun_shaft()
	_build_pressure_zones()
	_build_decomposition_display()
	_build_instruments()
	_build_controls()

	info_label = create_info_panel(
		"Weather Vector Field",
		Vector3(0.0, 4.5, -domain_extent - 1.0),
		Vector2(3.0, 1.2),
		"R = A + B\nF_rain = gravity + wind",
		"Vector addition\nForce superposition"
	)

	# Set initial mode
	_apply_mode(0)


## Derives world_scale, domain_extent, and grid_spacing from world_size.
## At world_size 5 we roughly double the prior ~2.3 m footprint.
func _recompute_sizing() -> void:
	world_size = clampf(world_size, 2.0, 14.0)
	# Empirically the prior build was ~2.3 m walkable at world_scale 1.0. The full
	# multiplier on a unit position is SCENE_SCALE(0.33) * scale(0.5) = 0.165, and
	# the field spanned ~6 units -> ~1.0 m mesh / ~2.3 m AABB. To hit world_size m
	# of field span, world_scale = world_size / (2 * domain_extent * 0.165).
	domain_extent = 3.0
	var unit_span := 2.0 * domain_extent          # field spans -extent..+extent
	var base_mult := SCENE_SCALE * 0.5             # 0.165
	world_scale = world_size / (unit_span * base_mult)
	world_scale = clampf(world_scale, 0.5, 6.0)
	grid_spacing = unit_span / float(max(arrow_grid_size - 1, 1))


func _process(delta: float) -> void:
	# Read grabbable vectors
	var a := _get_vector_fast(wind_a, _cached_a)
	var b := _get_vector_fast(wind_b, _cached_b)
	var sum := a + b

	# Update computed resultant
	_update_vector_fast(resultant, sum, _cached_sum)

	# Pulse the resultant glow — brighter + larger with the summed magnitude, with
	# a gentle breathing pulse so it always reads as the live, important vector.
	if _resultant_glow_mat and _resultant_glow:
		_glow_pulse_t += delta
		var mag: float = sum.length()
		var pulse: float = 0.85 + 0.15 * sin(_glow_pulse_t * 3.0)
		var energy: float = (2.2 + clampf(mag, 0.0, 4.0) * 0.6) * pulse
		_resultant_glow_mat.emission_energy_multiplier = energy
		var halo: float = (0.7 + clampf(mag, 0.0, 4.0) * 0.18) * pulse
		_resultant_glow.scale = Vector3.ONE * halo
		_resultant_glow.visible = mag > 0.05

	# Update parallelogram dotted lines
	_update_dotted_lines(a, b, sum)

	# Update floating labels
	var sc := _sc()
	if label_b_copy:
		label_b_copy.position = (a + b * 0.5) * sc + Vector3(0, 0.08, 0) * sc
	if label_a_copy:
		label_a_copy.position = (b + a * 0.5) * sc + Vector3(0, 0.08, 0) * sc

	# Animate pressure zones
	pressure_time += delta * 0.3
	_update_pressure_zones()

	# Update wind field grid (MultiMesh)
	if grid_visible:
		_update_grid_arrows(a, b)

	# Drive every GPU particle system from the live summed wind vector.
	_drive_rain(sum)
	_drive_clouds(sum)
	_drive_mist(sum)
	_drive_debris(sum)
	_drive_lightning(delta, sum)
	_drive_sun_shaft(delta, sum)

	# Update decomposition arrows
	_update_decomposition(sum)

	# Weather instruments — all driven by the live summed wind vector
	_update_instruments(delta, sum)
	_update_streamlines(a, b)
	_update_temperature_tint(sum)

	# Throttled text update
	_text_timer += delta
	if _text_timer >= TEXT_INTERVAL:
		_text_timer = 0.0
		_update_info_text(a, b, sum)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_W:
				_cycle_mode()
			KEY_T:
				_toggle_grid()
			KEY_R:
				reset()
			KEY_UP:
				gravity_strength = clampf(gravity_strength + 0.1, 0.0, 2.0)
			KEY_DOWN:
				gravity_strength = clampf(gravity_strength - 0.1, 0.0, 2.0)
			KEY_LEFT:
				pressure_intensity = clampf(pressure_intensity - 0.1, 0.0, 1.0)
			KEY_RIGHT:
				pressure_intensity = clampf(pressure_intensity + 0.1, 0.0, 1.0)
			KEY_1:
				_apply_mode(0)
			KEY_2:
				_apply_mode(1)
			KEY_3:
				_apply_mode(2)
			KEY_4:
				_apply_mode(3)


# ════════════════════════════════════════════════════════════════════
#  SETUP
# ════════════════════════════════════════════════════════════════════

func _build_ground_plane() -> void:
	var sc := _sc()
	var span := 2.0 * domain_extent + 0.6   # a little wider than the field
	ground_mesh = MeshInstance3D.new()
	ground_mesh.name = "Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(span, span)
	ground_mesh.mesh = plane
	ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.08, 0.1, 0.14, 0.9)
	ground_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Start matte/dry; _update_temperature_tint raises metallic + lowers roughness
	# per the active mode's `wet` value so the storm floor turns reflective.
	ground_material.roughness = 0.85
	ground_material.metallic = 0.0
	ground_material.metallic_specular = 0.7
	ground_material.emission_enabled = true
	ground_material.emission = Color(0.05, 0.06, 0.09)
	ground_material.emission_energy_multiplier = 0.3
	ground_mesh.material_override = ground_material
	ground_mesh.scale = Vector3.ONE * sc
	ground_mesh.position = Vector3(0, -0.01, 0) * sc
	environment_root.add_child(ground_mesh)

	# Subtle grid lines on ground
	var n := int(round(domain_extent))
	for i in range(-n, n + 1):
		_draw_ground_line(Vector3(float(i), 0, -domain_extent),
						  Vector3(float(i), 0, domain_extent),
						  Color(0.2, 0.25, 0.35, 0.3))
		_draw_ground_line(Vector3(-domain_extent, 0, float(i)),
						  Vector3(domain_extent, 0, float(i)),
						  Color(0.2, 0.25, 0.35, 0.3))


func _draw_ground_line(from: Vector3, to: Vector3, color: Color) -> void:
	var sc := _sc()
	var mesh_inst := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_set_color(color)
	im.surface_add_vertex(from * sc)
	im.surface_add_vertex(to * sc)
	im.surface_end()
	mesh_inst.mesh = im
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mesh_inst.material_override = mat
	environment_root.add_child(mesh_inst)


func _spawn_wind_vectors() -> void:
	# spawn_vector uses the bare SCENE_SCALE from the base class for placement.
	# That's fine — the grabbable handles live at SCENE_SCALE; we read them back
	# via _get_vector_fast which divides out (SCENE_SCALE * scale.x), giving us a
	# scale-independent vector. Instrument/field placement uses _sc() instead.
	# Wind A — cyan, grabbable
	wind_a = spawn_vector(
		Vector3(-1.0, 0.3, 0.0),
		Vector3(1.0, 0.0, 0.5),
		Color(0.3, 0.85, 0.95),
		"Wind A",
		true
	)
	# Wind B — magenta, grabbable
	wind_b = spawn_vector(
		Vector3(-1.0, 0.3, 0.0),
		Vector3(-0.5, 0.0, 1.0),
		Color(0.9, 0.3, 0.8),
		"Wind B",
		true
	)
	# Resultant — yellow, non-grabbable (computed)
	resultant = spawn_vector(
		Vector3(-1.0, 0.3, 0.0),
		Vector3.ZERO,
		Color(1.0, 0.9, 0.2),
		"A + B",
		false
	)

	# Cache nodes for fast per-frame access
	_cache_vector_nodes(wind_a, _cached_a)
	_cache_vector_nodes(wind_b, _cached_b)
	_cache_vector_nodes(resultant, _cached_sum)

	# Glow halo on the resultant tip — the summed wind glows brightest of all.
	_build_resultant_glow()


## A soft additive billboard quad parented to the resultant's tip. It rides the
## tip every frame and pulses, marking the summed vector as the chamber's
## brightest, most important light. No extra dynamic light — pure emissive quad.
func _build_resultant_glow() -> void:
	var end_node: Node3D = _cached_sum.get("end")
	if end_node == null:
		return
	_resultant_glow = MeshInstance3D.new()
	_resultant_glow.name = "ResultantGlow"
	var quad := QuadMesh.new()
	# Sized in the resultant's local space (it inherits SCENE_SCALE from the arrow).
	quad.size = Vector2(0.42, 0.42)
	_resultant_glow_mat = StandardMaterial3D.new()
	_resultant_glow_mat.albedo_color = Color(1.0, 0.92, 0.35, 0.9)
	_resultant_glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_resultant_glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_resultant_glow_mat.emission_enabled = true
	_resultant_glow_mat.emission = Color(1.0, 0.88, 0.3)
	_resultant_glow_mat.emission_energy_multiplier = 3.2
	_resultant_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_resultant_glow_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_resultant_glow_mat.billboard_keep_scale = true
	_resultant_glow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_resultant_glow_mat.disable_receive_shadows = true
	quad.material = _resultant_glow_mat
	_resultant_glow.mesh = quad
	_resultant_glow.position = Vector3.ZERO
	end_node.add_child(_resultant_glow)


func _build_parallelogram() -> void:
	if _dot_mesh == null:
		_dot_mesh = SphereMesh.new()
		_dot_mesh.radius = 0.015
		_dot_mesh.height = 0.03
		_dot_mesh.radial_segments = 8
		_dot_mesh.rings = 4

	# Dotted lines matching each vector's color
	dotted_line_a = _create_dotted_line_multimesh(Color(0.3, 0.85, 0.95, 0.4))
	dotted_line_b = _create_dotted_line_multimesh(Color(0.9, 0.3, 0.8, 0.4))
	environment_root.add_child(dotted_line_a)
	environment_root.add_child(dotted_line_b)

	# Floating copy labels
	label_a_copy = _create_floating_label("A (copy)", Color(0.3, 0.85, 0.95, 0.6))
	label_b_copy = _create_floating_label("B (copy)", Color(0.9, 0.3, 0.8, 0.6))


# ── Field arrows: MultiMesh shaft + head (pattern from VectorFieldFlow.gd) ──

func _build_grid_arrows() -> void:
	_arrow_origins.clear()
	var half := float(arrow_grid_size - 1) * 0.5
	for gx in range(arrow_grid_size):
		for gz in range(arrow_grid_size):
			var ux: float = (float(gx) - half) * grid_spacing
			var uz: float = (float(gz) - half) * grid_spacing
			_arrow_origins.append(Vector3(ux, 0.15, uz))
	_arrow_count = _arrow_origins.size()

	# Shaft MultiMesh (unit cylinder, scaled per instance along its local Y)
	var shaft_cyl := CylinderMesh.new()
	shaft_cyl.top_radius = 0.008
	shaft_cyl.bottom_radius = 0.008
	shaft_cyl.height = 1.0
	shaft_cyl.radial_segments = 6
	var shaft_mm := MultiMesh.new()
	shaft_mm.transform_format = MultiMesh.TRANSFORM_3D
	shaft_mm.use_colors = true
	shaft_mm.instance_count = _arrow_count
	shaft_mm.mesh = shaft_cyl
	_arrow_shaft_mm = MultiMeshInstance3D.new()
	_arrow_shaft_mm.name = "FieldShaftMM"
	_arrow_shaft_mm.multimesh = shaft_mm
	_arrow_shaft_mm.material_override = _field_mm_material()
	environment_root.add_child(_arrow_shaft_mm)

	# Head MultiMesh (small cone)
	var head_cone := CylinderMesh.new()
	head_cone.top_radius = 0.0
	head_cone.bottom_radius = 0.02
	head_cone.height = 0.06
	head_cone.radial_segments = 8
	var head_mm := MultiMesh.new()
	head_mm.transform_format = MultiMesh.TRANSFORM_3D
	head_mm.use_colors = true
	head_mm.instance_count = _arrow_count
	head_mm.mesh = head_cone
	_arrow_head_mm = MultiMeshInstance3D.new()
	_arrow_head_mm.name = "FieldHeadMM"
	_arrow_head_mm.multimesh = head_mm
	_arrow_head_mm.material_override = _field_mm_material()
	environment_root.add_child(_arrow_head_mm)


func _field_mm_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	# Brighter unshaded glow so the field arrows pop against the dark storm. Their
	# per-instance vertex colour already encodes magnitude (blue->yellow->red); the
	# emission energy makes those colours read as light, not paint.
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


# ── Rain: GPUParticles3D streaks (box emitter above the field, from the snow
#    box-emitter in physicssimulation/particlesystems/ParticleSystems.gd) ──
#
# Lives under environment_root, which inherits the 0.5 root scale. As with the
# old MultiMesh, every world quantity is multiplied by _sc() only (NOT by 0.5);
# the root 0.5 is applied by the node transform. So gravity/velocity/extent are
# all scaled by _sc() to keep the rain falling at a believable rate.

func _build_rain_particles() -> void:
	var sc := _sc()
	_rain_gpu = GPUParticles3D.new()
	_rain_gpu.name = "RainGPU"
	_rain_gpu.amount = max(1, rain_count)
	_rain_gpu.lifetime = 1.6
	# Emit from a box high above the field; particles fall through it.
	_rain_gpu.position = Vector3(0.0, 3.4, 0.0) * sc
	# Generous AABB so streaks aren't culled while they fall across the chamber.
	_rain_gpu.visibility_aabb = AABB(
		Vector3(-domain_extent - 1.0, -2.0, -domain_extent - 1.0) * sc,
		Vector3(2.0 * domain_extent + 2.0, 8.0, 2.0 * domain_extent + 2.0) * sc
	)

	_rain_mat = ParticleProcessMaterial.new()
	_rain_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_rain_mat.emission_box_extents = Vector3(domain_extent * 0.95, 0.1, domain_extent * 0.95) * sc
	_rain_mat.direction = Vector3(0.0, -1.0, 0.0)
	_rain_mat.spread = 4.0
	# Faster drops so streaks read as motion, not floating dashes.
	_rain_mat.initial_velocity_min = 0.8 * sc
	_rain_mat.initial_velocity_max = 1.6 * sc
	# Gravity is overwritten each frame as (down*gravity_strength + wind) * sc.
	_rain_mat.gravity = Vector3(0.0, -gravity_strength, 0.0) * 9.8 * sc
	# Per-drop length variety; _drive_rain stretches the whole sheet with speed.
	_rain_mat.scale_min = 0.7
	_rain_mat.scale_max = 1.3
	_rain_mat.color = Color(0.66, 0.82, 1.0, 0.95)
	_rain_gpu.process_material = _rain_mat

	# Tall, thin quad = a streak. BILLBOARD_PARTICLES orients the quad along the
	# particle's velocity, so when the gravity vector is (down + wind) the streak
	# tilts to the true resultant slant angle — the lesson, drawn by the geometry.
	var streak := QuadMesh.new()
	# Thinner + longer than before for a sharp bright line of falling light.
	streak.size = Vector2(0.009, 0.46) * sc
	_rain_draw_mat = StandardMaterial3D.new()
	_rain_draw_mat.vertex_color_use_as_albedo = true
	_rain_draw_mat.albedo_color = Color(0.66, 0.82, 1.0, 0.95)
	_rain_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Additive so each streak catches light against the dark storm — bright,
	# cool, and never muddy when streaks cross.
	_rain_draw_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_rain_draw_mat.emission_enabled = true
	_rain_draw_mat.emission = Color(0.55, 0.74, 1.0)
	_rain_draw_mat.emission_energy_multiplier = 2.2
	_rain_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_rain_draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_rain_draw_mat.billboard_keep_scale = true
	_rain_draw_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	streak.material = _rain_draw_mat
	_rain_gpu.draw_pass_1 = streak
	environment_root.add_child(_rain_gpu)

	# Splash ring sub-emitter: when a drop expires near the floor it spawns a tiny
	# burst of low outward flecks — a wet "tick" on the ground. Bounded + cheap.
	_build_rain_splash(sc)


## A small splash burst emitter wired as the rain's sub-emitter. Godot spawns a
## few of these at each parent particle's death position, giving a faint wet ring
## of flecks where rain meets the floor. Capped (amount 20) for VR perf.
func _build_rain_splash(sc: float) -> void:
	_splash_gpu = GPUParticles3D.new()
	_splash_gpu.name = "RainSplash"
	_splash_gpu.amount = 20
	_splash_gpu.lifetime = 0.45
	_splash_gpu.emitting = false   # only emits when triggered by the parent's death
	_splash_gpu.local_coords = false
	_splash_gpu.visibility_aabb = AABB(
		Vector3(-domain_extent - 1.0, -0.5, -domain_extent - 1.0) * sc,
		Vector3(2.0 * domain_extent + 2.0, 2.0, 2.0 * domain_extent + 2.0) * sc
	)
	_splash_mat = ParticleProcessMaterial.new()
	_splash_mat.direction = Vector3(0.0, 1.0, 0.0)
	_splash_mat.spread = 75.0
	_splash_mat.flatness = 0.85   # bias the burst outward/flat like a ring
	_splash_mat.initial_velocity_min = 0.15 * sc
	_splash_mat.initial_velocity_max = 0.5 * sc
	_splash_mat.gravity = Vector3(0.0, -4.0, 0.0) * sc
	_splash_mat.scale_min = 0.4
	_splash_mat.scale_max = 0.8
	_splash_mat.color = Color(0.7, 0.85, 1.0, 0.85)
	_splash_gpu.process_material = _splash_mat

	var fleck := QuadMesh.new()
	fleck.size = Vector2(0.012, 0.012) * sc
	var fleck_draw := StandardMaterial3D.new()
	fleck_draw.albedo_color = Color(0.7, 0.85, 1.0, 0.85)
	fleck_draw.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fleck_draw.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fleck_draw.emission_enabled = true
	fleck_draw.emission = Color(0.55, 0.75, 1.0)
	fleck_draw.emission_energy_multiplier = 1.6
	fleck_draw.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fleck_draw.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fleck_draw.billboard_keep_scale = true
	fleck_draw.cull_mode = BaseMaterial3D.CULL_DISABLED
	fleck.material = fleck_draw
	_splash_gpu.draw_pass_1 = fleck
	environment_root.add_child(_splash_gpu)

	# Wire it as the rain's sub-emitter: a few flecks at each drop's death point.
	if _rain_mat:
		_rain_mat.sub_emitter_mode = ParticleProcessMaterial.SUB_EMITTER_AT_END
		_rain_mat.sub_emitter_amount_at_end = 3
	if _rain_gpu:
		_rain_gpu.sub_emitter = _rain_gpu.get_path_to(_splash_gpu)


# ── Cloud slab: GPUParticles3D big soft drifting billboards ──
# Slow, large, expanding quads at mid-height. Drift is applied each frame by
# writing the wind into process_material.gravity (a horizontal "gravity" pushes
# the slab sideways on the wind). Colour curve from particle_campfire smoke.

func _build_cloud_slab() -> void:
	var sc := _sc()
	_cloud_gpu = GPUParticles3D.new()
	_cloud_gpu.name = "CloudGPU"
	_cloud_gpu.amount = max(1, cloud_count)
	# Longer life + slow spawn = sparse coverage. Fewer puffs on screen at once,
	# so they read as drifting wisps instead of an overlapping fog wall.
	_cloud_gpu.lifetime = 13.0
	_cloud_gpu.position = Vector3(0.0, 2.85, 0.0) * sc
	_cloud_gpu.visibility_aabb = AABB(
		Vector3(-2.0 * domain_extent, -1.0, -2.0 * domain_extent) * sc,
		Vector3(4.0 * domain_extent, 4.0, 4.0 * domain_extent) * sc
	)

	_cloud_mat = ParticleProcessMaterial.new()
	_cloud_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	# Spread the spawn box wider + thicker so the few puffs distribute in depth
	# (less stacking on one plane = less opaque overlap).
	_cloud_mat.emission_box_extents = Vector3(domain_extent * 1.3, 0.7, domain_extent * 1.3) * sc
	_cloud_mat.direction = Vector3(1.0, 0.0, 0.0)
	_cloud_mat.spread = 8.0
	_cloud_mat.initial_velocity_min = 0.02 * sc
	_cloud_mat.initial_velocity_max = 0.08 * sc
	_cloud_mat.gravity = Vector3.ZERO          # set to wind drift each frame
	# Smaller min so puffs don't all blanket the sky; range gives size variety.
	_cloud_mat.scale_min = 0.9
	_cloud_mat.scale_max = 2.2
	# Soft expand over life so each wisp swells then thins like real cloud edges.
	var cloud_scale_curve := _make_grow_curve_texture()
	_cloud_mat.scale_curve = cloud_scale_curve
	_cloud_mat.color = Color(0.74, 0.8, 0.92, 0.12)
	# Fade in then out so wisp edges are soft (smoke-style alpha curve).
	_cloud_mat.color_ramp = _make_soft_alpha_ramp(Color(0.74, 0.8, 0.92))
	_cloud_gpu.process_material = _cloud_mat

	var puff := QuadMesh.new()
	# Smaller base quad — overlap now adds light gently rather than blocking it.
	puff.size = Vector2(0.6, 0.6) * sc
	_cloud_draw_mat = StandardMaterial3D.new()
	_cloud_draw_mat.albedo_color = Color(0.74, 0.8, 0.92, 0.12)
	_cloud_draw_mat.vertex_color_use_as_albedo = true
	_cloud_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Additive-ish blend: overlapping wisps brighten softly instead of forming an
	# opaque grey wall. This is the core washout fix.
	_cloud_draw_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_cloud_draw_mat.emission_enabled = true
	_cloud_draw_mat.emission = Color(0.55, 0.62, 0.78)
	_cloud_draw_mat.emission_energy_multiplier = 0.45
	_cloud_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cloud_draw_mat.roughness = 1.0
	_cloud_draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_cloud_draw_mat.billboard_keep_scale = true
	_cloud_draw_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Render behind rain/instruments so additive haze never washes foreground glow.
	_cloud_draw_mat.render_priority = -2
	puff.material = _cloud_draw_mat
	_cloud_gpu.draw_pass_1 = puff
	environment_root.add_child(_cloud_gpu)


# ── Ground mist: wide thin GPUParticles3D slab at y≈0.1, huge faint quads ──

func _build_ground_mist() -> void:
	var sc := _sc()
	_mist_gpu = GPUParticles3D.new()
	_mist_gpu.name = "MistGPU"
	_mist_gpu.amount = max(1, int(cloud_count * 0.6))
	_mist_gpu.lifetime = 7.0
	_mist_gpu.position = Vector3(0.0, 0.1, 0.0) * sc
	_mist_gpu.visibility_aabb = AABB(
		Vector3(-2.0 * domain_extent, -0.5, -2.0 * domain_extent) * sc,
		Vector3(4.0 * domain_extent, 2.0, 4.0 * domain_extent) * sc
	)

	_mist_mat = ParticleProcessMaterial.new()
	_mist_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	# Keep the spawn box thin and low so wisps cling to the floor.
	_mist_mat.emission_box_extents = Vector3(domain_extent * 1.2, 0.04, domain_extent * 1.2) * sc
	_mist_mat.direction = Vector3(1.0, 0.0, 0.0)
	_mist_mat.spread = 10.0
	_mist_mat.initial_velocity_min = 0.01 * sc
	_mist_mat.initial_velocity_max = 0.05 * sc
	_mist_mat.gravity = Vector3.ZERO           # set to wind drift each frame
	_mist_mat.scale_min = 1.8
	_mist_mat.scale_max = 3.2
	_mist_mat.scale_curve = _make_grow_curve_texture()   # wisps swell + thin
	_mist_mat.color = Color(0.7, 0.78, 0.9, 0.08)
	_mist_mat.color_ramp = _make_soft_alpha_ramp(Color(0.7, 0.78, 0.9))
	_mist_gpu.process_material = _mist_mat

	var slab := QuadMesh.new()
	slab.size = Vector2(1.2, 1.2) * sc
	# Lay the mist quads flat-ish by orienting them as billboards (they read as
	# soft ground fog either way; keeping billboard avoids edge-on disappearance).
	_mist_draw_mat = StandardMaterial3D.new()
	_mist_draw_mat.albedo_color = Color(0.7, 0.78, 0.9, 0.08)
	_mist_draw_mat.vertex_color_use_as_albedo = true
	_mist_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Additive low wisps: soft glow near the floor instead of a flat grey sheet.
	_mist_draw_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mist_draw_mat.emission_enabled = true
	_mist_draw_mat.emission = Color(0.5, 0.6, 0.78)
	_mist_draw_mat.emission_energy_multiplier = 0.35
	_mist_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mist_draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_mist_draw_mat.billboard_keep_scale = true
	_mist_draw_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mist_draw_mat.render_priority = -3
	slab.material = _mist_draw_mat
	_mist_gpu.draw_pass_1 = slab
	environment_root.add_child(_mist_gpu)


# ── Wind-blown debris / leaves: the headline "vector in flight" ──
# Direction + initial_velocity are aimed downwind each frame, so the streak of
# debris IS the wind vector made visible. Emitted from the upwind edge.

func _build_debris() -> void:
	var sc := _sc()
	_debris_gpu = GPUParticles3D.new()
	_debris_gpu.name = "DebrisGPU"
	_debris_gpu.amount = 60
	_debris_gpu.lifetime = 2.4
	_debris_gpu.position = Vector3(0.0, 0.5, 0.0) * sc
	_debris_gpu.visibility_aabb = AABB(
		Vector3(-2.0 * domain_extent, -1.0, -2.0 * domain_extent) * sc,
		Vector3(4.0 * domain_extent, 4.0, 4.0 * domain_extent) * sc
	)

	_debris_mat = ParticleProcessMaterial.new()
	_debris_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_debris_mat.emission_box_extents = Vector3(domain_extent * 0.9, 0.6, domain_extent * 0.9) * sc
	_debris_mat.direction = Vector3(1.0, 0.0, 0.0)   # aimed downwind each frame
	_debris_mat.spread = 18.0
	_debris_mat.initial_velocity_min = 0.4 * sc
	_debris_mat.initial_velocity_max = 0.9 * sc
	# Light downward gravity so leaves settle; wind drift added each frame.
	_debris_mat.gravity = Vector3(0.0, -0.5, 0.0) * sc
	_debris_mat.scale_min = 0.6
	_debris_mat.scale_max = 1.2
	_debris_mat.angular_velocity_min = -180.0
	_debris_mat.angular_velocity_max = 180.0
	_debris_mat.color = Color(0.8, 0.7, 0.4, 0.9)
	_debris_gpu.process_material = _debris_mat

	var leaf := QuadMesh.new()
	leaf.size = Vector2(0.06, 0.04) * sc
	_debris_draw_mat = StandardMaterial3D.new()
	_debris_draw_mat.albedo_color = Color(0.8, 0.7, 0.4, 0.9)
	_debris_draw_mat.vertex_color_use_as_albedo = true
	_debris_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_debris_draw_mat.emission_enabled = true
	_debris_draw_mat.emission = Color(0.5, 0.42, 0.2)
	_debris_draw_mat.emission_energy_multiplier = 0.4
	_debris_draw_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_debris_draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_debris_draw_mat.billboard_keep_scale = true
	leaf.material = _debris_draw_mat
	_debris_gpu.draw_pass_1 = leaf
	environment_root.add_child(_debris_gpu)


# ── Lightning: emissive zig-zag ImmediateMesh bolt + one-shot spark burst +
#    OmniLight3D flash. Fires only in storm/blizzard modes, strike biased
#    downwind. (Spark burst pattern from sub_emitters; flash/fade from
#    lifetime_curves.) ──

func _build_lightning() -> void:
	var sc := _sc()
	_lightning_root = Node3D.new()
	_lightning_root.name = "Lightning"
	environment_root.add_child(_lightning_root)

	# Bolt — rebuilt as a fresh zig-zag each strike.
	_lightning_bolt = MeshInstance3D.new()
	_lightning_bolt.name = "Bolt"
	_lightning_bolt_mesh = ImmediateMesh.new()
	_lightning_bolt.mesh = _lightning_bolt_mesh
	_lightning_bolt_mat = StandardMaterial3D.new()
	_lightning_bolt_mat.albedo_color = Color(0.92, 0.97, 1.0)
	_lightning_bolt_mat.vertex_color_use_as_albedo = true
	_lightning_bolt_mat.emission_enabled = true
	_lightning_bolt_mat.emission = Color(0.85, 0.93, 1.0)
	# Much hotter core + additive blend so the bolt blooms white-hot.
	_lightning_bolt_mat.emission_energy_multiplier = 14.0
	_lightning_bolt_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_lightning_bolt_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_lightning_bolt_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_lightning_bolt_mat.render_priority = 4
	_lightning_bolt.material_override = _lightning_bolt_mat
	_lightning_bolt.visible = false
	_lightning_root.add_child(_lightning_bolt)

	# One-shot spark burst at the strike point.
	_lightning_sparks = GPUParticles3D.new()
	_lightning_sparks.name = "StrikeSparks"
	_lightning_sparks.amount = 40
	_lightning_sparks.lifetime = 0.6
	_lightning_sparks.one_shot = true
	_lightning_sparks.emitting = false
	_lightning_sparks.explosiveness = 1.0
	_lightning_sparks.visibility_aabb = AABB(
		Vector3(-domain_extent, -0.5, -domain_extent) * sc,
		Vector3(2.0 * domain_extent, 3.0, 2.0 * domain_extent) * sc
	)
	var spark_mat := ParticleProcessMaterial.new()
	spark_mat.direction = Vector3(0.0, 1.0, 0.0)
	spark_mat.spread = 80.0
	spark_mat.initial_velocity_min = 1.0 * sc
	spark_mat.initial_velocity_max = 3.0 * sc
	spark_mat.gravity = Vector3(0.0, -6.0, 0.0) * sc
	spark_mat.scale_min = 0.4
	spark_mat.scale_max = 0.8
	spark_mat.color = Color(0.9, 0.95, 1.0, 1.0)
	_lightning_sparks.process_material = spark_mat
	var spark_mesh := SphereMesh.new()
	spark_mesh.radius = 0.012 * sc
	spark_mesh.height = 0.024 * sc
	spark_mesh.radial_segments = 6
	spark_mesh.rings = 3
	var spark_draw := StandardMaterial3D.new()
	spark_draw.albedo_color = Color(0.92, 0.96, 1.0)
	spark_draw.emission_enabled = true
	spark_draw.emission = Color(0.85, 0.93, 1.0)
	spark_draw.emission_energy_multiplier = 5.0
	spark_draw.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	spark_draw.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mesh.material = spark_draw
	_lightning_sparks.draw_pass_1 = spark_mesh
	_lightning_root.add_child(_lightning_sparks)

	# Flash light — one pulsed OmniLight that briefly lights the whole field +
	# clouds. Wide range, high peak energy; energy is driven to 0 between strikes
	# so it costs nothing when idle. This is the only dynamic light we add.
	_lightning_light = OmniLight3D.new()
	_lightning_light.name = "Flash"
	_lightning_light.light_color = Color(0.82, 0.9, 1.0)
	_lightning_light.light_energy = 0.0
	# Reach across the whole chamber so the strike actually illuminates the room.
	_lightning_light.omni_range = (2.0 * domain_extent + 3.0) * sc
	_lightning_light.omni_attenuation = 0.6
	_lightning_root.add_child(_lightning_light)

	_lightning_cooldown = randf_range(2.5, 5.0)


# ── Calm-mode sun shaft: faint emissive cone + slow rising motes ──

func _build_sun_shaft() -> void:
	var sc := _sc()
	_sun_shaft = MeshInstance3D.new()
	_sun_shaft.name = "SunShaft"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.15
	cone.bottom_radius = 0.9
	cone.height = 3.2
	cone.radial_segments = 16
	_sun_shaft.mesh = cone
	_sun_shaft.position = Vector3(domain_extent * 0.45, 1.7, -domain_extent * 0.45) * sc
	_sun_shaft.scale = Vector3.ONE * sc
	_sun_shaft_mat = StandardMaterial3D.new()
	# Faint warm volume. Additive so the shaft adds golden light without occluding
	# anything behind it — a believable god-ray, not a solid cone.
	_sun_shaft_mat.albedo_color = Color(1.0, 0.93, 0.62, 0.05)
	_sun_shaft_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_sun_shaft_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_sun_shaft_mat.emission_enabled = true
	_sun_shaft_mat.emission = Color(1.0, 0.9, 0.55)
	_sun_shaft_mat.emission_energy_multiplier = 0.9
	_sun_shaft_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_sun_shaft_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_sun_shaft_mat.render_priority = -1
	_sun_shaft.material_override = _sun_shaft_mat
	# Tilt the shaft so it rakes across the floor like low sun through a window.
	_sun_shaft.rotation_degrees = Vector3(0, 0, 14)
	_sun_shaft.visible = false
	environment_root.add_child(_sun_shaft)

	_sun_motes = GPUParticles3D.new()
	_sun_motes.name = "SunMotes"
	_sun_motes.amount = 30
	_sun_motes.lifetime = 5.0
	_sun_motes.position = Vector3(domain_extent * 0.45, 0.3, -domain_extent * 0.45) * sc
	_sun_motes.visibility_aabb = AABB(
		Vector3(-domain_extent, -0.5, -domain_extent) * sc,
		Vector3(2.0 * domain_extent, 4.0, 2.0 * domain_extent) * sc
	)
	_sun_motes_mat = ParticleProcessMaterial.new()
	_sun_motes_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_sun_motes_mat.emission_box_extents = Vector3(0.6, 0.1, 0.6) * sc
	_sun_motes_mat.direction = Vector3(0.0, 1.0, 0.0)
	_sun_motes_mat.spread = 20.0
	_sun_motes_mat.initial_velocity_min = 0.05 * sc
	_sun_motes_mat.initial_velocity_max = 0.15 * sc
	_sun_motes_mat.gravity = Vector3(0.0, 0.05, 0.0) * sc   # gentle rise
	_sun_motes_mat.scale_min = 0.4
	_sun_motes_mat.scale_max = 0.9
	_sun_motes_mat.color = Color(1.0, 0.95, 0.7, 0.5)
	_sun_motes.process_material = _sun_motes_mat
	var mote := QuadMesh.new()
	mote.size = Vector2(0.03, 0.03) * sc
	var mote_draw := StandardMaterial3D.new()
	mote_draw.albedo_color = Color(1.0, 0.95, 0.7, 0.6)
	mote_draw.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Additive warm specks drifting up the shaft — dust catching the light.
	mote_draw.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mote_draw.emission_enabled = true
	mote_draw.emission = Color(1.0, 0.9, 0.55)
	mote_draw.emission_energy_multiplier = 2.2
	mote_draw.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mote_draw.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mote.material = mote_draw
	_sun_motes.draw_pass_1 = mote
	_sun_motes.emitting = false
	environment_root.add_child(_sun_motes)


# ── Curve/ramp helpers for the GPU emitters ──

## A scale curve that grows particles from small to large over their life.
func _make_grow_curve_texture() -> CurveTexture:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.4))
	curve.add_point(Vector2(1.0, 1.0))
	var tex := CurveTexture.new()
	tex.curve = curve
	return tex


## A colour ramp that fades alpha in then out (soft edges), tinted by `base`.
func _make_soft_alpha_ramp(base: Color) -> GradientTexture1D:
	var grad := Gradient.new()
	grad.set_color(0, Color(base.r, base.g, base.b, 0.0))
	grad.add_point(0.2, Color(base.r, base.g, base.b, 1.0))
	grad.add_point(0.8, Color(base.r, base.g, base.b, 1.0))
	grad.set_color(1, Color(base.r, base.g, base.b, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	return tex


func _build_pressure_zones() -> void:
	# High pressure — blue translucent sphere, pushes outward
	high_pressure = _create_pressure_sphere(Color(0.2, 0.4, 0.9, 0.12), "HighPressure")
	high_pressure.position = Vector3(domain_extent * 0.5, 0.3, -domain_extent * 0.33) * _sc()
	environment_root.add_child(high_pressure)

	# Low pressure — red translucent sphere, pulls inward
	low_pressure = _create_pressure_sphere(Color(0.9, 0.2, 0.2, 0.12), "LowPressure")
	low_pressure.position = Vector3(-domain_extent * 0.5, 0.3, domain_extent * 0.33) * _sc()
	environment_root.add_child(low_pressure)


func _create_pressure_sphere(color: Color, sphere_name: String) -> Node3D:
	var sc := _sc()
	var root := Node3D.new()
	root.name = sphere_name

	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 24
	sphere.rings = 16
	mesh.mesh = sphere
	mesh.scale = Vector3.ONE * 0.7 * sc

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b) * 0.4
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = mat
	root.add_child(mesh)

	# Label
	var label := Label3D.new()
	label.text = "H" if "High" in sphere_name else "L"
	label.font_size = 28
	label.modulate = Color(color.r, color.g, color.b, 0.7)
	label.position = Vector3(0, 0.4, 0) * sc
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	root.add_child(label)

	return root


func _build_decomposition_display() -> void:
	var sc := _sc()
	# Shows wind + gravity = trajectory at a sample point (perimeter corner)
	decomp_root = Node3D.new()
	decomp_root.name = "Decomposition"
	decomp_root.position = Vector3(domain_extent * 0.7, 0.3, domain_extent * 0.7) * sc
	environment_root.add_child(decomp_root)

	decomp_wind_arrow = _create_decomp_arrow(Color(0.3, 0.85, 0.95))
	decomp_gravity_arrow = _create_decomp_arrow(Color(0.3, 0.9, 0.3))
	decomp_result_arrow = _create_decomp_arrow(Color(1.0, 0.6, 0.2))

	decomp_root.add_child(decomp_wind_arrow)
	decomp_root.add_child(decomp_gravity_arrow)
	decomp_root.add_child(decomp_result_arrow)

	decomp_label = Label3D.new()
	decomp_label.text = "wind + gravity = trajectory"
	decomp_label.font_size = 14
	decomp_label.modulate = Color(0.8, 0.8, 0.9, 0.8)
	decomp_label.position = Vector3(0, 0.6, 0) * sc
	decomp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	decomp_label.no_depth_test = true
	decomp_root.add_child(decomp_label)


func _create_decomp_arrow(color: Color) -> MeshInstance3D:
	## A simple cylinder arrow for the decomposition display. Own emissive material
	## (not the shared cache) so we can crank the glow without affecting other
	## scenes — the decomposition arrows should read as bright bars of light.
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.height = 1.0
	cyl.top_radius = 0.008
	cyl.bottom_radius = 0.008
	cyl.radial_segments = 8
	mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.2
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	return mesh


# ════════════════════════════════════════════════════════════════════
#  WEATHER INSTRUMENTS  (all read the live summed wind vector)
# ════════════════════════════════════════════════════════════════════

func _build_instruments() -> void:
	_build_windsock()
	_build_anemometer()
	_build_compass_rose()
	_build_streamlines()


## Windsock — a pole on the perimeter with a yaw pivot and a tapered sleeve.
## In _update it yaws to the wind heading and stretches/lifts with magnitude.
func _build_windsock() -> void:
	var sc := _sc()
	var root := Node3D.new()
	root.name = "Windsock"
	root.position = Vector3(domain_extent + 0.3, 0.0, -domain_extent + 0.2) * sc
	environment_root.add_child(root)

	# Pole
	var pole := MeshInstance3D.new()
	var pole_cyl := CylinderMesh.new()
	pole_cyl.top_radius = 0.02
	pole_cyl.bottom_radius = 0.025
	pole_cyl.height = 1.2
	pole_cyl.radial_segments = 8
	pole.mesh = pole_cyl
	pole.scale = Vector3.ONE * sc
	pole.position = Vector3(0, 0.6, 0) * sc
	pole.material_override = _get_shared_material(Color(0.5, 0.52, 0.55), false)
	root.add_child(pole)

	# Yaw pivot at top of pole — rotates about Y to face the wind heading
	windsock_yaw = Node3D.new()
	windsock_yaw.name = "Yaw"
	windsock_yaw.position = Vector3(0, 1.2, 0) * sc
	root.add_child(windsock_yaw)

	# Sleeve — cone pointing +X (downwind). Scaled in _update for stretch.
	windsock_sleeve = MeshInstance3D.new()
	var sleeve_cone := CylinderMesh.new()
	sleeve_cone.top_radius = 0.03
	sleeve_cone.bottom_radius = 0.12
	sleeve_cone.height = 1.0
	sleeve_cone.radial_segments = 12
	windsock_sleeve.mesh = sleeve_cone
	# Orient the cone's local +Y along +X so it streams sideways.
	windsock_sleeve.transform.basis = _basis_from_direction(Vector3.RIGHT)
	windsock_sleeve.position = Vector3(0.5, 0, 0) * sc
	windsock_sleeve.scale = Vector3.ONE * sc
	windsock_material = StandardMaterial3D.new()
	windsock_material.albedo_color = Color(0.95, 0.4, 0.15)
	windsock_material.emission_enabled = true
	windsock_material.emission = Color(0.9, 0.35, 0.1)
	# Warm glow so the sock reads as a beacon against the cool storm.
	windsock_material.emission_energy_multiplier = 1.8
	windsock_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	windsock_sleeve.material_override = windsock_material
	windsock_yaw.add_child(windsock_sleeve)

	var label := Label3D.new()
	label.text = "WINDSOCK"
	label.font_size = 12
	label.modulate = Color(0.95, 0.6, 0.4, 0.7)
	label.position = Vector3(0, 1.5, 0) * sc
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	root.add_child(label)


## Anemometer — 3 cups on arms around a vertical axle. Spins in _process; the
## spin rate tracks wind speed.
func _build_anemometer() -> void:
	var sc := _sc()
	var root := Node3D.new()
	root.name = "Anemometer"
	root.position = Vector3(-domain_extent - 0.3, 0.0, -domain_extent + 0.2) * sc
	environment_root.add_child(root)

	# Mast
	var mast := MeshInstance3D.new()
	var mast_cyl := CylinderMesh.new()
	mast_cyl.top_radius = 0.018
	mast_cyl.bottom_radius = 0.022
	mast_cyl.height = 1.0
	mast_cyl.radial_segments = 8
	mast.mesh = mast_cyl
	mast.scale = Vector3.ONE * sc
	mast.position = Vector3(0, 0.5, 0) * sc
	mast.material_override = _get_shared_material(Color(0.5, 0.52, 0.55), false)
	root.add_child(mast)

	# Spinner — rotates about Y in _process
	anemometer_spinner = Node3D.new()
	anemometer_spinner.name = "Spinner"
	anemometer_spinner.position = Vector3(0, 1.0, 0) * sc
	root.add_child(anemometer_spinner)

	# Own emissive cup material so the spinner glows cyan-white and reads as it
	# spins — a little light moving with the wind speed.
	var cup_mat := StandardMaterial3D.new()
	cup_mat.albedo_color = Color(0.85, 0.9, 1.0)
	cup_mat.emission_enabled = true
	cup_mat.emission = Color(0.5, 0.75, 1.0)
	cup_mat.emission_energy_multiplier = 1.4
	var arm_mat := _get_shared_material(Color(0.6, 0.62, 0.66), false)
	for i in range(3):
		var ang := float(i) * TAU / 3.0
		var dir := Vector3(cos(ang), 0.0, sin(ang))

		# Arm
		var arm := MeshInstance3D.new()
		var arm_cyl := CylinderMesh.new()
		arm_cyl.top_radius = 0.008
		arm_cyl.bottom_radius = 0.008
		arm_cyl.height = 1.0
		arm_cyl.radial_segments = 6
		arm.mesh = arm_cyl
		var arm_len := 0.22
		arm.transform.basis = _basis_from_direction(dir)
		arm.scale = Vector3(sc, arm_len * sc, sc)
		arm.position = dir * (arm_len * 0.5) * sc
		arm.material_override = arm_mat
		anemometer_spinner.add_child(arm)

		# Cup (half-sphere stand-in)
		var cup := MeshInstance3D.new()
		var cup_sphere := SphereMesh.new()
		cup_sphere.radius = 0.5
		cup_sphere.height = 1.0
		cup_sphere.radial_segments = 10
		cup_sphere.rings = 6
		cup.mesh = cup_sphere
		cup.scale = Vector3.ONE * 0.09 * sc
		cup.position = dir * 0.22 * sc
		cup.material_override = cup_mat
		anemometer_spinner.add_child(cup)

	var label := Label3D.new()
	label.text = "ANEMOMETER"
	label.font_size = 12
	label.modulate = Color(0.7, 0.85, 0.95, 0.7)
	label.position = Vector3(0, 1.3, 0) * sc
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	root.add_child(label)


## Compass rose on the ground — N/E/S/W labels plus a needle that swings to the
## wind heading for an instant direction read.
func _build_compass_rose() -> void:
	var sc := _sc()
	var root := Node3D.new()
	root.name = "CompassRose"
	root.position = Vector3(0, 0.02, domain_extent - 0.4) * sc
	environment_root.add_child(root)

	# Disc
	var disc := MeshInstance3D.new()
	var disc_cyl := CylinderMesh.new()
	disc_cyl.top_radius = 0.5
	disc_cyl.bottom_radius = 0.5
	disc_cyl.height = 0.02
	disc_cyl.radial_segments = 32
	disc.mesh = disc_cyl
	disc.scale = Vector3.ONE * 0.7 * sc
	var disc_mat := StandardMaterial3D.new()
	disc_mat.albedo_color = Color(0.12, 0.14, 0.2, 0.85)
	disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc_mat.emission_enabled = true
	disc_mat.emission = Color(0.15, 0.2, 0.3)
	disc_mat.emission_energy_multiplier = 0.4
	disc.material_override = disc_mat
	root.add_child(disc)

	# Cardinal labels.  +Z = North (forward/back of the field), +X = East.
	var cardinals := [
		{"t": "N", "p": Vector3(0, 0.03, 0.6)},
		{"t": "E", "p": Vector3(0.6, 0.03, 0)},
		{"t": "S", "p": Vector3(0, 0.03, -0.6)},
		{"t": "W", "p": Vector3(-0.6, 0.03, 0)},
	]
	for c in cardinals:
		var label := Label3D.new()
		label.text = c["t"]
		label.font_size = 20
		label.modulate = Color(0.85, 0.9, 1.0, 0.9)
		label.position = (c["p"] as Vector3) * 0.7 * sc
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		root.add_child(label)

	# Needle — flat arrow pivoting about Y, swings to wind heading.
	compass_needle = Node3D.new()
	compass_needle.name = "Needle"
	compass_needle.position = Vector3(0, 0.04, 0) * sc
	root.add_child(compass_needle)

	var needle_mesh := MeshInstance3D.new()
	var needle_cone := CylinderMesh.new()
	needle_cone.top_radius = 0.0
	needle_cone.bottom_radius = 0.06
	needle_cone.height = 1.0
	needle_cone.radial_segments = 8
	needle_mesh.mesh = needle_cone
	# Point the cone's +Y along +X by default; the needle pivot yaws it.
	needle_mesh.transform.basis = _basis_from_direction(Vector3.RIGHT)
	needle_mesh.scale = Vector3(sc, 0.45 * sc, sc)
	needle_mesh.position = Vector3(0.22, 0, 0) * sc
	var needle_mat := StandardMaterial3D.new()
	needle_mat.albedo_color = Color(1.0, 0.3, 0.3)
	needle_mat.emission_enabled = true
	needle_mat.emission = Color(0.95, 0.25, 0.25)
	needle_mat.emission_energy_multiplier = 2.0
	needle_mesh.material_override = needle_mat
	compass_needle.add_child(needle_mesh)


## Wind streamlines — a few fading dotted trails seeded across the field, redrawn
## each frame by stepping through the wind field. Uses one MultiMesh of dots.
func _build_streamlines() -> void:
	if _stream_dot_mesh == null:
		_stream_dot_mesh = SphereMesh.new()
		_stream_dot_mesh.radius = 0.02
		_stream_dot_mesh.height = 0.04
		_stream_dot_mesh.radial_segments = 6
		_stream_dot_mesh.rings = 3

	_streamline_seeds.clear()
	for i in range(STREAMLINE_COUNT):
		var fx := lerpf(-domain_extent * 0.7, domain_extent * 0.7, float(i) / float(max(STREAMLINE_COUNT - 1, 1)))
		_streamline_seeds.append(Vector3(fx, 0.4, -domain_extent * 0.6))

	var total := STREAMLINE_COUNT * STREAMLINE_SEGMENTS
	var stream_mm := MultiMesh.new()
	stream_mm.transform_format = MultiMesh.TRANSFORM_3D
	stream_mm.use_colors = true
	stream_mm.mesh = _stream_dot_mesh
	stream_mm.instance_count = total
	stream_mm.visible_instance_count = 0
	_streamline_mm = MultiMeshInstance3D.new()
	_streamline_mm.name = "StreamlineMM"
	_streamline_mm.multimesh = stream_mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 1.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_streamline_mm.material_override = mat
	environment_root.add_child(_streamline_mm)


func _build_controls() -> void:
	var sc := _sc()
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("WEATHER FIELD", [
		[
			{"type": "button", "label": "MODE"},
			{"type": "button", "label": "GRID"},
			{"type": "button", "label": "RESET"},
		],
		[
			{"type": "slider_h", "label": "GRAVITY", "default": gravity_strength / 2.0},
			{"type": "slider_h", "label": "PRESSURE", "default": pressure_intensity},
		],
	])
	var control_base := Vector3(-domain_extent - 0.5, 1.5, -domain_extent * 0.8)
	panel.position = control_base * sc
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	mode_button = panel.find_child("Btn_0", true, false)
	if mode_button:
		var area: Node = mode_button.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_mode_pressed())

	grid_button = panel.find_child("Btn_1", true, false)
	if grid_button:
		var area: Node = grid_button.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_grid_pressed())

	reset_button = panel.find_child("Btn_2", true, false)
	if reset_button:
		var area: Node = reset_button.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_reset_pressed())

	gravity_slider = panel.find_child("Param_0", true, false)
	if gravity_slider and gravity_slider.has_signal("slider_moved"):
		gravity_slider.slider_moved.connect(func(_n): _on_gravity_changed(gravity_slider.get_normalized_value()))

	pressure_slider = panel.find_child("Param_1", true, false)
	if pressure_slider and pressure_slider.has_signal("slider_moved"):
		pressure_slider.slider_moved.connect(func(_n): _on_pressure_changed(pressure_slider.get_normalized_value()))

	# Status label
	status_label = Label3D.new()
	status_label.name = "StatusLabel"
	status_label.font_size = 14
	status_label.modulate = Color(0.7, 0.8, 1.0)
	status_label.position = (control_base + Vector3(0, 0.5, 0)) * sc
	status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	status_label.no_depth_test = true
	add_child(status_label)


# ════════════════════════════════════════════════════════════════════
#  PER-FRAME UPDATES
# ════════════════════════════════════════════════════════════════════

func _wind_at(pos: Vector3, base_a: Vector3, base_b: Vector3) -> Vector3:
	## Returns the wind vector at a unit-space position.
	## Base wind is A + B, plus pressure zone perturbation.
	var base_wind := base_a + base_b
	var sc := _sc()

	if pressure_intensity > 0.001:
		# High pressure pushes outward from its center
		var hp_center := high_pressure.position / sc
		var to_from_hp := pos - hp_center
		var hp_dist := to_from_hp.length()
		if hp_dist > 0.1:
			base_wind += to_from_hp.normalized() * pressure_intensity * 0.5 / (1.0 + hp_dist)

		# Low pressure pulls inward
		var lp_center := low_pressure.position / sc
		var to_lp := lp_center - pos
		var lp_dist := to_lp.length()
		if lp_dist > 0.1:
			base_wind += to_lp.normalized() * pressure_intensity * 0.5 / (1.0 + lp_dist)

	return base_wind


func _update_grid_arrows(a: Vector3, b: Vector3) -> void:
	if not _arrow_shaft_mm or not _arrow_head_mm:
		return
	var sc := _sc()
	var shaft_mm := _arrow_shaft_mm.multimesh
	var head_mm := _arrow_head_mm.multimesh
	var hidden := Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3(0, -999, 0))

	for i in _arrow_count:
		var origin := _arrow_origins[i]
		var wind := _wind_at(origin, a, b)
		var mag := wind.length()

		if mag < 0.01:
			shaft_mm.set_instance_transform(i, hidden)
			head_mm.set_instance_transform(i, hidden)
			continue

		var dir := wind / mag
		var arrow_len: float = clampf(mag * 0.15, 0.02, 0.25) * sc
		var base := origin * sc

		# Basis with local Y along direction (cylinder/cone axis is Y)
		var basis := _basis_from_direction(dir)

		# Shaft: scaled to arrow_len along Y, centered half-way
		var shaft_basis := Basis(basis.x, basis.y * arrow_len, basis.z)
		shaft_mm.set_instance_transform(i, Transform3D(shaft_basis, base + dir * (arrow_len * 0.5)))

		# Head: unit-scaled cone at the tip
		head_mm.set_instance_transform(i, Transform3D(basis, base + dir * arrow_len))

		# Color by magnitude: blue (calm) -> yellow -> red (strong)
		var t: float = clampf(mag / 3.0, 0.0, 1.0)
		var color: Color
		if t < 0.5:
			color = Color(0.3, 0.5, 1.0).lerp(Color(1.0, 1.0, 0.3), t * 2.0)
		else:
			color = Color(1.0, 1.0, 0.3).lerp(Color(1.0, 0.2, 0.1), (t - 0.5) * 2.0)
		shaft_mm.set_instance_color(i, color)
		head_mm.set_instance_color(i, color)


# ════════════════════════════════════════════════════════════════════
#  GPU PARTICLE DRIVERS  (every system reads the live summed wind vector)
# ════════════════════════════════════════════════════════════════════

## Rain: the streak slant IS gravity + wind. We write the resultant straight
## into process_material.gravity, exactly the decomposition the panel shows.
## Both terms are scaled by _sc() so the fall rate stays believable at scene
## scale (the node also inherits the 0.5 root scale via its transform).
func _drive_rain(sum: Vector3) -> void:
	if _rain_mat == null:
		return
	var sc := _sc()
	# Gravity term: down * gravity_strength * 9.8 (so the slider sweeps a real
	# fall rate). Wind term: the horizontal resultant. Keep the exact
	# "rain = gravity + wind" decomposition.
	var grav_term := Vector3(0.0, -gravity_strength * 9.8, 0.0)
	var wind_term := Vector3(sum.x, 0.0, sum.z) * 3.0   # gain to read clearly
	var resultant_v := grav_term + wind_term
	_rain_mat.gravity = resultant_v * sc
	# Stretch the streaks with the resultant SPEED — faster fall/blow = longer
	# light-trails. Snow (blizzard) stays short/round; storm rain reads as rain.
	if not bool(_palette().get("snow", false)):
		var spd: float = resultant_v.length()
		var stretch: float = clampf(0.55 + spd * 0.04, 0.6, 1.7)
		_rain_mat.scale_min = stretch * 0.8
		_rain_mat.scale_max = stretch * 1.35


## Clouds: drift the slab on the horizontal wind by writing wind into the
## process material's gravity (a sideways "gravity" carries the puffs downwind).
func _drive_clouds(sum: Vector3) -> void:
	if _cloud_mat == null:
		return
	var sc := _sc()
	var gain: float = float(_palette().get("drift_gain", 0.5))
	var drift := Vector3(sum.x, 0.0, sum.z) * gain * 0.6
	_cloud_mat.gravity = drift * sc


## Ground mist: same drift idea, a touch slower, swaying near the floor.
func _drive_mist(sum: Vector3) -> void:
	if _mist_mat == null:
		return
	var sc := _sc()
	var gain: float = float(_palette().get("drift_gain", 0.5))
	var drift := Vector3(sum.x, 0.0, sum.z) * gain * 0.4
	_mist_mat.gravity = drift * sc


## Debris: the headline vector in flight. Aim emission direction + velocity
## straight downwind (sum.normalized) so the streak of leaves draws the wind.
func _drive_debris(sum: Vector3) -> void:
	if _debris_mat == null:
		return
	var sc := _sc()
	var horiz := Vector3(sum.x, 0.0, sum.z)
	var speed: float = horiz.length()
	if speed < 0.05:
		# Near-calm: drift gently down/settle, low emission.
		_debris_mat.direction = Vector3(0.0, -1.0, 0.0)
		_debris_mat.gravity = Vector3(0.0, -0.5, 0.0) * sc
		_set_debris_amount(12)
		return
	var dir := horiz / speed
	_debris_mat.direction = dir
	# Velocity proportional to wind speed; gravity pulls leaves slightly down
	# PLUS pushes them downwind so they keep streaking.
	_debris_mat.initial_velocity_min = (0.3 + speed * 0.4) * sc
	_debris_mat.initial_velocity_max = (0.6 + speed * 0.7) * sc
	_debris_mat.gravity = (dir * speed * 1.5 + Vector3(0.0, -0.6, 0.0)) * sc
	# More debris in stronger wind, capped. Quantize to avoid reallocating the
	# particle buffer every frame (changing `amount` restarts the system).
	var amt: int = clampi(int(round((20.0 + speed * 25.0) / 10.0)) * 10, 10, 90)
	_set_debris_amount(amt)


## Only write GPUParticles3D.amount when it actually changes (it triggers a
## buffer realloc/restart), keeping the per-frame cost bounded.
func _set_debris_amount(amt: int) -> void:
	if _debris_gpu and _debris_gpu.amount != amt:
		_debris_gpu.amount = amt


func _update_pressure_zones() -> void:
	var sc := _sc()
	# Slowly drift pressure zones around their home positions
	var hx := domain_extent * 0.5 + sin(pressure_time) * domain_extent * 0.18
	var hz := -domain_extent * 0.33 + cos(pressure_time * 0.7) * domain_extent * 0.12
	high_pressure.position = Vector3(hx, 0.3, hz) * sc

	var lx := -domain_extent * 0.5 + cos(pressure_time * 0.8) * domain_extent * 0.18
	var lz := domain_extent * 0.33 + sin(pressure_time * 0.6) * domain_extent * 0.12
	low_pressure.position = Vector3(lx, 0.3, lz) * sc


func _update_decomposition(sum: Vector3) -> void:
	if decomp_root == null:
		return

	var sc := _sc()
	var wind_vec := sum
	var grav_vec := Vector3(0, -gravity_strength, 0)
	var result_vec := wind_vec + grav_vec

	# Wind arrow (cyan) — horizontal wind component
	_orient_decomp_arrow(decomp_wind_arrow, wind_vec, sc)
	# Gravity arrow (green) — always down
	_orient_decomp_arrow(decomp_gravity_arrow, grav_vec, sc)
	# Result arrow (orange) — combined trajectory
	_orient_decomp_arrow(decomp_result_arrow, result_vec, sc)


func _orient_decomp_arrow(mesh: MeshInstance3D, vec: Vector3, sc: float) -> void:
	var mag := vec.length()
	if mag < 0.01:
		mesh.visible = false
		return
	mesh.visible = true
	var dir := vec.normalized()
	var arrow_len: float = clampf(mag * 0.2, 0.03, 0.4) * sc
	mesh.transform.basis = _basis_from_direction(dir)
	mesh.scale = Vector3(1, arrow_len, 1)
	mesh.position = dir * arrow_len * 0.5


# ── Instrument updates ──

func _wind_heading(sum: Vector3) -> float:
	## Returns the wind heading (yaw about Y) from the horizontal components.
	## atan2(z, x): 0 = +X (east), increasing toward +Z (north).
	var horiz := Vector2(sum.x, sum.z)
	if horiz.length() < 0.001:
		return 0.0
	return atan2(sum.z, sum.x)


func _update_instruments(delta: float, sum: Vector3) -> void:
	var horiz_speed := Vector2(sum.x, sum.z).length()
	var heading := _wind_heading(sum)

	# Windsock — yaw to face downwind, stretch + lift with magnitude.
	if windsock_yaw:
		# Cone streams along +X locally; yaw by -heading so local +X aligns to wind dir.
		windsock_yaw.rotation.y = -heading
	if windsock_sleeve:
		var sc := _sc()
		var stretch: float = clampf(0.4 + horiz_speed * 0.5, 0.4, 2.2)
		# Lift: lighter wind droops (sleeve tilts down), strong wind stands out.
		var lift: float = clampf(sum.y * 0.3 + horiz_speed * 0.15, -0.4, 0.6)
		# Local +Y of the sleeve is its long axis (we oriented it to +X). Scale that.
		windsock_sleeve.scale = Vector3(sc, stretch * sc, sc)
		windsock_sleeve.position = Vector3(0.45 * stretch, lift * 0.5, 0) * sc
		# Tint: orange when calm, white-hot when blowing hard.
		var ht: float = clampf(horiz_speed / 3.0, 0.0, 1.0)
		windsock_material.albedo_color = Color(0.95, 0.4, 0.15).lerp(Color(1.0, 0.85, 0.5), ht)
		windsock_material.emission = Color(0.9, 0.35, 0.1).lerp(Color(1.0, 0.8, 0.4), ht)

	# Anemometer — spin rate tracks wind speed.
	if anemometer_spinner:
		var spin_rate: float = horiz_speed * 4.0 + 0.2   # rad/s, small idle
		_anemometer_angle += spin_rate * delta
		anemometer_spinner.rotation.y = _anemometer_angle

	# Compass needle — swing to wind heading.
	if compass_needle:
		# Needle points along local +X; yaw by -heading so it points to wind dir.
		var target := -heading
		compass_needle.rotation.y = lerp_angle(compass_needle.rotation.y, target, 0.15)


## Lightning: count down a cooldown; when it elapses (and the active palette
## permits) fire a strike biased downwind — fresh zig-zag bolt, spark burst,
## and a flash that decays over the next frames (flash/fade from lifetime_curves).
func _drive_lightning(delta: float, sum: Vector3) -> void:
	if _lightning_root == null:
		return
	var palette := _palette()
	var allowed: bool = bool(palette.get("lightning", false))

	# Phase 1 — the bolt itself: a fast, bright, flickering decay (the visible
	# zig-zag and the initial hard flash).
	if _lightning_flash > 0.0:
		_lightning_flash = maxf(0.0, _lightning_flash - delta * 5.5)
		# Flicker the bolt alpha so it reads as a crackling discharge, not a fade.
		var flicker: float = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.08)
		var a: float = clampf(_lightning_flash * flicker, 0.0, 1.0)
		_lightning_bolt_mat.albedo_color = Color(0.92, 0.97, 1.0, a)
		_lightning_bolt.visible = _lightning_flash > 0.04
	else:
		_lightning_bolt.visible = false

	# Phase 2 — thunder-delayed afterglow: after a short delay the whole field
	# swells with a softer blue glow (the "boom" you feel as light), then fades.
	if _thunder_pending:
		_thunder_delay -= delta
		if _thunder_delay <= 0.0:
			_thunder_pending = false
			_lightning_glow = maxf(_lightning_glow, 0.7)   # the swell
	if _lightning_glow > 0.0:
		_lightning_glow = maxf(0.0, _lightning_glow - delta * 1.6)

	# The flash light = hard bolt spike + soft thunder swell, combined.
	# Peak ~7 for a brief moment, so the room really lights up.
	var bolt_e: float = _lightning_flash * 7.0
	var glow_e: float = _lightning_glow * 2.2
	_lightning_light.light_energy = bolt_e + glow_e

	if not allowed:
		# Make sure nothing lingers when we leave a lightning mode mid-decay.
		if _lightning_flash <= 0.0 and _lightning_glow <= 0.0:
			_lightning_light.light_energy = 0.0
		return

	_lightning_cooldown -= delta
	if _lightning_cooldown > 0.0:
		return
	_lightning_cooldown = randf_range(2.5, 6.0)
	_strike_lightning(sum)


## Build a fresh zig-zag bolt from a high downwind point to the ground, fire the
## spark burst at the ground point, and arm the flash.
func _strike_lightning(sum: Vector3) -> void:
	var sc := _sc()
	var horiz := Vector3(sum.x, 0.0, sum.z)
	# Bias the strike downwind: base point offset along the wind direction.
	var bias := Vector3.ZERO
	if horiz.length() > 0.05:
		bias = horiz.normalized() * domain_extent * 0.4
	var ground_pt := Vector3(
		clampf(bias.x + randf_range(-0.6, 0.6), -domain_extent, domain_extent),
		0.05,
		clampf(bias.z + randf_range(-0.6, 0.6), -domain_extent, domain_extent)
	)
	# The bolt leans slightly upwind at the top (cloud anchor a touch back).
	var lean := Vector3.ZERO
	if horiz.length() > 0.05:
		lean = -horiz.normalized() * 0.4
	var top_pt := ground_pt + Vector3(lean.x, 3.0, lean.z)

	# Build the main channel as a jittered poly-line, remembering each node so we
	# can hang a few forks off the middle of the bolt.
	var main_pts: Array = []
	var segs := 9
	for i in range(segs + 1):
		var t: float = float(i) / float(segs)
		var base_pt := top_pt.lerp(ground_pt, t)
		# Jitter sideways, more in the middle, zero at the ends.
		var jitter: float = sin(t * PI) * 0.4
		var off := Vector3(randf_range(-jitter, jitter), 0.0, randf_range(-jitter, jitter))
		main_pts.append(base_pt + off)

	_lightning_bolt_mesh.clear_surfaces()
	_lightning_bolt_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	_lightning_bolt_mesh.surface_set_color(Color(0.96, 0.98, 1.0))
	for p in main_pts:
		_lightning_bolt_mesh.surface_add_vertex((p as Vector3) * sc)
	_lightning_bolt_mesh.surface_end()

	# A few branching forks: short jagged offshoots from interior nodes, drawn as
	# separate dimmer line strips in the same ImmediateMesh (cheap, no new node).
	var fork_count: int = randi_range(2, 3)
	for f in range(fork_count):
		var node_i: int = randi_range(2, main_pts.size() - 3)
		var root_pt: Vector3 = main_pts[node_i]
		# Fork heads outward + downward from the channel.
		var fork_dir := Vector3(randf_range(-1.0, 1.0), randf_range(-0.9, -0.2), randf_range(-1.0, 1.0)).normalized()
		var fork_len: float = randf_range(0.5, 1.1)
		var fork_segs := 4
		_lightning_bolt_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		_lightning_bolt_mesh.surface_set_color(Color(0.8, 0.9, 1.0, 0.85))
		var cur := root_pt
		_lightning_bolt_mesh.surface_add_vertex(cur * sc)
		for s in range(fork_segs):
			var step_len: float = fork_len / float(fork_segs)
			cur += fork_dir * step_len + Vector3(randf_range(-0.18, 0.18), randf_range(-0.18, 0.0), randf_range(-0.18, 0.18))
			_lightning_bolt_mesh.surface_add_vertex(cur * sc)
		_lightning_bolt_mesh.surface_end()

	_lightning_bolt.visible = true
	_lightning_flash = 1.0
	_lightning_light.position = ground_pt * sc + Vector3(0.0, 1.2, 0.0) * sc

	# Arm the delayed thunder afterglow — a short, believable light-lag before the
	# field swells with the soft "boom" glow.
	_thunder_pending = true
	_thunder_delay = randf_range(0.18, 0.5)

	if _lightning_sparks:
		_lightning_sparks.position = ground_pt * sc
		_lightning_sparks.restart()
		_lightning_sparks.emitting = true


## Calm-mode sun shaft: show only in calm mode, slowly bob, rising motes.
func _drive_sun_shaft(delta: float, _sum: Vector3) -> void:
	if _sun_shaft == null:
		return
	var want: bool = bool(_palette().get("sun", false))
	_sun_shaft.visible = want
	if _sun_motes:
		_sun_motes.emitting = want
	# Gentle breathing of the shaft brightness so the calm light feels alive.
	if want and _sun_shaft_mat:
		_sun_pulse_t += delta
		_sun_shaft_mat.emission_energy_multiplier = 0.75 + 0.25 * sin(_sun_pulse_t * 0.8)


func _update_streamlines(a: Vector3, b: Vector3) -> void:
	if not _streamline_mm:
		return
	var sc := _sc()
	var stream_mm := _streamline_mm.multimesh
	var idx := 0
	var step := 0.18
	for s in range(STREAMLINE_COUNT):
		var p: Vector3 = _streamline_seeds[s]
		for seg in range(STREAMLINE_SEGMENTS):
			var wind := _wind_at(p, a, b)
			var mag := wind.length()
			if mag > 0.001:
				p += (wind / mag) * step
			# Keep streamline within domain — clamp so it doesn't run away.
			p.x = clampf(p.x, -domain_extent, domain_extent)
			p.z = clampf(p.z, -domain_extent, domain_extent)
			var fade: float = 1.0 - float(seg) / float(STREAMLINE_SEGMENTS)
			var col := Color(0.5, 0.9, 1.0, fade * 0.7)
			stream_mm.set_instance_transform(idx, Transform3D(Basis.IDENTITY, p * sc))
			stream_mm.set_instance_color(idx, col)
			idx += 1
	stream_mm.visible_instance_count = idx


func _update_temperature_tint(sum: Vector3) -> void:
	## Warm/cool tint of the ground driven by the wind's vertical sign:
	## updraft (warm air rising) -> warm; downdraft -> cool. Also nudged by speed.
	## On top of the thermal tint we color-grade toward the active mode's
	## `ground_tint` and raise the floor's metallic/sheen with the mode's `wet`
	## value so a wet storm floor mirrors the rain and lightning.
	if ground_material == null:
		return
	# -1 (cool/down) .. +1 (warm/up)
	var thermal: float = clampf(sum.y * 0.6, -1.0, 1.0)
	var t: float = (thermal + 1.0) * 0.5   # 0..1
	var cool := Color(0.06, 0.1, 0.18, 0.9)
	var warm := Color(0.16, 0.11, 0.08, 0.9)
	var base := cool.lerp(warm, t)

	# Per-mode color grade pulls the floor toward the mode's signature tint.
	var pal := _palette()
	var mode_tint: Color = pal.get("ground_tint", Color(0.08, 0.1, 0.14))
	var graded := base.lerp(Color(mode_tint.r, mode_tint.g, mode_tint.b, base.a), 0.6)
	ground_material.albedo_color = graded

	var cool_em := Color(0.04, 0.06, 0.12)
	var warm_em := Color(0.14, 0.07, 0.03)
	ground_material.emission = cool_em.lerp(warm_em, t)

	# Wet sheen: a wet floor is darker, glossier, and a touch metallic so the
	# emissive rain + lightning flash reflect off it. Lerp toward the wet look so
	# mode changes feel like the floor drying / soaking.
	var wet: float = clampf(float(pal.get("wet", 0.0)), 0.0, 1.0)
	var target_rough: float = lerpf(0.85, 0.12, wet)
	var target_metal: float = lerpf(0.0, 0.55, wet)
	ground_material.roughness = lerpf(ground_material.roughness, target_rough, 0.08)
	ground_material.metallic = lerpf(ground_material.metallic, target_metal, 0.08)
	# Brighten the floor's own glow slightly when wet so reflections read in VR.
	ground_material.emission_energy_multiplier = lerpf(0.3, 0.6, wet)


func _update_info_text(a: Vector3, b: Vector3, sum: Vector3) -> void:
	if info_label == null:
		return

	var angle_deg: float = 0.0
	if a.length() > 0.01 and b.length() > 0.01:
		angle_deg = rad_to_deg(a.angle_to(b))

	var heading_deg := rad_to_deg(_wind_heading(sum))
	var lines: Array = []
	lines.append("A = (%.1f, %.1f, %.1f)  |A| = %.2f" % [a.x, a.y, a.z, a.length()])
	lines.append("B = (%.1f, %.1f, %.1f)  |B| = %.2f" % [b.x, b.y, b.z, b.length()])
	lines.append("A+B = (%.1f, %.1f, %.1f)  |A+B| = %.2f" % [sum.x, sum.y, sum.z, sum.length()])
	lines.append("Angle(A,B) = %.1f deg" % angle_deg)
	lines.append("Wind heading = %.0f deg" % heading_deg)
	info_label.text = "\n".join(lines)

	# Status label
	if status_label:
		status_label.text = "%s  |  Gravity: %.1f  |  Pressure: %.1f" % [
			MODE_NAMES[current_mode], gravity_strength, pressure_intensity
		]


# ════════════════════════════════════════════════════════════════════
#  PARALLELOGRAM (from VectorAddition pattern)
# ════════════════════════════════════════════════════════════════════

func _create_dotted_line_multimesh(color: Color) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "DottedLine"
	mmi.multimesh = MultiMesh.new()
	mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mmi.multimesh.mesh = _dot_mesh
	mmi.multimesh.instance_count = 100
	mmi.multimesh.visible_instance_count = 0

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mmi.material_override = mat
	return mmi


func _update_dotted_lines(a: Vector3, b: Vector3, _result: Vector3) -> void:
	var sc := _sc()
	# Line from tip of A to A+B (showing B's copy)
	_update_single_dotted_line(dotted_line_b, a * sc, (a + b) * sc)
	# Line from tip of B to A+B (showing A's copy)
	_update_single_dotted_line(dotted_line_a, b * sc, (a + b) * sc)


func _update_single_dotted_line(mmi: MultiMeshInstance3D, start: Vector3, end: Vector3) -> void:
	if mmi == null:
		return
	var direction := end - start
	var distance := direction.length()
	if distance < 0.001:
		mmi.visible = false
		return
	mmi.visible = true
	var spacing: float = 0.15 * _sc()
	var num_dots: int = int(distance / spacing) + 1
	if num_dots > mmi.multimesh.instance_count:
		mmi.multimesh.instance_count = num_dots + 50
	mmi.multimesh.visible_instance_count = num_dots
	for i in range(num_dots):
		var t: float = float(i) / float(num_dots - 1) if num_dots > 1 else 0.0
		var pos := start.lerp(end, t)
		mmi.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, pos))


func _create_floating_label(text: String, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = 12
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	environment_root.add_child(label)
	return label


# ════════════════════════════════════════════════════════════════════
#  CACHING (from VectorAddition pattern)
# ════════════════════════════════════════════════════════════════════

func _cache_vector_nodes(arrow: Node3D, cache_dict: Dictionary) -> void:
	if arrow == null:
		return
	cache_dict["start"] = arrow.get_node_or_null("lineContainer/GrabSphere")
	cache_dict["end"] = arrow.get_node_or_null("lineContainer/GrabSphere2")
	cache_dict["line_container"] = arrow.get_node_or_null("lineContainer")


func _get_vector_fast(arrow: Node3D, cache_dict: Dictionary) -> Vector3:
	var start_node: Node3D = cache_dict.get("start")
	var end_node: Node3D = cache_dict.get("end")
	if start_node and end_node:
		return (end_node.global_position - start_node.global_position) / (SCENE_SCALE * scale.x)
	if arrow and arrow.has_method("get_vector"):
		return arrow.get_vector()
	return Vector3.ZERO


func _update_vector_fast(_arrow: Node3D, vector: Vector3, cache_dict: Dictionary) -> void:
	var end_node: Node3D = cache_dict.get("end")
	if end_node:
		end_node.position = vector * SCENE_SCALE
	var lc: Node3D = cache_dict.get("line_container")
	if lc and lc.has_method("refresh_connections"):
		lc.refresh_connections()


# ════════════════════════════════════════════════════════════════════
#  WEATHER MODES
# ════════════════════════════════════════════════════════════════════

func _cycle_mode() -> void:
	current_mode = (current_mode + 1) % MODE_NAMES.size()
	_apply_mode(current_mode)


func _apply_mode(mode_idx: int) -> void:
	current_mode = mode_idx
	var vec_a: Vector3 = MODE_VECTORS_A[mode_idx]
	var vec_b: Vector3 = MODE_VECTORS_B[mode_idx]

	# Move grab sphere endpoints to match preset
	var end_a: Node3D = _cached_a.get("end")
	if end_a:
		end_a.position = vec_a * SCENE_SCALE
	var end_b: Node3D = _cached_b.get("end")
	if end_b:
		end_b.position = vec_b * SCENE_SCALE

	# Refresh line visuals
	var lc_a: Node3D = _cached_a.get("line_container")
	if lc_a and lc_a.has_method("refresh_connections"):
		lc_a.refresh_connections()
	var lc_b: Node3D = _cached_b.get("line_container")
	if lc_b and lc_b.has_method("refresh_connections"):
		lc_b.refresh_connections()

	# Swap the particle palette to match the mode (amount/scale/color/etc).
	_apply_weather_palette(mode_idx)

	# Restart emitters so the new look takes immediately.
	_reset_particles()


## Returns the palette dict for the current mode (safe fallback).
func _palette() -> Dictionary:
	if _mode_palettes.is_empty():
		return {}
	var idx: int = clampi(current_mode, 0, _mode_palettes.size() - 1)
	return _mode_palettes[idx]


## Applies a mode palette to every GPU emitter: density (amount), particle size
## (scale), tint (color), and the snow/blizzard variant (low gravity, white,
## wide spread). drift_gain + lightning + sun are read live in the drivers.
func _apply_weather_palette(mode_idx: int) -> void:
	if _mode_palettes.is_empty():
		return
	var idx: int = clampi(mode_idx, 0, _mode_palettes.size() - 1)
	var pal: Dictionary = _mode_palettes[idx]
	var amt_mult: float = float(pal.get("amount", 1.0))
	var scl_mult: float = float(pal.get("scale", 1.0))
	var is_snow: bool = bool(pal.get("snow", false))

	# Rain / snow.
	if _rain_gpu and _rain_mat:
		_rain_gpu.amount = max(1, int(rain_count * amt_mult))
		var rc: Color = pal.get("rain_color", Color(0.55, 0.68, 1.0, 0.85))
		_rain_mat.color = rc
		if _rain_draw_mat:
			_rain_draw_mat.albedo_color = rc
			_rain_draw_mat.emission = Color(rc.r, rc.g, rc.b)
		if is_snow:
			# Blizzard: white snow — slow fall, wide spread, round flakes.
			_rain_mat.spread = 35.0
			_rain_mat.scale_min = 0.9 * scl_mult
			_rain_mat.scale_max = 1.4 * scl_mult
			_rain_gpu.lifetime = 4.0
		else:
			_rain_mat.spread = 4.0
			_rain_mat.scale_min = 0.7 * scl_mult
			_rain_mat.scale_max = 1.1 * scl_mult
			_rain_gpu.lifetime = 1.6

	# Clouds.
	if _cloud_gpu and _cloud_mat:
		var cc: Color = pal.get("cloud_color", Color(0.7, 0.73, 0.8, 0.45))
		_cloud_mat.color = cc
		_cloud_mat.color_ramp = _make_soft_alpha_ramp(Color(cc.r, cc.g, cc.b))
		if _cloud_draw_mat:
			_cloud_draw_mat.albedo_color = cc

	# Mist.
	if _mist_gpu and _mist_mat:
		var mc: Color = pal.get("mist_color", Color(0.7, 0.78, 0.9, 0.12))
		_mist_mat.color = mc
		_mist_mat.color_ramp = _make_soft_alpha_ramp(Color(mc.r, mc.g, mc.b))
		if _mist_draw_mat:
			_mist_draw_mat.albedo_color = mc


func _toggle_grid() -> void:
	grid_visible = not grid_visible
	if _arrow_shaft_mm:
		_arrow_shaft_mm.visible = grid_visible
	if _arrow_head_mm:
		_arrow_head_mm.visible = grid_visible


func reset() -> void:
	_apply_mode(0)
	gravity_strength = 1.0
	pressure_intensity = 0.5
	pressure_time = 0.0
	_reset_particles()


## Restart the continuous GPU emitters so a mode/reset change reads immediately.
## (Lightning/sun motes are one-shot/driven and need no restart here.)
func _reset_particles() -> void:
	if _rain_gpu:
		_rain_gpu.restart()
	if _cloud_gpu:
		_cloud_gpu.restart()
	if _mist_gpu:
		_mist_gpu.restart()
	if _debris_gpu:
		_debris_gpu.restart()


# ════════════════════════════════════════════════════════════════════
#  VR BUTTON CALLBACKS
# ════════════════════════════════════════════════════════════════════

func _on_mode_pressed() -> void:
	_cycle_mode()

func _on_grid_pressed() -> void:
	_toggle_grid()

func _on_reset_pressed() -> void:
	reset()

func _on_gravity_changed(value: float) -> void:
	gravity_strength = lerpf(0.0, 2.0, value)

func _on_pressure_changed(value: float) -> void:
	pressure_intensity = lerpf(0.0, 1.0, value)


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ════════════════════════════════════════════════════════════════════
#  GRID CONFIG  (wired: world_size / densities rebuild the station)
# ════════════════════════════════════════════════════════════════════

func apply_grid_config(config: Dictionary) -> void:
	## Reads optional sizing/density knobs and rebuilds the station if any change.
	## Keys: world_size (float metres), arrow_grid_size (int), rain_count (int),
	## cloud_count (int). Called by the grid system after instantiation.
	if config == null or config.is_empty():
		return

	var changed := false
	if config.has("world_size"):
		world_size = float(config["world_size"])
		changed = true
	if config.has("arrow_grid_size"):
		arrow_grid_size = max(2, int(config["arrow_grid_size"]))
		changed = true
	if config.has("rain_count"):
		rain_count = max(0, int(config["rain_count"]))
		changed = true
	if config.has("cloud_count"):
		cloud_count = max(0, int(config["cloud_count"]))
		changed = true

	if not changed:
		return

	# Only rebuild if we're already in the tree (built once). Otherwise _ready
	# will pick up the new values when it runs.
	if not is_inside_tree() or environment_root == null:
		return

	_rebuild_station()


func _rebuild_station() -> void:
	## Tears down generated content and rebuilds at the new size/density.
	# Clear generated content out of environment_root and info_root.
	for child in environment_root.get_children():
		child.queue_free()
	if info_root:
		for child in info_root.get_children():
			child.queue_free()
	# Remove the wind vectors, control panel + status label (direct children of self).
	for child in get_children():
		if child == environment_root or child == info_root:
			continue
		if not child.owner:
			child.queue_free()

	# Reset arrays/handles.
	grid_arrows_reset()

	_recompute_sizing()
	_build_all()


func grid_arrows_reset() -> void:
	_arrow_origins = PackedVector3Array()
	_arrow_count = 0
	_arrow_shaft_mm = null
	_arrow_head_mm = null
	# GPU particle handles (freed with environment_root above; null the refs).
	_rain_gpu = null
	_rain_mat = null
	_rain_draw_mat = null
	_cloud_gpu = null
	_cloud_mat = null
	_cloud_draw_mat = null
	_mist_gpu = null
	_mist_mat = null
	_mist_draw_mat = null
	_debris_gpu = null
	_debris_mat = null
	_debris_draw_mat = null
	_lightning_root = null
	_lightning_bolt = null
	_lightning_bolt_mesh = null
	_lightning_bolt_mat = null
	_lightning_sparks = null
	_lightning_light = null
	_lightning_flash = 0.0
	_lightning_glow = 0.0
	_thunder_delay = 0.0
	_thunder_pending = false
	_splash_gpu = null
	_splash_mat = null
	_sun_shaft = null
	_sun_shaft_mat = null
	_sun_motes = null
	_sun_motes_mat = null
	_sun_pulse_t = 0.0
	_streamline_mm = null
	_streamline_seeds = PackedVector3Array()
	_resultant_glow = null
	_resultant_glow_mat = null
	_glow_pulse_t = 0.0
	_cached_a = {}
	_cached_b = {}
	_cached_sum = {}
