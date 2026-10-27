extends RefCounted
## A physical suspension for an existing display, not a replacement interface.
## The original screen keeps its labels, data and update signals.

static func attach(display: Node3D) -> Node3D:
	if display.has_node("CeilingMount"):
		return display.get_node("CeilingMount")
	var floor_root: Node = display.get_parent()
	while floor_root != null and not floor_root.has_meta("void_content_floor"):
		floor_root = floor_root.get_parent()
	if floor_root == null:
		return null
	var index := int(floor_root.get_meta("void_content_floor"))
	var building: Node3D = floor_root.get_parent().building
	if index <= 0: # An open rooftop has no slab from which to suspend a screen.
		return null
	var underside: float = float(building.spec.levels[index - 1]) - float(building.spec.slab_thickness)
	var world_top := Vector3(display.global_position.x, building.global_position.y + underside, display.global_position.z)
	var top := display.to_local(world_top).y
	var panel := display.get_node_or_null("BackgroundPanel") as MeshInstance3D
	if panel == null or not panel.mesh is QuadMesh:
		return null
	var size: Vector2 = panel.mesh.size
	# A long one-row strip needs a separate title band above its column indices.
	if int(display.get("rows"))==1 and size.x>3.0:
		size.y+=.16
		var heading:=display.get_node_or_null("TitleLabel") as Label3D
		if heading:
			heading.position.y+=.08
			heading.font_size=48
			heading.pixel_size=.0015
	var width := size.x + 0.30
	var height := size.y + 0.22
	var yoke_y := height/2.0 + 0.15
	if top < height / 2.0 + 0.25:
		return null

	var mount := Node3D.new()
	mount.name = "CeilingMount"
	display.add_child(mount)
	var paint := material("e5e0cf", 0.82)
	var metal := material("384249", 0.55, 0.45)
	var dark := material("101c20", 0.92)
	var screws := material("9caaa8", 0.4, 0.6)

	# The opaque screen and wide left margin keep every row index on the face.
	var face := material("101c20", 0.94)
	panel.material_override = face
	var screen_mesh := QuadMesh.new()
	screen_mesh.size = Vector2(size.x + 0.14, size.y)
	panel.mesh = screen_mesh
	box(mount, "Cabinet", Vector3(0, 0, -0.15), Vector3(width, height, 0.28), paint)
	box(mount, "TopLip", Vector3(0, height/2.0, -0.025), Vector3(width + 0.04, 0.045, 0.31), metal)
	box(mount, "LowerLip", Vector3(0, -height/2.0, -0.025), Vector3(width + 0.04, 0.045, 0.31), metal)
	for side in [-1.0, 1.0]:
		box(mount, "Bezel", Vector3(side*(width/2.0 - 0.035), 0, 0.005), Vector3(0.055, height - 0.06, 0.045), paint)
		for y in [-height/2.0 + 0.055, height/2.0 - 0.055]:
			box(mount, "CaptiveScrew", Vector3(side*(width/2.0 - 0.035), y, 0.03), Vector3(0.018, 0.018, 0.009), screws)
		# Side pivots make the support legible without covering the live face.
		box(mount, "TiltPivot", Vector3(side*(width/2.0 + 0.05), 0.17, -0.15), Vector3(0.10, 0.12, 0.16), metal)
		box(mount, "YokeSide", Vector3(side*(width/2.0 + 0.085), (0.17 + yoke_y)/2.0, -0.15), Vector3(0.065, yoke_y - 0.17, 0.12), paint)
	box(mount, "YokeBridge", Vector3(0, yoke_y, -0.15), Vector3(width + 0.23, 0.08, 0.16), paint)
	box(mount, "RearCleat", Vector3(0, yoke_y, -0.22), Vector3(0.27, 0.13, 0.24), metal)

	# A slim rectangular drop mast ends in a bolted plate flush with the slab.
	var plate_y := top - 0.035
	# Long strip readouts need two suspension points, like an installed sign.
	var hangers: Array = [-width*.34,width*.34] if width>3.0 else [0.0]
	for x in hangers:
		box(mount, "DropMast", Vector3(x, (yoke_y + plate_y)/2.0, -0.22), Vector3(0.12, plate_y - yoke_y, 0.14), paint)
		box(mount, "CeilingPlate", Vector3(x, plate_y, -0.22), Vector3(0.66, 0.07, 0.40), metal)
		for bx in [-0.27,0.27]:
			for z in [-0.35,-0.09]:
				box(mount,"AnchorBolt",Vector3(x+bx,top-.078,z),Vector3(.028,.02,.028),screws)
		var hanger_contact := Marker3D.new()
		hanger_contact.name = "HangerContactLeft" if x<0 else ("HangerContactRight" if x>0 else "HangerContact")
		hanger_contact.position = Vector3(x,top,-.22)
		mount.add_child(hanger_contact)
	box(mount, "CeilingJunction", Vector3(0.17, top - 0.13, -0.22), Vector3(0.25, 0.20, 0.30), paint)
	var contact := Marker3D.new()
	contact.name = "SlabContact"
	contact.position = Vector3(0, top, -0.22)
	mount.add_child(contact)

	# Power enters at the slab junction, then follows the support to the rear
	# of the original screen. This also works on abstract floors without a ring.
	var cable_top := top - 0.13
	box(mount, "ServiceTrunk", Vector3(0.17, cable_top/2.0, -0.32), Vector3(0.045, cable_top, 0.055), metal)
	box(mount, "RearSocket", Vector3(0.17, 0, -0.30), Vector3(0.12, 0.14, 0.08), dark)
	var clips := maxi(1, ceili(cable_top / 0.7))
	for i in range(clips):
		box(mount, "TrunkClip", Vector3(0.17, 0.20 + float(i)*(cable_top - 0.3)/clips, -0.32), Vector3(0.065, 0.03, 0.075), paint)
	for i in range(7):
		box(mount, "RearVent", Vector3(-0.28 + i*0.07, -0.30, -0.295), Vector3(0.035, 0.20, 0.012), dark)
	return mount

static func material(hex: String, roughness: float, metallic := 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = Color(hex)
	result.roughness = roughness
	result.metallic = metallic
	return result

static func box(host: Node3D, title: String, at: Vector3, size: Vector3, finish: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = title
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = finish
	instance.position = at
	host.add_child(instance)
