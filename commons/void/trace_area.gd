extends "res://commons/void/lines_area.gd"
## Placement adapters only: the museum's original scenes own drawing and sampling.
const Glass = preload("res://commons/artifacts/primitive_encounters/glass_paint_wall.tscn")
const Bead = preload("res://commons/primitives/point/draw_dot.tscn")
const Monitor = preload("res://commons/artifacts/concept_monitor/trace_sampling_monitor.tscn")
const Ramp = preload("res://commons/artifacts/trace_ball_ramp/trace_ball_ramp.tscn")
const ShadowPoint = preload("res://commons/void/shadow_trace_point.gd")
const GridReplay = preload("res://commons/void/grid_replay.tscn")
const SocketFrame = preload("res://commons/shadow_game/socket_frame.gd")
const TraceLight = preload("res://commons/void/trace_light.gd")
@export_enum("surface", "record", "release", "descent") var encounter := "surface"
@export var destination_title := "TRACE"
var bead_homes: Dictionary = {}

func _ready() -> void:
	add_to_group("void_lines_area") # The tower's existing recovery hook.
	match encounter:
		"surface":
			place(Glass,"GlassWall",Vector3(0,0.75,0))
			words("POINT TRACE / CONTACT LEAVES A MARK",Vector3(0,2.65,0),false,0.0016)
			words("THE ENDLESS MUSEUM\nalways another room",Vector3(0,3.25,0),false,0.0018)
		"record":
			for i in range(3):
				var x := float(i-1)*2.0
				wall(Vector3(x,0.45,0),Vector3(1.3,0.9,0.95),Color("e8e4da"),"BeadPlinth%d"%i)
				var bead := Bead.instantiate() as Node3D
				bead.name = "Bead%dmm"%[10,40,80][i]
				bead.position = Vector3(x,1.15,0)
				var config := {"tool":"bead","retention":"none","resolution":[10,40,80][i],"ink":["e05b91","30ad99","7b6bc4"][i],"data_table_scale":0.55,"data_table_tilt":50,"data_table_mount":"plinth"}
				for key in config: bead.set_meta("config_"+key,config[key])
				add_child(bead)
				bead.apply_grid_config(config)
				_light_trace(bead)
				bead_homes[str(bead.name)] = bead.get_node("GrabPoint").transform
			var monitor := place(Monitor,"SamplingMonitor",Vector3(4,0,-3.8))
			# The editor can place the screen anywhere on this 42m floor. Discovery
			# is still scoped to this hall; moving it must not disconnect the beads.
			monitor.active_distance = 50.0
			words("HOLD A POINT. KEEP ITS POSITIONS.",Vector3(0,0.025,1.6),true,0.0018)
			words("Release your drawing. Grid will receive a copy.",Vector3(0,0.025,2.15),true,0.0014)
			_shadow_points()
			# Keep drawing and its grid encounter on the same floor. This whole
			# encounter is a movable/copyable part in the lab editor.
			place(GridReplay,"GridReplay",Vector3(-4.7,0,0.6))
		"release":
			place(Ramp,"BallRamp",Vector3.ZERO)
			words("LET THE POINT CONTINUE",Vector3(0,2.5,-0.7),false,0.0018)
		"descent":
			# Mount at (6,-4.5). Two offset landings in shaft B; neither caps it.
			# Tops are at floor+3 and floor, splitting the six-metre fall.
			for step in range(2):
				var top := 3.0 if step==0 else 0.0
				var z := 2.85 if step==0 else 6.35
				for j in range(9):
					var plank := rod("Landing%dPlank%d"%[step,j],Vector3(5,top-0.03,z+(j-4)*0.26),Vector3.RIGHT,3.2,"plank",false)
					if step==1: plank.set_meta("void_floor_surface",true)
				for dz in [-0.98,0.98]:
					rod("Landing%dSteel"%step,Vector3(5.2,top-0.13,z+dz),Vector3.RIGHT,3.6,"beam",false)
					if step==0:
						rod("SteelHanger",Vector3(6.8,4.25,z+dz),Vector3.UP,2.8,"beam",false)
			# Outer edge rails leave both drop directions and slab exits open.
			for step in range(2):
				var top := 3.0 if step==0 else 0.0
				var z := 2.85 if step==0 else 6.35
				rod("CornerGuard",Vector3(3.35,top+0.9,z),Vector3.BACK,2.4,"beam",false)
				for dz in [-1.1,1.1]: rod("CornerPost",Vector3(3.35,top+0.45,z+dz),Vector3.UP,0.9,"beam",false)
			words("01 / LAND HERE",Vector3(5,3.012,2.85),true,0.0015)
			words("02 / " + destination_title,Vector3(5,0.012,6.35),true,0.0015)
			words(destination_title + " BELOW\nTwo short drops. Follow the timber.",Vector3(7.5,6.025,2.85),true,0.0016)
	for child in get_children():
		if child is Node3D:
			var bounds := _mesh_bounds(child,child)
			part_defaults[str(child.name)]={"position":[child.position.x,child.position.y,child.position.z],"rotation":[child.rotation_degrees.x,child.rotation_degrees.y,child.rotation_degrees.z],"bounds":[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z]}

func place(scene: PackedScene, title: String, at: Vector3) -> Node3D:
	var node := scene.instantiate() as Node3D
	node.name=title;node.position=at;add_child(node)
	return node

func _shadow_points() -> void:
	# A small study in the west bay. Each part is separately editable/copyable.
	# record mount is (-2, 1.2); existing artifacts and their aisles stay in place.
	wall(Vector3(-13,0.49,1.8),Vector3(0.55,0.98,0.55),Color("ece8dc"),"ShadowPointPlinth")
	var drawing := ShadowPoint.new()
	drawing.name = "ShadowPoint"
	drawing.position = Vector3(-13,1.05,1.8)
	add_child(drawing)
	_light_trace(drawing)
	for i in range(3):
		var at := Vector3(-15,0.98,1.8-i*2.2)
		wall(at-Vector3(0,0.49,0),Vector3(0.72,0.98,0.72),Color("ece8dc"),"OutlinePlinth%d"%i)
		var frame := SocketFrame.new()
		frame.name = "OutlineBox%d"%i
		frame.position = at+Vector3(0,0.252,0)
		add_child(frame)
	words("CARRY THE POINT THROUGH A FRAME\nRelease it. Its path remains.",Vector3(-13.8,0.025,3),true,0.0014)

func _light_trace(drawing: Node3D) -> void:
	var light := TraceLight.new()
	light.name = "TraceIllumination"
	drawing.add_child(light)

func reset_after_fall() -> void:
	# Do not erase ink or the shared archive. Recover escaped drawing handles.
	var shadow := get_node_or_null("ShadowPoint")
	if shadow != null: shadow.reset_after_fall()
	for key in bead_homes:
		var bead := get_node_or_null(NodePath(key))
		if bead==null: continue # An editor copy may contain only another part.
		var point: RigidBody3D = bead.get_node("GrabPoint")
		if not point.is_picked_up() and point.global_position.y<global_position.y-1:
			point.transform=bead_homes[key]
			point.linear_velocity=Vector3.ZERO;point.angular_velocity=Vector3.ZERO
			PhysicsServer3D.body_set_state(point.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,point.global_transform)
