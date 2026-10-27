extends SceneTree
## Isolated UI/board regression probe; captures are native renders, not headset proof.
class Link extends Node:
	var requests: Array = []
	func send_uplink(d: Dictionary) -> void: requests.append(d.duplicate(true))
class Content extends Node:
	var roots: Dictionary = {}
	var trial_id := ""
class Board extends "res://commons/bridge/spawn_menu.gd":
	var camera: Camera3D
	var left: XRController3D
	var right: XRController3D
	var content: Node
	func _xr_active() -> bool: return true
	func _eye() -> Node3D: return camera
	func _hand(which: String) -> XRController3D: return left if which == "left" else right
	func _content() -> Node: return content
	func _player_floor() -> int: return 0

var out := ""
var public_dir := ""
var checks: Array = []
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--public="): public_dir = arg.trim_prefix("--public=")
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks.append({"passed": ok, "label": label})
	print("PREFAB_CHECK ", ok, " ", label)

func frames(n: int) -> void:
	for i in n: await process_frame

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))

func run() -> void:
	root.size = Vector2i(1400, 1000)
	var link := Link.new()
	root.add_child(link)
	var desktop = load("res://commons/bridge/spawn_menu.gd").new()
	link.add_child(desktop)
	desktop._mount_desktop()
	desktop._set_open(true)
	await frames(15)
	var ui = desktop._ui
	ui._public_dir = public_dir
	check(ui._items.size() > 1000, "Complete generated catalogue loads")
	ui._on_search("plank:")
	check(ui._tokens.has("kit:timber_plank_1m") and ui._tokens.has("kit:timber_plank_2m"), "Search distinguishes plank variants")
	ui._show_items(ui._items.keys(), "All prefabs")
	ui._append_page()
	check(ui._shown > 48, "Library is not capped at 48 search results")
	ui._show_items(ui._items.keys().filter(func(k): return str(k).begins_with("kit:")), "Construction kit")
	await frames(20)
	await capture("desktop-library")
	desktop.queue_free()
	await frames(2)
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0, 1.65, 0)
	camera.current = true
	var content := Content.new()
	world.add_child(content)
	var floor_root := Node3D.new()
	world.add_child(floor_root)
	content.roots[0] = floor_root
	var floor_body := StaticBody3D.new()
	floor_root.add_child(floor_body)
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new(); box.size = Vector3(40, 0.2, 40)
	floor_shape.shape = box; floor_shape.position.y = -0.1
	floor_body.add_child(floor_shape)
	var slab := MeshInstance3D.new()
	var slab_mesh := BoxMesh.new(); slab_mesh.size = box.size
	slab.mesh = slab_mesh; slab.position.y = -0.1
	var concrete := StandardMaterial3D.new(); concrete.albedo_color = Color("929a96"); concrete.roughness = 1
	slab.material_override = concrete
	floor_root.add_child(slab)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -30, 0); light.shadow_enabled = true
	world.add_child(light)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("b9c0bb")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE; env.environment.ambient_light_energy = 0.6
	world.add_child(env)
	var board := Board.new()
	board.camera = camera
	board.content = content
	board.left = XRController3D.new()
	board.right = XRController3D.new()
	world.add_child(board.left)
	world.add_child(board.right)
	board.right.position = Vector3(0.3, 1.3, 0)
	board.right.rotation.x = -0.5
	link.add_child(board)
	await frames(20)
	board._set_open(true)
	await frames(25)
	var panel = board._vp3d
	check(panel.screen_size == Vector2(4, 4), "VR board is four by four metres")
	check(panel.get_parent() == board._stand, "Board is world anchored, not attached to hand")
	check(board._ui.label_mode, "VR defaults to compact labels")
	for i in 180: await physics_frame
	var stand = board._stand
	check(absf(stand.global_position.y) < 0.05 and stand.global_basis.y.dot(Vector3.UP) > 0.999, "Freestanding board settles upright on its feet")
	var settled: Vector3 = stand.global_position
	for i in 120: await physics_frame
	check(stand.global_position.distance_to(settled) < 0.02, "Weighted board remains stable without a push")
	var player_pose := camera.global_transform
	camera.position = Vector3(0, 2.5, 2.5)
	camera.look_at(stand.global_position + Vector3.UP * 2.3)
	await frames(5)
	await capture("vr-world-board")
	camera.position = Vector3(5.8, 3.5, 3.0)
	camera.look_at(stand.global_position + Vector3.UP * 2.15)
	await frames(5)
	await capture("vr-standing-board")
	camera.global_transform = player_pose
	stand.apply_impulse(Vector3(0, 0, -65), Vector3(0, 1.8, 0))
	for i in 60: await physics_frame
	check(stand.global_position.distance_to(settled) > 0.04, "Physical impulse moves the unfrozen stand")
	board._set_open(true)
	for i in 90: await physics_frame
	var before: Vector3 = panel.global_position
	board.left.position.x += 2
	await frames(2)
	check(panel.global_position.distance_to(before) < 0.02, "Hand movement does not move the board")
	board._set_open(false)
	check(board._stand.collision_layer == 0 and board._stand.freeze, "Dismissed board leaves no invisible physical obstacle")
	camera.position.x += 2
	board._set_open(true)
	check(board._vp3d == panel and panel.global_position.distance_to(before) > 1.9, "Reopening relocates the same board")
	check(link.requests.is_empty(), "Opening and relocating never send spawn or removal requests")
	var placed_pose: Vector3 = board._stand.global_position
	camera.position.x += 1.0
	board._on_left_button("by_button")
	check(board._stand.global_position.distance_to(placed_pose) > 0.9 and board._vp3d == panel, "Left Y relocates the same prefab board")
	placed_pose = board._stand.global_position
	board._on_spawn_requested("kit:timber_plank_2m", false)
	check(board._stand.visible and not panel.enabled, "Board stays in the room during artifact placement")
	await frames(2)
	check(link.requests.is_empty(), "Selecting prepares placement without spawning")
	board._armed_at = 0
	board._confirm_placement()
	check(link.requests.size() == 1 and link.requests[0].get("prefab") == "kit:timber_plank_2m", "Confirm sends exact catalogue identifier once")
	check(board._stand.global_position.distance_to(placed_pose) < 0.04, "Spawning does not relocate the board")
	board._on_spawn_requested("kit:timber_plank_1m", false)
	board._cancel_placement()
	check(link.requests.size() == 1, "Cancelling does not remove or replace an artifact")
	# Unsupported floor and obstructed volume must preserve the last valid board.
	camera.position = Vector3(100, 1.65, 100)
	var safe_pose: Transform3D = board._stand.global_transform
	check(not board._position_board() and board._stand.global_transform == safe_pose, "Summoning over empty space is refused without losing the old board")
	var passed := checks.all(func(c): return c.passed)
	var file := FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "checks": checks, "physical_headset_test": false}, "  "))
	file.close()
	print("PREFAB_MENU_RESULT ", passed)
	quit(0 if passed else 1)
