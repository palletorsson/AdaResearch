extends "res://commons/void/lines_area.gd"
## wp -> F33's continuous static bridge -> portal walk into the sky.
const Bridge = preload("res://commons/scenes/mapobjects/bridge_path.tscn")
const Wedge = preload("res://commons/artifacts/primitive_encounters/wedge_blocker.tscn")
const Portals = preload("res://commons/primitives/combines/combine_portals.tscn")
const Ladder = preload("res://commons/void/portal_span_ladder.gd")
const Geometry = preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const Arrivals = preload("res://commons/void/portal_arrivals.gd")
const SweepStudy = preload("res://commons/void/portal_sweep_study.gd")
const RING_COUNT := 20
const RING_SPACING := 3.0
const RING_START := -18.5
const LAST_RING := RING_START+(RING_COUNT-1)*RING_SPACING
const LOOKOUT := LAST_RING+2.0

func _ready() -> void:
	add_to_group("void_exterior_walk")
	set_meta("source_maps",["Primitives_Portals","F33_Bridge"])
	var study := SweepStudy.new(); study.name="ProfileToRing"
	study.position=Vector3(-15.7,0,4.2);add_child(study)
	for index in range(2):
		var lane := -.5+index
		var suffix := str(index+1)
		bridge("WestSpan"+suffix,Vector3(-19,.4,lane),26)
		bridge("ShaftBridge"+suffix,Vector3(7,.4,lane),7)
		bridge("EastSpan"+suffix,Vector3(14,.4,lane),ceili(LOOKOUT)-14)
		var ramp: Node3D=Wedge.instantiate()
		ramp.name="EntryRamp"+suffix
		ramp.position=Vector3(-18.5+lane,0,2)
		ramp.rotation_degrees.y=180
		add_child(ramp)
	var ladder: Node3D=Portals.instantiate()
	ladder.set_script(Ladder)
	ladder.name="RefinementPassage";ladder.position=Vector3(-18.5,0,0)
	ladder.rotation_degrees.y=90
	ladder.portal_count=RING_COUNT;ladder.portal_spacing=RING_SPACING;ladder.discovery=true
	add_child(ladder)
	var arrivals:=Arrivals.new();arrivals.name="StrangeArrivals"
	arrivals.position=Vector3(LAST_RING,1,0)
	arrivals.ring_mesh=ladder._portals.back().mesh
	add_child(arrivals)
	# A wider endpoint lets the visitor turn and see the whole construction.
	var end := Node3D.new();end.name="SkyLookout";end.position=Vector3(LOOKOUT,0,0);add_child(end)
	Geometry.box(end,"Deck",Vector3(0,.9,0),Vector3(2,.2,3),Color("b8b5ab"))
	Geometry.box(end,"EndRail",Vector3(.95,1.95,0),Vector3(.06,.06,3),Color("30313b"))
	for z in [-1.45,1.45]:
		Geometry.box(end,"SideRail",Vector3(0,1.95,z),Vector3(2,.06,.06),Color("30313b"))
		Geometry.box(end,"Post",Vector3(.95,1.5,z),Vector3(.06,1,.06),Color("30313b"))
	words("WEDGE / BRIDGE",Vector3(-18.5,.025,3.3),true,.0015).modulate=Color("f7dce9")
	words("TWENTY RINGS / A FINITE WALK\nLOOK BACK AT WHAT BROUGHT YOU HERE",Vector3(LOOKOUT-.5,1.015,0),true,.0011).modulate=Color("322a36")
	for child in get_children():
		if child is Node3D:
			var bounds := _mesh_bounds(child,child)
			part_defaults[str(child.name)]={"position":[child.position.x,child.position.y,child.position.z],"rotation":[child.rotation_degrees.x,child.rotation_degrees.y,child.rotation_degrees.z],"bounds":[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z]}
			if child.has_meta("editor_label"):part_defaults[str(child.name)]["label"]=child.get_meta("editor_label")

func bridge(title: String, at: Vector3, count: int) -> void:
	var node: Node3D=Bridge.instantiate()
	node.name=title;node.position=at;node.bridge_length=count;node.bridge_axis="x"
	node.pulse_speed=0.0
	add_child(node)

