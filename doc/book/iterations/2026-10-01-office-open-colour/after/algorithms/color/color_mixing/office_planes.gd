extends RefCounted
## Open partition score for Color_Walls. The enclosing museum is supplied.
## One QuadMesh per pane: the tint is applied once, from either side.
## Its thin box collider stays present in both filter and opaque modes.

const PANES := [
	# x, z, yaw, width, height, colour; gaps are part of the score.
	[-2.65,-4.70,90.0,3.6,3.55,"39e7ee"],
	[2.80,-4.40,90.0,4.0,3.55,"ffe82f"],
	[-2.10,-1.90,0.0,4.8,3.10,"f431ba"],
	[2.10,0.50,0.0,4.8,3.30,"5075f5"],
	[-3.20,2.00,90.0,4.0,3.50,"67e9ec"],
	[-2.00,3.10,0.0,4.6,3.00,"fae54a"],
	[2.80,2.70,90.0,3.6,3.50,"54df70"],
	[-2.20,5.80,15.0,3.0,3.20,"ef66c0"],
	[-4.05,-5.20,-15.0,1.6,2.85,"fc805d"],
	[4.00,-5.10,15.0,1.6,2.85,"6987f4"],
	[2.20,5.95,0.0,3.8,3.45,"78dee6"],
	[-4.10,3.90,32.0,1.4,2.75,"fbb268"],
]

static func build(office: Node3D) -> void:
	office.office_panes.clear()
	office.glass_visible = true
	office._office_box(office,"QuietFloor",Vector3(0,0.009,-0.1),Vector3(9.8,0.018,13.4),Color("e3ded4"),false)
	# A pale setting keeps furniture legible through layered colour. The dark
	# museum sky alone supplies little detail. Wings stay open at the entrance,
	# rear and two side passages; they never make individual coloured cells.
	for side in [-1.0,1.0]:
		office._office_box(office,"PaleWing",Vector3(side*5.2,2.05,-2.2),Vector3(0.10,4.1,9.2),Color("f1eee7"))
		office._office_box(office,"RearWing",Vector3(side*5.2,2.05,6.1),Vector3(0.10,4.1,3.0),Color("f1eee7"))
		office._office_box(office,"PaleBack",Vector3(side*3.15-0.2,2.05,7.5),Vector3(4.2,4.1,0.10),Color("f1eee7"))
		# Two overhead strips leave a central opening to the museum sky.
		office._office_box(office,"Canopy",Vector3(side*3.0,4.15,0.3),Vector3(4.4,0.08,14.4),Color("eeeae4"),false)
	for background in office.get_children():
		if background is MeshInstance3D:
			# Neutral display backing, independent of the dark museum sky.
			background.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			background.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in PANES.size():
		add_pane(office,PANES[i],i)
	workstation(office,Vector3(-3.85,0,-3.55),90,0)
	workstation(office,Vector3(3.95,0,1.7),-90,1)
	workstation(office,Vector3(-3.5,0,5.0),0,2)
	office.set_meta("em_visibility_bounds",AABB(Vector3(-5.5,0,-8.5),Vector3(11,4.3,16.2)))
	if str(office.get_meta("config_compare",""))=="visibility":
		var controls: Node3D = load("res://commons/ui/control_panel.gd").new()
		controls.name = "VisibilityConsole"
		controls.title = "A VIEW / A WAY THROUGH"
		controls.position = Vector3(-3.8,1.1,-7.55)
		controls.rotation_degrees.y = 180
		office.add_child(controls)
		office.glass_button = controls.add_button("FILTER / OPAQUE")
		office.glass_button.pressed.connect(office.toggle_office_glass)
		office.glass_readout = controls.add_readout("FILTER / SAME PASSAGES")
		office._office_box(office,"VisibilityPlinth",Vector3(-3.8,0.45,-7.55),Vector3(0.8,0.9,0.6),Color("dcd8d1"))

static func add_pane(office: Node3D, spec: Array, index: int) -> void:
	var width: float = spec[3]
	var height: float = spec[4]
	var colour := Color(str(spec[5]))
	var pane := MeshInstance3D.new()
	pane.name = "FilterPane_%02d" % index
	var mesh := QuadMesh.new()
	mesh.size = Vector2(width,height)
	pane.mesh = mesh
	pane.position = Vector3(spec[0],height*0.5+0.025,spec[1])
	pane.rotation_degrees.y = spec[2]
	var surface := StandardMaterial3D.new()
	surface.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	surface.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# The background already receives the museum fog; keep each tint clear.
	surface.disable_fog = true
	surface.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.albedo_color = colour
	surface.albedo_color.a = 0.52
	surface.roughness = 0.18
	pane.material_override = surface
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var body := StaticBody3D.new()
	body.name = "PaneBody"
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width,height,0.035)
	collision.shape = shape
	body.add_child(collision)
	pane.add_child(body)
	office.add_child(pane)
	office.office_panes.append(pane)
	# Fine edges make a transparent obstacle visible without outlining a cube.
	var edge_colour := colour.lightened(0.48)
	for x in [-width*0.5,width*0.5]:
		office._office_box(pane,"GlassEdge",Vector3(x,0,0),Vector3(0.018,height,0.024),edge_colour,false)
		office._office_box(pane,"Foot",Vector3(x,-height*0.5+0.04,0),Vector3(0.13,0.08,0.32),Color("b5b6b6"),false)
	# No top rail, no closing return, no suspended label across the view.

static func workstation(office: Node3D, at: Vector3, yaw: float, index: int) -> void:
	var station := Node3D.new()
	station.name = "Workstation_%d" % index
	office.add_child(station)
	station.position = at
	station.rotation_degrees.y = yaw
	office._office_box(station,"DeskTop",Vector3(0,0.74,0.65),Vector3(1.25,0.045,0.62),Color("d4b998"))
	for x in [-0.52,0.52]:
		office._office_box(station,"DeskLeg",Vector3(x,0.35,0.65),Vector3(0.03,0.7,0.45),Color("a2a3a1"))
	office._office_box(station,"Monitor",Vector3(0,1.01,0.78),Vector3(0.50,0.30,0.025),Color("383a40"))
	office._office_box(station,"MonitorFoot",Vector3(0,0.79,0.78),Vector3(0.12,0.08,0.16),Color("96999b"),false)
	office._office_box(station,"Seat",Vector3(0,0.45,-0.12),Vector3(0.47,0.045,0.45),Color("e4dfd3"))
	office._office_box(station,"Back",Vector3(0,0.70,-0.34),Vector3(0.47,0.50,0.04),Color("e4dfd3"))
	for x in [-0.19,0.19]:
		for z in [-0.28,0.04]:
			office._office_box(station,"ChairLeg",Vector3(x,0.22,z),Vector3(0.025,0.44,0.025),Color("96999b"),false)
