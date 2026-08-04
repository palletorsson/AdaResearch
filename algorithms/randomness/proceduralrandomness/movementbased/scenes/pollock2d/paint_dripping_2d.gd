extends Node2D

# Pollock Action Painting — 3D VR Version
# Paints to an Image texture applied to a wall-mounted QuadMesh canvas.

signal stroke_path_generated(path: PackedVector2Array, stroke_color: Color, stroke_width: float, duration: float)

@export var canvas_size: Vector2 = Vector2(1200, 800)
@export var background_color: Color = Color(0.85, 0.82, 0.73)

@export var min_drip_size: float = 1.0
@export var max_drip_size: float = 15.0
@export var drip_count: int = 50
@export var splatter_chance: float = 0.3
@export var max_splatter_count: int = 10

@export var min_line_width: float = 0.8
@export var max_line_width: float = 6.0
@export var line_segment_length: float = 10.0
@export var line_curviness: float = 0.3
@export var line_count: int = 20
@export var min_line_points: int = 10
@export var max_line_points: int = 100

@export var paint_interval: float = 4.0
@export_range(0.0, 1.0, 0.01) var initial_paint_ratio: float = 0.15
@export var paint_buildup_duration: float = 80.0

var colors: Array = [
	Color(0.0, 0.0, 0.0),
	Color(0.2, 0.2, 0.2),
	Color(1.0, 1.0, 1.0),
	Color(0.55, 0.27, 0.07),
	Color(0.0, 0.2, 0.4),
	Color(0.7, 0.1, 0.1)
]

var canvas: Image
var texture: ImageTexture
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var painting_timer: Timer
var _paint_elapsed_time: float = 0.0

var _mesh_instance: MeshInstance3D
var _material: StandardMaterial3D
var _label: Label3D

func _ready() -> void:
	rng.randomize()

	# Create wall-mounted canvas
	_mesh_instance = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.8, 0.53)
	_mesh_instance.mesh = quad
	_mesh_instance.position = Vector3(0, 0.3, 0)

	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh_instance.material_override = _material
	add_child(_mesh_instance)

	_label = Label3D.new()
	_label.text = "Pollock Action Painting"
	_label.font_size = 28
	_label.position = Vector3(0, -0.02, 0)
	_label.modulate = Color(1, 1, 1, 0.8)
	add_child(_label)

	# Create canvas image
	canvas = Image.create(int(canvas_size.x), int(canvas_size.y), false, Image.FORMAT_RGBA8)
	canvas.fill(background_color)
	_create_initial_painting()
	_update_texture()

	# Timer for continuous painting
	painting_timer = Timer.new()
	add_child(painting_timer)
	painting_timer.wait_time = paint_interval
	painting_timer.one_shot = false
	painting_timer.timeout.connect(_add_new_painting_strokes)
	painting_timer.start()

func _update_texture() -> void:
	texture = ImageTexture.create_from_image(canvas)
	_material.albedo_texture = texture

func _create_initial_painting() -> void:
	_paint_elapsed_time = 0.0
	var starting_ratio := clampf(initial_paint_ratio, 0.0, 1.0)
	var initial_drips := maxi(1, int(round(float(drip_count) * starting_ratio)))
	var initial_lines := maxi(1, int(round(float(line_count) * starting_ratio)))
	for i in range(initial_drips):
		_add_drip()
	for i in range(initial_lines):
		_add_line()

func _add_new_painting_strokes() -> void:
	_paint_elapsed_time += paint_interval
	var intensity := _get_paint_intensity()
	var max_drips_now := maxi(1, int(round(lerpf(2.0, 6.0, intensity))))
	var max_lines_now := maxi(1, int(round(lerpf(1.0, 4.0, intensity))))
	for i in range(rng.randi_range(1, max_drips_now)):
		_add_drip()
	for i in range(rng.randi_range(1, max_lines_now)):
		_add_line()
	_update_texture()

func _get_paint_intensity() -> float:
	if paint_buildup_duration <= 0.0:
		return 1.0
	return clampf(_paint_elapsed_time / paint_buildup_duration, 0.0, 1.0)

func _add_drip() -> void:
	var pos := Vector2(rng.randf_range(0, canvas_size.x), rng.randf_range(0, canvas_size.y))
	var color: Color = colors[rng.randi() % colors.size()]
	var sz := rng.randf_range(min_drip_size, max_drip_size)
	_paint_circle(pos, sz, color)
	if rng.randf() < splatter_chance:
		var splatter_count := rng.randi_range(1, max_splatter_count)
		for j in range(splatter_count):
			var direction := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
			var distance := rng.randf_range(sz, sz * 4)
			var splatter_pos := pos + direction * distance
			var splatter_size := sz * rng.randf_range(0.1, 0.5)
			_paint_circle(splatter_pos, splatter_size, color)

func _add_line() -> void:
	var start_pos := Vector2(rng.randf_range(0, canvas_size.x), rng.randf_range(0, canvas_size.y))
	var color: Color = colors[rng.randi() % colors.size()]
	var lw := rng.randf_range(min_line_width, max_line_width)
	var points: Array = [start_pos]
	var direction := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
	var point_count := rng.randi_range(min_line_points, max_line_points)

	for i in range(point_count):
		direction = direction.rotated(rng.randf_range(-line_curviness, line_curviness)).normalized()
		var next_pos: Vector2 = points[-1] + direction * line_segment_length
		if next_pos.x < 0 or next_pos.x >= canvas_size.x or next_pos.y < 0 or next_pos.y >= canvas_size.y:
			if next_pos.x < 0 or next_pos.x >= canvas_size.x:
				direction.x *= -1
			if next_pos.y < 0 or next_pos.y >= canvas_size.y:
				direction.y *= -1
			next_pos = points[-1] + direction * line_segment_length
			if next_pos.x < 0 or next_pos.x >= canvas_size.x or next_pos.y < 0 or next_pos.y >= canvas_size.y:
				break
		points.append(next_pos)
		if rng.randf() < 0.1:
			_paint_circle(next_pos, lw * rng.randf_range(1.0, 3.0), color)

	for i in range(1, points.size()):
		_paint_line(points[i - 1], points[i], color, lw)

	_emit_stroke_path(points, color, lw)

func _paint_circle(center: Vector2, radius: float, color: Color) -> void:
	if center.x < 0 or center.x >= canvas_size.x or center.y < 0 or center.y >= canvas_size.y:
		return
	var x_min := int(max(0, center.x - radius - 1))
	var x_max := int(min(canvas_size.x - 1, center.x + radius + 1))
	var y_min := int(max(0, center.y - radius - 1))
	var y_max := int(min(canvas_size.y - 1, center.y + radius + 1))
	for x in range(x_min, x_max + 1):
		for y in range(y_min, y_max + 1):
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius:
				if dist > radius * 0.8 and rng.randf() < 0.5:
					continue
				canvas.set_pixel(x, y, color)

func _paint_line(from: Vector2, to: Vector2, color: Color, line_width: float) -> void:
	var direction := (to - from).normalized()
	var length := from.distance_to(to)
	var step_size := line_width * 0.5
	var steps := maxi(2, int(length / step_size))
	for i in range(steps + 1):
		var t := float(i) / steps
		var pos := from.lerp(to, t)
		var fade := 0.7 if (i == 0 or i == steps) else 1.0
		var adjusted_width := line_width * fade * rng.randf_range(0.8, 1.2)
		_paint_circle(pos, adjusted_width, color)

func _emit_stroke_path(points: Array, stroke_color: Color, stroke_width: float) -> void:
	if points.size() < 2:
		return
	var packed_path := PackedVector2Array()
	for p in points:
		if p is Vector2:
			packed_path.append(p)
	if packed_path.size() < 2:
		return
	var duration := clampf(float(packed_path.size()) * 0.03, 0.25, 2.4)
	emit_signal("stroke_path_generated", packed_path, stroke_color, stroke_width, duration)

## Repaint the canvas from a fixed seed, for the DNA sweep.
##
## THE HOOK WITHOUT A RECEIVER. pollock_painting_in_3d calls
## `_paint_2d.call("repaint_with_seed", paint_seed)` behind a has_method() guard, and
## until now nothing here answered it — the guard held, the call silently did nothing,
## and four `support` variants would have been four different paintings. That turns an
## axis about where the canvas LIES into a measurement of the paint.
##
## Nothing calls this unless the host's paint_seed is non-zero, and that defaults to 0,
## so _ready's rng.randomize() and a fresh painting per launch are untouched in the
## rooms this already stands in.
func repaint_with_seed(new_seed: int) -> void:
	if canvas == null:
		return
	rng.seed = new_seed
	canvas.fill(background_color)
	_create_initial_painting()
	_update_texture()

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
