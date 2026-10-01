extends Node3D
## Supplied with this kit: the slider rail, a slider you work with your body.
## One contract: while `who` stands on the rail, `held` is true and `value` is
## where it stands along it, from `low` at this node's own place to `high`,
## `length` metres along its own +x (turn the node and the rail turns with it).
## When `who` steps off, `held` is false and `value` stays what it was. Read the two; the rail changes nothing but itself.
## You may set `value` too: the knob then shows it, until `who` steps on.
## The rail draws itself: a LINE along the floor, a BONE knob at `value`, and
## the two end values on plates.

const Look := preload("res://supplied/look.gd")
const Segment := preload("res://supplied/segment.gd")

@export var who: NodePath       # the body the rail listens to: the walker
@export var low := 0.0          # the value at the rail's own place
@export var high := 1.6         # the value at its far end
@export var length := 2.4       # metres
@export var reach := 0.5        # metres beside the line that still count as on it

var held := false               # true while `who` stands on the rail
var value := 0.0:               # read it; set it and the knob follows
	set(given):
		value = clampf(given, minf(low, high), maxf(low, high))
		if is_node_ready():
			_show()

var _knob: MeshInstance3D

func _ready() -> void:
	var line: MeshInstance3D = Segment.new()
	add_child(line)
	line.show_between(Vector3(0.0, 0.02, 0.0), Vector3(length, 0.02, 0.0))
	_knob = MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.07
	ball.height = 0.14
	_knob.mesh = ball
	_knob.material_override = Look.paint(Look.BONE)
	add_child(_knob)
	for end: Array in [[0.0, low], [length, high]]:
		var plate := Look.label("%.1f" % end[1])
		plate.position = Vector3(end[0], 0.02, 0.3)
		add_child(plate)
		plate.global_rotation = Vector3(-PI / 2.0, 0.0, 0.0)    # flat on the floor, its top away from us, however the rail is turned
	_show()

func _physics_process(_delta: float) -> void:
	var body := get_node_or_null(who) as Node3D
	if body == null:
		held = false
		return
	var at := to_local(body.global_position)
	held = absf(at.z) <= reach and at.x >= -reach and at.x <= length + reach
	if held:
		value = lerpf(low, high, clampf(at.x / length, 0.0, 1.0))

func _show() -> void:
	_knob.position = Vector3(inverse_lerp(low, high, value) * length, 0.07, 0.0)
