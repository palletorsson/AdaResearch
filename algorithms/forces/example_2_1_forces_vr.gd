# ===========================================================================
# NOC Example 2.1: Forces (Elevated)
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# Elevated version with:
#   - Air resistance (velocity-dependent quadratic drag)
#   - Orbital mechanics (Kepler ellipses, equal-area sweep)
#   - Force field visualization (ImmediateMesh vector arrows)
#   - VR slider controls and apply_grid_config()
#
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 2.1: Forces (Elevated)
## Wind, gravity, air resistance, orbital mechanics, and force field visualization

# --- Mode ---
enum Mode { FORCES, ORBITAL }
var _mode: int = Mode.FORCES

# --- Physics parameters ---
var gravity_strength: float = 0.5
var wind_strength: float = 0.3
var drag_coefficient: float = 0.04
var wind_enabled: bool = true

# --- Orbital parameters ---
var central_mass: float = 4.0
var orbital_G: float = 0.6

# --- Movers ---
var _movers: Array = []
var _mover_trails: Dictionary = {}
const MAX_TRAIL_LENGTH := 120
const MOVER_CONFIGS_FORCES := [
	{ "mass": 0.6, "pos": Vector3(-0.25, 0.35, 0.0), "vel": Vector3(0.0, 0.0, 0.0), "color": Color(0.95, 0.55, 0.85) },
	{ "mass": 1.0, "pos": Vector3(-0.08, 0.35, -0.1), "vel": Vector3(0.0, 0.0, 0.0), "color": Color(0.65, 0.75, 0.95) },
	{ "mass": 1.8, "pos": Vector3(0.12, 0.35, 0.05), "vel": Vector3(0.0, 0.0, 0.0), "color": Color(0.55, 0.95, 0.75) },
	{ "mass": 2.5, "pos": Vector3(0.28, 0.35, -0.05), "vel": Vector3(0.0, 0.0, 0.0), "color": Color(0.95, 0.75, 0.45) },
]
const MOVER_CONFIGS_ORBITAL := [
	{ "mass": 0.4, "pos": Vector3(0.18, 0.0, 0.0), "vel": Vector3(0.0, 0.0, 0.35), "color": Color(0.95, 0.55, 0.85) },
	{ "mass": 0.7, "pos": Vector3(0.28, 0.0, 0.0), "vel": Vector3(0.0, 0.0, 0.28), "color": Color(0.65, 0.75, 0.95) },
	{ "mass": 1.0, "pos": Vector3(-0.35, 0.0, 0.0), "vel": Vector3(0.0, 0.0, -0.22), "color": Color(0.55, 0.95, 0.75) },
]

# --- Central body (orbital mode) ---
var _central_body: MeshInstance3D
var _central_mat: StandardMaterial3D

# --- Visuals ---
var _field_mesh_inst: MeshInstance3D
var _trail_mesh_inst: MeshInstance3D
var _sweep_mesh_inst: MeshInstance3D
var _mat_unshaded: StandardMaterial3D

# --- Force field grid ---
const FIELD_GRID_SIZE := 7
const FIELD_SPACING := 0.1
const ARROW_SCALE := 0.12
const ARROW_HEAD_FRAC := 0.3

# --- UI ---
var _panel: ForcesRackPanel
var _drag_slider: Node3D
var _gravity_slider: Node3D
var _wind_slider: Node3D
var _mode_readout: Label3D
var _velocity_readout: Label3D
var _drag_readout: Label3D

# --- Sweep tracking (orbital) ---
var _sweep_areas: Dictionary = {}
var _sweep_prev_pos: Dictionary = {}
const SWEEP_INTERVAL := 0.5
var _sweep_timer: float = 0.0
var _sweep_triangles: Array = []
const MAX_SWEEP_TRIS := 40

# --- Auto reset ---
var _auto_reset_timer: Timer


func _ready() -> void:
	scale = Vector3(0.8, 0.8, 0.8)
	_create_materials()
	_create_visual_nodes()
	_create_panel()
	_spawn_movers()
	_setup_auto_reset()


func _process(delta: float) -> void:
	_step_physics(delta)
	_draw_force_field()
	_draw_trails()
	if _mode == Mode.ORBITAL:
		_update_sweep(delta)
		_draw_sweep()
	_update_readouts()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				wind_enabled = !wind_enabled
			KEY_TAB:
				_toggle_mode()
			KEY_R:
				_reset_scene()


# ── Materials ──────────────────────────────────────────────────────────

func _create_materials() -> void:
	_mat_unshaded = StandardMaterial3D.new()
	_mat_unshaded.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_unshaded.vertex_color_use_as_albedo = true
	_mat_unshaded.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_unshaded.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_unshaded.no_depth_test = false


# ── Visual nodes ───────────────────────────────────────────────────────

func _create_visual_nodes() -> void:
	_field_mesh_inst = MeshInstance3D.new()
	_field_mesh_inst.name = "ForceFieldMesh"
	_field_mesh_inst.material_override = _mat_unshaded
	add_child(_field_mesh_inst)

	_trail_mesh_inst = MeshInstance3D.new()
	_trail_mesh_inst.name = "TrailMesh"
	_trail_mesh_inst.material_override = _mat_unshaded
	add_child(_trail_mesh_inst)

	_sweep_mesh_inst = MeshInstance3D.new()
	_sweep_mesh_inst.name = "SweepMesh"
	_sweep_mesh_inst.material_override = _mat_unshaded
	add_child(_sweep_mesh_inst)

	# Central body for orbital mode (hidden initially)
	_central_mat = StandardMaterial3D.new()
	_central_mat.albedo_color = Color(0.95, 0.85, 0.25)
	_central_mat.emission_enabled = true
	_central_mat.emission = Color(0.95, 0.75, 0.15)
	_central_mat.emission_energy_multiplier = 0.6

	_central_body = MeshInstance3D.new()
	_central_body.name = "CentralBody"
	var sphere := SphereMesh.new()
	sphere.radius = 0.04
	sphere.height = 0.08
	_central_body.mesh = sphere
	_central_body.material_override = _central_mat
	_central_body.visible = false
	add_child(_central_body)


# ── Panel / UI ─────────────────────────────────────────────────────────

func _create_panel() -> void:
	_panel = ForcesRackPanel.new()
	_panel.setup("2.1  Forces (Elevated)", 2, 4)
	_panel.set_instructions("[TAB] Mode  [SPACE] Wind  [R] Reset")

	_gravity_slider = _panel.add_slider("Gravity", 0.0, 1.5, gravity_strength, 0.05)
	_gravity_slider.slider_moved.connect(func(_n): gravity_strength = _panel.get_slider_value(0))

	_drag_slider = _panel.add_slider("Drag Cd", 0.0, 0.2, drag_coefficient, 0.005)
	_drag_slider.slider_moved.connect(func(_n): drag_coefficient = _panel.get_slider_value(1))

	_wind_slider = _panel.add_slider("Wind", 0.0, 1.0, wind_strength, 0.05)
	_wind_slider.slider_moved.connect(func(_n): wind_strength = _panel.get_slider_value(2))

	_mode_readout = _panel.add_readout("Mode", "FORCES")
	_velocity_readout = _panel.add_readout("Velocity", "--")
	_drag_readout = _panel.add_readout("Drag F", "--")

	_panel.position = Vector3(-0.55, 0.35, 0.15)
	_panel.rotation_degrees = Vector3(0, 30, 0)
	add_child(_panel)


func _update_readouts() -> void:
	if not _panel:
		return
	_panel.update_readout("Mode", "ORBITAL" if _mode == Mode.ORBITAL else "FORCES")

	if _movers.size() > 0 and is_instance_valid(_movers[0]):
		var v: Vector3 = _movers[0].velocity
		_panel.update_readout("Velocity", "%.2f" % v.length())
		var drag_mag: float = _compute_drag(_movers[0]).length()
		_panel.update_readout("Drag F", "%.3f" % drag_mag)


# ── Movers ─────────────────────────────────────────────────────────────

func _spawn_movers() -> void:
	_clear_movers()
	var configs: Array = MOVER_CONFIGS_FORCES if _mode == Mode.FORCES else MOVER_CONFIGS_ORBITAL

	for cfg in configs:
		var mover := Mover.new()
		mover.mass = float(cfg["mass"])
		mover.position_v = Vector3(cfg["pos"])
		mover.velocity = Vector3(cfg["vel"])
		mover.acceleration = Vector3.ZERO
		mover.bounce_damping = 0.5
		mover.set_size(0.025 + mover.mass * 0.012)
		add_child(mover)
		mover.set_color(cfg["color"])
		_movers.append(mover)
		_mover_trails[mover] = []

	_sweep_triangles.clear()
	_sweep_areas.clear()
	_sweep_prev_pos.clear()
	_sweep_timer = 0.0

	_central_body.visible = (_mode == Mode.ORBITAL)


func _clear_movers() -> void:
	for m in _movers:
		if is_instance_valid(m):
			m.queue_free()
	_movers.clear()
	_mover_trails.clear()


# ── Physics ────────────────────────────────────────────────────────────

func _step_physics(delta: float) -> void:
	for mover in _movers:
		if not is_instance_valid(mover):
			continue

		if _mode == Mode.FORCES:
			# Gravity (mass-dependent)
			var gravity: Vector3 = Vector3(0, -gravity_strength, 0) * mover.mass
			mover.apply_force(gravity)

			# Wind (mass-independent)
			if wind_enabled:
				mover.apply_force(Vector3(wind_strength, 0, 0))

			# Air resistance (quadratic drag)
			var drag := _compute_drag(mover)
			mover.apply_force(drag)

			# Floor bounce
			_bounce_floor(mover)

		elif _mode == Mode.ORBITAL:
			# Gravitational attraction to central body
			var dir: Vector3 = -mover.position_v
			var dist: float = dir.length()
			dist = clamp(dist, 0.04, 1.0)
			dir = dir.normalized()
			var strength: float = (orbital_G * central_mass * mover.mass) / (dist * dist)
			mover.apply_force(dir * strength)

			# Light drag for stability
			var drag := _compute_drag(mover)
			mover.apply_force(drag * 0.3)

		# Record trail
		var trail: Array = _mover_trails.get(mover, [])
		trail.append(Vector3(mover.position_v))
		if trail.size() > MAX_TRAIL_LENGTH:
			trail.pop_front()
		_mover_trails[mover] = trail


func _compute_drag(mover: Mover) -> Vector3:
	var speed: float = mover.velocity.length()
	if speed < 0.001:
		return Vector3.ZERO
	# F_drag = -½ * Cd * |v|² * v̂
	var drag_mag: float = 0.5 * drag_coefficient * speed * speed
	return -mover.velocity.normalized() * drag_mag


func _bounce_floor(mover: Mover) -> void:
	if mover.position_v.y < -0.05:
		mover.position_v.y = -0.05
		mover.velocity.y *= -mover.bounce_damping
	# Side walls
	if abs(mover.position_v.x) > 0.5:
		mover.position_v.x = sign(mover.position_v.x) * 0.5
		mover.velocity.x *= -mover.bounce_damping
	if abs(mover.position_v.z) > 0.5:
		mover.position_v.z = sign(mover.position_v.z) * 0.5
		mover.velocity.z *= -mover.bounce_damping


# ── Force field arrows (ImmediateMesh) ─────────────────────────────────

func _draw_force_field() -> void:
	var im := ImmediateMesh.new()
	var half := (FIELD_GRID_SIZE - 1) * FIELD_SPACING * 0.5

	if _mode == Mode.FORCES:
		# 2D grid in XY plane showing gravity + wind + drag at rest
		for xi in range(FIELD_GRID_SIZE):
			for yi in range(FIELD_GRID_SIZE):
				var gx: float = xi * FIELD_SPACING - half
				var gy: float = yi * FIELD_SPACING - half + 0.15
				var origin := Vector3(gx, gy, -0.15)

				var force := Vector3(0, -gravity_strength, 0)
				if wind_enabled:
					force += Vector3(wind_strength, 0, 0)

				_draw_arrow(im, origin, force, Color(0.45, 0.65, 0.95, 0.35))

	elif _mode == Mode.ORBITAL:
		# Radial field around central body in XZ plane
		for xi in range(FIELD_GRID_SIZE):
			for zi in range(FIELD_GRID_SIZE):
				var gx: float = xi * FIELD_SPACING - half
				var gz: float = zi * FIELD_SPACING - half
				var origin := Vector3(gx, 0, gz)

				var dir: Vector3 = -origin
				var dist: float = dir.length()
				if dist < 0.06:
					continue
				dist = clamp(dist, 0.06, 1.0)
				dir = dir.normalized()
				var strength: float = (orbital_G * central_mass) / (dist * dist)
				var force := dir * strength

				var intensity: float = clamp(strength * 0.5, 0.1, 1.0)
				var col := Color(0.95, 0.45 + 0.4 * (1.0 - intensity), 0.15, 0.25 + 0.2 * intensity)
				_draw_arrow(im, origin, force, col)

	_field_mesh_inst.mesh = im


func _draw_arrow(im: ImmediateMesh, origin: Vector3, force: Vector3, color: Color) -> void:
	var mag: float = force.length()
	if mag < 0.01:
		return
	var dir: Vector3 = force.normalized()
	var length: float = clamp(mag * ARROW_SCALE, 0.01, 0.06)
	var tip: Vector3 = origin + dir * length
	var head_start: Vector3 = origin + dir * length * (1.0 - ARROW_HEAD_FRAC)

	# Shaft line
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_set_color(color)
	im.surface_add_vertex(origin)
	im.surface_set_color(color)
	im.surface_add_vertex(head_start)
	im.surface_end()

	# Arrowhead as two small lines
	var perp: Vector3
	if abs(dir.dot(Vector3.UP)) < 0.95:
		perp = dir.cross(Vector3.UP).normalized()
	else:
		perp = dir.cross(Vector3.RIGHT).normalized()
	var head_size: float = length * 0.2
	var head_col := Color(color.r, color.g, color.b, color.a * 1.3)

	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_set_color(head_col)
	im.surface_add_vertex(tip)
	im.surface_set_color(head_col)
	im.surface_add_vertex(head_start + perp * head_size)
	im.surface_end()

	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_set_color(head_col)
	im.surface_add_vertex(tip)
	im.surface_set_color(head_col)
	im.surface_add_vertex(head_start - perp * head_size)
	im.surface_end()


# ── Trails ─────────────────────────────────────────────────────────────

func _draw_trails() -> void:
	var im := ImmediateMesh.new()

	for mover in _movers:
		if not is_instance_valid(mover):
			continue
		var trail: Array = _mover_trails.get(mover, [])
		if trail.size() < 2:
			continue

		var base_color: Color = mover.primary_pink if mover.material else Color(0.8, 0.6, 0.9)
		im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for i in range(trail.size()):
			var alpha: float = float(i) / float(trail.size()) * 0.6
			im.surface_set_color(Color(base_color.r, base_color.g, base_color.b, alpha))
			im.surface_add_vertex(trail[i])
		im.surface_end()

	_trail_mesh_inst.mesh = im


# ── Kepler sweep area (orbital mode) ──────────────────────────────────

func _update_sweep(delta: float) -> void:
	_sweep_timer += delta
	if _sweep_timer < SWEEP_INTERVAL:
		return
	_sweep_timer = 0.0

	for mover in _movers:
		if not is_instance_valid(mover):
			continue
		var prev: Variant = _sweep_prev_pos.get(mover, null)
		if prev != null:
			# Triangle from origin to prev to current — demonstrates equal area in equal time
			_sweep_triangles.append({
				"a": Vector3.ZERO,
				"b": Vector3(prev),
				"c": Vector3(mover.position_v),
				"color": mover.primary_pink if mover.material else Color(0.7, 0.5, 0.9),
			})
			if _sweep_triangles.size() > MAX_SWEEP_TRIS:
				_sweep_triangles.pop_front()
		_sweep_prev_pos[mover] = Vector3(mover.position_v)


func _draw_sweep() -> void:
	var im := ImmediateMesh.new()
	for i in range(_sweep_triangles.size()):
		var tri: Dictionary = _sweep_triangles[i]
		var alpha: float = float(i) / float(_sweep_triangles.size()) * 0.2 + 0.05
		var col := Color(tri["color"].r, tri["color"].g, tri["color"].b, alpha)

		im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		im.surface_set_color(col)
		im.surface_add_vertex(tri["a"])
		im.surface_set_color(col)
		im.surface_add_vertex(tri["b"])
		im.surface_set_color(col)
		im.surface_add_vertex(tri["c"])
		im.surface_end()

	_sweep_mesh_inst.mesh = im


# ── Mode toggle ────────────────────────────────────────────────────────

func _toggle_mode() -> void:
	_mode = Mode.ORBITAL if _mode == Mode.FORCES else Mode.FORCES
	_spawn_movers()


# ── Reset ──────────────────────────────────────────────────────────────

func _reset_scene() -> void:
	gravity_strength = 0.5
	wind_strength = 0.3
	drag_coefficient = 0.04
	wind_enabled = true
	if _panel:
		_panel.set_slider_value(0, gravity_strength)
		_panel.set_slider_value(1, drag_coefficient)
		_panel.set_slider_value(2, wind_strength)
	_spawn_movers()


func _setup_auto_reset() -> void:
	_auto_reset_timer = Timer.new()
	_auto_reset_timer.wait_time = 25.0
	_auto_reset_timer.autostart = true
	_auto_reset_timer.timeout.connect(_reset_scene)
	add_child(_auto_reset_timer)


# ── Grid config ────────────────────────────────────────────────────────

func apply_grid_config(config: Dictionary) -> void:
	if config.has("gravity_strength"):
		gravity_strength = float(config["gravity_strength"])
	if config.has("wind_strength"):
		wind_strength = float(config["wind_strength"])
	if config.has("drag_coefficient"):
		drag_coefficient = float(config["drag_coefficient"])
	if config.has("wind_enabled"):
		wind_enabled = bool(config["wind_enabled"])
	if config.has("mode"):
		var m: String = str(config["mode"]).to_lower()
		_mode = Mode.ORBITAL if m == "orbital" else Mode.FORCES
	if config.has("central_mass"):
		central_mass = float(config["central_mass"])
	if config.has("orbital_g"):
		orbital_G = float(config["orbital_g"])

	if _panel:
		_panel.set_slider_value(0, gravity_strength)
		_panel.set_slider_value(1, drag_coefficient)
		_panel.set_slider_value(2, wind_strength)
	_spawn_movers()


# ── Cleanup ────────────────────────────────────────────────────────────

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
