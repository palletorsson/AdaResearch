# @identity
# essence: drip(t) = position(random_walk) + color(random) + width(random) — action painting as algorithm
# desire: watch a brush cursor trace Pollock-style drip paths across a floor canvas in real time
# critical_parameter: simulate_brush_motion — when true, the 3D brush follows 2D stroke paths from the SubViewport
# triggers: stroke_path_generated signal from PollockPainting2D drives brush tween across canvas surface
# emerges: layered strokes create depth and complexity — the painting is never finished, only accumulated
# needs: SubViewport for 2D painting [has]; Sprite3D projection [has]; VR proximity viewing [has]
# relationships: feeds Randomness_Examples_of_Randomness map; contrasts with monte_carlo_dartboard (aesthetic vs computational randomness)
# truth: A Pollock painting is not random — it is the trace of a body moving through a random field with intention.
# history: a grid-map work (Randomness_Examples_of_Randomness); the support axis put the canvas back on the floor.
#   2026-11-12, read as code: the truth above names a body, and the only body was a cursor. Where a room asks
#   (body_paints), a visitor who walks on the floor canvas leaves the black line: the path is theirs, and chance
#   decides how wide it runs, how far it wobbles and whether it throws drops. Off by default. The same day Palle:
#   "make the player paint with an open bucket standing along the very very large canvas" - with `buckets`, open
#   tins stand in a row on the canvas; a body takes one by walking up to it and pours that colour as it walks.
# lineage: ART - Jackson Pollock, 1947 on: the canvas on the studio floor, paint poured from above while walking
#   round it; Hans Namuth's 1950 film through glass; Yves Klein's body prints; Janine Antoni's Loving Care (1993),
#   a floor painted with the body. MATH - a path integral: the mark is a sum along where the body went.

extends Node3D

@export_group("Display")
@export var pixel_size: float = 0.0035
@export var frame_margin: float = 0.14
@export var frame_depth: float = 0.02
@export var frame_color: Color = Color(0.12, 0.09, 0.06, 1.0)
@export var backing_color: Color = Color(0.88, 0.85, 0.78, 1.0)
@export var place_on_floor: bool = true
@export var floor_height: float = 0.02

@export_group("Brush")
@export var simulate_brush_motion: bool = true
@export var brush_radius: float = 0.045
@export var brush_hover_height: float = 0.055

# DNA — support. Pollock's break was not a mark, it was a POSTURE: the canvas came off
# the easel and went on the studio floor, and the body walked around a thing it could
# no longer face. This artifact shipped that decision as a hard-coded `place_on_floor`
# rotation of (-90, 180, 0) at y = 0.02 and nothing else. The axis restores the ladder
# the drip argued against — the floor the body stands over, the table it leans across,
# the easel it was supposed to sit at, the wall the finished picture ends up on.
# `floor` is the shipped value in every respect, down to the same two numbers.
@export_group("Support")
## The allow-list apply_grid_config validates a map token against. Kept identical to the
## @export_enum above and to the registry's dna.axes.support — the three lists are the
## same list, and a value that appears in only two of them is the science_screen fault.
const SUPPORTS := ["floor", "table", "easel", "wall"]
@export_enum("floor", "table", "easel", "wall") var support: String = "floor"
@export var table_height: float = 0.78
@export var easel_lean_degrees: float = 18.0
@export var easel_center_height: float = 1.45
@export var wall_center_height: float = 1.65

# 0 means "leave the 2D painter alone", which is what shipped: paint_dripping_2d calls
# rng.randomize() and every boot is a different painting. That is correct in a room and
# ruinous in a sweep, where four postures would also be four different paintings and the
# measurement would be about the paint. A non-zero seed repaints the canvas once,
# deterministically, so the frames differ only in the axis. Set from dna.fixture.
@export var paint_seed: int = 0
## A room may ask for this (the Void, 2026-11-12): on the floor support, a body walking on the canvas is the brush.
@export var body_paints: bool = false
@export var body_color: Color = Color(0.05, 0.045, 0.05, 1.0)
## How many open buckets stand along the canvas. With buckets, a body paints only while it carries one.
@export_range(0, 8) var buckets: int = 0
## Pollock's own tins: black enamel, white, aluminium, ochre, red-brown, teal.
const BUCKET_COLOURS := [Color(0.05, 0.045, 0.05), Color(0.95, 0.94, 0.9), Color(0.62, 0.63, 0.65), Color(0.83, 0.62, 0.16), Color(0.52, 0.17, 0.1), Color(0.07, 0.36, 0.42)]
var _buckets: Array = []
var _body_area: Area3D = null
var _body_last := {}
var _body_clock := 0.0

@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var sub_viewport: SubViewport = $SubViewport

var _paint_2d: Node = null
var _brush_cursor: MeshInstance3D = null
var _brush_tween: Tween = null
var _built: bool = false


func _ready() -> void:
	if has_meta("config_pixel_size"): pixel_size = maxf(0.001, float(str(get_meta("config_pixel_size"))))
	if has_meta("config_body_paints"): body_paints = str(get_meta("config_body_paints")).to_lower() in ["true", "1", "yes"]
	if has_meta("config_buckets"): buckets = clampi(int(str(get_meta("config_buckets")).to_float()), 0, 8)
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await get_tree().process_frame

	_paint_2d = sub_viewport.get_node_or_null("PollockPainting2D")
	_apply_paint_seed()

	_configure_support_layout()
	sprite_3d.texture = sub_viewport.get_texture()
	sprite_3d.pixel_size = pixel_size
	_setup_sprite_material()
	_create_frame_panels()
	_connect_stroke_signal()
	_create_brush_cursor()
	if body_paints and support == "floor":
		_watch_bodies()
	_built = true


## The canvas as a place a body can be on.
func _watch_bodies() -> void:
	var content := Vector2(sub_viewport.size.x, sub_viewport.size.y) * pixel_size
	_body_area = Area3D.new()
	_body_area.name = "CanvasBodies"
	_body_area.collision_layer = 0
	_body_area.collision_mask = 0xFFFFFFFF
	_body_area.position = Vector3(sprite_3d.position.x, 1.0, sprite_3d.position.z)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(content.x, 2.0, content.y)
	shape.shape = box
	_body_area.add_child(shape)
	add_child(_body_area)
	if buckets > 0:
		_stand_buckets(content)


## OPEN BUCKETS, standing in a row along the canvas (Palle, 2026-11-12: "make the player paint with an open bucket
## standing along the very very large canvas"). A body that walks up to one takes it; from then on its walk pours
## that colour. Walking up to another swaps them. No bucket, no paint.
func _stand_buckets(content: Vector2) -> void:
	var row_z: float = content.y / 2.0 - 2.6
	var reach: float = content.x / 2.0 - 1.2
	for n in buckets:
		var t: float = (n + 0.5) / float(buckets)
		var x: float = lerpf(-reach, reach, t)
		if absf(x) < 0.9: x = signf(x if x != 0.0 else 1.0) * 0.9      # the way straight ahead stays clear
		var colour: Color = BUCKET_COLOURS[n % BUCKET_COLOURS.size()]
		var bucket := Node3D.new()
		bucket.name = "Bucket_%d" % n
		bucket.position = Vector3(sprite_3d.position.x + x, floor_height, sprite_3d.position.z + row_z)
		add_child(bucket)
		var shell := MeshInstance3D.new()
		var pail := CylinderMesh.new()
		pail.top_radius = 0.17
		pail.bottom_radius = 0.135
		pail.height = 0.3
		pail.cap_top = false
		pail.radial_segments = 20
		shell.mesh = pail
		shell.position.y = 0.15
		var tin := StandardMaterial3D.new()
		tin.albedo_color = Color(0.82, 0.83, 0.82)
		tin.metallic = 0.6
		tin.roughness = 0.42
		tin.cull_mode = BaseMaterial3D.CULL_DISABLED
		shell.material_override = tin
		bucket.add_child(shell)
		var paint := MeshInstance3D.new()
		var surface := CylinderMesh.new()
		surface.top_radius = 0.158
		surface.bottom_radius = 0.158
		surface.height = 0.012
		surface.radial_segments = 20
		paint.mesh = surface
		paint.position.y = 0.245
		paint.material_override = _paint_material(colour)
		bucket.add_child(paint)
		var stream := MeshInstance3D.new()
		stream.name = "Stream"
		var thread := CylinderMesh.new()
		thread.top_radius = 0.012
		thread.bottom_radius = 0.02
		thread.height = 0.55
		thread.radial_segments = 8
		stream.mesh = thread
		stream.position = Vector3(0, -0.27, 0.17)
		stream.material_override = _paint_material(colour)
		stream.visible = false
		bucket.add_child(stream)
		var pick := Area3D.new()
		pick.name = "Pick"
		pick.collision_layer = 0
		pick.collision_mask = 0xFFFFFFFF
		pick.position.y = 0.4
		var ball := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 0.5
		ball.shape = sphere
		pick.add_child(ball)
		bucket.add_child(pick)
		pick.body_entered.connect(_take.bind(n))
		_buckets.append({"node": bucket, "home": bucket.position, "colour": colour, "stream": stream, "held_by": 0})


func _paint_material(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.25
	mat.metallic = 0.1
	return mat


func _take(body: Node, index: int) -> void:
	if not body is CharacterBody3D:
		return
	var id := body.get_instance_id()
	if int(_buckets[index].held_by) == id:
		return
	for b in _buckets:      # the one this body carried goes back to its place
		if int(b.held_by) == id:
			_set_down(b)
	_buckets[index].held_by = id
	_body_last.erase(id)


func _set_down(bucket: Dictionary) -> void:
	bucket.held_by = 0
	(bucket.node as Node3D).position = bucket.home
	(bucket.node as Node3D).rotation = Vector3.ZERO
	(bucket.stream as Node3D).visible = false


## Which bucket a body carries, and where it stands - for probes.
func bucket_state() -> Array:
	var out := []
	for b in _buckets:
		out.append({"held": int(b.held_by) != 0, "at": (b.node as Node3D).global_position, "home": to_global(b.home), "colour": b.colour})
	return out


## The inverse of _canvas_pixel_to_world, for a point on the floor.
func world_to_canvas_pixel(world: Vector3) -> Vector2:
	var local := sprite_3d.to_local(world)
	return Vector2(float(sub_viewport.size.x) * 0.5 + local.x / pixel_size, float(sub_viewport.size.y) * 0.5 - local.y / pixel_size)


func _physics_process(delta: float) -> void:
	if _body_area == null or _paint_2d == null or not _paint_2d.has_method("paint_trace"):
		return
	_body_clock += delta
	var due: bool = _body_clock >= 0.09
	var on_canvas := {}
	for body in _body_area.get_overlapping_bodies():
		if body is CharacterBody3D:
			on_canvas[body.get_instance_id()] = body
	if buckets > 0:
		for b in _buckets:
			var id: int = int(b.held_by)
			if id == 0:
				continue
			var who := instance_from_id(id) as Node3D
			if who == null or who.global_position.distance_to(global_position) > 40.0:
				_set_down(b)
				continue
			# the open bucket rides at the hip, tipped forward: it pours as its bearer walks
			var basis := who.global_transform.basis
			var node := b.node as Node3D
			node.global_position = who.global_position + basis.x * 0.38 - basis.z * 0.28 + Vector3(0, 0.55, 0)
			node.global_rotation = Vector3(deg_to_rad(-24.0), who.global_rotation.y, 0)
			var pour := node.global_position - basis.z * 0.17
			var px := world_to_canvas_pixel(pour)
			var moving := false
			if on_canvas.has(id) and due:
				if _body_last.has(id):
					var gone: float = (_body_last[id] as Vector2).distance_to(px)
					if gone > 1.5:
						moving = true
						_paint_2d.call("paint_trace", _body_last[id], px, gone * pixel_size / _body_clock, b.colour, 0.058 / pixel_size, 0.023 / pixel_size)
						_body_last[id] = px
				else:
					_body_last[id] = px
				(b.stream as Node3D).visible = moving
			elif not on_canvas.has(id):
				_body_last.erase(id)
				(b.stream as Node3D).visible = false
	elif due:
		for id in on_canvas:
			var px := world_to_canvas_pixel((on_canvas[id] as Node3D).global_position)
			if _body_last.has(id):
				var gone: float = (_body_last[id] as Vector2).distance_to(px)
				if gone > 2.0:
					_paint_2d.call("paint_trace", _body_last[id], px, gone * pixel_size / _body_clock, body_color)
					_body_last[id] = px
			else:
				_body_last[id] = px
		for id in _body_last.keys():
			if not on_canvas.has(id):
				_body_last.erase(id)
	if due:
		_body_clock = 0.0


func _setup_sprite_material() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_texture = sub_viewport.get_texture()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	sprite_3d.material_override = material


func _configure_support_layout() -> void:
	# The shipped escape hatch, untouched: place_on_floor = false left the Sprite3D on
	# whatever transform the scene gave it. It still does, as long as nobody asked for a
	# different support — the two flags only meet on the default value.
	if support == "floor" and not place_on_floor:
		return

	var tilt: float = -90.0
	var height: float = floor_height
	match support:
		"floor":
			tilt = -90.0
			height = floor_height
		"table":
			tilt = -90.0
			height = table_height
		"easel":
			tilt = -easel_lean_degrees
			height = easel_center_height
		"wall":
			tilt = 0.0
			height = wall_center_height

	sprite_3d.rotation_degrees = Vector3(tilt, 180.0, 0.0)
	sprite_3d.position = Vector3(0.0, height, 0.0)


func _apply_paint_seed() -> void:
	if paint_seed == 0 or _paint_2d == null:
		return
	if _paint_2d.has_method("repaint_with_seed"):
		_paint_2d.call("repaint_with_seed", paint_seed)


func _create_frame_panels() -> void:
	var content_size := Vector2(sub_viewport.size.x, sub_viewport.size.y) * pixel_size

	var backing := MeshInstance3D.new()
	backing.name = "BackingPanel"
	var backing_mesh := QuadMesh.new()
	backing_mesh.size = content_size + Vector2(frame_margin * 0.45, frame_margin * 0.45)
	backing.mesh = backing_mesh
	backing.transform = sprite_3d.transform
	backing.translate_object_local(Vector3(0.0, 0.0, -frame_depth - 0.001))
	backing.material_override = _panel_material(backing_color)
	add_child(backing)

	var frame := MeshInstance3D.new()
	frame.name = "FramePanel"
	var frame_mesh := QuadMesh.new()
	frame_mesh.size = content_size + Vector2(frame_margin, frame_margin)
	frame.mesh = frame_mesh
	frame.transform = sprite_3d.transform
	frame.translate_object_local(Vector3(0.0, 0.0, -frame_depth * 0.45))
	frame.material_override = _panel_material(frame_color)
	add_child(frame)


func _panel_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mat.metallic = 0.12
	return mat


func _connect_stroke_signal() -> void:
	if not simulate_brush_motion:
		return
	_paint_2d = sub_viewport.get_node_or_null("PollockPainting2D")
	if _paint_2d and _paint_2d.has_signal("stroke_path_generated"):
		_paint_2d.connect("stroke_path_generated", Callable(self, "_on_stroke_path_generated"))


func _create_brush_cursor() -> void:
	if not simulate_brush_motion:
		return

	_brush_cursor = MeshInstance3D.new()
	_brush_cursor.name = "BrushCursor"

	var mesh := SphereMesh.new()
	mesh.radius = brush_radius
	mesh.height = brush_radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	_brush_cursor.mesh = mesh
	_brush_cursor.material_override = _brush_material(Color(0.2, 0.13, 0.07, 1.0))

	add_child(_brush_cursor)
	_brush_cursor.global_position = _canvas_pixel_to_world(
		Vector2(sub_viewport.size.x * 0.5, sub_viewport.size.y * 0.5),
		brush_hover_height
	)


func _brush_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.25
	mat.roughness = 0.45
	mat.emission_enabled = true
	mat.emission = color.lightened(0.2)
	mat.emission_energy_multiplier = 0.45
	return mat


func _on_stroke_path_generated(path: PackedVector2Array, stroke_color: Color, stroke_width: float, duration: float) -> void:
	if not simulate_brush_motion or _brush_cursor == null:
		return
	if path.size() < 2:
		return

	var brush_mat := _brush_cursor.material_override as StandardMaterial3D
	if brush_mat:
		brush_mat.albedo_color = stroke_color.darkened(0.2)
		brush_mat.emission = stroke_color
		brush_mat.emission_energy_multiplier = 0.7

	if _brush_tween and _brush_tween.is_running():
		_brush_tween.kill()

	var step_count: int = maxi(1, path.size() - 1)
	var step_duration: float = maxf(0.03, duration / float(step_count))
	_brush_tween = create_tween()
	_brush_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var hover: float = brush_hover_height + minf(stroke_width * 0.0015, 0.02)
	for point in path:
		var target_world := _canvas_pixel_to_world(point, hover)
		_brush_tween.tween_property(_brush_cursor, "global_position", target_world, step_duration)


func _canvas_pixel_to_world(pixel: Vector2, height_offset: float) -> Vector3:
	var width: float = float(sub_viewport.size.x)
	var height: float = float(sub_viewport.size.y)
	var half_w: float = width * 0.5
	var half_h: float = height * 0.5

	var local_x: float = (pixel.x - half_w) * pixel_size
	var local_y: float = (half_h - pixel.y) * pixel_size
	return sprite_3d.to_global(Vector3(local_x, local_y, height_offset))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Only ever restages when a value BOTH validates AND differs from what is already
## standing, and never before _ready has built once. The three shipped placements pass
## neither key, so nothing in them re-runs.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return

	var changed: bool = false

	if config.has("support"):
		var want: String = String(config["support"]).to_lower().strip_edges()
		if want in SUPPORTS and want != support:
			support = want
			changed = true

	if config.has("paint_seed"):
		var want_seed: int = int(config["paint_seed"])
		if want_seed != paint_seed:
			paint_seed = want_seed
			changed = true
			_apply_paint_seed()

	if changed and _built and is_inside_tree():
		_restage()


## Re-run the parts of _ready that depend on the support. The frame and backing panels
## copy sprite_3d.transform at build time, so moving the canvas without rebuilding them
## would leave the picture and its frame in two different rooms.
func _restage() -> void:
	_configure_support_layout()
	# remove_child BEFORE queue_free: a queued node is still a child until the end of
	# the frame, so _create_frame_panels would add a second "BackingPanel", Godot would
	# rename it, and the NEXT restage would no longer recognise it — one orphan panel
	# per switch, each in the posture it was built for.
	for child in get_children():
		if child is MeshInstance3D and child.name in ["BackingPanel", "FramePanel"]:
			remove_child(child)
			child.queue_free()
	_create_frame_panels()
	if _brush_cursor != null:
		if _brush_tween and _brush_tween.is_running():
			_brush_tween.kill()
		_brush_cursor.global_position = _canvas_pixel_to_world(
			Vector2(sub_viewport.size.x * 0.5, sub_viewport.size.y * 0.5),
			brush_hover_height
		)
