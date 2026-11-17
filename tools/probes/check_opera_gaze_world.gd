extends SceneTree
## Real installed artifacts and their surrounding collision, not just binding presence.
const Opera := preload("res://commons/void/inner_opera.gd")
class BindingOnly extends Opera:
	func _ready() -> void: pass
var game: Node3D
var opera: Node
var folder := ""
var records := []

func legacy_gaze(camera: Camera3D) -> String:
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_basis.z * 14)
	query.collide_with_areas = true
	query.exclude = [game.body.get_rid()]
	var hit: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return ""
	var node := hit.collider as Node
	while node != null:
		if node.is_in_group("inner_opera_object"): return str(node.get_meta("object_id", ""))
		node = node.get_parent()
	return ""

func _initialize() -> void: run.call_deferred()

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	assert(not folder.is_empty())
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.body.scripted_input = true
	game.scene_loaded()
	game.scene_visible()
	# Use the real controller, without starting audio during the collision survey.
	opera = BindingOnly.new()
	game.add_child(opera)
	opera.set_physics_process(false)
	opera.game = game
	assert(opera._read_bindings())
	for floor_index in [1, 2, 14]:
		game.place_player_at_spawn(floor_index)
		var began := Time.get_ticks_msec()
		while Time.get_ticks_msec() - began < 45000:
			await process_frame
			if game.building.content.roots.has(floor_index) and not game.building.content.pending.any(func(job): return int(job.index) == floor_index): break
		for tick in 20: await physics_frame
		opera._bind_what_stands()
		for tick in 3: await physics_frame
		game.body.set_physics_process(false)
		var camera: Camera3D = game.camera
		var wanted: Dictionary = opera.by_floor[floor_index]
		for selector in wanted:
			var key := "%d/%s" % [floor_index, selector]
			var target: Node3D = instance_from_id(int(opera.bound.get(key, 0))) as Node3D
			if target == null: continue
			var solids := []
			for solid in target.find_children("*", "CollisionObject3D", true, false):
				solids.append({"path":str(target.get_path_to(solid)), "type":solid.get_class(), "layer":solid.collision_layer, "at":str(solid.global_position)})
			var box := AABB(target.global_position, Vector3.ZERO)
			var first := true
			for visual in target.find_children("*", "MeshInstance3D", true, false):
				if not visual.is_visible_in_tree() or visual.mesh == null: continue
				var b: AABB = visual.global_transform * visual.get_aabb()
				box = b if first else box.merge(b)
				first = false
			var centre := box.get_center()
			var rays := []
			for offset in [Vector3(0, 0, 3), Vector3(3, 0, 0), Vector3(0, 0, -3), Vector3(-3, 0, 0)]:
				camera.global_position = Vector3(centre.x, float(game.building.spec.levels[floor_index]) + 1.65, centre.z) + offset
				camera.look_at(centre)
				camera.make_current()
				var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_basis.z * 14)
				query.collide_with_areas = true
				query.exclude = [game.body.get_rid()]
				var hits := []
				for step in 6:
					var hit: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
					if hit.is_empty(): break
					hits.append({"path":str(hit.collider.get_path()), "layer":hit.collider.collision_layer, "distance":camera.global_position.distance_to(hit.position)})
					var exclusions: Array[RID] = query.exclude
					exclusions.append(hit.rid)
					query.exclude = exclusions
				rays.append({"from":str(camera.global_position), "legacy":legacy_gaze(camera), "looked_at":opera._looked_at(), "hits":hits})
			records.append({"floor":floor_index, "selector":selector, "expected":wanted[selector], "centre":str(centre), "box":str(box), "solids":solids, "rays":rays})
		FileAccess.open(folder.path_join("world-gaze.json"), FileAccess.WRITE).store_string(JSON.stringify(records, "  "))
		print("OPERA_GAZE surveyed floor ", floor_index)
	opera.free()
	game.queue_free()
	await create_timer(0.2).timeout
	quit()
