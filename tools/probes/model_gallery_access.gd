extends "res://tools/probes/model_disagreement_museum.gd"
func landing_checks()->void:
	museum.call("flush_stamps");await create_timer(.8).timeout
	var work:=find_scene("/model_disagreement/model_disagreement.gd")
	if work==null:return
	map_origin=work.global_position-hall.global_basis*Vector3(28.5,0,45.5)
	var shape:=CapsuleShape3D.new();shape.radius=.25;shape.height=1.7
	var grid:Array=[]
	for z in range(0,32):
		var line:=""
		for x in range(0,21):line+="." if supported_clear(Vector3(x+.5,0,z+.5),shape) else "#"
		grid.append(line);print(z," ",line)
	observations.clear_grid=grid
	for p in [Vector3(10.5,0,.5),Vector3(10.5,0,4.5),Vector3(2.5,0,5.5),Vector3(10.5,0,9.5)]:
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=5;query.transform.origin=at(p)+Vector3.UP*.88
		var info:Array=[]
		for h in hall.get_world_3d().direct_space_state.intersect_shape(query,8):
			var owner=h.collider;var index:int=owner.shape_find_owner(h.shape)
			info.append({"node":str(owner.get_path()),"transform":str(owner.shape_owner_get_transform(index)),"shape":str(owner.shape_owner_get_shape(index,0))})
		observations[str(p)]=info
	await snapshot("entry-room",at(Vector3(7,5,9)),at(Vector3(8,1,2)),75)
