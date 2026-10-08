extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Twenty indexed rotors: common period, phase gradient, then frequency mismatch.
const COUNT := 20
var rods: Array[Node3D] = []
var eyes: Array[Node3D] = []
var _walker_camera: Camera3D
var elapsed := 0.0
var period := 6.0
var mode := "TOGETHER"
var one_offset := 0.0
var show_rule := false
var rule: Label3D
func _ready() -> void:
	var dark=material("182d38");box(Vector3(0,0.09,-0.2),Vector3(6.6,0.18,5.2),dark,true)
	# Shared meshes and materials; only each eye's orientation changes.
	var white=material("f4f0e6");white.roughness=0.24
	var iris=material("813e65");iris.roughness=0.35
	var pupil=material("080a10");pupil.roughness=0.12
	var eyeball=_eye_sphere(0.16)
	var iris_mesh=_eye_sphere(0.092)
	var pupil_mesh=_eye_sphere(0.044)
	for i in COUNT:
		var x=(i%5-2)*1.25;var z=-(i/5)*1.2+1.65
		box(Vector3(x,0.24,z),Vector3(0.40,0.3,0.40),dark,true)
		box(Vector3(x,0.96,z),Vector3(0.055,1.2,0.055),material("536373"))
		var pivot=Node3D.new();pivot.position=Vector3(x,1.57,z);add_child(pivot);rods.append(pivot)
		var ink=material(["ff669b","ffd75e","54e5da","9e99ff"][i/5],true)
		box(Vector3.ZERO,Vector3(0.045,1.05,0.045),ink,false,pivot)
		var eye=Node3D.new();eye.name="Eye";eye.position=Vector3(0,0.58,0);pivot.add_child(eye);eyes.append(eye)
		_eye_part(eye,"White",eyeball,white,Vector3.ZERO,Vector3.ONE)
		_eye_part(eye,"Iris",iris_mesh,iris,Vector3(0,0,-0.132),Vector3(1,1,0.34))
		_eye_part(eye,"Pupil",pupil_mesh,pupil,Vector3(0,0,-0.16),Vector3(1,1,0.18))
	console(["ONE +","WAVE","DRIFT","RESET","RULE"],3.3,"TWENTY CLOCKS")
	rule=label("",Vector3(0,2.75,-2.5),0.0018);rule.hide()
	var light=OmniLight3D.new();light.position=Vector3(0,3,0);light.omni_range=8;light.light_energy=1.4;add_child(light)
	_update_rods()
func angle_at(i: int, time: float) -> float:
	var frequency=1.0/period
	if mode=="DRIFT" and i>=10:frequency*=1.04
	var phase=(i%5)*TAU/5.0 if mode=="WAVE" else 0.0
	if i==9:phase+=one_offset
	return TAU*frequency*time+phase
func _process(delta: float) -> void:
	elapsed+=delta;_update_rods();_update_eyes()

func _eye_sphere(radius: float) -> SphereMesh:
	var mesh=SphereMesh.new();mesh.radius=radius;mesh.height=radius*2
	mesh.radial_segments=20;mesh.rings=12
	return mesh

func _eye_part(eye: Node3D, part_name: String, mesh: Mesh, mat: Material, at: Vector3, size: Vector3) -> void:
	var part=MeshInstance3D.new();part.name=part_name;part.mesh=mesh
	part.material_override=mat;part.position=at;part.scale=size;eye.add_child(part)

func _gaze_camera() -> Camera3D:
	var active=get_viewport().get_camera_3d()
	if active is XRCamera3D:return active
	# Prefer the museum visitor over a detached survey/editing camera.
	var walker=get_tree().get_first_node_in_group("em_walker")
	if walker!=null:
		if not is_instance_valid(_walker_camera) or not walker.is_ancestor_of(_walker_camera):
			var cameras=walker.find_children("*","Camera3D",true,false)
			_walker_camera=cameras[0] if not cameras.is_empty() else null
		if is_instance_valid(_walker_camera):return _walker_camera
	return active

func _update_eyes() -> void:
	var head=_gaze_camera()
	if not is_instance_valid(head):return
	for eye in eyes:
		var direction=head.global_position-eye.global_position
		if direction.length_squared()<0.000001:continue
		# Avoid a degenerate look-at when the player is directly above a tip.
		var up=Vector3.FORWARD if absf(direction.normalized().dot(Vector3.UP))>0.98 else Vector3.UP
		# Change local orientation only, so repeated world/local conversions
		# cannot accumulate positional drift at the rod tip.
		eye.basis=eye.get_parent().global_basis.orthonormalized().inverse()*Basis.looking_at(direction,up)

func _update_rods() -> void:
	for i in rods.size():rods[i].rotation.z=angle_at(i,elapsed)
	if readout:
		readout.text="%s / base period 6 s\n%s" % [mode,"back rows 4% faster" if mode=="DRIFT" else "rod 10 offset: %.0f degrees" % rad_to_deg(one_offset)]
	if rule:rule.text="angle = TAU * frequency * time + phase\nSame period + different phases can make a wave."
func act(id: String) -> void:
	match id:
		"ONE +":one_offset=fposmod(one_offset+PI/4,TAU)
		"WAVE":mode="WAVE";one_offset=0
		"DRIFT":mode="DRIFT";one_offset=0
		"RESET":mode="TOGETHER";one_offset=0
		"RULE":show_rule=not show_rule;rule.visible=show_rule
	_update_rods()
