extends "res://tools/probes/transformation_encounters.gd"
var completed := false
func landing_checks() -> void:
	museum.call("flush_stamps")
	var stream = museum.get("_portal_stream")
	if stream != null: stream.process_mode = Node.PROCESS_MODE_DISABLED
	var player = museum.get("_player")
	if player is Node3D:
		player.hide(); player.process_mode = Node.PROCESS_MODE_DISABLED
		player.global_position = Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes := CameraAttributesPractical.new()
	attributes.exposure_multiplier = .35
	camera.attributes = attributes
	var colony := find_scene("/PhysarumColony.gd")
	check("Existing Physarum colony is present",colony != null)
	if colony == null: return
	observations.colony_position = xyz(colony.global_position)
	observations.colony_scale = xyz(colony.global_basis.get_scale())
	observations.agent_count = colony.get("num_agents")
	observations.hall_position = xyz(hall.global_position)
	var adapter := find_scene("/physarum_museum.gd")
	var origin: Vector3 = colony.global_position - hall.global_basis * Vector3(5.5,0,3.5)
	if adapter != null: origin = adapter.global_position - hall.global_basis * Vector3(4.5,0,2.5)
	observations.map_origin = xyz(origin)
	await snapshot("above-before",origin+hall.global_basis*Vector3(6.5,20,15),origin+hall.global_basis*Vector3(6.5,0,5.5),60)
	await snapshot("entry-before",origin+hall.global_basis*Vector3(6.5,1.7,1.5),colony.global_position+Vector3.UP*.4,65)
	await snapshot("colony-before",colony.global_position+Vector3(2.5,3,3.5),colony.global_position,65)
	if adapter != null:
		check("Original simulation has a private physics world",colony.get_world_3d()!=hall.get_world_3d())
		check("Original 50m terrain and 300 agents retained",colony.terrain_size==Vector2(50,50) and colony.num_agents==300)
		check("Outer display has bounded dimensions",adapter.screen.mesh.size==Vector2(2.8,2.8))
		var signal_before: float = colony.grid.get_slime(128,128)
		await create_timer(1).timeout
		observations.center_signal_before=signal_before
		observations.center_signal_after=colony.grid.get_slime(128,128)
		check("Original colony continues depositing",colony.grid.get_slime(128,128)>0)
		adapter.apply_grid_config({"anchorage":"pair"})
		check("Display forwards the existing anchorage control",colony.anchorage=="pair" and colony.CAROUSEL[colony.dist_mode]=="pair")
		adapter.apply_grid_config({"anchorage":"triad"})
		await create_timer(1).timeout
		await snapshot("live-colony-table",adapter.to_global(Vector3(0,2.9,2.0)),adapter.to_global(Vector3(0,1,0)),70)
		await learner_checks(origin)
	completed = true

func clear_at(p: Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=.24;shape.height=1.65
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform.origin=p+Vector3.UP*.9
	return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func learner_checks(origin: Vector3) -> void:
	var study=load("res://doc/book/iterations/2026-10-10-swarm-a-trace-outside/printed/study.tscn").instantiate()
	hall.add_child(study)
	study.global_transform=Transform3D(hall.global_basis*Basis(Vector3.UP,-PI/2),origin+hall.global_basis*Vector3(8.5,0,3.0))
	await tick();study.set_process(false)
	check("Printed six-point study constructed in this hall",study.points.size()==6 and study.tiles.size()==256)
	var approach:Vector3=study.to_global(Vector3(0,.01,2.05))
	check("Learner controls have supported clear approach",not floor_at(approach).is_empty() and clear_at(approach))
	var aisle:=true
	for z in range(2,8):
		var p:Vector3=origin+hall.global_basis*Vector3(6.5,.01,z*.5)
		aisle=aisle and not floor_at(p).is_empty() and clear_at(p)
	check("Approach between both tables retains floor and body clearance",aisle)
	await snapshot("student-start",study.to_global(Vector3(0,2.9,2.3)),study.to_global(Vector3(0,1.2,0)),70)
	study.get_node("Run").emit_signal("pressed")
	for i in range(40):study._process(.15)
	check("Actual run signal produces tick40 in museum",study.trail.steps==40)
	await snapshot("student-trace",study.to_global(Vector3(0,2.9,2.3)),study.to_global(Vector3(0,1.2,0)),70)
	study.get_node("Retention").emit_signal("pressed")
	for i in range(40):study._process(.15)
	check("Actual retention signal resets and compares at same tick",study.trail.steps==40 and study.trail.retention==.55)
	await snapshot("student-short-memory",study.to_global(Vector3(0,2.9,2.3)),study.to_global(Vector3(0,1.2,0)),70)
	observations.caption_occlusion=[]
	for target:Vector3 in [study.caption.global_position,study.to_global(Vector3(0,1.02,-1.0))]:
		var ray:=PhysicsRayQueryParameters3D.create(study.to_global(Vector3(0,1.7,1.75)),target,1)
		var hit:Dictionary=hall.get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():observations.caption_occlusion.append({"target":xyz(target),"hit":xyz(hit.position),"collider":str(hit.collider.get_path())})
	await snapshot("above-after",origin+hall.global_basis*Vector3(6.5,20,15),origin+hall.global_basis*Vector3(6.5,0,5.5),60)

func finish() -> void:
	var result := {"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":completed and failures.is_empty(),"completed":completed,"scope":"Existing museum capture. No headset claim."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if result.passed else 1)
