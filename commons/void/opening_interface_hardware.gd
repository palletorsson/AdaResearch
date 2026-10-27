extends RefCounted
## Retrofit the original instruments in the opening floors.
## Their labels, signals, feed channels and collision remain owned by the source.
const Mount := preload("res://commons/void/ceiling_display_mount.gd")
const Supply := preload("res://commons/void/hardware_supply.gd")

static func attach(source: Node3D, kind: String) -> Node3D:
	if source.has_node("ArchitecturalHardware"):
		return source.get_node("ArchitecturalHardware")
	if kind not in ["frame_counter_display", "coordinate_readout"]:
		return null
	var floor_root: Node = source.get_parent()
	while floor_root != null and not floor_root.has_meta("void_content_floor"):
		floor_root = floor_root.get_parent()
	if floor_root == null:
		return null
	var hardware := Node3D.new()
	hardware.name = "ArchitecturalHardware"
	source.add_child(hardware)
	# The counter is enlarged 3.5 times. Its bolts and conduit still use metres.
	hardware.scale = Vector3.ONE / source.global_basis.get_scale()
	var cream := Mount.material("e5e0cf", .84)
	var steel := Mount.material("384249", .65, .25)
	var dark := Mount.material("30332f", .85)
	var scale: Vector3 = source.global_basis.get_scale()
	if kind == "frame_counter_display":
		source.get_node("Console/Casing").material_override = cream
		var width: float = source.W * scale.x
		var height: float = source.H * scale.y
		var depth: float = source.D * scale.z
		var bottom := hardware.to_local(Vector3(source.global_position.x, floor_root.global_position.y, source.global_position.z)).y
		var rear := -depth - .08
		for side in [-1.0, 1.0]:
			var x: float = side * width * .34
			Mount.box(hardware, "RearRail", Vector3(x, 0, rear), Vector3(.12, height * .9, .16), steel)
			Mount.box(hardware, "FloorUpright", Vector3(x, bottom/2, rear), Vector3(.12, -bottom, .16), cream)
			Mount.box(hardware, "FloorShoe", Vector3(x, bottom+.035, rear), Vector3(.48,.07,.60), steel)
			for dx in [-.17,.17]:
				for dz in [-.22,.22]:
					Mount.box(hardware, "AnchorBolt", Vector3(x+dx,bottom+.082,rear+dz), Vector3(.035,.025,.035), dark)
			var foot := Marker3D.new()
			foot.name = "FloorContactLeft" if side < 0 else "FloorContactRight"
			foot.position = Vector3(x,bottom,rear)
			hardware.add_child(foot)
		Supply.connect_unit(hardware, Vector3(width*.34,height*.35,rear-.11))
	else:
		var ds: float = source.display_scale
		var width: float = source.frame_width * ds * scale.x
		var height: float = source.frame_height * ds * scale.y
		source._label.outline_size = 0
		source._caption.outline_size = 0
		# Keep the white measuring card and original world/local caption.
		# The deeper cream cabinet and dark perimeter make it an instrument.
		Mount.box(hardware, "ReadoutCabinet", Vector3(0,0,-.16), Vector3(width+.14,height+.14,.24), cream)
		for x in [-width/2-.035,width/2+.035]:
			for y in [-height/2-.035,height/2+.035]:
				Mount.box(hardware,"CaptiveScrew",Vector3(x,y,-.032),Vector3(.025,.025,.012),steel)
		var index := int(floor_root.get_meta("void_content_floor"))
		var building: Node3D = floor_root.get_parent().building
		if index > 0:
			var underside: float = building.global_position.y + float(building.spec.levels[index-1]) - float(building.spec.slab_thickness)
			var top: float = hardware.to_local(Vector3(hardware.global_position.x,underside,hardware.global_position.z)).y
			var yoke: float = height/2 + .18
			if top > yoke + .08:
				for side in [-1.0,1.0]:
					var x: float = side*(width/2+.09)
					Mount.box(hardware,"TiltPivot",Vector3(x,0,-.15),Vector3(.12,.12,.16),steel)
					Mount.box(hardware,"YokeSide",Vector3(x,yoke/2,-.15),Vector3(.07,yoke,.12),cream)
				Mount.box(hardware,"YokeBridge",Vector3(0,yoke,-.15),Vector3(width+.25,.08,.16),cream)
				Mount.box(hardware,"DropMast",Vector3(0,(yoke+top-.035)/2,-.15),Vector3(.12,top-.035-yoke,.14),cream)
				Mount.box(hardware,"CeilingPlate",Vector3(0,top-.035,-.15),Vector3(.62,.07,.46),steel)
				for x in [-.25,.25]:
					for z in [-.31,.01]:
						Mount.box(hardware,"AnchorBolt",Vector3(x,top-.08,z),Vector3(.03,.025,.03),dark)
				var contact := Marker3D.new()
				contact.name = "SlabContact"
				contact.position = Vector3(0,top,-.15)
				hardware.add_child(contact)
		Supply.connect_unit(hardware, Vector3(width*.35,height/2,-.31))
	return hardware
