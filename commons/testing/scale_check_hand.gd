extends SceneTree
## Scale check: build a migrated artifact, find its slider, and place a real hand
## model (commons/body/hands) next to it so we can see whether the ControlPanel's
## cell-fit left the slider hand-reachable. Prints measured widths + screenshots.
##   godot --path . --xr-mode off --no-window --script res://commons/testing/scale_check_hand.gd -- --scene=res://commons/artifacts/shannon_workbench/shannon_workbench.tscn

const HAND_GLB := "res://commons/body/hands/Hand_R_Nails.glb"

var _scene_path := "res://commons/artifacts/shannon_workbench/shannon_workbench.tscn"
var _art: Node3D
var _cam: Camera3D
var _root: Node3D


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var s := str(a)
		if s.begins_with("--scene="): _scene_path = s.split("=", true, 1)[1]

	_root = Node3D.new(); get_root().add_child(_root)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.40, 0.41, 0.44)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.73, 0.76); env.ambient_light_energy = 1.0
	var we := WorldEnvironment.new(); we.environment = env; _root.add_child(we)
	for r in [Vector3(-45, 30, 0), Vector3(-30, -45, 0)]:
		var l := DirectionalLight3D.new(); l.rotation_degrees = r
		l.light_energy = 1.0 if r.y == 30 else 0.5; _root.add_child(l)

	var packed: PackedScene = ResourceLoader.load(_scene_path)
	_art = packed.instantiate()
	_root.add_child(_art)

	_cam = Camera3D.new(); _cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_root.add_child(_cam); _cam.current = true
	_run()


func _run() -> void:
	await process_frame
	await create_timer(1.0).timeout
	await process_frame

	# Find the slider (canonical SliderHorizontal) anywhere under the artifact.
	var slider := _find_by_name_contains(_art, "slider")
	if slider == null:
		print("[scale] no slider found"); quit(1); return
	var sab := _world_aabb(slider)
	print("[scale] slider world width = %.3f m  (height %.3f, depth %.3f)" % [sab.size.x, sab.size.y, sab.size.z])
	print("[scale] slider centre = %s" % str(sab.get_center()))

	# Drop a real hand next to the slider, same height, ~0.18 m to the left.
	var hand_packed: PackedScene = ResourceLoader.load(HAND_GLB)
	var hand := hand_packed.instantiate()
	_root.add_child(hand)
	var hab0 := _world_aabb(hand)
	print("[scale] hand native size = %.3f x %.3f x %.3f m" % [hab0.size.x, hab0.size.y, hab0.size.z])
	var c := sab.get_center()
	hand.global_position = Vector3(c.x - sab.size.x * 0.5 - 0.12, c.y, c.z + 0.05)

	await process_frame
	await create_timer(0.2).timeout
	await process_frame
	# Close-up framing on the slider + hand.
	var box := _world_aabb(slider).merge(_world_aabb(hand))
	var focus := box.get_center(); var diag: float = maxf(0.3, box.size.length())
	_cam.size = diag * 1.2
	_cam.position = focus + Vector3(0.2, 0.25, 1.4).normalized() * diag * 1.6
	_cam.look_at(focus, Vector3.UP)
	await process_frame
	await create_timer(0.2).timeout
	await process_frame
	get_root().get_viewport().get_texture().get_image().save_png("user://scale_check.png")
	print("[scale] saved user://scale_check.png")
	quit()


func _find_by_name_contains(node: Node, frag: String) -> Node3D:
	var f := frag.to_lower()
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Node3D and String(n.name).to_lower().contains(f) and n != node:
			return n
		for c in n.get_children(): stack.append(c)
	return null


func _world_aabb(node: Node) -> AABB:
	var box := AABB(); var first := true; var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is VisualInstance3D:
			var ab: AABB = (n as VisualInstance3D).get_aabb()
			ab = (n as Node3D).global_transform * ab
			if first: box = ab; first = false
			else: box = box.merge(ab)
		for c in n.get_children(): stack.append(c)
	return box
