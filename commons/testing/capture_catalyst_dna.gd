@tool
extends SceneTree
# Capture the full /catalyst-dna gallery: 5 personality stages,
# 4 foe friend modes, and (in a future pass) 12 catalyst bracelet modes.
#
# Output structure: user://catalyst_runs/<category>/<variant>/<angle>.png
#   stages/foe/{front,top}.png
#   stages/wary/{front,top}.png
#   ...
#   foe_modes/transport/{front,top}.png
#   foe_modes/swarm/{front,top}.png
#   ...
#
# Usage:
#   godot --no-window --xr-mode off --script res://commons/testing/capture_catalyst_dna.gd

const FOE_SCENE: PackedScene = preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")

const STAGES: Array = [
	{"id": "foe",     "label": "FOE — chases player, deals damage"},
	{"id": "wary",    "label": "WARY — keeps distance, alert red"},
	{"id": "neutral", "label": "NEUTRAL — ignores player, wanders"},
	{"id": "curious", "label": "CURIOUS — approaches gently, no damage"},
	{"id": "friend",  "label": "FRIEND — chases other foes to convert"},
]

const FOE_MODES: Array = [
	{"id": "goo",         "label": "GOO — default friend, converts on contact"},
	{"id": "transport",   "label": "TRANSPORT — pushes peer foes sideways (blue, wedge)"},
	{"id": "swarm",       "label": "SWARM — leads loose cluster (orange, satellites)"},
	{"id": "drainfriend", "label": "DRAINFRIEND — drags peers back (violet, drain pyramid)"},
]


func _init() -> void:
	var out_root := "user://catalyst_runs"
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("catalyst_runs/stages")
		dir.make_dir_recursive("catalyst_runs/foe_modes")

	# Capture each stage individually
	for stage in STAGES:
		await _capture_single_foe(stage["id"], "", "%s/stages/%s" % [out_root, stage["id"]])

	# Capture each foe mode at FRIEND state (distinct hues + badges)
	for mode in FOE_MODES:
		await _capture_single_foe("friend", mode["id"], "%s/foe_modes/%s" % [out_root, mode["id"]])

	print("[catalyst_dna] complete")
	quit()


func _capture_single_foe(state_id: String, foe_mode_id: String, out_dir: String) -> void:
	var dir := DirAccess.open("user://")
	if dir:
		var rel := out_dir.replace("user://", "")
		dir.make_dir_recursive(rel)

	# Build a fresh scene for this variant
	var root := Node3D.new()
	root.name = "CatalystVariant_%s_%s" % [state_id, foe_mode_id]

	# Ground plate
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)
	floor.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.92, 0.88, 0.78)
	floor_mat.roughness = 0.7
	floor.material_override = floor_mat
	floor.position = Vector3(0, 0, 0)
	root.add_child(floor)

	# Single foe at origin
	var foe: Node3D = FOE_SCENE.instantiate() as Node3D
	root.add_child(foe)
	foe.global_position = Vector3(0, 0.4, 0)
	if foe.has_method("apply_grid_config"):
		var cfg: Dictionary = {"initial_state": state_id}
		if foe_mode_id != "":
			cfg["foe_mode"] = foe_mode_id
		foe.call("apply_grid_config", cfg)

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
	var rim_light := DirectionalLight3D.new()
	rim_light.light_color = Color(1.0, 0.95, 0.88)
	rim_light.light_energy = 0.5
	rim_light.rotation = Vector3(deg_to_rad(15.0), deg_to_rad(160.0), 0.0)
	root.add_child(rim_light)

	# Environment
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
	cam.position = Vector3(0, 0.5, 1.4)
	cam.look_at(Vector3(0, 0.4, 0), Vector3.UP)
	cam.fov = 35.0
	root.add_child(cam)

	# Replace any existing scene root
	var prev := current_scene
	get_root().add_child(root)
	current_scene = root
	if prev != null and prev != root:
		prev.queue_free()

	# Settle frames
	await process_frame
	await process_frame
	await process_frame

	var vp: Viewport = root.get_viewport()
	vp.size = Vector2i(800, 800)
	await process_frame

	var img: Image = vp.get_texture().get_image()
	if img == null:
		print("[catalyst_dna] FAIL: viewport texture null for %s/%s" % [state_id, foe_mode_id])
		return
	img.save_png(out_dir + "/front.png")

	# Top view
	cam.position = Vector3(0, 2.0, 0.001)
	cam.look_at(Vector3(0, 0, 0), Vector3.FORWARD)
	cam.fov = 28.0
	await process_frame
	await process_frame
	var img_top: Image = vp.get_texture().get_image()
	img_top.save_png(out_dir + "/top.png")

	print("[catalyst_dna] saved %s_%s (front+top)" % [state_id, foe_mode_id])
