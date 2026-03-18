extends Node3D

## Fenwick Tree (Binary Indexed Tree) — Expressive VR 3D visualization
## Animated update propagation showing bit manipulation path, range query
## highlighting, VR hand interactive range selection with real-time sum,
## naive vs Fenwick timing comparison, and binary index decomposition.

@export var bounding_size: float = 0.8
@export var initial_array_size: int = 16

# ── Fenwick state ─────────────────────────────────────────────────────────
var _n: int = 16
var _original: PackedInt32Array          # 0-indexed source values
var _tree: PackedInt32Array              # 1-indexed BIT storage
var _time: float = 0.0

# ── Animation state ───────────────────────────────────────────────────────
# Update animation: walks the update path one hop at a time
var _anim_mode: int = 0                  # 0=idle, 1=update, 2=query
var _anim_step: int = 0                  # current hop in path
var _anim_timer: float = 0.0
var _anim_hop_dur: float = 0.4           # seconds per hop
var _anim_path: PackedInt32Array = PackedInt32Array()   # 1-indexed indices visited
var _anim_value: int = 0                 # delta being propagated (update) or running sum (query)
var _anim_running_sum: int = 0
var _anim_flash: float = 0.0            # 0→1 flash on completion

# Auto-demo timers
var _auto_timer: float = 0.0
var _auto_interval: float = 3.0
var _auto_mode: int = 0                  # 0=update, 1=query, alternates

# Range query selection (VR or auto)
var _query_left: int = 1
var _query_right: int = 8
var _query_result: int = 0
var _query_show: bool = false
var _query_path_left: PackedInt32Array = PackedInt32Array()
var _query_path_right: PackedInt32Array = PackedInt32Array()

# Timing comparison
var _naive_steps: int = 0
var _fenwick_steps: int = 0

# ── Meshes ────────────────────────────────────────────────────────────────
var _bar_mi: MeshInstance3D              # array bars
var _bar_im: ImmediateMesh
var _bar_mat: StandardMaterial3D

var _tree_mi: MeshInstance3D             # tree node bars (upper row)
var _tree_im: ImmediateMesh
var _tree_mat: StandardMaterial3D

var _conn_mi: MeshInstance3D             # responsibility arcs + propagation arrows
var _conn_im: ImmediateMesh
var _conn_mat: StandardMaterial3D

var _bits_mi: MeshInstance3D             # binary index bits
var _bits_im: ImmediateMesh
var _bits_mat: StandardMaterial3D

var _compare_mi: MeshInstance3D          # naive vs fenwick comparison bars
var _compare_im: ImmediateMesh
var _compare_mat: StandardMaterial3D

# ── Labels ────────────────────────────────────────────────────────────────
var _title_label: Label3D
var _metrics_label: Label3D
var _query_label: Label3D

# ── Controllers ───────────────────────────────────────────────────────────
var _size_ctrl: ParameterController3D
var _speed_ctrl: ParameterController3D
var _left_ctrl: ParameterController3D
var _right_ctrl: ParameterController3D


func _ready() -> void:
	_n = clampi(initial_array_size, 4, 32)
	_init_array()
	_build_fenwick()
	_setup_bar_mesh()
	_setup_tree_mesh()
	_setup_conn_mesh()
	_setup_bits_mesh()
	_setup_compare_mesh()
	_setup_labels()
	_setup_controllers()


# ── Fenwick core ──────────────────────────────────────────────────────────

func _init_array() -> void:
	_original.resize(_n)
	for i in range(_n):
		_original[i] = randi_range(1, 9)

func _build_fenwick() -> void:
	_tree.resize(_n + 1)
	for i in range(_n + 1):
		_tree[i] = 0
	for i in range(_n):
		_fenwick_update(i + 1, _original[i])

func _fenwick_update(idx: int, delta: int) -> void:
	while idx <= _n:
		_tree[idx] += delta
		idx += idx & (-idx)

func _fenwick_query(idx: int) -> int:
	var s: int = 0
	while idx > 0:
		s += _tree[idx]
		idx -= idx & (-idx)
	return s

func _get_update_path(idx: int) -> PackedInt32Array:
	var path := PackedInt32Array()
	while idx <= _n:
		path.append(idx)
		idx += idx & (-idx)
	return path

func _get_query_path(idx: int) -> PackedInt32Array:
	var path := PackedInt32Array()
	while idx > 0:
		path.append(idx)
		idx -= idx & (-idx)
	return path

func _responsibility_range(idx: int) -> Vector2i:
	## Returns [start, end] (1-indexed) of elements this tree node covers.
	var lsb := idx & (-idx)
	return Vector2i(idx - lsb + 1, idx)


# ── Mesh setup ────────────────────────────────────────────────────────────

func _make_unshaded_mat(base_color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = base_color * 0.3
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

func _make_mesh_pair(mat: StandardMaterial3D) -> Array:
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return [im, mi]

func _setup_bar_mesh() -> void:
	_bar_mat = _make_unshaded_mat(Color(0.3, 0.7, 1.0))
	var pair := _make_mesh_pair(_bar_mat)
	_bar_im = pair[0]; _bar_mi = pair[1]

func _setup_tree_mesh() -> void:
	_tree_mat = _make_unshaded_mat(Color(0.2, 1.0, 0.4))
	var pair := _make_mesh_pair(_tree_mat)
	_tree_im = pair[0]; _tree_mi = pair[1]

func _setup_conn_mesh() -> void:
	_conn_mat = _make_unshaded_mat(Color(1.0, 0.6, 0.2))
	_conn_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var pair := _make_mesh_pair(_conn_mat)
	_conn_im = pair[0]; _conn_mi = pair[1]

func _setup_bits_mesh() -> void:
	_bits_mat = _make_unshaded_mat(Color(0.9, 0.9, 0.3))
	var pair := _make_mesh_pair(_bits_mat)
	_bits_im = pair[0]; _bits_mi = pair[1]

func _setup_compare_mesh() -> void:
	_compare_mat = _make_unshaded_mat(Color(0.8, 0.3, 0.8))
	var pair := _make_mesh_pair(_compare_mat)
	_compare_im = pair[0]; _compare_mi = pair[1]


# ── Labels ────────────────────────────────────────────────────────────────

func _setup_labels() -> void:
	_title_label = _make_label(Vector3(0, bounding_size * 0.6, 0), 28)
	_title_label.text = "Fenwick Tree (Binary Indexed Tree)"

	_metrics_label = _make_label(Vector3(0, bounding_size * 0.52, 0), 20)
	_query_label = _make_label(Vector3(0, -bounding_size * 0.15, 0), 22)

func _make_label(pos: Vector3, font_sz: int) -> Label3D:
	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.font_size = font_sz
	lbl.modulate = Color(0.95, 0.95, 0.97, 1.0)
	lbl.outline_size = 4
	lbl.position = pos
	add_child(lbl)
	return lbl


# ── Controllers ───────────────────────────────────────────────────────────

func _setup_controllers() -> void:
	var y_base: float = -bounding_size * 0.35
	var x_start: float = -bounding_size * 0.38

	_size_ctrl = _make_ctrl("Array size", 4.0, 32.0, float(_n), 1.0)
	_size_ctrl.position = Vector3(x_start, y_base, 0)
	_size_ctrl.value_changed.connect(_on_size_changed)

	_speed_ctrl = _make_ctrl("Anim speed", 0.1, 1.0, _anim_hop_dur, 0.05)
	_speed_ctrl.position = Vector3(x_start + 0.35, y_base, 0)
	_speed_ctrl.value_changed.connect(_on_speed_changed)

	_left_ctrl = _make_ctrl("Query L", 1.0, float(_n), float(_query_left), 1.0)
	_left_ctrl.position = Vector3(x_start, y_base - 0.1, 0)
	_left_ctrl.value_changed.connect(_on_left_changed)

	_right_ctrl = _make_ctrl("Query R", 1.0, float(_n), float(_query_right), 1.0)
	_right_ctrl.position = Vector3(x_start + 0.35, y_base - 0.1, 0)
	_right_ctrl.value_changed.connect(_on_right_changed)

func _make_ctrl(pname: String, mn: float, mx: float, def: float, step: float) -> ParameterController3D:
	var ctrl := ParameterController3D.new()
	ctrl.parameter_name = pname
	ctrl.min_value = mn
	ctrl.max_value = mx
	ctrl.default_value = def
	ctrl.step_size = step
	add_child(ctrl)
	return ctrl

func _on_size_changed(val: float) -> void:
	var new_n := clampi(int(val), 4, 32)
	if new_n != _n:
		_n = new_n
		_init_array()
		_build_fenwick()
		_reset_anim()
		_left_ctrl.max_value = float(_n)
		_right_ctrl.max_value = float(_n)
		_query_left = clampi(_query_left, 1, _n)
		_query_right = clampi(_query_right, 1, _n)

func _on_speed_changed(val: float) -> void:
	_anim_hop_dur = clampf(val, 0.1, 1.0)

func _on_left_changed(val: float) -> void:
	_query_left = clampi(int(val), 1, _n)
	if _query_left > _query_right:
		_query_right = _query_left
	_start_query_anim()

func _on_right_changed(val: float) -> void:
	_query_right = clampi(int(val), 1, _n)
	if _query_right < _query_left:
		_query_left = _query_right
	_start_query_anim()

func _sync_controllers() -> void:
	if _size_ctrl:
		_size_ctrl.current_value = float(_n)
	if _speed_ctrl:
		_speed_ctrl.current_value = _anim_hop_dur
	if _left_ctrl:
		_left_ctrl.max_value = float(_n)
		_left_ctrl.current_value = float(_query_left)
	if _right_ctrl:
		_right_ctrl.max_value = float(_n)
		_right_ctrl.current_value = float(_query_right)


# ── Animation logic ───────────────────────────────────────────────────────

func _reset_anim() -> void:
	_anim_mode = 0
	_anim_step = 0
	_anim_timer = 0.0
	_anim_path = PackedInt32Array()
	_anim_flash = 0.0
	_query_show = false

func _start_update_anim() -> void:
	var idx := randi_range(0, _n - 1)
	var delta := randi_range(-3, 5)
	_original[idx] += delta
	_anim_value = delta
	_anim_path = _get_update_path(idx + 1)
	_anim_mode = 1
	_anim_step = 0
	_anim_timer = 0.0
	_anim_flash = 0.0
	# Actually update tree incrementally (we animate the visual path)
	_fenwick_update(idx + 1, delta)
	# Timing comparison
	_fenwick_steps = _anim_path.size()
	_naive_steps = _n  # naive would touch every element after idx

func _start_query_anim() -> void:
	_query_path_right = _get_query_path(_query_right)
	_query_path_left = _get_query_path(_query_left - 1) if _query_left > 1 else PackedInt32Array()
	_query_result = _fenwick_query(_query_right) - (_fenwick_query(_query_left - 1) if _query_left > 1 else 0)
	var total_hops := _query_path_right.size() + _query_path_left.size()
	_anim_path = _query_path_right
	# Append left path after right for sequential animation
	for idx in _query_path_left:
		_anim_path.append(idx)
	_anim_mode = 2
	_anim_step = 0
	_anim_timer = 0.0
	_anim_running_sum = 0
	_anim_flash = 0.0
	_query_show = true
	# Timing
	_fenwick_steps = total_hops
	_naive_steps = _query_right - _query_left + 1


func _process(delta: float) -> void:
	_time += delta

	# Advance animation
	if _anim_mode != 0:
		_anim_timer += delta
		if _anim_timer >= _anim_hop_dur:
			_anim_timer -= _anim_hop_dur
			if _anim_step < _anim_path.size():
				# Accumulate running sum for query animation
				if _anim_mode == 2 and _anim_step < _anim_path.size():
					var tree_idx := _anim_path[_anim_step]
					if _anim_step < _query_path_right.size():
						_anim_running_sum += _tree[tree_idx]
					else:
						_anim_running_sum -= _tree[tree_idx]
				_anim_step += 1
			else:
				# Animation complete — flash
				_anim_flash = minf(_anim_flash + delta * 4.0, 1.0)
				if _anim_flash >= 1.0:
					_anim_mode = 0
					_anim_flash = 0.0
	else:
		# Auto-demo when idle
		_auto_timer += delta
		if _auto_timer >= _auto_interval:
			_auto_timer = 0.0
			if _auto_mode == 0:
				_start_update_anim()
				_auto_mode = 1
			else:
				_query_left = randi_range(1, maxi(_n / 2, 1))
				_query_right = randi_range(_query_left, _n)
				_start_query_anim()
				_auto_mode = 0

	# Flash decay
	if _anim_mode == 0 and _anim_flash > 0.0:
		_anim_flash = maxf(_anim_flash - delta * 3.0, 0.0)

	# Rebuild all meshes
	_rebuild_bars()
	_rebuild_tree_nodes()
	_rebuild_connections()
	_rebuild_bits()
	_rebuild_compare()
	_update_labels()


# ── Geometry helpers ──────────────────────────────────────────────────────

func _idx_x(i: int) -> float:
	## X position for 1-indexed element i, centered around 0.
	var half := float(_n) * 0.5
	var spacing := bounding_size / float(_n)
	return (float(i) - 0.5 - half) * spacing

func _add_box(im: ImmediateMesh, center: Vector3, half: Vector3, color: Color) -> void:
	## Add an axis-aligned box as 12 triangles (6 faces).
	var c := center; var h := half
	# 8 corners
	var v := [
		c + Vector3(-h.x, -h.y, -h.z), c + Vector3( h.x, -h.y, -h.z),
		c + Vector3( h.x,  h.y, -h.z), c + Vector3(-h.x,  h.y, -h.z),
		c + Vector3(-h.x, -h.y,  h.z), c + Vector3( h.x, -h.y,  h.z),
		c + Vector3( h.x,  h.y,  h.z), c + Vector3(-h.x,  h.y,  h.z),
	]
	var faces := [
		[0,1,2,3], [5,4,7,6],  # front, back
		[4,0,3,7], [1,5,6,2],  # left, right
		[3,2,6,7], [4,5,1,0],  # top, bottom
	]
	for f in faces:
		im.surface_set_color(color)
		im.surface_add_vertex(v[f[0]])
		im.surface_set_color(color)
		im.surface_add_vertex(v[f[1]])
		im.surface_set_color(color)
		im.surface_add_vertex(v[f[2]])
		im.surface_set_color(color)
		im.surface_add_vertex(v[f[0]])
		im.surface_set_color(color)
		im.surface_add_vertex(v[f[2]])
		im.surface_set_color(color)
		im.surface_add_vertex(v[f[3]])

func _add_line(im: ImmediateMesh, a: Vector3, b: Vector3, color: Color) -> void:
	im.surface_set_color(color)
	im.surface_add_vertex(a)
	im.surface_set_color(color)
	im.surface_add_vertex(b)

func _add_arrow(im: ImmediateMesh, from: Vector3, to: Vector3, color: Color) -> void:
	_add_line(im, from, to, color)
	# Small arrowhead
	var dir := (to - from).normalized()
	var perp := Vector3(dir.z, 0, -dir.x) if absf(dir.y) < 0.9 else Vector3(1, 0, 0)
	perp = perp.normalized() * 0.01
	var tip := to
	var base := to - dir * 0.025
	_add_line(im, tip, base + perp, color)
	_add_line(im, tip, base - perp, color)


# ── Rebuild: original array bars ──────────────────────────────────────────

func _rebuild_bars() -> void:
	_bar_im.clear_surfaces()
	_bar_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var max_val := 1
	for i in range(_n):
		max_val = maxi(max_val, absi(_original[i]))
	var spacing := bounding_size / float(_n)
	var bar_w := spacing * 0.35
	var base_y := -bounding_size * 0.25

	for i in range(_n):
		var val := _original[i]
		var h := absf(float(val)) / float(max_val) * bounding_size * 0.2
		h = maxf(h, 0.003)
		var x := _idx_x(i + 1)
		var y := base_y + h * 0.5 * signf(float(val))

		# Color: blue for positive, orange for negative
		var color: Color
		if val >= 0:
			color = Color(0.3, 0.65, 1.0, 0.85)
		else:
			color = Color(1.0, 0.45, 0.2, 0.85)

		# Highlight if this index is in the current query range
		if _query_show and (i + 1) >= _query_left and (i + 1) <= _query_right:
			color = color.lightened(0.3)
			color.a = 1.0

		_add_box(_bar_im, Vector3(x, y, 0), Vector3(bar_w, h * 0.5, bar_w), color)

	_bar_im.surface_end()


# ── Rebuild: Fenwick tree nodes (upper row) ───────────────────────────────

func _rebuild_tree_nodes() -> void:
	_tree_im.clear_surfaces()
	_tree_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var max_val := 1
	for i in range(1, _n + 1):
		max_val = maxi(max_val, absi(_tree[i]))
	var spacing := bounding_size / float(_n)
	var bar_w := spacing * 0.3
	var base_y := bounding_size * 0.12

	for i in range(1, _n + 1):
		var val := _tree[i]
		var h := absf(float(val)) / float(max_val) * bounding_size * 0.2
		h = maxf(h, 0.003)
		var x := _idx_x(i)
		var y := base_y + h * 0.5

		# Responsibility level determines color intensity
		var resp_bits := count_trailing_zeros(i & (-i))
		var t := clampf(float(resp_bits) / 4.0, 0.0, 1.0)
		var color := Color(0.2 + t * 0.6, 1.0 - t * 0.3, 0.3 + t * 0.3, 0.9)

		# Animated highlight: is this node in the current animation path?
		var in_path := false
		var is_current := false
		if _anim_mode != 0 and _anim_path.size() > 0:
			for s in range(mini(_anim_step, _anim_path.size())):
				if _anim_path[s] == i:
					in_path = true
					break
			if _anim_step < _anim_path.size() and _anim_path[_anim_step] == i:
				is_current = true

		if is_current:
			# Current hop: bright pulse
			var pulse := 0.5 + 0.5 * sin(_time * 12.0)
			if _anim_mode == 1:
				color = Color(1.0, 0.2 + pulse * 0.3, 0.1, 1.0)  # red/orange for update
			else:
				color = Color(0.1, 1.0, 0.2 + pulse * 0.3, 1.0)  # green for query
		elif in_path:
			if _anim_mode == 1:
				color = Color(1.0, 0.5, 0.3, 0.95)
			else:
				color = Color(0.3, 0.9, 0.5, 0.95)

		_add_box(_tree_im, Vector3(x, y, 0), Vector3(bar_w, h * 0.5, bar_w), color)

	_tree_im.surface_end()


# ── Rebuild: connections and arrows ───────────────────────────────────────

func _rebuild_connections() -> void:
	_conn_im.clear_surfaces()
	_conn_im.surface_begin(Mesh.PRIMITIVE_LINES)

	var base_y_arr := -bounding_size * 0.25
	var base_y_tree := bounding_size * 0.12

	# Responsibility brackets (faint)
	for i in range(1, _n + 1):
		var rng := _responsibility_range(i)
		if rng.x != rng.y:
			var x_start := _idx_x(rng.x)
			var x_end := _idx_x(rng.y)
			var y := base_y_tree - 0.02
			var c := Color(1.0, 0.6, 0.2, 0.25)
			_add_line(_conn_im, Vector3(x_start, y, 0), Vector3(x_end, y, 0), c)
			_add_line(_conn_im, Vector3(x_start, y - 0.01, 0), Vector3(x_start, y + 0.01, 0), c)
			_add_line(_conn_im, Vector3(x_end, y - 0.01, 0), Vector3(x_end, y + 0.01, 0), c)

	# Animated propagation arrows
	if _anim_mode != 0 and _anim_path.size() > 1:
		var visited := mini(_anim_step + 1, _anim_path.size())
		for s in range(visited - 1):
			var from_x := _idx_x(_anim_path[s])
			var to_x := _idx_x(_anim_path[s + 1])
			var y := base_y_tree + bounding_size * 0.15
			var c: Color
			if _anim_mode == 1:
				c = Color(1.0, 0.3, 0.1, 0.9)
			else:
				c = Color(0.1, 1.0, 0.4, 0.9)
			_add_arrow(_conn_im, Vector3(from_x, y, 0), Vector3(to_x, y, 0), c)

			# Show bit operation label position (arc above)
			var mid_x := (from_x + to_x) * 0.5
			var arc_y := y + 0.02
			_add_line(_conn_im, Vector3(from_x, y, 0), Vector3(mid_x, arc_y, 0), c)
			_add_line(_conn_im, Vector3(mid_x, arc_y, 0), Vector3(to_x, y, 0), c)

	# Vertical connectors from array bar to tree node
	for i in range(1, _n + 1):
		var x := _idx_x(i)
		var c := Color(0.5, 0.5, 0.6, 0.15)
		_add_line(_conn_im, Vector3(x, base_y_arr + 0.01, 0), Vector3(x, base_y_tree - 0.01, 0), c)

	_conn_im.surface_end()


# ── Rebuild: binary index bits ────────────────────────────────────────────

func _rebuild_bits() -> void:
	_bits_im.clear_surfaces()
	_bits_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var bit_count := 0
	var temp := _n
	while temp > 0:
		bit_count += 1
		temp >>= 1
	bit_count = maxi(bit_count, 4)

	var base_y := bounding_size * 0.35
	var bit_size := bounding_size * 0.008
	var bit_gap := bit_size * 3.0

	for i in range(1, _n + 1):
		var x_center := _idx_x(i)
		for b in range(bit_count):
			var bit_val := (i >> b) & 1
			var bx := x_center + (float(b) - float(bit_count) * 0.5 + 0.5) * bit_gap
			var by := base_y
			var c: Color
			if bit_val == 1:
				# Highlight LSB specifically
				if b == count_trailing_zeros(i & (-i)) and b == _lowest_set_bit_pos(i):
					c = Color(1.0, 0.9, 0.2, 1.0)  # gold for LSB boundary
				else:
					c = Color(0.9, 0.9, 0.4, 0.9)
			else:
				c = Color(0.25, 0.25, 0.3, 0.4)
			_add_box(_bits_im, Vector3(bx, by, 0), Vector3(bit_size, bit_size, bit_size), c)

	_bits_im.surface_end()

func _lowest_set_bit_pos(n: int) -> int:
	if n == 0:
		return -1
	var pos := 0
	while (n & 1) == 0:
		n >>= 1
		pos += 1
	return pos


# ── Rebuild: naive vs Fenwick comparison ──────────────────────────────────

func _rebuild_compare() -> void:
	_compare_im.clear_surfaces()
	if _naive_steps == 0 and _fenwick_steps == 0:
		return
	_compare_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var cx := bounding_size * 0.38
	var base_y := -bounding_size * 0.1
	var max_steps := maxi(_naive_steps, 1)
	var bar_w := bounding_size * 0.04
	var max_h := bounding_size * 0.15

	# Naive bar (red)
	var naive_h := float(_naive_steps) / float(max_steps) * max_h
	naive_h = maxf(naive_h, 0.005)
	_add_box(_compare_im, Vector3(cx, base_y + naive_h * 0.5, 0),
		Vector3(bar_w, naive_h * 0.5, bar_w), Color(0.9, 0.3, 0.3, 0.85))

	# Fenwick bar (green)
	var fen_h := float(_fenwick_steps) / float(max_steps) * max_h
	fen_h = maxf(fen_h, 0.005)
	_add_box(_compare_im, Vector3(cx + bar_w * 3.0, base_y + fen_h * 0.5, 0),
		Vector3(bar_w, fen_h * 0.5, bar_w), Color(0.3, 0.9, 0.4, 0.85))

	_compare_im.surface_end()


# ── Labels update ─────────────────────────────────────────────────────────

func _update_labels() -> void:
	var mode_str := ""
	if _anim_mode == 1:
		mode_str = "UPDATE  delta=%d  hop %d/%d" % [_anim_value, mini(_anim_step + 1, _anim_path.size()), _anim_path.size()]
	elif _anim_mode == 2:
		mode_str = "QUERY [%d..%d]  sum=%d  hop %d/%d" % [_query_left, _query_right, _anim_running_sum, mini(_anim_step + 1, _anim_path.size()), _anim_path.size()]
	else:
		mode_str = "idle"

	_metrics_label.text = "n=%d | %s" % [_n, mode_str]

	if _naive_steps > 0 or _fenwick_steps > 0:
		_query_label.text = "Naive: O(%d)   Fenwick: O(%d)   [range %d..%d = %d]" % [
			_naive_steps, _fenwick_steps, _query_left, _query_right, _query_result]
	else:
		_query_label.text = ""


# ── Utility ───────────────────────────────────────────────────────────────

func count_trailing_zeros(n: int) -> int:
	if n == 0:
		return 0
	var c := 0
	while (n & 1) == 0:
		n >>= 1
		c += 1
	return c


# ── Grid config ───────────────────────────────────────────────────────────

func apply_grid_config(config: Dictionary) -> void:
	if config.has("array_size"):
		var sz := clampi(int(config.array_size), 4, 32)
		if sz != _n:
			_n = sz
			_init_array()
			_build_fenwick()
			_reset_anim()
	if config.has("values") and config.values is Array:
		var vals: Array = config.values
		_n = clampi(vals.size(), 4, 32)
		_original.resize(_n)
		for i in range(_n):
			_original[i] = int(vals[i])
		_build_fenwick()
		_reset_anim()
	if config.has("anim_speed"):
		_anim_hop_dur = clampf(float(config.anim_speed), 0.1, 1.0)
	if config.has("query_left"):
		_query_left = clampi(int(config.query_left), 1, _n)
	if config.has("query_right"):
		_query_right = clampi(int(config.query_right), _query_left, _n)
	if config.has("auto_interval"):
		_auto_interval = clampf(float(config.auto_interval), 1.0, 10.0)
	_sync_controllers()
