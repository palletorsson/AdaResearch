extends RefCounted
## Construction finishes for this trial. The original transformation laws remain.
const SteelShader = preload("res://commons/void/trials/transformation/rotation_steel.gdshader")
const ConcreteShader = preload("res://commons/void/trials/transformation/scale_concrete.gdshader")

static func apply_growth(growth: Node3D) -> void:
	var concrete := ShaderMaterial.new()
	concrete.shader = ConcreteShader
	growth.mesh_instance.material_override = concrete

static func apply_rotation(turn: Node3D, pivot_height: float) -> void:
	var steel := ShaderMaterial.new()
	steel.shader = SteelShader
	turn.mesh_instance.material_override = steel
	# This stays on the non-rotating root. Moving/copying the editor part carries
	# its column too, while only the original deck and collider change direction.
	var pier := StaticBody3D.new()
	pier.name = "CentralSupport"
	pier.position.y = -pivot_height
	turn.add_child(pier)
	var primer := StandardMaterial3D.new()
	primer.albedo_color = Color("795149")
	primer.metallic = 0.35
	primer.roughness = 0.72
	var bearing := StandardMaterial3D.new()
	bearing.albedo_color = Color("515b62")
	bearing.metallic = 0.8
	bearing.roughness = 0.38
	var top := pivot_height - 0.1 # The underside of the existing 20 cm deck.
	_box(pier, "BasePlate", Vector3(.9,.14,.9), Vector3(0,.07,0), primer)
	var column_height := top - .36
	for z in [-.18,.18]:
		_box(pier, "ColumnFlange", Vector3(.46,column_height,.08), Vector3(0,.14+column_height*.5,z), primer)
	_box(pier, "ColumnWeb", Vector3(.08,column_height,.28), Vector3(0,.14+column_height*.5,0), primer)
	_box(pier, "BearingPlate", Vector3(.72,.12,.72), Vector3(0,top-.16,0), bearing)
	_cylinder(pier, "PivotBearing", .31,.1,Vector3(0,top-.05,0), bearing, true)
	for x in [-.33,.33]:
		for z in [-.33,.33]:
			_cylinder(pier, "AnchorBolt", .035,.045,Vector3(x,.16,z), bearing, false)

static func _box(parent: Node3D, title: String, size: Vector3, at: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_visual(parent,title,mesh,at,material)
	var shape := BoxShape3D.new()
	shape.size = size
	_collision(parent,shape,at)

static func _cylinder(parent: Node3D, title: String, radius: float, height: float, at: Vector3, material: Material, solid: bool) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=height
	mesh.radial_segments=24
	_visual(parent,title,mesh,at,material)
	if solid:
		var shape := CylinderShape3D.new()
		shape.radius=radius
		shape.height=height
		_collision(parent,shape,at)

static func _visual(parent: Node3D, title: String, mesh: Mesh, at: Vector3, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.name=title
	node.mesh=mesh
	node.position=at
	node.material_override=material
	parent.add_child(node)

static func _collision(parent: Node3D, shape: Shape3D, at: Vector3) -> void:
	var node := CollisionShape3D.new()
	node.shape=shape
	node.position=at
	parent.add_child(node)
