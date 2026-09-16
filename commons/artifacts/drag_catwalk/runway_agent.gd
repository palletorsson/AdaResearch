extends Node3D
## A runway performer using the same outfit builder as the local player.
## Choreographed head/hands/feet are animation, not simulated body tracking.
const Outfit := preload("res://commons/player/super_drag_outfit.gd")
var outfit: Node3D
var head: Node3D
var left: Node3D
var right: Node3D
var feet: Array[Dictionary] = []
var look_index: int = 0
var walking: bool = false
var yielding: bool = false
var gait: float = 0.0

func _ready() -> void:
	head = Node3D.new()
	head.name = "ChoreographedHead"
	add_child(head)
	left = Node3D.new()
	left.name = "LeftHandTarget"
	add_child(left)
	right = Node3D.new()
	right.name = "RightHandTarget"
	add_child(right)
	outfit = Outfit.new()
	outfit.name = "WornOutfit"
	outfit.position.y = 1.55
	add_child(outfit)
	set_look(look_index)

func set_look(index: int) -> void:
	look_index = posmod(index, Outfit.LOOKS.size())
	if not is_instance_valid(outfit):
		return
	outfit.dress(Outfit.LOOKS[look_index])
	feet.clear()
	# Layer 19 hides only the LOCAL wearer's head. Other agents are ordinary
	# world geometry and must remain visible when the player wears a crown.
	for mesh in outfit.find_children("*", "MeshInstance3D", true, false):
		mesh.layers = 1
	for mesh in outfit.get_children():
		if String(mesh.name).begins_with("Boot") or String(mesh.name).begins_with("Platform"):
			feet.append({"node": mesh, "rest": mesh.position})
	animate(0.0, false)

func animate(distance: float, moving: bool) -> void:
	walking = moving
	gait = distance * TAU / 0.95
	var step := sin(gait) if moving else 0.0
	var sway := sin(gait * 0.5) * 0.018 if moving else 0.0
	outfit.position.x = sway
	outfit.rotation.z = -sway * 0.6
	head.position = Vector3(sway, 1.70, 0)
	head.rotation.z = sway * 0.6 if moving else -0.045
	left.position = Vector3(-0.34, 1.09 if moving else 1.19, -0.06 + step * 0.17)
	right.position = Vector3(0.34, 1.09 if moving else 1.02, -0.06 - step * 0.17)
	outfit.follow(head, left, right)
	for foot in feet:
		var rest: Vector3 = foot.rest
		var stride := step * (-1.0 if rest.x < 0 else 1.0)
		foot.node.position = rest + Vector3(0, maxf(0, stride) * 0.085, stride * 0.16)
