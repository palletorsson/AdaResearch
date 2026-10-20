extends Node3D
## An optional identity cue, independent of the experiment's material and record.
var bench: Node3D
var part_index: int=-1
var enabled:=false
var frames: Array[MeshInstance3D]=[]
var labels: Array[Label3D]=[]
var edges: Array=[]

func setup(host: Node3D) -> void:
	bench=host
	for i in bench.pieces.size():
		if bench.pieces[i].item==1 and bench.pieces[i].label=="Screen": part_index=i;break
	if part_index<0: return
	var bounds: AABB=bench.pieces[part_index].bounds.grow(0.015)
	var ink:=StandardMaterial3D.new();ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;ink.albedo_color=Color("ffd479")
	var mesh:=ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_LINES,ink)
	for i in 8:
		for j in range(i+1,8):
			var a:=bounds.get_endpoint(i);var b:=bounds.get_endpoint(j)
			var d:=a-b
			if int(not is_zero_approx(d.x))+int(not is_zero_approx(d.y))+int(not is_zero_approx(d.z))==1:
				mesh.surface_add_vertex(a);mesh.surface_add_vertex(b)
	mesh.surface_end()
	for side in 2:
		var frame:=MeshInstance3D.new();frame.mesh=mesh;add_child(frame);frames.append(frame)
		var rods: Array=[]
		for i in 12:
			var rod:=MeshInstance3D.new();var cylinder:=CylinderMesh.new();cylinder.top_radius=0.003;cylinder.bottom_radius=0.003;cylinder.height=1;cylinder.radial_segments=6
			rod.mesh=cylinder;rod.material_override=ink;add_child(rod);rods.append(rod)
		edges.append(rods)
		var label:=Label3D.new();label.font_size=30;label.pixel_size=0.002;label.outline_size=9
		label.modulate=Color("ffe5a6");label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label);labels.append(label)
	refresh()
	bench.changed.connect(refresh)

func centre(side: int=1) -> Vector3:
	if part_index<0: return bench.to_global(Vector3(bench.SIDE,1.25,0))
	var part: Dictionary=bench.pieces[part_index]
	return part.views[side].global_transform*part.bounds.get_center()

func refresh() -> void:
	visible=enabled and not bench.gallery_open and part_index>=0
	if part_index<0: return
	var part: Dictionary=bench.pieces[part_index]
	for side in 2:
		frames[side].global_transform=part.views[side].global_transform
		var bounds: AABB=part.bounds.grow(0.015)
		var n:=0
		for i in 8:
			for j in range(i+1,8):
				var d:=bounds.get_endpoint(i)-bounds.get_endpoint(j)
				if int(not is_zero_approx(d.x))+int(not is_zero_approx(d.y))+int(not is_zero_approx(d.z))!=1: continue
				var a: Vector3=part.views[side].global_transform*bounds.get_endpoint(i)
				var b: Vector3=part.views[side].global_transform*bounds.get_endpoint(j)
				var up: Vector3=(b-a).normalized()
				var x: Vector3=up.cross(Vector3.FORWARD if absf(up.z)<0.9 else Vector3.RIGHT).normalized()
				edges[side][n].global_transform=Transform3D(Basis(x,up*a.distance_to(b),x.cross(up)),(a+b)*0.5);n+=1
		labels[side].global_position=centre(side)+Vector3.UP*0.24
		labels[side].text="CRT screen / whole" if side==0 else "CRT screen → "+("separated" if bench.disorder<=0.5 else "hybrid "+["A","B","C","D"][int(bench.hybrids[part_index].group)])

func observation(camera: Camera3D) -> Dictionary:
	if part_index<0: return {"available":false}
	var part: Dictionary=bench.pieces[part_index]
	var point:=centre()
	var pixel:=camera.unproject_position(point)
	return {"available":true,"marked":enabled,"source":"computer_monitor","part_key":part.key,"label":part.label,"hybrid":int(bench.hybrids[part_index].group),"right_world":bench.Hybrid.pack(part.views[1].global_transform),"left_world":bench.Hybrid.pack(part.views[0].global_transform),"centre_pixel":[pixel.x,pixel.y],"centre_in_frustum":camera.is_position_in_frustum(point),"visibility_note":"Frustum inclusion is not an occlusion or recognition test."}
