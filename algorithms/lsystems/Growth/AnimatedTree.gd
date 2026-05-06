extends Node3D

# @identity
# essence: generation_timer → lsystem.generate() → interpret → draw_with_wind — growth made visible in time
# desire: To grow before your eyes — each generation adding branches with tapering thickness and wind sway
# critical_parameter: growth_delay — controls the pace of revelation, from instant to meditative
# triggers: Each generation adds depth, widens angles (angle_spread_per_gen), and adds leaves at terminal branches
# emerges: Wind animation on cached segments creates living motion — the tree breathes after it finishes growing
# needs: VR growth controls [missing], wind parameter sliders [missing], Label3D [has]
# relationships: Extends lsystem_tree (static → animated). Feeds into LSystems_Growth. Uses LSystem.create_fractal_plant().
# truth: Watching a tree grow generation by generation teaches more than seeing the final form.

## Animated L-System Tree
## Grows step-by-step showing L-System generation process.
## Realistic branch tapering, fractal angle variation, and wind sway.

@export var max_iterations: int = 5
@export var step_length: float = 0.12
@export var base_angle: float = 25.0
@export var growth_delay: float = 1.5
@export var initial_thickness: float = 0.018
@export var thickness_decay: float = 0.62
@export var length_decay: float = 0.72
@export var angle_spread_per_gen: float = 1.12  # angles widen each generation
@export var display_size: float = 1.0

## Wind
@export var wind_strength: float = 0.04
@export var wind_speed: float = 1.2

## Colors
@export var trunk_color: Color = Color(0.45, 0.28, 0.12)
@export var branch_color: Color = Color(0.55, 0.38, 0.18)
@export var leaf_color: Color = Color(0.25, 0.72, 0.22)

var _lsystem: LSystem
var _current_iteration: int = 0
var _growth_timer: float = 0.0
var _is_growing: bool = true
var _rng: RandomNumberGenerator

# Rendering
var _mesh_instance: MeshInstance3D
var _immediate_mesh: ImmediateMesh
var _info_label: Label3D
var _gen_label: Label3D

# Cached segment data for wind animation: [start, end, depth, thickness, normal]
var _segments: Array = []
var _max_depth: int = 0
var _scale_factor: float = 1.0
var _center: Vector3 = Vector3.ZERO
var _time: float = 0.0


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 42

	_lsystem = LSystem.create_fractal_plant()

	_create_display()
	_create_ground()
	_create_ui()

	# Start first generation
	_grow_one_generation()


func _process(delta: float) -> void:
	_time += delta

	# Growth timer
	if _is_growing:
		_growth_timer += delta
		if _growth_timer >= growth_delay:
			_growth_timer = 0.0
			_grow_one_generation()

	# Continuous wind redraw
	if not _segments.is_empty():
		_draw_tree()


func _grow_one_generation() -> void:
	if _current_iteration >= max_iterations:
		_is_growing = false
		_update_ui()
		return

	_lsystem.generate()
	_current_iteration += 1

	# Re-interpret with new generation
	_rng.seed = 42
	_interpret_lsystem()
	_draw_tree()
	_update_ui()


func _interpret_lsystem() -> void:
	var instructions := _lsystem.get_sentence()
	if instructions.is_empty():
		return

	# Turtle state
	var pos := Vector3.ZERO
	var dir := Vector3.UP
	var right := Vector3.RIGHT
	var up := Vector3.FORWARD
	var depth: int = 0
	var current_length: float = step_length
	var current_angle: float = base_angle
	var current_thickness: float = initial_thickness

	var stack: Array = []
	_segments.clear()
	_max_depth = 0

	for c in instructions:
		match c:
			"F", "G":
				var new_pos := pos + dir * current_length
				# Compute perpendicular for quad building
				var perp := right.normalized()
				_segments.append([pos, new_pos, depth, current_thickness, perp])
				pos = new_pos
			"f":
				pos += dir * current_length
			"+":
				# Turn left — angle widens with generation depth
				var gen_factor := pow(angle_spread_per_gen, float(depth))
				var varied := deg_to_rad(current_angle * gen_factor + _rng.randf_range(-4.0, 4.0))
				var axis := dir.cross(right)
				if axis.length_squared() < 0.01:
					axis = up
				axis = axis.normalized()
				dir = dir.rotated(axis, varied).normalized()
				right = right.rotated(axis, varied).normalized()
			"-":
				var gen_factor := pow(angle_spread_per_gen, float(depth))
				var varied := deg_to_rad(current_angle * gen_factor + _rng.randf_range(-4.0, 4.0))
				var axis := dir.cross(right)
				if axis.length_squared() < 0.01:
					axis = up
				axis = axis.normalized()
				dir = dir.rotated(axis, -varied).normalized()
				right = right.rotated(axis, -varied).normalized()
			"[":
				stack.append({
					"pos": pos,
					"dir": dir,
					"right": right,
					"up": up,
					"depth": depth,
					"length": current_length,
					"angle": current_angle,
					"thickness": current_thickness,
				})
				depth += 1
				if depth > _max_depth:
					_max_depth = depth
				current_length *= length_decay
				current_angle *= 0.95  # Subtle angle tightening per depth
				current_thickness *= thickness_decay
			"]":
				if stack.size() > 0:
					var state: Dictionary = stack.pop_back()
					pos = state["pos"]
					dir = state["dir"]
					right = state["right"]
					up = state["up"]
					depth = state["depth"]
					current_length = state["length"]
					current_angle = state["angle"]
					current_thickness = state["thickness"]
			"X":
				pass

	# Compute bounds for centering and scaling
	if _segments.is_empty():
		return

	var min_bounds := Vector3(INF, INF, INF)
	var max_bounds := Vector3(-INF, -INF, -INF)
	for seg in _segments:
		var s: Vector3 = seg[0]
		var e: Vector3 = seg[1]
		min_bounds = min_bounds.min(s).min(e)
		max_bounds = max_bounds.max(s).max(e)

	var bounds_size := max_bounds - min_bounds
	var max_dim: float = maxf(maxf(bounds_size.x, bounds_size.y), maxf(bounds_size.z, 0.001))
	_scale_factor = display_size * 0.75 / max_dim
	_center = (min_bounds + max_bounds) / 2.0
	_center.y = min_bounds.y


func _draw_tree() -> void:
	if not _immediate_mesh or _segments.is_empty():
		return
	_immediate_mesh.clear_surfaces()

	var safe_max_depth := maxi(_max_depth, 1)

	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for seg in _segments:
		var p1: Vector3 = (seg[0] - _center) * _scale_factor
		var p2: Vector3 = (seg[1] - _center) * _scale_factor
		var depth: int = seg[2]
		var thickness: float = seg[3] * _scale_factor
		var perp: Vector3 = seg[4]

		# Wind displacement — increases with height, varies with time
		var height_factor := maxf(p1.y, 0.0) / maxf(display_size * 0.75, 0.01)
		var wind_offset := Vector3(
			sin(_time * wind_speed + p1.y * 3.0) * wind_strength * height_factor,
			0.0,
			cos(_time * wind_speed * 0.7 + p1.x * 2.0) * wind_strength * height_factor * 0.5
		)
		var wind_offset_end := Vector3(
			sin(_time * wind_speed + p2.y * 3.0) * wind_strength * height_factor,
			0.0,
			cos(_time * wind_speed * 0.7 + p2.x * 2.0) * wind_strength * height_factor * 0.5
		)

		p1 += wind_offset
		p2 += wind_offset_end

		# Tapering: start of segment is thicker, end is thinner
		var taper_start := thickness
		var taper_end := thickness * 0.75

		# Depth-based color: trunk brown -> branch -> green tips
		var t: float = clampf(float(depth) / float(safe_max_depth), 0.0, 1.0)
		var col: Color
		if t < 0.4:
			col = trunk_color.lerp(branch_color, t / 0.4)
		elif t < 0.8:
			col = branch_color.lerp(leaf_color, (t - 0.4) / 0.4)
		else:
			col = leaf_color.lightened((t - 0.8) * 0.5)

		# Build a tapered quad (two triangles) for each segment
		# Use perpendicular direction for width
		var seg_dir := (p2 - p1).normalized()
		var side := perp
		# Make sure side is actually perpendicular to segment direction
		side = (side - seg_dir * side.dot(seg_dir)).normalized()
		if side.length_squared() < 0.01:
			side = seg_dir.cross(Vector3.UP).normalized()
			if side.length_squared() < 0.01:
				side = Vector3.RIGHT

		var s1 := p1 + side * taper_start
		var s2 := p1 - side * taper_start
		var e1 := p2 + side * taper_end
		var e2 := p2 - side * taper_end

		# Triangle 1: s1, s2, e1
		_immediate_mesh.surface_set_color(col)
		_immediate_mesh.surface_add_vertex(s1)
		_immediate_mesh.surface_set_color(col)
		_immediate_mesh.surface_add_vertex(s2)
		_immediate_mesh.surface_set_color(col)
		_immediate_mesh.surface_add_vertex(e1)

		# Triangle 2: s2, e2, e1
		_immediate_mesh.surface_set_color(col)
		_immediate_mesh.surface_add_vertex(s2)
		_immediate_mesh.surface_set_color(col)
		_immediate_mesh.surface_add_vertex(e2)
		_immediate_mesh.surface_set_color(col)
		_immediate_mesh.surface_add_vertex(e1)

		# Second quad rotated 90° for billboard-like thickness from all angles
		var side2 := seg_dir.cross(side).normalized()
		if side2.length_squared() > 0.01:
			var s3 := p1 + side2 * taper_start
			var s4 := p1 - side2 * taper_start
			var e3 := p2 + side2 * taper_end
			var e4 := p2 - side2 * taper_end

			_immediate_mesh.surface_set_color(col)
			_immediate_mesh.surface_add_vertex(s3)
			_immediate_mesh.surface_set_color(col)
			_immediate_mesh.surface_add_vertex(s4)
			_immediate_mesh.surface_set_color(col)
			_immediate_mesh.surface_add_vertex(e3)

			_immediate_mesh.surface_set_color(col)
			_immediate_mesh.surface_add_vertex(s4)
			_immediate_mesh.surface_set_color(col)
			_immediate_mesh.surface_add_vertex(e4)
			_immediate_mesh.surface_set_color(col)
			_immediate_mesh.surface_add_vertex(e3)

	_immediate_mesh.surface_end()

	# Leaf particles at terminal branches (depth == max_depth)
	if _max_depth > 1:
		_draw_leaves()


func _draw_leaves() -> void:
	var safe_max_depth := maxi(_max_depth, 1)
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for seg in _segments:
		var depth: int = seg[2]
		if depth < _max_depth - 1:
			continue

		var tip: Vector3 = (seg[1] - _center) * _scale_factor
		var height_factor := maxf(tip.y, 0.0) / maxf(display_size * 0.75, 0.01)
		tip += Vector3(
			sin(_time * wind_speed + tip.y * 3.0) * wind_strength * height_factor,
			0.0,
			cos(_time * wind_speed * 0.7 + tip.x * 2.0) * wind_strength * height_factor * 0.5
		)

		# Small triangle leaf
		var leaf_size: float = 0.012 * _scale_factor
		var t: float = clampf(float(depth) / float(safe_max_depth), 0.0, 1.0)
		var col := leaf_color.lightened(0.15 + t * 0.1)
		col.a = 1.0

		# Vary leaf orientation slightly
		var phase := tip.x * 7.0 + tip.z * 5.0
		var lx := cos(phase) * leaf_size
		var lz := sin(phase) * leaf_size

		_immediate_mesh.surface_set_color(col)
		_immediate_mesh.surface_add_vertex(tip + Vector3(0, leaf_size, 0))
		_immediate_mesh.surface_set_color(col)
		_immediate_mesh.surface_add_vertex(tip + Vector3(lx, 0, lz))
		_immediate_mesh.surface_set_color(col)
		_immediate_mesh.surface_add_vertex(tip + Vector3(-lz, 0, lx))

	_immediate_mesh.surface_end()


func _create_display() -> void:
	_immediate_mesh = ImmediateMesh.new()

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "TreeDisplay"
	_mesh_instance.mesh = _immediate_mesh

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh_instance.material_override = mat

	add_child(_mesh_instance)


func _create_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "Ground"

	var cylinder := CylinderMesh.new()
	cylinder.top_radius = display_size * 0.2
	cylinder.bottom_radius = display_size * 0.25
	cylinder.height = 0.02
	ground.mesh = cylinder

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.14, 0.1)
	mat.roughness = 0.95
	ground.material_override = mat

	ground.position = Vector3(0, -0.01, 0)
	add_child(ground)


func _create_ui() -> void:
	_info_label = Label3D.new()
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.font_size = 28
	_info_label.outline_size = 4
	_info_label.modulate = Color(0.4, 0.8, 0.3)
	_info_label.position = Vector3(0, display_size + 0.15, 0)
	add_child(_info_label)

	_gen_label = Label3D.new()
	_gen_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_gen_label.font_size = 20
	_gen_label.modulate = Color(0.6, 0.85, 0.5)
	_gen_label.position = Vector3(0, display_size + 0.02, 0)
	_gen_label.width = 600.0
	_gen_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_gen_label)


func _update_ui() -> void:
	if _info_label:
		_info_label.text = "L-System Tree\nGeneration: %d/%d" % [_current_iteration, max_iterations]

	if _gen_label:
		var status := "Growing..." if _is_growing else "Complete"
		_gen_label.text = "Status: %s\nSegments: %d | Depth: %d\nAngle spread: %.1fx | Wind: %.2f" % [
			status,
			_segments.size(),
			_max_depth,
			angle_spread_per_gen,
			wind_strength,
		]


func restart() -> void:
	_current_iteration = 0
	_growth_timer = 0.0
	_is_growing = true
	_segments.clear()
	_lsystem.reset()
	if _immediate_mesh:
		_immediate_mesh.clear_surfaces()
	_grow_one_generation()


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("max_iterations"):
		max_iterations = clampi(int(config["max_iterations"]), 1, 7)
	if config.has("step_length"):
		step_length = clampf(float(config["step_length"]), 0.02, 0.3)
	if config.has("base_angle"):
		base_angle = clampf(float(config["base_angle"]), 10.0, 50.0)
	if config.has("growth_delay"):
		growth_delay = clampf(float(config["growth_delay"]), 0.3, 5.0)
	if config.has("wind_strength"):
		wind_strength = clampf(float(config["wind_strength"]), 0.0, 0.2)
	if config.has("wind_speed"):
		wind_speed = clampf(float(config["wind_speed"]), 0.0, 5.0)
	if config.has("thickness_decay"):
		thickness_decay = clampf(float(config["thickness_decay"]), 0.3, 0.9)
	if config.has("angle_spread_per_gen"):
		angle_spread_per_gen = clampf(float(config["angle_spread_per_gen"]), 0.8, 1.5)
	if config.has("display_size"):
		display_size = clampf(float(config["display_size"]), 0.3, 3.0)
	restart()
