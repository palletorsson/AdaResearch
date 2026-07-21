# ===========================================================================
# Rounded SoftBody — Strain Energy Visualization
#
# Elevated: 3 modes (STRAIN / COLLISION / VOLUME), ImmediateMesh
# force arrows and strain heatmap overlay, volume preservation
# constraints with real-time tracking, VR hand squeeze interaction.
# ===========================================================================

extends Node3D

# @identity
# essence: SoftBody3D rounded cube with per-vertex strain energy E = 0.5 * k * displacement^2 computed every frame, displayed as a blue-green-red heatmap overlay
# desire: to let you squeeze a soft body with your VR hand and see the stress field bloom red under your grip — making internal forces visible and tangible
# critical_parameter: _stiffness — governs the spring constant k in the strain equation; low stiffness means large deformation for small force, high stiffness means the body barely yields
# triggers: VR grip_click activates hand squeeze mode, pushing vertices away from hand center; mode button cycles through STRAIN, COLLISION, and VOLUME visualization
# emerges: in VOLUME mode, the pressure_coefficient auto-adjusts to preserve volume — squeeze one side and the other side bulges out, revealing conservation of volume as an emergent constraint
# needs: slider_horizontal [has] (stiffness, pressure, squeeze); push_button [has] (mode cycle); Label3D [has]
# relationships: deepens jelly_cube's deformation intro with quantitative strain visualization; three modes correspond to three aspects of continuum mechanics
# truth: strain is not damage — it is the body's memory of every force that has touched it, written in the displacement of every vertex from its rest position

## Rounded SoftBody — Strain Energy Visualization
## Deformable rounded cube with stress coloring, collision forces, and volume tracking

# ── Modes ────────────────────────────────────────────────────────────
enum Mode { STRAIN, COLLISION, VOLUME }

const MODE_NAMES := ["Strain Energy", "Collision Forces", "Volume Preservation"]

# ── Cabinet grammar (HORIZONTAL dialect) ─────────────────────────────
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

@export var show_cabinet: bool = true
@export var finish: String = "rams"
@export var wear: float = 0.10
@export var unit_code: String = "RS-01"
## How far the bench legs reach BELOW the deck plane. The grid's auto-grounding
## lifts the assembly by exactly this, so the deck arrives at working height.
@export var bench_drop: float = 0.84
## The G3 datum. The working surface IS the artifact's own origin plane — the
## specimen already lives above it — so the bench hangs below and not one
## authored physics coordinate moves. probe_cabinet_grammar reads this property
## by name; without it the rule silently falls back to 0.85 and never bites.
@export var deck_height: float = 0.0
## RESCUE FLAG, off by default — see _seat_specimen_on_deck().
@export var seat_specimen: bool = false

# Controls built via RackTemplates
var _rack_panel: Node3D

# ── Bench (housing) ──────────────────────────────────────────────────
var _bench: Node3D = null
var _readout_anchor: Node3D = null
var _readout_node: Node3D = null
var _readout_size := Vector2(0.52, 0.105)
var _readout_last := ""
var _readout_accum := 0.0
var _mode_header := "STRAIN ENERGY"

# Volume strip-chart geometry — free-standing defaults, overridden by the bench
# builder which routes the chart FLAT into the deck.
var _chart_origin := Vector3(0.8, 0.3, 0.0)
var _chart_w := 0.6
var _chart_h := 0.4
var _chart_flat := false

# ── Colors ───────────────────────────────────────────────────────────
const COL_LOW_STRAIN := Color(0.15, 0.55, 0.95)     # blue — relaxed
const COL_MID_STRAIN := Color(0.2, 0.85, 0.4)       # green — moderate
const COL_HIGH_STRAIN := Color(0.95, 0.25, 0.15)    # red — high stress
const COL_FORCE_ARROW := Color(1.0, 0.85, 0.2, 0.9) # yellow force arrows
const COL_COLLISION := Color(1.0, 0.3, 0.6, 0.8)    # pink collision flash
const COL_VOLUME_OK := Color(0.3, 0.9, 0.5, 0.6)    # green — volume preserved
const COL_VOLUME_WARN := Color(0.95, 0.7, 0.1, 0.6) # amber — volume drifting
const COL_VOLUME_BAD := Color(0.95, 0.2, 0.2, 0.6)  # red — volume lost
const COL_GRID := Color(0.4, 0.4, 0.5, 0.3)
const COL_HAND := Color(0.6, 0.4, 1.0, 0.5)         # purple hand sphere
const COL_REST_GHOST := Color(0.5, 0.5, 0.6, 0.15)  # faint rest shape

# ── Soft body parameters ─────────────────────────────────────────────
var _mode: int = Mode.STRAIN
var _size := 0.6
var _radius := 0.08
var _segments := 5
var _stiffness := 0.5
var _pressure := 0.3
var _damping := 0.01
var _mass := 1.0

# ── Simulation state ────────────────────────────────────────────────
var _soft_body: SoftBody3D
var _rest_positions: PackedVector3Array   # vertex positions at rest
var _prev_positions: PackedVector3Array   # previous frame for velocity
var _vertex_count := 0
var _rest_volume := 0.0
var _current_volume := 0.0
var _volume_history: Array[float] = []
const VOLUME_HISTORY_SIZE := 120

# ── Strain data ──────────────────────────────────────────────────────
var _vertex_strain: PackedFloat32Array    # per-vertex strain energy
var _max_strain := 0.001                  # running max for normalization
var _total_strain := 0.0

# ── Collision data ───────────────────────────────────────────────────
var _collision_forces: Array[Dictionary] = []  # {pos, dir, magnitude}
const MAX_COLLISION_DISPLAY := 24
var _collision_decay: Array[float] = []

# ── Volume preservation ─────────────────────────────────────────────
var _volume_correction_strength := 0.3
var _volume_target_ratio := 1.0

# ── VR hand squeeze ─────────────────────────────────────────────────
var _vr_controller: XRController3D = null
var _hand_active := false
var _hand_pos := Vector3.ZERO
var _squeeze_radius := 0.25
var _squeeze_strength := 2.0

# ── Visual nodes ─────────────────────────────────────────────────────
var _strain_im: ImmediateMesh       # strain heatmap overlay on body
var _strain_mi: MeshInstance3D
var _force_im: ImmediateMesh        # force arrows / collision vectors
var _force_mi: MeshInstance3D
var _volume_im: ImmediateMesh       # volume chart / wireframe
var _volume_mi: MeshInstance3D
var _ghost_im: ImmediateMesh        # rest shape ghost
var _ghost_mi: MeshInstance3D
var _hand_mesh: MeshInstance3D      # hand interaction sphere

# ── Labels ───────────────────────────────────────────────────────────
var _label_title: Label3D
var _label_info: Label3D
var _label_detail: Label3D

# ── Controls ─────────────────────────────────────────────────────────
var _mode_button = null
var _slider_stiffness = null
var _slider_pressure = null
var _slider_squeeze = null

# ── Timing ───────────────────────────────────────────────────────────
var _time := 0.0


func _ready() -> void:
	_find_vr_controller()
	_create_soft_body()
	_create_mesh_instances()
	_create_hand_visual()
	_create_labels()
	_create_controls()
	_init_mode()
	# LAST: the bench re-homes the keypad and the live figures onto itself.
	# _capture_rest_state() awaits two process frames, so the deck collider
	# built here exists well before the specimen's rest state is recorded.
	_create_bench()


# ── VR controller detection ─────────────────────────────────────────

func _find_vr_controller() -> void:
	var node := get_parent()
	while node:
		if node is XRController3D:
			_vr_controller = node as XRController3D
			return
		node = node.get_parent()


# ── Soft body creation ───────────────────────────────────────────────

func _create_soft_body() -> void:
	_soft_body = SoftBody3D.new()
	_soft_body.ray_pickable = false
	_soft_body.simulation_precision = 10
	_soft_body.collision_layer = 1
	_soft_body.collision_mask = 1
	_soft_body.linear_stiffness = _stiffness
	_soft_body.pressure_coefficient = _pressure
	_soft_body.damping_coefficient = _damping
	_soft_body.total_mass = _mass
	_soft_body.position = Vector3(0, 0.5, 0)
	add_child(_soft_body)

	_build_rounded_cube_mesh()
	_capture_rest_state()


func _build_rounded_cube_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half := _size * 0.5
	var r := clampf(_radius, 0.0, half * 0.49)
	var divs := _segments
	var gs := divs * 2 + 1

	var vgrid := {}
	var vi := 0

	for xi in range(gs):
		for yi in range(gs):
			for zi in range(gs):
				var on_surface := (xi == 0 or xi == gs - 1 or
								   yi == 0 or yi == gs - 1 or
								   zi == 0 or zi == gs - 1)
				if not on_surface:
					continue

				var x := (float(xi) / float(gs - 1)) * 2.0 - 1.0
				var y := (float(yi) / float(gs - 1)) * 2.0 - 1.0
				var z := (float(zi) / float(gs - 1)) * 2.0 - 1.0

				var pos := Vector3(x, y, z) * half
				var rpos := _apply_rounding(pos, half, r)

				st.set_uv(Vector2(x * 0.5 + 0.5, y * 0.5 + 0.5))
				st.add_vertex(rpos)

				vgrid[Vector3i(xi, yi, zi)] = vi
				vi += 1

	var add_quad := func(i: int, j: int, get_coords: Callable) -> void:
		var c0: Variant = get_coords.call(i, j)
		var c1: Variant = get_coords.call(i + 1, j)
		var c2: Variant = get_coords.call(i + 1, j + 1)
		var c3: Variant = get_coords.call(i, j + 1)
		if vgrid.has(c0) and vgrid.has(c1) and vgrid.has(c2) and vgrid.has(c3):
			var v0: int = vgrid[c0]
			var v1: int = vgrid[c1]
			var v2: int = vgrid[c2]
			var v3: int = vgrid[c3]
			st.add_index(v0); st.add_index(v1); st.add_index(v2)
			st.add_index(v0); st.add_index(v2); st.add_index(v3)

	var n := divs * 2
	for i in range(n):
		for j in range(n):
			add_quad.call(i, j, func(u, v): return Vector3i(u, v, gs - 1))          # +Z
			add_quad.call(i, j, func(u, v): return Vector3i(gs - 1 - u, v, 0))      # -Z
			add_quad.call(i, j, func(u, v): return Vector3i(u, gs - 1, v))           # +Y
			add_quad.call(i, j, func(u, v): return Vector3i(u, 0, gs - 1 - v))      # -Y
			add_quad.call(i, j, func(u, v): return Vector3i(gs - 1, v, gs - 1 - u)) # +X
			add_quad.call(i, j, func(u, v): return Vector3i(0, v, u))                # -X

	st.generate_normals()
	var new_mesh := st.commit()
	_soft_body.mesh = new_mesh

	# Apply to physics
	if _soft_body.is_inside_tree():
		var rid := _soft_body.get_physics_rid()
		if rid.is_valid():
			PhysicsServer3D.soft_body_set_mesh(rid, new_mesh)

	# Unshaded vertex-color material for strain visualization
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COL_LOW_STRAIN
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	_soft_body.material_override = mat


func _capture_rest_state() -> void:
	# Need to wait one frame for physics to initialize
	await get_tree().process_frame
	await get_tree().process_frame

	var rid := _soft_body.get_physics_rid()
	if not rid.is_valid():
		return

	if seat_specimen and show_cabinet:
		_seat_specimen_on_deck()

	_vertex_count = _soft_body.get_point_count()
	_rest_positions.resize(_vertex_count)
	_prev_positions.resize(_vertex_count)
	_vertex_strain.resize(_vertex_count)

	for i in range(_vertex_count):
		var p: Vector3 = _soft_body.get_point_global_position(i)
		_rest_positions[i] = p - _soft_body.global_position
		_prev_positions[i] = p
		_vertex_strain[i] = 0.0

	_rest_volume = _compute_volume()
	_current_volume = _rest_volume
	_volume_history.clear()


func _apply_rounding(pos: Vector3, half_size: float, r: float) -> Vector3:
	var x_sign := signf(pos.x) if pos.x != 0 else 1.0
	var y_sign := signf(pos.y) if pos.y != 0 else 1.0
	var z_sign := signf(pos.z) if pos.z != 0 else 1.0

	var ax := absf(pos.x)
	var ay := absf(pos.y)
	var az := absf(pos.z)
	var inner := half_size - r

	var cx := clampf(ax, 0, inner)
	var cy := clampf(ay, 0, inner)
	var cz := clampf(az, 0, inner)

	var dx := ax - inner
	var dy := ay - inner
	var dz := az - inner

	if dx > 0 or dy > 0 or dz > 0:
		dx = maxf(dx, 0)
		dy = maxf(dy, 0)
		dz = maxf(dz, 0)
		var dist := sqrt(dx * dx + dy * dy + dz * dz)
		if dist > 0:
			var s := minf(dist, r) / dist
			dx *= s
			dy *= s
			dz *= s

	return Vector3(x_sign * (cx + dx), y_sign * (cy + dy), z_sign * (cz + dz))


# ── Mesh instances ───────────────────────────────────────────────────

func _create_mesh_instances() -> void:
	# Strain overlay
	_strain_im = ImmediateMesh.new()
	_strain_mi = MeshInstance3D.new()
	_strain_mi.mesh = _strain_im
	var mat_s := StandardMaterial3D.new()
	mat_s.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_s.vertex_color_use_as_albedo = true
	mat_s.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Depth-test ONLY in bare mode. With a bench under the specimen the strain
	# diamonds would otherwise draw straight through the platen and the rails.
	mat_s.no_depth_test = not show_cabinet
	_strain_mi.material_override = mat_s
	add_child(_strain_mi)

	# Force arrows
	_force_im = ImmediateMesh.new()
	_force_mi = MeshInstance3D.new()
	_force_mi.mesh = _force_im
	var mat_f := StandardMaterial3D.new()
	mat_f.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_f.vertex_color_use_as_albedo = true
	mat_f.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_force_mi.material_override = mat_f
	add_child(_force_mi)

	# Volume chart
	_volume_im = ImmediateMesh.new()
	_volume_mi = MeshInstance3D.new()
	_volume_mi.mesh = _volume_im
	var mat_v := StandardMaterial3D.new()
	mat_v.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_v.vertex_color_use_as_albedo = true
	mat_v.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_volume_mi.material_override = mat_v
	add_child(_volume_mi)

	# Rest shape ghost
	_ghost_im = ImmediateMesh.new()
	_ghost_mi = MeshInstance3D.new()
	_ghost_mi.mesh = _ghost_im
	var mat_g := StandardMaterial3D.new()
	mat_g.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_g.vertex_color_use_as_albedo = true
	mat_g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_mi.material_override = mat_g
	add_child(_ghost_mi)


func _create_hand_visual() -> void:
	_hand_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = _squeeze_radius * 0.5
	sphere.height = _squeeze_radius
	sphere.radial_segments = 12
	sphere.rings = 6
	_hand_mesh.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = COL_HAND
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.3, 0.9)
	mat.emission_energy_multiplier = 1.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_hand_mesh.material_override = mat
	_hand_mesh.visible = false
	add_child(_hand_mesh)


# ── Labels ───────────────────────────────────────────────────────────

func _create_labels() -> void:
	# BARE MODE ONLY. With the bench, the far-rail readout carries the live
	# figures and the near-rail inlay carries the name — these three billboards
	# hanging at y = 1.25 … 1.60 are exactly the orphan text the cabinet
	# grammar exists to retire (G1).
	if show_cabinet:
		return

	_label_title = Label3D.new()
	_label_title.font_size = 48
	_label_title.position = Vector3(0, 1.6, 0)
	_label_title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_title.outline_size = 8
	add_child(_label_title)

	_label_info = Label3D.new()
	_label_info.font_size = 32
	_label_info.position = Vector3(0, 1.4, 0)
	_label_info.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_info.outline_size = 6
	add_child(_label_info)

	_label_detail = Label3D.new()
	_label_detail.font_size = 24
	_label_detail.position = Vector3(0, 1.25, 0)
	_label_detail.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_detail.outline_size = 4
	add_child(_label_detail)


# ── Controls ─────────────────────────────────────────────────────────

func _create_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	# HORIZONTAL dialect: the milled pocket in the near rail IS the faceplate,
	# so the pad is FRAMELESS and its title goes empty — the rail inlay owns
	# the name. Bare mode keeps the old framed panel exactly as it was.
	var pad_title: String = "" if show_cabinet else "SOFT BODY"
	_rack_panel = RackTpl.create_panel(pad_title, [
		[
			{"type": "slider_h", "label": "STIFFNESS", "default": -1.0},
			{"type": "slider_h", "label": "PRESSURE", "default": -1.0},
			{"type": "slider_h", "label": "SQUEEZE", "default": -1.0},
		],
		[
			{"type": "button", "label": "MODE"},
		],
	], show_cabinet)
	# Bare placement — hanging off the front-left corner BELOW the origin.
	# _create_bench() re-homes it flush into the near rail.
	_rack_panel.position = Vector3(-0.5, -0.3, 0.3)
	_rack_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_rack_panel)

	# Extract slider references
	_slider_stiffness = _rack_panel.find_child("Param_0", true, false)
	_slider_pressure = _rack_panel.find_child("Param_1", true, false)
	_slider_squeeze = _rack_panel.find_child("Param_2", true, false)

	# Set initial values
	if _slider_stiffness and _slider_stiffness.has_method("set_normalized_value"):
		_slider_stiffness.set_normalized_value(_stiffness)
	if _slider_pressure and _slider_pressure.has_method("set_normalized_value"):
		_slider_pressure.set_normalized_value(remap(_pressure, -1.0, 2.0, 0.0, 1.0))
	if _slider_squeeze and _slider_squeeze.has_method("set_normalized_value"):
		_slider_squeeze.set_normalized_value(remap(_squeeze_strength, 0.0, 5.0, 0.0, 1.0))

	# Connect slider signals
	if _slider_stiffness and _slider_stiffness.has_signal("slider_moved"):
		_slider_stiffness.slider_moved.connect(_on_stiffness_changed)
	if _slider_pressure and _slider_pressure.has_signal("slider_moved"):
		_slider_pressure.slider_moved.connect(_on_pressure_changed)
	if _slider_squeeze and _slider_squeeze.has_signal("slider_moved"):
		_slider_squeeze.slider_moved.connect(_on_squeeze_changed)

	# Mode button
	_mode_button = _rack_panel.find_child("Btn_0", true, false)
	if _mode_button:
		var btn_area = _mode_button.get_node_or_null("InteractableAreaButton")
		if btn_area:
			btn_area.button_pressed.connect(func(_b): _cycle_mode())


func _cycle_mode() -> void:
	_mode = (_mode + 1) % 3
	_init_mode()


func _on_stiffness_changed(_name: String, value: float) -> void:
	_stiffness = clampf(value, 0.01, 1.0)
	_soft_body.linear_stiffness = _stiffness


func _on_pressure_changed(_name: String, value: float) -> void:
	_pressure = remap(value, 0.0, 1.0, -1.0, 2.0)
	_soft_body.pressure_coefficient = _pressure


func _on_squeeze_changed(_name: String, value: float) -> void:
	_squeeze_strength = remap(value, 0.0, 1.0, 0.0, 5.0)


# ── Mode initialization ─────────────────────────────────────────────

func _init_mode() -> void:
	_collision_forces.clear()
	_collision_decay.clear()
	_max_strain = 0.001
	match _mode:
		Mode.STRAIN:
			_mode_header = "STRAIN ENERGY"
		Mode.COLLISION:
			_mode_header = "COLLISION FORCES"
		Mode.VOLUME:
			_mode_header = "VOLUME PRESERVATION"
			_volume_history.clear()

	# The mode name used to be a billboard overhead; it is now the HEADER strip
	# of the readout sunk in the far rail. The Label3D survives in bare mode.
	if _label_title != null and is_instance_valid(_label_title):
		_label_title.text = str(MODE_NAMES[_mode])

	# Force the next refresh through the throttle so the header changes at once.
	_readout_last = ""
	_readout_accum = 99.0


# ── Process loop ─────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _vertex_count == 0:
		return

	_time += delta

	_update_vr_hand(delta)
	_compute_strain()
	_detect_collisions(delta)
	_compute_current_volume()

	if _mode == Mode.VOLUME:
		_apply_volume_correction()

	_draw_all()
	_refresh_readout(delta)

	# Store previous positions
	var rid := _soft_body.get_physics_rid()
	if rid.is_valid():
		for i in range(_vertex_count):
			_prev_positions[i] = _soft_body.get_point_global_position(i)


# ── VR hand interaction ──────────────────────────────────────────────

func _update_vr_hand(_delta: float) -> void:
	if _vr_controller:
		_hand_active = _vr_controller.is_button_pressed("grip_click")
		if _hand_active:
			_hand_pos = _vr_controller.global_position
	else:
		# Desktop fallback: use a slowly orbiting squeeze point
		_hand_active = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if _hand_active:
			var orbit_r := 0.3
			_hand_pos = _soft_body.global_position + Vector3(
				cos(_time * 0.8) * orbit_r,
				sin(_time * 1.2) * 0.15,
				sin(_time * 0.8) * orbit_r
			)

	_hand_mesh.visible = _hand_active
	if _hand_active:
		_hand_mesh.global_position = _hand_pos
		_apply_squeeze()


func _apply_squeeze() -> void:
	var rid := _soft_body.get_physics_rid()
	if not rid.is_valid():
		return

	for i in range(_vertex_count):
		var vpos: Vector3 = _soft_body.get_point_global_position(i)
		var to_hand: Vector3 = _hand_pos - vpos
		var dist: float = to_hand.length()
		if dist < _squeeze_radius and dist > 0.001:
			# Push vertices away from hand center (squeeze effect)
			var push_dir: Vector3 = -to_hand.normalized()
			var strength: float = _squeeze_strength * (1.0 - dist / _squeeze_radius)
			var push: Vector3 = push_dir * strength * 0.016  # frame-rate independent approx
			PhysicsServer3D.soft_body_move_point(rid, i, vpos + push)


# ── Strain computation ───────────────────────────────────────────────

func _compute_strain() -> void:
	var rid := _soft_body.get_physics_rid()
	if not rid.is_valid():
		return

	_total_strain = 0.0
	var sb_origin := _soft_body.global_position

	for i in range(_vertex_count):
		var current: Vector3 = _soft_body.get_point_global_position(i)
		var rest: Vector3 = _rest_positions[i] + sb_origin
		var displacement: float = (current - rest).length()

		# Strain energy ~ 0.5 * k * displacement^2
		var energy: float = 0.5 * _stiffness * displacement * displacement
		_vertex_strain[i] = energy
		_total_strain += energy

		if energy > _max_strain:
			_max_strain = energy

	# Slowly decay max for normalization
	_max_strain *= 0.999


# ── Collision detection (approximate) ────────────────────────────────

func _detect_collisions(delta: float) -> void:
	var rid := _soft_body.get_physics_rid()
	if not rid.is_valid():
		return

	# Decay existing collision markers
	var i := 0
	while i < _collision_decay.size():
		_collision_decay[i] -= delta * 2.0
		if _collision_decay[i] <= 0:
			_collision_forces.remove_at(i)
			_collision_decay.remove_at(i)
		else:
			i += 1

	# Detect large velocity changes as collision proxies
	for vi in range(_vertex_count):
		var current: Vector3 = _soft_body.get_point_global_position(vi)
		var prev: Variant = _prev_positions[vi]
		var vel: Vector3 = (current - prev) / maxf(delta, 0.001)
		var speed: float = vel.length()

		if speed > 1.5 and _collision_forces.size() < MAX_COLLISION_DISPLAY:
			_collision_forces.append({
				"pos": current,
				"dir": vel.normalized(),
				"magnitude": clampf(speed / 5.0, 0.1, 1.0)
			})
			_collision_decay.append(1.0)


# ── Volume computation ───────────────────────────────────────────────

func _compute_volume() -> float:
	# Approximate volume via bounding box of deformed vertices
	var rid := _soft_body.get_physics_rid()
	if not rid.is_valid() or _vertex_count == 0:
		return 0.0

	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)

	for i in range(_vertex_count):
		var p: Vector3 = _soft_body.get_point_global_position(i)
		mn = mn.min(p)
		mx = mx.max(p)

	var extents: Vector3 = mx - mn
	return extents.x * extents.y * extents.z


func _compute_current_volume() -> void:
	_current_volume = _compute_volume()
	_volume_history.append(_current_volume)
	if _volume_history.size() > VOLUME_HISTORY_SIZE:
		_volume_history.remove_at(0)


func _apply_volume_correction() -> void:
	if _rest_volume <= 0.0001:
		return

	var ratio := _current_volume / maxf(_rest_volume, 0.0001)
	if absf(ratio - _volume_target_ratio) < 0.02:
		return  # close enough

	# Adjust pressure to compensate
	var error := _volume_target_ratio - ratio
	_soft_body.pressure_coefficient += error * _volume_correction_strength * 0.016


# ── Drawing ──────────────────────────────────────────────────────────

func _draw_all() -> void:
	_strain_im.clear_surfaces()
	_force_im.clear_surfaces()
	_volume_im.clear_surfaces()
	_ghost_im.clear_surfaces()

	match _mode:
		Mode.STRAIN:
			_draw_strain_overlay()
			_draw_rest_ghost()
		Mode.COLLISION:
			_draw_collision_forces()
			_draw_strain_overlay()
		Mode.VOLUME:
			_draw_volume_chart()
			_draw_volume_wireframe()

	if _hand_active:
		_draw_squeeze_field()


func _draw_strain_overlay() -> void:
	if _vertex_count == 0:
		return

	var rid := _soft_body.get_physics_rid()
	if not rid.is_valid():
		return

	_strain_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Draw small diamond at each vertex colored by strain
	for i in range(_vertex_count):
		var p: Vector3 = _soft_body.get_point_global_position(i)
		var t: float = clampf(_vertex_strain[i] / maxf(_max_strain, 0.001), 0.0, 1.0)
		var col: Color = _strain_color(t)
		var sz := 0.008 + t * 0.012
		_im_diamond(_strain_im, p, sz, col)

	_strain_im.surface_end()


func _strain_color(t: float) -> Color:
	if t < 0.5:
		return COL_LOW_STRAIN.lerp(COL_MID_STRAIN, t * 2.0)
	return COL_MID_STRAIN.lerp(COL_HIGH_STRAIN, (t - 0.5) * 2.0)


func _draw_rest_ghost() -> void:
	if _vertex_count == 0:
		return

	var sb_origin := _soft_body.global_position
	_ghost_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Sample every few vertices to keep it light
	var step := maxi(_vertex_count / 40, 1)
	for i in range(0, _vertex_count, step):
		var rest_p := _rest_positions[i] + sb_origin
		_im_diamond(_ghost_im, rest_p, 0.006, COL_REST_GHOST)

	_ghost_im.surface_end()


func _draw_collision_forces() -> void:
	if _collision_forces.is_empty():
		return

	_force_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(_collision_forces.size()):
		var cf: Dictionary = _collision_forces[i]
		var alpha := _collision_decay[i]
		var col := COL_COLLISION
		col.a *= alpha

		var arrow_len: float = 0.1 * cf["magnitude"]
		_im_arrow_3d(_force_im, cf["pos"], cf["dir"], arrow_len, col)

		# Impact burst diamond
		var burst_col := COL_FORCE_ARROW
		burst_col.a *= alpha
		_im_diamond(_force_im, cf["pos"], 0.015 * cf["magnitude"], burst_col)

	_force_im.surface_end()


func _draw_volume_chart() -> void:
	if _rest_volume <= 0.0001:
		return

	_volume_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Frame + the 100% target line, drawn even before there is history, so the
	# routed deck channel reads as a live instrument and not an empty slot.
	_im_line_3d(_volume_im, _chart_pt(0.0, 0.0), _chart_pt(_chart_w, 0.0), COL_GRID)
	_im_line_3d(_volume_im, _chart_pt(0.0, 0.0), _chart_pt(0.0, _chart_h), COL_GRID)
	_im_line_3d(_volume_im,
		_chart_pt(0.0, _chart_h * 0.5),
		_chart_pt(_chart_w, _chart_h * 0.5),
		COL_VOLUME_OK)

	# Plot volume history
	var n := _volume_history.size()
	for i in range(1, n):
		var x0: float = (float(i - 1) / float(VOLUME_HISTORY_SIZE)) * _chart_w
		var x1: float = (float(i) / float(VOLUME_HISTORY_SIZE)) * _chart_w

		var r0: float = _volume_history[i - 1] / maxf(_rest_volume, 0.0001)
		var r1: float = _volume_history[i] / maxf(_rest_volume, 0.0001)

		var y0: float = clampf(r0 * 0.5, 0.0, 1.0) * _chart_h
		var y1: float = clampf(r1 * 0.5, 0.0, 1.0) * _chart_h

		var deviation: float = absf(r1 - _volume_target_ratio)
		var col: Color = COL_VOLUME_OK if deviation < 0.05 else (COL_VOLUME_WARN if deviation < 0.15 else COL_VOLUME_BAD)
		_im_line_3d(_volume_im, _chart_pt(x0, y0), _chart_pt(x1, y1), col)

	_volume_im.surface_end()


## One chart point in the artifact's LOCAL space. `u` runs the time axis, `v`
## the value axis. On the bench the strip chart is ROUTED FLAT INTO THE DECK,
## so the value axis lies in the deck plane (+Z, growing toward the reader)
## instead of standing up in +Y beside the body.
func _chart_pt(u: float, v: float) -> Vector3:
	if _chart_flat:
		return _chart_origin + Vector3(u, 0.0, v)
	return _chart_origin + Vector3(u, v, 0.0)


func _draw_volume_wireframe() -> void:
	# Draw current bounding box of deformed body
	var rid := _soft_body.get_physics_rid()
	if not rid.is_valid() or _vertex_count == 0:
		return

	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	for i in range(_vertex_count):
		var p: Vector3 = _soft_body.get_point_global_position(i)
		mn = mn.min(p)
		mx = mx.max(p)

	var ratio: float = _current_volume / maxf(_rest_volume, 0.0001)
	var deviation: float = absf(ratio - _volume_target_ratio)
	var col := COL_VOLUME_OK if deviation < 0.05 else (COL_VOLUME_WARN if deviation < 0.15 else COL_VOLUME_BAD)

	_ghost_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# 12 edges of bounding box
	var corners := [
		Vector3(mn.x, mn.y, mn.z), Vector3(mx.x, mn.y, mn.z),
		Vector3(mx.x, mx.y, mn.z), Vector3(mn.x, mx.y, mn.z),
		Vector3(mn.x, mn.y, mx.z), Vector3(mx.x, mn.y, mx.z),
		Vector3(mx.x, mx.y, mx.z), Vector3(mn.x, mx.y, mx.z),
	]
	var edges := [[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]]
	for e in edges:
		_im_line_3d(_ghost_im, corners[e[0]], corners[e[1]], col)

	_ghost_im.surface_end()


func _draw_squeeze_field() -> void:
	# Draw radial lines around hand position showing squeeze influence
	_force_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var ring_count := 8
	for i in range(ring_count):
		var angle := float(i) / float(ring_count) * TAU
		var dir := Vector3(cos(angle), 0, sin(angle))
		var start := _hand_pos + dir * _squeeze_radius * 0.15
		var end := _hand_pos + dir * _squeeze_radius * 0.5
		var col := COL_HAND
		col.a = 0.4
		_im_line_3d(_force_im, start, end, col)

	_force_im.surface_end()


# ── Readout / label updates ──────────────────────────────────────────

## The live figures. On the bench they are the body lines of the framed
## instrument screen sunk in the far rail; in bare mode they fall back to the
## old billboards. Baked text is fixed at build time and these floats move every
## frame, so the screen is rebuilt at most 5x a second — rebuilding at 90 Hz
## would tank the map.
func _refresh_readout(delta: float) -> void:
	if _readout_anchor == null or not is_instance_valid(_readout_anchor):
		_update_labels()
		return

	_readout_accum += delta
	if _readout_accum < 0.20:
		return
	_readout_accum = 0.0

	var lines: Array = []
	match _mode:
		Mode.STRAIN:
			lines.append("TOTAL %.4f" % _total_strain)
			lines.append("PEAK  %.4f" % _max_strain)
			lines.append("VERTS %d   K %.2f" % [_vertex_count, _stiffness])
			if _hand_active:
				lines.append("SQUEEZING")
		Mode.COLLISION:
			lines.append("EVENTS %d" % _collision_forces.size())
			lines.append("K %.2f   P %.2f" % [_stiffness, _pressure])
			lines.append("VERTS %d" % _vertex_count)
		Mode.VOLUME:
			var ratio: float = _current_volume / maxf(_rest_volume, 0.0001)
			lines.append("VOL  %.1f%%" % (ratio * 100.0))
			lines.append("TGT  %.0f%%" % (_volume_target_ratio * 100.0))
			lines.append("CORR %.2f  P %.2f" % [
				_volume_correction_strength, _soft_body.pressure_coefficient])

	var joined: String = _mode_header
	for l in lines:
		joined += "\n" + str(l)
	if joined == _readout_last and _readout_node != null and is_instance_valid(_readout_node):
		return
	_readout_last = joined

	if _readout_node != null and is_instance_valid(_readout_node):
		_readout_node.queue_free()
		_readout_node = null

	var pal: Dictionary = HangarKit.finish_palette(finish)
	_readout_node = HangarKit.readout(_mode_header, lines, _readout_size,
		pal["screen"], pal["text"], pal["header"])
	if _readout_node != null:
		_readout_anchor.add_child(_readout_node)


func _update_labels() -> void:
	if _label_info == null or not is_instance_valid(_label_info):
		return
	match _mode:
		Mode.STRAIN:
			_label_info.text = "Total strain: %.4f  Max: %.4f" % [_total_strain, _max_strain]
			_label_detail.text = "Verts: %d  Stiffness: %.2f" % [_vertex_count, _stiffness]
			if _hand_active:
				_label_detail.text += "  [SQUEEZING]"
		Mode.COLLISION:
			_label_info.text = "Active collisions: %d" % _collision_forces.size()
			_label_detail.text = "Stiffness: %.2f  Pressure: %.2f" % [_stiffness, _pressure]
		Mode.VOLUME:
			var ratio := _current_volume / maxf(_rest_volume, 0.0001)
			_label_info.text = "Volume: %.1f%%  Target: %.0f%%" % [ratio * 100.0, _volume_target_ratio * 100.0]
			_label_detail.text = "Correction: %.2f  Pressure: %.2f" % [_volume_correction_strength, _soft_body.pressure_coefficient]


# ── ImmediateMesh helpers ────────────────────────────────────────────

func _im_diamond(im: ImmediateMesh, center: Vector3, sz: float, col: Color) -> void:
	var up := Vector3(0, sz, 0)
	var rt := Vector3(sz * 0.6, 0, 0)
	var fw := Vector3(0, 0, sz * 0.6)

	im.surface_set_color(col)
	# Top pyramid
	im.surface_set_normal(Vector3.UP)
	im.surface_add_vertex(center + up)
	im.surface_add_vertex(center + rt)
	im.surface_add_vertex(center + fw)

	im.surface_add_vertex(center + up)
	im.surface_add_vertex(center + fw)
	im.surface_add_vertex(center - rt)

	im.surface_add_vertex(center + up)
	im.surface_add_vertex(center - rt)
	im.surface_add_vertex(center - fw)

	im.surface_add_vertex(center + up)
	im.surface_add_vertex(center - fw)
	im.surface_add_vertex(center + rt)

	# Bottom pyramid
	im.surface_add_vertex(center - up)
	im.surface_add_vertex(center + fw)
	im.surface_add_vertex(center + rt)

	im.surface_add_vertex(center - up)
	im.surface_add_vertex(center - rt)
	im.surface_add_vertex(center + fw)

	im.surface_add_vertex(center - up)
	im.surface_add_vertex(center - fw)
	im.surface_add_vertex(center - rt)

	im.surface_add_vertex(center - up)
	im.surface_add_vertex(center + rt)
	im.surface_add_vertex(center - fw)


func _im_line_3d(im: ImmediateMesh, from: Vector3, to: Vector3, col: Color) -> void:
	var dir := (to - from)
	var length := dir.length()
	if length < 0.0001:
		return
	dir /= length

	var perp := Vector3.UP.cross(dir)
	if perp.length_squared() < 0.0001:
		perp = Vector3.RIGHT.cross(dir)
	perp = perp.normalized() * 0.003

	im.surface_set_color(col)
	im.surface_set_normal(Vector3.UP)
	im.surface_add_vertex(from - perp)
	im.surface_add_vertex(from + perp)
	im.surface_add_vertex(to + perp)

	im.surface_add_vertex(from - perp)
	im.surface_add_vertex(to + perp)
	im.surface_add_vertex(to - perp)


func _im_arrow_3d(im: ImmediateMesh, origin: Vector3, dir: Vector3, length: float, col: Color) -> void:
	var tip := origin + dir * length
	_im_line_3d(im, origin, tip, col)

	# Arrowhead
	var perp := Vector3.UP.cross(dir)
	if perp.length_squared() < 0.0001:
		perp = Vector3.RIGHT.cross(dir)
	perp = perp.normalized() * length * 0.25

	var head_base := origin + dir * length * 0.7
	im.surface_set_color(col)
	im.surface_set_normal(Vector3.UP)
	im.surface_add_vertex(tip)
	im.surface_add_vertex(head_base + perp)
	im.surface_add_vertex(head_base - perp)


# ═════════════════════════════════════════════════════════════════════
# THE COMPRESSION BENCH — cabinet grammar, HORIZONTAL dialect
# ═════════════════════════════════════════════════════════════════════
#
# THE PLANE PICKS THE BODY. This artifact's desire is "to let you squeeze a
# soft body with your VR hand and see the stress field bloom red under your
# grip". The vertical dialect's defining move is a WINDOW — a dark backdrop
# plus pale glass over the live phenomenon — and glass here would seal off the
# one thing the artifact exists for. So the plane is horizontal: the field is
# the deck itself, open to the hand from above, and the keypad is pressed
# DOWNWARD, which is the squeeze gesture.
#
# NOT the canon "table console". A card table is a play field things move
# ACROSS — thrown dice, felt, a rail as bumper. This is the opposite premise: a
# specimen held STILL under your hand and measured. The deck is a collider and
# a platen, the near rail is a wrist rest you lean on while pressing, and an
# inlaid strip-chart channel runs the volume trace flat in the far strip. A
# materials-test bench.
#
# THE FLOOR PLANE IS y = 0 (deck_height). The specimen already lives above the
# origin, so the deck surface IS the artifact's own origin plane and the bench
# hangs BELOW it, down to -bench_drop. Not one authored physics coordinate
# changes; auto-grounding lifts the whole assembly and the deck arrives at
# working height, putting the specimen's centre at ~1.15 m — hand height for a
# squeeze instead of the ~0.30 m knee height it used to settle at.
#
# Translation table applied (never transfer, always translate):
#   back slab             -> broad working RAIL ring around the deck
#   maroon flank (a mass) -> maroon EDGE INLAY LINE under the rail's top edge
#   inset window/screen   -> readout SUNK in the far rail, 14 deg off the deck
#   sign band overhead    -> name INLAID FLAT in the near rail, read looking down
#   keypad on a wedge     -> keypad recessed FLUSH in a milled pocket, face-up
#   vent slats on a back  -> vents in the APRON, seen from below
#   plinth + feet         -> apron + the furniture's own legs

func _create_bench() -> void:
	if not show_cabinet:
		return

	# Every dimension derives from the artifact's OWN variables, so the bench
	# fits the specimen and the hand that squeezes it.
	var reach: float = _size * 0.5 + _squeeze_radius       # how far the hand travels
	var deck_w: float = reach * 2.0 + 0.04                 # rail lands at full squeeze
	var platen_s: float = _size * 1.20                     # the specimen seat
	var strip_d: float = _size * 0.28                      # instrument strip, each side
	var deck_d: float = platen_s + strip_d * 2.0 + 0.04
	var rail_far: float = _size * 0.34                     # deeper: it carries the screen
	var rail_near: float = _size * 0.38                    # deeper still: you lean here
	var rail_side: float = _size * 0.18
	var rail_th: float = 0.055
	var rail_top: float = deck_height + 0.048
	var rail_y: float = rail_top - rail_th * 0.5
	var outer_w: float = deck_w + rail_side * 2.0
	var far_z: float = -(deck_d * 0.5 + rail_far * 0.5)
	var near_z: float = deck_d * 0.5 + rail_near * 0.5
	var z_out_far: float = -(deck_d * 0.5 + rail_far)
	var z_out_near: float = deck_d * 0.5 + rail_near
	var ring_cz: float = (z_out_far + z_out_near) * 0.5
	var ring_d: float = z_out_near - z_out_far

	_bench = Node3D.new()
	_bench.name = "CompressionBench"
	# The grammar probe scopes its rules by this meta (or the names Cabinet /
	# TableConsole) — without it nothing here is measured.
	_bench.set_meta("housing", true)
	add_child(_bench)

	# ── one word drives every colour ──
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_body: Color = pal["body"]
	var col_panel: Color = pal["panel"]
	var col_accent: Color = pal["accent"]
	var ew: float = float(pal["wear"]) if finish.to_lower() == "terminal" else wear
	var shell: StandardMaterial3D = HangarKit.finish_body(finish, col_body, ew)
	var deckmat: StandardMaterial3D = HangarKit.finish_body(finish, col_panel, ew)
	var dark: StandardMaterial3D = HangarKit.painted_metal(Color(0.09, 0.09, 0.105), ew, 0.4, 0.5)
	var maroon: StandardMaterial3D = HangarKit.painted_metal(Color(0.30, 0.11, 0.09), ew)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_panel)
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)

	# ── the working RAIL ring — the horizontal answer to the back slab ──
	# Warm off-white dominates the mass.
	_bench.add_child(HangarKit.box(Vector3(0.0, rail_y, far_z),
		Vector3(outer_w, rail_th, rail_far), shell))
	_bench.add_child(HangarKit.box(Vector3(0.0, rail_y, near_z),
		Vector3(outer_w, rail_th, rail_near), shell))
	for i in range(2):
		var sx: float = -1.0 if i == 0 else 1.0
		_bench.add_child(HangarKit.box(
			Vector3(sx * (deck_w * 0.5 + rail_side * 0.5), rail_y, 0.0),
			Vector3(rail_side, rail_th, deck_d), shell))

	# ── maroon as an EDGE INLAY LINE, not a band ──
	# The vertical flank is a MASS; laid flat on furniture the same mass becomes
	# a stripe of paint. On a bench the colour is stated by a line.
	var band_y: float = rail_top - 0.015
	var band_h: float = 0.009
	_bench.add_child(HangarKit.box(Vector3(0.0, band_y, z_out_far + 0.004),
		Vector3(outer_w, band_h, 0.008), maroon))
	_bench.add_child(HangarKit.box(Vector3(0.0, band_y, z_out_near - 0.004),
		Vector3(outer_w, band_h, 0.008), maroon))
	for i in range(2):
		var sx2: float = -1.0 if i == 0 else 1.0
		_bench.add_child(HangarKit.box(
			Vector3(sx2 * (outer_w * 0.5 - 0.004), band_y, ring_cz),
			Vector3(0.008, band_h, ring_d), maroon))

	# ── the ember line (G7) — one warm line, framing the field ──
	for i in range(2):
		var sz: float = -1.0 if i == 0 else 1.0
		_bench.add_child(HangarKit.box(
			Vector3(0.0, rail_top + 0.001, sz * (deck_d * 0.5 + 0.014)),
			Vector3(outer_w, 0.003, 0.006), accent))

	# ── deck slab, platen, and the colliders that make the housing REAL ──
	# The slab runs the full rail-ring footprint so the rails sit ON it instead
	# of floating over a shadow gap; its top face is the deck plane.
	_bench.add_child(HangarKit.box(Vector3(0.0, deck_height - 0.030, ring_cz),
		Vector3(outer_w, 0.060, ring_d), deckmat))
	# The near-black milled platen the specimen is pressed against. A pocket is
	# where near-black is allowed, and it gives the strain diamonds a ground.
	_bench.add_child(HangarKit.box(Vector3(0.0, deck_height + 0.006, 0.0),
		Vector3(platen_s, 0.014, platen_s), dark))
	# This is the whole argument for the horizontal dialect, made structural:
	# _soft_body spawns at y = 0.5 and FALLS. It used to fall past the artifact
	# onto the map floor; now it lands on the platen at hand height.
	_bench.add_child(HangarKit.box_collider(
		Vector3(platen_s, 0.060, platen_s),
		Vector3(0.0, deck_height + 0.013 - 0.030, 0.0)))
	_bench.add_child(HangarKit.box_collider(
		Vector3(outer_w, 0.060, ring_d),
		Vector3(0.0, deck_height - 0.030, ring_cz)))

	# ── the volume strip chart, ROUTED FLAT INTO THE DECK ──
	# It used to be a 2D graph hanging in mid-air off the +X side — the largest
	# floating element on the artifact. Now it is an inlaid instrument channel
	# in the far strip, directly beyond the readout, read by looking down.
	_chart_flat = true
	_chart_w = deck_w * 0.62
	_chart_h = strip_d
	_chart_origin = Vector3(-_chart_w * 0.5, deck_height + 0.003,
		-deck_d * 0.5 + 0.010)
	_bench.add_child(HangarKit.box(
		Vector3(0.0, deck_height - 0.004, -deck_d * 0.5 + 0.010 + _chart_h * 0.5),
		Vector3(_chart_w + 0.030, 0.010, _chart_h + 0.016), dark))

	# ── READOUT sunk into the FAR rail, 14 deg off the deck ──
	# Nearly flat: an inlaid instrument screen, read by looking down. Steeper
	# than this and it stands up like a monitor — the vertical dialect wearing
	# a table. The constants match dice_throw so the two horizontal bodies agree.
	var tilt: float = -76.0
	var norm := Vector3(0.0, 0.970, 0.242)        # screen face normal
	var loc_up := Vector3(0.0, 0.242, -0.970)     # screen local up, in world
	var scr_w: float = deck_w * 0.46
	var scr_h: float = 0.105
	var scr_c := Vector3(0.0, rail_top - 0.008, far_z)

	# G6: a dark pocket within 0.03 m behind the lit face — a screen without one
	# is a poster taped on.
	var pocket: MeshInstance3D = HangarKit.box(scr_c - norm * 0.010,
		Vector3(scr_w + 0.034, scr_h + 0.028, 0.014), dark)
	pocket.rotation_degrees = Vector3(tilt, 0.0, 0.0)
	_bench.add_child(pocket)

	var lip: MeshInstance3D = HangarKit.box(
		scr_c + loc_up * (scr_h * 0.5 + 0.005) + norm * 0.003,
		Vector3(scr_w + 0.030, 0.004, 0.005), accent)
	lip.rotation_degrees = Vector3(tilt, 0.0, 0.0)
	_bench.add_child(lip)

	_readout_anchor = Node3D.new()
	_readout_anchor.name = "BenchReadout"
	_readout_anchor.position = scr_c + norm * 0.004
	_readout_anchor.rotation_degrees = Vector3(tilt, 0.0, 0.0)
	_bench.add_child(_readout_anchor)
	_readout_size = Vector2(scr_w, scr_h)

	# ── NEAR rail: keypad recessed FLUSH in a milled pocket ──
	var pad_pocket: MeshInstance3D = HangarKit.box(
		Vector3(-deck_w * 0.28, rail_top + 0.008, deck_d * 0.5 + 0.100),
		Vector3(0.40, 0.175, 0.012), dark)
	pad_pocket.rotation_degrees = Vector3(-80.0, 0.0, 0.0)
	_bench.add_child(pad_pocket)
	if _rack_panel != null and is_instance_valid(_rack_panel):
		# 10 degrees off the deck, pressed downward — the squeeze gesture.
		_rack_panel.position = Vector3(-deck_w * 0.28, rail_top + 0.020,
			deck_d * 0.5 + 0.102)
		_rack_panel.rotation_degrees = Vector3(-80.0, 0.0, 0.0)
		_rack_panel.scale = Vector3(0.80, 0.80, 0.80)

	# ── the name INLAID FLAT in the near rail, read by looking down ──
	var name_tag: Node3D = BakedText.make_tag(
		"ROUNDED SOFTBODY", Color(0.93, 0.94, 0.97), 0.030,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if name_tag != null:
		name_tag.position = Vector3(deck_w * 0.24, rail_top + 0.002, near_z - 0.032)
		name_tag.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		_bench.add_child(name_tag)
	var name_sub: Node3D = BakedText.make_tag(
		"STRAIN ENERGY FIELD", Color(0.58, 0.50, 0.44), 0.013,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if name_sub != null:
		name_sub.position = Vector3(deck_w * 0.24, rail_top + 0.002, near_z + 0.008)
		name_sub.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		_bench.add_child(name_sub)

	# A machine carries an asset code, not only a title.
	var code: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.11, 0.028),
		col_accent.lightened(0.25))
	if code != null:
		code.position = Vector3(-outer_w * 0.5 + 0.075, rail_top + 0.002,
			near_z + 0.058)
		code.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		_bench.add_child(code)

	# ── APRON, vents seen from below, and a bolted near face ──
	_bench.add_child(HangarKit.box(Vector3(0.0, deck_height - 0.125, ring_cz),
		Vector3(outer_w - 0.09, 0.130, ring_d - 0.09), dark))
	for gi in range(5):
		_bench.add_child(HangarKit.box(
			Vector3(0.0, deck_height - 0.170 + float(gi) * 0.013,
				ring_cz + (ring_d - 0.09) * 0.5 + 0.002),
			Vector3(0.30, 0.007, 0.008), steel))
	_bench.add_child(HangarKit.bolts(
		Vector3(-outer_w * 0.5 + 0.10, rail_y, z_out_near - 0.006),
		Vector3(outer_w * 0.5 - 0.10, rail_y, z_out_near - 0.006),
		9, 0.008, steel))
	# No grime_band and no dust_streaks: the apron is already near-black, where
	# an opaque dirt shadow reads as a slab hanging under the bench, and the
	# legs are gapped posts a flat plate cannot lie across. Age comes from
	# `wear` on the materials plus the bolt row — the ruling dice_throw made.

	# ── LEGS and FEET: the furniture's own footing, never a second plinth ──
	var leg_h: float = maxf(bench_drop - 0.190, 0.10)
	for xi in range(2):
		var lx: float = (-1.0 if xi == 0 else 1.0) * (outer_w * 0.5 - 0.115)
		for zi in range(2):
			var lz: float = ring_cz + (-1.0 if zi == 0 else 1.0) * (ring_d * 0.5 - 0.115)
			_bench.add_child(HangarKit.box(
				Vector3(lx, deck_height - 0.190 - leg_h * 0.5, lz),
				Vector3(0.085, leg_h, 0.085), steel))
			_bench.add_child(HangarKit.box(
				Vector3(lx, deck_height - bench_drop + 0.011, lz),
				Vector3(0.115, 0.022, 0.115), dark))

	# Light the screen at once — _process bails until the soft body reports
	# vertices, and a capture taken before then would show a blank face.
	_refresh_readout(99.0)


## RESCUE FLAG, off by default (`seat_specimen`). SoftBody3D simulates in GLOBAL
## space. If the engine does not carry the simulated points when the grid's
## auto-grounding translates the artifact, the specimen falls past the bench to
## the map floor and ends up UNDER the deck. Flip this on only if the capture
## shows that: it lifts every point (never drops one) until the lowest rests on
## the platen, once, before the rest state is recorded.
func _seat_specimen_on_deck() -> void:
	var rid: RID = _soft_body.get_physics_rid()
	if not rid.is_valid():
		return
	var n: int = _soft_body.get_point_count()
	if n == 0:
		return
	var lowest: float = INF
	for i in range(n):
		lowest = minf(lowest, _soft_body.get_point_global_position(i).y)
	var platen_top: float = to_global(Vector3(0.0, deck_height + 0.013, 0.0)).y
	var lift: float = platen_top - lowest
	if lift <= 0.02 or lift > 5.0:
		return
	for i in range(n):
		var p: Vector3 = _soft_body.get_point_global_position(i)
		PhysicsServer3D.soft_body_move_point(rid, i, p + Vector3(0.0, lift, 0.0))


# ── Grid config ──────────────────────────────────────────────────────

func apply_grid_config(config: Dictionary) -> void:
	if config.has("mode"):
		var m := str(config["mode"]).to_upper()
		match m:
			"STRAIN": _mode = Mode.STRAIN
			"COLLISION": _mode = Mode.COLLISION
			"VOLUME": _mode = Mode.VOLUME

	if config.has("stiffness"):
		_stiffness = clampf(float(config["stiffness"]), 0.01, 1.0)
		_soft_body.linear_stiffness = _stiffness
		if _slider_stiffness:
			_slider_stiffness.set_normalized_value(_stiffness)

	if config.has("pressure"):
		_pressure = clampf(float(config["pressure"]), -1.0, 2.0)
		_soft_body.pressure_coefficient = _pressure
		if _slider_pressure:
			_slider_pressure.set_normalized_value(remap(_pressure, -1.0, 2.0, 0.0, 1.0))

	if config.has("damping"):
		_damping = clampf(float(config["damping"]), 0.0, 1.0)
		_soft_body.damping_coefficient = _damping

	if config.has("mass"):
		_mass = clampf(float(config["mass"]), 0.1, 20.0)
		_soft_body.total_mass = _mass

	if config.has("squeeze_strength"):
		_squeeze_strength = clampf(float(config["squeeze_strength"]), 0.0, 5.0)
		if _slider_squeeze:
			_slider_squeeze.set_normalized_value(remap(_squeeze_strength, 0.0, 5.0, 0.0, 1.0))

	if config.has("volume_correction"):
		_volume_correction_strength = clampf(float(config["volume_correction"]), 0.0, 1.0)

	if config.has("size"):
		_size = clampf(float(config["size"]), 0.2, 2.0)

	_init_mode()
