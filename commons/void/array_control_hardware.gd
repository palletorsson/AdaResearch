extends RefCounted
## An opt-in casing for the existing hand-index apparatus.
## The artifact keeps its point, buttons, signals and one occupancy array.
const Mount := preload("res://commons/void/ceiling_display_mount.gd")
const Rack := preload("res://commons/audio/rack_templates/RackTemplates.gd")
const Ink := preload("res://commons/utils/baked_text_albedo.gd")

static func attach(source: Node3D) -> Node3D:
	if source.has_node("ArchitecturalHardware"):
		return source.get_node("ArchitecturalHardware")
	var hardware := Node3D.new()
	hardware.name="ArchitecturalHardware"
	source.add_child(hardware)
	var cream := Mount.material("e5e0cf",.84)
	var steel := Mount.material("384249",.65,.25)
	var dark := Mount.material("101c20",.9)
	# Retire the two generic block stands; nothing interactive is replaced.
	for title in ["ControlTable","WRITESELECTEDCELLStand"]:
		var old: Node3D=source.get_node(title)
		old.hide()
		for collision in old.find_children("*","CollisionObject3D",true,false):
			collision.collision_layer=0
			collision.collision_mask=0
	# The hand grid stays at its proven height and scale, recessed into a desk.
	box(hardware,"GridCabinet",Vector3(0,.74,0),Vector3(1.12,.48,1.12),cream,true)
	box(hardware,"GridTop",Vector3(0,.985,0),Vector3(1.16,.07,1.16),cream,true)
	box(hardware,"GridWell",Vector3(0,1.024,0),Vector3(.89,.008,.89),dark)
	for x in [-.45,.45]:
		box(hardware,"DeskLeg",Vector3(x,.27,-.12),Vector3(.09,.54,.70),steel,true)
		box(hardware,"FloorShoe",Vector3(x,.025,-.12),Vector3(.20,.05,.84),steel,true)
		for z in [-.48,.24]:
			box(hardware,"FloorBolt",Vector3(x,.06,z),Vector3(.025,.025,.025),dark)
	# Raise the address display above the sightline, keeping the hand grid below.
	box(hardware,"ReadoutSpine",Vector3(0,1.665,-.53),Vector3(.12,1.37,.12),steel)
	var address_mount := Node3D.new()
	address_mount.name="RaisedAddress"
	address_mount.position=Vector3(0,2.35,-.51)
	address_mount.rotation_degrees.x=10
	hardware.add_child(address_mount)
	box(address_mount,"AddressCabinet",Vector3.ZERO,Vector3(1.04,.32,.14),cream)
	box(address_mount,"AddressGlass",Vector3(0,0,.078),Vector3(.94,.23,.014),dark)
	source.address.reparent(address_mount,false)
	source.address.position=Vector3(0,0,.09)
	source.address.font_size=32
	source.address.pixel_size=.00115
	source.address.outline_size=0
	var instruction: Label3D=source.get_node("GripInstructions")
	instruction.position=Vector3(0,.83,.565)
	instruction.font_size=28
	instruction.pixel_size=.0009
	instruction.outline_size=0
	instruction.modulate=Color("30332f")
	mark(hardware,"INDEX / 7 x 7",Vector3(0,.65,.565),Vector2(.52,.07))
	# The existing sloped ControlPanel gets a floor cabinet and matching keys.
	var panel: Node3D=source.control_panel
	panel.panel_color=Color("e5e0cf")
	panel.frame_color=Color("384249")
	panel.accent_color=Color("b66d33")
	for button in [source.add_button,source.remove_button,source.restore_button]:
		Rack.make_button_rectangular(button)
		button.scale=Vector3.ONE*1.5
		button.released_color=Color("858d80") if button==source.add_button else Color("b7a786")
		button.pressed_color=Color("d98b3f")
		button.released_emission_energy=.015
		button.pressed_emission_energy=.2
		button.update_colors()
		var cap: StandardMaterial3D=button.get_node("Button/ButtonMesh").get_active_material(0)
		cap.metallic=0
		cap.roughness=.85
	# Lift the live readout above the sightline without lifting its input keys.
	# Keep the original Label (source.readout) and its data updates.
	var upper := Node3D.new()
	upper.name="RaisedReadout"
	upper.position=Vector3(1.65,2.35,-.28)
	upper.rotation_degrees.x=10
	hardware.add_child(upper)
	box(upper,"DisplayCabinet",Vector3.ZERO,Vector3(1.10,.25,.18),cream)
	box(upper,"DisplayGlass",Vector3(0,0,.098),Vector3(1.0,.16,.014),dark)
	var live_display: Node3D=panel._readout_disp
	live_display.reparent(upper,false)
	live_display.position=Vector3(0,0,.11)
	live_display.rotation=Vector3.ZERO
	live_display.scale=Vector3.ONE*1.7
	panel._readout_disp=null
	box(hardware,"DisplayBracket",Vector3(1.65,2.35,-.47),Vector3(.16,.10,.24),steel)
	# Relayout now leaves only the title and reachable keys on the lower plate.
	panel.title="WRITE / array[x,z]"
	box(hardware,"ControlPlinth",Vector3(1.65,.035,-.1),Vector3(.78,.07,.68),steel,true)
	box(hardware,"ControlCabinet",Vector3(1.65,.56,-.12),Vector3(.62,1.05,.44),cream,true)
	# Backing follows the exact tilt of the live controls.
	var cradle := Node3D.new()
	cradle.name="ControlCradle"
	cradle.position=panel.position
	cradle.rotation=panel.get_node("Tilt").rotation
	hardware.add_child(cradle)
	box(cradle,"PanelBack",Vector3(0,0,-.065),Vector3(.94,.42,.12),cream)
	for i in range(7):
		box(hardware,"Vent",Vector3(1.44+i*.07,.53,.105),Vector3(.035,.22,.012),dark)
	mark(hardware,"SHAFT B / OCCUPANCY",Vector3(1.65,.81,.107),Vector2(.54,.055))
	for x in [1.36,1.94]:
		box(hardware,"PlinthBolt",Vector3(x,.082,-.1),Vector3(.035,.025,.035),dark)
	# Rear trunk: both cabinets join a slab-mounted service junction.
	box(hardware,"DeskSupply",Vector3(.83,.9,-.55),Vector3(1.66,.065,.065),steel)
	box(hardware,"ControlSupply",Vector3(1.65,.9,-.34),Vector3(.065,.065,.45),steel)
	slab_feed(source,hardware,Vector3(1.65,.9,-.55),cream,steel)
	# Move the far floating warning onto a small rim-mounted notice.
	var notice: Label3D=source.get_node("ShaftNotice")
	notice.position=Vector3(0,.42,-6.85)
	notice.font_size=28
	notice.pixel_size=.00135
	notice.outline_size=0
	for x in [-.70,.70]:
		box(hardware,"NoticePost",Vector3(x,.23,-6.9),Vector3(.045,.46,.045),steel)
	box(hardware,"NoticePlate",Vector3(0,.42,-6.87),Vector3(1.9,.29,.035),dark)
	return hardware

static func slab_feed(source: Node3D, hardware: Node3D, port: Vector3, cream: Material, steel: Material) -> void:
	var floor_root: Node=source.get_parent()
	while floor_root!=null and not floor_root.has_meta("void_content_floor"):
		floor_root=floor_root.get_parent()
	if floor_root==null:return
	var index:=int(floor_root.get_meta("void_content_floor"))
	if index<=0:return
	var building: Node3D=floor_root.get_parent().building
	var top_world: Vector3=source.to_global(port)
	top_world.y=building.global_position.y+float(building.spec.levels[index-1])-float(building.spec.slab_thickness)
	var top:=source.to_local(top_world)
	if top.y<=port.y:return
	box(hardware,"ServiceTrunk",(top+port)/2,Vector3(.075,top.y-port.y,.075),steel)
	box(hardware,"SlabJunction",top-Vector3.UP*.10,Vector3(.34,.20,.30),cream)
	box(hardware,"CeilingPlate",top-Vector3.UP*.02,Vector3(.54,.04,.42),steel)
	for x in [-.22,.22]:
		for z in [-.16,.16]:
			box(hardware,"CeilingBolt",top+Vector3(x,-.052,z),Vector3(.025,.025,.025),cream)
	var clips:=maxi(1,ceili((top.y-port.y)/.7))
	for i in clips:
		box(hardware,"ServiceClip",port.lerp(top,(i+.5)/clips),Vector3(.105,.04,.105),cream)
	var contact:=Marker3D.new()
	contact.name="SlabContact"
	contact.position=top
	hardware.add_child(contact)

static func box(host: Node3D, title: String, at: Vector3, size: Vector3, finish: Material, solid:=false) -> void:
	Mount.box(host,title,at,size,finish)
	if not solid:return
	var body:=StaticBody3D.new()
	body.name=title+"Body"
	body.position=at
	var shape:=BoxShape3D.new()
	shape.size=size
	var collision:=CollisionShape3D.new()
	collision.shape=shape
	host.add_child(body)
	body.add_child(collision)

static func mark(host: Node3D, words: String, at: Vector3, size: Vector2) -> void:
	var node:=MeshInstance3D.new()
	node.name="PrintedLegend"
	var quad:=QuadMesh.new()
	quad.size=size
	node.mesh=quad
	node.position=at
	var finish:=Mount.material("ffffff",1.0)
	finish.albedo_texture=Ink.generate_text_image(words,Color("30332f"),Vector2i(1024,128),64,"medium")
	finish.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	node.material_override=finish
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host.add_child(node)
