# ===========================================================================
# NewtonCradle.gd - Newton's Cradle Demonstration
# 5 pendulum balls on strings — pull one back, release, watch momentum transfer
# Shows conservation of momentum + energy, elastic collisions, F=ma
#
# QFEP: Momentum as conserved quantity — what enters must exit.
# ===========================================================================
# @identity
# essence: Five suspended balls trade momentum through elastic collisions — lift one, release it, and exactly one leaves the far end
# desire: To make conservation of momentum audible and visible, so a conserved quantity stops being an equation and becomes a click-clack you can count
# critical_parameter: damping — at near-1.0 the cradle rings for minutes; lower it and the swing decays, revealing that "conservation" is always an idealisation energy leaks from
# triggers: Lift two balls and two leave; lift one and one leaves — the count is never negotiable, but friction eventually steals the height
# emerges: A one-in-one-out rule no ball was told to obey falls out of equal masses and elastic contact alone
# needs: pendulum balls [has], elastic collision transfer [has], suspending frame [has], slight damping [has]
# relationships: Physics-simulation sibling to gravity_well and slingshot_launcher; the collision-side complement to the forces vector-accumulation artifacts
# truth: In a closed line of equal masses, momentum cannot be created or destroyed — it can only be handed down the chain.
# ===========================================================================
extends Node3D

class_name NewtonCradle

## Cradle parameters
@export var ball_count: int = 5
@export var ball_radius: float = 0.12
@export var string_length: float = 0.6
@export var ball_mass: float = 1.0

## Physics
@export var gravity: float = 9.8
@export var damping: float = 0.998  # Very slight energy loss

## Colors
@export var frame_color: Color = Color(0.3, 0.3, 0.35)
@export var ball_color: Color = Color(0.85, 0.85, 0.9)
@export var string_color: Color = Color(0.5, 0.5, 0.55, 0.8)

## AXIS — WHAT THE APPARATUS SAYS WHEN NOTHING IS MOVING.
##
## A cradle at rest is five identical balls in a row: the entire demonstration is
## invisible, and any axis pinned to the swing is one photograph taken five times. So the
## claim is made in the hardware that survives the stopping — the demonstration outlives
## the demonstration, or it does not.
##
##   none    the bare rig — the legacy lineage, byte for byte. Rest tells you nothing.
##   catch   ARMED. A hooked fork on a bracket off the left post, out at the release
##           point, with a trigger lever and a pull cord to the base. The initial
##           condition is held by the apparatus, so you can read the drop with the
##           balls hanging dead.
##   chalk   DRAWN. A slate board a hand's width behind the swing plane, carrying both
##           swept arcs scribed in chalk out to the release angle, the plumb rest line,
##           and ONE IN — ONE OUT written across the top. The path is marked where it
##           happened and stays after the motion has gone.
##   scale   MEASURED. A graduated quadrant on each end pivot with the release tick lit
##           and a pointer laid on it, plus a height rule up the right post with a lit
##           index collar at the drop height. The demonstration becomes a reading.
##   tally   COUNTED. A bead rail over the top bar with one bead pushed clear of four,
##           and a slate on the base counting one lit pip IN against one lit pip OUT.
##           The claim is written as a number and needs no motion at all.
##
## Appearance only: nothing here touches _angles, _angular_velocities or the collision
## rule. The conservation law is taught by the same code in all five.
@export_enum("none", "catch", "chalk", "scale", "tally") var standstill: String = "none"
const STANDSTILLS: PackedStringArray = ["none", "catch", "chalk", "scale", "tally"]

# State per ball: angle from vertical, angular velocity
var _angles: Array[float] = []
var _angular_velocities: Array[float] = []

# Visuals
var _balls: Array[MeshInstance3D] = []
var _strings: Array[MeshInstance3D] = []
var _pivot_y: float = 0.0
var _info_label: Label3D
var _standstill_root: Node3D = null


func _ready() -> void:
	_pivot_y = string_length + ball_radius + 0.1
	_create_frame()
	_create_balls()
	_create_labels()
	_create_vr_controls()
	_release_left(1)  # Start with 1 ball pulled back
	_build_standstill()   # APPENDED LAST — nothing above it moves

func _create_frame() -> void:
	# Top bar
	var bar := MeshInstance3D.new()
	bar.name = "TopBar"
	var box := BoxMesh.new()
	var total_width: float = (ball_count - 1) * ball_radius * 2.0 + ball_radius * 2.0 + 0.1
	box.size = Vector3(total_width + 0.15, 0.03, 0.03)
	bar.mesh = box
	bar.position = Vector3(0, _pivot_y, 0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = frame_color
	mat.metallic = 0.7
	mat.roughness = 0.3
	bar.material_override = mat
	add_child(bar)

	# Two vertical supports
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.name = "Post"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.015
		cyl.bottom_radius = 0.015
		cyl.height = _pivot_y + 0.05
		post.mesh = cyl
		post.material_override = mat
		post.position = Vector3(side * (total_width / 2.0 + 0.05), _pivot_y / 2.0 - 0.025, 0)
		add_child(post)

	# Base plate
	var base := MeshInstance3D.new()
	base.name = "Base"
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(total_width + 0.3, 0.02, 0.2)
	base.mesh = base_mesh
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.15, 0.15, 0.18)
	base_mat.metallic = 0.5
	base.material_override = base_mat
	base.position = Vector3(0, -0.01, 0)
	add_child(base)

func _create_balls() -> void:
	var spacing := ball_radius * 2.0
	var start_x := -(ball_count - 1) * spacing / 2.0

	for i in range(ball_count):
		# Init physics state
		_angles.append(0.0)
		_angular_velocities.append(0.0)

		var x := start_x + i * spacing

		# String
		var string_mesh := MeshInstance3D.new()
		string_mesh.name = "String_%d" % i
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.003
		cyl.bottom_radius = 0.003
		cyl.height = string_length
		string_mesh.mesh = cyl

		var str_mat := StandardMaterial3D.new()
		str_mat.albedo_color = string_color
		str_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		string_mesh.material_override = str_mat
		add_child(string_mesh)
		_strings.append(string_mesh)

		# Ball
		var ball := MeshInstance3D.new()
		ball.name = "Ball_%d" % i
		var sphere := SphereMesh.new()
		sphere.radius = ball_radius
		sphere.height = ball_radius * 2.0
		ball.mesh = sphere

		var mat := StandardMaterial3D.new()
		mat.albedo_color = ball_color
		mat.metallic = 0.8
		mat.roughness = 0.15
		mat.emission_enabled = true
		mat.emission = ball_color * 0.1
		mat.emission_energy_multiplier = 0.5
		ball.material_override = mat
		add_child(ball)
		_balls.append(ball)

	_update_ball_positions()

func _update_ball_positions() -> void:
	var spacing := ball_radius * 2.0
	var start_x := -(ball_count - 1) * spacing / 2.0

	for i in range(ball_count):
		var base_x := start_x + i * spacing
		var angle := _angles[i]

		# Ball position: pendulum swing from pivot
		var ball_x := base_x + sin(angle) * string_length
		var ball_y := _pivot_y - cos(angle) * string_length
		_balls[i].position = Vector3(ball_x, ball_y, 0)

		# String: connect pivot to ball
		var pivot_pos := Vector3(base_x, _pivot_y, 0)
		var ball_pos := _balls[i].position
		var midpoint := (pivot_pos + ball_pos) / 2.0
		_strings[i].position = midpoint

		# Orient string
		_strings[i].transform.basis = Basis.IDENTITY
		var dir := (ball_pos - pivot_pos).normalized()
		if dir.length() > 0.001:
			var up := Vector3.FORWARD if abs(dir.dot(Vector3.FORWARD)) < 0.99 else Vector3.RIGHT
			_strings[i].look_at(_strings[i].global_position + dir, up)
			_strings[i].rotate_object_local(Vector3.RIGHT, PI / 2.0)

func _physics_process(delta: float) -> void:
	# Pendulum physics for each ball
	for i in range(ball_count):
		# Angular acceleration from gravity: alpha = -(g/L) * sin(theta)
		var alpha := -(gravity / string_length) * sin(_angles[i])
		_angular_velocities[i] += alpha * delta
		_angular_velocities[i] *= damping
		_angles[i] += _angular_velocities[i] * delta

	# Collision detection: adjacent balls transfer momentum on contact
	for i in range(ball_count - 1):
		var angle_diff := _angles[i + 1] - _angles[i]
		# Balls are touching when angle difference is small enough
		# At rest, they're all at angle=0 and touching.
		# A collision happens when left ball catches up to right ball
		var spacing_angle := ball_radius * 2.0 / string_length  # angular size of one ball diameter
		if angle_diff < spacing_angle * 0.1 and _angular_velocities[i] > _angular_velocities[i + 1]:
			# Elastic collision: swap velocities (equal mass)
			var temp := _angular_velocities[i]
			_angular_velocities[i] = _angular_velocities[i + 1]
			_angular_velocities[i + 1] = temp

	_update_ball_positions()
	_update_info()

func _release_left(count: int = 1) -> void:
	_reset_all()
	count = clampi(count, 1, ball_count - 1)
	for i in range(count):
		_angles[i] = -0.8  # Pull left ball(s) back ~45 degrees

func _release_right(count: int = 1) -> void:
	_reset_all()
	count = clampi(count, 1, ball_count - 1)
	for i in range(ball_count - count, ball_count):
		_angles[i] = 0.8

func _release_both() -> void:
	_reset_all()
	_angles[0] = -0.8
	_angles[ball_count - 1] = 0.8

func _reset_all() -> void:
	for i in range(ball_count):
		_angles[i] = 0.0
		_angular_velocities[i] = 0.0

func _create_labels() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 14
	_info_label.position = Vector3(0, _pivot_y + 0.12, 0)
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.text = "NEWTON'S CRADLE"
	add_child(_info_label)

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("NEWTON CRADLE", [
		[
			{"type": "button", "label": "1 BALL"},
			{"type": "button", "label": "2 BALLS"},
		],
		[
			{"type": "button", "label": "BOTH"},
			{"type": "button", "label": "RESET"},
		],
	])
	panel.position = Vector3(0, -0.05, 0.35)
	panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(panel)

	var btn_1ball: Node = panel.find_child("Btn_0", true, false)
	if btn_1ball:
		var area: Node = btn_1ball.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _release_left(1))

	var btn_2balls: Node = panel.find_child("Btn_1", true, false)
	if btn_2balls:
		var area2: Node = btn_2balls.get_node_or_null("InteractableAreaButton")
		if area2:
			area2.button_pressed.connect(func(_b): _release_left(2))

	var btn_both: Node = panel.find_child("Btn_2", true, false)
	if btn_both:
		var area3: Node = btn_both.get_node_or_null("InteractableAreaButton")
		if area3:
			area3.button_pressed.connect(func(_b): _release_both())

	var btn_reset: Node = panel.find_child("Btn_3", true, false)
	if btn_reset:
		var area4: Node = btn_reset.get_node_or_null("InteractableAreaButton")
		if area4:
			area4.button_pressed.connect(func(_b): _reset_all())

func _update_info() -> void:
	var total_ke := 0.0
	var total_pe := 0.0
	for i in range(ball_count):
		var v := _angular_velocities[i] * string_length
		total_ke += 0.5 * ball_mass * v * v
		var h := string_length * (1.0 - cos(_angles[i]))
		total_pe += ball_mass * gravity * h
	_info_label.text = "NEWTON'S CRADLE\nKE=%.3f  PE=%.3f  Total=%.3f" % [total_ke, total_pe, total_ke + total_pe]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _release_left(1)
			KEY_2: _release_left(2)
			KEY_3: _release_both()
			KEY_R: _reset_all()

func reset() -> void:
	_reset_all()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("standstill"):
		var want: String = str(config["standstill"]).strip_edges().to_lower()
		# Unknown word keeps the default — a typo must never silently publish a variant.
		if STANDSTILLS.has(want):
			standstill = want
	if _pivot_y > 0.0:
		_build_standstill()


# ═══════════════════════════════════════════════════════════════════════════
# STANDSTILL — the apparatus that speaks with the balls hanging dead.
# Everything below is additive dressing parented under one node, so a rebuild
# frees exactly this and leaves the cradle untouched.
# ═══════════════════════════════════════════════════════════════════════════
const SS_RELEASE := 0.8                            # the angle _release_left pulls to
const SS_INK := Color(0.98, 0.74, 0.26)            # the lit accent: readings and marks
const SS_CHALK := Color(0.93, 0.93, 0.88)          # dry chalk on slate
const SS_SLATE := Color(0.13, 0.14, 0.17)
const SS_STEEL := Color(0.42, 0.45, 0.50)


func _build_standstill() -> void:
	if is_instance_valid(_standstill_root):
		_standstill_root.queue_free()
	_standstill_root = null
	if standstill == "none":
		return
	var root := Node3D.new()
	root.name = "Standstill"
	add_child(root)
	_standstill_root = root
	match standstill:
		"catch":
			_ss_catch(root)
		"chalk":
			_ss_chalk(root)
		"scale":
			_ss_scale(root)
		"tally":
			_ss_tally(root)
		_:
			pass


# ── CATCH — the release height held in hardware ───────────────────────────
func _ss_catch(root: Node3D) -> void:
	var steel: StandardMaterial3D = _ss_mat(SS_STEEL, 0.35, 0.7)
	var lit: StandardMaterial3D = _ss_glow(SS_INK, 1.1)
	var spacing: float = ball_radius * 2.0
	var post_x: float = -((ball_count - 1) * spacing * 0.5 + spacing * 0.5 + 0.05 + 0.05)
	var hold: Vector3 = _ss_ball_at(0, -SS_RELEASE)

	# Collar clamped on the left post, and the bracket arm reaching out to the hold point.
	var collar: Vector3 = Vector3(post_x, _pivot_y * 0.78, 0.0)
	root.add_child(_ss_box(collar, Vector3(0.055, 0.075, 0.055), steel))
	root.add_child(_ss_link(collar, hold + Vector3(-0.02, 0.055, 0.0), 0.012, steel))

	# The fork: two prongs the ball rests between, and a lit seat plate under it.
	for sz: float in [-0.062, 0.062]:
		root.add_child(_ss_box(Vector3(hold.x + 0.03, hold.y - ball_radius * 0.55, sz),
			Vector3(0.13, 0.016, 0.016), steel))
	root.add_child(_ss_box(Vector3(hold.x + 0.03, hold.y - ball_radius - 0.012, 0.0),
		Vector3(0.14, 0.012, 0.115), lit))

	# Trigger lever off the collar and the pull cord dropped to the base.
	var lever: Vector3 = collar + Vector3(0.09, 0.17, 0.10)
	root.add_child(_ss_link(collar, lever, 0.010, steel))
	root.add_child(_ss_sphere(lever, 0.028, lit))
	root.add_child(_ss_link(lever, Vector3(lever.x, 0.03, lever.z), 0.0035, lit))
	root.add_child(_ss_label("HOLD", Vector3(hold.x, hold.y + 0.19, 0.0), 13, SS_INK))


# ── CHALK — the swept path drawn where it happened ────────────────────────
func _ss_chalk(root: Node3D) -> void:
	var slate: StandardMaterial3D = _ss_mat(SS_SLATE, 0.9, 0.0)
	var frame: StandardMaterial3D = _ss_mat(Color(0.30, 0.26, 0.21), 0.8, 0.0)
	var chalk: StandardMaterial3D = _ss_mat(SS_CHALK, 0.95, 0.0)
	var spacing: float = ball_radius * 2.0
	var half: float = (ball_count - 1) * spacing * 0.5
	var bw: float = (half + string_length) * 2.0 + 0.34
	var bh: float = _pivot_y + 0.30
	var bz: float = -0.28                       # a hand's width behind the swing plane
	var by: float = bh * 0.5 - 0.06

	root.add_child(_ss_box(Vector3(0.0, by, bz - 0.022), Vector3(bw + 0.07, bh + 0.07, 0.022), frame))
	root.add_child(_ss_box(Vector3(0.0, by, bz), Vector3(bw, bh, 0.018), slate))

	# The two swept arcs, at the true swing radius about the true end pivots.
	for s: float in [-1.0, 1.0]:
		var pivot: Vector3 = Vector3(s * half, _pivot_y, bz + 0.012)
		var prev: Vector3 = pivot + Vector3(0.0, -string_length, 0.0)
		for i in range(1, 15):
			var a: float = SS_RELEASE * (float(i) / 14.0) * s
			var p: Vector3 = pivot + Vector3(sin(a) * string_length, -cos(a) * string_length, 0.0)
			if i % 2 == 1:
				root.add_child(_ss_link(prev, p, 0.0055, chalk))
			prev = p
		# The release stroke: a radial tick laid across the end of the arc.
		var e: Vector3 = pivot + Vector3(sin(SS_RELEASE * s) * string_length,
			-cos(SS_RELEASE * s) * string_length, 0.0)
		var out: Vector3 = pivot + Vector3(sin(SS_RELEASE * s) * (string_length + 0.11),
			-cos(SS_RELEASE * s) * (string_length + 0.11), 0.0)
		root.add_child(_ss_link(e, out, 0.007, chalk))

	# Plumb rest line down the middle, dashed.
	for i in range(7):
		var y0: float = _pivot_y - 0.06 - float(i) * 0.09
		root.add_child(_ss_box(Vector3(0.0, y0, bz + 0.012), Vector3(0.008, 0.05, 0.006), chalk))
	root.add_child(_ss_label("ONE IN — ONE OUT", Vector3(0.0, by + bh * 0.5 - 0.09, bz + 0.02),
		20, SS_CHALK))


# ── SCALE — the demonstration turned into a reading ───────────────────────
func _ss_scale(root: Node3D) -> void:
	var steel: StandardMaterial3D = _ss_mat(SS_STEEL, 0.35, 0.7)
	var tick: StandardMaterial3D = _ss_mat(Color(0.88, 0.88, 0.84), 0.5, 0.1)
	var lit: StandardMaterial3D = _ss_glow(SS_INK, 1.1)
	var spacing: float = ball_radius * 2.0
	var half: float = (ball_count - 1) * spacing * 0.5
	var qz: float = -0.145
	var rad: float = 0.30

	for s: float in [-1.0, 1.0]:
		var pivot: Vector3 = Vector3(s * half, _pivot_y, qz)
		root.add_child(_ss_sphere(pivot, 0.026, steel))
		# Quadrant plate behind the graduations so the ticks read against something.
		root.add_child(_ss_box(pivot + Vector3(s * rad * 0.42, -rad * 0.52, -0.014),
			Vector3(rad * 0.95, rad * 1.15, 0.012), _ss_mat(Color(0.20, 0.21, 0.25), 0.8, 0.0)))
		for i in range(11):
			var a: float = SS_RELEASE * (float(i) / 10.0) * s
			var major: bool = (i % 5) == 0
			var tl: float = (0.075 if major else 0.038)
			var inner: Vector3 = pivot + Vector3(sin(a) * (rad - tl), -cos(a) * (rad - tl), 0.0)
			var outer: Vector3 = pivot + Vector3(sin(a) * rad, -cos(a) * rad, 0.0)
			var tr: float = (0.007 if major else 0.0045)
			var tm: StandardMaterial3D = (lit if major else tick)
			root.add_child(_ss_link(inner, outer, tr, tm))
		# The pointer laid on the release graduation.
		var tipv: Vector3 = pivot + Vector3(sin(SS_RELEASE * s) * (rad + 0.05),
			-cos(SS_RELEASE * s) * (rad + 0.05), 0.0)
		root.add_child(_ss_link(pivot, tipv, 0.010, lit))
		root.add_child(_ss_sphere(tipv, 0.024, lit))

	# Height rule up the right post with a lit index collar at the drop height.
	var rx: float = half + spacing * 0.5 + 0.05 + 0.10
	var drop: float = _ss_ball_at(0, -SS_RELEASE).y
	root.add_child(_ss_box(Vector3(rx, (_pivot_y - 0.04) * 0.5 + 0.04, 0.0),
		Vector3(0.045, _pivot_y - 0.08, 0.012), _ss_mat(Color(0.86, 0.86, 0.82), 0.6, 0.0)))
	for i in range(13):
		var gy: float = 0.06 + float(i) * ((_pivot_y - 0.14) / 12.0)
		var wide: bool = (i % 4) == 0
		var gin: float = (0.014 if wide else 0.020)
		var gw: float = (0.040 if wide else 0.026)
		root.add_child(_ss_box(Vector3(rx + gin, gy, 0.008), Vector3(gw, 0.007, 0.006), tick))
	root.add_child(_ss_box(Vector3(rx, drop, 0.014), Vector3(0.075, 0.018, 0.030), lit))
	root.add_child(_ss_link(Vector3(rx - 0.03, drop, 0.014), Vector3(rx - 0.20, drop, 0.014), 0.007, lit))
	root.add_child(_ss_label("h 0.18", Vector3(rx + 0.03, drop + 0.10, 0.02), 13, SS_INK))


# ── TALLY — the claim written as a count ──────────────────────────────────
func _ss_tally(root: Node3D) -> void:
	var steel: StandardMaterial3D = _ss_mat(SS_STEEL, 0.35, 0.7)
	var slate: StandardMaterial3D = _ss_mat(SS_SLATE, 0.9, 0.0)
	var dead: StandardMaterial3D = _ss_mat(Color(0.34, 0.35, 0.39), 0.7, 0.1)
	var lit: StandardMaterial3D = _ss_glow(SS_INK, 1.2)
	var chalk: StandardMaterial3D = _ss_mat(SS_CHALK, 0.95, 0.0)
	var spacing: float = ball_radius * 2.0
	var half: float = (ball_count - 1) * spacing * 0.5

	# Bead rail over the top bar: one bead pushed clear of the other four.
	var ry: float = _pivot_y + 0.11
	var rail: float = half + 0.20
	root.add_child(_ss_link(Vector3(-rail, ry, 0.0), Vector3(rail, ry, 0.0), 0.008, steel))
	for sx: float in [-rail, rail]:
		root.add_child(_ss_box(Vector3(sx, ry - 0.045, 0.0), Vector3(0.02, 0.09, 0.02), steel))
	root.add_child(_ss_sphere(Vector3(-rail + 0.05, ry, 0.0), 0.030, lit))
	for i in range(4):
		root.add_child(_ss_sphere(Vector3(rail - 0.05 - float(i) * 0.065, ry, 0.0), 0.030, dead))

	# Slate on the base, tilted up to the reader: one pip IN against one pip OUT.
	var pw: float = half * 1.55
	var plate := Node3D.new()
	plate.position = Vector3(0.0, 0.20, 0.17)
	plate.rotation_degrees = Vector3(-14.0, 0.0, 0.0)
	root.add_child(plate)
	plate.add_child(_ss_box(Vector3.ZERO, Vector3(pw + 0.035, 0.32, 0.014),
		_ss_mat(Color(0.30, 0.26, 0.21), 0.8, 0.0)))
	plate.add_child(_ss_box(Vector3(0.0, 0.0, 0.010), Vector3(pw, 0.285, 0.010), slate))
	for side: float in [-1.0, 1.0]:
		for i in range(ball_count):
			var px: float = side * (pw * 0.27) + (float(i) - (ball_count - 1) * 0.5) * (pw * 0.062)
			var on: bool = (side < 0.0 and i == 0) or (side > 0.0 and i == ball_count - 1)
			var pm: StandardMaterial3D = (lit if on else dead)
			plate.add_child(_ss_box(Vector3(px, -0.055, 0.017), Vector3(0.026, 0.026, 0.008), pm))
	plate.add_child(_ss_box(Vector3(0.0, -0.055, 0.017), Vector3(0.055, 0.008, 0.008), chalk))
	plate.add_child(_ss_box(Vector3(0.0, -0.040, 0.017), Vector3(0.055, 0.008, 0.008), chalk))
	plate.add_child(_ss_label("IN", Vector3(-pw * 0.27, 0.055, 0.03), 15, SS_CHALK))
	plate.add_child(_ss_label("OUT", Vector3(pw * 0.27, 0.055, 0.03), 15, SS_CHALK))
	# Legs so the slate stands off the base plate rather than floating.
	for sx2: float in [-pw * 0.36, pw * 0.36]:
		root.add_child(_ss_link(Vector3(sx2, 0.02, 0.20), Vector3(sx2, 0.11, 0.175), 0.010, steel))


# ── Small builders (prefixed so nothing in the cradle can collide) ────────
func _ss_ball_at(index: int, angle: float) -> Vector3:
	var spacing: float = ball_radius * 2.0
	var base_x: float = -(ball_count - 1) * spacing * 0.5 + float(index) * spacing
	return Vector3(base_x + sin(angle) * string_length,
		_pivot_y - cos(angle) * string_length, 0.0)


func _ss_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _ss_glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


func _ss_box(p: Vector3, s: Vector3, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = s
	mi.mesh = bm
	mi.material_override = m
	mi.position = p
	return mi


func _ss_sphere(p: Vector3, r: float, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	mi.material_override = m
	mi.position = p
	return mi


# A cylinder spanning a to b, oriented by a hand-built Basis. look_at() needs the node to
# be in the tree already, and these are built before they are parented.
func _ss_link(a: Vector3, b: Vector3, r: float, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	var d: Vector3 = b - a
	var span: float = d.length()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = maxf(span, 0.002)
	mi.mesh = cm
	mi.material_override = m
	var dir: Vector3 = Vector3.UP
	if span > 0.0001:
		dir = d / span
	var up: Vector3 = Vector3.UP
	if absf(dir.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var right: Vector3 = dir.cross(up).normalized()
	var fwd: Vector3 = right.cross(dir).normalized()
	mi.transform = Transform3D(Basis(right, dir, fwd), (a + b) * 0.5)
	return mi


func _ss_label(text: String, p: Vector3, size: int, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.002
	l.modulate = c
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = p
	return l
