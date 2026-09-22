extends Node3D
## A bounded scale experiment. Only Room changes; the museum and body do not.
const FACTOR := 4.0
const ROOM_WIDTH := 4.0
const ROOM_DEPTH := 4.0
const ROOM_HEIGHT := 3.2
const EXIT_X := 1.2
const EXIT_WIDTH := 0.45
const EXIT_HEIGHT := 0.60
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
var witness: Node3D # An ordinary doorway outside the scaling parent.

func _ready() -> void:
	# Reserve the complete experiment from the start; a reference door remains
	# visible beyond the small room and never joins its multiplication.
	get_parent().set_meta("em_visibility_bounds", AABB(Vector3(-8.4,0,-0.2),Vector3(16.8,13,18.2)))
	room = Node3D.new(); room.name = "Room"; add_child(room)
	room.position.y = 0.04 # Separate the authored floor from the museum deck.
	porcelain = material(Color("f4e7d4"))
	var wall_mat := material(Color("40535d"))
	var floor_mat := material(Color("ae8870"))
	box(room, "Floor", Vector3(ROOM_WIDTH,0.04,ROOM_DEPTH), Vector3(0,-0.02,ROOM_DEPTH*0.5), floor_mat)
	box(room, "LeftWall", Vector3(0.08,ROOM_HEIGHT,ROOM_DEPTH+0.08), Vector3(-ROOM_WIDTH*0.5-0.04,ROOM_HEIGHT*0.5,ROOM_DEPTH*0.5), wall_mat)
	box(room, "RightWall", Vector3(0.08,ROOM_HEIGHT,ROOM_DEPTH+0.08), Vector3(ROOM_WIDTH*0.5+0.04,ROOM_HEIGHT*0.5,ROOM_DEPTH*0.5), wall_mat)
	box(room, "Ceiling", Vector3(ROOM_WIDTH+0.16,0.06,ROOM_DEPTH+0.16), Vector3(0,ROOM_HEIGHT+0.03,ROOM_DEPTH*0.5), wall_mat)
	# Entry 1.4 x 2.4 m. The far door is physically cut out, never a painted decal.
	door_wall("Entry", 0.0, 1.4, 2.4, wall_mat)
	door_wall("TinyExit", ROOM_DEPTH, EXIT_WIDTH, EXIT_HEIGHT, wall_mat, EXIT_X)
	var brass := material(Color("d8b36a"))
	box(room,"DoorFrameL",Vector3(0.02,EXIT_HEIGHT+0.02,0.03),Vector3(EXIT_X-EXIT_WIDTH*0.5-0.01,EXIT_HEIGHT*0.5+0.01,ROOM_DEPTH-0.06),brass,false)
	box(room,"DoorFrameR",Vector3(0.02,EXIT_HEIGHT+0.02,0.03),Vector3(EXIT_X+EXIT_WIDTH*0.5+0.01,EXIT_HEIGHT*0.5+0.01,ROOM_DEPTH-0.06),brass,false)
	box(room,"DoorFrameTop",Vector3(EXIT_WIDTH+0.04,0.02,0.03),Vector3(EXIT_X,EXIT_HEIGHT+0.01,ROOM_DEPTH-0.06),brass,false)
	table = TABLE.instantiate(); table.name = "BloomingServiceTower"
	table.set("spread","blooming"); table.set("service","tower"); table.set("seed",1)
	room.add_child(table); table.position = Vector3(0,0,1.7)
	table.set_meta("artifact_lookup_name", "dream_food_table__spread-blooming__service-tower")
	figure = FIGURE.instantiate(); figure.name = "CrystalHost"
	figure.set("crust","spire"); figure.set("panels","leaning"); figure.set("seed",1)
	room.add_child(figure); figure.position = Vector3(0,0,3.1); figure.scale = Vector3.ONE * 1.35
	figure.set_meta("artifact_lookup_name", "dream_crystal_suit__crust-spire__panels-leaning")
	# Dream bodies are visual sculptures. Bake their actual mesh faces once so
	# the enlarged food and crystal remain physical, without hundreds of bodies.
	mesh_collision(table); mesh_collision(figure)
	# Porcelain serving steps wrap the existing tower. They exist at BOTH scales.
	# Their wide tops give a body somewhere to land without invisible platforms.
	for i in range(13):
		var h := 1.76 - i * 0.135
		# At fourfold scale, neighbouring centres must clear the previous
		# plate AND the body radius; the old tight spiral stranded the feet
		# on a higher plate even while the player reached the next centre.
		var a := float(i) * 0.95
		var radius := 0.0 if i == 0 else 0.24 + float(i) * 0.025
		var p := Vector3(sin(a)*radius, h, -cos(a)*radius)
		var r := 0.13 if i == 0 else 0.14
		plate(table, "ServingStep%02d" % i, p, r)
		landings.append(p); landing_radii.append(r)
	make_bottle()
	make_witness(brass)
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
	var half := ROOM_WIDTH*0.5
	var left := centre-width*0.5+half
	var right := half-centre-width*0.5
	box(room,title+"Left",Vector3(left,ROOM_HEIGHT,0.08),Vector3(-half+left*0.5,ROOM_HEIGHT*0.5,z),mat)
	box(room,title+"Right",Vector3(right,ROOM_HEIGHT,0.08),Vector3(half-right*0.5,ROOM_HEIGHT*0.5,z),mat)
	box(room,title+"Lintel",Vector3(width,ROOM_HEIGHT-height,0.08),Vector3(centre,height+(ROOM_HEIGHT-height)*0.5,z),mat)

func make_witness(mat: Material) -> void:
	# The same 1.8 x 2.4 m opening, already body-sized and outside Room.
	# At the exit the two frames line up. Only one has changed.
	witness = Node3D.new(); witness.name = "UnscaledDoorway"; add_child(witness)
	witness.position = Vector3(EXIT_X*FACTOR,0,ROOM_DEPTH*FACTOR+1.15)
	var w := EXIT_WIDTH*FACTOR
	var h := EXIT_HEIGHT*FACTOR
	box(witness,"LeftPost",Vector3(0.08,h+0.08,0.12),Vector3(-w*0.5-0.04,h*0.5+0.04,0),mat)
	box(witness,"RightPost",Vector3(0.08,h+0.08,0.12),Vector3(w*0.5+0.04,h*0.5+0.04,0),mat)
	box(witness,"Lintel",Vector3(w,0.08,0.12),Vector3(0,h+0.04,0),mat)
	var label := Label3D.new(); label.text = "1.8 m x 2.4 m\nTHIS FRAME STAYED THE SAME"
	label.font_size = 36; label.pixel_size = 0.003; label.outline_size = 4
	label.position = Vector3(0,h+0.35,0); label.rotation.y = PI
	witness.add_child(label)

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
	room.get_node("RoomLight").omni_range = 8.0*FACTOR
	# No clock-driven reversal: a disappearing floor would invalidate the descent.
	await get_tree().physics_frame
	var feet := table.to_global(landings[0]) + Vector3.UP*0.08
	var destination := actor.global_transform; destination.origin = feet
	if actor is XRToolsPlayerBody:
		actor.teleport(destination)
	else:
		actor.global_transform = destination
	if actor is CharacterBody3D: actor.velocity = Vector3.ZERO
