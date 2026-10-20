extends Node3D
## Four assemblies of existing museum artifacts; each has one ceiling distribution socket.
## The tower supplies the arrangement. The source artifacts keep their behaviour.
const Pairing = preload("res://commons/artifacts/primitive_encounters/pairing_field.gd")
const BlackBox = preload("res://commons/artifacts/line_black_box/line_black_box.gd")
const EntryGate = preload("lines_entry_gate.gd")
const Survey = preload("lines_survey.gd")
const LightTunnel = preload("lines_light_tunnel.gd")
const TouchLight = preload("line_touch_light.gd")
const Barrier = preload("res://commons/artifacts/do_not_cross_barrier/do_not_cross_barrier.gd")
const Marking = preload("res://commons/artifacts/walk_this_line_marking/walk_this_line_marking.gd")
const LineBody = preload("res://commons/artifacts/line_relations_gallery/line_body.gd")
const Hazard = preload("res://commons/artifacts/anamorphic_cross/anamorphic_cross.gd")
const Recovery = preload("res://commons/artifacts/health_cross/health_cross.gd")
const Trace = preload("lines_trace.gd")
const Laser = preload("res://commons/primitives/laser_measure/grab_laser_measure.tscn")
const Reactions = preload("res://commons/interactables/artifact_reactions/router.gd")
@export_enum("setting_out", "directions", "assembly", "consequences") var area := "setting_out"
var part_defaults: Dictionary = {}
var name_counts: Dictionary = {}
var reusable: Array[Node3D] = []
var initial_poses: Array[Transform3D] = []
var safety: Node
var health_label: Label3D
var hazard: Node3D
var recovery: Node3D
var trace: Node3D

func _ready() -> void:
	add_to_group("void_lines_area")
	safety = get_tree().get_first_node_in_group("void_health")
	match area:
		"setting_out": _setting_out()
		"directions": _directions()
		"assembly": _assembly()
		"consequences": _consequences()
	for child in get_children():
		if child is Node3D:
			part_defaults[str(child.name)]={"position":[child.position.x,child.position.y,child.position.z],"rotation":[child.rotation_degrees.x,child.rotation_degrees.y,child.rotation_degrees.z]}
			var bounds := _mesh_bounds(child,child)
			part_defaults[str(child.name)]["bounds"]=[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z]

func _setting_out() -> void:
	var field := Pairing.new()
	field.name = "PairingPoints"
	field.position = Vector3(0,0,3.0)
	add_child(field)
	var room := EntryGate.new()
	room.name = "MeasurementRoom"
	room.position = Vector3(0,0,-3.2)
	add_child(room)
	var plan := Survey.new()
	plan.name = "FloorPlanTable"
	plan.position = Vector3(16.5,0,-2.7)
	add_child(plan)
	var ruler := Survey.new()
	ruler.name = "FullSizeRuler"
	ruler.plan = false
	ruler.position = Vector3(16.5,0,-5.8)
	add_child(ruler)
	var laser := Laser.instantiate() as RigidBody3D
	laser.name = "SurveyLaser"
	laser.position = Vector3(2.8,1.1,0)
	laser.rotation_degrees.y = 90
	laser.get_node("LaserMeasure").burns = false
	laser.get_node("LaserMeasure").lethal = false
	laser.get_node("LaserMeasure").deals_damage = false
	add_child(laser)
	reusable.append(laser)
	initial_poses.append(laser.transform)
	wall(Vector3(2.8,0.45,0),Vector3(0.7,0.9,0.7),Color("e8e4da"),"SurveyStand")
	# Room's own two openings remain free, including the path round its north wall.
	words("01 / SET OUT THE WORK",Vector3(0,0.025,6.0),true)
	words("Two points. A relation. A length.",Vector3(0,0.025,5.5),true,0.0016)
	wall(Vector3(0,1.5,-6.15),Vector3(6.8,3,0.15))
	words("THE ENDLESS MUSEUM\nalways another room",Vector3(0,2.3,-6.05))

func _directions() -> void:
	words("02 / WHAT DOES A LINE ASK?",Vector3(-1,0.025,5.7),true)
	for row in [[Vector3(-3.7,0,2.2),3.6],[Vector3(-2,0,0),2.8]]:
		var barrier := Barrier.new()
		barrier.name = _unique("PoliceBarricade")
		barrier.form = "sawhorse"
		barrier.legend_text = "DO NOT CROSS"
		barrier.span_m = row[1]
		barrier.height_m = 1.1
		barrier.solid = true
		barrier.position = row[0]
		add_child(barrier)
	var walk := Marking.new()
	walk.name = "WalkThisLine"
	walk.stripe_len_m = 6.0
	walk.paint_color = Color("202329")
	walk.position = Vector3(0.4,0,0)
	walk.rotation.y = PI/2
	add_child(walk)
	var red := Marking.new()
	red.name = "RedLine"
	red.legend_text = "RED LINE / OPEN SHAFT"
	red.stripe_len_m = 4.6
	red.paint_color = Color("bb3049")
	red.position = Vector3(7.15,0,0)
	red.rotation.y = PI/2
	add_child(red)
	# A painted instruction acquires an unsupported continuation over shaft B.
	wall(Vector3(4.5,0.7,-1.4),Vector3(1.6,1.4,1.6),Color("efeee7"),"WhiteCrate")
	for z in [-2.05,-0.75]:
		wall(Vector3(4.5,0.7,z),Vector3(1.62,0.035,0.025),Color("bebdb6"),"CrateSeam",false)
	mark("FollowApproach",Vector3(1.8,0.018,-1.4),Vector3(3.8,0.016,0.08))
	mark("FollowUp",Vector3(3.694,0.7,-1.4),Vector3(0.012,1.4,0.08))
	mark("FollowOver",Vector3(4.5,1.412,-1.4),Vector3(1.62,0.016,0.08))
	mark("FollowIntoAir",Vector3(7.5,1.412,-1.4),Vector3(4.4,0.016,0.08))
	words("FOLLOW THIS LINE",Vector3(1.1,0.025,-2.3),true)
	words("Your eye can continue.",Vector3(4.5,0.025,-3.0),true,0.0015)
	# The survey lines have no collision. Their apparent meeting is in the view.
	for x in [-1.0,1.0]:
		mark("ParallelSurvey",Vector3(x,0.014,-4.8),Vector3(0.04,0.02,5.5))
	words("PARALLEL",Vector3(0,0.025,-7.7),true,0.0017)
	trace = Trace.new()
	trace.name = "PlayerTrace"
	add_child(trace)

func _assembly() -> void:
	words("03 / A BODY FOR THE LINE",Vector3(0,0.025,6.0),true)
	# A working bench, then the same objects at architectural scale.
	wall(Vector3(0,0.84,-3.8),Vector3(5.8,0.12,1.4),Color("d3cbbb"),"BenchTop")
	for x in [-2.3,2.3]: wall(Vector3(x,0.4,-3.8),Vector3(0.16,0.8,1.1),Color("343a3c"),"BenchLeg")
	var finishes := ["plank","stick","light","measure"]
	for i in range(4):
		rod("Hand_"+finishes[i],Vector3(-2.1+i*1.4,1.05,-3.8),Vector3.BACK,1.05,finishes[i],true)
		words(finishes[i].to_upper(),Vector3(-2.1+i*1.4,0.025,-2.7),true,0.0013)
	# + and X are grabbable line studies. Neither has a health effect.
	for entry in [[-1.7,0.0],[1.7,PI/4]]:
		var angle: float = entry[1]
		for j in range(2):
			var direction := Vector3.RIGHT.rotated(Vector3.FORWARD,angle+j*PI/2)
			rod("Relation",Vector3(entry[0],1.2,0.0+0.16*j),direction,1.7,"point_line",true)
	words("+     TWO LINES     X",Vector3(0,0.025,1.5),true,0.0018)
	for x in [-1.2,1.2]: rod("Upright",Vector3(x,1.1,3.7),Vector3.UP,2.0,"beam",true)
	for z in [2.5,3.2]: rod("ParallelPlank",Vector3(0,0.1,z),Vector3.RIGHT,3.6,"plank",true)
	# Seven increasing lengths hang from a common rail on the north wall.
	wall(Vector3(0,1.8,-6.25),Vector3(6.6,3.6,0.15))
	var hangers := Node3D.new()
	hangers.name = "CollectionHangers"
	add_child(hangers)
	var rail := wall(Vector3(0,3.6,-6.06),Vector3(5.7,.035,.035),Color("343a3c"),"CollectionRail",false)
	rail.reparent(hangers)
	for i in range(7):
		var span := 0.8+i*0.42
		var x := -2.7+i*0.77
		rod("SevenPlanks%d"%i,Vector3(x,1.8,-6.1),Vector3.UP,span,"plank",true)
		var top := 1.8+span/2
		var cable := wall(Vector3(x,(3.6+top)/2,-6.04),Vector3(.008,3.6-top,.008),Color("343a3c"),"HangingWire",false)
		cable.reparent(hangers)
	words("03 / SEVEN LENGTHS / TAKE A LINE",Vector3(0,3.85,-6.14),false,0.0016)
	# Fixed timber is deliberately distinct from movable specimens. Existing
	# line geometry is used; its actual collider carries the player's weight.
	for z in [0.9,1.16,1.42,1.68]:
		rod("BridgeBoard",Vector3(-6.5,0.0,z),Vector3.RIGHT,6.4,"plank",false)
	for z in [0.65,1.94]:
		rod("BridgeRail",Vector3(-6.5,1.05,z),Vector3.RIGHT,6.4,"beam",false)
		for x in [-9.5,-7.5,-5.5,-3.5]: rod("BridgePost",Vector3(x,0.52,z),Vector3.UP,1.04,"beam",false)
	words("FIXED TIMBER / CROSS HERE",Vector3(-2.7,0.025,1.3),true,0.0016)
	# Edge guard is a composition of uprights, rails and crossed braces.
	for z in [-4.5,-1.5,1.5,4.5]: rod("EdgePost",Vector3(4.0,0.55,z),Vector3.UP,1.1,"beam",false)
	rod("EdgeRail",Vector3(4,1.05,0),Vector3.BACK,9.0,"beam",false)
	for z in [-3,0,3]:
		for sign in [-1,1]: rod("EdgeBrace",Vector3(4,0.55,z),Vector3(0,0.95,sign*2.7).normalized(),2.86,"plank",false)
	rod("CeilingAlignment",Vector3(0,3.0,4.8),Vector3.RIGHT,2.8,"light",false)
	var tunnel := LightTunnel.new()
	tunnel.name = "LightTunnel"
	tunnel.position = Vector3(0,0,1.6)
	add_child(tunnel)
	# The six-line plane from the museum's fourth view. Each line remains a
	# separate, editable body: pulling one forward opens the drawing into depth.
	for i in range(3):
		var offset := (i-1)*0.6
		rod("DepthGridHorizontal%d"%i,Vector3(-2.4,1.35+offset,2.7),Vector3.RIGHT,1.8,"stick",true)
		rod("DepthGridVertical%d"%i,Vector3(-2.4+offset,1.35,2.78),Vector3.UP,1.8,"stick",true)
	words("SIX LINES / PULL ONE INTO DEPTH",Vector3(-2.4,.025,4.1),true,.0013)

func _consequences() -> void:
	words("04 / SAME SHAPE. ANOTHER OPERATION.",Vector3(0,0.025,1.5),true,0.0018)
	hazard = Hazard.new()
	hazard.name = "DangerX"
	hazard.passage = true
	hazard.bar_len_m = 2.4
	hazard.cross_height_m = 1.15
	hazard.damage_per_tick = 14
	hazard.tick_interval = 0.6
	hazard.health_provider = safety
	hazard.position = Vector3(-1.5,0,0)
	add_child(hazard)
	recovery = Recovery.new()
	recovery.name = "RecoveryPlus"
	recovery.boost = 28
	recovery.take_below = 1.0
	recovery.respawn_s = 5.0
	recovery.passage = true
	recovery.arm_m = 0.7
	recovery.hover_m = 1.05
	recovery.cross_color = Color("bdebdc")
	recovery.health_provider = safety
	recovery.position = Vector3(1.8,0,0)
	add_child(recovery)
	words("X / CHARGE DRAINS WHILE INSIDE",Vector3(-1.5,0.025,-1.0),true,0.0012)
	words("+ / RECOVER",Vector3(1.8,0.025,-1.0),true,0.0014)
	health_label = words("CHARGE 100 / 100",Vector3(0,2.0,0),false,0.0021)
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	if safety != null: safety.changed.connect(_health_changed)
	wall(Vector3(0,1.0,2.1),Vector3(5.8,2.0,0.12),Color("dad3c5"),"ServiceWall")
	var caption := words("A sign. A boundary. A consequence.\nYou can go around this pair.",Vector3(0,1.4,2.02),false,0.0018)
	caption.rotation.y = PI

func _health_changed(value: float, _difference: float) -> void:
	if is_instance_valid(health_label): health_label.text = "CHARGE %d / 100" % roundi(value)

func rod(title: String, at: Vector3, direction: Vector3, span: float, skin: String, movable: bool) -> Node3D:
	var line := LineBody.new()
	line.name = _unique(title)
	line.collision_layer = 6
	line.collision_mask = 1
	line.skin = skin
	line.span = span
	line.position = at
	line.quaternion = Quaternion(Vector3.RIGHT,direction.normalized())
	add_child(line)
	if movable:
		var illumination := TouchLight.new()
		illumination.name = "TouchIllumination"
		line.add_child(illumination)
		reusable.append(line)
		initial_poses.append(line.transform)
		# The museum's tool contract belongs to specimens, never the bridge,
		# edge guards, furniture or the fixed structure supporting a visitor.
		Reactions.attach.call_deferred(line,{"reactive":"break","rebuild":8})
	else:
		line.enabled = false
		line.collision_layer = 1
		line.collision_mask = 0
		line.freeze = true
		line.set_meta("fixed_construction",true)
	return line

func reset_after_fall() -> void:
	for i in range(reusable.size()):
		var line: RigidBody3D = reusable[i]
		if line.is_picked_up(): continue
		line.transform = initial_poses[i]
		PhysicsServer3D.body_set_state(line.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,line.global_transform)
		line.linear_velocity = Vector3.ZERO
		line.angular_velocity = Vector3.ZERO
	if is_instance_valid(trace): trace.clear_trail()
	var room := get_node_or_null("MeasurementRoom")
	if room != null: room.reset_line()
	for key in ["FloorPlanTable","FullSizeRuler"]:
		var survey := get_node_or_null(NodePath(key))
		if survey != null: survey.reset_line()
	var field := get_node_or_null("PairingPoints")
	if field != null:
		# Keep authored point placement accessible; connections remain the field's own state.
		for p in field.points:
			if p.global_position.y < global_position.y-2:
				p.position = Vector3(0,1.1,3)
				PhysicsServer3D.body_set_state(p.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,p.global_transform)

func wall(at: Vector3, size: Vector3, colour := Color("c3bdb1"), title := "Wall", solid := true) -> Node3D:
	var host: Node3D = StaticBody3D.new() if solid else Node3D.new()
	host.name = _unique(title)
	host.position = at
	add_child(host)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new();box.size = size
	var mat := StandardMaterial3D.new();mat.albedo_color = colour;mat.roughness = 0.85
	mesh.mesh = box;mesh.material_override = mat;host.add_child(mesh)
	if solid:
		var col := CollisionShape3D.new();var shape := BoxShape3D.new();shape.size = size
		col.shape = shape;host.add_child(col)
	return host

func mark(title: String, at: Vector3, size: Vector3) -> void:
	wall(at,size,Color("202329"),title,false)

func words(text: String, at: Vector3, flat := false, pixels := 0.0023) -> Label3D:
	var label := Label3D.new()
	label.name = _unique("Caption");label.text = text;label.font_size = 64;label.pixel_size = pixels
	label.outline_size = 0;label.modulate = Color("202329");label.position = at
	if flat: label.rotation.x = -PI/2
	add_child(label)
	return label

func _unique(title: String) -> String:
	var n := int(name_counts.get(title,0))
	name_counts[title]=n+1
	return title if n==0 else title+"_"+str(n+1)

func apply_grid_config(config: Dictionary) -> void:
	# A copied part is built fresh by the same factory, then isolated. Duplicating
	# an already-running node would run _ready twice on its generated children.
	if config.has("only_parts"):
		var kept: Array = config.only_parts
		for i in range(reusable.size()-1,-1,-1):
			if str(reusable[i].name) not in kept:
				reusable.remove_at(i)
				initial_poses.remove_at(i)
		for child in get_children():
			if str(child.name) not in kept:
				part_defaults.erase(str(child.name))
				child.free()
	for key in config.get("parts",{}):
		if not part_defaults.has(key): continue
		var node := get_node_or_null(NodePath(key)) as Node3D
		if node==null: continue
		var placement: Dictionary = config.parts[key]
		var pos: Array = placement.get("position",part_defaults[key].position)
		var rot: Array = placement.get("rotation",part_defaults[key].rotation)
		node.position=Vector3(float(pos[0]),float(pos[1]),float(pos[2]))
		node.rotation_degrees=Vector3(float(rot[0]),float(rot[1]),float(rot[2]))
		# Frozen pickables also have a physics-server transform. Synchronize it
		# after an editor move so physics cannot restore the previous world pose.
		_sync_bodies(node)
	for i in range(reusable.size()): initial_poses[i]=reusable[i].transform

func _sync_bodies(node: Node) -> void:
	if node is RigidBody3D:
		PhysicsServer3D.body_set_state(node.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,node.global_transform)
	for child in node.get_children(): _sync_bodies(child)

func _mesh_bounds(node: Node3D, relative_to: Node3D) -> AABB:
	var result := AABB()
	if node is MeshInstance3D and node.mesh!=null:
		result=(relative_to.global_transform.affine_inverse()*node.global_transform)*node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			var b := _mesh_bounds(child,relative_to)
			if b.has_surface(): result=b if not result.has_surface() else result.merge(b)
	return result
