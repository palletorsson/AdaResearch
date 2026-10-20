extends Node3D
## Reuses museum form builders; all new game colliders are explicit.
const Course := preload("course.gd")
const Target := preload("target.gd")
const BoxBody := preload("res://commons/museum_runner/forms/box_body.gd")
const LineSkin := preload("res://commons/museum_runner/forms/line_skin.gd")
const Totem := preload("res://commons/artifacts/resolution_colonnade/resolution_totem.gd")
const FaceBody := preload("res://commons/museum_runner/forms/face_body.gd")
const FLOOR_COLOURS := [Color("23313d"), Color("3b303c"), Color("23413f"), Color("2b3154")]
const ACCENTS := [Color("efb2cf"), Color("e7cf98"), Color("8cdbcc"), Color("c0b7ef")]
var index := 0
var chapter_override := -1
var last_section := false
var seed_value := 17
var layout: Array[Dictionary] = []
var pickups: Array[Area3D] = []
var hazards: Array[StaticBody3D] = []

func _ready() -> void:
	var phase := chapter_override if chapter_override >= 0 else Course.chapter(index)
	layout = Course.rows(seed_value, index)
	var accent: Color = ACCENTS[phase]
	# Repetition is one MultiMesh, not an unbounded set of individual tiles.
	var tiles := MultiMeshInstance3D.new()
	var unit := BoxBody.new(Vector3(2.04, 0.14, 2.94))
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = unit.mesh
	unit.free()
	batch.instance_count = 36
	for row in range(12):
		for lane in range(3):
			batch.set_instance_transform(row*3+lane, Transform3D(Basis.IDENTITY, Vector3((lane-1)*Course.LANE_WIDTH, -0.07, -row*3.0-1.5)))
	tiles.multimesh = batch
	tiles.material_override = finish(FLOOR_COLOURS[phase], 0.7)
	add_child(tiles)
	for x in [-3.25, 3.25]:
		line(Vector3(x,0.035,0),Vector3(x,0.035,-Course.LENGTH),accent,0.025)
	for x in [-1.05,1.05]:
		line(Vector3(x,0.008,0),Vector3(x,0.008,-Course.LENGTH),Color("7d8a92"),0.009)
	for row in layout:
		for hazard in row.hazards:
			add_hazard(hazard.kind, hazard.lane*Course.LANE_WIDTH, row.z)
		var pickup := Area3D.new()
		pickup.collision_layer = 4
		pickup.collision_mask = 0
		pickup.monitoring = false
		pickup.position = Vector3(row.clear*Course.LANE_WIDTH,0.72,row.z-2.8)
		pickup.set_meta("collectible", true)
		var mesh := BoxBody.new(Vector3.ONE*0.3)
		mesh.material_override = finish(Color("fbdc81"),0.2,0.6)
		mesh.rotation_degrees = Vector3(25,45,15)
		pickup.add_child(mesh)
		var boundary := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.4
		boundary.shape = shape
		pickup.add_child(boundary)
		add_child(pickup)
		pickups.append(pickup)
	# The actual profile generator from the museum, with no scenery collisions.
	for side in [-1,1]:
		var column := Totem.new()
		column.radial_segments = [4,6,8,12,16][posmod(index,5)]
		column.profile_rings = 4
		column.profile_kind = posmod(index + (1 if side == 1 else 0),5)
		column.column_height = 3.3 + posmod(index,3)*0.65
		column.width_factor = 0.7
		column.collisions = false
		column.position = Vector3(side*5.4,0,-20)
		add_child(column)
		box(Vector3(side*5.4,-0.12,-20),Vector3(2.2,0.24,2.2),Color("bdbbb1"))
	# A triangle frame is composed of the same finite line skin.
	var a := Vector3(-3.7,0,-34)
	var b := Vector3(3.7,0,-34)
	var c := Vector3(0,6,-34)
	# Leave a clear view of the finish instead of layering two gates together.
	if not last_section:
		line(a,c,accent,0.065)
		line(c,b,accent,0.065)
		if phase == 1: line(a,b,accent,0.025)
	if phase == 1:
		for side in [-1,1]:
			var form := FaceBody.new()
			var points: Array[Vector3] = [Vector3(-1,0,0.8),Vector3(1,0,0.8),Vector3(0,0,-1),Vector3(0,2,0)]
			var faces: Array[Vector3i] = [Vector3i(0,1,3),Vector3i(1,2,3),Vector3i(2,0,3),Vector3i(0,2,1)]
			form.show_faces(points,faces)
			var target := Target.new()
			target.collision_layer = 16
			target.collision_mask = 0
			target.position = Vector3(side*5,0.2,-7)
			target.rotation.y = side*0.4
			target.add_child(form)
			var boundary := CollisionShape3D.new()
			var shape := ConvexPolygonShape3D.new()
			shape.points = PackedVector3Array(points)
			boundary.shape = shape
			target.add_child(boundary)
			mark_target(target,Vector3(0,0.8,0.86),0.2)
			add_child(target)
	if index % 3 == 0:
		var title := Label3D.new()
		title.text = Course.TITLES[phase]
		title.position = Vector3(0,4.7,-3)
		title.font_size = 64
		title.pixel_size = 0.009
		title.outline_size = 0
		title.modulate = accent
		add_child(title)
	if phase == 2:
		for side in [-1,1]:
			var target := add_hazard("cube",side*5,-8)
			# These side cubes are optional targets, outside the running lanes.
			target.collision_layer = 16
			target.position.y = 2
			target.rotation_degrees = Vector3(25,35,20)
	if phase == 3:
		for i in range(9):
			box(Vector3(-5.4+i*1.35,5,-29),Vector3(0.85,0.25,0.85),Color.from_hsv(i/10.0,0.32,0.85))

func add_hazard(kind: String, x: float, z: float) -> StaticBody3D:
	var body: StaticBody3D = Target.new() if kind=="cube" else StaticBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	body.set_meta("hazard", kind)
	var size := Vector3(1.4,1.8,1.15) if kind == "cube" else Vector3(1.65,0.32,0.38)
	body.position = Vector3(x,size.y/2,z)
	var shape := BoxShape3D.new()
	shape.size = size
	var boundary := CollisionShape3D.new()
	boundary.shape = shape
	body.add_child(boundary)
	var mesh := BoxBody.new(size)
	mesh.material_override = finish(Color("ede6d7") if kind == "cube" else Color("ef8eaf"),0.35)
	body.add_child(mesh)
	if kind == "cube":
		mark_target(body,Vector3(0,0,size.z/2+0.025),0.27)
		# Dark top edges make the tall obstacle distinct from golden pickups.
		for x_sign in [-1,1]:
			var edge := BoxBody.new(Vector3(0.035,0.035,size.z+0.04))
			edge.position = Vector3(x_sign*size.x/2,size.y/2,0)
			edge.material_override = finish(Color("22232b"),0.6)
			body.add_child(edge)
	add_child(body)
	hazards.append(body)
	return body

func mark_target(body: Node3D, centre: Vector3, radius: float) -> void:
	# Keep the mark legible on pale surfaces under the museum lighting.
	var plate := BoxBody.new(Vector3(radius*2.5,radius*2.5,0.012))
	plate.position = centre-Vector3(0,0,0.014)
	plate.material_override = finish(Color("162c30"),1)
	plate.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	body.add_child(plate)
	var corners := [Vector3.UP,Vector3.RIGHT,Vector3.DOWN,Vector3.LEFT]
	for i in range(4):
		var start: Vector3 = centre+corners[i]*radius
		var end: Vector3 = centre+corners[(i+1)%4]*radius
		var edge := LineSkin.new()
		edge.show_segment(start,end-start,start.distance_to(end))
		edge.material_override = finish(Color("8cffe1"),1)
		edge.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		body.add_child(edge)

func box(at: Vector3, size: Vector3, colour: Color) -> MeshInstance3D:
	var mesh := BoxBody.new(size)
	mesh.position = at
	mesh.material_override = finish(colour,0.55)
	add_child(mesh)
	return mesh

func line(a: Vector3, b: Vector3, colour: Color, radius: float) -> MeshInstance3D:
	var mesh := LineSkin.new()
	mesh.show_segment(a,b-a,a.distance_to(b))
	mesh.mesh.top_radius = radius
	mesh.mesh.bottom_radius = radius
	mesh.material_override = finish(colour,0.35)
	add_child(mesh)
	return mesh

static func finish(colour: Color, roughness: float, glow := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = roughness
	if glow > 0:
		material.emission_enabled = true
		material.emission = colour
		material.emission_energy_multiplier = glow
	return material
