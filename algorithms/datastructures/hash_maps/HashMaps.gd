extends Node3D

## Hash Maps — Expressive VR 3D visualization
## Interactive hash table with linear chaining, collision distribution bar chart,
## dynamic rehashing animation (2x expansion), and load-factor colored buckets.
## VR sliders control bucket count, insertion rate, hash function, and load threshold.

@export var bounding_size: float = 0.8
@export var initial_bucket_count: int = 8
@export var max_bucket_count: int = 32
@export var rehash_load_threshold: float = 0.75

# ── State ──────────────────────────────────────────────────────────────────
var _bucket_count: int = 8
var _buckets: Array = []          # Array of Arrays (each bucket = array of key strings)
var _bucket_hashes: Array = []    # Parallel: original hash values for each element
var _total_elements: int = 0
var _collision_count: int = 0
var _time: float = 0.0
var _insert_timer: float = 0.0
var _insert_interval: float = 1.2
var _is_initialized: bool = false
var _frame_count: int = 0

# Rehash animation state
var _rehashing: bool = false
var _rehash_progress: float = 0.0   # 0→1
var _old_bucket_count: int = 0
var _old_buckets: Array = []
var _rehash_duration: float = 2.0

# Hash function selector: 0=djb2, 1=fnv1a, 2=simple_mod
var _hash_function_index: int = 0
var _hash_function_names: Array = ["djb2", "fnv1a", "mod-sum"]

# Visual flash: index of last-inserted bucket, fade timer
var _flash_bucket: int = -1
var _flash_timer: float = 0.0

# ── Meshes ─────────────────────────────────────────────────────────────────

# Bucket boxes (table visualization)
var _table_mesh_instance: MeshInstance3D
var _table_imesh: ImmediateMesh
var _table_material: StandardMaterial3D

# Chain elements (spheres inside buckets)
var _chain_mesh_instance: MeshInstance3D
var _chain_imesh: ImmediateMesh
var _chain_material: StandardMaterial3D

# Chain links (lines connecting elements)
var _link_mesh_instance: MeshInstance3D
var _link_imesh: ImmediateMesh
var _link_material: StandardMaterial3D

# Collision distribution bar chart
var _chart_mesh_instance: MeshInstance3D
var _chart_imesh: ImmediateMesh
var _chart_material: StandardMaterial3D

# Hash function arrow / indicator
var _arrow_mesh_instance: MeshInstance3D
var _arrow_imesh: ImmediateMesh
var _arrow_material: StandardMaterial3D

# ── Labels ─────────────────────────────────────────────────────────────────
var _title_label: Label3D
var _metrics_label: Label3D
var _chart_label: Label3D

# ── Controllers ────────────────────────────────────────────────────────────
var _bucket_ctrl: ParameterController3D
var _speed_ctrl: ParameterController3D
var _hash_ctrl: ParameterController3D
var _threshold_ctrl: ParameterController3D

# ── Key pool for insertion ─────────────────────────────────────────────────
var _key_pool: Array = [
	"apple", "banana", "cherry", "date", "elderberry", "fig", "grape",
	"honeydew", "kiwi", "lemon", "mango", "nectarine", "orange", "papaya",
	"quince", "raspberry", "strawberry", "tangerine", "ugli", "vanilla",
	"watermelon", "xigua", "yuzu", "zucchini", "avocado", "blueberry",
	"coconut", "dragonfruit", "eggplant", "fennel", "ginger", "hazelnut",
]
var _insert_counter: int = 0


func _ready() -> void:
	_bucket_count = initial_bucket_count
	_init_buckets()
	_setup_table_mesh()
	_setup_chain_mesh()
	_setup_link_mesh()
	_setup_chart_mesh()
	_setup_arrow_mesh()
	_setup_labels()
	_setup_controllers()
	# Seed with a few entries
	for key in ["apple", "banana", "cherry", "date", "elderberry"]:
		_insert_key(key)
	_is_initialized = true


# ── Bucket management ──────────────────────────────────────────────────────

func _init_buckets() -> void:
	_buckets.clear()
	_bucket_hashes.clear()
	_buckets.resize(_bucket_count)
	_bucket_hashes.resize(_bucket_count)
	for i in range(_bucket_count):
		_buckets[i] = []
		_bucket_hashes[i] = []


func _hash_key(key: String) -> int:
	match _hash_function_index:
		0:  # djb2
			var h: int = 5381
			for i in range(key.length()):
				h = ((h << 5) + h) + key.unicode_at(i)
			return absi(h) % _bucket_count
		1:  # fnv1a
			var h: int = 0x811c9dc5
			for i in range(key.length()):
				h = h ^ key.unicode_at(i)
				h = (h * 0x01000193) & 0x7FFFFFFF
			return h % _bucket_count
		2:  # simple mod-sum
			var h: int = 0
			for i in range(key.length()):
				h += key.unicode_at(i)
			return h % _bucket_count
	return 0


func _insert_key(key: String) -> void:
	var idx := _hash_key(key)
	if _buckets[idx].size() > 0:
		_collision_count += 1
	_buckets[idx].append(key)
	_bucket_hashes[idx].append(idx)
	_total_elements += 1
	_flash_bucket = idx
	_flash_timer = 0.6


func _get_load_factor() -> float:
	if _bucket_count == 0:
		return 0.0
	return float(_total_elements) / float(_bucket_count)


func _start_rehash() -> void:
	if _rehashing:
		return
	_old_bucket_count = _bucket_count
	_old_buckets = _buckets.duplicate(true)
	_bucket_count = mini(_bucket_count * 2, max_bucket_count)
	# Redistribute
	var all_keys: Array = []
	for b in _old_buckets:
		for k in b:
			all_keys.append(k)
	_init_buckets()
	_total_elements = 0
	_collision_count = 0
	for k in all_keys:
		_insert_key(k)
	_rehashing = true
	_rehash_progress = 0.0


# ── Mesh setup ─────────────────────────────────────────────────────────────

func _make_unshaded_material(emission_color: Color, emission_energy: float = 1.5) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = emission_color
	mat.emission_energy_multiplier = emission_energy
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _add_imesh_layer(mat: StandardMaterial3D) -> Array:
	var imesh := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = imesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.material_override = mat
	add_child(mi)
	return [mi, imesh]


func _setup_table_mesh() -> void:
	_table_material = _make_unshaded_material(Color(0.15, 0.2, 0.5), 1.2)
	var layer := _add_imesh_layer(_table_material)
	_table_mesh_instance = layer[0]
	_table_imesh = layer[1]


func _setup_chain_mesh() -> void:
	_chain_material = _make_unshaded_material(Color(0.4, 0.7, 1.0), 2.0)
	var layer := _add_imesh_layer(_chain_material)
	_chain_mesh_instance = layer[0]
	_chain_imesh = layer[1]


func _setup_link_mesh() -> void:
	_link_material = _make_unshaded_material(Color(0.8, 0.7, 0.2), 1.8)
	var layer := _add_imesh_layer(_link_material)
	_link_mesh_instance = layer[0]
	_link_imesh = layer[1]


func _setup_chart_mesh() -> void:
	_chart_material = _make_unshaded_material(Color(0.3, 0.8, 0.4), 1.5)
	var layer := _add_imesh_layer(_chart_material)
	_chart_mesh_instance = layer[0]
	_chart_imesh = layer[1]
	# Position chart behind the table
	_chart_mesh_instance.position = Vector3(0, 0, -bounding_size * 0.55)


func _setup_arrow_mesh() -> void:
	_arrow_material = _make_unshaded_material(Color(1.0, 0.6, 0.15), 2.5)
	var layer := _add_imesh_layer(_arrow_material)
	_arrow_mesh_instance = layer[0]
	_arrow_imesh = layer[1]


# ── Labels ─────────────────────────────────────────────────────────────────

func _setup_labels() -> void:
	_title_label = Label3D.new()
	_title_label.font_size = 28
	_title_label.pixel_size = 0.001
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.no_depth_test = true
	_title_label.modulate = Color(1, 1, 1, 0.9)
	_title_label.position = Vector3(0, bounding_size * 0.65, 0)
	add_child(_title_label)

	_metrics_label = Label3D.new()
	_metrics_label.font_size = 22
	_metrics_label.pixel_size = 0.001
	_metrics_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_metrics_label.no_depth_test = true
	_metrics_label.modulate = Color(0.7, 0.9, 1.0, 0.85)
	_metrics_label.position = Vector3(0, bounding_size * 0.65 - 0.06, 0)
	add_child(_metrics_label)

	_chart_label = Label3D.new()
	_chart_label.font_size = 20
	_chart_label.pixel_size = 0.001
	_chart_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_chart_label.no_depth_test = true
	_chart_label.modulate = Color(0.6, 1.0, 0.7, 0.85)
	_chart_label.position = Vector3(0, bounding_size * 0.65 - 0.12, 0)
	add_child(_chart_label)


# ── Controllers ────────────────────────────────────────────────────────────

func _setup_controllers() -> void:
	var y_pos := -bounding_size * 0.55

	_bucket_ctrl = ParameterController3D.new()
	_bucket_ctrl.parameter_name = "Buckets"
	_bucket_ctrl.min_value = 4.0
	_bucket_ctrl.max_value = float(max_bucket_count)
	_bucket_ctrl.default_value = float(initial_bucket_count)
	_bucket_ctrl.step_size = 1.0
	_bucket_ctrl.position = Vector3(-0.3, y_pos, 0)
	_bucket_ctrl.value_changed.connect(_on_buckets_changed)
	add_child(_bucket_ctrl)

	_speed_ctrl = ParameterController3D.new()
	_speed_ctrl.parameter_name = "Insert speed"
	_speed_ctrl.min_value = 0.2
	_speed_ctrl.max_value = 3.0
	_speed_ctrl.default_value = 1.2
	_speed_ctrl.step_size = 0.1
	_speed_ctrl.position = Vector3(0.0, y_pos, 0)
	_speed_ctrl.value_changed.connect(_on_speed_changed)
	add_child(_speed_ctrl)

	_hash_ctrl = ParameterController3D.new()
	_hash_ctrl.parameter_name = "Hash: djb2"
	_hash_ctrl.min_value = 0.0
	_hash_ctrl.max_value = 2.0
	_hash_ctrl.default_value = 0.0
	_hash_ctrl.step_size = 1.0
	_hash_ctrl.position = Vector3(0.3, y_pos, 0)
	_hash_ctrl.value_changed.connect(_on_hash_changed)
	add_child(_hash_ctrl)

	_threshold_ctrl = ParameterController3D.new()
	_threshold_ctrl.parameter_name = "Rehash at"
	_threshold_ctrl.min_value = 0.5
	_threshold_ctrl.max_value = 2.0
	_threshold_ctrl.default_value = 0.75
	_threshold_ctrl.step_size = 0.05
	_threshold_ctrl.position = Vector3(0.0, y_pos - 0.12, 0)
	_threshold_ctrl.value_changed.connect(_on_threshold_changed)
	add_child(_threshold_ctrl)


func _on_buckets_changed(val: float) -> void:
	var new_count := int(val)
	if new_count != _bucket_count:
		_old_bucket_count = _bucket_count
		_old_buckets = _buckets.duplicate(true)
		_bucket_count = new_count
		var all_keys: Array = []
		for b in _old_buckets:
			for k in b:
				all_keys.append(k)
		_init_buckets()
		_total_elements = 0
		_collision_count = 0
		for k in all_keys:
			_insert_key(k)
		_rehashing = true
		_rehash_progress = 0.0


func _on_speed_changed(val: float) -> void:
	_insert_interval = val


func _on_hash_changed(val: float) -> void:
	_hash_function_index = int(val)
	_hash_ctrl.parameter_name = "Hash: " + _hash_function_names[_hash_function_index]
	# Rehash with new function
	var all_keys: Array = []
	for b in _buckets:
		for k in b:
			all_keys.append(k)
	_init_buckets()
	_total_elements = 0
	_collision_count = 0
	for k in all_keys:
		_insert_key(k)


func _on_threshold_changed(val: float) -> void:
	rehash_load_threshold = val


func _sync_controllers() -> void:
	if _bucket_ctrl:
		_bucket_ctrl.default_value = float(_bucket_count)
	if _speed_ctrl:
		_speed_ctrl.default_value = _insert_interval
	if _hash_ctrl:
		_hash_ctrl.default_value = float(_hash_function_index)
		_hash_ctrl.parameter_name = "Hash: " + _hash_function_names[_hash_function_index]
	if _threshold_ctrl:
		_threshold_ctrl.default_value = rehash_load_threshold


# ── Main loop ──────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _is_initialized:
		return

	_time += delta
	_frame_count += 1

	# Flash decay
	if _flash_timer > 0.0:
		_flash_timer = maxf(0.0, _flash_timer - delta)

	# Rehash animation
	if _rehashing:
		_rehash_progress = minf(1.0, _rehash_progress + delta / _rehash_duration)
		if _rehash_progress >= 1.0:
			_rehashing = false

	# Auto-insert
	_insert_timer += delta
	if _insert_timer >= _insert_interval and not _rehashing:
		_insert_timer = 0.0
		var key := _key_pool[_insert_counter % _key_pool.size()] + str(_insert_counter)
		_insert_counter += 1
		_insert_key(key)
		# Check rehash threshold
		if _get_load_factor() > rehash_load_threshold and _bucket_count < max_bucket_count:
			_start_rehash()

	# Rebuild visuals
	_rebuild_table()
	_rebuild_chains()
	_rebuild_links()
	_rebuild_chart()
	_rebuild_arrow()
	_update_labels()


# ── Color helpers ──────────────────────────────────────────────────────────

func _load_factor_color(bucket_size: int) -> Color:
	## Color bucket by its load: empty→cool blue, 1→green, 2+→orange→red
	if bucket_size == 0:
		return Color(0.2, 0.25, 0.6, 0.4)
	elif bucket_size == 1:
		return Color(0.2, 0.7, 0.3, 0.7)
	elif bucket_size == 2:
		return Color(0.8, 0.7, 0.1, 0.8)
	elif bucket_size == 3:
		return Color(0.9, 0.4, 0.1, 0.85)
	else:
		return Color(1.0, 0.15, 0.1, 0.9)


func _element_color(bucket_idx: int, chain_pos: int) -> Color:
	## Color elements by bucket position — hue spread across table width
	var hue := float(bucket_idx) / float(maxi(_bucket_count, 1))
	var sat := clampf(0.6 + chain_pos * 0.1, 0.6, 1.0)
	var val := clampf(0.9 - chain_pos * 0.05, 0.6, 0.95)
	return Color.from_hsv(hue, sat, val, 1.0)


func _chart_bar_color(bucket_size: int, max_size: int) -> Color:
	## Bar chart color: gradient from green (low) to red (high)
	if max_size <= 0:
		return Color(0.3, 0.8, 0.4, 0.8)
	var t := clampf(float(bucket_size) / float(maxi(max_size, 1)), 0.0, 1.0)
	var r := lerpf(0.2, 1.0, t)
	var g := lerpf(0.8, 0.15, t)
	var b := lerpf(0.3, 0.1, t)
	return Color(r, g, b, 0.85)


# ── Geometry builders ──────────────────────────────────────────────────────

func _bucket_x(idx: int) -> float:
	## X position for bucket center, centered around 0
	var half_width := bounding_size * 0.5
	if _bucket_count <= 1:
		return 0.0
	return lerpf(-half_width, half_width, float(idx) / float(_bucket_count - 1))


func _bucket_width() -> float:
	if _bucket_count <= 1:
		return bounding_size * 0.8
	return (bounding_size / float(_bucket_count)) * 0.75


func _add_box(imesh: ImmediateMesh, center: Vector3, size: Vector3, color: Color) -> void:
	## Draw a box as 12 triangles (6 faces × 2 tris)
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var hz := size.z * 0.5
	var cx := center.x
	var cy := center.y
	var cz := center.z

	# 8 corners
	var corners: Array = [
		Vector3(cx - hx, cy - hy, cz - hz),  # 0: left-bottom-back
		Vector3(cx + hx, cy - hy, cz - hz),  # 1: right-bottom-back
		Vector3(cx + hx, cy + hy, cz - hz),  # 2: right-top-back
		Vector3(cx - hx, cy + hy, cz - hz),  # 3: left-top-back
		Vector3(cx - hx, cy - hy, cz + hz),  # 4: left-bottom-front
		Vector3(cx + hx, cy - hy, cz + hz),  # 5: right-bottom-front
		Vector3(cx + hx, cy + hy, cz + hz),  # 6: right-top-front
		Vector3(cx - hx, cy + hy, cz + hz),  # 7: left-top-front
	]

	# 6 faces as quads (2 tris each) — indices into corners
	var faces: Array = [
		[4, 5, 6, 7],  # front
		[1, 0, 3, 2],  # back
		[0, 4, 7, 3],  # left
		[5, 1, 2, 6],  # right
		[7, 6, 2, 3],  # top
		[0, 1, 5, 4],  # bottom
	]

	for face in faces:
		imesh.surface_set_color(color)
		imesh.surface_add_vertex(corners[face[0]])
		imesh.surface_set_color(color)
		imesh.surface_add_vertex(corners[face[1]])
		imesh.surface_set_color(color)
		imesh.surface_add_vertex(corners[face[2]])

		imesh.surface_set_color(color)
		imesh.surface_add_vertex(corners[face[0]])
		imesh.surface_set_color(color)
		imesh.surface_add_vertex(corners[face[2]])
		imesh.surface_set_color(color)
		imesh.surface_add_vertex(corners[face[3]])


func _add_sphere_approx(imesh: ImmediateMesh, center: Vector3, radius: float, color: Color, segments: int = 6) -> void:
	## Draw a simple UV sphere as triangles
	var rings := segments
	var slices := segments * 2
	for ring in range(rings):
		var theta0 := PI * float(ring) / float(rings)
		var theta1 := PI * float(ring + 1) / float(rings)
		for sl in range(slices):
			var phi0 := TAU * float(sl) / float(slices)
			var phi1 := TAU * float(sl + 1) / float(slices)

			var p00 := center + Vector3(
				sin(theta0) * cos(phi0),
				cos(theta0),
				sin(theta0) * sin(phi0)
			) * radius
			var p10 := center + Vector3(
				sin(theta1) * cos(phi0),
				cos(theta1),
				sin(theta1) * sin(phi0)
			) * radius
			var p01 := center + Vector3(
				sin(theta0) * cos(phi1),
				cos(theta0),
				sin(theta0) * sin(phi1)
			) * radius
			var p11 := center + Vector3(
				sin(theta1) * cos(phi1),
				cos(theta1),
				sin(theta1) * sin(phi1)
			) * radius

			imesh.surface_set_color(color)
			imesh.surface_add_vertex(p00)
			imesh.surface_set_color(color)
			imesh.surface_add_vertex(p10)
			imesh.surface_set_color(color)
			imesh.surface_add_vertex(p11)

			imesh.surface_set_color(color)
			imesh.surface_add_vertex(p00)
			imesh.surface_set_color(color)
			imesh.surface_add_vertex(p11)
			imesh.surface_set_color(color)
			imesh.surface_add_vertex(p01)


# ── Rebuild: bucket table ──────────────────────────────────────────────────

func _rebuild_table() -> void:
	_table_imesh.clear_surfaces()
	_table_imesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var bw := _bucket_width()
	var base_y := -bounding_size * 0.25
	var box_height := bounding_size * 0.06
	var box_depth := bw * 0.8

	for i in range(_bucket_count):
		var bx := _bucket_x(i)
		var load := _buckets[i].size()
		var color := _load_factor_color(load)

		# Flash highlight
		if i == _flash_bucket and _flash_timer > 0.0:
			var flash_t := _flash_timer / 0.6
			color = color.lerp(Color(1.0, 1.0, 1.0, 1.0), flash_t * 0.6)

		# Rehash animation: slide buckets into new positions
		var anim_scale := 1.0
		if _rehashing:
			var ease_t := 1.0 - pow(1.0 - _rehash_progress, 3.0)
			anim_scale = lerpf(0.5, 1.0, ease_t)
			color.a *= lerpf(0.4, 1.0, ease_t)

		_add_box(_table_imesh, Vector3(bx, base_y, 0),
			Vector3(bw * anim_scale, box_height, box_depth * anim_scale), color)

		# Bucket index label line (small tick above bucket)
		var tick_color := Color(0.5, 0.6, 0.7, 0.5)
		_table_imesh.surface_set_color(tick_color)
		_table_imesh.surface_add_vertex(Vector3(bx, base_y - box_height * 0.6, 0))
		_table_imesh.surface_set_color(tick_color)
		_table_imesh.surface_add_vertex(Vector3(bx, base_y - box_height * 1.2, 0))
		_table_imesh.surface_set_color(tick_color)
		_table_imesh.surface_add_vertex(Vector3(bx + 0.001, base_y - box_height * 1.2, 0))

	_table_imesh.surface_end()


# ── Rebuild: chain elements (spheres in buckets) ──────────────────────────

func _rebuild_chains() -> void:
	_chain_imesh.clear_surfaces()
	_chain_imesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var base_y := -bounding_size * 0.25 + bounding_size * 0.06
	var spacing := bounding_size * 0.06
	var radius := _bucket_width() * 0.25

	for i in range(_bucket_count):
		var bx := _bucket_x(i)
		var bucket: Array = _buckets[i]
		for j in range(bucket.size()):
			var cy := base_y + spacing + j * (radius * 2.5 + spacing * 0.3)
			var color := _element_color(i, j)

			# Pulse if recently inserted
			var r := radius
			if i == _flash_bucket and j == bucket.size() - 1 and _flash_timer > 0.0:
				var pulse := 1.0 + sin(_flash_timer * 20.0) * 0.3
				r *= pulse
				color = color.lerp(Color(1, 1, 1, 1), _flash_timer / 0.6 * 0.4)

			_add_sphere_approx(_chain_imesh, Vector3(bx, cy, 0), r, color, 5)

	_chain_imesh.surface_end()


# ── Rebuild: chain link lines ─────────────────────────────────────────────

func _rebuild_links() -> void:
	_link_imesh.clear_surfaces()
	_link_imesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var base_y := -bounding_size * 0.25 + bounding_size * 0.06
	var spacing := bounding_size * 0.06
	var radius := _bucket_width() * 0.25
	var link_color := Color(0.85, 0.75, 0.2, 0.7)

	for i in range(_bucket_count):
		var bx := _bucket_x(i)
		var bucket: Array = _buckets[i]
		if bucket.size() < 2:
			continue

		# Link from bucket top to first element
		for j in range(1, bucket.size()):
			var y0 := base_y + spacing + (j - 1) * (radius * 2.5 + spacing * 0.3)
			var y1 := base_y + spacing + j * (radius * 2.5 + spacing * 0.3)
			_link_imesh.surface_set_color(link_color)
			_link_imesh.surface_add_vertex(Vector3(bx, y0, 0))
			_link_imesh.surface_set_color(link_color)
			_link_imesh.surface_add_vertex(Vector3(bx, y1, 0))

		# Draw pointer arrow at bottom (bucket → first element)
		var arrow_y := base_y
		var first_y := base_y + spacing
		var arrow_color := Color(0.6, 0.6, 0.3, 0.5)
		_link_imesh.surface_set_color(arrow_color)
		_link_imesh.surface_add_vertex(Vector3(bx, arrow_y, 0))
		_link_imesh.surface_set_color(arrow_color)
		_link_imesh.surface_add_vertex(Vector3(bx, first_y, 0))

	_link_imesh.surface_end()


# ── Rebuild: collision distribution bar chart ─────────────────────────────

func _rebuild_chart() -> void:
	_chart_imesh.clear_surfaces()
	_chart_imesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_w := bounding_size * 0.5
	var chart_height := bounding_size * 0.35
	var max_size := 0
	for b in _buckets:
		max_size = maxi(max_size, b.size())

	if max_size == 0:
		max_size = 1

	var bar_width := (bounding_size / float(maxi(_bucket_count, 1))) * 0.7

	# Draw axes
	var axis_color := Color(0.4, 0.5, 0.6, 0.5)
	# X axis
	_chart_imesh.surface_set_color(axis_color)
	_chart_imesh.surface_add_vertex(Vector3(-half_w, 0, 0))
	_chart_imesh.surface_set_color(axis_color)
	_chart_imesh.surface_add_vertex(Vector3(half_w, 0, 0))
	_chart_imesh.surface_set_color(axis_color)
	_chart_imesh.surface_add_vertex(Vector3(half_w, 0.001, 0))
	# Y axis
	_chart_imesh.surface_set_color(axis_color)
	_chart_imesh.surface_add_vertex(Vector3(-half_w, 0, 0))
	_chart_imesh.surface_set_color(axis_color)
	_chart_imesh.surface_add_vertex(Vector3(-half_w, chart_height, 0))
	_chart_imesh.surface_set_color(axis_color)
	_chart_imesh.surface_add_vertex(Vector3(-half_w + 0.001, chart_height, 0))

	# Draw threshold line
	if max_size > 0:
		var threshold_y := (rehash_load_threshold * float(_bucket_count) / float(max_size)) * chart_height
		threshold_y = clampf(threshold_y, 0.0, chart_height)
		var threshold_color := Color(1.0, 0.3, 0.3, 0.4)
		_chart_imesh.surface_set_color(threshold_color)
		_chart_imesh.surface_add_vertex(Vector3(-half_w, threshold_y, 0))
		_chart_imesh.surface_set_color(threshold_color)
		_chart_imesh.surface_add_vertex(Vector3(half_w, threshold_y, 0))
		_chart_imesh.surface_set_color(threshold_color)
		_chart_imesh.surface_add_vertex(Vector3(half_w, threshold_y + 0.001, 0))

	# Draw bars
	for i in range(_bucket_count):
		var bx := _bucket_x(i)
		var size: int = _buckets[i].size()
		if size == 0:
			continue

		var bar_h := (float(size) / float(max_size)) * chart_height
		var color := _chart_bar_color(size, max_size)

		# Animated growth
		if _rehashing:
			var ease_t := 1.0 - pow(1.0 - _rehash_progress, 2.0)
			bar_h *= ease_t

		_add_box(_chart_imesh, Vector3(bx, bar_h * 0.5, 0),
			Vector3(bar_width, bar_h, bar_width * 0.5), color)

	_chart_imesh.surface_end()


# ── Rebuild: hash function indicator arrow ────────────────────────────────

func _rebuild_arrow() -> void:
	_arrow_imesh.clear_surfaces()
	_arrow_imesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Animated arrow showing hash function mapping
	var cycle := fmod(_time * 0.8, float(_bucket_count))
	var target_idx := int(cycle) % _bucket_count
	var arrow_t := fmod(cycle, 1.0)

	var start_y := bounding_size * 0.35
	var end_y := -bounding_size * 0.25 + bounding_size * 0.1
	var target_x := _bucket_x(target_idx)

	# Funnel from top center down to target bucket
	var current_y := lerpf(start_y, end_y, arrow_t)
	var current_x := lerpf(0.0, target_x, arrow_t * arrow_t)

	var arrow_color := Color(1.0, 0.7, 0.2, 0.7 + arrow_t * 0.3)
	_arrow_imesh.surface_set_color(arrow_color)
	_arrow_imesh.surface_add_vertex(Vector3(0, start_y, 0))
	_arrow_imesh.surface_set_color(arrow_color)
	_arrow_imesh.surface_add_vertex(Vector3(current_x, current_y, 0))

	# Small crosshair at current position
	var ch := 0.01
	var bright := Color(1.0, 0.9, 0.3, 1.0)
	_arrow_imesh.surface_set_color(bright)
	_arrow_imesh.surface_add_vertex(Vector3(current_x - ch, current_y, 0))
	_arrow_imesh.surface_set_color(bright)
	_arrow_imesh.surface_add_vertex(Vector3(current_x + ch, current_y, 0))
	_arrow_imesh.surface_set_color(bright)
	_arrow_imesh.surface_add_vertex(Vector3(current_x, current_y - ch, 0))
	_arrow_imesh.surface_set_color(bright)
	_arrow_imesh.surface_add_vertex(Vector3(current_x, current_y + ch, 0))

	_arrow_imesh.surface_end()


# ── Labels update ──────────────────────────────────────────────────────────

func _update_labels() -> void:
	var lf := _get_load_factor()
	_title_label.text = "Hash Map — %s" % _hash_function_names[_hash_function_index]

	var status := "REHASHING..." if _rehashing else "active"
	_metrics_label.text = "buckets: %d  |  elements: %d  |  load: %.2f  |  collisions: %d  |  %s" % [
		_bucket_count, _total_elements, lf, _collision_count, status
	]

	# Chart label: distribution stats
	var max_chain := 0
	var empty_count := 0
	for b in _buckets:
		max_chain = maxi(max_chain, b.size())
		if b.size() == 0:
			empty_count += 1
	_chart_label.text = "distribution — max chain: %d  |  empty: %d/%d  |  threshold: %.0f%%" % [
		max_chain, empty_count, _bucket_count, rehash_load_threshold * 100.0
	]

	# Color metrics label by load factor
	if lf > rehash_load_threshold:
		_metrics_label.modulate = Color(1.0, 0.4, 0.3, 0.9)
	elif lf > rehash_load_threshold * 0.7:
		_metrics_label.modulate = Color(1.0, 0.8, 0.3, 0.9)
	else:
		_metrics_label.modulate = Color(0.7, 0.9, 1.0, 0.85)


# ── apply_grid_config ──────────────────────────────────────────────────────

func apply_grid_config(config: Dictionary) -> void:
	if config.has("bucket_count"):
		var bc := clampi(int(config["bucket_count"]), 4, max_bucket_count)
		if bc != _bucket_count:
			_on_buckets_changed(float(bc))

	if config.has("hash_function"):
		var hf_name: String = str(config["hash_function"]).to_lower()
		for i in range(_hash_function_names.size()):
			if _hash_function_names[i].to_lower() == hf_name:
				_hash_function_index = i
				_on_hash_changed(float(i))
				break

	if config.has("insert_interval"):
		_insert_interval = clampf(float(config["insert_interval"]), 0.2, 3.0)

	if config.has("rehash_threshold"):
		rehash_load_threshold = clampf(float(config["rehash_threshold"]), 0.5, 2.0)

	if config.has("initial_keys") and config["initial_keys"] is Array:
		_init_buckets()
		_total_elements = 0
		_collision_count = 0
		for key in config["initial_keys"]:
			_insert_key(str(key))

	_sync_controllers()
