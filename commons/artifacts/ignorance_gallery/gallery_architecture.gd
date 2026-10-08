extends RefCounted
## Local display surfaces. The museum still owns floors, walls, exits and collision.
const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")

static func bay(parent: Node3D, depth: float, centre_z: float = 0.0, side_walls: bool = true) -> void:
	# A pale stone ground and roof strips give the comparisons a common field.
	Kit.block(parent,Vector3(15.6,0.008,depth),Vector3(0,0.004,centre_z),Kit.WHITE,false)
	for side in [-1,1]:
		Kit.block(parent,Vector3(5.8,0.12,depth),Vector3(side*4.9,3.94,centre_z),Kit.WHITE,false)
		if side_walls:
			Kit.block(parent,Vector3(0.06,3.8,depth),Vector3(side*7.8,1.9,centre_z),Kit.WHITE,false)
	# The luminous upper strip is a museum light, kept away from eye height.
	var strip := Kit.block(parent,Vector3(4.03,0.03,depth),Vector3(0,4.03,centre_z),Kit.WHITE,false)
	var material := Kit.material(Kit.WHITE)
	material.emission_enabled=true;material.emission=Color(1.0,0.95,0.84);material.emission_energy_multiplier=0.7
	strip.material_override=material
	for z in [-depth*0.30,depth*0.30]:
		Kit.lamp(parent,Vector3(0,3.45,centre_z+z),0.8,9)

static func pentagon(parent: Node3D, at: Vector3) -> void:
	Kit.block(parent,Vector3(1.85,1.85,0.055),at,Kit.WHITE,false)
	var mesh := ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in 5:
		for index in [i,i+1]:
			var angle := TAU*float(index)/5.0
			mesh.surface_add_vertex(Vector3(sin(angle),cos(angle),0)*0.63+Vector3(0,0,-0.034))
	mesh.surface_end()
	var drawing := MeshInstance3D.new();drawing.mesh=mesh;drawing.position=at
	var mat := Kit.material(Kit.BLACK);mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	drawing.material_override=mat;parent.add_child(drawing)
	Kit.label(parent,"FIVE SIDES / ONE PROFILE",at+Vector3(0,-1.12,-0.04),0.0015,PI)
