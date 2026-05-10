@tool
extends SceneTree
# Capture the 5 personality stages of CatalystFoe side by side, on a clean
# background (no biome, no curriculum overlay). The output is a single
# image that reads the colour progression cold-grey → alarm-red → earth
# → amber → friend at a glance.
#
# Usage:
#   godot --headless --xr-mode off --script res://commons/testing/capture_catalyst_arc.gd
#
# Output:
#   user://multi_shots/catalyst_arc_demo/{front,top,iso}.png

const FOE_SCENE: PackedScene = preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")

const STATES: Array = [
	{"name": "FOE",     "key": "foe"},
	{"name": "WARY",    "key": "wary"},
	{"name": "NEUTRAL", "key": "neutral"},
	{"name": "CURIOUS", "key": "curious"},
	{"name": "FRIEND",  "key": "friend"},
]


func _init() -> void:
	# Build the scene root
	var root := Node3D.new()
	root.name = "CatalystArcDemo"

	# Ground plate so the foes have something to sit on
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(8.0, 2.0)
	floor.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.92, 0.88, 0.78)
	floor_mat.roughness = 0.7
	floor.material_override = floor_mat
	floor.position = Vector3(0, 0, 0)
	root.add_child(floor)

	# Place 5 foes at x = -3, -1.5, 0, 1.5, 3
	var spacing := 1.5
	for i in range(STATES.size()):
		var foe: Node3D = FOE_SCENE.instantiate() as Node3D
		root.add_child(foe)
		var x: float = (i - (STATES.size() - 1) * 0.5) * spacing
		foe.global_position = Vector3(x, 0.4, 0)
		# Apply state directly via apply_grid_config
		if foe.has_method("apply_grid_config"):
			foe.call("apply_grid_config", {"initial_state": STATES[i]["key"]})

	# Lights
	var key_light := DirectionalLight3D.new()
	key_light.light_color = Color(1.0, 0.96, 0.86)
	key_light.light_energy = 1.2
	key_light.rotation = Vector3(deg_to_rad(-50.0), deg_to_rad(35.0), 0.0)
	root.add_child(key_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.light_color = Color(0.78, 0.86, 1.0)
	fill_light.light_energy = 0.4
	fill_light.rotation = Vector3(deg_to_rad(-30.0), deg_to_rad(-120.0), 0.0)
	root.add_child(fill_light)

	# WorldEnvironment for clean background
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.55, 0.66, 0.50)
	environment.ambient_light_color = Color(0.85, 0.85, 0.90)
	environment.ambient_light_energy = 0.5
	env.environment = environment
	root.add_child(env)

	# Camera — front view
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.2, 4.5)
	cam.look_at(Vector3(0, 0.4, 0), Vector3.UP)
	cam.fov = 35.0
	root.add_child(cam)

	get_root().add_child(root)
	current_scene = root

	# Wait a couple frames for materials to settle, then capture
	await process_frame
	await process_frame
	await process_frame

	# Set viewport size for 16:9 capture
	var vp: Viewport = root.get_viewport()
	vp.size = Vector2i(1600, 600)
	await process_frame

	var img: Image = vp.get_texture().get_image()
	var out_dir := "user://multi_shots/catalyst_arc_demo"
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("multi_shots/catalyst_arc_demo")
	img.save_png(out_dir + "/front.png")
	print("[catalyst_arc] saved front.png")

	# Top view
	cam.position = Vector3(0, 5.0, 0.001)
	cam.look_at(Vector3(0, 0, 0), Vector3.FORWARD)
	cam.fov = 28.0
	await process_frame
	await process_frame
	var img2: Image = vp.get_texture().get_image()
	img2.save_png(out_dir + "/top.png")
	print("[catalyst_arc] saved top.png")

	quit()
