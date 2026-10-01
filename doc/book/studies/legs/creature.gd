extends Node3D
## A creature: four legs under one body, and the body follows its feet.

const Look := preload("res://supplied/look.gd")
const LEG := preload("res://leg.tscn")
const ORDER := [0, 2, 1, 3]              # whose turn it is: a foot, then the foot across from it

@export var segments := 3                # parts in each leg
@export var heading := Vector3.RIGHT     # the way the feet reach; Vector3.ZERO and it stands
@export var lead := 0.2                  # metres a foot reaches ahead of its rest place
@export var ride := 0.4                  # metres the body rides above the middle of its feet
@export var beat := 0.2                  # seconds from one foot's turn to the next foot's
@export var leash := 0.0                 # metres from its start before it turns; 0: until the ground ends
@export_flags_3d_physics var ground := 1 # the layers that are ground for its feet
@export var hand: Node3D                 # if set, the first foot goes where this node is

var legs: Array[Node3D] = []
var turn := 0        # a place in ORDER
var clock := 0.0     # seconds since the last turn
var home := Vector3.ZERO

func _ready() -> void:
	var trunk := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.7, 0.16, 0.44)
	trunk.mesh = box
	trunk.material_override = Look.paint(Look.BODY)
	add_child(trunk)
	trunk.create_convex_collision()          # a StaticBody3D: what a walker and a marble meet
	for i in 4:
		var out := Vector3.RIGHT.rotated(Vector3.UP, deg_to_rad(45 + 90 * i))   # the way this leg leaves the body
		var leg := LEG.instantiate()
		leg.segments = segments
		leg.ground = ground
		leg.position = Vector3(signf(out.x) * 0.3, 0, signf(out.z) * 0.18)
		leg.rotation_degrees = Vector3(0, 45 + 90 * i, 90)   # a quarter turn about z lays the leg on its side
		add_child(leg)
		leg.target = leg.to_global(Vector3(0, -leg.reach, 0)) + Vector3.DOWN * ride
		leg.foot = leg.target
		legs.append(leg)
	home = global_position

func _physics_process(delta: float) -> void:
	clock += delta
	if clock >= beat:                        # one foot's turn to find the ground
		clock = 0.0
		var leg := legs[ORDER[turn]]
		turn = (turn + 1) % 4
		if leash > 0.0 and (global_position - home).dot(heading) > leash:
			heading = -heading               # far enough: turn round
		leg.lead = heading * lead
		if not leg.find_ground():
			heading = -heading               # no ground there: turn round
	if hand != null:
		legs[0].target = hand.global_position
	var middle := Vector3.ZERO
	for leg in legs:
		middle += leg.foot / 4.0
	global_position = middle + Vector3.UP * ride   # the body follows its feet
	for leg in legs:
		leg.step(delta)                            # and each leg follows its foot
