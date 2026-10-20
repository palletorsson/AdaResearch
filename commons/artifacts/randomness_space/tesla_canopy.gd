extends Node3D
## One overhead terminal per address. Visual RNG never consumes removal draws.
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
var columns := 15
var rows := 11
const TIP_HEIGHT := 3.55
var charge_marker: MeshInstance3D
var bolt: MeshInstance3D
var strike_points := PackedVector3Array()
var active_index := -1

func _ready() -> void:
	name="TeslaCanopy"
	var copper := Stage.material(Color("ad623f"))
	copper.metallic=0.75
	var steel := Stage.material(Color("91b4c6"));steel.metallic=0.9
	var insulator := Stage.material(Color("d9d4c8"))
	var stem := CylinderMesh.new();stem.top_radius=0.065;stem.bottom_radius=0.065;stem.height=0.55;stem.radial_segments=8
	_batch(stem,copper,[4.0])
	var ring := TorusMesh.new();ring.inner_radius=0.14;ring.outer_radius=0.24;ring.rings=12;ring.ring_segments=6
	_batch(ring,steel,[3.66])
	var rib := TorusMesh.new();rib.inner_radius=0.065;rib.outer_radius=0.11;rib.rings=10;rib.ring_segments=4
	_batch(rib,insulator,[3.82,3.94,4.06,4.18])
	var cap := SphereMesh.new();cap.radius=0.09;cap.height=0.18;cap.radial_segments=8;cap.rings=4
	_batch(cap,steel,[TIP_HEIGHT])
	for z in range(rows):
		Stage.box(self,Vector3(0,4.31,z-(rows-1)/2.0),Vector3(columns,0.10,0.10),Color("384552"))
	for x in [-columns/2.0,columns/2.0]:
		Stage.box(self,Vector3(x,4.31,0),Vector3(0.10,0.12,rows),Color("384552"))
	charge_marker=MeshInstance3D.new();charge_marker.mesh=ring
	var glow := Stage.material(Color("ff6547"));glow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	charge_marker.material_override=glow;charge_marker.scale=Vector3.ONE*1.15;charge_marker.visible=false;add_child(charge_marker)
	bolt=MeshInstance3D.new();add_child(bolt)
	var light := StandardMaterial3D.new();light.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	light.cull_mode=BaseMaterial3D.CULL_DISABLED
	light.albedo_color=Color("afdcff");light.emission_enabled=true;light.emission=Color("94beff");light.emission_energy_multiplier=2
	bolt.material_override=light

func cell_position(index: int) -> Vector3:
	return Vector3(index%columns-(columns-1)/2.0,0,index/columns-(rows-1)/2.0)

func _batch(mesh: Mesh, mat: Material, heights: Array) -> void:
	var mm := MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.mesh=mesh;mm.instance_count=columns*rows*heights.size()
	var slot:=0
	for i in range(columns*rows):
		for y in heights:
			mm.set_instance_transform(slot,Transform3D(Basis.IDENTITY,cell_position(i)+Vector3.UP*float(y)));slot+=1
	var instance:=MultiMeshInstance3D.new();instance.multimesh=mm;instance.material_override=mat;add_child(instance)

func charge(index: int) -> void:
	charge_marker.visible=index>=0
	if index>=0:charge_marker.position=cell_position(index)+Vector3.UP*3.66

func strike(index: int, turn: int) -> void:
	active_index=index
	charge(-1)
	var rng:=RandomNumberGenerator.new();rng.seed=index*7937+turn*101
	var p:=cell_position(index)
	strike_points.clear()
	for k in range(13):
		var offset:=Vector3.ZERO
		if k>0 and k<12:offset=Vector3(rng.randf_range(-0.16,0.16),0,rng.randf_range(-0.16,0.16))
		strike_points.append(p+Vector3.UP*lerpf(TIP_HEIGHT,0.02,k/12.0)+offset)
	var mesh:=ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(1,strike_points.size()):
		var a:=strike_points[k-1];var b:=strike_points[k]
		for axis in [Vector3.RIGHT,Vector3.FORWARD]:
			var w:Vector3=axis*0.024
			for v in [a-w,a+w,b+w,a-w,b+w,b-w]:mesh.surface_add_vertex(v)
	mesh.surface_end();bolt.mesh=mesh;bolt.visible=true

func clear_strike() -> void:
	bolt.visible=false;active_index=-1
