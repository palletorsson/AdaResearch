# ===========================================================================
# NOC Example 3.2: Forces with Arbitrary Angular Motion
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing -> GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================
#
# @identity
# essence: a += F/m, v += a, p += v, omega += random, theta += omega. Linear attraction plus independent angular motion. Two dynamics, one body.
# desire: To show that rotation and translation are independent — boxes orbit an attractor while spinning at their own rate, two freedoms coexisting.
# critical_parameter: angular_damping (0.9-0.999) — controls how quickly spin decays. Low damping = chaotic spinning. High damping = gradual alignment. The knob between chaos and order.
# triggers: Automatic — 8 movers orbit attractor, each accumulating random angular velocity. VR sliders → attractor strength and angular damping.
# emerges: Movers wrapping around boundaries and re-entering from the opposite side (toroidal space). Spin rates diverging as random angular impulses accumulate.
# needs: VR parameter controllers [has], attractor visualization [has]. Missing: angular velocity display arrows, trail visualization.
# relationships: Extends torque_demo concepts to many bodies. Lives in ForcesSystems. Bridges linear forces (attraction) with angular dynamics (spin).
# truth: Rotation does not need a force. It needs a torque — or random impulses. Translation and rotation are independent stories told by the same body.

class_name ArbitraryAngularMotionVR
extends Node3D
const ARTIFACT_SCENE_PRESENTER := preload("res://commons/artifacts/ArtifactScenePresenter.gd")

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_ATTRACTOR := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")
const MAT_MOVER := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var num_movers: int = 8
@export var attractor_strength: float = 0.15
@export var angular_damping: float = 0.98

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `configuration`
# ═══════════════════════════════════════════════════════════════════════════
#
# WHERE THE EIGHT ARE, AND HOW THEY ARE HELD, AT t = 0.
#
# This file's own truth statement is that rotation and translation are two
# independent stories told by the same body. The shipped scene asserts that and
# never contrasts it, and the asymmetry is visible in the spawn loop: the
# TRANSLATION freedom is given a rich initial condition — a ring, a jittered
# radius, a tangential velocity — and the ROTATION freedom is given nothing at
# all. Every box starts at angle 0 with zero spin and waits for the random
# impulses to do something. So the freedom the artifact is named after is the one
# it never initialises, and the only demonstration it can offer of independence
# is that the two eventually drift apart.
#
# `configuration` is where the mass and the attitude are before the law touches
# either. Neither is derivable: gravity cannot tell you where to put the bodies
# and a torque cannot tell you which way they were already facing.
#
#   ring      the shipped statements, in the shipped order: eight on a circle of
#             jittered radius 0.20-0.35 around the attractor, tangential, every
#             one of them axis-aligned and still. The legacy lineage.
#   column    translation collapsed onto one axis — the eight stacked on a
#             vertical line through the attractor, evenly spaced, still
#             tangential. Position maximally ordered; attitude still blank.
#   shells    a hierarchy instead of a ring: four at r = 0.15 and four at
#             r = 0.34, on two levels, offset by half a step so no inner box
#             hides behind an outer one.
#   fan       THE VALUE THAT CARRIES THE CLAIM. Same circle, but each box is
#             rolled to its own attitude — position ordered on one ladder,
#             rotation ordered on another, the two freedoms drawn as two
#             independent ladders in one picture. This is the thing the shipped
#             scene cannot show.
#   scatter   neither freedom ordered: uniform positions in the tank, uniform
#             attitudes, uniform spins. The null against which the other four
#             are arrangements rather than noise.
#
# THE LAW IS UNTOUCHED at every value. _process, the attraction, the damping, the
# random angular impulses and the wrap are the same lines they were; this axis
# only decides what they are handed.
@export_enum("ring", "column", "shells", "fan", "scatter") var configuration: String = "ring"

## Allow-list. An unknown word falls back to the shipped ring rather than stranding a
## placement with an empty tank.
const CONFIGURATIONS: PackedStringArray = ["ring", "column", "shells", "fan", "scatter"]

## FIXTURES — not axes, and deliberately not declared as any. Neither changes what the
## artifact argues; both exist so a still can be taken OF the argument.
##
## `clock` = hold freezes the demonstration at the state it was released in. It is needed
## because of a number this promotion measured rather than assumed: position advances by
## |v| once per 60 Hz frame (`position += velocity * delta * 60.0`), |v| is capped at
## max_speed = 0.4, and the tank is 0.9 m across — about 30 m/s in a box you can reach
## across, wrapping roughly every third frame. An initial arrangement therefore survives
## about a thirtieth of a second, and a sweep that settles for 1.1 s before the shutter
## photographs eight boxes at uniformly random positions whatever it was handed. Default
## is "run" and every shipped placement keeps it.
@export_enum("run", "hold") var clock: String = "run"

## `spawn_seed` >= 0 pins the ring's jitter and scatter's draws to a RandomNumberGenerator
## instead of the global one. -1 is the shipped behaviour EXACTLY — the same randf_range
## calls, in the same order, against the same global RNG — because five variants of an
## unseeded generative artifact are five different objects rather than five views of one.
@export var spawn_seed: int = -1

var _sim_root: Node3D
var _attractor: MeshInstance3D
var _movers: Array[AngularMover] = []
var _status_label: Label3D
var _controller_root: Node3D

## null on the shipped path, and the only thing _rf() ever asks about.
var _rng: RandomNumberGenerator = null

## Built only under `clock` = hold, which no map sets. null everywhere else.
var _diorama: Node3D = null

func _ready() -> void:
	_read_grid_config_meta()
	_setup_environment()
	_spawn_scene()
	call_deferred("_apply_standard_presentation")
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 22
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.82, 0)
	_sim_root.add_child(_status_label)

	_controller_root = Node3D.new()
	_controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(_controller_root)

	var strength_controller := CONTROLLER_SCENE.instantiate()
	strength_controller.parameter_name = "Attractor"
	strength_controller.min_value = 0.05
	strength_controller.max_value = 0.3
	strength_controller.default_value = attractor_strength
	strength_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(strength_controller)
	strength_controller.value_changed.connect(func(v: float) -> void:
		attractor_strength = v
	)
	strength_controller.set_value(attractor_strength)

	var damping_controller := CONTROLLER_SCENE.instantiate()
	damping_controller.parameter_name = "Damping"
	damping_controller.min_value = 0.9
	damping_controller.max_value = 0.999
	damping_controller.default_value = angular_damping
	damping_controller.position = Vector3(0, -0.18, 0)
	damping_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(damping_controller)
	damping_controller.value_changed.connect(func(v: float) -> void:
		angular_damping = v
	)
	damping_controller.set_value(angular_damping)

func _spawn_scene() -> void:
	_attractor = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.06
	sphere.height = sphere.radius * 2.0
	_attractor.mesh = sphere
	_attractor.material_override = MAT_ATTRACTOR
	_attractor.position = Vector3(0, 0.5, 0)
	_sim_root.add_child(_attractor)

	_spawn_movers()


## THE INITIAL CONDITION, and the only place it is written. Split out of _spawn_scene so a
## configuration change can re-release the eight without rebuilding the attractor, the
## sliders or the label around them.
func _spawn_movers() -> void:
	var want: String = String(configuration).strip_edges().to_lower()
	if not CONFIGURATIONS.has(want):
		want = "ring"
	configuration = want

	_rng = null
	if spawn_seed >= 0:
		_rng = RandomNumberGenerator.new()
		_rng.seed = spawn_seed

	for i in num_movers:
		var m := AngularMover.new()
		m.init(_sim_root, MAT_MOVER)
		_place(m, i, want)
		_movers.append(m)

	# The same string _process writes on its first frame, written once here as well so a
	# held clock is not photographed with a blank readout. At `run` frame one overwrites it
	# with a byte-identical value.
	_status_label.text = "Angular + Forces | %d movers" % _movers.size()

	_apply_hold_diorama()


## THE DIORAMA — ink that exists ONLY under the `hold` fixture, which no map sets.
##
## Held, this is not a simulation any more; it is a tableau of an initial condition, and a
## tableau has to be readable. Eight bars of 0.06 x 0.02 m are too little ink for a still
## to separate five arrangements by — that is arithmetic, not taste: they total about a
## hundredth of a square metre of projected area, and an axis that moves a hundredth of a
## square metre around a one-and-a-half metre frame cannot register above a percent.
##
## Two things are drawn, and both are DERIVED FROM WHERE THE EIGHT ACTUALLY ARE rather
## than from the word that put them there: a spoke from the attractor to each body, which
## is r, the length the whole attraction is a function of; and a bar through each body
## along its own long axis, which is its attitude. Same information, at a thickness a
## photograph can hold.
##
## It is drawn at EVERY value INCLUDING `ring`, which is the point. An exhibit whose ink
## appears only away from the default measures the ink; this one compares one arrangement
## with another and never compares something with nothing.
func _apply_hold_diorama() -> void:
	if is_instance_valid(_diorama):
		_diorama.queue_free()
	_diorama = null
	if clock != "hold":
		return

	# A slider that cannot be moved is not an instrument; in a still it is only a large
	# object parked off to one side, pulling the frame away from the demonstration. Freed
	# rather than hidden, because the capture's AABB walk counts a MeshInstance3D whether
	# it is visible or not — hiding it would have shrunk nothing.
	if is_instance_valid(_controller_root):
		var parent: Node = _controller_root.get_parent()
		if parent != null:
			parent.remove_child(_controller_root)
		_controller_root.queue_free()
		_controller_root = null

	var d := Node3D.new()
	d.name = "HoldDiorama"
	_sim_root.add_child(d)
	_diorama = d

	var ink := StandardMaterial3D.new()
	ink.albedo_color = Color(0.70, 0.78, 0.86)
	ink.roughness = 0.6
	ink.emission_enabled = true
	ink.emission = Color(0.45, 0.62, 0.82)
	ink.emission_energy_multiplier = 0.5

	var att := StandardMaterial3D.new()
	att.albedo_color = Color(0.98, 0.74, 0.26)
	att.roughness = 0.6
	att.emission_enabled = true
	att.emission = Color(0.98, 0.74, 0.26)
	att.emission_energy_multiplier = 1.0

	var hub: Vector3 = _attractor.position
	for m in _movers:
		if not is_instance_valid(m.root):
			continue
		var at: Vector3 = m.root.position
		_hold_bar(d, hub, at - hub, 0.010, ink)
		# The attitude. `angle` is a roll about Z and the body is 0.06 long in its local X,
		# so this is the bar the box already is, drawn three times its length and in its own
		# colour so a still can read the roll instead of guessing at it.
		#
		# 0.18 x 0.012 is deliberately the SAME ORDER OF INK as the spokes (about 0.019 m2
		# across the eight against their 0.024). In an artifact whose claim is that rotation
		# and translation are equal partners, drawing the rotation freedom at a third of the
		# translation freedom's weight would have been the asymmetry the shipped spawn loop
		# already had, repeated in the exhibit that was supposed to expose it.
		var axis: Vector3 = Vector3(cos(m.angle), sin(m.angle), 0.0) * 0.18
		_hold_bar(d, at - axis * 0.5, axis, 0.012, att)


## A shaft along `vec`, oriented with Basis.looking_at rather than look_at() so it does not
## care whether the node is in the tree yet or where the map put the artifact.
func _hold_bar(root: Node3D, from: Vector3, vec: Vector3, thick: float,
		m: StandardMaterial3D) -> void:
	var length: float = vec.length()
	if length < 0.001:
		return
	var up: Vector3 = Vector3.UP
	if absf(vec.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(thick, thick, length)
	mi.mesh = bm
	mi.material_override = m
	mi.transform = Transform3D(Basis.looking_at(vec, up), from + vec * 0.5)
	root.add_child(mi)


## One draw. Routed so that `spawn_seed` can pin them; at the shipped -1 this IS
## randf_range, the same global RNG, called in the same order with the same bounds.
func _rf(a: float, b: float) -> float:
	if _rng != null:
		return _rng.randf_range(a, b)
	return randf_range(a, b)


func _place(m: AngularMover, i: int, want: String) -> void:
	var angle: float = (float(i) / num_movers) * TAU
	var lo: Vector3 = AngularMover.TANK_MIN
	var hi: Vector3 = AngularMover.TANK_MAX

	if want == "ring":
		# THE SHIPPED STATEMENTS, in the shipped order. Three draws per box: radius, then
		# the y jitter, then the vy jitter — Vector3's arguments evaluate left to right, so
		# the order the global RNG is consumed in is part of what "unchanged" means here.
		var radius: float = _rf(0.2, 0.35)
		m.position = Vector3(
			cos(angle) * radius,
			0.5 + _rf(-0.1, 0.1),
			sin(angle) * radius
		)
		m.velocity = Vector3(
			-sin(angle) * 0.3,
			_rf(-0.05, 0.05),
			cos(angle) * 0.3
		)
		return

	match want:
		"column":
			var f: float = float(i) / float(maxi(num_movers - 1, 1))
			m.position = Vector3(0.0, lo.y + 0.06 + f * (hi.y - lo.y - 0.12), 0.0)
			m.velocity = Vector3(-sin(angle) * 0.3, 0.0, cos(angle) * 0.3)
			m.set_spin(0.0, 0.0)
		"shells":
			# The bodies alternate between the two shells, so the ANGLE has to be indexed by
			# the position within a shell and not by i. Doubling the ring's angle looked
			# right and was not: at num_movers = 8 it sends i = 0 and i = 4 to the same
			# point and i = 2 and i = 6 to another, hiding two of the eight inside two
			# others. Half-shell indexing, plus a half-step offset on the outer ring so no
			# outer body stands directly behind an inner one.
			var inner: bool = (i % 2) == 0
			var half: int = maxi(num_movers / 2, 1)
			var k: int = i / 2
			var a2: float = (float(k) / float(half)) * TAU
			if not inner:
				a2 += PI / float(half)
			# 0.12 against 0.40, and two levels 0.24 apart. Measured, not chosen: at 0.15 /
			# 0.34 on one level the mean body displacement from `ring` was 0.099 m, which is
			# two similar rings wearing different names. These separations put it past 0.2 m.
			var r2: float = 0.12 if inner else 0.40
			var y2: float = 0.62 if inner else 0.38
			m.position = Vector3(cos(a2) * r2, y2, sin(a2) * r2)
			m.velocity = Vector3(-sin(a2) * 0.3, 0.0, cos(a2) * 0.3)
			m.set_spin(0.0, 0.0)
		"fan":
			m.position = Vector3(cos(angle) * 0.28, 0.5, sin(angle) * 0.28)
			m.velocity = Vector3(-sin(angle) * 0.3, 0.0, cos(angle) * 0.3)
			# Position on one ladder, attitude on another. The two freedoms, both ordered,
			# neither derived from the other.
			m.set_spin(angle, 0.0)
		"scatter":
			m.position = Vector3(
				_rf(lo.x + 0.05, hi.x - 0.05),
				_rf(lo.y + 0.05, hi.y - 0.05),
				_rf(lo.z + 0.05, hi.z - 0.05)
			)
			m.velocity = Vector3(_rf(-0.3, 0.3), _rf(-0.05, 0.05), _rf(-0.3, 0.3))
			m.set_spin(_rf(0.0, TAU), _rf(-0.02, 0.02))
		_:
			pass


func _process(delta: float) -> void:
	# FIXTURE. Default is "run", so this compare is the whole cost on the shipped path.
	if clock == "hold":
		return
	for mover in _movers:
		var dir := (_attractor.position - mover.position).normalized()
		var force := dir * attractor_strength
		mover.apply_force(force)
		mover.angular_velocity *= angular_damping
		mover.update(delta)
		mover.wrap_bounds()

	_status_label.text = "Angular + Forces | %d movers" % _movers.size()

func _apply_standard_presentation() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	ARTIFACT_SCENE_PRESENTER.present(self, _sim_root)

func _exit_tree() -> void:
	for m in _movers:
		m.queue_free()

class AngularMover:
	## The tank, named where wrap_bounds() actually uses it. These were six inline literals
	## and the numbers are unchanged; naming them is what lets `scatter` draw from the same
	## box the wrap enforces instead of a second copy of it.
	const TANK_MIN := Vector3(-0.45, 0.05, -0.45)
	const TANK_MAX := Vector3(0.45, 0.95, 0.45)

	var root: Node3D
	var body: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO
	var angular_velocity: float = 0.0
	var angle: float = 0.0
	var max_speed: float = 0.4

	## THE ROTATION FREEDOM AT t = 0. update() writes root.rotation from `angle` on every
	## frame, so a configuration that wants the eight to start at different attitudes has to
	## set the accumulator AND the node — otherwise the attitude appears only after the
	## first frame, which is exactly the frame a held clock never reaches. Never called on
	## the shipped path: `ring` leaves both at the zero they already had.
	func set_spin(a: float, w: float) -> void:
		angle = a
		angular_velocity = w
		if is_instance_valid(root):
			root.rotation = Vector3(0, 0, a)

	var position: Vector3:
		get:
			if not is_instance_valid(root):
				return Vector3.ZERO
			return root.global_position
		set(value):
			if not is_instance_valid(root):
				return
			if root.get_parent() is Node3D:
				var det := (root.get_parent() as Node3D).global_transform.basis.determinant()
				if abs(det) < 0.0001:
					root.position = value
					return
			root.global_position = value

	func init(parent: Node3D, mat: Material) -> void:
		root = Node3D.new()
		root.name = "Mover"
		parent.add_child(root)

		body = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.06, 0.02, 0.02)
		body.mesh = box
		body.material_override = mat
		root.add_child(body)

	func apply_force(force: Vector3) -> void:
		acceleration += force

	func update(delta: float) -> void:
		velocity += acceleration
		velocity = velocity.limit_length(max_speed)
		position += velocity * delta * 60.0
		acceleration = Vector3.ZERO

		angular_velocity += randf_range(-0.01, 0.01)
		angle += angular_velocity
		root.rotation = Vector3(0, 0, angle)

	func wrap_bounds() -> void:
		var pos := position
		if pos.x < TANK_MIN.x:
			pos.x = TANK_MAX.x
		elif pos.x > TANK_MAX.x:
			pos.x = TANK_MIN.x
		if pos.y < TANK_MIN.y:
			pos.y = TANK_MAX.y
		elif pos.y > TANK_MAX.y:
			pos.y = TANK_MIN.y
		if pos.z < TANK_MIN.z:
			pos.z = TANK_MAX.z
		elif pos.z > TANK_MAX.z:
			pos.z = TANK_MIN.z
		position = pos

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()

## Grid config arrives twice and by two different routes: GridInteractablesComponent sets
## config_<key> metadata on the instantiated root and then calls apply_grid_config(), and
## the capture harness calls apply_grid_config() before the scene enters the tree. Reading
## the metadata on the way in means the eight are released once, correctly, instead of
## released as a ring and then torn down.
##
## Costs nothing when no token is present: the exports keep their defaults and not a single
## existing placement changes.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_configuration"):
			configuration = str(node.get_meta("config_configuration"))
		if node.has_meta("config_clock"):
			clock = str(node.get_meta("config_clock"))
		if node.has_meta("config_spawn_seed"):
			spawn_seed = int(node.get_meta("config_spawn_seed"))
		node = node.get_parent()


## Config from map_data.json tokens: #configuration:fan  ·  #configuration:column
##
## GUARDED ON CHANGE, deliberately. All 7 map files carrying this token arrive here with
## none of these keys, and the grid reaches this twice for one placement; an unguarded
## re-release would tear down and re-spawn the eight on both of those, for nothing. This
## function used to be a bare `pass`, so every one of those calls was already a no-op and
## stays one.
func apply_grid_config(config: Dictionary) -> void:
	var was_configuration: String = configuration
	var was_clock: String = clock
	var was_seed: int = spawn_seed

	if config.has("configuration"):
		configuration = str(config["configuration"])
	if config.has("clock"):
		clock = str(config["clock"])
	if config.has("spawn_seed"):
		spawn_seed = int(config["spawn_seed"])

	if configuration == was_configuration and clock == was_clock and spawn_seed == was_seed:
		return
	# Before _ready() there is nothing to re-release and _ready() will build with these
	# values itself.
	if _sim_root == null:
		return

	for m in _movers:
		m.queue_free()
	_movers.clear()
	_spawn_movers()
	# The arrangement changed size, so the 0.82 m fit is stale. present() sets scale
	# absolutely and re-centres, so calling it again converges rather than compounding.
	call_deferred("_apply_standard_presentation")
