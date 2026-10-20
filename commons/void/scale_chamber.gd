extends "res://algorithms/primitives/scaleme/drink_me_room.gd"
## The unchanged Drink Me experiment on a movable exterior foundation.
## The foundation, return path and reference frame never inherit Room.scale.
const Parts = preload("res://commons/artifacts/rotation_studies/parts.gd")
const REGION := AABB(Vector3(-10.2,-0.3,-6.5),Vector3(20.4,14.8,26.9))

func _ready() -> void:
	add_to_group("void_floor_extension")
	add_to_group("void_exterior_walk")
	Parts.box(self,"Foundation",Vector3(20,.36,22),Vector3(0,-.18,9),Color("a9a6a5"))
	Parts.box(self,"Bridge",Vector3(3,.36,4.4),Vector3(0,-.18,-4.2),Color("a9a6a5"))
	for x in [-9.9,9.9]:
		Parts.box(self,"SideRail",Vector3(.1,1.1,22),Vector3(x,.55,9),Color("45434b"))
		for z in [-1.8,19.8]:
			Parts.box(self,"Column",Vector3(.25,14,.25),Vector3(x,7,z),Color("41414a"))
	for z in [-1.8,19.8]:
		Parts.box(self,"HighBeam",Vector3(20,.25,.25),Vector3(0,14,z),Color("41414a"))
	Parts.box(self,"RearRail",Vector3(20,1.1,.1),Vector3(0,.55,19.9),Color("45434b"))
	for x in [-5.8,5.8]:
		Parts.box(self,"FrontRail",Vector3(8.3,1.1,.1),Vector3(x,.55,-1.95),Color("45434b"))
	for x in [-1.5,1.5]:
		Parts.box(self,"BridgeRail",Vector3(.08,1.1,4.3),Vector3(x,.55,-4.15),Color("45434b"))
	var title := Parts.label(self,"SCALE / DRINK ME",Vector3(0,2.7,-1),36)
	title.pixel_size=.005
	super._ready()
	# A real walkable route around the enlarged room leads back to the bridge.
	for at in [Vector3(-9,.015,17.7),Vector3(-9,.015,8),Vector3(0,.015,-1.2)]:
		var mark := Parts.label(self,"RETURN TO THE CAROUSELS",at,24)
		mark.pixel_size=.003
		mark.rotation_degrees=Vector3(-90,180,0)

func contains_visitor(world_position: Vector3) -> bool:
	return REGION.has_point(to_local(world_position))

func enlarge(actor: Node3D) -> void:
	if enlarged: return
	await super.enlarge(actor)
	# The museum relocation is a cut, not seven metres of movement or a jump.
	var ancestor: Node = self
	while ancestor != null:
		if ancestor.has_method("rebase_player_motion") and ancestor.get("body") == actor:
			ancestor.rebase_player_motion()
			break
		ancestor=ancestor.get_parent()
