extends Node3D
## Original wall studies after Gillick: interval, layered crossing, open composition.
signal state_changed
const PALETTE: Array[Color] = [Color("e74889"),Color("efa72d"),Color("129681"),Color("7652a8"),Color("ee6932"),Color("344f85")]
var intervals: Array[Node3D] = []
var uprights: Array[Node3D] = []
var rails: Array[Node3D] = []
var materials: Array[StandardMaterial3D] = []
var spacing := 0.16
var projection := 0.18
var omitted := false
var colour_rule := 0
var roots: Array[Node3D] = []

func _ready() -> void:
	for x in [-5.8,0.0,5.8]:
		var node := Node3D.new()
		node.position = Vector3(x,2.35,-3.85)
		add_child(node)
		roots.append(node)
	for i in 24:
		intervals.append(_bar(roots[0],Vector2(0,-1.30),Vector2(0,1.30),0.072,0.18,i))
	for i in 6:
		var a := (i-2.5)*0.46
		var upright := _bar(roots[1],Vector2(a,-1.30),Vector2(a,1.30),0.14,0.18,i)
		uprights.append(upright)
		var crossing := _bar(roots[1],Vector2(-1.30,a),Vector2(1.30,a),0.14,0.14,i+2)
		crossing.position.z = 0.02
	# Independent straight segments, intentionally an open composition rather than a network simulator.
	var ends := [
		[Vector2(-1.3,1.2),Vector2(-1.3,-1.15)],
		[Vector2(-1.3,-1.15),Vector2(-0.2,-1.15)],
		[Vector2(-0.2,-1.15),Vector2(-0.2,0.05)],
		[Vector2(-0.2,0.05),Vector2(0.85,0.05)],
		[Vector2(0.85,0.05),Vector2(0.85,1.2)],
		[Vector2(-1.3,1.2),Vector2(0.85,1.2)],
		[Vector2(-0.65,-0.50),Vector2(-0.65,0.60)],
		[Vector2(-0.65,0.60),Vector2(0.35,0.60)],
		[Vector2(0.35,0.60),Vector2(0.35,1.6)],
		[Vector2(1.4,-1.4),Vector2(1.4,0.6)],
		[Vector2(0.35,-0.55),Vector2(1.4,-0.55)],
		[Vector2(-1.7,-0.1),Vector2(-1.3,-0.1)]
	]
	for i in ends.size():
		var segment := _bar(roots[2],ends[i][0],ends[i][1],0.105,0.14,i,true)
		segment.position.z = 0.12
		rails.append(segment)
	set_spacing(spacing)
	set_projection(projection)
	set_colour_rule(0)
	set_meta("em_visibility_bounds",AABB(Vector3(-8.6,0.8,-4.1),Vector3(17.2,3.4,1.1)))

func _bar(parent: Node3D,a: Vector2,b: Vector2,width: float,depth: float,index: int,groove := false) -> Node3D:
	var node := Node3D.new()
	var delta := b-a
	node.position = Vector3((a.x+b.x)/2,(a.y+b.y)/2,0)
	node.rotation.z = -atan2(delta.x,delta.y)
	node.set_meta("palette_index",index)
	parent.add_child(node)
	var mat := StandardMaterial3D.new()
	mat.metallic = 0.28
	mat.roughness = 0.38
	mat.set_meta("palette_index",index)
	materials.append(mat)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width,delta.length(),depth)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = mat
	node.add_child(visual)
	var body := StaticBody3D.new()
	body.name = "Solid"
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	collision.shape = shape
	body.add_child(collision)
	node.add_child(body)
	if groove:
		# A visible face groove recalls an extrusion; this is not its engineering profile.
		var dark := StandardMaterial3D.new()
		dark.albedo_color = Color("252930")
		dark.roughness = 0.5
		var slot := MeshInstance3D.new()
		var slot_mesh := BoxMesh.new()
		slot_mesh.size = Vector3(width*0.2,maxf(delta.length()-0.05,0.01),0.003)
		slot.mesh = slot_mesh
		slot.material_override = dark
		slot.position.z = depth/2+0.002
		node.add_child(slot)
	return node

func set_spacing(value: float) -> void:
	spacing = clampf(value,0.11,0.21)
	for i in intervals.size(): intervals[i].position.x = (i-11.5)*spacing
	state_changed.emit()

func set_projection(value: float) -> void:
	projection = clampf(value,0.18,0.52)
	for bar in uprights: bar.position.z = projection
	state_changed.emit()

func set_omitted(value: bool) -> void:
	omitted = value
	rails[5].visible = not omitted
	(rails[5].get_node("Solid") as StaticBody3D).collision_layer = 0 if omitted else 1
	state_changed.emit()

func set_colour_rule(value: int) -> void:
	colour_rule = clampi(value,0,2)
	for mat in materials:
		var index: int = mat.get_meta("palette_index")
		var choice := index%PALETTE.size()
		if colour_rule == 1: choice = floori(index/4.0)%PALETTE.size()
		if colour_rule == 2: choice = 0
		mat.albedo_color = PALETTE[choice]
	state_changed.emit()

func reset() -> void:
	set_spacing(0.16)
	set_projection(0.18)
	set_omitted(false)
	set_colour_rule(0)
