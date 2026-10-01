extends Node3D
## The scene of the soft body study. It is given: it joins the parts.
##   Cloth       ours, cloth.gd. Its child Hand holds one corner; the supplied
##               mover moves the Hand on the four move keys
##   SoftCloth   the soft body Godot has built in, with soft_cloth.gd
##   Walker      the supplied walker on its autopilot: `pause` (Space) sends it
##               to its next stop: into our cloth, behind it, into it again,
##               and back to where it started
##   `drop` (M)  lets go of the cloth: first the nail, then the hand
## Every step of the physics it tells the cloth what to keep out of: the floor
## and the walker. It asks the cloth for nothing the cloth does not have yet,
## so it runs with every stage of the lesson.

const Look := preload("res://supplied/look.gd")
const STOPS := [Vector3(-1.0, 0.0, 0.0), Vector3(-1.0, 0.0, -1.8), Vector3(-1.0, 0.0, 0.0), Vector3(-2.4, 0.0, 1.0)]   # our cloth hangs over (-1, 0, 0)
const SKIN := 0.04                     # metres the cloth keeps from a body, so that it lies on it and not in it

var stop := -1   # the stop the walker last went to; -1: it has not moved yet

func _ready() -> void:
	$Cloth/Hand.material_override = Look.paint(Look.BONE)
	$Readout.modulate = Look.INK
	$Readout.outline_modulate = Look.SHADE

func _physics_process(_delta: float) -> void:
	if not $Cloth.has_method("meet"):
		return
	# The floor, as a ball two kilometres across with its top at the floor.
	$Cloth.meet(Vector3(0.0, -1000.0, 0.0), Vector3(0.0, -1000.0, 0.0), 1000.0 + SKIN / 4.0)
	# The walker, as a capsule from its shins to its head.
	var feet: Vector3 = $Walker.global_position
	$Cloth.meet(feet + Vector3(0.0, 0.3, 0.0), feet + Vector3(0.0, 1.5, 0.0), 0.3 + SKIN)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause") and not $Walker.walking:
		stop = (stop + 1) % STOPS.size()
		$Walker.walk_to([STOPS[stop]])
	if Input.is_action_just_pressed("drop") and $Cloth.has_method("let_go"):
		$Cloth.let_go()
	var lines := "WASD or arrows: carry the corner    Space: the walker's next stop    M: let go"
	if $Cloth.has_method("report"):
		lines = $Cloth.report() + "\n" + lines
	$Readout.text = lines
