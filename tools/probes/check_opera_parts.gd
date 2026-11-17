extends SceneTree
## Named editable studies inside one installation must retain distinct gaze identities.
const Opera := preload("res://commons/void/inner_opera.gd")
class BindingOnly extends Opera:
	func _ready() -> void: pass
class Content extends RefCounted:
	var exhibits := {}
	var props := {}
class Building extends RefCounted:
	var content := Content.new()
class Game extends Node3D:
	var building := Building.new()
	var body: Node3D
	var camera: Camera3D
var game: Game
var opera: Node

func _initialize() -> void: run.call_deferred()

func solid(parent: Node, title: String, at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = title
	body.position = at
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	body.add_child(shape)
	parent.add_child(body)
	return body

func run() -> void:
	game = Game.new()
	root.add_child(game)
	var mount := Node3D.new()
	game.add_child(mount)
	var artifact := Node3D.new()
	artifact.name = "Artifact"
	mount.add_child(artifact)
	var left := solid(artifact, "Left", Vector3(-2, 0, -5))
	var right := solid(artifact, "Right", Vector3(2, 0, -5))
	var other := solid(artifact, "Unbound", Vector3(0, 0, -5))
	game.building.content.exhibits["1/assembly"] = mount
	opera = BindingOnly.new() # A viewport for gaze, without starting the audio service.
	game.add_child(opera)
	opera.set_physics_process(false)
	opera.game = game
	opera.by_floor = {1: {"assembly/Artifact/Left": "left", "assembly/Artifact/Right": "right"}}
	opera._bind_what_stands()
	assert(left.get_meta("object_id") == "left" and right.get_meta("object_id") == "right")
	assert(not other.has_meta("object_id") and not mount.has_meta("object_id"))
	assert(not left.has_node("OperaLook")) # A bound body itself already supplies collision.
	var camera := Camera3D.new()
	game.add_child(camera)
	game.camera = camera
	camera.current = true
	for tick in 3: await physics_frame
	camera.look_at(left.global_position)
	assert(opera._looked_at() == "left")
	camera.look_at(right.global_position)
	assert(opera._looked_at() == "right")
	camera.look_at(other.global_position)
	assert(opera._looked_at().is_empty())
	# Reloading a streamed row must bind the new instance under the same selector.
	var old_instance := left.get_instance_id()
	left.free()
	left = solid(artifact, "Left", Vector3(-2, 0, -5))
	opera._bind_what_stands()
	assert(left.get_instance_id() != old_instance and left.get_meta("object_id") == "left")
	assert(opera.bound["1/assembly/Artifact/Left"] == left.get_instance_id())
	# A large invisible interaction trigger must not hide the visible artifact.
	var trigger := Area3D.new()
	trigger.position = Vector3(0, 0, -2)
	var trigger_shape := CollisionShape3D.new()
	var trigger_box := BoxShape3D.new()
	trigger_box.size = Vector3(8, 8, 0.2)
	trigger_shape.shape = trigger_box
	trigger.add_child(trigger_shape)
	game.add_child(trigger)
	for tick in 3: await physics_frame
	camera.look_at(right.global_position)
	assert(opera._looked_at() == "right", "Invisible triggers must not occlude singing")
	trigger.free()
	other.free()
	var tiny := solid(artifact, "TinyPoint", Vector3(0, 0, -6))
	(tiny.get_child(0).shape as BoxShape3D).size = Vector3.ONE * 0.14
	opera._bind(tiny, "tiny")
	for tick in 3: await physics_frame
	camera.look_at(Vector3(0.35, 0, -6))
	assert(opera._gaze_ray(camera, -camera.global_basis.z).is_empty())
	assert(opera._looked_at() == "tiny", "A small head movement must not lose a tiny study")
	# An unrelated scene camera cannot become the visitor's attention.
	var other_camera := Camera3D.new()
	game.add_child(other_camera)
	other_camera.rotation.y = PI
	other_camera.make_current()
	assert(opera._looked_at() == "tiny")
	other_camera.free()
	# Tolerance is still subject to world collision: no songs through walls.
	var wall := solid(game, "Wall", Vector3(0, 0, -2))
	(wall.get_child(0).shape as BoxShape3D).size = Vector3(8, 8, 0.2)
	for tick in 3: await physics_frame
	assert(opera._looked_at().is_empty(), "A physical wall must occlude the study")
	opera.free()
	game.queue_free()
	await process_frame
	print("OPERA_PARTS PASS: named studies; stream reload; trigger transparency; small-target tolerance; visitor camera; wall occlusion")
	quit()
