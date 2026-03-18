# ===========================================================================
# NOC Example 2.6: Single Attractor (Elevated)
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# Elevated version with:
#   - Escape velocity visualization (threshold ring + mover state coloring)
#   - Roche limit and tidal force stretching
#   - Multi-body gravitational interactions between movers
#   - VR slider controls and apply_grid_config()
#
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 2.6: Single Attractor (Elevated)
## Gravitational attraction with escape velocity, Roche limit, and multi-body interactions

# --- Mode ---
enum Mode { SINGLE, MULTI_BODY }
var _mode: int = Mode.SINGLE

# --- Physics parameters ---
const DEFAULT_GRAVITY := 0.6
const DEFAULT_ATTRACTOR_MASS := 4.0
var attractor_strength: float = DEFAULT_GRAVITY
var attractor_mass: float = DEFAULT_ATTRACTOR_MASS
var multi_body_enabled: bool = false

# --- Movers ---
var _movers: Array = []
var _mover_trails: Dictionary = {}
var _mover_colors: Dictionary = {}
const MAX_TRAIL_LENGTH := 150
const MOVER_CONFIGS := [
	{ "mass": 0.6, "pos": Vector3(-0.25, 0.0, 0.15), "vel": Vector3(0.0, 0.0, 0.30), "color": Color(0.95, 0.55, 0.85) },
	{ "mass": 1.0, "pos": Vector3(0.22, 0.0, -0.10), "vel": Vector3(0.0, 0.0, -0.25), "color": Color(0.65, 0.75, 0.95) },
	{ "mass": 1.5, "pos": Vector3(-0.10, 0.0, -0.28), "vel": Vector3(0.20, 0.0, 0.0), "color": Color(0.55, 0.95, 0.75) },
	{ "mass": 2.2, "pos": Vector3(0.30, 0.0, 0.20), "vel": Vector3(-0.18, 0.0, 0.0), "color": Color(0.95, 0.75, 0.45) },
	{ "mass": 0.8, "pos": Vector3(0.0, 0.0, 0.35), "vel": Vector3(-0.28, 0.0, 0.0), "color": Color(0.75, 0.55, 0.95) },
]

# --- Attractor ---
const ATTRACTOR_SCENE := preload("res://commons/primitives/point/grab_sphere_point_with_color.tscn")
var _attractor_anchor: Node3D
var _attractor_position: Vector3 = Vector3.ZERO

# --- Visuals ---
var _trail_mesh_inst: MeshInstance3D
var _escape_mesh_inst: MeshInstance3D
var _roche_mesh_inst: MeshInstance3D
var _tidal_mesh_inst: MeshInstance3D
var _field_mesh_inst: MeshInstance3D
var _mat_unshaded: StandardMaterial3D

# --- Escape velocity ---
const ESCAPE_RING_SEGMENTS := 64
var _escape_radius_display: float = 0.0

# --- Roche limit ---
# Roche limit ≈ r_attractor * (2 * M_attractor / M_mover)^(1/3)
# We use a simplified visual radius
const ROCHE_BASE_FACTOR := 0.08
var _roche_radius: float = 0.12

# --- Force field grid ---
const FIELD_GRID_SIZE := 7
const FIELD_SPACING := 0.1
const ARROW_SCALE := 0.12
const ARROW_HEAD_FRAC := 0.3

# --- UI ---
var _panel: ForcesRackPanel
var _gravity_slider: Node3D
var _mass_slider: Node3D
var _mode_readout: Label3D
var _energy_readout: Label3D
var _escape_readout: Label3D
var _roche_readout: Label3D

# --- Auto reset ---
var _auto_reset_timer: Timer


func _ready() -> void:
	scale = Vector3(0.8, 0.8, 0.8)
	_create_materials()
	_create_visual_nodes()
	_create_attractor()
	_create_panel()
	_spawn_movers()
	_setup_auto_reset()


func _process(delta: float) -> void:
	# Update attractor position from grabbable
	if is_instance_valid(_attractor_anchor):
		_attractor_position = _attractor_anchor.global_position

	_step_physics(delta)
	_draw_trails()
	_draw_escape_ring()
	_draw_roche_limit()
	_draw_tidal_forces()
	if _mode == Mode.MULTI_BODY:
		_draw_force_field()
	_update_readouts()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_TAB:
				_toggle_mode()
			KEY_SPACE:
				_scatter_movers()
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
	_trail_mesh_inst = MeshInstance3D.new()
	_trail_mesh_inst.name = "TrailMesh"
	_trail_mesh_inst.material_override = _mat_unshaded
	add_child(_trail_mesh_inst)

	_escape_mesh_inst = MeshInstance3D.new()
	_escape_mesh_inst.name = "EscapeRingMesh"
	_escape_mesh_inst.material_override = _mat_unshaded
	add_child(_escape_mesh_inst)

	_roche_mesh_inst = MeshInstance3D.new()
	_roche_mesh_inst.name = "RocheLimitMesh"
	_roche_mesh_inst.material_override = _mat_unshaded
	add_child(_roche_mesh_inst)

	_tidal_mesh_inst = MeshInstance3D.new()
	_tidal_mesh_inst.name = "TidalForceMesh"
	_tidal_mesh_inst.material_override = _mat_unshaded
	add_child(_tidal_mesh_inst)

	_field_mesh_inst = MeshInstance3D.new()
	_field_mesh_inst.name = "ForceFieldMesh"
	_field_mesh_inst.material_override = _mat_unshaded
	add_child(_field_mesh_inst)


func _create_attractor() -> void:
	_attractor_anchor = ATTRACTOR_SCENE.instantiate()
	_attractor_anchor.name = "Attractor"
	_attractor_anchor.position = _attractor_position
	add_child(_attractor_anchor)


# ── Panel / UI ─────────────────────────────────────────────────────────

func _create_panel() -> void:
	_panel = ForcesRackPanel.new()
	_panel.setup("2.6  Single Attractor", 2, 5)
	_panel.set_instructions("[TAB] Mode  [SPACE] Scatter  [R] Reset")

	_gravity_slider = _panel.add_slider("Gravity", 0.1, 1.5, attractor_strength, 0.05)
	_gravity_slider.slider_moved.connect(func(_n): attractor_strength = _panel.get_slider_value(0))

	_mass_slider = _panel.add_slider("Att. Mass", 1.0, 10.0, attractor_mass, 0.2)
	_mass_slider.slider_moved.connect(func(_n): attractor_mass = _panel.get_slider_value(1))

	_mode_readout = _panel.add_readout("Mode", "SINGLE")
	_energy_readout = _panel.add_readout("Energy", "--")
	_escape_readout = _panel.add_readout("V_esc", "--")
	_roche_readout = _panel.add_readout("Roche", "--")

	_panel.position = Vector3(-0.55, 0.35, 0.15)
	_panel.rotation_degrees = Vector3(0, 30, 0)
	add_child(_panel)


func _update_readouts() -> void:
	if not _panel:
		return
	_panel.update_readout("Mode", "MULTI-BODY" if _mode == Mode.MULTI_BODY else "SINGLE")

	if _movers.size() > 0 and is_instance_valid(_movers[0]):
		var mover: Mover = _movers[0]
		var r: float = (_attractor_position - mover.global_position).length()
		r = max(r, 0.01)

		# Specific orbital energy: E = ½v² - GM/r
		var ke: float = 0.5 * mover.velocity.length_squared()
		var pe: float = -(attractor_strength * attractor_mass) / r
		var total_e: float = ke + pe
		var sign_str: String = "+" if total_e >= 0 else ""
		_panel.update_readout("Energy", "%s%.2f" % [sign_str, total_e])

		# Escape velocity at this radius: v_esc = sqrt(2GM/r)
		var v_esc: float = sqrt(2.0 * attractor_strength * attractor_mass / r)
		_panel.update_readout("V_esc", "%.2f" % v_esc)

	_panel.update_readout("Roche", "%.3f" % _roche_radius)


# ── Movers ─────────────────────────────────────────────────────────────

func _spawn_movers() -> void:
	_clear_movers()
	var count: int = MOVER_CONFIGS.size() if _mode == Mode.MULTI_BODY else 4

	for i in range(count):
		var cfg: Dictionary = MOVER_CONFIGS[i]
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
		_mover_colors[mover] = cfg["color"]


func _clear_movers() -> void:
	for m in _movers:
		if is_instance_valid(m):
			m.queue_free()
	_movers.clear()
	_mover_trails.clear()
	_mover_colors.clear()


# ── Physics ────────────────────────────────────────────────────────────

func _step_physics(_delta: float) -> void:
	# Update Roche limit radius
	_roche_radius = ROCHE_BASE_FACTOR * pow(2.0 * attractor_mass, 1.0 / 3.0)

	for i in range(_movers.size()):
		var mover: Mover = _movers[i]
		if not is_instance_valid(mover):
			continue

		# --- Central attractor force ---
		var to_attractor: Vector3 = _attractor_position - mover.global_position
		var dist: float = to_attractor.length()
		dist = clamp(dist, 0.04, 1.0)
		var dir: Vector3 = to_attractor.normalized()
		var strength: float = (attractor_strength * attractor_mass * mover.mass) / (dist * dist)
		mover.apply_force(dir * strength)

		# --- Tidal disruption near Roche limit ---
		var raw_dist: float = to_attractor.length()
		if raw_dist < _roche_radius * 1.5 and raw_dist > 0.01:
			# Tidal force ~ differential gravity = 2GMmr / d³
			var tidal_mag: float = 2.0 * attractor_strength * attractor_mass * mover.mass * 0.02 / (raw_dist * raw_dist * raw_dist)
			tidal_mag = min(tidal_mag, 0.5)
			# Apply perpendicular stretching force
			var perp: Vector3
			if abs(dir.dot(Vector3.UP)) < 0.95:
				perp = dir.cross(Vector3.UP).normalized()
			else:
				perp = dir.cross(Vector3.RIGHT).normalized()
			# Oscillating tidal disruption
			var tidal_dir: float = sin(Time.get_ticks_msec() * 0.005 + float(i) * 1.5)
			mover.apply_force(perp * tidal_mag * tidal_dir)

		# --- Multi-body interactions ---
		if _mode == Mode.MULTI_BODY:
			for j in range(_movers.size()):
				if i == j:
					continue
				var other: Mover = _movers[j]
				if not is_instance_valid(other):
					continue
				var to_other: Vector3 = other.global_position - mover.global_position
				var d: float = to_other.length()
				d = clamp(d, 0.03, 0.8)
				var d_norm: Vector3 = to_other.normalized()
				# Mutual gravitational attraction (scaled down)
				var mutual_str: float = (attractor_strength * 0.3 * mover.mass * other.mass) / (d * d)
				mover.apply_force(d_norm * mutual_str)

		# --- Color movers by orbital energy state ---
		_update_mover_visual(mover, i)

		# Record trail
		var trail: Array = _mover_trails.get(mover, [])
		trail.append(Vector3(mover.position_v))
		if trail.size() > MAX_TRAIL_LENGTH:
			trail.pop_front()
		_mover_trails[mover] = trail


func _update_mover_visual(mover: Mover, index: int) -> void:
	var to_att: Vector3 = _attractor_position - mover.global_position
	var r: float = to_att.length()
	r = max(r, 0.01)

	# Specific orbital energy: E/m = ½v² - GM/r
	var v_sq: float = mover.velocity.length_squared()
	var specific_energy: float = 0.5 * v_sq - (attractor_strength * attractor_mass) / r

	var base_color: Color = _mover_colors.get(mover, Color(0.8, 0.6, 0.9))

	if specific_energy >= 0:
		# Escaping — shift toward warm red/orange
		var escape_frac: float = clamp(specific_energy * 2.0, 0.0, 1.0)
		var escape_color := Color(0.95, 0.3 + 0.2 * (1.0 - escape_frac), 0.15)
		mover.set_color(base_color.lerp(escape_color, 0.4 + 0.4 * escape_frac))
	else:
		# Bound — keep base color with slight blue tint for deep orbits
		var bound_depth: float = clamp(-specific_energy * 1.5, 0.0, 1.0)
		var bound_color := Color(0.3, 0.5, 0.95)
		mover.set_color(base_color.lerp(bound_color, bound_depth * 0.3))


# ── Escape velocity ring (ImmediateMesh) ──────────────────────────────

func _draw_escape_ring() -> void:
	var im := ImmediateMesh.new()

	# Draw escape velocity threshold circles at reference radii
	var ref_radii := [0.1, 0.2, 0.35]
	for radius in ref_radii:
		var v_esc: float = sqrt(2.0 * attractor_strength * attractor_mass / radius)
		# Map escape velocity to ring brightness
		var intensity: float = clamp(v_esc * 0.5, 0.1, 1.0)
		var col := Color(0.95, 0.55, 0.25, 0.12 + 0.15 * intensity)

		im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for seg in range(ESCAPE_RING_SEGMENTS + 1):
			var angle: float = float(seg) / float(ESCAPE_RING_SEGMENTS) * TAU
			var pt := _attractor_position + Vector3(cos(angle) * radius, 0, sin(angle) * radius)
			im.surface_set_color(col)
			im.surface_add_vertex(pt)
		im.surface_end()

		# Label the v_esc value with small tick marks
		var label_angle: float = PI * 0.25
		var label_pt := _attractor_position + Vector3(cos(label_angle) * radius, 0, sin(label_angle) * radius)
		var tick_end := label_pt + Vector3(0, 0.02, 0)
		im.surface_begin(Mesh.PRIMITIVE_LINES)
		im.surface_set_color(Color(0.95, 0.55, 0.25, 0.3))
		im.surface_add_vertex(label_pt)
		im.surface_set_color(Color(0.95, 0.55, 0.25, 0.3))
		im.surface_add_vertex(tick_end)
		im.surface_end()

	# Draw per-mover escape velocity indicators (radial line showing v vs v_esc)
	for mover in _movers:
		if not is_instance_valid(mover):
			continue
		var to_att: Vector3 = _attractor_position - mover.global_position
		var r: float = to_att.length()
		r = max(r, 0.01)
		var v_esc: float = sqrt(2.0 * attractor_strength * attractor_mass / r)
		var v_current: float = mover.velocity.length()
		var ratio: float = clamp(v_current / max(v_esc, 0.01), 0.0, 2.0)

		# Small bar above mover: green=bound, yellow=near escape, red=escaping
		var bar_color: Color
		if ratio < 0.7:
			bar_color = Color(0.3, 0.85, 0.5, 0.6)
		elif ratio < 1.0:
			bar_color = Color(0.95, 0.85, 0.25, 0.7)
		else:
			bar_color = Color(0.95, 0.3, 0.15, 0.8)

		var mover_pos: Vector3 = mover.global_position
		var bar_base: Vector3 = mover_pos + Vector3(0, 0.04, 0)
		var bar_len: float = clamp(ratio * 0.03, 0.005, 0.06)

		im.surface_begin(Mesh.PRIMITIVE_LINES)
		im.surface_set_color(bar_color)
		im.surface_add_vertex(bar_base)
		im.surface_set_color(bar_color)
		im.surface_add_vertex(bar_base + Vector3(bar_len, 0, 0))
		im.surface_end()

		# Threshold tick at v/v_esc = 1.0
		var tick_x: float = clamp(1.0 / max(ratio, 0.01) * bar_len, 0.0, 0.06)
		if ratio > 0.3:
			im.surface_begin(Mesh.PRIMITIVE_LINES)
			im.surface_set_color(Color(1, 1, 1, 0.5))
			im.surface_add_vertex(bar_base + Vector3(min(0.03, tick_x), -0.003, 0))
			im.surface_set_color(Color(1, 1, 1, 0.5))
			im.surface_add_vertex(bar_base + Vector3(min(0.03, tick_x), 0.003, 0))
			im.surface_end()

	_escape_mesh_inst.mesh = im


# ── Roche limit visualization ─────────────────────────────────────────

func _draw_roche_limit() -> void:
	var im := ImmediateMesh.new()

	# Draw Roche limit as a dashed circle
	var dash_segments := 32
	for seg in range(dash_segments):
		if seg % 2 == 1:
			continue  # Skip every other segment for dashed effect
		var angle_start: float = float(seg) / float(dash_segments) * TAU
		var angle_end: float = float(seg + 1) / float(dash_segments) * TAU

		im.surface_begin(Mesh.PRIMITIVE_LINES)
		im.surface_set_color(Color(0.95, 0.25, 0.25, 0.35))
		im.surface_add_vertex(_attractor_position + Vector3(cos(angle_start) * _roche_radius, 0, sin(angle_start) * _roche_radius))
		im.surface_set_color(Color(0.95, 0.25, 0.25, 0.35))
		im.surface_add_vertex(_attractor_position + Vector3(cos(angle_end) * _roche_radius, 0, sin(angle_end) * _roche_radius))
		im.surface_end()

	# Second ring slightly above for depth
	for seg in range(dash_segments):
		if seg % 2 == 0:
			continue
		var angle_start: float = float(seg) / float(dash_segments) * TAU
		var angle_end: float = float(seg + 1) / float(dash_segments) * TAU

		im.surface_begin(Mesh.PRIMITIVE_LINES)
		im.surface_set_color(Color(0.95, 0.25, 0.25, 0.2))
		im.surface_add_vertex(_attractor_position + Vector3(cos(angle_start) * _roche_radius, 0.01, sin(angle_start) * _roche_radius))
		im.surface_set_color(Color(0.95, 0.25, 0.25, 0.2))
		im.surface_add_vertex(_attractor_position + Vector3(cos(angle_end) * _roche_radius, 0.01, sin(angle_end) * _roche_radius))
		im.surface_end()

	_roche_mesh_inst.mesh = im


# ── Tidal force visualization ─────────────────────────────────────────

func _draw_tidal_forces() -> void:
	var im := ImmediateMesh.new()

	for mover in _movers:
		if not is_instance_valid(mover):
			continue
		var to_att: Vector3 = _attractor_position - mover.global_position
		var raw_dist: float = to_att.length()
		if raw_dist < 0.01 or raw_dist > _roche_radius * 2.5:
			continue

		var dir: Vector3 = to_att.normalized()
		# Tidal stretch factor increases as 1/r³
		var tidal_factor: float = clamp(attractor_mass * 0.01 / (raw_dist * raw_dist * raw_dist), 0.0, 0.8)
		if tidal_factor < 0.02:
			continue

		# Draw stretching arrows perpendicular to radial direction
		var perp: Vector3
		if abs(dir.dot(Vector3.UP)) < 0.95:
			perp = dir.cross(Vector3.UP).normalized()
		else:
			perp = dir.cross(Vector3.RIGHT).normalized()

		var mover_pos: Vector3 = mover.global_position
		var stretch_len: float = tidal_factor * 0.15
		var alpha: float = clamp(tidal_factor * 2.0, 0.1, 0.7)
		var col := Color(0.95, 0.35, 0.25, alpha)

		# Outward stretch arrows (two directions)
		for sign_val in [-1.0, 1.0]:
			var arrow_start: Vector3 = mover_pos + perp * sign_val * 0.02
			var arrow_end: Vector3 = mover_pos + perp * sign_val * (0.02 + stretch_len)
			im.surface_begin(Mesh.PRIMITIVE_LINES)
			im.surface_set_color(col)
			im.surface_add_vertex(arrow_start)
			im.surface_set_color(col)
			im.surface_add_vertex(arrow_end)
			im.surface_end()

			# Small arrowhead
			var head_back: Vector3 = arrow_end - perp * sign_val * stretch_len * 0.25
			var head_perp: Vector3 = dir * stretch_len * 0.15
			im.surface_begin(Mesh.PRIMITIVE_LINES)
			im.surface_set_color(col)
			im.surface_add_vertex(arrow_end)
			im.surface_set_color(col)
			im.surface_add_vertex(head_back + head_perp)
			im.surface_end()
			im.surface_begin(Mesh.PRIMITIVE_LINES)
			im.surface_set_color(col)
			im.surface_add_vertex(arrow_end)
			im.surface_set_color(col)
			im.surface_add_vertex(head_back - head_perp)
			im.surface_end()

		# Compression arrows along radial direction
		var compress_len: float = stretch_len * 0.5
		var comp_col := Color(0.25, 0.55, 0.95, alpha * 0.7)
		for sign_val in [-1.0, 1.0]:
			var arrow_start: Vector3 = mover_pos + dir * sign_val * (0.02 + compress_len)
			var arrow_end: Vector3 = mover_pos + dir * sign_val * 0.02
			im.surface_begin(Mesh.PRIMITIVE_LINES)
			im.surface_set_color(comp_col)
			im.surface_add_vertex(arrow_start)
			im.surface_set_color(comp_col)
			im.surface_add_vertex(arrow_end)
			im.surface_end()

	_tidal_mesh_inst.mesh = im


# ── Force field arrows (multi-body mode) ──────────────────────────────

func _draw_force_field() -> void:
	var im := ImmediateMesh.new()
	var half: float = (FIELD_GRID_SIZE - 1) * FIELD_SPACING * 0.5

	for xi in range(FIELD_GRID_SIZE):
		for zi in range(FIELD_GRID_SIZE):
			var gx: float = xi * FIELD_SPACING - half
			var gz: float = zi * FIELD_SPACING - half
			var origin := Vector3(gx, 0, gz)

			# Central attractor contribution
			var to_att: Vector3 = _attractor_position - origin
			var d_att: float = to_att.length()
			if d_att < 0.05:
				continue
			d_att = clamp(d_att, 0.05, 1.0)
			var force: Vector3 = to_att.normalized() * (attractor_strength * attractor_mass) / (d_att * d_att)

			# Add mover contributions
			for mover in _movers:
				if not is_instance_valid(mover):
					continue
				var to_m: Vector3 = mover.global_position - origin
				var d_m: float = to_m.length()
				if d_m < 0.03:
					continue
				d_m = clamp(d_m, 0.03, 0.8)
				force += to_m.normalized() * (attractor_strength * 0.3 * mover.mass) / (d_m * d_m)

			var intensity: float = clamp(force.length() * 0.3, 0.1, 1.0)
			var col := Color(0.45, 0.65, 0.95, 0.15 + 0.2 * intensity)
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

	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_set_color(color)
	im.surface_add_vertex(origin)
	im.surface_set_color(color)
	im.surface_add_vertex(head_start)
	im.surface_end()

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

		var base_color: Color = _mover_colors.get(mover, Color(0.8, 0.6, 0.9))
		im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for i in range(trail.size()):
			var alpha: float = float(i) / float(trail.size()) * 0.6
			im.surface_set_color(Color(base_color.r, base_color.g, base_color.b, alpha))
			im.surface_add_vertex(trail[i])
		im.surface_end()

	_trail_mesh_inst.mesh = im


# ── Mode toggle ────────────────────────────────────────────────────────

func _toggle_mode() -> void:
	_mode = Mode.MULTI_BODY if _mode == Mode.SINGLE else Mode.SINGLE
	_spawn_movers()


# ── Scatter / Reset ────────────────────────────────────────────────────

func _scatter_movers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for mover in _movers:
		if not is_instance_valid(mover):
			continue
		mover.velocity += Vector3(
			rng.randf_range(-0.2, 0.2),
			rng.randf_range(-0.05, 0.05),
			rng.randf_range(-0.2, 0.2)
		)


func _reset_scene() -> void:
	attractor_strength = DEFAULT_GRAVITY
	attractor_mass = DEFAULT_ATTRACTOR_MASS
	if _panel:
		_panel.set_slider_value(0, attractor_strength)
		_panel.set_slider_value(1, attractor_mass)
	_spawn_movers()


func _setup_auto_reset() -> void:
	_auto_reset_timer = Timer.new()
	_auto_reset_timer.wait_time = 25.0
	_auto_reset_timer.autostart = true
	_auto_reset_timer.timeout.connect(_reset_scene)
	add_child(_auto_reset_timer)


# ── Grid config ────────────────────────────────────────────────────────

func apply_grid_config(config: Dictionary) -> void:
	if config.has("attractor_strength"):
		attractor_strength = float(config["attractor_strength"])
	if config.has("gravity"):
		attractor_strength = float(config["gravity"])
	if config.has("attractor_mass"):
		attractor_mass = float(config["attractor_mass"])
	if config.has("mode"):
		var m: String = str(config["mode"]).to_lower()
		_mode = Mode.MULTI_BODY if m == "multi_body" or m == "multi" else Mode.SINGLE
	if config.has("multi_body_enabled"):
		if bool(config["multi_body_enabled"]):
			_mode = Mode.MULTI_BODY

	if _panel:
		_panel.set_slider_value(0, attractor_strength)
		_panel.set_slider_value(1, attractor_mass)
	_spawn_movers()


# ── Cleanup ────────────────────────────────────────────────────────────

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
