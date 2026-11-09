extends Node3D
class_name CarouselRing
## A RING AROUND A CAROUSEL, WITH A BALL YOU CAN TAKE ROUND IT (Palle, 2026-11-09, floor 17 "Carousel rotation": "add
## a torus ring to around merry go around that has a moving ball with a handle we can grab on to and move around with").
##
##   rail    a faceted torus at handrail height (config radius / height / tube), white with dark feature edges like the
##           carousels and Primitives_Ignorance's solids. Low tube facets (6) so its six seams run round the ring.
##   ball    an 8-sided ball rolling ON the rail: its roll is arc / ball radius, so a turn of the ring is a count of the
##           ball's own turns - two rotations at once, one about the carousel's axis, one about the ball's.
##   handle  a yoke over the ball. Grab it (XR hand, desktop right-click carry, or desktop left-click drag) and the ball
##           follows the hand's angle round the ring - never off it: the hand's position is projected onto the ring's
##           plane and only its angle is read. Let go and the ball keeps some of the hand's speed (momentum), which
##           decays back to its own slow turn over `settle` seconds.
##
## WALKING. The rail has NO collision: it is for the hand, not the body. A solid closed ring at 1.05 m round a carousel
## either keeps the visitor off the carousel's base plates or, once they are on them, traps them between the plates and
## the rail; an opening would stop the ball's circuit. So the ring can be walked through, and the ball and handle sit on
## grab layers only (19/21/23), never the body's layer 1.
const EdgeOutline = preload("res://commons/void/edge_outline.gd")
const PlatonicStudy = preload("res://commons/void/platonic_study.gd")
const HANDLE_SCRIPT := "res://commons/artifacts/carousel_ring/ring_handle.gd"

var radius := 2.9          # m, centre of the tube from the ring's axis
var height := 1.05         # m, centre of the tube above the floor
var tube := 0.035          # m, tube radius (a 7 cm handrail)
var ring_sides := 48       # facets round the ring
var tube_sides := 6        # facets round the tube: six seams
var ball_radius := 0.11
var ball_sides := 8
var speed := 0.12          # rad/s, the ball's own turn (sign = direction)
var momentum := 0.6        # share of the hand's release speed the ball keeps
var settle := 2.5          # s, time constant back to its own turn
var max_speed := 2.5       # rad/s, cap on a thrown ball
var look := "white_edges"  # or "plain" (finish only, no edges)
var outline_angle := 25.0

var angle := 0.0           # rad: ball at (sin, 0, cos) * radius
var velocity := 0.0        # rad/s, current
var state := "own"         # own | held | coast
var _held_velocity := 0.0
var _hold_target := 0.0
var _hold_fresh := false
var _hold_source: Node3D = null   # a pointer (desktop LMB drag) while that drag lasts

var rail: MeshInstance3D
var carriage: Node3D
var ball: MeshInstance3D
var handle: RigidBody3D
var _built := false


func _ready() -> void:
	_read_config()
	_build()

func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	var before := [radius, height, tube, ring_sides, tube_sides, ball_radius, ball_sides, look, outline_angle]
	_read_config()
	var after := [radius, height, tube, ring_sides, tube_sides, ball_radius, ball_sides, look, outline_angle]
	if _built and before != after:
		_build()

func _read_config() -> void:
	radius = clampf(float(get_meta("config_radius", radius)), 0.5, 20.0)
	height = clampf(float(get_meta("config_height", height)), 0.1, 6.0)
	tube = clampf(float(get_meta("config_tube", tube)), 0.01, 0.3)
	ring_sides = clampi(int(get_meta("config_ring_segments", ring_sides)), 8, 128)
	tube_sides = clampi(int(get_meta("config_tube_segments", tube_sides)), 3, 32)
	ball_radius = clampf(float(get_meta("config_ball_radius", ball_radius)), 0.04, 0.5)
	ball_sides = clampi(int(get_meta("config_ball_segments", ball_sides)), 4, 64)
	speed = clampf(float(get_meta("config_speed", speed)), -2.0, 2.0)
	momentum = clampf(float(get_meta("config_momentum", momentum)), 0.0, 1.0)
	settle = clampf(float(get_meta("config_settle", settle)), 0.1, 30.0)
	look = str(get_meta("config_look", look)).strip_edges().to_lower()
	outline_angle = clampf(float(get_meta("config_outline_angle", outline_angle)), 1.0, 89.0)
	if not _built:
		angle = deg_to_rad(float(get_meta("config_start_angle", 0.0)))
		velocity = speed

# ── BUILD ─────────────────────────────────────────────────────────────────────
func _build() -> void:
	for old in [rail, carriage, handle]:
		if is_instance_valid(old):
			remove_child(old)
			old.queue_free()
	var white := PlatonicStudy.finish()
	rail = MeshInstance3D.new()
	rail.name = "Rail"
	var torus := TorusMesh.new()
	torus.inner_radius = radius - tube
	torus.outer_radius = radius + tube
	torus.rings = ring_sides
	torus.ring_segments = tube_sides
	rail.mesh = torus
	rail.position.y = height
	rail.material_override = white
	add_child(rail)

	carriage = Node3D.new()
	carriage.name = "Carriage"
	add_child(carriage)
	ball = MeshInstance3D.new()
	ball.name = "Ball"
	var sphere := SphereMesh.new()
	sphere.radius = ball_radius
	sphere.height = ball_radius * 2.0
	sphere.radial_segments = ball_sides
	sphere.rings = maxi(2, ball_sides / 2)
	ball.mesh = sphere
	ball.material_override = white
	carriage.add_child(ball)
	# The yoke: an axle through the ball along the radius, two arms, and a grip bar over the ball. It rides the
	# carriage and never rolls - the ball turns inside it.
	var reach := ball_radius + 0.035
	var top := ball_radius + 0.11
	_bar(carriage, "Axle", Vector3(-reach, 0, 0), Vector3(reach, 0, 0), 0.012, white)
	_bar(carriage, "ArmIn", Vector3(-reach, 0, 0), Vector3(-reach, top, 0), 0.016, white)
	_bar(carriage, "ArmOut", Vector3(reach, 0, 0), Vector3(reach, top, 0), 0.016, white)
	_bar(carriage, "Grip", Vector3(-reach - 0.03, top, 0), Vector3(reach + 0.03, top, 0), 0.024, white)
	if look == "white_edges":
		for visual in [rail, ball] + carriage.get_children():
			if visual is MeshInstance3D:
				EdgeOutline.refresh(visual, outline_angle)

	handle = RigidBody3D.new()
	var script: Script = load(HANDLE_SCRIPT)
	if script != null and script.can_instantiate():
		handle.set_script(script)
	handle.name = "Handle"
	handle.set("ring", self)
	handle.freeze = true
	# Grab layers only, like movable_pivot's grips: 19 (desktop pointer), 21, 23 (the Void's hands). Never layer 1.
	handle.collision_layer = (1 << 18) | (1 << 20) | (1 << 22)
	handle.collision_mask = 0
	if "picked_up_layer" in handle:
		handle.set("picked_up_layer", 0)
		handle.set("release_mode", 2)        # XRToolsPickable.ReleaseMode.FROZEN
		handle.set("ranged_grab_method", 0)  # XRToolsPickable.RangedMethod.NONE
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0 * reach + 0.12, top + ball_radius + 0.08, 0.16)
	shape.shape = box
	shape.position = Vector3(0, (top - ball_radius) * 0.5, 0)
	handle.add_child(shape)
	add_child(handle)
	if handle.has_signal("dropped"):
		handle.connect("dropped", func(_p): hold_end())
	if handle.has_signal("picked_up"):
		handle.connect("picked_up", func(_p): hold_begin())
	_built = true
	_pose()

func _bar(parent: Node3D, title: String, a: Vector3, b: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var bar := MeshInstance3D.new()
	bar.name = title
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = a.distance_to(b)
	c.radial_segments = 6
	c.rings = 0
	bar.mesh = c
	bar.material_override = mat
	var y := (b - a).normalized()
	var ref := Vector3.RIGHT if absf(y.dot(Vector3.UP)) > 0.95 else Vector3.UP
	var x := ref.cross(y).normalized()
	bar.transform = Transform3D(Basis(x, y, x.cross(y)), (a + b) * 0.5)
	parent.add_child(bar)
	return bar

# ── MOTION ────────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if not _built:
		return
	if is_instance_valid(handle) and handle.has_method("is_picked_up") and handle.is_picked_up():
		if state != "held":
			hold_begin()
		hold_to(handle.global_position)
	step(delta)
	_pose()

## One step of the ball's motion. Pure: it reads only the ring's own state, so a probe can drive it without a hand.
func step(delta: float) -> void:
	if delta <= 0.0:
		return
	match state:
		"held":
			var previous := angle
			if _hold_fresh:
				angle = _hold_target
				_hold_fresh = false
			var now := (angle - previous) / delta
			_held_velocity = lerpf(_held_velocity, now, clampf(delta * 12.0, 0.0, 1.0))
			velocity = _held_velocity
		"coast":
			velocity = speed + (velocity - speed) * exp(-delta / settle)
			if absf(velocity - speed) < 0.004:
				velocity = speed
				state = "own"
			angle += velocity * delta
		_:
			velocity = speed
			angle += velocity * delta

func hold_begin(source: Node3D = null) -> void:
	state = "held"
	_held_velocity = 0.0
	_hold_fresh = false
	_hold_source = source

## The hand is at world_point: the ball takes the angle of its projection onto the ring's plane, unwrapped so a full
## circle by hand is a full circle of the ball. A hand nearer the axis than 15 cm has no angle and is ignored.
func hold_to(world_point: Vector3) -> void:
	if state != "held":
		return
	var local := to_local(world_point)
	var flat := Vector2(local.x, local.z)
	if flat.length() < 0.15:
		return
	var target := atan2(local.x, local.z)
	_hold_target = angle + wrapf(target - angle, -PI, PI)
	_hold_fresh = true

func hold_end(source: Node3D = null) -> void:
	if state != "held":
		return
	if source != null and _hold_source != null and source != _hold_source:
		return
	_hold_source = null
	velocity = clampf(_held_velocity, -max_speed, max_speed) * momentum
	state = "coast"

func held() -> bool:
	return state == "held"

## The ball on the ring at `a`: a point at (sin a, 0, cos a) * radius, the tube's top under it.
func ball_centre(a: float = angle) -> Vector3:
	return Vector3(sin(a) * radius, height + tube + ball_radius, cos(a) * radius)

## Horizontal distance of a local point from the ring's centre line (0 = exactly on the ring).
func off_ring(local: Vector3) -> float:
	return absf(Vector2(local.x, local.z).length() - radius)

func grip_local() -> Vector3:
	return carriage.transform * Vector3(0, ball_radius + 0.11, 0) if is_instance_valid(carriage) else Vector3.ZERO

func _pose() -> void:
	# Carriage frame: x = outward radius, y = up, z = x cross y (against the ball's travel), so travel is -z.
	var radial := Vector3(sin(angle), 0, cos(angle))
	var basis := Basis(radial, Vector3.UP, radial.cross(Vector3.UP))
	carriage.transform = Transform3D(basis, ball_centre())
	# Rolling without slipping on a rail: travel arc / ball radius, about the radius (the axle).
	ball.transform = Transform3D(Basis(Vector3.RIGHT, -angle * radius / ball_radius), Vector3.ZERO)
	if is_instance_valid(handle):
		var picked: bool = handle.has_method("is_picked_up") and handle.is_picked_up()
		if not picked:
			handle.transform = carriage.transform
			PhysicsServer3D.body_set_state(handle.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, handle.global_transform)
