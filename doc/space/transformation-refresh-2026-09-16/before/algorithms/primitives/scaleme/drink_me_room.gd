extends Node3D
## A bounded scale experiment. Only Room changes; the museum and body do not.
const FACTOR := 10.0
const TABLE := preload("res://commons/artifacts/dream_bodies/figures/food_table.tscn")
const FIGURE := preload("res://commons/artifacts/dream_bodies/figures/crystal_suit.tscn")
const BOTTLE := preload("res://algorithms/primitives/scaleme/drink_me_bottle.gd")
var room: Node3D
var bottle: XRToolsPickable
var table: Node3D
var figure: Node3D
var enlarged := false
var landings: Array[Vector3] = [] # Table-local top surfaces, highest first.
var landing_radii: Array[float] = []
var porcelain: StandardMaterial3D

func _ready() -> void:
	get_parent().set_meta("em_visibility_bounds", AABB(Vector3(-3,0,0),Vector3(6,3.3,6)))
	room = Node3D.new(); room.name = "Room"; add_child(room)
	room.position.y = 0.04 # Separate the authored floor from the museum deck.
	porcelain = material(Color("f4e7d4"))
	var wall_mat := material(Color("40535d"))
	var floor_mat := material(Color("ae8870"))
	box(room, "Floor", Vector3(6,0.04,6), Vector3(0,-0.02,3), floor_mat)
	box(room, "LeftWall", Vector3(0.08,3.2,6.08), Vector3(-3.04,1.6,3), wall_mat)
	box(room, "RightWall", Vector3(0.08,3.2,6.08), Vector3(3.04,1.6,3), wall_mat)
	box(room, "Ceiling", Vector3(6.16,0.06,6.16), Vector3(0,3.23,3), wall_mat)
	# Entry 1.4 x 2.4 m. The far door is physically cut out, never a painted decal.
	door_wall("Entry", 0.0, 1.4, 2.4, wall_mat)
	door_wall("TinyExit", 6.0, 0.18, 0.24, wall_mat, 2.0)
	var brass := material(Color("d8b36a"))
	box(room,"DoorFrameL",Vector3(0.02,0.26,0.03),Vector3(1.90,0.13,5.94),brass,false)
	box(room,"DoorFrameR",Vector3(0.02,0.26,0.03),Vector3(2.10,0.13,5.94),brass,false)
	box(room,"DoorFrameTop",Vector3(0.22,0.02,0.03),Vector3(2,0.25,5.94),brass,false)
	table = TABLE.instantiate(); table.name = "BloomingServiceTower"
	table.set("spread","blooming"); table.set("service","tower"); table.set("seed",1)
	room.add_child(table); table.position = Vector3(0,0,3)
	table.set_meta("artifact_lookup_name", "dream_food_table__spread-blooming__service-tower")
	figure = FIGURE.instantiate(); figure.name = "CrystalHost"
	figure.set("crust","spire"); figure.set("panels","leaning"); figure.set("seed",1)
	room.add_child(figure); figure.position = Vector3(0,0,4.8); figure.scale = Vector3.ONE * 1.35
	figure.set_meta("artifact_lookup_name", "dream_crystal_suit__crust-spire__panels-leaning")
	# Dream bodies are visual sculptures. Bake their actual mesh faces once so
	# the enlarged food and crystal remain physical, without hundreds of bodies.
	mesh_collision(table); mesh_collision(figure)
	# Porcelain serving steps wrap the existing tower. They exist at BOTH scales.
	# Their wide tops give a body somewhere to land without invisible platforms.
	for i in range(13):
		var h := 1.76 - i * 0.135
		var a := float(i) * 0.65
		var radius := 0.0 if i == 0 else 0.24 + float(i) * 0.025
		var p := Vector3(sin(a)*radius, h, -cos(a)*radius)
		var r := 0.13 if i == 0 else 0.14
		plate(table, "ServingStep%02d" % i, p, r)
		landings.append(p); landing_radii.append(r)
	make_bottle()
	var light := OmniLight3D.new(); light.position = Vector3(0,2.8,2.5)
	light.omni_range = 8; light.light_energy = 1.2; light.omni_attenuation = 0.5
	light.name = "RoomLight"; room.add_child(light)

func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = color; m.roughness = 0.6
	return m

func box(parent: Node3D, title: String, size: Vector3, pos: Vector3, mat: Material, solid := true) -> void:
	var mesh := BoxMesh.new(); mesh.size = size
	var mi := MeshInstance3D.new(); mi.name = title; mi.mesh = mesh; mi.material_override = mat
	parent.add_child(mi); mi.position = pos
	if solid:
		var body := StaticBody3D.new(); mi.add_child(body)
		var col := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size
		col.shape = shape; body.add_child(col)

func door_wall(title: String, z: float, width: float, height: float, mat: Material, centre := 0.0) -> void:
	var left := centre-width*0.5+3.0
	var right := 3.0-centre-width*0.5
	box(room,title+"Left",Vector3(left,3.2,0.08),Vector3(-3+left*0.5,1.6,z),mat)
	box(room,title+"Right",Vector3(right,3.2,0.08),Vector3(3-right*0.5,1.6,z),mat)
	box(room,title+"Lintel",Vector3(width,3.2-height,0.08),Vector3(centre,height+(3.2-height)*0.5,z),mat)

func mesh_collision(visual: Node3D) -> void:
	var faces := PackedVector3Array()
	for mi in visual.find_children("*", "MeshInstance3D", true, false):
		var local: Transform3D = visual.global_transform.affine_inverse() * mi.global_transform
		for v in mi.mesh.get_faces(): faces.append(local * v)
	var body := StaticBody3D.new(); body.name = "SculptureCollision"; visual.add_child(body)
	var col := CollisionShape3D.new(); var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces); shape.backface_collision = true; col.shape = shape; body.add_child(col)

func plate(parent: Node3D, title: String, top: Vector3, r: float) -> void:
	var mi := MeshInstance3D.new(); mi.name = title
	var mesh := CylinderMesh.new(); mesh.top_radius = r; mesh.bottom_radius = r; mesh.height = 0.025
	mesh.radial_segments = 32; mi.mesh = mesh; mi.material_override = porcelain
	parent.add_child(mi); mi.position = top - Vector3.UP*0.0125
	var body := StaticBody3D.new(); mi.add_child(body)
	var col := CollisionShape3D.new(); var shape := CylinderShape3D.new()
	shape.radius = r; shape.height = mesh.height; col.shape = shape; body.add_child(col)

func make_bottle() -> void:
	bottle = BOTTLE.new(); bottle.name = "DrinkMeBottle"; bottle.encounter = self
	bottle.freeze = true; bottle.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	bottle.collision_layer = 4; bottle.collision_mask = 196615 # XRTools pickable / hand layers.
	var shape := CylinderShape3D.new(); shape.radius = 0.07; shape.height = 0.25
	var col := CollisionShape3D.new(); col.shape = shape; bottle.add_child(col)
	var glass := material(Color("36b99e")); glass.metallic = 0.25; glass.roughness = 0.18
	var body_mesh := CylinderMesh.new(); body_mesh.top_radius = 0.06; body_mesh.bottom_radius = 0.065
	body_mesh.height = 0.18
	var body := MeshInstance3D.new(); body.mesh = body_mesh; body.material_override = glass; bottle.add_child(body)
	var neck_mesh := CylinderMesh.new(); neck_mesh.top_radius = 0.025; neck_mesh.bottom_radius = 0.04; neck_mesh.height = 0.08
	var neck := MeshInstance3D.new(); neck.mesh = neck_mesh; neck.position.y = 0.12; neck.material_override = glass; bottle.add_child(neck)
	box(bottle,"PaperLabel",Vector3(0.115,0.08,0.012),Vector3(0,0,-0.067),porcelain,false)
	var label := Label3D.new(); label.text = "DRINK\nME"; label.font_size = 40; label.pixel_size = 0.0009
	label.modulate = Color("20352f"); label.outline_size = 0; label.rotation.y = PI; label.position = Vector3(0,0,-0.075)
	bottle.add_child(label)
	# The physical label is supplemented by a readable hanging tag at arm's reach.
	var tag := Label3D.new(); tag.text = "DRINK ME"; tag.font_size = 32; tag.pixel_size = 0.003
	tag.position = Vector3(0,0.3,0); tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED; bottle.add_child(tag)
	add_child(bottle); bottle.position = room.position + table.position + landings[0] + Vector3.UP*0.10

func enlarge(actor: Node3D) -> void:
	if enlarged: return
	enlarged = true
	room.scale = Vector3.ONE * FACTOR
	get_parent().set_meta("em_visibility_bounds", AABB(Vector3(-30,0,0),Vector3(60,33,60)))
	room.get_node("RoomLight").omni_range = 80.0
	# No clock-driven reversal: a disappearing floor would invalidate the descent.
	await get_tree().physics_frame
	var feet := table.to_global(landings[0]) + Vector3.UP*0.08
	var destination := actor.global_transform; destination.origin = feet
	if actor is XRToolsPlayerBody:
		actor.teleport(destination)
	else:
		actor.global_transform = destination
	if actor is CharacterBody3D: actor.velocity = Vector3.ZERO
