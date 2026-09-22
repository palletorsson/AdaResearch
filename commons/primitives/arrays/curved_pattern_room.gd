extends Node3D
## An inhabitable receiver: 300 degrees of wall, a four-metre entrance,
## a continuous metre-addressed curved sheet and an independently held floor.
const RADIUS:=4.0
const HEIGHT:=3.2
const SEGMENTS:=80
const SWEEP:=5.235987755982989
var study:Node3D
var source:Node3D
var wall:MeshInstance3D
var floor_mesh:MeshInstance3D

func _ready() -> void:
	# Begin with a readable architectural repeat (60 cm per card).
	source.package_extra["tile_scale"]=2.0;source.refresh()
	wall=MeshInstance3D.new();wall.name="RoomWall";wall.mesh=wall_mesh();add_child(wall)
	wall.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat:=StandardMaterial3D.new();mat.cull_mode=BaseMaterial3D.CULL_DISABLED;wall.material_override=mat
	# A separate plaster outer skin frames the printed interior. Shell shadows
	# are disabled: the museum sun's coarse shadow edge obscures this large print.
	var backing:=MeshInstance3D.new();backing.name="OuterWall";backing.mesh=wall.mesh
	backing.scale=Vector3(1.04,1,1.04);backing.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var backing_mat:=StandardMaterial3D.new();backing_mat.albedo_color=Color("ddd5c6")
	backing_mat.cull_mode=BaseMaterial3D.CULL_DISABLED;backing_mat.roughness=1.0
	backing.material_override=backing_mat;add_child(backing)
	for i in SEGMENTS:
		var angle:=PI/6+SWEEP*(i+0.5)/SEGMENTS
		var body:=StaticBody3D.new();body.name="WallSupport_%02d"%i;body.collision_layer=1;body.collision_mask=0
		body.position=Vector3(sin(angle)*(RADIUS+0.08),HEIGHT/2,cos(angle)*(RADIUS+0.08));body.rotation.y=angle
		var collider:=CollisionShape3D.new();var shape:=BoxShape3D.new()
		shape.size=Vector3(SWEEP*RADIUS/SEGMENTS+0.012,HEIGHT,0.18);collider.shape=shape;body.add_child(collider);add_child(body)
	# UVs on the circle are a planar projection, unlike arc length on the wall.
	floor_mesh=MeshInstance3D.new();floor_mesh.name="RoomFloor";floor_mesh.mesh=disc_mesh(0.0,RADIUS,0.022)
	floor_mesh.material_override=mat.duplicate();add_child(floor_mesh)
	var roof:=MeshInstance3D.new();roof.name="OculusRoof";roof.mesh=disc_mesh(1.65,RADIUS+0.16,HEIGHT+0.06)
	# Keep the large printed field free of the low-resolution sun-shadow edge.
	# The oculus frames the sky; local fill, not roof-shadow detail, lights the study.
	roof.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var plaster:=StandardMaterial3D.new();plaster.albedo_color=Color("ddd5c6");plaster.cull_mode=BaseMaterial3D.CULL_DISABLED;plaster.roughness=1.0
	roof.material_override=plaster;add_child(roof)
	# A gentle local fill makes this a usable material comparison under the roof.
	var light:=OmniLight3D.new();light.position=Vector3(0,2.7,0);light.omni_range=7;light.light_energy=0.7;light.shadow_enabled=false;add_child(light)
	register("ROOM WALL",wall,Vector2(RADIUS*SWEEP,HEIGHT),Vector3(0,2.9,-3.85))
	register("ROOM FLOOR",floor_mesh,Vector2(RADIUS*2,RADIUS*2),Vector3(0,2.65,-3.85))
	study.apply_source(["ROOM WALL","ROOM FLOOR"],source)
	# Initial dressing is setup, not a visitor transaction.
	study.link_history.pop_back()
	var sign:=Label3D.new();sign.text="ENTER THE PATTERN";sign.position=Vector3(0,2.5,3.55)
	sign.font_size=48;sign.pixel_size=0.003;sign.outline_size=0;add_child(sign)

func register(id:String,mesh:MeshInstance3D,metres:Vector2,tag_pos:Vector3) -> void:
	study.register_receiver(id,mesh,metres)
	var tag:=Label3D.new();tag.font_size=32;tag.pixel_size=0.003;tag.outline_size=0
	tag.position=tag_pos;add_child(tag)
	study.receivers[id].tag=tag
	# CPU loom fallback is bounded; the studio uses the existing GPU shader.
	study.receivers[id].sampling=30.0

func wall_mesh() -> ArrayMesh:
	var vertices:=PackedVector3Array();var normals:=PackedVector3Array();var uv:=PackedVector2Array();var indices:=PackedInt32Array()
	for i in range(SEGMENTS+1):
		var u:=float(i)/SEGMENTS;var angle:=PI/6+SWEEP*u
		for y in [0.0,HEIGHT]:
			vertices.append(Vector3(sin(angle)*RADIUS,y,cos(angle)*RADIUS))
			normals.append(Vector3(-sin(angle),0,-cos(angle)));uv.append(Vector2(u,1-y/HEIGHT))
	for i in SEGMENTS:
		var k:=i*2;indices.append_array(PackedInt32Array([k,k+1,k+2,k+1,k+3,k+2]))
	return assemble(vertices,normals,uv,indices)

func disc_mesh(inner:float,outer:float,y:float) -> ArrayMesh:
	var vertices:=PackedVector3Array();var normals:=PackedVector3Array();var uv:=PackedVector2Array();var indices:=PackedInt32Array()
	for i in range(SEGMENTS+1):
		var angle:=TAU*i/SEGMENTS
		for r in [inner,outer]:
			var p:=Vector3(sin(angle)*r,y,cos(angle)*r)
			vertices.append(p);normals.append(Vector3.UP);uv.append(Vector2(p.x/(RADIUS*2)+0.5,p.z/(RADIUS*2)+0.5))
	for i in SEGMENTS:
		var k:=i*2;indices.append_array(PackedInt32Array([k,k+2,k+1,k+1,k+2,k+3]))
	return assemble(vertices,normals,uv,indices)

func assemble(vertices:PackedVector3Array,normals:PackedVector3Array,uv:PackedVector2Array,indices:PackedInt32Array) -> ArrayMesh:
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);return mesh
