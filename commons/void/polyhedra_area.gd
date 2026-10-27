extends "res://commons/void/lines_area.gd"
## Tower arrangement of the existing Polyhedra encounters. Original scenes own
## alignment, gravity, geometry, grips and unfolding.
const Tetra = preload("res://commons/artifacts/primitive_encounters/align_tetrahedron.tscn")
const Wedge = preload("res://commons/artifacts/primitive_encounters/align_wedge.tscn")
const Corner = preload("res://commons/artifacts/primitive_encounters/corner_tetrahedron.tscn")
const OpenBody = preload("res://commons/primitives/trihedron/grab_trihedron.tscn")
const ClosedBody = preload("res://commons/primitives/tetrahedron/grab_tetrahedron.tscn")
const Pyramid = preload("res://commons/primitives/pyramid/pyramid_edit.tscn")
const Plate = preload("res://commons/artifacts/polyhedra_boundary_plate/polyhedra_boundary_plate.tscn")
const Monitor = preload("res://commons/artifacts/concept_monitor/polyhedra_reveal_monitor.tscn")
const Prism = preload("res://commons/primitives/prismes/prism_block.tscn")
const Platform = preload("res://commons/void/polyhedra_walk_up.tscn")
const TetraBlocker = preload("res://commons/artifacts/primitive_encounters/tetrahedron_blocker.tscn")
const PyramidBlocker = preload("res://commons/artifacts/primitive_encounters/pyramid_blocker.tscn")
const WedgeBlocker = preload("res://commons/artifacts/primitive_encounters/wedge_blocker.tscn")
const Column = preload("res://commons/artifacts/primitive_encounters/wedge_column.tscn")
@export_enum("closure", "boundaries", "obstruction", "support") var encounter := "closure"
var homes: Dictionary = {}

func _ready() -> void:
	add_to_group("void_lines_area")
	set_meta("em_map","Primitives_Polythedra")
	match encounter:
		"closure":
			for entry in [[Tetra,"AlignTetrahedron",Vector3(0,0,2.2)],[Wedge,"AlignWedge",Vector3(0,0,-1.6)]]:
				var instrument := place(entry[0],entry[1],entry[2])
				instrument.completed.connect(remember_homes)
			place(Corner,"CornerTetrahedron",Vector3(.8,0,-8.1))
			words("01 / TRIANGLES CLOSE A BODY",Vector3(0,.025,4.5),true,.0018)
			words("THE ENDLESS MUSEUM\nalways another room",Vector3(2.2,3.15,-8.0),false,.0018)
		"boundaries":
			wall(Vector3(-3,.45,1.5),Vector3(1.5,.9,1.5),Color("e8e4da"),"OpenBodyPlinth")
			place(OpenBody,"OpenTrihedron",Vector3(-3,1.5,1.5))
			wall(Vector3(-3,.45,-1.2),Vector3(1.5,.9,1.5),Color("e8e4da"),"ClosedBodyPlinth")
			place(ClosedBody,"ClosedTetrahedron",Vector3(-3,1.5,-1.2))
			wall(Vector3(0,.45,1.5),Vector3(1.3,.9,1.1),Color("e8e4da"),"PyramidPlinth")
			place(Pyramid,"EditablePyramid",Vector3(0,.9,1.5),0,{"workbench":true})
			place(Plate,"VisibleAndPhysicalBoundary",Vector3(-.5,0,-2.6)).scale=Vector3.ONE*.8
			# This observer already knows the shipped grabbable tetrahedron type.
			# Keeping its source in this assembly scopes copies to their own object.
			place(Monitor,"UnfoldingMonitor",Vector3(3.5,0,-.8))
			words("02 / SURFACE AND COLLISION",Vector3(0,.025,3.5),true,.0018)
			words("3 VISIBLE FACES / A CLOSED COLLISION HULL",Vector3(-3,.025,2.55),true,.00085)
			words("4 FACES / TURN THE CLOSED BODY",Vector3(-3,.025,-.15),true,.001)
			words("MOVE A CORNER / SEVERAL FACES CHANGE",Vector3(2,.025,2.3),true,.00095)
		"obstruction":
			place(TetraBlocker,"TetrahedronBlocker",Vector3(-3.2,0,0))
			place(PyramidBlocker,"PyramidBlocker",Vector3.ZERO)
			# The upright face meets the approach; walking round reveals the slope.
			place(WedgeBlocker,"WedgeBlocker",Vector3(3.2,0,0),180)
			place(load("res://commons/artifacts/primitive_encounters/traffic_pyramid_5.tscn"),"TrafficPyramidFive",Vector3(0,0,-1.3))
			place(load("res://commons/artifacts/primitive_encounters/pentagonal_bipyramid_7.tscn"),"SevenVertexCrystal",Vector3(5.2,0,0))
			words("7 VERTICES / TWO TIPS + FIVE AROUND",Vector3(5.2,.025,1.15),true,.00085)
			words("03 / COMPLETED SOLIDS BECOME BUILDING PIECES",Vector3(0,.025,-1.7),true,.0015)
			for entry in [[-3.2,"TETRAHEDRON / 4 FACES"],[0,"PYRAMID / 5 FACES"],[3.2,"WEDGE / BLOCK OR CLIMB"]]:
				words(entry[1],Vector3(entry[0],.025,1.5),true,.0011)
		"support":
			place(Platform,"WedgePlatform",Vector3.ZERO)
			place(Column,"WedgeColumn",Vector3(-.95,1,-.95))
			words("04 / A SOLID CAN SUPPORT A PATH",Vector3(-4.7,.025,1.9),true,.0016)
			words("wp / SIX VERTICES\n2 m RUN / 1 m RISE",Vector3(-3,.025,2.4),true,.0013)
	for child in get_children():
		if child is Node3D:
			var bounds := _mesh_bounds(child,child)
			part_defaults[str(child.name)]={"position":[child.position.x,child.position.y,child.position.z],"rotation":[child.rotation_degrees.x,child.rotation_degrees.y,child.rotation_degrees.z],"bounds":[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z]}
	remember_homes.call_deferred()

func place(scene: PackedScene, title: String, at: Vector3, facing := 0.0, settings := {}) -> Node3D:
	var node := scene.instantiate() as Node3D
	node.name=title;node.position=at;node.rotation_degrees.y=facing
	for key in settings: node.set(key,settings[key])
	add_child(node)
	return node

func remember_homes() -> void:
	for body in find_children("*","RigidBody3D",true,false):
		if body.has_method("is_picked_up") and not homes.has(body): homes[body]=body.transform

func reset_after_fall() -> void:
	# Recover escaped pieces on retry; preserve completed alignment and edits.
	for body in homes:
		if not is_instance_valid(body) or body.is_picked_up(): continue
		if body.global_position.y < global_position.y-1:
			body.transform=homes[body]
			body.linear_velocity=Vector3.ZERO;body.angular_velocity=Vector3.ZERO
			PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
