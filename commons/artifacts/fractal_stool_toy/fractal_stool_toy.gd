extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FractalStoolToy

## @identity
## name: "Fractal furniture"
## tier: small
## lineage: a stool grown from one rule — a leg that decided to keep being legs.
## essence: A held stool whose single leg splits into legs, which split into legs,
##   until enough feet reach the ground to stand. A seat caps the top. The support
##   is recursive: the same "fork into thinner forks" runs three times and a piece
##   of furniture falls out.
## truth: "a leg that splits into legs holds up a seat"
## applications: recurse a strut and get a chair — the branching that makes a tree
##   stable makes furniture stable too.

@export var depth: int = 3
@export var trunk_len: float = 0.12
@export var trunk_radius: float = 0.016
@export var seat_radius: float = 0.16
@export var wood_col: Color = Color(0.62, 0.44, 0.26)
@export var seat_col: Color = Color(0.74, 0.56, 0.34)
@export var label_col: Color = Color(0.82, 0.66, 0.42)

var _t: float = 0.0
var _spin_root: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("depth"):
		depth = clampi(int(config["depth"]), 1, 4)
	if config.has("trunk_len"):
		trunk_len = float(config["trunk_len"])
	if config.has("wood_col"):
		wood_col = _parse_color(config["wood_col"], wood_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_spin_root = null
	_build()


func _build() -> void:
	# Held toy — no table. The recursive support sits near origin, ~0.4m tall.
	var root := Node3D.new()
	root.name = "StoolSpin"
	add_child(root)
	_spin_root = root

	var wood_mat: StandardMaterial3D = _matte_mat(wood_col, 0.7, 0.0)
	var seat_mat: StandardMaterial3D = _matte_mat(seat_col, 0.6, 0.0)

	# The support grows DOWN from the seat: a fork that keeps forking to the floor.
	var seat_y: float = trunk_len * (depth + 1) * 1.4
	var seat_centre := Vector3(0.0, seat_y, 0.0)
	# splay the children downward and outward
	_support(root, seat_centre, Vector3.DOWN, trunk_len, trunk_radius, depth, wood_mat)

	# the seat on top
	root.add_child(_cylinder(seat_centre + Vector3(0.0, 0.01, 0.0), seat_radius, 0.02, seat_mat))
	root.add_child(_torus(seat_centre + Vector3(0.0, 0.02, 0.0), seat_radius * 0.92, 0.008, _matte_mat(wood_col, 0.6)))

	_settle(root, 0.4)
	add_child(_billboard_label("LEGS OF LEGS", Vector3(0.0, 0.5, 0.0), 20, label_col))


func _support(parent: Node3D, base: Vector3, dir: Vector3, length: float, radius: float, d: int, mat: Material) -> void:
	var tip: Vector3 = base + dir.normalized() * length
	parent.add_child(_cylinder_between(base, tip, radius, mat))
	if d <= 1:
		# a little foot pad
		parent.add_child(_sphere(tip, radius * 1.5, mat))
		return
	# split into a small fan of thinner supports reaching further out and down
	var splits: int = 3
	var ref: Vector3 = Vector3.RIGHT if absf(dir.normalized().dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var perp: Vector3 = dir.cross(ref).normalized()
	var spread: float = deg_to_rad(30.0)
	for i in range(splits):
		var about: float = TAU * float(i) / float(splits)
		var axis: Vector3 = perp.rotated(dir.normalized(), about)
		var child_dir: Vector3 = dir.normalized().rotated(axis, spread)
		_support(parent, tip, child_dir, length * 0.82, radius * 0.7, d - 1, mat)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _spin_root != null:
		_spin_root.rotation.y = sin(_t * 0.5) * 0.3
