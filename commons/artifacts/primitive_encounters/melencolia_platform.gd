extends Node3D
## The old 5 × 5 metre court, built out of the kit rather than a new slab.
## Root matches the old CourtDeck centre, so saved poses keep their meaning.
const Cube = preload("platform_block.tscn")
const Sheet = preload("timber_panel_1x1.tscn")
const Long = preload("timber_plank_4m.tscn")
const Short = preload("timber_plank_1m.tscn")
func _ready() -> void:
	for x in 5:
		for z in 5:
			var block := Cube.instantiate() as Node3D
			block.name="Cube_%d_%d"%[x,z];block.position=Vector3(x-2,-.5,z-2);add_child(block)
			var sheet := Sheet.instantiate() as Node3D
			sheet.name="Panel_%d_%d"%[x,z];sheet.position=Vector3(x-2,.458,z-2);add_child(sheet)
			sheet.enabled=false;sheet.collision_layer=1;sheet.collision_mask=0
	# The long line returns as a fitted edge, with a one-metre remainder.
	for axis in 2:
		for side in [-1,1]:
			for entry in [[Long,-.5],[Short,2.0]]:
				var rim: Node3D=entry[0].instantiate()
				rim.name="Rim_%d_%d_%s"%[axis,side,str(entry[1])]
				rim.position=Vector3(entry[1],.5,side*2.375) if axis==0 else Vector3(side*2.375,.5,entry[1])
				if axis==1:rim.rotation.y=PI/2
				add_child(rim);rim.enabled=false;rim.collision_layer=1;rim.collision_mask=0
	for side in [-1,1]:
		var light := SpotLight3D.new();light.name="CourtWorkLightLeft" if side<0 else "CourtWorkLightRight"
		light.position=Vector3(side*2.4,3.4,2.4);light.light_color=Color("ffe3b7")
		light.light_energy=3.0;light.spot_range=9;light.spot_angle=48;light.shadow_enabled=side<0
		add_child(light);light.look_at(to_global(Vector3(0,.5,-.4)),Vector3.UP)
	set_meta("construction_recipe",["construction_cube","timber_panel_1x1","timber_plank_4m","timber_plank_1m"])
	_batch_fixed_visuals()

func _batch_fixed_visuals() -> void:
	# Keep all source bodies/colliders. Repeated fixed skins use GPU instances
	# here; placing one kit member from the palette still yields its own object.
	var groups: Dictionary={}
	for source: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		var mat: Material=source.material_override
		var key := str(source.name)+str(source.mesh.get_aabb().size)
		if not groups.has(key):groups[key]={"mesh":source.mesh,"material":mat,"poses":[]}
		groups[key].poses.append(global_transform.affine_inverse()*source.global_transform)
		source.hide()
	for key in groups:
		var batch := MultiMeshInstance3D.new();batch.name="FixedSkin_"+str(get_child_count())
		batch.multimesh=MultiMesh.new();batch.multimesh.transform_format=MultiMesh.TRANSFORM_3D
		batch.multimesh.mesh=groups[key].mesh;batch.material_override=groups[key].material
		batch.multimesh.instance_count=groups[key].poses.size()
		for i in groups[key].poses.size():batch.multimesh.set_instance_transform(i,groups[key].poses[i])
		add_child(batch)
	set_meta("fixed_draw_groups",groups.size())
