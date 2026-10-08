extends "res://commons/artifacts/reference_studies/build.gd"
## Original tensile encounter after Nengudi. No player/camera belongs here.
const Score = preload("res://commons/artifacts/spine_studies/tension_score.gd")
const Handle = preload("res://commons/artifacts/spine_studies/tension_handle.gd")
var score := Score.new()
var handle: RigidBody3D
var cloth: MeshInstance3D
var load_ball: MeshInstance3D
var caption: Label3D
var accumulator := 0.0
var preset_hold := false
var return_message := ""
var uv := PackedVector2Array()
var indices := PackedInt32Array()
var surface := ArrayMesh.new()
func _ready() -> void:
	var chalk := material(Color("e3e0d8"))
	var dark := material(Color("343139"),0.7)
	for i in score.pins:
		var p: Vector3 = score.rest[i]
		box(Vector3(p.x,(p.y-0.03)*0.5,p.z),Vector3(0.06,p.y-0.03,0.06),chalk,true)
		ball(p,Vector3.ONE*0.075,dark)
		box(Vector3(p.x,0.02,p.z),Vector3(0.32,0.04,0.32),chalk,true)
	cloth = MeshInstance3D.new(); cloth.mesh=surface; add_child(cloth)
	var fabric := ShaderMaterial.new(); fabric.shader=preload("res://commons/artifacts/spine_studies/tension_fabric.gdshader")
	cloth.material_override=fabric
	for z in Score.NZ:
		for x in Score.NX:
			uv.append(Vector2(float(x)/(Score.NX-1),float(z)/(Score.NZ-1)))
			if x<Score.NX-1 and z<Score.NZ-1:
				var a:=z*Score.NX+x
				indices.append_array(PackedInt32Array([a,a+1,a+Score.NX,a+1,a+Score.NX+1,a+Score.NX]))
	handle=Handle.new(); handle.name="PullHandle"; add_child(handle)
	load_ball=ball(Vector3.ZERO,Vector3.ONE*0.12,dark)
	caption=Label3D.new(); caption.position=Vector3(0,0.40,2.65)
	caption.font_size=32; caption.pixel_size=0.002; caption.modulate=Color("363039"); caption.outline_size=0; add_child(caption)
	plaque("A LITTLE GIVE",Vector3(0,3.6,-2.3),Color("eee9e1"))
	# Begin settled, so the first hand can reach the fabric.
	for i in 600: score.step()
	update_surface()

func _physics_process(delta: float) -> void:
	score.grip_held=handle.held_by_visitor() or preset_hold
	if handle.held_by_visitor():
		preset_hold=false
		score.grip_target=score.bounded_target(to_local(handle.global_position))
	elif preset_hold: score.grip_target=Vector3(0,2.1,1.75)
	accumulator=minf(accumulator+delta,Score.STEP*8)
	while accumulator>=Score.STEP:
		score.step(); accumulator-=Score.STEP
	update_surface()

func update_surface() -> void:
	var normals:=PackedVector3Array(); normals.resize(score.points.size())
	for i in range(0,indices.size(),3):
		var a:=indices[i]; var b:=indices[i+1]; var c:=indices[i+2]
		var normal:Vector3=(score.points[c]-score.points[a]).cross(score.points[b]-score.points[a])
		normals[a]+=normal; normals[b]+=normal; normals[c]+=normal
	for i in normals.size(): normals[i]=normals[i].normalized()
	var arrays:=[]; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=score.points; arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_TEX_UV]=uv; arrays[Mesh.ARRAY_INDEX]=indices
	surface.clear_surfaces(); surface.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	if not handle.held_by_visitor(): handle.global_position=to_global(score.points[score.grip_index])
	load_ball.position=score.load_position()-Vector3(0,0.1,0)
	load_ball.visible=score.load_kg>0
	caption.text="PINK / PULL AND RELEASE\nAdded load %.0f kg · centre %.2f m" % [score.load_kg,score.load_position().y]

func control(index: int) -> void:
	return_message=""
	if index in [0,1,4] and handle.held_by_visitor():
		return_message="Release the pink handle first."; return
	match index:
		0: preset_hold=true
		1: preset_hold=false
		2: score.load_kg=Score.LOAD_KG[(Score.LOAD_KG.find(score.load_kg)+1)%Score.LOAD_KG.size()]
		3: score.compliance=0.0045 if score.compliance<0.004 else 0.0015
		4:
			preset_hold=false; score.reset(); score.compliance=0.0015; accumulator=0.0
			for i in 600: score.step()
	update_surface()
