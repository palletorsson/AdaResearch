extends "res://algorithms/vectors/shared/vector_scene_base.gd"
## Weather Vector Field — Applied Teaching Artifact
##
## Two grabbable wind vectors (Wind A, Wind B) combine via vector addition.
## The user drags arrow endpoints in VR to feel how wind directions sum.
## A 6x6 grid of display arrows shows the resulting wind field.
## Rain particles fall under gravity + wind, their diagonal paths
## demonstrating force superposition visibly.
##
## @identity
## essence: R = A + B; F_rain = gravity + wind. Vector addition drives both the field and the particles. Superposition made meteorological.
## desire: To let the learner drag two wind arrows and watch rain fall sideways — making force superposition a weather event you stand inside.
## critical_parameter: gravity_strength — it competes with wind. High gravity = rain falls nearly vertical; low gravity = rain flies nearly horizontal. The ratio is the angle.
## triggers: Drag wind handles → 36 grid arrows recolor and reorient, rain particles change trajectory, mode button → trade/cross/opposing/updraft presets, pressure slider → zones drift and distort the field
## emerges: Rain streaking diagonally as the decomposition display shows wind + gravity = trajectory. High/low pressure zones bending the uniform field into curves.
## needs: VR grabbable wind vectors [has], mode/grid/reset buttons [has], gravity/pressure sliders [has]. Missing: temperature gradient coloring the field.
## relationships: Applied extension of vector_addition_demo and VectorFieldFlow. Demonstrates the same addition in a narrative (weather) context. Contrasts with force_field_visualizer (abstract vs applied).
## truth: Wind is a vector field. Rain is a particle advected through two fields at once. Weather is superposition you can stand in.


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

# ── Display arrow grid (6x6 = 36 small arrows) ──
const GRID_SIZE := 6
const GRID_SPACING := 0.7
var grid_arrows: Array = []       # Array of Dictionary {root, shaft, cone}
var grid_visible := true

# ── Rain particles ──
const PARTICLE_COUNT := 25
var particles: Array = []         # Array of Dictionary {node, velocity, position}
var gravity_strength: float = 1.0

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

	_build_ground_plane()
	_spawn_wind_vectors()
	_build_parallelogram()
	_build_grid_arrows()
	_build_rain_particles()
	_build_pressure_zones()
	_build_decomposition_display()
	_build_controls()

	info_label = create_info_panel(
		"Weather Vector Field",
		Vector3(0.0, 4.5, -3.0),
		Vector2(3.0, 1.2),
		"R = A + B\nF_rain = gravity + wind",
		"Vector addition\nForce superposition"
	)

	# Set initial mode
	_apply_mode(0)


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
	if label_b_copy:
		label_b_copy.position = (a + b * 0.5) * SCENE_SCALE + Vector3(0, 0.08, 0) * SCENE_SCALE
	if label_a_copy:
		label_a_copy.position = (b + a * 0.5) * SCENE_SCALE + Vector3(0, 0.08, 0) * SCENE_SCALE

	# Animate pressure zones
	pressure_time += delta * 0.3
	_update_pressure_zones()

	# Update wind field grid
	if grid_visible:
		_update_grid_arrows(a, b)

	# Move rain particles
	_move_particles(delta, a, b)

	# Update decomposition arrows
	_update_decomposition(sum)

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
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(6.0, 6.0)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.1, 0.14, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.9
	floor_mesh.material_override = mat
	floor_mesh.scale = Vector3.ONE * SCENE_SCALE
	floor_mesh.position = Vector3(0, -0.01, 0) * SCENE_SCALE
	environment_root.add_child(floor_mesh)

	# Subtle grid lines on ground
	for i in range(-3, 4):
		_draw_ground_line(Vector3(float(i) * GRID_SPACING, 0, -3.0 * GRID_SPACING),
						  Vector3(float(i) * GRID_SPACING, 0, 3.0 * GRID_SPACING),
						  Color(0.2, 0.25, 0.35, 0.3))
		_draw_ground_line(Vector3(-3.0 * GRID_SPACING, 0, float(i) * GRID_SPACING),
						  Vector3(3.0 * GRID_SPACING, 0, float(i) * GRID_SPACING),
						  Color(0.2, 0.25, 0.35, 0.3))


func _draw_ground_line(from: Vector3, to: Vector3, color: Color) -> void:
	var mesh_inst := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_set_color(color)
	im.surface_add_vertex(from * SCENE_SCALE)
	im.surface_add_vertex(to * SCENE_SCALE)
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
		_dot_mesh.radius = 0.015 * SCENE_SCALE
		_dot_mesh.height = 0.03 * SCENE_SCALE
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


func _build_grid_arrows() -> void:
	var half := float(GRID_SIZE - 1) * 0.5
	for gx in range(GRID_SIZE):
		for gz in range(GRID_SIZE):
			var world_x: float = (float(gx) - half) * GRID_SPACING
			var world_z: float = (float(gz) - half) * GRID_SPACING
			var pos := Vector3(world_x, 0.15, world_z)

			var arrow_data := _build_small_arrow(pos)
			grid_arrows.append(arrow_data)


func _build_small_arrow(pos: Vector3) -> Dictionary:
	## Creates a non-interactive display arrow (cylinder shaft + cone head)
	var root := Node3D.new()
	root.name = "FieldArrow"
	root.position = pos * SCENE_SCALE
	environment_root.add_child(root)

	# Shaft
	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	var cyl := CylinderMesh.new()
	cyl.height = 1.0
	cyl.top_radius = 0.008
	cyl.bottom_radius = 0.008
	cyl.radial_segments = 6
	shaft.mesh = cyl
	shaft.material_override = _get_shared_material(Color(0.5, 0.7, 1.0), true)
	root.add_child(shaft)

	# Cone head
	var cone := MeshInstance3D.new()
	cone.name = "Cone"
	var cone_mesh := CylinderMesh.new()
	cone_mesh.height = 0.06
	cone_mesh.bottom_radius = 0.02
	cone_mesh.top_radius = 0.0
	cone_mesh.radial_segments = 8
	cone.mesh = cone_mesh
	cone.material_override = _get_shared_material(Color(0.5, 0.7, 1.0), true)
	root.add_child(cone)

	return {"root": root, "shaft": shaft, "cone": cone}


func _build_rain_particles() -> void:
	var rain_mat := _get_shared_material(Color(0.5, 0.7, 1.0, 0.8), true)
	for i in range(PARTICLE_COUNT):
		var mesh := MeshInstance3D.new()
		mesh.name = "Rain_%d" % i
		var sphere := SphereMesh.new()
		sphere.radius = 0.02 * SCENE_SCALE
		sphere.height = 0.04 * SCENE_SCALE
		sphere.radial_segments = 8
		sphere.rings = 4
		mesh.mesh = sphere
		mesh.material_override = rain_mat
		environment_root.add_child(mesh)

		var start_pos := _random_rain_start()
		mesh.position = start_pos * SCENE_SCALE

		particles.append({
			"node": mesh,
			"velocity": Vector3.ZERO,
			"position": start_pos,
		})


func _build_pressure_zones() -> void:
	# High pressure — blue translucent sphere, pushes outward
	high_pressure = _create_pressure_sphere(Color(0.2, 0.4, 0.9, 0.12), "HighPressure")
	high_pressure.position = Vector3(1.5, 0.3, -1.0) * SCENE_SCALE
	environment_root.add_child(high_pressure)

	# Low pressure — red translucent sphere, pulls inward
	low_pressure = _create_pressure_sphere(Color(0.9, 0.2, 0.2, 0.12), "LowPressure")
	low_pressure.position = Vector3(-1.5, 0.3, 1.0) * SCENE_SCALE
	environment_root.add_child(low_pressure)


func _create_pressure_sphere(color: Color, sphere_name: String) -> Node3D:
	var root := Node3D.new()
	root.name = sphere_name

	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.35 * SCENE_SCALE
	sphere.height = 0.7 * SCENE_SCALE
	sphere.radial_segments = 24
	sphere.rings = 16
	mesh.mesh = sphere

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
	label.position = Vector3(0, 0.4, 0) * SCENE_SCALE
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	root.add_child(label)

	return root


func _build_decomposition_display() -> void:
	# Shows wind + gravity = trajectory at a sample point
	decomp_root = Node3D.new()
	decomp_root.name = "Decomposition"
	decomp_root.position = Vector3(2.0, 0.3, 2.0) * SCENE_SCALE
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
	decomp_label.position = Vector3(0, 0.6, 0) * SCENE_SCALE
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


func _build_controls() -> void:
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
	var sc := SCENE_SCALE
	var control_base := Vector3(-3.5, 1.5, -2.5)
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
	## Returns the wind vector at a world position.
	## Base wind is A + B, plus pressure zone perturbation.
	var base_wind := base_a + base_b

	if pressure_intensity > 0.001:
		# High pressure pushes outward from its center
		var hp_center := high_pressure.position / SCENE_SCALE
		var to_from_hp := pos - hp_center
		var hp_dist := to_from_hp.length()
		if hp_dist > 0.1:
			base_wind += to_from_hp.normalized() * pressure_intensity * 0.5 / (1.0 + hp_dist)

		# Low pressure pulls inward
		var lp_center := low_pressure.position / SCENE_SCALE
		var to_lp := lp_center - pos
		var lp_dist := to_lp.length()
		if lp_dist > 0.1:
			base_wind += to_lp.normalized() * pressure_intensity * 0.5 / (1.0 + lp_dist)

	return base_wind


func _update_grid_arrows(a: Vector3, b: Vector3) -> void:
	var sc := SCENE_SCALE
	for arrow_data in grid_arrows:
		var root: Node3D = arrow_data["root"]
		var shaft: MeshInstance3D = arrow_data["shaft"]
		var cone: MeshInstance3D = arrow_data["cone"]

		var world_pos := root.position / sc
		var wind := _wind_at(world_pos, a, b)
		var mag := wind.length()

		if mag < 0.01:
			shaft.visible = false
			cone.visible = false
			continue

		shaft.visible = true
		cone.visible = true

		# Orient arrow along wind direction
		var dir := wind.normalized()
		var arrow_len: float = clampf(mag * 0.15, 0.02, 0.25) * sc

		# Shaft: positioned at half-length along direction
		shaft.transform.basis = _basis_from_direction(dir)
		shaft.scale = Vector3(1, arrow_len / 1.0, 1)  # CylinderMesh.height = 1.0
		shaft.position = dir * (arrow_len * 0.5)

		# Cone: positioned at end of shaft
		cone.transform.basis = _basis_from_direction(dir)
		cone.position = dir * arrow_len

		# Color by magnitude: blue (calm) -> yellow -> red (strong)
		var t: float = clampf(mag / 3.0, 0.0, 1.0)
		var color: Color
		if t < 0.5:
			color = Color(0.3, 0.5, 1.0).lerp(Color(1.0, 1.0, 0.3), t * 2.0)
		else:
			color = Color(1.0, 1.0, 0.3).lerp(Color(1.0, 0.2, 0.1), (t - 0.5) * 2.0)

		shaft.material_override = _get_shared_material(color, true)
		cone.material_override = _get_shared_material(color, true)


func _move_particles(delta: float, a: Vector3, b: Vector3) -> void:
	var sc := SCENE_SCALE
	var grav := Vector3(0, -gravity_strength, 0)

	for p in particles:
		var pos: Vector3 = p["position"]
		var vel: Vector3 = p["velocity"]

		# Force = gravity + wind at position
		var wind := _wind_at(pos, a, b)
		var force := grav + wind

		# Velocity lerp (smooth, not instant)
		vel = vel.lerp(force, 3.0 * delta)
		pos += vel * delta

		# Respawn if below ground or too far
		if pos.y < -0.5 or pos.length() > 5.0:
			pos = _random_rain_start()
			vel = Vector3.ZERO

		p["position"] = pos
		p["velocity"] = vel

		var node: MeshInstance3D = p["node"]
		node.position = pos * sc


func _update_pressure_zones() -> void:
	# Slowly drift pressure zones
	var hp_x: float = 1.5 + sin(pressure_time) * 0.5
	var hp_z: float = -1.0 + cos(pressure_time * 0.7) * 0.3
	high_pressure.position = Vector3(hp_x, 0.3, hp_z) * SCENE_SCALE

	var lp_x: float = -1.5 + cos(pressure_time * 0.8) * 0.5
	var lp_z: float = 1.0 + sin(pressure_time * 0.6) * 0.3
	low_pressure.position = Vector3(lp_x, 0.3, lp_z) * SCENE_SCALE


func _update_decomposition(sum: Vector3) -> void:
	if decomp_root == null:
		return

	var sc := SCENE_SCALE
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


func _update_info_text(a: Vector3, b: Vector3, sum: Vector3) -> void:
	if info_label == null:
		return

	var angle_deg: float = 0.0
	if a.length() > 0.01 and b.length() > 0.01:
		angle_deg = rad_to_deg(a.angle_to(b))

	var lines: Array = []
	lines.append("A = (%.1f, %.1f, %.1f)  |A| = %.2f" % [a.x, a.y, a.z, a.length()])
	lines.append("B = (%.1f, %.1f, %.1f)  |B| = %.2f" % [b.x, b.y, b.z, b.length()])
	lines.append("A+B = (%.1f, %.1f, %.1f)  |A+B| = %.2f" % [sum.x, sum.y, sum.z, sum.length()])
	lines.append("Angle(A,B) = %.1f deg" % angle_deg)
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
	# Line from tip of A to A+B (showing B's copy)
	_update_single_dotted_line(dotted_line_b, a * SCENE_SCALE, (a + b) * SCENE_SCALE)
	# Line from tip of B to A+B (showing A's copy)
	_update_single_dotted_line(dotted_line_a, b * SCENE_SCALE, (a + b) * SCENE_SCALE)


func _update_single_dotted_line(mmi: MultiMeshInstance3D, start: Vector3, end: Vector3) -> void:
	if mmi == null:
		return
	var direction := end - start
	var distance := direction.length()
	if distance < 0.001:
		mmi.visible = false
		return
	mmi.visible = true
	var spacing: float = 0.15 * SCENE_SCALE
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
	for arrow_data in grid_arrows:
		var root: Node3D = arrow_data["root"]
		root.visible = grid_visible


func reset() -> void:
	_apply_mode(0)
	gravity_strength = 1.0
	pressure_intensity = 0.5
	pressure_time = 0.0
	_reset_particles()


func _reset_particles() -> void:
	for p in particles:
		p["position"] = _random_rain_start()
		p["velocity"] = Vector3.ZERO


func _random_rain_start() -> Vector3:
	return Vector3(
		randf_range(-2.5, 2.5),
		randf_range(2.0, 4.0),
		randf_range(-2.5, 2.5)
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


func apply_grid_config(config: Dictionary) -> void:
	pass
