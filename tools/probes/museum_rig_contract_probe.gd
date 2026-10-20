extends SceneTree
## Load the full production base scene without entering it or altering saves.
## Compare the original to the shared-rig refactor at every original node path.
var failures: Array[String] = []
var checked := 0
var properties := ["transform", "script", "collision_layer", "collision_mask",
	"strafe", "max_speed", "input_action", "turn_mode", "step_turn_angle", "step_turn_delay",
	"jump_button_action", "flight_button", "enabled", "visible", "mode",
	"pickup_axis_action", "action_button_action", "ranged_enable", "active_button_action",
	"collide_with_areas", "show_laser", "laser_length", "suppress_radius", "deadzone",
	"fallback_y_deadzone", "fallback_x_deadzone", "calibrate", "tracker", "pose"]

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var old: Node = load("res://ada_run/museum-rig-before.tscn").instantiate()
	var current: Node = load("res://commons/scenes/base.tscn").instantiate()
	compare(old, old, current)
	var shared: Node = current.get_node("XROrigin3D")
	if shared.scene_file_path != "res://commons/player/museum_rig.tscn": failures.append("base does not instance shared rig")
	var scene_base: Script = load("res://addons/godot-xr-tools/staging/scene_base.gd")
	if current.get_script() != scene_base: failures.append("base scene type changed")
	var out := "res://ada_run/museum-rig-checks"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	FileAccess.open(out.path_join("base-contract.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"nodes_compared":checked,"failures":failures},"\t"))
	print("MUSEUM_RIG_CONTRACT ",checked," nodes; failures: ",failures)
	old.free();current.free()
	quit(0 if failures.is_empty() else 1)

func compare(node: Node, old: Node, current: Node) -> void:
	var path: NodePath = old.get_path_to(node)
	var other := current.get_node_or_null(path)
	checked += 1
	if other == null:
		failures.append("missing: "+str(path));return
	if node.get_class() != other.get_class(): failures.append("type: "+str(path))
	for property in properties:
		if property not in node: continue
		var a = node.get(property)
		var b = other.get(property)
		if a is Resource: a = a.resource_path
		if b is Resource: b = b.resource_path
		if a != b: failures.append(str(path)+":"+property)
	for child in node.get_children(): compare(child,old,current)
