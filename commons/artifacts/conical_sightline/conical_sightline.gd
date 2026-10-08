extends Node3D
## Original study after the spatial question of Matta-Clark's Conical Intersect.
## Three separate walls receive one shared conical cutter. The offcuts retain
## the complementary intersection. This is not a model of the 1975 buildings.

var cut_x := 0.0
var cut_enabled := true
var cutters: Array[CSGCylinder3D] = []
var witness: Node3D
var walls: Array[CSGCombiner3D] = []

func _ready() -> void:
	var plaster := _material(Color("#ddd9d0"))
	var cut_surface := _material(Color("#ba7661"))
	var ink := _material(Color("#22262c"))
	_box(self, "Floor", Vector3(8.6,0.2,11), Vector3(0,-0.1,0), _material(Color("#a6a09a")), true)
	# Side wall gives the diagonal view a room to come from. The right is open.
	_box(self, "Returning wall", Vector3(0.22,4.8,10), Vector3(-4.2,2.4,0), plaster, true)
	witness = Node3D.new()
	witness.name = "The retained offcuts"
	add_child(witness)
	witness.position.x = 10.2
	_box(witness, "Offcut deck", Vector3(7.8,0.3,8.7), Vector3(0,0.15,0), ink, true)
	for z in [3.4,0.0,-3.4]:
		var wall := _wall(float(z), plaster, cut_surface, false)
		add_child(wall)
		walls.append(wall)
		var kept := _wall(float(z), plaster, cut_surface, true)
		kept.position.y = 0.3
		witness.add_child(kept)
		var radius_here := 2.4 * (float(z) + 10.8) / 18.0
		var support_height := 2.8 - radius_here
		_box(witness, "Offcut support", Vector3(0.045,support_height,0.045), Vector3(0,0.3+support_height/2.0,float(z)), ink)
		# Horizontal joints make each remaining plane readable at a distance.
		for y in [0.16,4.64]:
			_box(self, "Wall edge", Vector3(8.4,0.025,0.015), Vector3(0,y,float(z)+0.141), ink)
	_label("ONE CUT / THREE WALLS", Vector3(0,5.08,3.4), 36)
	_label("A − B", Vector3(0,0.16,5.2), 28)
	_label("A ∩ B / WHAT WAS REMOVED", Vector3(10.2,0.55,4.7), 25)

func _wall(z: float, plaster: Material, cut_surface: Material, keep: bool) -> CSGCombiner3D:
	var result := CSGCombiner3D.new()
	result.name = ("Offcut_" if keep else "Wall_") + str(z)
	result.use_collision = true
	var stock := CSGBox3D.new()
	stock.size = Vector3(8.4,4.8,0.28)
	stock.position = Vector3(0,2.4,z)
	stock.material = plaster
	result.add_child(stock)
	# A separate door retains an ordinary floor-level route beside the sightline.
	var door := CSGBox3D.new()
	door.size = Vector3(1.4,2.6,0.65)
	door.position = Vector3(-2.9,1.25,z)
	door.operation = CSGShape3D.OPERATION_SUBTRACTION
	door.material = cut_surface
	result.add_child(door)
	var cutter := CSGCylinder3D.new()
	cutter.name = "Shared cone"
	cutter.cone = true
	cutter.radius = 2.4
	cutter.height = 18.0
	cutter.sides = 96
	# All six cutters occupy the SAME local line; the walls differ in z.
	# Cone tip points toward -Z. Wall intersections shrink into the distance.
	cutter.rotation.x = -PI/2.0
	cutter.position = Vector3(cut_x,2.8,-1.8)
	cutter.operation = CSGShape3D.OPERATION_INTERSECTION if keep else CSGShape3D.OPERATION_SUBTRACTION
	cutter.material = cut_surface
	result.add_child(cutter)
	cutters.append(cutter)
	return result

func set_cut_x(value: float) -> void:
	cut_x = clampf(value,-0.65,0.85)
	for cutter in cutters:
		cutter.position.x = cut_x

func set_cut_enabled(value: bool) -> void:
	cut_enabled = value
	for cutter in cutters:
		cutter.visible = value
	witness.visible = value

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.88
	return mat

func _box(parent: Node3D, label: String, size: Vector3, at: Vector3, material: Material, collision: bool = false) -> void:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	node.position = at
	parent.add_child(node)
	if collision: node.create_trimesh_collision()

func _label(text: String, at: Vector3, size: int) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = size
	label.pixel_size = 0.012
	label.modulate = Color("#272733")
	label.outline_size = 0
	add_child(label)
