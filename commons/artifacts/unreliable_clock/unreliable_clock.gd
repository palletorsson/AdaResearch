extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name UnreliableClock

## @identity
## lineage: the Break hero — a grandfather clock whose maker, in a moment of
##   ambition, hinged a second pendulum to the first. The case door stands open on
##   the tangle; behind the bobs, the path they actually took hangs in the air as a
##   beaded ribbon that never once repeats. The numerals have given up their posts.
## essence: the double pendulum is where the promise of return fails. One pendulum
##   is a vow - same swing, same period, forever. Two, hinged, are a rumor: nearby
##   starts diverge, the period dissolves, and the clock stops being ABOUT time.
##   This is the door out of waves and into randomness.
## truth: add one joint to a promise and you get weather.
##
## The 2026-08-29 category-heroes pass, wavefunctions.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 7
## Initial angles of the two arms, radians from straight down.
@export var a1: float = 1.9
@export var a2: float = 2.6

func _ready() -> void:
	_rng.seed = seed
	_build_case()
	_build_face()
	_build_pendulum()
	_build_trace()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "a1", "a2"]:
		if config_data.has(key):
			set(key, config_data[key])

func _build_case() -> void:
	var wood := _matte_mat(Color(0.33, 0.22, 0.13), 0.75)
	var wood_d := _matte_mat(Color(0.26, 0.17, 0.10), 0.8)
	# tall case, open front: back panel, two sides, base, hood
	add_child(_box(Vector3(0.0, 1.05, -0.16), Vector3(0.56, 2.1, 0.05), wood_d))
	for sx in [-0.26, 0.26]:
		add_child(_box(Vector3(sx, 1.05, 0.0), Vector3(0.05, 2.1, 0.36), wood))
	add_child(_box(Vector3(0.0, 0.12, 0.0), Vector3(0.72, 0.24, 0.46), wood))
	add_child(_box(Vector3(0.0, 2.2, 0.0), Vector3(0.72, 0.2, 0.46), wood))
	add_child(_box(Vector3(0.0, 2.34, 0.0), Vector3(0.6, 0.08, 0.4), wood_d))
	# the door, open on its hinge: proof the tangle is on display, not hidden
	var door := _box(Vector3.ZERO, Vector3(0.5, 1.16, 0.03), wood)
	door.position = Vector3(0.26 + 0.24, 0.82, 0.3)
	door.rotation.y = 1.15
	add_child(door)

func _build_face() -> void:
	# the face: a pale disc whose numerals have slid off their posts
	var fc := Vector3(0.0, 1.86, 0.03)
	add_child(_cylinder(fc, 0.24, 0.03, _matte_mat(Color(0.9, 0.87, 0.78), 0.85)))
	var rim := _torus(fc + Vector3(0.0, 0.0, 0.01), 0.24, 0.012, _steel_mat(Color(0.7, 0.56, 0.26)))
	add_child(rim)
	for i in range(12):
		var a := TAU * float(i) / 12.0
		var drift := _rng.randf_range(0.0, 1.0)
		var r := 0.19 - drift * _rng.randf_range(0.0, 0.13)
		var mark := _box(fc + Vector3(sin(a) * r, cos(a) * r, 0.025), Vector3(0.035, 0.05, 0.01), _matte_mat(Color(0.15, 0.13, 0.1), 0.6))
		mark.rotation.z = -a + _rng.randf_range(-1.2, 1.2) * drift
		add_child(mark)
	# hands pointing at nothing in particular
	add_child(_cylinder_between(fc + Vector3(0.0, 0.0, 0.03), fc + Vector3(0.1, 0.13, 0.03), 0.008, _matte_mat(Color(0.12, 0.1, 0.08), 0.5)))
	add_child(_cylinder_between(fc + Vector3(0.0, 0.0, 0.03), fc + Vector3(-0.14, -0.05, 0.03), 0.006, _matte_mat(Color(0.12, 0.1, 0.08), 0.5)))

func _build_pendulum() -> void:
	# the double pendulum, frozen at its seeded angles
	var pivot := Vector3(0.0, 1.62, 0.02)
	var brass := _steel_mat(Color(0.74, 0.6, 0.28))
	var l1 := 0.55
	var l2 := 0.45
	var p1 := pivot + Vector3(sin(a1) * l1, -cos(a1) * l1, 0.0)
	var p2 := p1 + Vector3(sin(a2) * l2, -cos(a2) * l2, 0.0)
	add_child(_sphere(pivot, 0.03, brass))
	add_child(_cylinder_between(pivot, p1, 0.014, brass))
	add_child(_sphere(p1, 0.055, _steel_mat(Color(0.78, 0.65, 0.3))))
	add_child(_cylinder_between(p1, p2, 0.011, brass))
	add_child(_sphere(p2, 0.075, _glow_mat(Color(0.9, 0.5, 0.25), 1.2)))

func _build_trace() -> void:
	# the path the tip ACTUALLY took: a real double-pendulum integration from the
	# frozen state backwards in style - beads along a curve that never repeats
	var pivot := Vector3(0.0, 1.62, 0.02)
	var l1 := 0.55
	var l2 := 0.45
	var t1 := a1
	var t2 := a2
	var w1 := 0.0
	var w2 := 0.0
	var g := 9.8
	var dt := 0.012
	var beads := 0
	for step in range(900):
		# equations of motion, equal masses, standard form
		var d := t1 - t2
		var den := 2.0 - cos(2.0 * d)
		var n1 := -3.0 * g / l1 * sin(t1) - g / l1 * sin(t1 - 2.0 * t2) - 2.0 * sin(d) * (w2 * w2 * l2 / l1 + w1 * w1 * cos(d))
		var n2 := 2.0 * sin(d) * (w1 * w1 * l1 / l2 + 2.0 * g / l2 * cos(t1) + w2 * w2 * cos(d))
		w1 += n1 / den * dt
		w2 += n2 / den * dt
		t1 += w1 * dt
		t2 += w2 * dt
		if step % 18 == 0 and beads < 46:
			var q1 := pivot + Vector3(sin(t1) * l1, -cos(t1) * l1, 0.0)
			var q2 := q1 + Vector3(sin(t2) * l2, -cos(t2) * l2, 0.0)
			var u := float(beads) / 46.0
			var bead := _sphere(q2 + Vector3(0.0, 0.0, -0.06 - u * 0.05), 0.014 + 0.008 * (1.0 - u), _glow_mat(Color(0.55 + 0.4 * u, 0.35, 0.7 - 0.35 * u), 1.4 * (1.0 - u * 0.6)))
			add_child(bead)
			beads += 1

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "ClockPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(0.62, 0.24, 0.62)
	ts.rotation.y = deg_to_rad(-10.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("UNRELIABLE CLOCK - the break",
			"One pendulum is a vow: same swing, same period, forever. The maker\nhinged a second to it, and the vow became weather - the beaded path never\nonce repeats, and the numerals have left their posts. The door out of waves.")
