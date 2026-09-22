extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Opt-in desks for Fractal_Recursion. The original artifacts remain the executors.
## Only map tokens carrying lesson:true attach this fixture.
var kind: String = "one"
var source: Node3D
var show_rule := false
var _elapsed := 0.0
const CHAIR_STAGES := ["CUBE", "CUT + LIFT", "FLATTEN SEAT", "EXTEND LEGS", "EXTEND BACK", "ADD ARMRESTS"]

func _ready() -> void:
	source = get_parent()
	var raise_by: float = {"one": 2.2, "branch": 2.4, "spend": 1.5, "cut": 0.0}[kind]
	position.y = -raise_by
	var ids: Array
	var title: String
	match kind:
		"one":
			ids = ["MORE", "LESS", "LAYOUT", "COLLAPSE", "BEGIN", "RULE"]
			title = "01 / ONE CALL"
		"branch":
			ids = ["MORE", "LESS", "PACKING", "TURN", "BEGIN", "RULE"]
			title = "02 / FOUR CALLS"
		"spend":
			ids = ["SPLIT", "DRILL", "SPREAD", "LOTS", "BEGIN", "RULE"]
			title = "03 / WHERE NEXT?"
			box(Vector3(0, 0.5, 0), Vector3(1.35, 1, 1.35), material("263a44"), true)
		"cut":
			ids = ["NEXT", "GHOST", "SCAR", "GONE", "BEGIN", "RULE"]
			title = "04 / WHAT COUNTS AS A CHAIR?"
	_build_compact_console(ids, title)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 3.6, 1.0)
	lamp.light_color = Color("ffe8c9")
	lamp.light_energy = 1.2
	lamp.omni_range = 6.0
	add_child(lamp)
	if kind == "cut":
		# The chair sits on the floor: its legs disappear behind a frontal
		# desk even with a low screen. Turn this desk to the side of the study.
		var side_desk := Node3D.new()
		side_desk.name = "SideDesk"
		add_child(side_desk)
		for child in get_children():
			if child != side_desk: child.reparent(side_desk, false)
		side_desk.rotation.y = PI / 2
	# A low boundary marks the study's footprint without blocking the visitor.
	box(Vector3(0, 0.006, 0), Vector3(4.7, 0.012, 3.1), material("23323b"))
	begin()
	if kind == "one": _use_hall_light.call_deferred()

func _build_compact_console(ids: Array, title: String) -> void:
	# All six controls fit within one standing position. Keep the physical
	# button size; compact the spacing instead of shrinking the touch targets.
	var casing := material("263a44")
	box(Vector3(0, 0.95, 2.0), Vector3(1.12, 0.12, 0.44), casing, true)
	for x in [-0.42, 0.42]:
		box(Vector3(x, 0.445, 2.0), Vector3(0.08, 0.89, 0.30), casing, true)
	for i in ids.size():
		var id: String = ids[i]
		var column: int = i % 3
		var row: int = i / 3
		var button = PUSH.instantiate()
		button.position = Vector3((column - 1) * 0.32, 1.045, 1.88 + row * 0.23)
		button.rotation = Vector3.ZERO
		button.scale = Vector3.ONE * 1.15
		add_child(button)
		buttons[id] = button
		button.pressed.connect(act.bind(id))
		var caption := label(id, button.position + Vector3(0, 0.01, 0.09), 0.00065)
		caption.rotation_degrees.x = -70
	box(Vector3(0, 0.90, 2.235), Vector3(1.12, 0.15, 0.025), casing)
	label(title, Vector3(0, 0.90, 2.252), 0.00063)

	# A single transparent plane avoids the doubled opacity of a glass box.
	# Text keeps an opaque outline, so the exhibit is visible behind the panel
	# while the reading remains distinct from its changing background.
	var panel := Node3D.new()
	panel.name = "TextPanel"
	add_child(panel)
	panel.position = Vector3(0, 1.27, 1.58)
	panel.rotation_degrees.x = -35
	var glass := MeshInstance3D.new()
	glass.name = "Glass"
	var pane := QuadMesh.new()
	pane.size = Vector2(1.18, 0.36)
	glass.mesh = pane
	var tint := StandardMaterial3D.new()
	tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tint.cull_mode = BaseMaterial3D.CULL_DISABLED
	tint.albedo_color = Color(0.12, 0.25, 0.30, 0.14)
	glass.material_override = tint
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	panel.add_child(glass)
	for y in [-0.19, 0.19]:
		box(Vector3(0, y, 0), Vector3(1.22, 0.016, 0.016), casing, false, panel)
	for x in [-0.60, 0.60]:
		box(Vector3(x, 0, 0), Vector3(0.016, 0.38, 0.016), casing, false, panel)
	for x in [-0.48, 0.48]:
		box(Vector3(x, 1.09, 1.70), Vector3(0.018, 0.22, 0.018), casing)
	readout = label(title, Vector3.ZERO, 0.0011)
	readout.font_size = 28
	readout.outline_size = 7
	readout.outline_modulate = Color(0.025, 0.04, 0.055, 0.95)
	readout.reparent(panel, false)
	readout.position = Vector3(0, 0, 0.009)

func _use_hall_light() -> void:
	# These demonstrations each shipped a standalone sun. Together their
	# directional lights wash out this hall. Keep the museum's shared lighting
	# and local artifact lamps; this scoped fixture affects no other hall.
	var hall: Node = source
	while hall != null and not hall.has_meta("em_map"):
		hall = hall.get_parent()
	if hall == null or str(hall.get_meta("em_map")) != "Fractal_Recursion": return
	for lamp: DirectionalLight3D in hall.find_children("*", "DirectionalLight3D", true, false):
		lamp.hide()

func begin() -> void:
	show_rule = false
	match kind:
		"one": source.apply_grid_config({"depth": 1, "recession": "nested"})
		"branch":
			source.apply_grid_config({"depth": 1, "packing": "fused", "rotation_speed": 0})
			face_rings()
		"spend":
			source.auto_start = false
			source.build_mode = "grow"
			source.tick = "dense"
			source.seed_value = 31415
			source._rebuild()
		"cut": chair_at(0)
	refresh()

func act(id: String) -> void:
	if id == "RULE":
		show_rule = not show_rule
	elif id == "BEGIN":
		begin()
	else:
		show_rule = false
		match kind:
			"one":
				match id:
					"MORE": source.apply_grid_config({"depth": mini(source.depth + 1, 7)})
					"LESS": source.apply_grid_config({"depth": maxi(source.depth - 1, 1)})
					"LAYOUT": source.apply_grid_config({"recession": "nested" if source.recession == "abreast" else "abreast"})
					"COLLAPSE": source.apply_grid_config({"recession": "collapsed" if source.recession != "collapsed" else "nested"})
			"branch":
				match id:
					"MORE": source.apply_grid_config({"depth": mini(source.depth + 1, 5)})
					"LESS": source.apply_grid_config({"depth": maxi(source.depth - 1, 1)})
					"PACKING":
						var packs := ["fused", "contact", "open", "dust"]
						source.apply_grid_config({"packing": packs[(packs.find(source.packing) + 1) % packs.size()]})
					"TURN": source.rotation_speed = 0.3 if source.rotation_speed == 0 else 0.0
				face_rings()
			"spend":
				if id == "SPLIT": source.step()
				else:
					source.walk = {"DRILL": "drill", "SPREAD": "spread", "LOTS": "population"}[id]
					begin()
			"cut":
				if id == "NEXT":
					if source.step < 5:
						source.step += 1
						source._execute_step(source.step)
				else:
					source.removal = id.to_lower()
					chair_at(source.step)
	refresh()

func chair_at(stage: int) -> void:
	source.build_mode = "grow"
	source.reset()
	source.is_animating = false
	for next_stage in range(1, stage + 1):
		source.step = next_stage
		source._execute_step(next_stage)

func face_rings() -> void:
	# TorusMesh is horizontal by default. This encounter starts face-on, with
	# centres unchanged in the source's XY plane. TURN lets the tori tumble again.
	for circle: Dictionary in source._circles:
		circle.node.rotation = Vector3(PI / 2 if source.rotation_speed == 0 else 0.0, 0, 0)
		circle.rotation = 0.0
	source._is_paused = false
	source._pause_timer = 0.0
	source._status_label.hide()

func _process(dt: float) -> void:
	_elapsed += dt
	if _elapsed >= 0.2:
		_elapsed = 0
		refresh()

func refresh() -> void:
	if not is_instance_valid(readout): return
	if show_rule:
		readout.text = {
			"one": "SOURCE / one self-call after drawing\nif d <= 0 or size < 0.01: return\n_draw_recursive_pattern(center, size * size_reduction, d - 1)",
			"branch": "SOURCE / four self-calls after drawing\nif level <= 0 or radius < 0.01: return\ncentres move to +X, -X, +Y, -Y; level decreases by 1",
			"spend": "SOURCE / replace ONE selected cell\nremove 1, add 8; child.scale = parent.scale * 0.45\n12 splits is the hall budget. Selection decides where it goes.",
			"cut": "SOURCE / an authored sequence of five stages\n3 x 3 x 3 cells: keep legs, seat, back; lift the lattice\nthen reshape parts and add armrests. No self-call."
		}[kind]
		return
	match kind:
		"one":
			var terms: Array = source._terms()
			readout.text = "What changed when you asked for more?\n%d squares / depth %d of 7 / %s\nSmallest term %.4f m / MORE, then try LAYOUT" % [source._mesh_instances.size(), source.depth, source.recession, terms.back()]
		"branch":
			readout.text = "Predict the next count before pressing MORE.\n%d rings / depth %d of 5 / %s\nRadius x %.2f / minimum 0.01 m / turning %s" % [source._circles.size(), source.depth, source.packing, source.radius_reduction, "ON" if source.rotation_speed != 0 else "OFF"]
		"spend":
			var deepest := 0
			for d in source.cube_depths.values(): deepest = maxi(deepest, int(d))
			readout.text = "Where will the next split be spent?\n%d cells / %d of 12 splits / deepest %d\n%s / fixed seed 31415 / choose a mode to begin again" % [source.all_cubes.size(), source.subdivision_count, deepest, source.walk]
		"cut":
			readout.text = "%s / stage %d of 5\n%d kept parts / %d removal markers / %s\nNEXT builds; GHOST shows cells the first cut excluded." % [CHAIR_STAGES[source.step], source.step, source.all_cubes.size(), source._removed_nodes.size(), source.removal]
