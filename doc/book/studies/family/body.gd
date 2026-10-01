extends Node3D

# 0 flat   1 a chain   2 a chain with offset pivots   3 two chains from one hip
@export_enum("flat", "a chain", "a chain with offset pivots", "two chains from one hip") var parenting := 0

# where each pivot stands, in the body's own numbers: metres from the root
var point_at := Vector3(-0.8, 0.075, 0.0)
var plane_at := Vector3(-0.2, 0.02, 0.0)
var cube_at := Vector3(0.55, 0.25, 0.0)
var limb_at := Vector3(0.55, 0.25, 0.25)
var walk_middle := Vector3(1.2, 1.12, 0.45)   # the middle of our walk, in the walk's own numbers

var shift := Vector3.ZERO       # how far every pivot stands from its part's middle
var speed := deg_to_rad(30.0)   # radians per second
var limit := deg_to_rad(30.0)   # the turn stops here
var angle := 0.0
var pivots: Array[Node3D] = []

func _ready() -> void:
	if parenting == 2:
		shift = Vector3(-0.25, 0.0, 0.0)
	if parenting == 0:
		add_part("point", self, point_at, Vector3.ZERO)
		add_part("plane", self, plane_at, walk_middle)
		add_part("cube", self, cube_at, Vector3.ZERO)
		add_part("limb", self, limb_at, Vector3.ZERO)
	if parenting == 1 or parenting == 2:
		var point := add_part("point", self, point_at, Vector3.ZERO)
		var plane := add_part("plane", point, plane_at, walk_middle)
		var cube := add_part("cube", plane, cube_at, Vector3.ZERO)
		add_part("limb", cube, limb_at, Vector3.ZERO)
	if parenting == 3:
		var plane := add_part("plane", self, plane_at, walk_middle)
		add_part("point", plane, point_at, Vector3.ZERO)
		var cube := add_part("cube", self, cube_at, Vector3.ZERO)
		add_part("limb", cube, limb_at, Vector3.ZERO)

func add_part(kind: String, parent: Node3D, at: Vector3, middle: Vector3) -> Node3D:
	var pivot := Node3D.new()
	parent.add_child(pivot)
	pivot.global_position = to_global(at + shift)
	var part: Node3D = load("res://parts/" + kind + "_part.tscn").instantiate()
	pivot.add_child(part)
	part.position = -(middle + shift)
	pivot.name = part.name + "Pivot"
	pivots.append(pivot)
	return pivot

func _process(delta: float) -> void:
	angle += speed * delta
	if angle > limit:
		angle = limit
	for pivot in pivots:
		pivot.rotation.y = angle
