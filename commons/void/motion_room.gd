# motion_room.gd
# Inherits the Void's _build_player unchanged: one rig, two environments.
extends "res://commons/void/game.gd"

const HeldPoint := preload("res://commons/primitives/point/point_held.tscn")
const LineRoom := preload("res://commons/artifacts/line_black_box/line_black_box.gd")
var meter: Node
var held_study: Node3D
var line_study: Node3D

func _ready() -> void:
	var interface := XRServer.primary_interface
	vr = force_xr or (interface != null and interface.is_initialized())
	_suspend_global_tools()
	catalyst = get_tree().get_first_node_in_group("first_catalyst_ability") as Node3D
	if catalyst != null: catalyst_was_processing = catalyst.is_physics_processing()
	_build_environment()
	_build_room()
	_build_player() # Exact production movement, hands, jump and pickup construction.
	body.add_to_group("player_body")
	place_player(spawn_for(0))
	ready_for_play = true
	meter = MotionMeter.new()
	meter.name = "MotionMeter"
	add_child(meter)
	meter.configure(self, "room")
	print("[void-motion] Same Void rig. Left stick walk/strafe, right stick forward/back and turn, grip grab, A jump, B reset, Y compare tower, X menu.")

func _build_room() -> void:
	_box("Floor", Vector3(0,-0.15,0), Vector3(20,0.3,22), Color("c4bfc5"))
	_box("BackWall", Vector3(0,1.75,-11), Vector3(20,3.5,0.2), Color("ded7df"))
	_box("LeftWall", Vector3(-10,1.75,0), Vector3(0.2,3.5,22), Color("d6cbd8"))
	_box("RightWall", Vector3(10,1.75,0), Vector3(0.2,3.5,22), Color("d6cbd8"))
	_box("FrontWall", Vector3(0,1.75,11), Vector3(20,3.5,0.2), Color("ded7df"))
	for z in range(-9,10):
		_box("MetreMark", Vector3(0,0.006,z), Vector3(2.2,0.01,0.035), Color("65536e"), false)
	for x in [-1.3,1.3]:
		_box("Lane", Vector3(x,0.008,0), Vector3(0.035,0.01,19), Color("ce7098"), false)
	for z in range(-9,10,2):
		_box("SightPost", Vector3(-9.85,1.4,z), Vector3(0.05,2.8,0.13), Color("534457"), false)
	held_study = HeldPoint.instantiate()
	held_study.name = "ExistingCoordinatePoint"
	held_study.position = Vector3(-4,0,1)
	add_child(held_study)
	line_study = LineRoom.new()
	line_study.name = "ExistingLineRoom"
	line_study.position = Vector3(5,0,-3)
	add_child(line_study)
	_words("THE VOID / MOVEMENT ROOM", Vector3(0,2.7,-10.82), 0.004)
	_words("Left stick: walk/strafe. Right stick: forward/back and turn.\nWalk the centre lane, then try carrying a point.\nA: jump   B: reset   Y: compare tower   X: menu\nDesktop: WASD / Space / R / T / M", Vector3(0,1.7,-10.82), 0.0017)
	_words("SAME POINT / SAME GRIP", Vector3(-4,2.4,-0.4), 0.0017)

func _box(title: String, at: Vector3, size: Vector3, colour: Color, solid := true) -> void:
	var host: Node3D = StaticBody3D.new() if solid else Node3D.new()
	host.name = title
	host.position = at
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var finish := StandardMaterial3D.new()
	finish.albedo_color = colour
	finish.roughness = 0.9
	mesh.material_override = finish
	host.add_child(mesh)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		host.add_child(collision)
	add_child(host)

func _words(text: String, at: Vector3, pixel: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.pixel_size = pixel
	label.font_size = 36
	label.modulate = Color("35243f")
	label.outline_size = 0
	add_child(label)

func _physics_process(_delta: float) -> void:
	if ready_for_play and not returning and body.global_position.y < -2.0: die("Reset")

func spawn_for(_index: int) -> Vector3:
	return Vector3(0,0.06,7)

func die(_reason: String) -> void:
	for pickup in pickups: pickup.drop_object()
	line_study.reset_line()
	held_study.point.global_transform = held_study.global_transform * Transform3D(Basis.IDENTITY, held_study.CENTRE)
	held_study.point.linear_velocity = Vector3.ZERO
	held_study.point.angular_velocity = Vector3.ZERO
	place_player(spawn_for(0))

func _left_button(button: String) -> void:
	if returning: return
	if button == "ax_button": return_to_menu()
	elif button == "by_button": compare_tower()

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo: return
	if event.keycode == KEY_M: return_to_menu()
	elif event.keycode == KEY_R: die("Reset")
	elif event.keycode == KEY_T: compare_tower()

func compare_tower() -> void:
	if returning: return
	returning = true
	_set_enabled(false)
	meter.save_report()
	motion_test_requested = true
	Route.load_scene(self, "res://commons/void/void.tscn")
