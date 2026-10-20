extends "res://tools/probes/transformation_encounters.gd"
func clear_person(p: Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=0.22;shape.height=1.6
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform=Transform3D(Basis(),p+Vector3.UP*0.85)
	return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
func landing_checks() -> void:
	root.size=Vector2i(1600,1050);museum.call("flush_stamps");await create_timer(0.5).timeout
	var bank: Node3D=null
	for node in hall.find_children("*","Node3D",true,false):
		if node.get_script()!=null and str(node.get_script().resource_path).ends_with("ordinary_entropies/jar_states.gd"):bank=node
	check("column bank installed",bank!=null)
	if bank==null:return
	check("full scale",bank.scale.is_equal_approx(Vector3.ONE))
	for i in 4:
		var column: Node3D=bank.jars[i]
		for z in [-0.85,1.0]:
			var p: Vector3=bank.to_global(Vector3(column.position.x,0,z))
			check("floor %d / %s" % [i,z],not floor_at(p).is_empty())
			check("standing space %d / %s" % [i,z],clear_person(p))
		await snapshot("column-"+str(i+1),column.to_global(Vector3(0,1.6,1.05)),column.to_global(Vector3(0,1.1,0)),88)
	var panel: Node3D=bank.get_node("ReadingPanel")
	var approach: Vector3=panel.to_global(Vector3(0,0,0.9))
	check("reading panel has floor",not floor_at(approach).is_empty())
	check("reading panel has clear approach",clear_person(approach))
	await snapshot("reading-panel",panel.to_global(Vector3(0,1.45,1.6)),panel.to_global(Vector3(0,1.45,0)),64)
	check("overview position has floor",not floor_at(bank.to_global(Vector3(0,0,1.4))).is_empty())
	check("overview position clear",clear_person(bank.to_global(Vector3(0,0,1.4))))
	await snapshot("columns-in-room",bank.to_global(Vector3(0,1.65,1.4)),bank.to_global(Vector3(0,1.15,0)),113)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.7
	await snapshot("columns-front",bank.to_global(Vector3(0,1.35,1.4)),bank.to_global(Vector3(0,1.35,0)),70)
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	observations.scope="Two-metre columns at full scale, same retained small-jar data and readings. Front and rear inspection positions plus separate side panel tested. Front orthographic image is a comparison view; room view is perspective. Human and headset reading remain open."
