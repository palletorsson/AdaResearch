extends Node2D

# Draws 2D streamlines of a vector field, similar to the provided reference image.

@export var background_color: Color = Color(0.7, 0.73, 0.76, 1.0) # soft gray
@export var line_color: Color = Color(0.8, 0.0, 0.0, 0.7) # red with some alpha
@export var line_width: float = 1.2
@export var seed_grid_cols: int = 28
@export var seed_grid_rows: int = 16
@export var step_size: float = 2.0
@export var max_steps: int = 400
@export var field_strength: float = 140.0
@export var centers_count: int = 12
@export var random_seed: int = 42
@export var animate: bool = true
@export var animation_speed: float = 0.4
@export var center_orbit_radius: float = 20.0
@export var rebuild_interval: float = 0.06

var _polylines: Array[PackedVector2Array] = []
var _centers: Array[Vector2] = []
var _time: float = 0.0
var _accum: float = 0.0

func _ready() -> void:
	randomize()
	if random_seed != 0:
		randi() # mix state
		seed(random_seed)
	get_viewport().size_changed.connect(_on_viewport_resized)
	_generate_centers()
	_build_streamlines()
	queue_redraw()

func _on_viewport_resized() -> void:
	_build_streamlines()
	queue_redraw()

func _process(delta: float) -> void:
	if !animate:
		return
	_time += delta
	_accum += delta
	if _accum >= rebuild_interval:
		_accum = 0.0
		_build_streamlines()
		queue_redraw()

func _draw() -> void:
	# Background
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), background_color, true)
	# Streamlines
	for points in _polylines:
		if points.size() > 1:
			draw_polyline(points, line_color, line_width, true)

func _build_streamlines() -> void:
	_polylines.clear()
	if _centers.is_empty():
		_generate_centers()

	var size: Vector2 = get_viewport_rect().size
	var cols: int = max(seed_grid_cols, 1)
	var rows: int = max(seed_grid_rows, 1)

	for r in range(rows):
		for c in range(cols):
			var p: Vector2 = Vector2(
				(c + 0.5) * size.x / cols,
				(r + 0.5) * size.y / rows
			)
			# integrate both directions for a fuller streamline
			var forward: PackedVector2Array = _integrate_streamline(p, 1.0)
			var backward: PackedVector2Array = _integrate_streamline(p, -1.0)
			backward.reverse()
			var joined: PackedVector2Array = PackedVector2Array()
			joined.append_array(backward)
			joined.push_back(p)
			joined.append_array(forward)
			_polylines.append(joined)

func _integrate_streamline(start: Vector2, direction_sign: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	var p: Vector2 = start
	var size: Vector2 = get_viewport_rect().size
	for i in range(max_steps):
		var v: Vector2 = _vector_field(p)
		var v_len: float = v.length()
		if v_len < 0.0001:
			break
		var dp: Vector2 = v.normalized() * step_size * direction_sign
		# RK2 midpoint to keep curvature smooth
		var mid: Vector2 = p + dp * 0.5
		var vmid: Vector2 = _vector_field(mid).normalized()
		dp = vmid * step_size * direction_sign
		p += dp
		if p.x < 2.0 or p.y < 2.0 or p.x > size.x - 2.0 or p.y > size.y - 2.0:
			break
		pts.append(p)
	return pts

func _generate_centers() -> void:
	_centers.clear()
	var size: Vector2 = get_viewport_rect().size
	if size == Vector2.ZERO:
		size = Vector2(1280, 720)
	for i in range(centers_count):
		var pos: Vector2 = Vector2(
			randf_range(size.x * 0.05, size.x * 0.95),
			randf_range(size.y * 0.05, size.y * 0.95)
		)
		_centers.append(pos)

func _vector_field(p: Vector2) -> Vector2:
	# Superposition of several swirling centers (vortices) with soft falloff.
	# Each contributes a perpendicular vector scaled by inverse-square distance.
	var v: Vector2 = Vector2.ZERO
	for i in range(_centers.size()):
		var base_c: Vector2 = _centers[i]
		var phase: float = _time * animation_speed + float(i) * 0.7
		var c: Vector2 = base_c + Vector2(sin(phase), cos(phase)) * center_orbit_radius
		var r: Vector2 = p - c
		var d2: float = max(r.length_squared(), 25.0)
		var swirl: Vector2 = Vector2(-r.y, r.x) / d2
		v += swirl * field_strength
	# Gentle boundary flow to keep lines inside
	var size: Vector2 = get_viewport_rect().size
	if size != Vector2.ZERO:
		var to_center: Vector2 = (size * 0.5) - p
		v += to_center * 0.0008
	return v
