# creature_editor.gd — Desktop DNA creature editor
#
# Split-view: gene sliders on the left, live 3D organism on the right.
# Change any gene → morphology rebuilds in real-time.
# Kingdom buttons spawn different types. Presets load named configurations.
#
# Usage: Open creature_editor.tscn and run (F5).

extends HSplitContainer

# ── Gene definitions ──────────────────────────────────────────────
const GENE_GROUPS: Array[Dictionary] = [
	{"name": "Kingdom", "genes": [
		{"id": "body_type", "label": "Body Type", "min": 0.0, "max": 4.0, "step": 0.1},
		{"id": "scale", "label": "Scale", "min": 0.3, "max": 3.0, "step": 0.1},
	]},
	{"name": "Morphology", "genes": [
		{"id": "segments", "label": "Segments", "min": 2.0, "max": 12.0, "step": 1.0},
		{"id": "symmetry", "label": "Symmetry", "min": 1.0, "max": 8.0, "step": 1.0},
		{"id": "branch_angle", "label": "Branch Angle", "min": 10.0, "max": 90.0, "step": 1.0},
		{"id": "branch_decay", "label": "Branch Decay", "min": 0.3, "max": 0.95, "step": 0.05},
		{"id": "leaf_density", "label": "Leaf Density", "min": 0.0, "max": 1.0, "step": 0.05},
	]},
	{"name": "Geometry", "genes": [
		{"id": "part_length", "label": "Part Length", "min": 0.1, "max": 2.0, "step": 0.1},
		{"id": "part_width", "label": "Part Width", "min": 0.1, "max": 2.0, "step": 0.1},
		{"id": "part_curve", "label": "Part Curve", "min": 0.0, "max": 1.0, "step": 0.05},
		{"id": "part_taper", "label": "Part Taper", "min": 0.0, "max": 1.0, "step": 0.05},
		{"id": "part_twist", "label": "Part Twist", "min": 0.0, "max": 1.0, "step": 0.05},
	]},
	{"name": "Material", "genes": [
		{"id": "roughness", "label": "Roughness", "min": 0.0, "max": 1.0, "step": 0.05},
		{"id": "metallic", "label": "Metallic", "min": 0.0, "max": 1.0, "step": 0.05},
		{"id": "iridescence", "label": "Iridescence", "min": 0.0, "max": 1.0, "step": 0.05},
		{"id": "transparency", "label": "Transparency", "min": 0.0, "max": 0.8, "step": 0.05},
	]},
	{"name": "Behavior", "genes": [
		{"id": "mobility", "label": "Mobility", "min": 0.0, "max": 1.0, "step": 0.05},
		{"id": "aggression", "label": "Aggression", "min": 0.0, "max": 1.0, "step": 0.05},
		{"id": "sociality", "label": "Sociality", "min": 0.0, "max": 1.0, "step": 0.05},
		{"id": "curiosity", "label": "Curiosity", "min": 0.0, "max": 1.0, "step": 0.05},
	]},
	{"name": "Detail", "genes": [
		{"id": "phyllotaxis", "label": "Phyllotaxis", "min": 0.0, "max": 1.0, "step": 0.05},
		{"id": "inflorescence", "label": "Inflorescence", "min": 0.0, "max": 1.0, "step": 0.05},
		{"id": "pattern_type", "label": "Pattern Type", "min": 0.0, "max": 1.0, "step": 0.1},
		{"id": "pattern_density", "label": "Pattern Density", "min": 0.0, "max": 1.0, "step": 0.05},
	]},
]

# ── State ─────────────────────────────────────────────────────────
var _dna: CritterDNA = null
var _entity: CritterEntity = null
var _spawner: CritterSpawner = null
var _organism_root: Node3D = null
var _sliders: Dictionary = {}  # gene_id → HSlider
var _color_pickers: Dictionary = {}  # color_id → ColorPickerButton
var _rebuild_timer: float = 0.0
var _needs_rebuild: bool = false

# ── UI refs ───────────────────────────────────────────────────────
var controls: VBoxContainer = null
var viewport_container: SubViewportContainer = null
var viewport: SubViewport = null
var cam: Camera3D = null
var info_label: Label = null
var orbit_yaw: float = 0.3
var orbit_pitch: float = 0.4
var orbit_dist: float = 4.0
var orbiting: bool = false


func _ready() -> void:
	# Left panel: controls
	controls = VBoxContainer.new()
	controls.custom_minimum_size = Vector2(280, 0)
	add_child(controls)

	# Right panel: 3D viewport
	viewport_container = SubViewportContainer.new()
	viewport_container.stretch = true
	viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(viewport_container)

	viewport = SubViewport.new()
	viewport.size = Vector2i(800, 600)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(viewport)

	# Camera
	cam = Camera3D.new()
	cam.name = "EditorCamera"
	cam.fov = 50
	cam.current = true
	viewport.add_child(cam)

	# Light
	var light := DirectionalLight3D.new()
	light.light_energy = 1.0
	light.rotation_degrees = Vector3(-40, -30, 0)
	viewport.add_child(light)

	var ambient := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.1, 0.13)
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.6
	ambient.environment = env
	viewport.add_child(ambient)

	# Organism root in viewport
	_organism_root = Node3D.new()
	_organism_root.name = "OrganismRoot"
	viewport.add_child(_organism_root)

	_spawner = CritterSpawner.new(_organism_root)
	_spawner.max_population = 5
	_spawner.default_lod = 0

	# Build UI
	_build_kingdom_buttons()
	_build_preset_buttons()
	_build_color_pickers()
	_build_gene_sliders()
	_build_info_bar()

	# Start with a random tree
	_spawn_new(0)
	_update_cam()

	# Connect orbit input
	viewport_container.gui_input.connect(_on_viewport_input)


func _process(delta: float) -> void:
	if _needs_rebuild:
		_rebuild_timer += delta
		if _rebuild_timer > 0.15:  # Throttle: max ~7 rebuilds/sec
			_rebuild_timer = 0.0
			_needs_rebuild = false
			_rebuild_organism()

	# Slow auto-rotation when not orbiting
	if not orbiting and _entity and is_instance_valid(_entity):
		_entity.rotation.y += delta * 0.2


# ═══════════════════════════════════════════════════════════════
# UI CONSTRUCTION
# ═══════════════════════════════════════════════════════════════

func _build_kingdom_buttons() -> void:
	var header := Label.new()
	header.text = "Kingdom"
	header.add_theme_font_size_override("font_size", 14)
	controls.add_child(header)

	var hbox := HBoxContainer.new()
	var kingdoms_list: Array[String] = ["Tree", "Creature", "Flower", "Fungus", "Hybrid"]
	for i: int in kingdoms_list.size():
		var btn := Button.new()
		btn.text = kingdoms_list[i]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_spawn_new.bind(i))
		hbox.add_child(btn)
	controls.add_child(hbox)

	# Random button
	var rand_btn := Button.new()
	rand_btn.text = "Random"
	rand_btn.pressed.connect(_on_random_pressed)
	controls.add_child(rand_btn)


## Callback for the Random button — avoids a lambda closure.
func _on_random_pressed() -> void:
	_spawn_new(randi() % 5)


func _build_preset_buttons() -> void:
	var header := Label.new()
	header.text = "Presets"
	header.add_theme_font_size_override("font_size", 14)
	controls.add_child(header)

	var grid := GridContainer.new()
	grid.columns = 3
	var preset_names: Array[String] = [
		"lsystem_tree", "fibonacci_flower", "turing_fungus",
		"flocking_creature", "walking_tree", "predator",
		"oak", "mushroom_colony", "hybrid_drag",
	]
	for pname: String in preset_names:
		var btn := Button.new()
		btn.text = pname.replace("_", " ").capitalize()
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_load_preset.bind(pname))
		grid.add_child(btn)
	controls.add_child(grid)


func _build_color_pickers() -> void:
	var header := Label.new()
	header.text = "Colors"
	header.add_theme_font_size_override("font_size", 14)
	controls.add_child(header)

	var hbox := HBoxContainer.new()
	var color_defs: Array[Dictionary] = [
		{"id": "primary_color", "label": "Primary", "default": Color.WHITE},
		{"id": "secondary_color", "label": "Secondary", "default": Color.WHITE},
		{"id": "tertiary_color", "label": "Tertiary", "default": Color.WHITE},
	]
	for cdef: Dictionary in color_defs:
		var color_id: String = cdef["id"] as String
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var clbl := Label.new()
		clbl.text = cdef["label"] as String
		clbl.add_theme_font_size_override("font_size", 10)
		clbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(clbl)

		var picker := ColorPickerButton.new()
		picker.custom_minimum_size = Vector2(60, 28)
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picker.color = cdef["default"] as Color
		picker.edit_alpha = false
		picker.color_changed.connect(_on_color_changed.bind(color_id))
		vbox.add_child(picker)

		hbox.add_child(vbox)
		_color_pickers[color_id] = picker

	controls.add_child(hbox)


func _build_gene_sliders() -> void:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 300)
	var vbox := VBoxContainer.new()

	for group: Dictionary in GENE_GROUPS:
		var group_label := Label.new()
		group_label.text = "— %s —" % [group["name"] as String]
		group_label.add_theme_font_size_override("font_size", 12)
		group_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(group_label)

		var genes: Array = group["genes"] as Array
		for gene: Dictionary in genes:
			var gene_id: String = gene["id"] as String
			var hbox := HBoxContainer.new()
			var lbl := Label.new()
			lbl.text = gene["label"] as String
			lbl.custom_minimum_size = Vector2(100, 0)
			lbl.add_theme_font_size_override("font_size", 11)
			hbox.add_child(lbl)

			var slider := HSlider.new()
			slider.min_value = gene["min"] as float
			slider.max_value = gene["max"] as float
			slider.step = gene["step"] as float
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slider.value_changed.connect(_on_gene_changed.bind(gene_id))
			hbox.add_child(slider)

			var val_label := Label.new()
			val_label.name = "Val"
			val_label.custom_minimum_size = Vector2(40, 0)
			val_label.add_theme_font_size_override("font_size", 10)
			hbox.add_child(val_label)

			vbox.add_child(hbox)
			_sliders[gene_id] = slider

	scroll.add_child(vbox)
	controls.add_child(scroll)


func _build_info_bar() -> void:
	info_label = Label.new()
	info_label.text = "Left-click+drag: orbit | Scroll: zoom | Kingdom/Preset: spawn"
	info_label.add_theme_font_size_override("font_size", 10)
	controls.add_child(info_label)


# ═══════════════════════════════════════════════════════════════
# ORGANISM MANAGEMENT
# ═══════════════════════════════════════════════════════════════

func _spawn_new(kingdom: int) -> void:
	_clear_organism()
	if kingdom == 4:
		_dna = CritterDNA.random()
		_dna.body_type = randf_range(0.5, 3.5)
	else:
		_dna = CritterDNA.random_kingdom(kingdom)
	_spawn_from_dna()


func _load_preset(preset_name: String) -> void:
	_clear_organism()
	var placer_script: GDScript = load("res://commons/artifacts/critter_placer/critter_placer.gd") as GDScript
	if placer_script and preset_name in placer_script.PRESETS:
		var preset: Dictionary = placer_script.PRESETS[preset_name] as Dictionary
		_dna = CritterDNA.new()
		var kingdom: int = int(preset.get("kingdom", 0))
		_dna.body_type = float(kingdom) if kingdom >= 0 else float(preset.get("body_type", 1.0))
		for gene_name: String in preset:
			if gene_name in ["kingdom", "primary_color", "secondary_color", "tertiary_color"]:
				continue
			_dna.set(gene_name, float(preset[gene_name]))
		if preset.has("primary_color"):
			_dna.primary_color = Color(preset["primary_color"] as String)
		if preset.has("secondary_color"):
			_dna.secondary_color = Color(preset["secondary_color"] as String)
	else:
		_dna = CritterDNA.random()
	_spawn_from_dna()


func _spawn_from_dna() -> void:
	_entity = _spawner.spawn(_dna, Vector3.ZERO, 0)
	if _entity:
		_entity.set_process(false)
		_entity.set_physics_process(false)
	_sync_sliders_to_dna()
	_update_info()


func _clear_organism() -> void:
	if _entity and is_instance_valid(_entity):
		_entity.queue_free()
	_entity = null
	# Clear any leftover children
	for child: Node in _organism_root.get_children():
		child.queue_free()
	# Use the public API instead of accessing private _active_critters directly
	_spawner.despawn_all()


func _rebuild_organism() -> void:
	if not _entity or not is_instance_valid(_entity) or not _dna:
		return
	MorphologyRouter.rebuild(_entity, _dna, _spawner.trait_mapper, 0)
	_update_info()


func _sync_sliders_to_dna() -> void:
	if not _dna:
		return
	for gene_id: String in _sliders:
		var slider: HSlider = _sliders[gene_id] as HSlider
		var val: Variant = _dna.get(gene_id)
		if val != null:
			slider.set_value_no_signal(float(val))
		var val_label: Label = slider.get_parent().get_node_or_null("Val") as Label
		if val_label:
			val_label.text = "%.2f" % slider.value
	_sync_color_pickers_to_dna()


func _sync_color_pickers_to_dna() -> void:
	if not _dna:
		return
	for color_id: String in _color_pickers:
		var picker: ColorPickerButton = _color_pickers[color_id] as ColorPickerButton
		var col: Variant = _dna.get(color_id)
		if col is Color:
			picker.color = col as Color


func _update_info() -> void:
	if not info_label or not _dna:
		return
	var kingdoms: Array[String] = ["Tree", "Creature", "Flower", "Fungus", "Hybrid"]
	var kid: int = int(round(_dna.body_type))
	var kname: String = kingdoms[clampi(kid, 0, 4)]
	info_label.text = "%s | seg=%.0f sym=%.0f scale=%.1f" % [
		kname, _dna.segments, _dna.symmetry, _dna.scale]


# ═══════════════════════════════════════════════════════════════
# GENE EDITING — slider changes
# ═══════════════════════════════════════════════════════════════

func _on_gene_changed(value: float, gene_id: String) -> void:
	if not _dna:
		return
	_dna.set(gene_id, value)
	# Update value label
	var slider: HSlider = _sliders.get(gene_id) as HSlider
	if slider:
		var val_label: Label = slider.get_parent().get_node_or_null("Val") as Label
		if val_label:
			val_label.text = "%.2f" % value
	# Queue rebuild (throttled)
	_needs_rebuild = true
	_rebuild_timer = 0.0


func _on_color_changed(color: Color, color_id: String) -> void:
	if not _dna:
		return
	_dna.set(color_id, color)
	_needs_rebuild = true
	_rebuild_timer = 0.0


# ═══════════════════════════════════════════════════════════════
# CAMERA ORBIT
# ═══════════════════════════════════════════════════════════════

func _on_viewport_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			orbiting = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			orbit_dist = maxf(1.5, orbit_dist - 0.5)
			_update_cam()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			orbit_dist = minf(15.0, orbit_dist + 0.5)
			_update_cam()
	elif ev is InputEventMouseMotion and orbiting:
		var mm: InputEventMouseMotion = ev as InputEventMouseMotion
		orbit_yaw -= mm.relative.x * 0.005
		orbit_pitch = clampf(orbit_pitch + mm.relative.y * 0.005, 0.1, 1.4)
		_update_cam()


func _update_cam() -> void:
	if not cam:
		return
	var o := Vector3(
		sin(orbit_yaw) * cos(orbit_pitch),
		sin(orbit_pitch),
		cos(orbit_yaw) * cos(orbit_pitch)
	) * orbit_dist
	cam.position = o + Vector3(0, 0.5, 0)
	cam.look_at(Vector3(0, 0.5, 0), Vector3.UP)
