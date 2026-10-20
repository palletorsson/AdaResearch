extends Node3D
## A light, controller-sized body for visible rehearsals; no player collision/groups.
# Visual layer 16 is reserved for this actor's head shell, not physics collision.
const HEAD_LAYER := 1 << 15
var hands: Array[Node3D]=[]
var arms: Array[Dictionary]=[]
var head: Node3D
var eyes: Marker3D
var glow: StandardMaterial3D
var shell: ShaderMaterial
var elapsed:=0.0

func _ready() -> void:
	glow=StandardMaterial3D.new()
	glow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color=Color("77e6ef");glow.emission_enabled=true;glow.emission=Color("39a9bc")
	shell=ShaderMaterial.new()
	var shader:=Shader.new()
	shader.code="""shader_type spatial;
render_mode unshaded, cull_disabled;
varying vec3 local_point;
void vertex(){ local_point=VERTEX; }
void fragment(){
 float rim=pow(1.0-abs(dot(normalize(NORMAL),normalize(VIEW))),2.0);
 float bands=step(0.86,fract(local_point.y*90.0-TIME*0.25));
 ALBEDO=vec3(0.20,0.72,0.83); EMISSION=vec3(0.10,0.32,0.40)*rim;
 ALPHA=0.12+0.35*rim+0.13*bands;
}"""
	shell.shader=shader
	var torso:=CylinderMesh.new();torso.top_radius=0.23;torso.bottom_radius=0.12;torso.height=0.48;torso.radial_segments=16
	mesh(self,torso,Vector3(0,1.17,0),shell)
	head=Node3D.new();head.position=Vector3(0,1.64,0);add_child(head)
	var face:=sphere(head,Vector3.ZERO,0.14,shell);face.scale=Vector3(0.85,1.08,0.87)
	face.layers=HEAD_LAYER
	var visor:=BoxMesh.new();visor.size=Vector3(0.16,0.025,0.012)
	mesh(head,visor,Vector3(0,0,-0.119),glow).layers=HEAD_LAYER
	eyes=Marker3D.new();eyes.name="Eyes";eyes.position=Vector3(0,0,-0.08);head.add_child(eyes)
	for y in [0.90,1.43]:
		var ring:=TorusMesh.new();ring.inner_radius=0.13;ring.outer_radius=0.145;ring.rings=16;ring.ring_segments=8
		mesh(self,ring,Vector3(0,y,0),glow)
	for side in [-1,1]:
		var upper:=CylinderMesh.new();upper.top_radius=0.021;upper.bottom_radius=0.028;upper.height=1;upper.radial_segments=8
		var lower:=CylinderMesh.new();lower.top_radius=0.018;lower.bottom_radius=0.022;lower.height=1;lower.radial_segments=8
		arms.append({"upper":mesh(self,upper,Vector3.ZERO,shell),"lower":mesh(self,lower,Vector3.ZERO,shell),"elbow":sphere(self,Vector3.ZERO,0.031,glow),"shoulder":sphere(self,Vector3.ZERO,0.039,glow)})
		var hand:=Node3D.new();hand.name="LeftHand" if side<0 else "RightHand";add_child(hand);hands.append(hand)
		var palm:=BoxMesh.new();palm.size=Vector3(0.068,0.023,0.075)
		mesh(hand,palm,Vector3(0,0,0.115),shell)
		# The origin is the extended index fingertip, used as the pointer's contact.
		for finger in 4:
			var x: float=(finger-1)*0.018
			var length: float=[0.067,0.080,0.072,0.056][finger]
			for joint in 3:
				var bone:=BoxMesh.new();bone.size=Vector3(0.012,0.013,length/3.0-0.002)
				mesh(hand,bone,Vector3(x,0,0.080-length+(joint+0.5)*length/3.0),glow)
		var thumb:=BoxMesh.new();thumb.size=Vector3(0.016,0.016,0.048)
		var thumb_view:=mesh(hand,thumb,Vector3(-side*0.047,0,0.095),glow);thumb_view.rotation.y=side*0.6
	pose([Vector3(-0.25,1.02,-0.20),Vector3(0.25,1.02,-0.20)],Vector3(0,1.2,-1))

func mesh(parent: Node3D, shape: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var view:=MeshInstance3D.new();view.mesh=shape;view.material_override=material;view.position=at
	view.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(view);return view

func sphere(parent: Node3D, at: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var shape:=SphereMesh.new();shape.radius=radius;shape.height=radius*2;shape.radial_segments=12;shape.rings=6
	return mesh(parent,shape,at,material)

func segment(view: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var delta:=end-start
	view.transform=Transform3D(Basis(Quaternion(Vector3.UP,delta.normalized()))*Basis.from_scale(Vector3(1,delta.length(),1)),(start+end)*0.5)

func pose(tips: Array, gaze: Vector3) -> void:
	if hands.is_empty(): return
	for i in 2:
		var side: int=-1 if i==0 else 1
		var shoulder:=Vector3(side*0.20,1.42,0)
		var wrist: Vector3=tips[i]+Vector3(0,0,0.15)
		var delta:=wrist-shoulder
		var length:=clampf(delta.length(),0.08,0.78)
		var direction:=delta.normalized()
		var bend:=Vector3(side,0.1,0.7)
		bend=(bend-direction*bend.dot(direction)).normalized()
		var elbow:=shoulder+direction*length*0.5+bend*sqrt(maxf(0.0,0.40*0.40-pow(length*0.5,2)))
		arms[i].shoulder.position=shoulder;arms[i].elbow.position=elbow
		segment(arms[i].upper,shoulder,elbow);segment(arms[i].lower,elbow,wrist)
		hands[i].position=tips[i]
	if head.position.distance_to(gaze)>0.05: head.look_at(to_global(gaze),global_basis.y)

func idle(delta: float) -> void:
	elapsed+=delta
	pose([Vector3(-0.25,1.02+sin(elapsed)*0.016,-0.20),Vector3(0.25,1.02+sin(elapsed+1)*0.016,-0.20)],Vector3(sin(elapsed*0.4)*0.2,1.2,-1))
