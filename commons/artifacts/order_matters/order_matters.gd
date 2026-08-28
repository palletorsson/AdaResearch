extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name OrderMatters

## @identity
## lineage: transformation's cheat-code is that composition does not commute, and every
##   diagram of that fact is a diagram. This is the object instead: ONE figure, ONE
##   translation, ONE rotation, ONE scale, and the six orders you can apply them in.
## essence: the letters are read left to right as the order the operations are applied in
##   WORLD space, so each is pre-multiplied onto what came before: TRS builds S*R*T. The
##   scale is deliberately NON-UNIFORM (1, 2.4, 1) — a uniform scale commutes with
##   rotation and the whole axis would die quietly. A pale ghost of the untouched figure
##   stands at the origin in every frame, so the six are read against the same nothing.
## truth: the numbers never change. 1.3 metres across, 0.55 up, fifty degrees, two-point-
##   four times as tall — identical in all six frames. Only the order changes, and six
##   different objects come out.
## critical_parameter: order — it is the entire artifact. There is nothing else to vary.
## triggers: none. No _process, no clock; the transform is composed once in _ready.
##
## Built 2026-08-27 for transformation-dna, one of three sequences the DNA galleries had
## never covered.

const BRASS := Color(0.77, 0.69, 0.48)
const BRASS_DARK := Color(0.44, 0.38, 0.25)
const STONE := Color(0.13, 0.13, 0.15)
const GHOST := Color(0.55, 0.62, 0.72)

# The three operations. Fixed for every value of `order` — that is the point.
const MOVE := Vector3(1.3, 0.55, 0.0)
const TURN_DEG := 50.0
const STRETCH := Vector3(1.0, 2.4, 1.0)

@export var seed: int = 3
## Read left to right: the order the three operations are applied in, in world space.
@export_enum("TRS", "TSR", "RTS", "RST", "SRT", "STR") var order: String = "TRS"
@export var show_ghost: bool = true


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("order"):
		order = str(config_data["order"])
	if config_data.has("show_ghost"):
		show_ghost = bool(config_data["show_ghost"])
	if config_data.has("seed"):
		seed = int(config_data["seed"])
	for c in get_children():
		c.queue_free()
	_build()


func _build() -> void:
	_rng.seed = seed
	_plinth()
	if show_ghost:
		var g := _figure(_matte_mat(GHOST, 1.0, 0.0), true)
		add_child(g)
	var rig := _figure(_steel_mat(BRASS), false)
	rig.transform = _compose(order)
	add_child(rig)


func _plinth() -> void:
	add_child(_box(Vector3(0.65, -0.03, 0), Vector3(4.4, 0.06, 1.6), _matte_mat(STONE, 0.9, 0.0)))


## Pre-multiply each operation onto the running transform, so the letters read left to
## right as "what happens next, in world space". TRS therefore builds S * R * T.
func _compose(code: String) -> Transform3D:
	var m := Transform3D.IDENTITY
	for i in range(code.length()):
		var ch: String = code.substr(i, 1)
		m = _op(ch) * m
	return m


func _op(ch: String) -> Transform3D:
	match ch:
		"T":
			return Transform3D(Basis.IDENTITY, MOVE)
		"R":
			return Transform3D(Basis(Vector3.BACK, deg_to_rad(TURN_DEG)), Vector3.ZERO)
		"S":
			return Transform3D(Basis.from_scale(STRETCH), Vector3.ZERO)
	return Transform3D.IDENTITY


## A small figure rather than a cube: a cube tells you nothing about which way is up, and
## half of what the order does is turn things over.
func _figure(mat: Material, ghost: bool) -> Node3D:
	var n := Node3D.new()
	var m: Material = mat
	if ghost:
		m = _glass_mat(GHOST, 0.22)
	n.add_child(_box(Vector3(0, 0.30, 0), Vector3(0.34, 0.60, 0.24), m))
	n.add_child(_sphere(Vector3(0, 0.72, 0), 0.12, m))
	# one arm, forward — asymmetry is what makes a rotation legible in a still
	n.add_child(_cylinder_between(Vector3(0.14, 0.46, 0), Vector3(0.44, 0.46, 0.16), 0.035, m))
	n.add_child(_box(Vector3(0, 0.02, 0), Vector3(0.44, 0.05, 0.34),
		m if ghost else _steel_mat(BRASS_DARK)))
	return n
