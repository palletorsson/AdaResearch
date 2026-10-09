extends Node3D
## One existing field wrapped over a walk-through arch. Same mapping on both sides.
## Display uses vertex displacement; the collider receives identical triangles.
const Kit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const U := 56
const V := 28
const WIDTH := 1.35
const HEIGHT := 2.7
const LENGTH := 2.0
const DEPTH := 0.55
var work: Node3D
var surface: MeshInstance3D
var collider: CollisionShape3D
var marker: MeshInstance3D
var status: Label3D
var raw := PackedFloat32Array()
var vertices := PackedVector3Array()
var displaced := PackedVector3Array()
var indices := PackedInt32Array()
var colours := PackedColorArray()
var reference_mesh: ArrayMesh
var plate := false
var held := false
var revision := 0
var _signature := ""

func build(source: Node3D, title: String) -> void:
	name="NoiseArch";work=source
	# The map's source roots are at y=1.1. Feet stay on the museum floor.
	position=Vector3(-.25,-1.1,-5.1)
	surface=MeshInstance3D.new();surface.name="FieldSurface";add_child(surface)
	var material:=ShaderMaterial.new();material.shader=load("res://algorithms/randomness/simplexnoise/noise_arch.gdshader")
	surface.material_override=material
	var body:=StaticBody3D.new();body.name="SameSurfaceCollision";add_child(body)
	collider=CollisionShape3D.new();body.add_child(collider)
	var sphere:=SphereMesh.new();sphere.radius=.055;sphere.height=.11
	marker=MeshInstance3D.new();marker.mesh=sphere;marker.material_override=Kit.emissive(Color(1,.35,.63),1);add_child(marker)
	status=Label3D.new();status.font_size=36;status.pixel_size=.0025
	status.position=Vector3(0,3.02,-1.06);status.rotation.y=PI;status.text=title;status.set_meta("title",title);add_child(status)
	# Pale ribs retain the unmodified outline at both entrances.
	var lines:=PackedVector3Array()
	for z in [-1.005,1.005]:
		for i in range(U):
			lines.append(base_at(float(i)/U,(z+1)/2));lines.append(base_at(float(i+1)/U,(z+1)/2))
	var a:Array=[];a.resize(Mesh.ARRAY_MAX);a[Mesh.ARRAY_VERTEX]=lines
	var frame:=MeshInstance3D.new();var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES,a)
	frame.mesh=mesh;frame.material_override=Kit.emissive(Color(.9,.88,.77),.4);add_child(frame)
	refresh(false,Vector2.ZERO)

func base_at(u: float, v: float) -> Vector3:
	var angle:float=PI*u
	return Vector3(cos(angle)*WIDTH,sin(angle)*HEIGHT,(v-.5)*LENGTH)

func weight_at(u: float, v: float) -> float:
	return smoothstep(0,.12,minf(u,1-u))*smoothstep(0,.12,minf(v,1-v))

func occupied() -> bool:
	var bodies:Array=get_tree().get_nodes_in_group("em_walker")
	bodies.append_array(get_tree().get_nodes_in_group("player_body"))
	for body in bodies:
		if not body is Node3D:continue
		var p:Vector3=to_local(body.global_position)
		if absf(p.x)<1.85 and absf(p.z)<1.25 and p.y>-.3 and p.y<3.4:return true
	return false

func refresh(flat: bool, sample: Vector2) -> void:
	var signature:String=JSON.stringify(work.generator_readback())+str(flat)
	if signature!=_signature:
		held=occupied() and revision>0
		if not held:
			plate=flat;rebuild();_signature=signature
	else: held=false
	status.text=str(status.get_meta("title"))+ ("\nHeld while occupied" if held else "\nSame field / another body")
	# Five shared addresses are exact vertices of this denser sampling grid.
	if not displaced.is_empty():
		var u:int=clampi(roundi((sample.x+2)/3.5*U),0,U)
		var v:int=clampi(roundi((sample.y+2)/3.5*V),0,V)
		var direction:=Vector3(cos(PI*float(u)/U),sin(PI*float(u)/U),0)
		marker.position=displaced[v*(U+1)+u]-direction*.075

func rebuild() -> void:
	vertices.clear();displaced.clear();indices.clear();raw.clear();colours.clear()
	var samples:=PackedVector2Array();var coords:=PackedVector2Array();var normals:=PackedVector3Array()
	var depth:float=0.0 if plate else DEPTH
	for j in range(V+1):
		var v:float=float(j)/V
		for i in range(U+1):
			var u:float=float(i)/U
			var value:float=work.sample_at(-2+3.5*u,-2+3.5*v)
			var weight:float=weight_at(u,v)
			var base:Vector3=base_at(u,v)
			var direction:=Vector3(cos(PI*u),sin(PI*u),0)
			vertices.append(base);raw.append(value);samples.append(Vector2(value,weight));coords.append(Vector2(u,v));normals.append(direction)
			displaced.append(base+direction*value*weight*depth)
			colours.append(Color(.16,.22,.42).lerp(Color(.96,.86,.48),(value+1)*.5))
	for j in range(V):
		for i in range(U):
			var k:int=j*(U+1)+i
			indices.append_array(PackedInt32Array([k,k+1,k+U+1,k+1,k+U+2,k+U+1]))
	var a:Array=[];a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX]=vertices;a[Mesh.ARRAY_NORMAL]=normals;a[Mesh.ARRAY_TEX_UV]=samples
	a[Mesh.ARRAY_TEX_UV2]=coords;a[Mesh.ARRAY_COLOR]=colours;a[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a)
	surface.mesh=mesh;surface.custom_aabb=AABB(Vector3(-1.95,-.05,-1.1),Vector3(3.9,3.35,2.2))
	surface.material_override.set_shader_parameter("relief_depth",depth)
	a[Mesh.ARRAY_VERTEX]=displaced
	reference_mesh=ArrayMesh.new();reference_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a)
	var faces:=PackedVector3Array()
	for index in indices: faces.append(displaced[index])
	var shape:=ConcavePolygonShape3D.new();shape.set_faces(faces);shape.backface_collision=true
	collider.shape=shape;revision+=1
