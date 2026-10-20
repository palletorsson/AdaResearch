extends "res://tools/probes/transformation_encounters.gd"
## Photograph saved placements in the actual museum; do not alter the museum plan.
var shots: Array = []

func world_bounds(host: Node3D) -> AABB:
	var bounds := AABB()
	var found := false
	for n in host.find_children("*", "VisualInstance3D", true, false):
		if n is Label3D or not n.is_visible_in_tree() or n.get_world_3d() != host.get_world_3d():
			continue
		var b: AABB = n.global_transform * n.get_aabb()
		if b.size.length_squared() < .00001: continue
		bounds = bounds.merge(b) if found else b
		found = true
	return bounds

func landing_checks() -> void:
	museum.call("flush_stamps")
	var stream = museum.get("_portal_stream")
	if stream != null: stream.process_mode = Node.PROCESS_MODE_DISABLED
	var player = museum.get("_player")
	if player is Node3D:
		player.hide()
		player.process_mode = Node.PROCESS_MODE_DISABLED
		player.global_position = Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes := CameraAttributesPractical.new()
	attributes.exposure_multiplier = .35
	camera.attributes = attributes
	await create_timer(2.0).timeout
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder+"plan.json"))
	var row: Dictionary = {}
	for item in plan.plans:
		if item.map == map_id: row=item;break
	var records: Dictionary = {}
	var origin := hall.global_position
	var center := Vector3.ZERO
	var count := 0
	for r in museum.get("_edit_records"):
		var node = r.get("node")
		if not is_instance_valid(node) or r.get("seg") != hall: continue
		records[str(r.token)] = node
		center += node.global_position
		count += 1
		if r.get("from") is Array and r["from"].size() == 2:
			origin = node.global_position - hall.global_basis * Vector3(float(r["from"][0])+.5,0,float(r["from"][1])+.5)
	origin.y = hall.global_position.y
	if count > 0: center /= float(count)
	center.y = hall.global_position.y + 1.2
	for item in row.get("artifacts",[]):
		var token: String = item.token
		var host: Node3D = records.get(token)
		var shot := {"token":token,"cell":item.cell,"loaded":is_instance_valid(host)}
		if not is_instance_valid(host):
			shots.append(shot)
			continue
		shot.scene = host.scene_file_path
		shot.position = xyz(host.global_position)
		var box := world_bounds(host)
		shot.bounds_position = xyz(box.position)
		shot.bounds_size = xyz(box.size)
		var target := box.get_center() if box.size.length() > .01 else host.global_position+Vector3.UP*.3
		var span := clampf(maxf(box.size.x,maxf(box.size.y,box.size.z)),.55,20)
		var direction := center-target
		direction.y=0
		if direction.length()<.1: direction=host.global_basis.z
		direction=direction.normalized()
		var eye := target + direction*maxf(1.15,span*.8) + Vector3.UP*maxf(.55,span*.65)
		var fov := 65.0
		if token == "science_screen":
			target=host.to_global(Vector3(0,1.15,0))
			eye=host.to_global(Vector3(0,1.15,1.25))
			fov=100.0
		elif token in ["PhysarumColony","flow_field_table"]:
			eye=host.to_global(Vector3(0,2.9,2));target=host.to_global(Vector3(0,1,0))
		elif token == "flocking_controls":
			eye=host.to_global(Vector3(0,.55,1.0));target=host.global_position
		elif token == "boids_aquarium":
			eye=host.to_global(Vector3(0,.75,1.25));target=host.global_position
		elif token == "boids_2d_in_3d":
			eye=host.to_global(Vector3(0,.6,2.0));target=host.global_position
		elif token == "ant_colony_optimization":
			eye=host.to_global(Vector3(0,2.6,-3));target=host.to_global(Vector3(0,2,0))
		elif token in ["ant_colony_walk","particle_swarm_walk","population_account_walk"]:
			eye=host.to_global(Vector3(5,5,6));target=host.to_global(Vector3(0,.8,0))
		await snapshot(token,eye,target,fov)
		shot.image=token+".png"
		shot.camera=xyz(eye)
		shot.target=xyz(target)
		shots.append(shot)
	await snapshot("hall-overview",origin+hall.global_basis*Vector3(8,28,27),origin+hall.global_basis*Vector3(7,0,9),64)

func finish() -> void:
	var result := {"room":map_id,"artifacts":shots,"checks":checks,"failures":failures,
		"completed":hall!=null,"passed":hall!=null and failures.is_empty(),
		"scope":"Actual saved museum placements photographed. Missing live instances are recorded; this is visual inventory, not a behavior or headset test."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if result.passed else 1)
