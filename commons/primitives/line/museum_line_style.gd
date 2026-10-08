extends RefCounted
## The pink segment and white point used in Point Lines, continued at hand scale.
const PINK := Color("ec8fba")
const WHITE := Color("f5f1e9")

static func pink() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color=PINK;mat.roughness=0.32
	mat.emission_enabled=true;mat.emission=Color("bb517f");mat.emission_energy_multiplier=0.35
	return mat

static func white() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color=WHITE;mat.roughness=0.38
	return mat

static func face() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color=Color(PINK,0.44);mat.roughness=0.5
	mat.emission_enabled=true;mat.emission=PINK;mat.emission_energy_multiplier=0.3
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	return mat

static func point(handle: Node3D, radius: float) -> void:
	if is_equal_approx(float(handle.get_meta("museum_point_radius",-1.0)),radius):return
	handle.set_meta("museum_point_radius",radius)
	handle.scale=Vector3.ONE
	var mesh: MeshInstance3D=handle.get_node_or_null("MeshInstance3D")
	if mesh!=null:
		var ball := SphereMesh.new();ball.radius=radius;ball.height=radius*2
		ball.radial_segments=24;ball.rings=12
		mesh.mesh=ball;mesh.material_override=white()
		for label in mesh.find_children("*","Label3D",true,false):label.visible=false
	var col: CollisionShape3D=handle.get_node_or_null("CollisionShape3D")
	if col!=null:
		var shape := SphereShape3D.new();shape.radius=radius;col.shape=shape

static func plinth(parent: Node3D, at: Vector3, size_m: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new();body.name="MuseumPlinth";body.position=at
	body.collision_layer=1;body.collision_mask=0;parent.add_child(body)
	var mesh := MeshInstance3D.new();var box := BoxMesh.new();box.size=size_m
	mesh.mesh=box;var mat:=white();mat.albedo_color=Color("eee8dd");mat.roughness=0.82
	mesh.material_override=mat;body.add_child(mesh)
	var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size_m
	col.shape=shape;body.add_child(col)
	return body
