extends Node3D
## Two batched mesh instances, rebuilt only when a parameter changes.
var rods: MultiMeshInstance3D
var balls: MultiMeshInstance3D

func show_geometry(data: Dictionary, colour: Color) -> void:
	if rods==null:
		rods=MultiMeshInstance3D.new();rods.name="Rods";add_child(rods)
		balls=MultiMeshInstance3D.new();balls.name="Balls";add_child(balls)
	var cylinder:=CylinderMesh.new()
	cylinder.top_radius=0.5;cylinder.bottom_radius=0.5;cylinder.height=1.0
	cylinder.radial_segments=12;cylinder.rings=1
	var sphere:=SphereMesh.new();sphere.radius=0.5;sphere.height=1.0
	sphere.radial_segments=16;sphere.rings=8
	rods.multimesh=batch(cylinder,data.rods.size(),colour)
	balls.multimesh=batch(sphere,data.balls.size(),colour.lightened(0.14))
	for i in data.rods.size():
		var rod: Dictionary=data.rods[i]
		var delta: Vector3=rod.b-rod.a
		var basis:=Basis(Quaternion(Vector3.UP,delta.normalized()))*Basis.from_scale(Vector3(2*rod.r,delta.length(),2*rod.r))
		rods.multimesh.set_instance_transform(i,Transform3D(basis,(rod.a+rod.b)*0.5))
	for i in data.balls.size():
		var ball: Dictionary=data.balls[i]
		balls.multimesh.set_instance_transform(i,Transform3D(Basis().scaled(Vector3.ONE*2*ball.r),ball.p))

func batch(mesh: Mesh, count: int, colour: Color) -> MultiMesh:
	var material:=StandardMaterial3D.new();material.albedo_color=colour
	material.metallic=0.18;material.roughness=0.36
	mesh.surface_set_material(0,material)
	var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.mesh=mesh;mm.instance_count=count
	return mm
