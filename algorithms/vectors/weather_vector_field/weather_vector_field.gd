extends "res://algorithms/vectors/shared/vector_scene_base.gd"
## Weather Vector Field — Applied Teaching Artifact (Weather Station edition)
##
## Two grabbable wind vectors (Wind A, Wind B) combine via vector addition.
## The user drags arrow endpoints in VR to feel how wind directions sum.
## A dense field of display arrows shows the resulting wind field. Rain
## particles fall under gravity + wind, their diagonal paths demonstrating
## force superposition visibly.
##
## The space is now a walkable weather station (~5x5 m). Real instruments ring
## the perimeter — a windsock, a 3-cup anemometer, a compass rose, a drifting
## cloud layer, and fading wind streamlines — every one of them DRIVEN by the
## live summed wind vector. Change the mode preset or drag the wind handles and
## the whole station reacts. The field and ground tint warm/cool with the wind's
## thermal sign (updraft = warm, downdraft = cool).
##
## @identity
## essence: R = A + B; F_rain = gravity + wind. Vector addition drives both the field and the particles. Superposition made meteorological — and now instrumented.
## desire: To let the learner walk inside a weather station, drag two wind arrows, and watch every instrument (sock, anemometer, compass, clouds, streamlines) answer the same summed vector.
## critical_parameter: gravity_strength — it competes with wind. High gravity = rain falls nearly vertical; low gravity = rain flies nearly horizontal. The ratio is the angle.
## triggers: Drag wind handles → field arrows recolor/reorient, rain re-trajects, windsock yaws + lifts, anemometer spins faster, compass needle swings, clouds advect, streamlines redraw, ground tints warm/cool. Mode button → trade/cross/opposing/updraft presets. Pressure slider → zones drift and distort the field.
## emerges: Rain streaking diagonally as the decomposition display shows wind + gravity = trajectory. A windsock standing straight out in a gale, slack in calm. The whole station agreeing on one vector.
## needs: VR grabbable wind vectors [has], mode/grid/reset buttons [has], gravity/pressure sliders [has], temperature gradient coloring [has], weather instruments [has].
## relationships: Applied extension of vector_addition_demo and VectorFieldFlow (MultiMesh field), and particle_flow_swarm (advecting clouds). Demonstrates the same addition in a narrative (weather) context.
## truth: Wind is a vector field. Rain is a particle advected through two fields at once. Every instrument in a weather station is a different read of the same vector.


# ── Sizing / domain ──
# world_size is the target walkable extent in metres. The base class SCENE_SCALE
# (a const, 0.33) and this node's local scale (0.5) already shrink the scene; we
# fold an extra world_scale multiplier on top so the station can grow without
# touching the shared const. domain_extent is the half-width of the field in the
# scene's *unit* space (pre-scale), used for grid spread, cloud wrap, rain spawn.
@export var world_size: float = 5.0      # target walkable size in metres (~5x5 m)
@export var arrow_grid_size: int = 12    # arrows per side (12x12 = 144) — MultiMesh
@export var rain_count: int = 200        # rain droplets — MultiMesh
@export var cloud_count: int = 36        # cloud puffs — MultiMesh

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

# ── Rain particles (MultiMesh) ──
var gravity_strength: float = 1.0
var _rain_state: Array = []              # Array of {pos: Vector3, vel: Vector3}
var _rain_mm: MultiMeshInstance3D

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
var _cloud_state: Array = []             # Array of {pos: Vector3}
var _cloud_mm: MultiMeshInstance3D
const STREAMLINE_COUNT := 5
const STREAMLINE_SEGMENTS := 16
var _streamline_mm: MultiMeshInstance3D
var _streamline_seeds: PackedVector3Array = PackedVector3Array()
static var _stream_dot_mesh: SphereMesh

# ── Weather modes ──
var current_mode: int = 0
const MODE_NAMES := ["Trade Winds", "Crosswinds", "Opposing Winds", "Updraft"]
const MODE_VECTORS_A := [
	Vector3(2.0, 0.0, 0.0),     # Trade: pure east
	Vector3(1.0, 0.0, 0.0),     # Cross: east
	Vector3(1.0, 0.0, 0.0),     # Opposing: east
	Vector3(0.0, 0.5, 0.0),     # Updraft: up
]
const MODE_VECTORS_B := [
	Vector3(0.0, 0.0, 0.0),     # Trade: none
	Vector3(0.0, 0.0, 1.0),     # Cross: north
	Vector3(-0.8, 0.0, 0.0),    # Opposing: west
	Vector3(0.0, 0.8, 0.0),     # Updraft: more up
]

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

	_recompute_sizing()
	_build_all()


func _build_all() -> void:
	_build_ground_plane()
	_spawn_wind_vectors()
	_build_parallelogram()
	_build_grid_arrows()
	_build_rain_particles()
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

	# Move rain particles (MultiMesh)
	_move_particles(delta, a, b)

	# Update decomposition arrows
	_update_decomposition(sum)

	# Weather instruments — all driven by the live summed wind vector
	_update_instruments(delta, sum)
	_update_clouds(delta, a, b)
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
	ground_material.albedo_color = Color(0.08, 0.1, 0.14, 0.85)
	ground_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ground_material.roughness = 0.9
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
	mat.emission_energy_multiplier = 1.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


# ── Rain: MultiMesh droplets (pattern from particle_campfire.gd) ──

func _build_rain_particles() -> void:
	_rain_state.clear()
	var rain_mm := MultiMesh.new()
	rain_mm.transform_format = MultiMesh.TRANSFORM_3D
	rain_mm.use_colors = true
	rain_mm.instance_count = rain_count
	var sphere := SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.05
	sphere.radial_segments = 6
	sphere.rings = 3
	rain_mm.mesh = sphere
	_rain_mm = MultiMeshInstance3D.new()
	_rain_mm.name = "RainMM"
	_rain_mm.multimesh = rain_mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 1.2
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_rain_mm.material_override = mat
	environment_root.add_child(_rain_mm)

	for i in range(rain_count):
		_rain_state.append({
			"pos": _random_rain_start(),
			"vel": Vector3.ZERO,
		})


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
	## A simple cylinder arrow for the decomposition display
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.height = 1.0
	cyl.top_radius = 0.006
	cyl.bottom_radius = 0.006
	cyl.radial_segments = 6
	mesh.mesh = cyl
	mesh.material_override = _get_shared_material(color, true)
	return mesh


# ════════════════════════════════════════════════════════════════════
#  WEATHER INSTRUMENTS  (all read the live summed wind vector)
# ════════════════════════════════════════════════════════════════════

func _build_instruments() -> void:
	_build_windsock()
	_build_anemometer()
	_build_compass_rose()
	_build_cloud_layer()
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
	windsock_material.emission_energy_multiplier = 0.8
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

	var cup_mat := _get_shared_material(Color(0.85, 0.85, 0.9), false)
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
	needle_mat.emission = Color(0.9, 0.2, 0.2)
	needle_mat.emission_energy_multiplier = 0.8
	needle_mesh.material_override = needle_mat
	compass_needle.add_child(needle_mesh)


## Cloud layer — MultiMesh puffs at mid-height that advect with the wind and
## wrap at the domain edge (pattern from particle_flow_swarm.gd).
func _build_cloud_layer() -> void:
	_cloud_state.clear()
	var cloud_mm := MultiMesh.new()
	cloud_mm.transform_format = MultiMesh.TRANSFORM_3D
	cloud_mm.use_colors = true
	cloud_mm.instance_count = cloud_count
	var puff := SphereMesh.new()
	puff.radius = 0.5
	puff.height = 1.0
	puff.radial_segments = 8
	puff.rings = 5
	cloud_mm.mesh = puff
	_cloud_mm = MultiMeshInstance3D.new()
	_cloud_mm.name = "CloudMM"
	_cloud_mm.multimesh = cloud_mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.5
	mat.roughness = 1.0
	_cloud_mm.material_override = mat
	environment_root.add_child(_cloud_mm)

	for i in range(cloud_count):
		_cloud_state.append({
			"pos": Vector3(
				randf_range(-domain_extent, domain_extent),
				randf_range(2.2, 3.2),
				randf_range(-domain_extent, domain_extent)
			),
			"size": randf_range(0.6, 1.4),
		})


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


func _move_particles(delta: float, a: Vector3, b: Vector3) -> void:
	if not _rain_mm:
		return
	var sc := _sc()
	var grav := Vector3(0, -gravity_strength, 0)
	var rain_mm := _rain_mm.multimesh
	var splash := domain_extent + 1.5

	for i in range(_rain_state.size()):
		var p: Dictionary = _rain_state[i]
		var pos: Vector3 = p["pos"]
		var vel: Vector3 = p["vel"]

		# Force = gravity + wind at position
		var wind := _wind_at(pos, a, b)
		var force := grav + wind

		# Velocity lerp (smooth, not instant)
		vel = vel.lerp(force, 3.0 * delta)
		pos += vel * delta

		# Respawn if below ground or too far
		if pos.y < -0.5 or pos.length() > splash:
			pos = _random_rain_start()
			vel = Vector3.ZERO

		p["pos"] = pos
		p["vel"] = vel

		# Color: cooler blue when slow, brighter when fast-moving
		var speed: float = vel.length()
		var rc := Color(0.45, 0.6, 1.0, 0.85).lerp(Color(0.7, 0.85, 1.0, 0.95), clampf(speed / 3.0, 0.0, 1.0))
		rain_mm.set_instance_color(i, rc)
		rain_mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, pos * sc))


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


func _update_clouds(delta: float, a: Vector3, b: Vector3) -> void:
	if not _cloud_mm:
		return
	var sc := _sc()
	var cloud_mm := _cloud_mm.multimesh
	for i in range(_cloud_state.size()):
		var c: Dictionary = _cloud_state[i]
		var pos: Vector3 = c["pos"]
		# Advect with horizontal wind at this height (use base wind only — cheap).
		var wind := a + b
		pos.x += wind.x * delta * 0.4
		pos.z += wind.z * delta * 0.4
		# Wrap at domain edge.
		if pos.x > domain_extent:
			pos.x -= 2.0 * domain_extent
		elif pos.x < -domain_extent:
			pos.x += 2.0 * domain_extent
		if pos.z > domain_extent:
			pos.z -= 2.0 * domain_extent
		elif pos.z < -domain_extent:
			pos.z += 2.0 * domain_extent
		c["pos"] = pos

		var size: float = c["size"]
		var xform := Transform3D(Basis().scaled(Vector3.ONE * size * 0.45 * sc), pos * sc)
		cloud_mm.set_instance_transform(i, xform)
		# Whiter/brighter clouds when wind is strong, greyer when calm.
		var st: float = clampf(Vector2(wind.x, wind.z).length() / 3.0, 0.0, 1.0)
		var grey: float = lerp(0.55, 0.85, st)
		cloud_mm.set_instance_color(i, Color(grey, grey, grey * 1.02, 0.5))


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
	if ground_material == null:
		return
	# -1 (cool/down) .. +1 (warm/up)
	var thermal: float = clampf(sum.y * 0.6, -1.0, 1.0)
	var t: float = (thermal + 1.0) * 0.5   # 0..1
	var cool := Color(0.06, 0.1, 0.18, 0.85)
	var warm := Color(0.16, 0.11, 0.08, 0.85)
	var base := cool.lerp(warm, t)
	ground_material.albedo_color = base
	var cool_em := Color(0.04, 0.06, 0.12)
	var warm_em := Color(0.14, 0.07, 0.03)
	ground_material.emission = cool_em.lerp(warm_em, t)


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

	# Reset particles for new mode
	_reset_particles()


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


func _reset_particles() -> void:
	for p in _rain_state:
		p["pos"] = _random_rain_start()
		p["vel"] = Vector3.ZERO


func _random_rain_start() -> Vector3:
	var e := domain_extent * 0.85
	return Vector3(
		randf_range(-e, e),
		randf_range(2.0, 4.0),
		randf_range(-e, e)
	)


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
	_rain_state.clear()
	_rain_mm = null
	_cloud_state.clear()
	_cloud_mm = null
	_streamline_mm = null
	_streamline_seeds = PackedVector3Array()
	_cached_a = {}
	_cached_b = {}
	_cached_sum = {}
