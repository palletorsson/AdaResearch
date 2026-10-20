extends Node3D
## Procedural six-limbed creature: rest geometry and weights built once.
## Animation edits real Skeleton3D poses, never the mesh's source vertices.
var skeleton: Skeleton3D
var skin_mesh: MeshInstance3D
var rest_points: Array[Vector3] = []
var parents: Array[int] = []
var branches: Array = []
var bone_markers: Array[MeshInstance3D] = []
var bone_rods: Array[MeshInstance3D] = []
var overlay: Node3D
var vertices := PackedVector3Array()
var normals := PackedVector3Array()
var indices := PackedInt32Array()
var bones := PackedInt32Array()
var weights := PackedFloat32Array()
var material: StandardMaterial3D
const SIDES := 16
const STEPS := 24

func _ready() -> void:
	skeleton = Skeleton3D.new()
	skeleton.name = "CreatureSkeleton"
	add_child(skeleton)
	bone("Root", -1, Vector3.ZERO)
	bone("Chest", 0, Vector3(0,.38,0))
	bone("Neck", 1, Vector3(0,.69,0))
	bone("Head", 2, Vector3(0,.91,0))
	ellipsoid(Vector3(0,.22,0),Vector3(.33,.55,.25),0,1)
	ellipsoid(Vector3(0,.87,0),Vector3(.26,.30,.23),3,3)
	for row in 3:
		for side in [-1,1]:
			var y := .45-float(row)*.36
			var a := bone("Limb_%s_%s_root"%[row,side],1 if row==0 else 0,Vector3(side*.24,y,0))
			var b := bone("Limb_%s_%s_middle"%[row,side],a,Vector3(side*.76,y+.18,0))
			var c := bone("Limb_%s_%s_tip"%[row,side],b,Vector3(side*1.27,y+.43,.06))
			branches.append([a,b,c])
			tube([rest_points[a],rest_points[b],rest_points[c],Vector3(side*1.46,y+.61,.12)],[a,b,c],.16)
	var tail_a := bone("TailRoot",0,Vector3(0,-.30,0))
	var tail_b := bone("TailMiddle",tail_a,Vector3(0,-.80,0))
	var tail_c := bone("TailTip",tail_b,Vector3(0,-1.30,.08))
	branches.append([tail_a,tail_b,tail_c])
	tube([rest_points[tail_a],rest_points[tail_b],rest_points[tail_c],Vector3(.10,-1.57,.16)],[tail_a,tail_b,tail_c],.20)
	skeleton.reset_bone_poses()
	var data: Array = []
	data.resize(Mesh.ARRAY_MAX)
	data[Mesh.ARRAY_VERTEX]=vertices
	data[Mesh.ARRAY_NORMAL]=normals
	data[Mesh.ARRAY_INDEX]=indices
	data[Mesh.ARRAY_BONES]=bones
	data[Mesh.ARRAY_WEIGHTS]=weights
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,data)
	material=StandardMaterial3D.new()
	material.albedo_color=Color("eab59e")
	material.roughness=.25
	material.metallic=.12
	material.clearcoat_enabled=true
	material.clearcoat=.65
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	skin_mesh=MeshInstance3D.new()
	skin_mesh.name="ProceduralSkin"
	skin_mesh.mesh=mesh
	skin_mesh.material_override=material
	skeleton.add_child(skin_mesh)
	skin_mesh.skeleton=NodePath("..")
	var skin := Skin.new()
	for i in skeleton.get_bone_count():
		skin.add_bind(i,Transform3D(Basis.IDENTITY,-rest_points[i]))
	skin_mesh.skin=skin
	skin_mesh.custom_aabb=AABB(Vector3(-4,-4,-4),Vector3(8,8,8))
	var eyes := BoneAttachment3D.new()
	eyes.bone_name="Head"
	skeleton.add_child(eyes)
	for x in [-.12,0,.12]:
		var eye := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius=.048;sphere.height=.096
		eye.mesh=sphere
		var ink := StandardMaterial3D.new()
		ink.albedo_color=Color("14282a");ink.roughness=.1
		eye.material_override=ink
		eye.position=Vector3(x,.04 if x==0 else -.015,.205)
		eyes.add_child(eye)
	build_overlay()
	pose(0,0,Vector3.ZERO)

func bone(id: String, parent: int, at: Vector3) -> int:
	var index := skeleton.add_bone(id)
	if parent>=0:skeleton.set_bone_parent(index,parent)
	var local := at-(rest_points[parent] if parent>=0 else Vector3.ZERO)
	skeleton.set_bone_rest(index,Transform3D(Basis.IDENTITY,local))
	rest_points.append(at);parents.append(parent)
	return index

func vertex(p: Vector3,n: Vector3,a: int,b: int,w: float) -> void:
	vertices.append(p);normals.append(n.normalized())
	bones.append_array(PackedInt32Array([a,b,0,0]))
	weights.append_array(PackedFloat32Array([1.0-w,w,0,0]))

func connect_rings(start: int,rings: int,sides: int) -> void:
	for r in rings-1:
		for s in sides:
			var a := start+r*sides+s
			var b := start+r*sides+(s+1)%sides
			indices.append_array(PackedInt32Array([a,a+sides,b,b,a+sides,b+sides]))

func ellipsoid(at: Vector3,size: Vector3,a: int,b: int) -> void:
	var start := vertices.size()
	for r in 17:
		var phi := PI*float(r)/16.0
		for s in SIDES:
			var theta := TAU*float(s)/SIDES
			var n := Vector3(sin(phi)*cos(theta),cos(phi),sin(phi)*sin(theta))
			var p := at+n*size
			vertex(p,n/size,a,b,clampf(p.y/.5,0,1) if a!=b else 0.0)
	connect_rings(start,17,SIDES)

func tube(points: Array,chain: Array,radius: float) -> void:
	var start := vertices.size()
	for r in STEPS+1:
		var t := float(r)/STEPS
		var u := t*3.0
		var interval := mini(int(u),2)
		var f := u-interval
		var direction: Vector3=(points[interval+1]-points[interval]).normalized()
		var across:=direction.cross(Vector3.FORWARD).normalized()
		var around:=direction.cross(across).normalized()
		var centre: Vector3=points[interval].lerp(points[interval+1],f)
		var rad := radius*(1.0-pow(t,1.4))+.007
		# Bone centres occur at u=0,1,2; smoothly blend their transforms.
		var ia := mini(int(u),2)
		var ib := mini(ia+1,2)
		var blend:=smoothstep(0.0,1.0,u-float(ia)) if ia!=ib else 0.0
		for s in SIDES:
			var theta:=TAU*float(s)/SIDES
			var n:=across*cos(theta)+around*sin(theta)
			vertex(centre+n*rad,n,chain[ia],chain[ib],blend)
	connect_rings(start,STEPS+1,SIDES)

func pose(time: float,amount: float,pivot: Vector3) -> void:
	skeleton.reset_bone_poses()
	for k in branches.size():
		var chain: Array=branches[k]
		for j in chain.size():
			var i: int=chain[j]
			var phase:=time*.75+float(k)*.83+float(j)*.9
			var sign_side:=signf(rest_points[i].x) if k<6 else 1.0
			var turn:=Basis.from_euler(Vector3(sin(phase)*.75,cos(phase*.7)*.40,sin(phase+.8)*1.05*sign_side)*amount)
			var stretch:=Vector3(1.0+amount*.35*(.5+.5*sin(phase)),1.0+amount*.18,1.0)
			var basis:=turn.scaled_local(stretch)
			# A second centre is expressed in the parent bone's frame.
			var local_pivot:=pivot*.27*amount
			var rest:=skeleton.get_bone_rest(i)
			skeleton.set_bone_pose(i,Transform3D(basis,rest.origin+local_pivot-basis*local_pivot))
	update_overlay()

func build_overlay() -> void:
	overlay=Node3D.new();overlay.name="VisibleBones";add_child(overlay)
	var ink:=StandardMaterial3D.new()
	ink.albedo_color=Color("192b30");ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;ink.no_depth_test=true
	for i in skeleton.get_bone_count():
		var marker:=MeshInstance3D.new()
		var orb:=SphereMesh.new();orb.radius=.026;orb.height=.052
		marker.mesh=orb;marker.material_override=ink;overlay.add_child(marker);bone_markers.append(marker)
		var rod:=MeshInstance3D.new()
		var cylinder:=CylinderMesh.new();cylinder.top_radius=.009;cylinder.bottom_radius=.009;cylinder.height=1
		rod.mesh=cylinder;rod.material_override=ink;overlay.add_child(rod);bone_rods.append(rod)
	overlay.hide()

func update_overlay() -> void:
	if not is_instance_valid(overlay) or not overlay.visible:return
	for i in rest_points.size():
		var p:=skeleton.get_bone_global_pose(i).origin
		bone_markers[i].position=p
		var rod:=bone_rods[i]
		if parents[i]<0:rod.hide();continue
		var a:=skeleton.get_bone_global_pose(parents[i]).origin
		var d:=p-a
		rod.position=(a+p)*.5
		rod.basis=Basis(Quaternion(Vector3.UP,d.normalized())).scaled_local(Vector3(1,d.length(),1))

func show_bones(value: bool) -> void:
	overlay.visible=value
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA if value else BaseMaterial3D.TRANSPARENCY_DISABLED
	material.albedo_color.a=.3 if value else 1.0
	update_overlay()

func deformed_vertex(i: int) -> Vector3:
	var result:=Vector3.ZERO
	for j in 4:
		var b:=bones[i*4+j]
		result+=(skeleton.get_bone_global_pose(b)*Transform3D(Basis.IDENTITY,-rest_points[b])*vertices[i])*weights[i*4+j]
	return result
