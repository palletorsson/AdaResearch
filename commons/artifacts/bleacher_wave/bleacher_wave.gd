extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BleacherWave

## @identity
## lineage: the Wave-in-space hero — one row of stadium fold-up seats doing the
##   mexican wave with nobody in them. Each seat only stands and sits; the STANDING
##   travels down the row. Section W, admission free, crowd optional.
## essence: sin(x - vt) is sin(t) walked: give every seat the same motion and each a
##   later start, and a shape moves through them that none of them owns. Period
##   becomes wavelength the moment the phase is paid out along a bench.
## truth: nothing in the row travels. The wave does. That is the whole trick of
##   propagation, performed by furniture.
##
## The 2026-08-29 category-heroes pass, wavefunctions.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 8
@export var seats: int = 9
## Wavelength in seats and the frozen phase of the travelling wave.
@export var wavelength: float = 6.0
@export var phase: float = 1.1
@export var wave_speed: float = 1.4

var _flips: Array[Node3D] = []

func _ready() -> void:
	_rng.seed = seed
	_build_stand()
	_build_seats()
	_build_sign()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "seats", "wavelength", "phase", "wave_speed"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	phase += wave_speed * delta
	for i in range(_flips.size()):
		var u := _wave_at(i)
		_flips[i].rotation.x = -1.35 * clampf(u, 0.0, 1.0)

func _wave_at(i: int) -> float:
	# 0 = seated (folded up), 1 = fully risen; a hump travelling along the row
	return sin(TAU * float(i) / wavelength - phase)

func _build_stand() -> void:
	var w := 0.46 * float(seats) + 0.3
	add_child(_box(Vector3(0.0, 0.16, 0.0), Vector3(w, 0.32, 0.65), _matte_mat(Color(0.32, 0.34, 0.4), 0.8)))
	add_child(_box(Vector3(0.0, 0.03, 0.42), Vector3(w, 0.06, 0.3), _matte_mat(Color(0.28, 0.3, 0.35), 0.8)))

func _build_seats() -> void:
	var w := 0.46 * float(seats)
	for i in range(seats):
		var x := -w * 0.5 + 0.46 * (float(i) + 0.5)
		var u := _wave_at(i)
		var col := Color(0.16, 0.35, 0.72) if i % 2 == 0 else Color(0.75, 0.16, 0.2)
		# fixed back shell
		add_child(_box(Vector3(x, 0.62, -0.26), Vector3(0.4, 0.6, 0.06), _matte_mat(col, 0.55)))
		# the flip: seat pan hinged at the back edge - risen seats have paid their phase
		var hinge := Node3D.new()
		hinge.position = Vector3(x, 0.36, -0.2)
		add_child(hinge)
		var pan := _box(Vector3(0.0, 0.02, 0.19), Vector3(0.4, 0.05, 0.38), _matte_mat(col * 0.9, 0.5))
		hinge.add_child(pan)
		hinge.rotation.z = 0.0
		hinge.rotation.x = -1.35 * clampf(u, 0.0, 1.0)
		_flips.append(hinge)
		# armrest posts
		add_child(_cylinder(Vector3(x - 0.21, 0.42, 0.0), 0.015, 0.2, _steel_mat(Color(0.6, 0.6, 0.65))))

func _build_sign() -> void:
	var w := 0.46 * float(seats)
	var post_x := -w * 0.5 - 0.25
	add_child(_cylinder(Vector3(post_x, 0.85, -0.2), 0.025, 1.7, _steel_mat(Color(0.55, 0.55, 0.6))))
	add_child(_box(Vector3(post_x, 1.75, -0.2), Vector3(0.5, 0.3, 0.05), _matte_mat(Color(0.12, 0.12, 0.16), 0.7)))
	var l := _billboard_label("SECTION  W", Vector3(post_x, 1.75, -0.12), 42, Color(0.95, 0.9, 0.6))
	add_child(l)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "BleacherPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(0.4, 0.24, 0.95)
	ts.rotation.y = deg_to_rad(8.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("BLEACHER WAVE - sin(x - vt)",
			"Every seat does the same thing a moment later than its neighbour.\nNo seat moves along the row, and yet something does: the standing itself.\nPeriod becomes wavelength the moment the phase is paid out along a bench.")
