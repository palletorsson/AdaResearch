extends Node3D
const PointBody = preload("point_body.gd")
const FRACTIONS := [0.25, 1.0 / 3.0, 0.4]
const LIMIT := 5
const DISPLAY_SCALE := 0.34
var recipe := {"seed": Vector2(0, 6), "fraction": 1.0 / 3.0, "steps": 4}
var kept_recipe: Dictionary = {}
var live: Array[Vector2] = []
var kept: Array[Vector2] = []
var point: XRToolsPickable
var drawing: Node3D
var live_caption: Label3D
var kept_caption: Label3D

func _ready() -> void:
	drawing = Node3D.new()
	add_child(drawing)
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(keep_current)
	live_caption = label("", Vector3(0, 1.40, 0))
	kept_caption = label("", Vector3(0, 1.79, 0))
	label("CHANGE ONE RULE / KEEP A COMPARISON", Vector3(0, 2.02, 0))
	for i in 3:
		label(["1/4", "1/3", "2/5"][i], Vector3((i - 1) * 0.35, 1.0, 0.55))
	kept_recipe = recipe.duplicate(true)
	rebuild()
	park()

func replace_intervals(intervals: Array[Vector2], fraction: float) -> Array[Vector2]:
	assert(fraction > 0.0 and fraction < 0.5)
	var next: Array[Vector2] = []
	for interval in intervals:
		var size := interval.y * fraction
		next.append(Vector2(interval.x, size))
		next.append(Vector2(interval.x + interval.y - size, size))
	return next

func build(settings: Dictionary) -> Array[Vector2]:
	assert(settings.steps >= 0 and settings.steps <= LIMIT)
	var intervals: Array[Vector2] = [settings.seed]
	for generation in range(settings.steps):
		intervals = replace_intervals(intervals, settings.fraction)
	return intervals

func rebuild() -> void:
	live = build(recipe)
	kept = build(kept_recipe)
	redraw()

func choose(index: int) -> void:
	var fraction: float = FRACTIONS[clampi(index, 0, 2)]
	if is_equal_approx(recipe.fraction, fraction):
		return
	recipe.fraction = fraction
	rebuild()

func keep_current(_body = null) -> void:
	kept_recipe = recipe.duplicate(true)
	rebuild()

func restore() -> void:
	if point.held():
		return
	recipe = kept_recipe.duplicate(true)
	rebuild()

func advance() -> void:
	if point.held():
		return
	recipe.steps = mini(recipe.steps + 1, LIMIT)
	rebuild()

func reset_live() -> void:
	if point.held():
		return
	recipe = {"seed": Vector2(0, 6), "fraction": 1.0 / 3.0, "steps": 3}
	rebuild()

func _physics_process(_dt: float) -> void:
	if point.held():
		var local := to_local(point.global_position)
		choose(clampi(roundi(local.x / 0.35) + 1, 0, 2))
	else:
		park()

func park() -> void:
	var index: int = FRACTIONS.find(recipe.fraction)
	var home := Vector3((index - 1) * 0.35, 1.15, 0.55)
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, home)

func _process(_dt: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		keep_current()

func total(intervals: Array[Vector2]) -> float:
	var length := 0.0
	for interval in intervals:
		length += interval.y
	return length

func redraw() -> void:
	for child in drawing.get_children():
		drawing.remove_child(child)
		child.queue_free()
	draw_row(live, 1.27, Color("28252c"))
	draw_row(kept, 1.66, Color("e99db8"))
	live_caption.text = describe("LIVE", recipe, live)
	kept_caption.text = describe("KEPT", kept_recipe, kept)

func describe(title: String, settings: Dictionary, intervals: Array[Vector2]) -> String:
	return "%s / %d cuts / %.1f%% at each end / %d pieces / %.3f m" % [title, settings.steps, settings.fraction * 100, intervals.size(), total(intervals)]

func draw_row(intervals: Array[Vector2], y: float, colour: Color) -> void:
	for interval in intervals:
		var surface := MeshInstance3D.new()
		var shape := BoxMesh.new()
		shape.size = Vector3(interval.y * DISPLAY_SCALE, 0.045, 0.06)
		surface.mesh = shape
		surface.position = Vector3((interval.x + interval.y * 0.5 - 3) * DISPLAY_SCALE, y, 0)
		var finish := StandardMaterial3D.new()
		finish.albedo_color = colour
		surface.material_override = finish
		drawing.add_child(surface)

func label(text: String, at: Vector3) -> Label3D:
	var tag := Label3D.new()
	tag.text = text
	tag.position = at
	tag.font_size = 36
	tag.pixel_size = 0.0016
	tag.outline_size = 7
	add_child(tag)
	return tag
