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

# ── Preloads ─────────────────────────────────────────────────────────
const SliderScene = preload("res://commons/interactables/slider_horizontal.tscn")
const ButtonScene = preload("res://commons/interactables/push_button.tscn")

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
	mat_s.no_depth_test = true
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
	var x0 := -0.9
	var y0 := -0.3
	var sp := 0.35

	# Mode button
	_mode_button = ButtonScene.instantiate()
	_mode_button.position = Vector3(x0, y0 - 0.15, 0)
	add_child(_mode_button)
	var btn_area = _mode_button.get_node_or_null("InteractableAreaButton")
	if btn_area:
		btn_area.button_pressed.connect(_cycle_mode)
	var btn_label = _mode_button.get_node_or_null("Frame/LabelName")
	if btn_label:
		btn_label.text = "Mode"

	# Stiffness slider
	_slider_stiffness = SliderScene.instantiate()
	_slider_stiffness.position = Vector3(x0 + sp, y0, 0)
	_slider_stiffness.scale = Vector3(0.3, 0.3, 0.3)
	add_child(_slider_stiffness)
	_slider_stiffness.set_param_name("Stiffness")
	_slider_stiffness.set_normalized_value(_stiffness)
	_slider_stiffness.slider_moved.connect(_on_stiffness_changed)

	# Pressure slider
	_slider_pressure = SliderScene.instantiate()
	_slider_pressure.position = Vector3(x0 + sp * 2, y0, 0)
	_slider_pressure.scale = Vector3(0.3, 0.3, 0.3)
	add_child(_slider_pressure)
	_slider_pressure.set_param_name("Pressure")
	_slider_pressure.set_normalized_value(remap(_pressure, -1.0, 2.0, 0.0, 1.0))
	_slider_pressure.slider_moved.connect(_on_pressure_changed)

	# Squeeze strength slider
	_slider_squeeze = SliderScene.instantiate()
	_slider_squeeze.position = Vector3(x0 + sp * 3, y0, 0)
	_slider_squeeze.scale = Vector3(0.3, 0.3, 0.3)
	add_child(_slider_squeeze)
	_slider_squeeze.set_param_name("Squeeze")
	_slider_squeeze.set_normalized_value(remap(_squeeze_strength, 0.0, 5.0, 0.0, 1.0))
	_slider_squeeze.slider_moved.connect(_on_squeeze_changed)


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
			_label_title.text = "Strain Energy"
		Mode.COLLISION:
			_label_title.text = "Collision Forces"
		Mode.VOLUME:
			_label_title.text = "Volume Preservation"
			_volume_history.clear()


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
	_update_labels()

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
	if _volume_history.size() < 2 or _rest_volume <= 0.0001:
		return

	# Draw chart to the right of the body
	var chart_origin := Vector3(0.8, 0.3, 0)
	var chart_w := 0.6
	var chart_h := 0.4

	_volume_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Chart background frame
	_im_line_3d(_volume_im, chart_origin, chart_origin + Vector3(chart_w, 0, 0), COL_GRID)
	_im_line_3d(_volume_im, chart_origin, chart_origin + Vector3(0, chart_h, 0), COL_GRID)

	# Target line at 100%
	var target_y := chart_origin.y + chart_h * 0.5
	_im_line_3d(_volume_im,
		Vector3(chart_origin.x, target_y, 0),
		Vector3(chart_origin.x + chart_w, target_y, 0),
		COL_VOLUME_OK)

	# Plot volume history
	var n := _volume_history.size()
	for i in range(1, n):
		var x0 := chart_origin.x + (float(i - 1) / float(VOLUME_HISTORY_SIZE)) * chart_w
		var x1 := chart_origin.x + (float(i) / float(VOLUME_HISTORY_SIZE)) * chart_w

		var r0 := _volume_history[i - 1] / maxf(_rest_volume, 0.0001)
		var r1 := _volume_history[i] / maxf(_rest_volume, 0.0001)

		var y0 := chart_origin.y + clampf(r0 * 0.5, 0.0, 1.0) * chart_h
		var y1 := chart_origin.y + clampf(r1 * 0.5, 0.0, 1.0) * chart_h

		var deviation := absf(r1 - _volume_target_ratio)
		var col := COL_VOLUME_OK if deviation < 0.05 else (COL_VOLUME_WARN if deviation < 0.15 else COL_VOLUME_BAD)
		_im_line_3d(_volume_im, Vector3(x0, y0, 0), Vector3(x1, y1, 0), col)

	_volume_im.surface_end()


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


# ── Label updates ────────────────────────────────────────────────────

func _update_labels() -> void:
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
