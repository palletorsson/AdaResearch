extends RefCounted
## The one physical part library shared by the hand model and the large playground.
const Model=preload("model.gd")
const Kit=preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const Finishes=preload("res://commons/modular/construction_materials.gd")

static func vertices(half:int,unit:float,span:float=1) -> PackedVector3Array:
	var corners:Array=[[Vector3.ZERO,Vector3.RIGHT,Vector3(1,0,1)],[Vector3.ZERO,Vector3(1,0,1),Vector3.BACK],[Vector3.ZERO,Vector3.RIGHT,Vector3.BACK],[Vector3.RIGHT,Vector3(1,0,1),Vector3.BACK]][clampi(half,0,3)]
	var centre:Vector3=(corners[0]+corners[1]+corners[2])/3
	var result:=PackedVector3Array()
	for y in [-.018,.018]:
		for p:Vector3 in corners:result.append(((p-centre)*span+Vector3.UP*y)*unit)
	return result

static func shape_for(raw:Dictionary,unit:float) -> Shape3D:
	var r:Dictionary=Model.as_face(raw)
	if Model.is_prefab(r.kind):
		var solid:=ConvexPolygonShape3D.new();solid.points=prefab_vertices(r.kind,unit,Model.prefab_span(r));return solid
	if r.kind=="point":
		if r.get("_seated",false):
			var joint:=ConvexPolygonShape3D.new();joint.points=seated_joint(unit).vertices;return joint
		var sphere:=SphereShape3D.new();sphere.radius=.09*unit;return sphere
	if r.kind=="diag":
		var box:=BoxShape3D.new();box.size=Vector3(.075,Model.vec(r.at).distance_to(Model.vec(r.end)),.075)*unit;return box
	if r.kind in ["rod","rod_short"]:
		var box:=BoxShape3D.new();box.size=Vector3(.075,.5 if r.kind=="rod_short" else 1,.075)*unit;return box
	if Model.is_macro(r.kind):
		var box:=BoxShape3D.new();box.size=Vector3(.18,float(Model.MACRO_UNITS[r.kind]),.18)*unit;return box
	if r.kind=="quad":
		var span:float=float(r.get("span",1));var box:=BoxShape3D.new();box.size=Vector3(span,.036,span)*unit;return box
	var triangle:=ConvexPolygonShape3D.new();triangle.points=vertices(int(r.half),unit,float(r.get("span",1)));return triangle

static func visual(raw:Dictionary,unit:float,phase:String="monochrome") -> MeshInstance3D:
	var r:Dictionary=Model.as_face(raw)
	var mesh:=MeshInstance3D.new()
	if Model.is_prefab(r.kind):
		var faces:Array=Kit.wedge_faces() if r.kind=="wedge" else [[0,3,2,1],[0,1,4],[1,2,4],[2,3,4],[3,0,4]]
		mesh.mesh=Kit.mesh(prefab_vertices(r.kind,unit,Model.prefab_span(r)),faces)
		mesh.material_override=Finishes.surface("timber",phase)
	elif r.kind=="point":
		if r.get("_seated",false):
			var joint:=seated_joint(unit);mesh.mesh=Kit.mesh(joint.vertices,joint.faces)
			mesh.material_override=Finishes.surface("steel",phase);return mesh
		var sphere:=SphereMesh.new();sphere.radius=.09*unit;sphere.height=.18*unit;sphere.radial_segments=12;sphere.rings=6;mesh.mesh=sphere
		mesh.material_override=Finishes.surface("steel",phase)
		# Six physical sockets make the construction rule visible on every node.
		for axis:Vector3i in Model.AXES:
			for direction in [-1,1]:
				var socket:=MeshInstance3D.new();var disk:=CylinderMesh.new();disk.top_radius=.035*unit;disk.bottom_radius=.035*unit;disk.height=.012*unit;disk.radial_segments=8
				socket.mesh=disk;socket.material_override=Finishes.surface("collar",phase);socket.position=Vector3(axis)*direction*.085*unit
				socket.quaternion=Quaternion(Vector3.UP,Vector3(axis)*direction);mesh.add_child(socket)
	elif r.kind=="diag":
		var brace:=BoxMesh.new();brace.size=Vector3(.075,Model.vec(r.at).distance_to(Model.vec(r.end)),.075)*unit;mesh.mesh=brace;mesh.material_override=Finishes.surface("rail",phase)
	elif r.kind in ["rod","rod_short"]:
		var beam:=BoxMesh.new();beam.size=Vector3(.075,.5 if r.kind=="rod_short" else 1,.075)*unit;mesh.mesh=beam;mesh.material_override=Finishes.surface("rail",phase)
	elif Model.is_macro(r.kind):
		# the chain as it will be laid: a one-metre rod per half address and a joint at every metre between
		var length:float=float(Model.MACRO_UNITS[r.kind]);var n:int=int(roundf(length*2))
		for i in n:
			var beam:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(.075,.5,.075)*unit;beam.mesh=box
			beam.material_override=Finishes.surface("rail",phase);beam.position.y=(-length/2+.25+i*.5)*unit;mesh.add_child(beam)
			if i<n-1:
				var joint:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.09*unit;sphere.height=.18*unit;sphere.radial_segments=12;sphere.rings=6;joint.mesh=sphere
				joint.material_override=Finishes.surface("steel",phase);joint.position.y=(-length/2+.5+i*.5)*unit;mesh.add_child(joint)
	elif r.kind=="quad":
		var span:float=float(r.get("span",1));var face:=BoxMesh.new();face.size=Vector3(span,.036,span)*unit;mesh.mesh=face;mesh.material_override=Finishes.surface("timber",phase)
	else:
		mesh.mesh=Kit.mesh(vertices(int(r.half),unit,float(r.get("span",1))),[[0,2,1],[3,4,5],[0,1,4,3],[1,2,5,4],[2,0,3,5]])
		mesh.material_override=Finishes.surface("timber",phase)
		# The join remains legible before colour: a narrow seam on each half.
		var corners:=vertices(int(r.half),unit,float(r.get("span",1)))
		for i in 3:
			var a:Vector3=corners[i+3];var b:Vector3=corners[(i+1)%3+3]
			var seam:=Kit.box(mesh,"PanelSeam",(a+b)*.5,Vector3(.005*unit,a.distance_to(b),.003*unit),Color("555555"),false)
			seam.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	return mesh

static func seated_joint(unit:float)->Dictionary:
	# The connection remains at the grid address. Once a surface closes over it,
	# its upper cap is flush: fittings must not lift a pyramid or trip the walker.
	var vertices:=PackedVector3Array();var faces:Array=[];var rim:Array=[]
	for ring in 4:
		var angle:float=ring*PI/8
		for i in 12:
			vertices.append(Vector3(cos(i*TAU/12)*cos(angle),-sin(angle),sin(i*TAU/12)*cos(angle))*.09*unit)
			if ring==0:rim.append(i)
			if ring>0:faces.append([(ring-1)*12+i,(ring-1)*12+(i+1)%12,ring*12+(i+1)%12,ring*12+i])
	vertices.append(Vector3.DOWN*.09*unit);faces.append(rim)
	for i in 12:faces.append([36+i,36+(i+1)%12,48])
	return {"vertices":vertices,"faces":faces}

static func prefab_vertices(kind:String,unit:float,span:float=1.0)->PackedVector3Array:
	if span==.5:
		# THE CELL SOLIDS (2026-11-06), about the centre of their first 1 m cell. The wedge: .8 of the cell wide,
		# two cells long, one node level high - the bay ramp's slope; its high edge meets the rail as before.
		if kind=="wedge":
			var cell_ramp:=Kit.wedge(unit*.4,unit*.5,unit)
			for i in cell_ramp.size():cell_ramp[i].z+=unit*(.25-.0375)
			return cell_ramp
		return PackedVector3Array([Vector3(-.25,0,-.25)*unit,Vector3(.25,0,-.25)*unit,Vector3(.25,0,.25)*unit,Vector3(-.25,0,.25)*unit,Vector3(0,.5,0)*unit])
	if kind=="wedge":
		# A 2m bay includes its fittings. The 1.6m clear ramp passes between
		# 36cm joints; its high edge meets the outer face of the 15cm rail.
		var ramp:=Kit.wedge(unit*.8,unit*.5,unit)
		for i in ramp.size():ramp[i].z-=unit*.0375
		return ramp
	return PackedVector3Array([Vector3(-.5,0,-.5)*unit,Vector3(.5,0,-.5)*unit,Vector3(.5,0,.5)*unit,Vector3(-.5,0,.5)*unit,Vector3(0,.5,0)*unit])

static func hologram(mesh:Node)->void:
	# Material belongs only to the miniature; physical output keeps its finish.
	if mesh is MeshInstance3D:
		var material:=StandardMaterial3D.new()
		material.albedo_color=Color(.88,.88,.88,.72)
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		material.roughness=.35;material.metallic=.12
		material.emission_enabled=true;material.emission=Color(.26,.26,.26);material.emission_energy_multiplier=.35
		mesh.material_override=material;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in mesh.get_children():hologram(child)

