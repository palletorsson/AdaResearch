extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	root.size=Vector2i(1600,1050);museum.call("flush_stamps");await create_timer(0.5).timeout
	var bank: Node3D=null
	var live: Node3D=null
	for node in hall.find_children("*","Node3D",true,false):
		if node.get_script()==null:continue
		var path: String=node.get_script().resource_path
		if path.ends_with("ordinary_entropies/jar_states.gd"):bank=node
		if path.ends_with("entropy_jar/entropy_jar.gd"):live=node
	check("four-jar bank installed",bank!=null)
	check("original shakeable jar retained",live!=null)
	if bank==null:return
	check("four prepared states",bank.jars.size()==4)
	for i in 4:
		var jar: Node3D=bank.jars[i]
		var p: Vector3=bank.to_global(Vector3(jar.position.x,0,1.05))
		check("jar approach has floor "+str(i),not floor_at(p).is_empty())
		var shape:=CapsuleShape3D.new();shape.radius=0.22;shape.height=1.6
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform=Transform3D(Basis(),p+Vector3.UP*0.85)
		check("jar approach clear "+str(i),hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty())
		await snapshot("jar-"+str(i+1),jar.to_global(Vector3(0,1.55,0.72)),jar.to_global(Vector3(0,1.06,0)),48)
	check("overview camera has floor",not floor_at(bank.to_global(Vector3(0,0,1.4))).is_empty())
	await snapshot("four-jars",bank.to_global(Vector3(0,1.65,1.4)),bank.to_global(Vector3(0,1.2,0)),113)
	observations.scope="Four prepared jar states added to the experimental Entropy hall. Original shakeable jar and prefab investigation retained. Supplied native views; no visitor or headset understanding claimed."
