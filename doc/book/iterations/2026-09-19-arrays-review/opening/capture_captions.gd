extends SceneTree
## Same-camera comparison of the real artifact before/after its two caption edits.
## Isolated lighting fixture, not a museum screenshot and not an XR comfort test.
const OUT := "res://doc/book/iterations/2026-09-19-arrays-review/opening/"
var room: Node3D
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size = Vector2i(1600,1000)
	room = Node3D.new()
	root.add_child(room)
	current_scene = room
	var env := WorldEnvironment.new()
	var resource := Environment.new()
	resource.background_mode = Environment.BG_COLOR
	resource.background_color = Color(.12,.14,.17)
	resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	resource.ambient_light_color = Color(.9,.94,1)
	resource.ambient_light_energy = .7
	env.environment = resource
	room.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35,-30,0)
	sun.light_energy = 1.6
	room.add_child(sun)
	var floor_ := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(22,.2,22)
	floor_.mesh = floor_mesh
	floor_.position.y = -.15
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(.23,.25,.28)
	floor_.material_override = mat
	room.add_child(floor_)
	var camera := Camera3D.new()
	camera.position = Vector3(0,2.25,-11)
	camera.fov = 66
	room.add_child(camera)
	camera.look_at(Vector3(0,2.5,0))
	camera.make_current()
	var phases: Array = ["after"] if "--after-only" in OS.get_cmdline_user_args() else ["before","after"]
	for phase in phases:
		var path := OUT + "array_flight_lab-before.gd" if phase == "before" else "res://commons/artifacts/regularity/array_flight_lab.gd"
		var lab = load(path).new()
		room.add_child(lab)
		for i in 80: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + "captions-" + phase + ".png")
		lab.queue_free()
		for i in 3: await process_frame
	quit()
