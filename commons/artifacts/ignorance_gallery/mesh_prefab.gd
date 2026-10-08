extends Node3D
## A reusable scene around an actual Godot PrimitiveMesh resource.
const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
@export var kind: String = "PrismMesh"
var specimen: MeshInstance3D

func _ready() -> void:
	var mesh: PrimitiveMesh
	match kind:
		"PrismMesh":
			var m := PrismMesh.new();m.size=Vector3(1.1,1.1,1.1);mesh=m
		"TorusMesh":
			var m := TorusMesh.new();m.inner_radius=0.27;m.outer_radius=0.62;m.rings=32;m.ring_segments=16;mesh=m
		"PlaneMesh":
			var m := PlaneMesh.new();m.size=Vector2(1.3,1.1);m.subdivide_width=3;m.subdivide_depth=3;mesh=m
		"QuadMesh":
			var m := QuadMesh.new();m.size=Vector2(1.25,1.0);mesh=m
		"PointMesh": mesh=PointMesh.new()
		"TextMesh":
			var m := TextMesh.new();m.text="Aa";m.font_size=80;m.pixel_size=0.012;m.depth=0.15;mesh=m
		"RibbonTrailMesh":
			var m := RibbonTrailMesh.new();m.size=0.65;m.sections=5;m.section_length=0.22;m.shape=RibbonTrailMesh.SHAPE_CROSS;mesh=m
		"TubeTrailMesh":
			var m := TubeTrailMesh.new();m.radius=0.27;m.radial_steps=12;m.sections=5;m.section_length=0.22;mesh=m
	assert(mesh!=null,"Unknown PrimitiveMesh prefab "+kind)
	specimen=Kit.exhibit(self,mesh,Vector3.ZERO,Kit.BLACK,"Primitive")
	var mat: StandardMaterial3D=specimen.material_override
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	if kind=="PointMesh":
		mat.use_point_size=true;mat.point_size=22;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.custom_aabb=AABB(Vector3(-0.2,-0.2,-0.2),Vector3.ONE*0.4)
	elif kind=="TextMesh":
		specimen.rotation.y=PI
	elif kind=="PlaneMesh":
		specimen.rotation_degrees.x=28
	elif kind=="TorusMesh":
		specimen.rotation_degrees.x=68
