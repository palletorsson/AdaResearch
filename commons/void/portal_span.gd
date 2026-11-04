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
## The pipe around the passage (Palle, 2026-11-04): a hollow cylinder on the rings' own axis (their centre is half
## the ladder's 4 m outside diameter up), opening just after the entry ramps and onto the lookout. 0.45 m clear of the
## rings all round, and no wider: floor 11's route passes the limit table at z 3.4, 2.9 m from the axis, and the
## walker's 0.2 m capsule must still clear the outer wall there (at most 2.6 m out).
const PIPE_AXIS_Y := 2.0
const PIPE_INNER := 2.45
const PIPE_WALL := .15
const PIPE_START := RING_START+1.1
const PIPE_END := LAST_RING+1.0

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
	pipe()
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

## Two open shells - the outer facing out, the inner flipped to be seen from inside - and a lip at each mouth.
func pipe() -> void:
	var length := PIPE_END-PIPE_START
	var body := StaticBody3D.new();body.name="RefinementPipe"
	body.position=Vector3((PIPE_START+PIPE_END)*.5,PIPE_AXIS_Y,0)
	body.set_meta("editor_label","pipe around the refinement passage")
	add_child(body)
	var glass := StandardMaterial3D.new()
	# Steel-blue glass: dark enough to read as a pipe against the grey hall, clear enough to keep the rings in view.
	glass.albedo_color=Color(Color("5f7a96"),.55);glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.metallic=.4;glass.roughness=.25
	for flip in [false,true]:
		var shell := CylinderMesh.new()
		shell.top_radius=PIPE_INNER+(0.0 if flip else PIPE_WALL);shell.bottom_radius=shell.top_radius
		shell.height=length;shell.radial_segments=72;shell.rings=1
		shell.cap_top=false;shell.cap_bottom=false;shell.flip_faces=flip
		var mesh := MeshInstance3D.new();mesh.name="Inner" if flip else "Outer";mesh.mesh=shell
		mesh.material_override=glass;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.rotation_degrees.z=90   # the cylinder's axis is Y; the passage runs along X
		body.add_child(mesh)
		var shape := CollisionShape3D.new();shape.name=mesh.name+"Shape";shape.shape=shell.create_trimesh_shape()
		shape.rotation_degrees.z=90
		body.add_child(shape)
	for end in [-1,1]:
		var lip := MeshInstance3D.new();lip.name="Lip"+("West" if end<0 else "East")
		var torus := TorusMesh.new();torus.inner_radius=PIPE_INNER-.02;torus.outer_radius=PIPE_INNER+PIPE_WALL+.02
		torus.rings=72;torus.ring_segments=8;lip.mesh=torus
		lip.material_override=glass;lip.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lip.position.x=end*length*.5;lip.rotation_degrees.z=90   # the torus lies around Y; turn it to face along X
		body.add_child(lip)

func bridge(title: String, at: Vector3, count: int) -> void:
	var node: Node3D=Bridge.instantiate()
	node.name=title;node.position=at;node.bridge_length=count;node.bridge_axis="x"
	node.pulse_speed=0.0
	add_child(node)

