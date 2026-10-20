extends "res://tools/probes/transformation_encounters.gd"

func press(table: Node3D) -> void:
	var area: Node3D=table.button.get_node("InteractableAreaButton")
	var hand:=Node3D.new();root.add_child(hand)
	XRToolsPointerEvent.pressed(hand,area,area.global_position)
	await create_timer(0.1).timeout
	XRToolsPointerEvent.released(hand,area,area.global_position)
	await create_timer(0.15).timeout
	hand.queue_free()

func landing_checks() -> void:
	root.size=Vector2i(1600,1100)
	var table:=find_scene("/entropy_sorting_table.gd")
	check("sorting table installed in entropy hall",table!=null)
	check("sixteen-site bench retained",find_scene("/entropy_compartments.gd")!=null)
	if table==null:return
	observations["table_world"]=xyz(table.global_position)
	var map_frame: Transform3D=table.get_parent().global_transform*table.get_meta("artifact_map_frame")
	check("authored table placement retained",table.global_position.distance_to(map_frame*Vector3(13.5,0,9.5))<0.05)
	var hit:=floor_at(table.to_global(Vector3(0,0,1.45)))
	check("approach has floor",not hit.is_empty() and absf(hit.position.y-table.global_position.y)<0.03)
	var ray:=PhysicsRayQueryParameters3D.create(table.to_global(Vector3(0.18,1.55,1.6)),table.to_global(Vector3(0.18,1.05,0.94)),1)
	var reach: Dictionary=hall.get_world_3d().direct_space_state.intersect_ray(ray)
	observations["button_reach_hit"]="none" if reach.is_empty() else str(reach.collider.get_path())
	check("clear view and reach to button",reach.is_empty() or table.button.is_ancestor_of(reach.collider))
	await snapshot("arrival",table.to_global(Vector3(-0.3,2.35,3.1)),table.to_global(Vector3(0,1.32,0.05)),49)
	await press(table)
	await create_timer(6.0).timeout
	check("museum pointer delivers kept batch",table.delivered==4 and not table.delivering)
	await snapshot("one-box",table.to_global(Vector3(-0.3,2.35,3.1)),table.to_global(Vector3(0,1.32,0.05)),49)
	await press(table)
	check("museum pointer adds exactly one divider",table.model.stage==1 and table.picture_patterns.size()==4)
	await snapshot("two-boxes",table.to_global(Vector3(-0.3,2.35,3.1)),table.to_global(Vector3(0,1.32,0.05)),49)
	var cube: Node3D=table.cubes[1]
	cube.on_desktop_grab(null);cube.global_position=table.to_global(table.slot_position(2));cube.on_desktop_drop(null)
	await process_frame
	check("installed swap changes WAYS from four to one",table.model.occupants==[0,2,1,3] and table.picture_patterns.size()==1)
	await snapshot("sorted-two-boxes",table.to_global(Vector3(-0.3,2.35,3.1)),table.to_global(Vector3(0,1.32,0.05)),49)
	cube.on_desktop_grab(null);cube.global_position=table.to_global(table.slot_position(1));cube.on_desktop_drop(null)
	await process_frame
	await press(table)
	check("third compartment keeps two pictures",table.model.stage==2 and table.picture_patterns.size()==2)
	await snapshot("three-boxes",table.to_global(Vector3(-0.3,2.35,3.1)),table.to_global(Vector3(0,1.32,0.05)),49)
	await press(table)
	check("fourth compartment keeps one picture",table.model.stage==3 and table.picture_patterns.size()==1)
	await snapshot("four-boxes",table.to_global(Vector3(-0.3,2.35,3.1)),table.to_global(Vector3(0,1.32,0.05)),49)
	await press(table)
	check("return to one box preserves kept batch",table.model.stage==0 and table.delivered==4 and table.picture_patterns.size()==6)
	await snapshot("table-in-hall",table.to_global(Vector3(4,3.2,5.5)),table.to_global(Vector3(1.8,1.1,0)),68)
	observations.scope="Native installed hall, ray-button events and desktop grab/drop hooks. Headset comfort and independent learner understanding still need a human trial."

func finish() -> void:
	var file:=FileAccess.open(folder+"report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations},"\t"));file.close()
	quit(0 if failures.is_empty() else 1)
