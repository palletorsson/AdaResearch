extends RefCounted
## A shared ceiling carrier for the Random Definition instruments.
##
## The museum artifact remains the signal owner and keeps every button, pickup,
## animation and label.  This adapter only lifts the complete instrument clear
## of the slab, gives it one restrained service face and connects it to the
## tower's ceiling structure and electrical bus.

const Mount := preload("res://commons/void/ceiling_display_mount.gd")
const Supply := preload("res://commons/void/hardware_supply.gd")
const Ink := preload("res://commons/utils/baked_text_albedo.gd")
const Rack := preload("res://commons/audio/rack_templates/RackTemplates.gd")

static func attach_later(source: Node3D, specification: Dictionary) -> void:
	# A number of imported instruments build their real controls in _ready().
	# Measure and fit that finished apparatus rather than its empty scene root.
	await source.get_tree().physics_frame
	await source.get_tree().physics_frame
	if is_instance_valid(source) and source.is_inside_tree():
		attach(source, specification)

static func attach(source: Node3D, specification: Dictionary) -> Node3D:
	if source.has_node("ArchitecturalHardware"):
		return source.get_node("ArchitecturalHardware")
	var floor_root := _floor(source)
	if floor_root == null:
		return null
	var kind := str(source.get_meta("artifact_lookup_name", ""))
	_prepare(source, kind)
	var measured := source
	var shaft_ride := kind == "void_random_return" and bool(source.get("shaft_route"))
	if shaft_ride:
		measured = source.own_panel

	# Lift only upward.  Existing authored elevations remain meaningful, while
	# floor-standing feet acquire a visible shadow gap and read as suspended.
	var clearance := float(specification.get("clearance", 0.28))
	var before := _world_bounds(source)
	if before.size != Vector3.ZERO and not shaft_ride and not source.has_meta("independent_instrument"):
		var wanted_y: float = floor_root.global_position.y + clearance
		if before.position.y < wanted_y:
			source.global_position.y += wanted_y - before.position.y

	var hardware := Node3D.new()
	hardware.name = "ArchitecturalHardware"
	source.add_child(hardware)
	# Cabinet dimensions remain real metres even on the enlarged crank machine.
	var inherited_scale := source.global_basis.get_scale()
	hardware.scale = Vector3(
		1.0 / maxf(inherited_scale.x, 0.001),
		1.0 / maxf(inherited_scale.y, 0.001),
		1.0 / maxf(inherited_scale.z, 0.001)
	)
	source.set_meta("mounted_interface", true)
	source.set_meta("ceiling_interface_style", "restrained_instrument")
	source.set_meta("ceiling_interface_clearance", clearance)

	var bounds := _local_bounds(measured, hardware)
	if bounds.size == Vector3.ZERO:
		bounds = AABB(Vector3(-0.45, 0.0, -0.20), Vector3(0.90, 1.20, 0.40))
	var centre := bounds.get_center()
	var width := clampf(bounds.size.x + 0.18, 0.90, 4.20)
	var depth := clampf(bounds.size.z + 0.12, 0.24, 1.20)
	var bottom := bounds.position.y
	var object_top := bounds.end.y
	var front := bounds.end.z + 0.055
	var rear := bounds.position.z - 0.075

	var warm_white := Mount.material("e8e4d8", 0.92)
	var graphite := Mount.material("343b3d", 0.82, 0.12)
	var black := Mount.material("15191a", 0.96)
	var signal_finish := Mount.material(str(specification.get("accent", "d86e32")).trim_prefix("#"), 0.86)
	# Casing surrounds, rather than paints over, the working readouts and glass.
	# It leaves the original buttons and their collision shapes untouched.
	if kind in ["void_random_seed", "lava_entropy_wall", "geiger_counter", "movement_sampler"]:
		for side in [-1.0, 1.0]:
			Mount.box(hardware, "IvorySide", Vector3(centre.x + side * (bounds.size.x * .5 + .035), centre.y, rear + .04), Vector3(.10, bounds.size.y + .12, .20), warm_white)
		Mount.box(hardware,"IvoryLowerLip",Vector3(centre.x,bottom-.04,rear+.04),Vector3(bounds.size.x+.16,.08,.20),warm_white)

	# One legible top cassette replaces decorative plinth language.  The original
	# controls stay exposed below it; the new face states action before ornament.
	var cassette_y := object_top + 0.16
	Mount.box(hardware, "InstrumentCassette", Vector3(centre.x, cassette_y, front), Vector3(width, 0.36, 0.15), warm_white)
	Mount.box(hardware, "InstrumentGlass", Vector3(centre.x, cassette_y - 0.015, front + 0.081), Vector3(width - 0.10, 0.27, 0.012), black)
	Mount.box(hardware, "SignalKey", Vector3(centre.x + width * 0.5 - 0.085, cassette_y + 0.092, front + 0.089), Vector3(0.075, 0.035, 0.014), signal_finish)
	for side in [-1.0, 1.0]:
		Mount.box(hardware, "CaptiveScrew", Vector3(centre.x + side * (width * 0.5 - 0.035), cassette_y + 0.09, front + 0.09), Vector3(0.018, 0.018, 0.010), graphite)
	_mark(hardware, "InterfaceTitle", str(specification.get("title", "RANDOM / INSTRUMENT")), Vector3(centre.x - 0.03, cassette_y + 0.045, front + 0.091), Vector2(width - 0.22, 0.13), Color("edf1eb"))
	_mark(hardware, "InterfaceAction", str(specification.get("action", "TOUCH · OBSERVE · REPLAY")), Vector3(centre.x - 0.03, cassette_y - 0.075, front + 0.091), Vector2(width - 0.22, 0.09), Color("b9c5bf"))

	# Two slim rails make the thing read as one installed apparatus without
	# enclosing its distinct geometry or covering any interaction volume.
	var rail_height := maxf(bounds.size.y, 0.55)
	for side in [-1.0, 1.0]:
		var rail_x: float = centre.x + float(side) * minf(width * 0.5 - 0.055, bounds.size.x * 0.5 + 0.045)
		Mount.box(hardware, "CarrierRail", Vector3(rail_x, bottom + rail_height * 0.5, rear), Vector3(0.065, rail_height, 0.075), graphite)
		Mount.box(hardware, "UpperCleat", Vector3(rail_x, object_top + 0.035, centre.z), Vector3(0.13, 0.07, depth), warm_white)
	Mount.box(hardware, "RearService", Vector3(centre.x, cassette_y, rear - 0.04), Vector3(minf(width * 0.62, 1.40), 0.17, 0.12), graphite)
	for i in range(7):
		Mount.box(hardware, "ServiceVent", Vector3(centre.x - 0.24 + i * 0.08, cassette_y, rear - 0.105), Vector3(0.035, 0.09, 0.010), black)

	# Structural yoke reaches the actual underside of the slab above.  The service
	# trunk stops at the established 4.8 m bus and then runs to its quadrant socket.
	var slab_y := _slab_y(floor_root)
	var slab_local := hardware.to_local(Vector3(hardware.global_position.x, slab_y, hardware.global_position.z)).y
	var yoke_y := cassette_y + 0.23
	Mount.box(hardware, "YokeBridge", Vector3(centre.x, yoke_y, rear), Vector3(width + 0.14, 0.08, 0.14), warm_white)
	if str(specification.get("style", "")) == "pillar_instrument":
		_pillar(hardware, floor_root, bounds, rear, warm_white, graphite)
	elif slab_local > yoke_y + 0.10:
		var two_hangers := width > 2.40
		var hanger_xs: Array = [centre.x - width * 0.30, centre.x + width * 0.30] if two_hangers else [centre.x]
		for hanger_x in hanger_xs:
			var hanger_x_m := float(hanger_x)
			Mount.box(hardware, "DropMast", Vector3(hanger_x_m, (yoke_y + slab_local - 0.035) * 0.5, rear), Vector3(0.10, slab_local - 0.035 - yoke_y, 0.12), warm_white)
			Mount.box(hardware, "CeilingAnchorPlate", Vector3(hanger_x_m, slab_local - 0.035, rear), Vector3(0.52, 0.07, 0.38), graphite)
			for dx in [-0.19, 0.19]:
				for dz in [-0.13, 0.13]:
					Mount.box(hardware, "CeilingAnchorBolt", Vector3(hanger_x_m + float(dx), slab_local - 0.078, rear + float(dz)), Vector3(0.024, 0.020, 0.024), warm_white)
		var contact := Marker3D.new()
		contact.name = "SlabContact"
		contact.position = Vector3(centre.x, slab_local, rear)
		hardware.add_child(contact)
	Supply.connect_unit(hardware, Vector3(centre.x, cassette_y + 0.08, rear - 0.12))
	# Frozen pickups otherwise retain their old physics pose after their parent lifts.
	for body in source.find_children("*", "RigidBody3D", true, false):
		if body.freeze:
			body.force_update_transform()
			PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
	if kind == "void_random_seed" and is_instance_valid(source._movement_sampler):
		attach(source._movement_sampler, {"title":"BODY / SEED", "action":"HOLD · MOVE · RELEASE", "style":"ceiling_instrument"})
	return hardware

static func _prepare(source: Node3D, kind: String) -> void:
	if kind == "prng_crank_machine":
		_remove(source.get_node_or_null("Plinth"))
	if kind == "slot_machine":
		var assembly := source.get_node_or_null("Assembly")
		if assembly:
			for child in assembly.get_children():
				if child.name == "Pedestal" or (child is MeshInstance3D and child.position.y < float(source.pedestal_height)):
					_remove(child)
	if kind == "void_random_seed" and is_instance_valid(source._movement_sampler):
		var sampler: Node3D = source._movement_sampler
		sampler.set_meta("independent_instrument", true)
		sampler.set_meta("artifact_lookup_name", "movement_sampler")
		# Replace the floor post with a small shelf attached to the rear case.
		for child in sampler.get_children():
			if child is StaticBody3D and child.position.y < 1.0: _remove(child)
			elif child is MeshInstance3D and child.mesh is BoxMesh and child.mesh.size.is_equal_approx(Vector3(.3,.96,.3)): _remove(child)
		if not sampler.has_node("PointDock"):
			Mount.box(sampler,"PointDock",Vector3(0,.97,.21),Vector3(.32,.045,.48),Mount.material("e8e4d8",.9))
	# Refinish structural trim only. Coloured samples, status lights and their
	# material references remain owned by the source simulation.
	var cream := Mount.material("e8e4d8",.88)
	for mesh in source.find_children("*","MeshInstance3D",true,false):
		if not mesh.mesh is BoxMesh: continue
		var size: Vector3=mesh.mesh.size
		var replace := kind == "geiger_counter" and size.y>3.0 and size.x<.10
		if kind == "lava_entropy_wall": replace = (size.y>3.35 and size.x<.15) or (size.x>3.6 and size.y<.06)
		if kind == "void_random_seed" and mesh.get_parent().name=="SeedCabinet":
			replace = size.x<.08 or (size.y<.11 and size.x>2.8)
		if replace: mesh.material_override=cream
	for button in source.find_children("*", "Node3D", true, false):
		if button.has_node("Button/ButtonMesh") and button.has_node("InteractableAreaButton"):
			Rack.make_button_rectangular(button)

static func _remove(node: Node) -> void:
	if node == null: return
	node.get_parent().remove_child(node)
	node.queue_free()

static func _pillar(host: Node3D, floor_root: Node3D, bounds: AABB, rear: float, cream: Material, graphite: Material) -> void:
	var building: Node3D = floor_root.get_parent().building
	var world := host.global_position
	var xs: Array = building.spec.column_x
	var zs: Array = building.spec.column_z
	var px: float = xs[0]
	var pz: float = zs[0]
	for x in xs:
		if absf(float(x)-world.x)<absf(px-world.x): px=float(x)
	for z in zs:
		if absf(float(z)-world.z)<absf(pz-world.z): pz=float(z)
	var face := Vector3(px,world.y,pz-signf(pz)*float(building.spec.column_width)*.5)
	var contact := host.to_local(face)
	var centre := bounds.get_center()
	Mount.box(host,"PillarBackplate",Vector3(contact.x,centre.y,contact.z+.035),Vector3(.62,bounds.size.y+.20,.07),graphite)
	for dy in [-1.0,1.0]:
		var y: float=centre.y+dy*bounds.size.y*.35
		Mount.box(host,"WallArm",Vector3(centre.x,y,(rear+contact.z)*.5),Vector3(.20,.07,maxf(.07,absf(rear-contact.z))),cream)
		for dx in [-.24,.24]:
			Mount.box(host,"PillarBolt",Vector3(contact.x+dx,y,contact.z+.08),Vector3(.026,.026,.025),cream)
	var mark:=Marker3D.new(); mark.name="PillarContact"
	mark.position=Vector3(contact.x,centre.y,contact.z);host.add_child(mark)

static func _floor(node: Node) -> Node3D:
	while node != null and not node.has_meta("void_content_floor"):
		node = node.get_parent()
	return node as Node3D

static func _slab_y(floor_root: Node3D) -> float:
	var index := int(floor_root.get_meta("void_content_floor"))
	var building: Node3D = floor_root.get_parent().building
	if index <= 0:
		return floor_root.global_position.y + float(building.spec.storey_height)
	return building.global_position.y + float(building.spec.levels[index - 1]) - float(building.spec.slab_thickness)

static func _world_bounds(source: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for node in source.find_children("*", "GeometryInstance3D", true, false):
		if _inside_private_viewport(node, source) or _independent(node, source):
			continue
		var mesh_bounds := _geometry_bounds(node)
		if mesh_bounds.size == Vector3.ZERO:
			continue
		mesh_bounds = node.global_transform * mesh_bounds
		result = mesh_bounds if first else result.merge(mesh_bounds)
		first = false
	return result

static func _local_bounds(source: Node3D, hardware: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var inverse := hardware.global_transform.affine_inverse()
	for node in source.find_children("*", "GeometryInstance3D", true, false):
		if node == hardware or hardware.is_ancestor_of(node) or _inside_private_viewport(node, source) or _independent(node, source):
			continue
		var mesh_bounds := _geometry_bounds(node)
		if mesh_bounds.size == Vector3.ZERO:
			continue
		mesh_bounds = (inverse * node.global_transform) * mesh_bounds
		result = mesh_bounds if first else result.merge(mesh_bounds)
		first = false
	return result

static func _geometry_bounds(node: GeometryInstance3D) -> AABB:
	if node is MeshInstance3D and node.mesh != null:
		return node.mesh.get_aabb()
	if node is MultiMeshInstance3D and node.multimesh != null:
		return node.multimesh.get_aabb()
	return AABB()

static func _independent(node: Node, source: Node) -> bool:
	var parent := node.get_parent()
	while parent != null and parent != source:
		if parent.has_meta("independent_instrument"): return true
		parent=parent.get_parent()
	return false

static func _inside_private_viewport(node: Node, source: Node3D) -> bool:
	var parent := node.get_parent()
	while parent != null and parent != source:
		if parent is Viewport:
			return true
		parent = parent.get_parent()
	return false

static func _mark(host: Node3D, title: String, words: String, at: Vector3, size: Vector2, ink: Color) -> void:
	var node := MeshInstance3D.new()
	node.name = title
	var quad := QuadMesh.new()
	quad.size = size
	node.mesh = quad
	node.position = at
	var finish := Mount.material("ffffff", 1.0)
	var pixels := Vector2i(1536, maxi(16, roundi(1536.0*size.y/size.x)))
	var readable := mini(roundi(pixels.y*.78),roundi(1536.0/maxf(1,words.length()*.62)))
	finish.albedo_texture = Ink.generate_text_image(words, ink, pixels, readable, "medium")
	finish.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	node.material_override = finish
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host.add_child(node)
