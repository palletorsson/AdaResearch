extends RefCounted
## Fitted playground finish for the existing metre-addressed workshop grammar.
## Dimensions are physical, shared by the visible part and its collision shape.
const Kit=preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const Legacy=preload("geometry.gd")
const ROD_SIDES=12
const JOINT_RADIUS=.05 # 20cm diameter at the 2m world unit; always a whole sphere.
static var materials:Dictionary={}

static func finish(role:String)->StandardMaterial3D:
	if not materials.has(role):
		var mat:=StandardMaterial3D.new()
		mat.albedo_color=Color({"rod":"159fea","point":"f3eee0","quad":"ffd447","wedge":"ff7651"}.get(role,"ffd447"))
		mat.roughness=.42;mat.metallic=0
		materials[role]=mat
	return materials[role]

static func panel_vertices(span:float,unit:float)->PackedVector3Array:
	# 15cm rail + 5mm clearance. Square corners now clear the smaller round joint.
	var half:float=span*.5-.04
	var outline:Array[Vector2]=[Vector2(-half,-half),Vector2(half,-half),Vector2(half,half),Vector2(-half,half)]
	var result:=PackedVector3Array()
	for y in [-.018,.018]:
		for p in outline:result.append(Vector3(p.x,y,p.y)*unit)
	return result

static func panel_faces()->Array:
	var faces:Array=[[3,2,1,0],[4,5,6,7]]
	for i in 4:faces.append([i,(i+1)%4,(i+1)%4+4,i+4])
	return faces

static func ramp_vertices(unit:float)->PackedVector3Array:
	# 2m run, EXACTLY 1m rise, 1.6m clear width; 72mm vertical thickness.
	# The low nose tapers inside the bay, never beneath its zero-height plane.
	var result:=PackedVector3Array()
	for x in [-.4,.4]:
		for p:Vector2 in [Vector2(-.5,0),Vector2(.5,.5),Vector2(.5,.464),Vector2(-.428,0)]:
			result.append(Vector3(x,p.y,p.x)*unit)
	return result

static func ramp_faces()->Array:
	return [[0,1,2,3],[4,7,6,5],[0,4,5,1],[1,5,6,2],[2,6,7,3],[3,7,4,0]]

static func shape_for(r:Dictionary,unit:float)->Shape3D:
	if r.kind=="point":
		var sphere:=SphereShape3D.new();sphere.radius=JOINT_RADIUS*unit;return sphere
	if r.kind in ["rod","rod_short"]:
		var cylinder:=CylinderShape3D.new();cylinder.radius=.0375*unit;cylinder.height=(.5 if r.kind=="rod_short" else 1)*unit;return cylinder
	if r.kind in ["quad","wedge"]:
		var shape:=ConvexPolygonShape3D.new()
		shape.points=panel_vertices(float(r.get("span",1)),unit) if r.kind=="quad" else ramp_vertices(unit)
		return shape
	return Legacy.shape_for(r,unit)

static func visual(r:Dictionary,unit:float,phase:String="colour")->MeshInstance3D:
	var mesh:=MeshInstance3D.new()
	if r.kind=="point":
		var sphere:=SphereMesh.new();sphere.radius=JOINT_RADIUS*unit;sphere.height=sphere.radius*2
		sphere.radial_segments=12;sphere.rings=6;mesh.mesh=sphere
	elif r.kind in ["rod","rod_short"]:
		var rod:=CylinderMesh.new();rod.top_radius=.0375*unit;rod.bottom_radius=rod.top_radius
		rod.height=(.5 if r.kind=="rod_short" else 1)*unit;rod.radial_segments=ROD_SIDES;rod.rings=0;mesh.mesh=rod
	elif r.kind=="quad":mesh.mesh=Kit.mesh(panel_vertices(float(r.get("span",1)),unit),panel_faces())
	elif r.kind=="wedge":mesh.mesh=Kit.mesh(ramp_vertices(unit),ramp_faces())
	else:
		mesh.free();mesh=Legacy.visual(r,unit,phase)
	mesh.material_override=finish("rod" if r.kind=="rod_short" else r.kind)
	for child in mesh.get_children():
		if child is MeshInstance3D:child.material_override=finish("rod")
	return mesh
