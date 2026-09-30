extends "res://commons/primitives/cubes/grab_cube.gd"
## A held, triggered nozzle deposits bounded, distance-sensitive aerosol stamps.
@export var ink: Color = Color("ed368c")
@export var max_distance: float = 3.0
var _paint_home := Transform3D.IDENTITY
var _pressed := false
var _desktop_held := false
var painted_samples := 0
var paper_surface: MeshInstance3D
var last_uv_position := Vector2(-1, -1)
var last_radius_m := 0.0
var nozzle: Node3D
var mist: CPUParticles3D
var is_painting := false
var is_spraying := false
var hiss: AudioStreamPlayer3D
var _stroke_origin := Vector3.ZERO
var _stroke_direction := Vector3.FORWARD
var _stroke_hit := Vector3.ZERO
var _stroke_surface: MeshInstance3D
var _sample_seed := 0
static var _hiss_stream: AudioStreamWAV
const MAX_SWEEP_SAMPLES := 12

static func cylinder(parent: Node3D, label: String, radius: float, height: float, y: float, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = label
	var shape := CylinderMesh.new()
	shape.top_radius = radius; shape.bottom_radius = radius; shape.height = height
	shape.radial_segments = 32
	part.mesh = shape; part.material_override = material; part.position.y = y
	parent.add_child(part)
	return part

static func material(colour: Color, metal: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour; mat.metallic = metal; mat.roughness = 0.32
	return mat

static func build_visuals(parent: Node3D, colour: Color) -> MeshInstance3D:
	var silver := material(Color("aeb5bd"), 0.75)
	var pigment := material(colour)
	var body := cylinder(parent, "MeshInstance3D", 0.056, 0.24, 0.0, pigment)
	cylinder(parent, "BottomRim", 0.058, 0.014, -0.115, silver)
	cylinder(parent, "Shoulder", 0.045, 0.03, 0.13, silver)
	cylinder(parent, "TopRim", 0.057, 0.012, 0.12, silver)
	cylinder(parent, "PaperBand", 0.0565, 0.065, -0.035, material(Color("ece8df")))
	var cap := cylinder(parent, "NozzleButton", 0.022, 0.035, 0.16, material(Color("202127")))
	var hole := cylinder(cap, "Orifice", 0.009, 0.01, 0.0, pigment)
	hole.rotation_degrees.x = 90.0; hole.position = Vector3(0, 0, -0.023)
	var label := Label3D.new()
	label.name = "CanLabel"; label.text = "SPRAY"; label.font_size = 28; label.pixel_size = 0.0006
	label.outline_size = 0; label.modulate = Color("262830"); label.position = Vector3(0, -0.035, 0.057)
	parent.add_child(label)
	return body

func _ready() -> void:
	freeze = true; snap_to_shelf = false; collision_layer = 3; collision_mask = 1
	build_visuals(self, ink)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new(); capsule.radius = 0.06; capsule.height = 0.30
	shape.shape = capsule; shape.position.y = 0.02; add_child(shape)
	nozzle = Node3D.new(); nozzle.name = "Nozzle"; nozzle.position = Vector3(0, 0.16, -0.03); add_child(nozzle)
	_build_mist()
	_build_hiss()
	super._ready()
	_paint_home = global_transform
	action_pressed.connect(_on_action_pressed)
	action_released.connect(_on_action_released)

func _build_mist() -> void:
	mist = CPUParticles3D.new(); mist.name = "Aerosol"; mist.emitting = false
	mist.amount = 96; mist.lifetime = 0.22; mist.local_coords = false
	mist.direction = Vector3.FORWARD; mist.spread = 8.0; mist.gravity = Vector3(0, -0.08, 0)
	mist.initial_velocity_min = 3.0; mist.initial_velocity_max = 4.0
	mist.scale_amount_min = 0.5; mist.scale_amount_max = 1.5
	var quad := QuadMesh.new(); quad.size = Vector2(0.012, 0.012)
	var mat := material(Color(ink, 0.28)); mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	var gradient := Gradient.new(); gradient.set_color(0, Color.WHITE); gradient.set_color(1, Color(1,1,1,0))
	var texture := GradientTexture2D.new(); texture.gradient = gradient; texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5,0.5); texture.fill_to = Vector2(1,0.5); texture.width = 32; texture.height = 32
	mat.albedo_texture = texture; quad.material = mat; mist.mesh = quad
	nozzle.add_child(mist)

func _on_action_pressed(_object) -> void:
	_pressed = true

func _on_action_released(_object) -> void:
	_pressed = false
	_stop_spray()

func _on_dropped(object) -> void:
	_pressed = false; _stop_spray()
	super._on_dropped(object)
	_return_to_dock.call_deferred()

func _return_to_dock() -> void:
	if is_picked_up() or _desktop_held: return
	freeze = true; linear_velocity = Vector3.ZERO; angular_velocity = Vector3.ZERO
	global_transform = _paint_home

func on_desktop_grab(_pointer: Node) -> void:
	_desktop_held = true
	_pressed = false

func on_desktop_drop(_pointer: Node) -> void:
	_desktop_held = false
	_pressed = false
	_stop_spray()
	_return_to_dock.call_deferred()

func _build_hiss() -> void:
	# A quiet, shared loop: thirty parked cans do not synthesize thirty sounds.
	if _hiss_stream == null:
		_hiss_stream = AudioStreamWAV.new()
		_hiss_stream.mix_rate = 22050
		_hiss_stream.format = AudioStreamWAV.FORMAT_16_BITS
		_hiss_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_hiss_stream.loop_end = 11025
		var data := PackedByteArray(); data.resize(11025 * 2)
		var rng := RandomNumberGenerator.new(); rng.seed = 73119
		var low := 0.0
		for i in 11025:
			var white := rng.randf_range(-1.0, 1.0)
			low = lerpf(low, white, 0.18)
			data.encode_s16(i * 2, int((white - low) * 11000.0))
		_hiss_stream.data = data
	hiss = AudioStreamPlayer3D.new(); hiss.name = "NozzleHiss"
	hiss.stream = _hiss_stream; hiss.max_distance = 7.0; hiss.unit_size = 1.0
	hiss.volume_db = -24.0; nozzle.add_child(hiss)

func _break_stroke() -> void:
	is_painting = false; last_uv_position = Vector2(-1, -1)
	_stroke_surface = null

func _stop_spray() -> void:
	_break_stroke(); is_spraying = false
	if is_instance_valid(mist): mist.emitting = false
	if is_instance_valid(hiss): hiss.stop()
	if is_instance_valid(nozzle):
		nozzle.position.y = 0.16
		get_node("NozzleButton").position.y = 0.16

func _sample_nozzle(origin: Vector3, direction: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * max_distance, 1, [get_rid()])
	query.collide_with_areas = true
	var collision := get_world_3d().direct_space_state.intersect_ray(query)
	if collision.is_empty(): return {}
	var receiver := collision.collider as Node3D
	if not is_instance_valid(receiver) or not receiver.is_in_group("drawing_area"): return {}
	var surface := receiver.get_node_or_null("PaperDrawSurface") as MeshInstance3D
	if not is_instance_valid(surface) or not surface.has_method("draw_spray"): return {}
	var normal := surface.global_basis.y.normalized()
	if -direction.dot(normal) < 0.22: return {}
	# Hit the visible plane, not the surrounding Area's thickness.
	var distance := normal.dot(surface.global_position - origin) / normal.dot(direction)
	if distance < 0.025 or distance > max_distance: return {}
	var hit := origin + direction * distance
	var uv: Vector2 = surface.get_uv_from_world_pos(hit)
	if uv.x < 0 or uv.x > 1 or uv.y < 0 or uv.y > 1: return {}
	return {"surface": surface, "hit": hit, "uv": uv, "distance": distance}

func _physics_process(delta: float) -> void:
	if not (is_picked_up() or _desktop_held) or not _pressed:
		_stop_spray(); return
	var pressure := 1.0
	if is_instance_valid(_current_controller):
		pressure = clampf(_current_controller.get_float("trigger"), 0.0, 1.0)
	if pressure <= 0.02:
		_stop_spray(); return
	# The valve releases aerosol even when no paintable surface receives it.
	is_spraying = true; mist.emitting = true
	nozzle.position.y = 0.16 - 0.004 * pressure
	get_node("NozzleButton").position.y = nozzle.position.y
	hiss.volume_db = -30.0 + 8.0 * pressure
	if not hiss.playing: hiss.play()
	var origin := nozzle.global_position
	var direction := -nozzle.global_basis.z.normalized()
	var sample := _sample_nozzle(origin, direction)
	if sample.is_empty():
		mist.lifetime = 0.22
		_break_stroke(); return
	var surface: MeshInstance3D = sample.surface
	var hit: Vector3 = sample.hit
	last_radius_m = 0.012 + float(sample.distance) * tan(deg_to_rad(7.0))
	mist.lifetime = clampf(float(sample.distance) / 4.0, 0.035, 0.22)
	# Spread one tick's pigment across the swept path. Extra samples must not
	# multiply its quantity. Teleports, release and lost targets break the path.
	var steps := 1
	if _stroke_surface == surface and _stroke_hit.distance_to(hit) < 0.6 and _stroke_direction.dot(direction) > 0.94:
		steps = clampi(ceili(_stroke_hit.distance_to(hit) / maxf(last_radius_m * 0.45, 0.008)), 1, MAX_SWEEP_SAMPLES)
	for i in steps:
		var fraction := float(i + 1) / steps
		var ray_direction := direction
		var deposit := sample
		if steps > 1:
			ray_direction = _stroke_direction.lerp(direction, fraction).normalized()
			# Test every intermediate ray too: a fast stroke cannot paint through
			# an obstruction just because both endpoint rays find the canvas.
			deposit = _sample_nozzle(_stroke_origin.lerp(origin, fraction), ray_direction)
			if deposit.is_empty() or deposit.surface != surface: continue
		var radius := 0.012 + float(deposit.distance) * tan(deg_to_rad(7.0))
		var density := clampf(pow(0.09 / radius, 2.0), 0.06, 4.0)
		var opacity := 1.0 - exp(-8.0 * pressure * density * minf(delta, 0.05) / steps)
		surface.draw_spray(deposit.hit, ray_direction, radius, ink, opacity, _sample_seed)
		_sample_seed += 1
	paper_surface = surface; last_uv_position = sample.uv
	_stroke_origin = origin; _stroke_direction = direction; _stroke_hit = hit; _stroke_surface = surface
	painted_samples += 1; is_painting = true
