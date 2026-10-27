extends "res://commons/artifacts/regularity/pattern_architecture.gd"
## Keep the museum controller and machine textures; replace only its grid receiver.
## Skins belong to the fixed floor, so moving the console cannot move the building.
var receiver_root: Node3D

func _build_skins() -> void:
	var room: Node = Kit.room_root(self)
	if not room.has_meta("void_content_floor"): return
	var building: Node3D = room.get_parent().building
	var index := int(room.get_meta("void_content_floor"))
	var spec: Dictionary = building.spec
	receiver_root = Node3D.new()
	receiver_root.name = "PatternReceivers"
	building.floors[index].add_child(receiver_root)
	var floor_st := SurfaceTool.new()
	var wall_st := SurfaceTool.new()
	floor_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	wall_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := float(spec.width)/2
	var d := float(spec.depth)/2
	var hole := float(spec.shaft_depth)/2
	quad(floor_st,Vector3(-w,.026,-d),Vector3(w*2,0,0),Vector3(0,0,d-hole))
	quad(floor_st,Vector3(-w,.026,hole),Vector3(w*2,0,0),Vector3(0,0,d-hole))
	var cursor := -w
	for shaft in spec.shafts:
		var edge := float(shaft.x)-float(spec.shaft_width)/2
		quad(floor_st,Vector3(cursor,.026,-hole),Vector3(edge-cursor,0,0),Vector3(0,0,hole*2))
		cursor = float(shaft.x)+float(spec.shaft_width)/2
	quad(floor_st,Vector3(cursor,.026,-hole),Vector3(w-cursor,0,0),Vector3(0,0,hole*2))
	# WALLS targets the existing vertical pillar faces; no extra walls are built.
	var half := float(spec.column_width)/2+.012
	var high := float(spec.storey_height)-.55
	for x in spec.column_x:
		for z in spec.column_z:
			for sign_ in [-1,1]:
				quad(wall_st,Vector3(x+sign_*half,0,z-half),Vector3(0,0,half*2),Vector3(0,high,0))
				quad(wall_st,Vector3(x-half,0,z+sign_*half),Vector3(half*2,0,0),Vector3(0,high,0))
	for pair in [[floor_st,"FLOOR"],[wall_st,"WALLS"]]:
		var n := MeshInstance3D.new()
		n.name = "Architecture"+pair[1]
		n.mesh = pair[0].commit()
		n.material_override = Kit.material(Color.WHITE)
		n.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
		n.material_override.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		n.set_meta("receiver",pair[1])
		receiver_root.add_child(n)
		skins.append(n)
	built = true
	refresh()

func _exit_tree() -> void:
	if is_instance_valid(receiver_root): receiver_root.queue_free()
