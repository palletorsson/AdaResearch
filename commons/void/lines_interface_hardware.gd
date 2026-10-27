extends RefCounted
## Void-only adapters: original measurements, pickup bodies and signal owners
## remain in charge. Hardware belongs to the existing editable part.
const Mount := preload("res://commons/void/ceiling_display_mount.gd")
const Supply := preload("res://commons/void/hardware_supply.gd")
const Print := preload("res://commons/void/array_control_hardware.gd")

static func attach(source: Node3D, kind: String) -> void:
	if _floor(source) == null:
		return
	if source.has_node("ArchitecturalHardware"):
		_connect(source.get_node("ArchitecturalHardware"))
		return
	match kind:
		"gate":
			var h := _root(source)
			var face := _cabinet(h, Vector3(1.85,1.9,-3.135), Vector2(1.48,.46))
			_label(source.readout, face, .0018)
			Print.mark(face,"01 / JOIN THE POINTS",Vector3(0,.15,.012),Vector2(1.20,.055))
			h.set_meta("support","wall")
			# Back plate contacts the original north panel's inner surface.
			Mount.box(h,"WallPlate",Vector3(1.85,1.9,-3.27),Vector3(1.58,.55,.02),_steel())
			h.set_meta("port",Vector3(1.85,2.2,-3.22))
			var contact := Marker3D.new()
			contact.name="WallContact"
			contact.position=Vector3(1.85,1.9,-3.28)
			h.add_child(contact)
			_connect(h)
		"survey":
			var h := _root(source)
			var z := -1.50 if source.plan else -.55
			var face := _cabinet(h,Vector3(0,2.35,z),Vector2(1.40,.40))
			face.rotation_degrees.x=10
			source.mounted_readout=true
			_label(source.readout,face,.0018)
			Print.mark(face,"02 / FLOOR PLAN / 1:10" if source.plan else "SPACE RULER / 1:1",
				Vector3(0,.125,.012),Vector2(1.18,.045))
			# Retain the instructions, but print them onto the actual instrument.
			var title: Label3D=source.get_node_or_null("SurveyTitle")
			if title != null: title.hide()
			var caption: Label3D=source.get_node_or_null("SurveyInstructions")
			if caption != null:
				caption.reparent(face,false)
				caption.position=Vector3(0,-.13,.014)
				caption.rotation=Vector3.ZERO
				caption.font_size=28
				caption.pixel_size=.00085
				caption.outline_size=0
			h.set_meta("port",Vector3(0,2.48,z-.14))
			_connect(h)
		"charge":
			var h := _root(source)
			# The status label itself remains an editor part and signal recipient.
			source.billboard=BaseMaterial3D.BILLBOARD_DISABLED
			source.font_size=32
			source.pixel_size=.0017
			source.modulate=Color("e5f1e8")
			source.outline_size=0
			var face := _cabinet(h,Vector3(0,0,-.014),Vector2(1.12,.35))
			Print.mark(face,"04 / CHARGE",Vector3(0,.115,.012),Vector2(.86,.045))
			h.set_meta("port",Vector3(0,.13,-.16))
			_connect(h)
		"line_black_box":
			var h := _root(source)
			var face := _cabinet(h,Vector3(0,1.83,1.895),Vector2(1.10,.35),PI)
			_label(source.readout,face,.0018)
			h.set_meta("support","wall")
			h.set_meta("port",Vector3(0,2.08,1.9))
			# Keep the actual rectangular reset key and its exact pointer volume.
			var cap: MeshInstance3D=source.get_node("ResetCap")
			cap.material_override=Mount.material("a9ad9b",.85)
			Mount.box(h,"ResetCabinet",Vector3(1.4,1.15,1.935),Vector3(.29,.28,.045),_cream())
			Mount.box(h,"ReadoutWallPlate",Vector3(0,1.83,1.92),Vector3(1.2,.43,.02),_steel())
			_connect(h)
		"two_point_ruler":
			var h := _root(source)
			var display: Node3D=source._readout
			var w: float=display.width_m
			Mount.box(h,"ReadoutCabinet",display.position+Vector3(0,0,-.08),
				Vector3(w+.12,w*.62+.12,.14),_cream())
			h.set_meta("support","floor")
			h.set_meta("port",display.position+Vector3(0,0,-.19))
			_connect(h)
		"sketch_monitor":
			var h := _root(source)
			# Lift the original viewport and chassis together to reading height.
			for child in source.get_children():
				if child is MeshInstance3D and not child.is_queued_for_deletion():
					child.position.y+=1.15
					if child != source._screen: child.material_override=_cream()
			var screen: MeshInstance3D=source._screen
			Mount.box(h,"MonitorBack",screen.position+Vector3(0,0,-.11),
				Vector3(source.screen_w_m*1.12,screen.mesh.size.y*1.14,.14),_cream())
			h.set_meta("support","floor")
			h.set_meta("port",screen.position+Vector3(0,0,-.22))
			_connect(h)
		"science_screen":
			var h := _root(source)
			# This apparatus already has a grounded stand and a live viewport.
			# Add a service back and feed, without rebuilding its tracking surface.
			var screen: MeshInstance3D=source._screen_mesh
			var at: Vector3=source.to_local(screen.global_position)
			Mount.box(h,"ServiceBack",at+Vector3(0,0,-.14),
				Vector3(source.screen_width+.20,source.screen_height+.20,.18),_cream())
			h.set_meta("support","existing")
			h.set_meta("port",at+Vector3(0,source.screen_height*.5+.15,-.24))
			_connect(h)
		"line_space_workshop":
			var h := _root(source)
			for study in source.studies:
				var casing: Node3D=study.get_node("MonitorCasing")
				for mesh in casing.get_children():
					if mesh is MeshInstance3D and mesh != study.screen:
						mesh.material_override=_cream()
				var x: float=source.bay_x(study.bay)
				Mount.box(h,"MonitorPost",Vector3(x,.56,.53),Vector3(.09,1.12,.09),_steel())
				Mount.box(h,"FloorShoe",Vector3(x,.02,.53),Vector3(.44,.04,.40),_steel())
			Mount.box(h,"SharedServiceRail",Vector3(0,.27,.53),Vector3(3.05,.11,.11),_cream())
			h.set_meta("support","existing")
			h.set_meta("port",Vector3(1.425,.27,.53))
			_connect(h)

static func _root(source: Node3D) -> Node3D:
	var h := Node3D.new()
	h.name="ArchitecturalHardware"
	source.add_child(h)
	source.set_meta("mounted_interface",true)
	return h

static func _cabinet(h: Node3D, at: Vector3, size: Vector2, yaw := 0.0) -> Node3D:
	var face := Node3D.new()
	face.name="InstrumentFace"
	face.position=at
	face.rotation.y=yaw
	h.add_child(face)
	Mount.box(face,"Cabinet",Vector3(0,0,-.065),Vector3(size.x,size.y,.13),_cream())
	Mount.box(face,"Glass",Vector3(0,0,.004),Vector3(size.x-.10,size.y-.08,.008),Mount.material("152328",.92))
	Mount.box(face,"LegendStrip",Vector3(0,size.y/2-.07,.009),Vector3(size.x-.10,.07,.006),_cream())
	for x in [-size.x/2+.025,size.x/2-.025]:
		for y in [-size.y/2+.025,size.y/2-.025]:
			Mount.box(face,"CaptiveScrew",Vector3(x,y,.007),Vector3(.015,.015,.006),_steel())
	return face

static func _label(label: Label3D, face: Node3D, pixels: float) -> void:
	label.reparent(face,false)
	label.position=Vector3(0,-.015,.014)
	label.rotation=Vector3.ZERO
	label.billboard=BaseMaterial3D.BILLBOARD_DISABLED
	label.font_size=32
	label.pixel_size=pixels
	label.outline_size=0
	label.modulate=Color("e5f1e8")

static func _floor(node: Node) -> Node3D:
	while node != null and not node.has_meta("void_content_floor"):
		node=node.get_parent()
	return node as Node3D

static func _connect(h: Node3D) -> void:
	# Recompute on an editor move/rotation; never delete the original labels.
	for key in ["StructuralSupport","HardwareSupply"]:
		var old: Node=h.get_node_or_null(key)
		if old != null: old.free()
	var floor_root := _floor(h)
	if floor_root == null: return
	var port: Vector3=h.get_meta("port")
	var support := Node3D.new()
	support.name="StructuralSupport"
	h.add_child(support)
	var mode: String=h.get_meta("support","ceiling")
	var level := int(floor_root.get_meta("void_content_floor"))
	if mode=="ceiling" and level==0: mode="floor"
	if mode in ["ceiling","floor"]:
		var building: Node3D=floor_root.get_parent().building
		var end_y: float=floor_root.global_position.y
		if mode == "ceiling":
			end_y=building.global_position.y+float(building.spec.levels[level-1])-float(building.spec.slab_thickness)
		var start: Vector3=h.to_global(port)
		var end := Vector3(start.x,end_y,start.z)
		# Work in world axes, so quarter-turn and arbitrary editor yaw work.
		support.global_basis=Basis.IDENTITY
		var a := support.to_local(start)
		var b := support.to_local(end)
		Mount.box(support,"ConnectionBlock",a,Vector3(.20,.14,.20),_steel())
		Mount.box(support,"Mast",(a+b)/2,Vector3(.10,absf(a.y-b.y),.12),_cream())
		var sign_y := -1.0 if mode == "ceiling" else 1.0
		Mount.box(support,"AnchorPlate",b+Vector3(0,.025*sign_y,0),Vector3(.48,.05,.38),_steel())
		for dx in [-.18,.18]:
			for dz in [-.13,.13]:
				Mount.box(support,"AnchorBolt",b+Vector3(dx,.06*sign_y,dz),Vector3(.025,.025,.025),_steel())
		var contact := Marker3D.new()
		contact.name="SlabContact" if mode=="ceiling" else "FloorContact"
		contact.position=b
		support.add_child(contact)
	Supply.connect_unit(h,port)

static func _cream() -> StandardMaterial3D:
	return Mount.material("e5e0cf",.84)

static func _steel() -> StandardMaterial3D:
	return Mount.material("384249",.65,.25)
