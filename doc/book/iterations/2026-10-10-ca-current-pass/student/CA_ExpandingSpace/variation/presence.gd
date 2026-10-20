extends Node3D
const PointBody = preload("point_body.gd")
const WIDTH := 5
const LENGTH := 16
const PITCH := 0.6
const RADIUS := 0.75
const DT := 0.1
const LIMIT := 300
const VIEW_SCALE := 0.2
const VIEW_ORIGIN := Vector3(0, 1.02, 0)
const W := Vector2i(2, 6)
const DIRECTIONS := [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
var current: Dictionary = {}
var materials: Dictionary = {}
var supports: Dictionary = {}
var point: XRToolsPickable
var reading := Label3D.new()
var ticks := 0
var chain := false
var synchronous := true
var backwards := false

func _ready() -> void:
	for y in LENGTH:
		for x in WIDTH:
			current[Vector2i(x, y)] = 1.0
	make_display()
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body): step())
	park()
	reset()

func cell_position(site: Vector2i) -> Vector3:
	return Vector3((site.x - 2) * PITCH, -0.1, site.y * PITCH)

func view_position(site: Vector2i) -> Vector3:
	return VIEW_ORIGIN + cell_position(site) * VIEW_SCALE

func input_position() -> Vector3:
	return (to_local(point.global_position) - VIEW_ORIGIN) / VIEW_SCALE

func neighbours(old: Dictionary, site: Vector2i) -> int:
	var count := 0
	for direction in DIRECTIONS:
		var other: Vector2i = site + direction
		if old.has(other) and old[other] > 0.5:
			count += 1
	return count

func evolve(old: Dictionary, at: Vector3, present: bool) -> Dictionary:
	var next := old.duplicate()
	var read: Dictionary = old if synchronous else next
	var order := old.keys()
	if backwards:
		order.reverse()
	for site: Vector2i in order:
		var health: float = old[site]
		if present and cell_position(site).distance_to(at) < RADIUS:
			next[site] = maxf(0.0, health - 0.08 * DT * 5.0)
		else:
			next[site] = minf(1.0, health + 1.0 * DT * 0.1 * neighbours(read, site))
	return next

func step() -> void:
	if ticks == LIMIT:
		return
	current = evolve(current, input_position(), point.held() and not chain)
	ticks += 1
	redraw()

func reset() -> void:
	ticks = 0
	for site in current:
		current[site] = 0.0 if chain else 1.0
	if chain:
		current[Vector2i(1, 6)] = 0.6
		current[W] = 0.495
	redraw()

func _physics_process(_delta: float) -> void:
	if not point.held():
		park()

func park() -> void:
	point.position = Vector3(-0.65, 1.12, 0.3)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER: step()
			KEY_R: chain = false; reset()
			KEY_C: chain = true; reset()
			KEY_O: synchronous = not synchronous; reset()
			KEY_V: backwards = not backwards; reset()
			_: return
		get_viewport().set_input_as_handled()

func box(size: Vector3, at: Vector3, colour: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	var finish := StandardMaterial3D.new()
	finish.albedo_color = colour
	node.material_override = finish
	add_child(node)
	return node

func solid(node: MeshInstance3D, size: Vector3) -> CollisionShape3D:
	var body := StaticBody3D.new()
	var boundary := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	boundary.shape = shape
	node.add_child(body)
	body.add_child(boundary)
	return boundary

func make_display() -> void:
	var tray := box(Vector3(0.72, 0.04, 2.0), Vector3(0, 0.86, 0.9), Color("354650"))
	solid(tray, Vector3(0.72, 0.04, 2.0))
	box(Vector3(0.1, 0.84, 0.1), Vector3(0, 0.42, 0.9), Color("bf9469"))
	var wall := box(Vector3(0.04, 0.38, 2), Vector3(0.55, 1.28, 0.9), Color("20373a"))
	solid(wall, Vector3(0.04, 0.38, 2))
	for site: Vector2i in current:
		var tile := box(Vector3(0.114, 0.04, 0.114), view_position(site), Color.WHITE)
		materials[site] = tile.material_override
		supports[site] = solid(tile, Vector3(0.12, 0.04, 0.12))
		var panel := box(Vector3(0.02, 0.058, 0.106), Vector3(0.52, 1.15 + site.x * 0.064, site.y * 0.12), Color.WHITE)
		panel.material_override = materials[site]
	var at := view_position(W) + Vector3.UP * 0.025
	for side in [-1, 1]:
		box(Vector3(0.124, 0.008, 0.008), at + Vector3(0, 0, side * 0.062), Color("ffd484"))
		box(Vector3(0.008, 0.008, 0.124), at + Vector3(side * 0.062, 0, 0), Color("ffd484"))
	reading.position = Vector3(0, 1.8, 0.6)
	reading.font_size = 28
	reading.pixel_size = 0.0014
	reading.modulate = Color("213639")
	reading.outline_modulate = Color("f5f0e8")
	reading.outline_size = 4
	add_child(reading)

func redraw() -> void:
	for site: Vector2i in current:
		var health: float = current[site]
		var finish: StandardMaterial3D = materials[site]
		finish.albedo_color = Color("a86c88").lerp(Color("8cd9be"), health)
		finish.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if health < 0.2 else BaseMaterial3D.TRANSPARENCY_DISABLED
		finish.albedo_color.a = 0.18 + health if health < 0.2 else 1.0
		supports[site].set_deferred("disabled", health < 0.2)
	reading.text = "W (2,6) / HEALTH %.3f / SUPPORT %s\n%s / %s / %.1f s\nTRIGGER / ENTER: STEP   R: FULL   C: CHAIN\nO: SYNC/SCAN   V: REVERSE" % [current[W], "ON" if current[W] >= 0.2 else "OFF", "SYNC" if synchronous else "SCAN", "REVERSE" if backwards else "FORWARD", ticks * DT]
