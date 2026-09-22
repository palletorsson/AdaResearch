extends RefCounted
## Opt-in human-sized controls for miniaturized gallery sculptures.
## The existing model, panel, signals and sound generators are retained.

static func stage(gallery: Node3D, panel: Node3D, status: Label3D, kind: String) -> void:
	if gallery.has_node("GalleryConsole"):
		return
	var unit := Node3D.new()
	unit.name = "GalleryConsole"
	unit.set_meta("em_local_instrument", true)
	gallery.add_child(unit)
	unit.scale = Vector3.ONE / gallery.global_basis.get_scale().abs()
	unit.position = Vector3(0.78, 0, 0) / gallery.global_basis.get_scale().abs()
	panel.reparent(unit, false)
	panel.name = "Panel"
	panel.position = Vector3(0, 0.22, 0.73)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	panel.scale = Vector3.ONE * 1.8
	# The original narrow cylinders sit behind the button origins. At this
	# standing approach their top row missed rays. These local hit volumes
	# include the visible buttons without changing any shared button scene.
	for button in panel.find_children("Btn_*", "", false, false):
		var collider: CollisionShape3D = button.get_node_or_null("InteractableAreaButton/CollisionShape3D")
		if collider != null:
			var hit := SphereShape3D.new()
			hit.radius = 0.045
			collider.shape = hit
			collider.position = Vector3.ZERO
	status.reparent(unit, false)
	status.position = Vector3(0, -0.12, 0.82)
	status.rotation_degrees = Vector3(-15, 0, 0)
	status.font_size = 22
	status.pixel_size = 0.0012
	status.outline_size = 3
	status.modulate = Color(0.88, 0.94, 1.0)
	var kit := load("res://commons/artifacts/_hangar/hangar_kit.gd")
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.16, 0.21, 0.24)
	metal.metallic = 0.4
	unit.add_child(kit.box(Vector3(0, -0.55, 0.59), Vector3(0.34, 0.90, 0.24), metal))
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.015, 0.026, 0.04)
	var casing: Node3D = kit.box(Vector3(0, -0.12, 0.80), Vector3(0.90, 0.26, 0.028), dark)
	casing.rotation_degrees.x = -15
	unit.add_child(casing)
	var invitation := Label3D.new()
	invitation.name = "Invitation"
	invitation.text = "LISTEN. WHAT IN THE IMAGE CHANGES?" if kind == "field" else "FIVE COLOURS. TRY ANOTHER SOUND."
	invitation.font_size = 24
	invitation.pixel_size = 0.0011
	invitation.position = Vector3(0, 0.50, 0.74)
	unit.add_child(invitation)
	var backing: Node3D = kit.box(Vector3(0, 0.50, 0.72), Vector3(0.90, 0.065, 0.024), dark)
	unit.add_child(backing)
