extends RefCounted
## Opt-in installation of Random_Entropy's existing instruments. No new model,
## pointer receivers or saved experiment state: original controls keep ownership.
const Mount = preload("res://commons/void/ceiling_display_mount.gd")
const Hardware = preload("res://commons/void/randomness_interface_hardware.gd")
const Supply = preload("res://commons/void/hardware_supply.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")

static func attach_later(source: Node3D, kind: String) -> void:
	# The museum furnishing adapter relocates compact panels after _ready.
	var tree := source.get_tree()
	for i in 4: await tree.process_frame
	if not is_instance_valid(source) or not source.is_inside_tree(): return
	if source.has_meta("entropy_workshop_installed"): return
	source.set_meta("entropy_workshop_installed", true)
	source.set_meta("mounted_interface", true)
	match kind:
		"shannon_entropy_meter", "entropy_ruin":
			var console: Node3D = source.get_node("ExhibitStage/ReachConsole")
			if kind == "entropy_ruin":
				# The old operating marker was over the shaft. Move the original
				# console and its standing marker together onto the west bank.
				console.position.x = 4.2
			for child in console.get_children():
				if child is MeshInstance3D and child.mesh is BoxMesh and child.mesh.size.is_equal_approx(Vector3(.09,.97,.09)):
					remove(child)
			for child in console.get_children():
				if child.has_meta("panel_w"): fit_panel(child)
			if kind == "shannon_entropy_meter":
				remove(source.get_node_or_null("Staging/Post"))
				# Keep this on Staging, which survives the gauge's DISCLOSE rebuild.
				carrier(source.get_node("Staging"),"GaugeCarrier",Vector3(0,1.4,-.08),Vector2(.86,.64))
		"entropy_jar_states":
			var panel: Node3D = source.get_node("ReadingPanel")
			for child in panel.get_children():
				if child is MeshInstance3D and child.mesh is BoxMesh and child.mesh.size.y > 2:
					remove(child)
				elif child is StaticBody3D:
					remove(child) # The source stand uses a sibling collider.
			carrier(panel,"ReadingCarrier",Vector3(0,1.36,-.06),Vector2(1.84,1.52))
		"entropy_jar":
			var panel: Node3D = source.get_node("RackPanel")
			panel.position = Vector3(.55,1.12,.06)
			panel.scale = Vector3.ONE * 2.8
			fit_panel(panel)
		"prefab_disorder":
			for node in source.console.find_children("Lectern*","",true,false): remove(node)
			fit_panel(source.console)
		"entropy_compartments":
			# Retain both live circular dials and horizontal two-row hand controls.
			# The rear yoke belongs to the cabinet; it never crosses the tray.
			carrier(source,"GaugeCarrier",Vector3(0,1.90,-.66),Vector2(2.5,1.44))
		"entropy_sorting_table":
			# Delivery tube, four pickable cubes, and the WAYS witness stay intact.
			carrier(source,"WaysCarrier",Vector3(.18,1.66,-.55),Vector2(2.28,1.28))
		"hardware_entropy_decay":
			# W/A/S/D belongs to locomotion here, not the demo's keyboard fallback.
			source.set_process_input(false)
			for panel in source.get_children():
				if panel.has_meta("panel_w"):
					# This artifact is curated at 0.6 scale. Its original two-button
					# panel was only ten centimetres wide in world space.
					panel.scale = Vector3.ONE * 3.5
					panel.rotation_degrees = Vector3(-20,0,0)
					panel.position = Vector3(-2.9,1.15,.28)
					fit_panel(panel)
		"signal_room":
			# The room was curated beyond the main slab. Fix the operating face to
			# its own entrance lintel instead of pretending there is a slab above it.
			var face := Node3D.new(); face.name = "SignalOperatingFace"; source.add_child(face)
			face.position = Vector3(0,1.08,source.console_z)
			for button in source.controls:
				button.reparent(face, true)
				for mesh in button.find_children("*","MeshInstance3D",true,false):
					mesh.material_override = Mount.material("e8e4d8",.92)
				for label in button.find_children("*","Label3D",true,false):
					label.modulate = Color("232b2d")
			source.status.reparent(face,true)
			source.status.modulate = Color("e8e4d8")
			# Set the console back onto the room's own floor, leaving the narrow
			# balcony-to-room threshold open before the visitor chooses a side.
			face.position.z = 11.2
			# Remove only the original solid counter below this face.
			for child in source.get_children():
				if child is StaticBody3D:
					for mesh in child.get_children():
						if mesh is MeshInstance3D and mesh.mesh is BoxMesh and mesh.mesh.size.is_equal_approx(Vector3(3.9,1.04,.42)):
							remove(child); break
			carrier(face,"EntranceCarrier",Vector3(0,.03,.16),Vector2(3.90,.68),float(source.specimen.room_height),-1.8)
	# Rectangular buttons preserve all original callback and collision objects.
	for button in source.find_children("*","Node3D",true,false):
		if button.has_node("Button/ButtonMesh") and button.has_node("InteractableAreaButton"):
			Rack.make_button_rectangular(button)

static func remove(node: Node) -> void:
	if not is_instance_valid(node): return
	node.get_parent().remove_child(node); node.queue_free()

static func fit_panel(panel: Node3D) -> void:
	if panel.has_node("WorkshopCarrier"): return
	var probe := Node3D.new(); panel.add_child(probe)
	# Fit in real metres, with world-up even for a tilted/scaled control head.
	probe.global_basis = Basis(Vector3.UP,panel.global_rotation.y)
	var bounds := Hardware._local_bounds(panel,probe)
	var origin: Vector3 = probe.to_local(panel.global_position)
	panel.remove_child(probe); probe.free()
	if bounds.size == Vector3.ZERO: return
	var at := Vector3(bounds.get_center().x,bounds.get_center().y,bounds.position.z-.075)-origin
	carrier(panel,"WorkshopCarrier",at,Vector2(maxf(.40,bounds.size.x+.12),maxf(.27,bounds.size.y+.10)), -1,0,true)

static func carrier(parent: Node3D, label: String, at: Vector3, size: Vector2, room_height := -1.0, lintel_offset := 0.0, real_axes := false) -> Node3D:
	var mount := Node3D.new(); mount.name = label; parent.add_child(mount)
	if real_axes:
		mount.global_basis = Basis(Vector3.UP,parent.global_rotation.y)
		mount.global_position = parent.global_position + mount.global_basis * at
	else:
		mount.position = at
		# All custom cases are defined in their source's unscaled metre frame.
	var floor_root := Hardware._floor(parent)
	var ceiling: float = Hardware._slab_y(floor_root)
	if room_height > 0: ceiling = floor_root.global_position.y + room_height
	var top: float = mount.to_local(Vector3(mount.global_position.x,ceiling,mount.global_position.z)).y
	var cream := Mount.material("e8e4d8",.92)
	var graphite := Mount.material("343b3d",.85,.12)
	Mount.box(mount,"ServiceCase",Vector3.ZERO,Vector3(size.x,size.y,.09),graphite)
	for side in [-1.0,1.0]:
		var x: float = side * (size.x/2+.025)
		Mount.box(mount,"IvoryRail",Vector3(x,0,.025),Vector3(.05,size.y+.08,.14),cream)
		var start: float = size.y/2+.08
		if top > start:
			Mount.box(mount,"DropMast",Vector3(x,(top+start)/2,lintel_offset),Vector3(.065,top-start,.08),cream)
			Mount.box(mount,"AnchorPlate",Vector3(x,top-.035,lintel_offset),Vector3(.30,.07,.28),graphite)
			if not is_zero_approx(lintel_offset):
				Mount.box(mount,"LintelArm",Vector3(x,start,lintel_offset/2),Vector3(.08,.08,absf(lintel_offset)+.08),cream)
			var mark := Marker3D.new()
			mark.name=("LintelContact" if room_height>0 else "SlabContact")+("Left" if side<0 else "Right")
			mark.position=Vector3(x,top,lintel_offset); mount.add_child(mark)
	Mount.box(mount,"Yoke",Vector3(0,size.y/2+.06,0),Vector3(size.x+.10,.05,.14),cream)
	Supply.connect_unit(mount,Vector3(0,size.y/2,-.10))
	var lamp := OmniLight3D.new(); lamp.name="ReadingLight"; mount.add_child(lamp)
	lamp.position=Vector3(0,size.y/2+.12,.35); lamp.light_color=Color("ffead5")
	lamp.light_energy=.45; lamp.omni_range=2.4; lamp.shadow_enabled=false
	return mount
