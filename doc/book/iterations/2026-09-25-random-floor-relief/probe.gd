extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(0.8).timeout
	for n in museum.find_children("*MushroomHand*","Node3D",true,false):n.visible=false
	var ground:=find_scene("/RandomSpace.gd")
	var worley:=find_scene("/worley_noise.gd")
	var gauge:=find_scene("/shannon_entropy_meter.gd")
	check("ground and neighbouring exhibits remain",ground!=null and worley!=null and gauge!=null)
	if ground==null:return
	var vertices: PackedVector3Array=ground.mesh_instance.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var low: float=INF;var high: float=-INF
	for v in vertices:
		var y: float=ground.mesh_instance.to_global(v).y
		low=minf(low,y);high=maxf(high,y)
	var hash_context:=HashingContext.new();hash_context.start(HashingContext.HASH_SHA256);hash_context.update(var_to_bytes(vertices))
	var mat: StandardMaterial3D=ground.mesh_instance.material_override
	observations["ground"]={"position":xyz(ground.global_position),"scale":xyz(ground.global_basis.get_scale()),"lowest":low,"highest":high,"vertices":vertices.size(),"local_mesh_sha256":hash_context.finish().hex_encode(),"color":mat.albedo_color.to_html(false),"emission":mat.emission_energy_multiplier}
	check("visible ground and collision use identical triangles",ground.mesh_instance.mesh.get_faces()==ground.collision_shape.shape.get_faces())
	check("ground remains still",not ground.enable_animation)
	observations["exhibits"]={"worley":xyz(worley.global_position),"gauge":xyz(gauge.global_position)}
	if ground.global_position.y>0.1:
		check("entire ground clears the underlying floor",low>0.02)
		check("cellular image remains above the ground",worley.global_position.y>high+0.01)
	await snapshot("floor-overview",Vector3(10.6,1.7,12.9),Vector3(6.5,0.25,6.0),70)
	await snapshot("cellular-field",Vector3(8.5,1.7,5.7),worley.global_position,53)
