extends RefCounted
## Fitted playground finish for the existing metre-addressed workshop grammar.
## Dimensions are physical, shared by the visible part and its collision shape.
const Kit=preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const Legacy=preload("geometry.gd")
const ROD_SIDES=12
const JOINT_RADIUS=.05 # 20cm diameter at the 2m world unit; always a whole sphere.
static var materials:Dictionary={}
## THE WHITE PALETTE (opt-in, Palle 2026-11-09: "for all the playground in the sequence we should use the white shader
## (since we have not introduced color yet). Use the same outline shader as in Primitives Ignorance"). Floor 8's white
## (PlatonicStudy.finish) with dark FEATURE edges (edge_outline.gd), on these same slim fitted parts. A rod shows its two
## rims, a panel its outline, a joint only its silhouette (40 degrees: a 12-sided rod's 30-degree facets stay smooth).
## Nothing changes for a part without palette "white".
const PALETTE_WHITE:="white"
const EDGE_ANGLE:=40.0
const EdgeOutline=preload("res://commons/void/edge_outline.gd")
const PlatonicStudy=preload("res://commons/void/platonic_study.gd")
static var _white:StandardMaterial3D

static func white_finish()->StandardMaterial3D:
	if _white==null:_white=PlatonicStudy.finish()
	return _white

## One mesh (and its mesh children): white, with its edge overlay as a CHILD. For a lone visual (the workstation's
## miniature, the glass box's built pieces) that is moved as one node.
static func white(mesh:MeshInstance3D)->MeshInstance3D:
	for node:Node in [mesh]+mesh.find_children("*","MeshInstance3D",true,false):
		if not solid(node):continue
		node.material_override=white_finish();EdgeOutline.refresh(node,EDGE_ANGLE)
	return mesh

## Every solid mesh directly under a playground body: white, with its edge overlay as a SIBLING (same parent, the
## overlay's own pose composed in), so the playground's static batching draws the lines as it draws the faces.
static func whiten(host:Node3D)->int:
	var count:=0
	for node in host.get_children():
		if not node is MeshInstance3D or not solid(node):continue
		node.material_override=white_finish();count+=1
		var line:=EdgeOutline.overlay(node.mesh,EDGE_ANGLE)
		if line==null:continue
		line.name=EdgeOutline.NAME+str(count);line.transform=node.transform*line.transform;host.add_child(line)
	return count

## A surface the white takes: an opaque, visible mesh that is not itself an edge overlay. Glass, water and shader
## looks keep theirs (edge_outline's own test also skips by name, and would skip a pool's "Shell").
static func solid(node:Node)->bool:
	if not node is MeshInstance3D or node.name.begins_with(EdgeOutline.NAME):return false
	var mesh:MeshInstance3D=node
	if mesh.mesh==null or mesh.mesh is ImmediateMesh or not mesh.visible or mesh.layers==0:return false
	var material:Material=mesh.material_override
	if material is ShaderMaterial:return false
	var base:=material as BaseMaterial3D
	if base!=null and (base.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED or base.albedo_color.a<.99):return false
	return true

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
