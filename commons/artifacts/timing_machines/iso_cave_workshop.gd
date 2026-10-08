extends "res://commons/artifacts/timing_machines/pg_workshop.gd"
## A small desk for the cave/portal pair. The existing generators own the field;
## this desk only writes their declared controls and makes the consequences legible.
const PLUMBS := ["bedded", "overturned", "weightless", "steep"]
const OCTAVES := [1, 2, 3, 6]
const PORTALS := [1, 3, 7, 16]
const BURIALS := ["straddling", "sunken", "standing", "floating"]
const PUSH_FRONT = preload("res://commons/interactables/push_button.tscn")
var cave
var portal
var plumb_i := 0
var octave_i := 3
var portal_i := 2
var burial_i := 0
var cave_snapshot: MeshInstance3D
var actions_taken := 0

func _bind() -> void:
	var hall: Node = get_parent()
	while hall != null and not hall.has_meta("em_map"): hall = hall.get_parent()
	if hall == null: return
	var em: Node = hall
	while em != null and not "_edit_records" in em: em = em.get_parent()
	if em == null: return
	for attempt in 100:
		for rec: Dictionary in em.get("_edit_records"):
			var n = rec.get("node")
			if is_instance_valid(n) and hall.is_ancestor_of(n):
				if rec.get("token") == "mc_inside_cave": cave = _script_node(n, "TerrainGenerator.gd")
				if rec.get("token") == "mc_portal_landscape": portal = _script_node(n, "TerrainGeneratorUnifiedPortals.gd")
		if cave != null and portal != null: break
		await get_tree().create_timer(0.1).timeout
	if cave == null or portal == null:
		push_error("Cave workshop needs both primary fields"); return
	for n in [cave, portal]:
		n.set_process(false)
		for cam in n.find_children("*", "Camera3D", true, false): cam.current = false
	# Prevent inherited labels and old panels from covering the comparison.
	for ui in hall.find_children("*", "CanvasLayer", true, false): ui.hide()
	ids = ["PLUMB", "OCTAVES", "PORTALS", "BURIAL", "HOLD", "RESET", "RULE"]
	_build_cave_console(ids, "OPENING / ENCLOSURE / ROUTE")
	# The museum's general dressing pass may mute inherited controls. These are
	# new lesson controls, so keep their real pointer areas on the same layer as
	# the other working desks.
	for button in buttons.values():
		var area := button.get_node_or_null("InteractableAreaButton") as Area3D
		if area != null:
			area.collision_layer = 1048576
			area.collision_mask = 393216
			area.monitoring = true
			area.monitorable = true
			var shape := area.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if shape != null: shape.disabled = false
	# A regenerated segment can retain an earlier desk's hidden touch areas for
	# one physics frame. They would intercept the ray before the live control.
	# The cave desk owns its controls, so retire every other area beneath this
	# desk while leaving the artifact interaction areas in the hall untouched.
	for area in find_children("*", "Area3D", true, false):
		var keep := false
		for button in buttons.values():
			if area == button.get_node_or_null("InteractableAreaButton"): keep = true; break
		if not keep:
			area.collision_layer = 0; area.collision_mask = 0; area.monitoring = false; area.monitorable = false
	rule_card = label("LEFT: plumb + octaves alter the enclosing field.\nRIGHT: portal count + burial alter the opening.\nA visible opening is not a clearance proof.\nA sampled boundary is not a route.", Vector3(0, 2.25, 0.4), 0.001)
	rule_card.visible = false
	label("ENCLOSING FIELD", Vector3(4.5, 2.55, -6), 0.003)
	label("PORTAL FIELD", Vector3(-5.5, 2.55, -6), 0.003)
	readout = label("LEFT bedded / 6 octaves\nRIGHT 7 portals / straddling\nHOLD keeps the earlier boundary behind the live one.", Vector3(0, 2.7, 0.45), 0.001)
	for at in [Vector3(-4, 5, -3), Vector3(4, 5, -8)]:
		var light := OmniLight3D.new(); light.position = at; light.omni_range = 20; light.light_energy = 3; add_child(light)
	ready_for_input = true
	refresh()

func _script_node(n: Node, ending: String):
	if n.get_script() != null and str(n.get_script().resource_path).ends_with(ending): return n
	for child in n.get_children():
		var found = _script_node(child, ending)
		if found != null: return found
	return null

func _build_cave_console(control_ids: Array, title: String) -> void:
	# Front-facing buttons keep the touch volume aligned with the visible cap;
	# the generic desk's sideways button transform is useful for its other layouts
	# but makes a rotated cave desk hard to aim at from the approach.
	box(Vector3(0, 0.95, 2.0), Vector3(1.12, 0.12, 0.44), material("263a44"), true)
	for x in [-0.42, 0.42]: box(Vector3(x, 0.445, 2.0), Vector3(0.08, 0.89, 0.30), material("263a44"), true)
	for i in control_ids.size():
		var id: String = control_ids[i]; var button = PUSH_FRONT.instantiate()
		var column: int = i % 3; var row: int = i / 3
		button.position = Vector3((column - 1) * 0.32, 1.045, 1.88 + row * 0.23); button.scale = Vector3.ONE * 1.15
		add_child(button); buttons[id] = button; button.pressed.connect(act.bind(id))
		# The visible cap is intentionally small, but a VR/desktop hand needs a
		# forgiving target. Add a shallow box to the same area so the control can
		# be reached at an oblique approach without changing its appearance.
		var area := button.get_node_or_null("InteractableAreaButton") as Area3D
		if area != null:
			var touch_shape := CollisionShape3D.new(); var touch_box := BoxShape3D.new()
			# local z becomes the desk's vertical direction; keep that depth thin
			# so the next row cannot occlude a ray aimed at this row.
			touch_box.size = Vector3(0.22, 0.22, 0.04); touch_shape.shape = touch_box
			touch_shape.position = Vector3(0, 0, 0.01); area.add_child(touch_shape)
		var caption = label(id, button.position + Vector3(0, 0.01, 0.09), 0.00065); caption.rotation_degrees.x = -70
	box(Vector3(0, 0.90, 2.235), Vector3(1.12, 0.15, 0.025), material("263a44"))
	label(title, Vector3(0, 0.90, 2.252), 0.00063)
	var panel := Node3D.new(); panel.name = "TextPanel"; panel.position = Vector3(0, 1.27, 1.58); panel.rotation_degrees.x = -35; add_child(panel)
	var glass := MeshInstance3D.new(); var pane := QuadMesh.new(); pane.size = Vector2(1.18, 0.36); glass.mesh = pane
	var tint := StandardMaterial3D.new(); tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; tint.cull_mode = BaseMaterial3D.CULL_DISABLED; tint.albedo_color = Color(0.12, 0.25, 0.30, 0.14); glass.material_override = tint; glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; panel.add_child(glass)
	readout = label(title, Vector3.ZERO, 0.0011); readout.font_size = 28; readout.outline_size = 7; readout.outline_modulate = Color(0.025,0.04,0.055,0.95); readout.reparent(panel)

func act(id: String) -> void:
	if not ready_for_input or busy: return
	actions_taken += 1
	if id == "RULE": rule_card.visible = not rule_card.visible; return
	busy = true
	match id:
		"PLUMB":
			plumb_i = (plumb_i + 1) % PLUMBS.size(); cave.apply_grid_config({"plumb": PLUMBS[plumb_i]})
		"OCTAVES":
			octave_i = (octave_i + 1) % OCTAVES.size(); cave.apply_grid_config({"octaves": OCTAVES[octave_i]})
		"PORTALS":
			portal_i = (portal_i + 1) % PORTALS.size(); portal.apply_grid_config({"num_portals": PORTALS[portal_i]})
		"BURIAL":
			burial_i = (burial_i + 1) % BURIALS.size(); portal.apply_grid_config({"burial": BURIALS[burial_i]})
		"HOLD":
			if is_instance_valid(cave_snapshot): cave_snapshot.queue_free()
			if cave.mesh is ArrayMesh:
				cave_snapshot = MeshInstance3D.new(); cave_snapshot.mesh = cave.mesh.duplicate(true); cave_snapshot.material_override = cave.material_override
				add_child(cave_snapshot); cave_snapshot.global_transform = cave.global_transform; cave_snapshot.global_position += global_basis * Vector3(0, 0, 10)
		"RESET":
			plumb_i = 0; octave_i = 3; portal_i = 2; burial_i = 0
			cave.apply_grid_config({"plumb": PLUMBS[plumb_i], "octaves": OCTAVES[octave_i]})
			portal.apply_grid_config({"num_portals": PORTALS[portal_i], "burial": BURIALS[burial_i]})
	await get_tree().process_frame
	busy = false; refresh()

func refresh() -> void:
	if is_instance_valid(readout):
		readout.text = "LEFT %s / %d octaves\nRIGHT %d portals / %s\nHOLD keeps the earlier boundary behind the live one." % [PLUMBS[plumb_i], OCTAVES[octave_i], PORTALS[portal_i], BURIALS[burial_i]]
