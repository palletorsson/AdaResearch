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
	{"name": "Process", "genes": [
		{"id": "form_process", "label": "Form Process", "min": 0.0, "max": 1.0, "step": 0.05},
		{"id": "skeleton_complexity", "label": "Skeleton", "min": 0.0, "max": 1.0, "step": 0.05},
		{"id": "surface_method", "label": "Surface", "min": 0.0, "max": 1.0, "step": 0.05},
		{"id": "modularity", "label": "Modularity", "min": 0.0, "max": 1.0, "step": 0.05},
		{"id": "recursion_depth", "label": "Recursion", "min": 0.0, "max": 1.0, "step": 0.05},
	]},
]

# ── Form process taxonomy labels ─────────────────────────────────
const PROCESS_LABELS: Array[String] = ["Grown", "Grown", "Extruded", "Extruded", "Carved", "Carved", "Carved", "Folded", "Folded", "Crystallized", "Crystallized"]
const SKELETON_LABELS: Array[String] = ["None", "None", "Simple", "Simple", "Spine", "Spine", "Branching", "Branching", "Recursive", "Recursive", "Deep"]
const SURFACE_LABELS: Array[String] = ["Sweep", "Sweep", "Sweep", "Revolution", "Revolution", "SDF", "SDF", "Primitive", "Primitive", "Particle", "Particle"]

# ── Biome stages (loaded from soft_stages.json) ──────────────────
var _biome_stages: Dictionary = {}
var _current_stage: String = ""
var _biome_mode: bool = false
var _biome_entities: Array = []
var _biome_ground: MeshInstance3D = null
var _biome_foliage: Array = []  # Array of MultiMeshInstance3D
var _biome_env_original: Dictionary = {}  # Save original env settings to restore

# ── State ─────────────────────────────────────────────────────────
var _dna: CritterDNA = null
var _entity: CritterEntity = null
var _spawner: CritterSpawner = null
var _organism_root: Node3D = null
var _sliders: Dictionary = {}  # gene_id → HSlider
var _color_pickers: Dictionary = {}  # color_id → ColorPickerButton
var _rebuild_timer: float = 0.0
var _needs_rebuild: bool = false
var _favorites: Array[Dictionary] = []  # [{name, dna_data}]

const FAVORITES_PATH := "user://creature_favorites.json"

# ── UI refs ───────────────────────────────────────────────────────
var controls: VBoxContainer = null
var viewport_container: SubViewportContainer = null
var viewport: SubViewport = null
var cam: Camera3D = null
var info_label: Label = null
var process_label: Label = null
var stage_info_label: Label = null
var fav_list: ItemList = null
var fav_name_edit: LineEdit = null
var stage_selector: OptionButton = null
var _world_env: WorldEnvironment = null
var orbit_yaw: float = 0.3
var orbit_pitch: float = 0.4
var orbit_dist: float = 4.0
var orbiting: bool = false


func _ready() -> void:
	# Left panel: controls (scroll the whole panel)
	var left_scroll := ScrollContainer.new()
	left_scroll.custom_minimum_size = Vector2(300, 0)
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(left_scroll)
	controls = VBoxContainer.new()
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.add_child(controls)

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

	_world_env = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.1, 0.13)
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.6
	_world_env.environment = env
	viewport.add_child(_world_env)

	# Organism root in viewport
	_organism_root = Node3D.new()
	_organism_root.name = "OrganismRoot"
	viewport.add_child(_organism_root)

	_spawner = CritterSpawner.new(_organism_root)
	_spawner.max_population = 15  # Enough for main creature + biome ring
	_spawner.default_lod = 0

	# Load biome stages
	_load_biome_stages()

	# Build UI
	_build_kingdom_buttons()
	_build_preset_buttons()
	_build_biome_controls()
	_build_color_pickers()
	_build_gene_sliders()
	_build_favorites_panel()
	_build_info_bar()
	_build_export_button()

	# Load saved favorites
	_load_favorites()

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
	var kingdoms_list: Array[String] = ["Tree", "Creature", "Flower", "Fungus", "Hybrid", "Pipeline"]
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
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(260, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

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
			slider.custom_minimum_size = Vector2(120, 20)
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


func _build_favorites_panel() -> void:
	var sep := HSeparator.new()
	controls.add_child(sep)

	var header := Label.new()
	header.text = "Favorites"
	header.add_theme_font_size_override("font_size", 14)
	controls.add_child(header)

	# Name input + Save button
	var save_row := HBoxContainer.new()
	fav_name_edit = LineEdit.new()
	fav_name_edit.placeholder_text = "Name..."
	fav_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fav_name_edit.custom_minimum_size = Vector2(150, 0)
	save_row.add_child(fav_name_edit)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_save_favorite)
	save_row.add_child(save_btn)

	var del_btn := Button.new()
	del_btn.text = "Del"
	del_btn.pressed.connect(_delete_favorite)
	save_row.add_child(del_btn)

	controls.add_child(save_row)

	# Favorites list
	fav_list = ItemList.new()
	fav_list.custom_minimum_size = Vector2(0, 120)
	fav_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fav_list.item_selected.connect(_on_favorite_selected)
	controls.add_child(fav_list)


func _save_favorite() -> void:
	if not _dna:
		return
	var fav_name: String = fav_name_edit.text.strip_edges()
	if fav_name.is_empty():
		fav_name = _auto_name_from_dna(_dna)

	# Serialize DNA to dictionary
	var dna_data: Dictionary = _serialize_dna(_dna)
	_favorites.append({"name": fav_name, "dna": dna_data})
	_save_favorites_to_disk()
	_refresh_favorites_list()
	_play_save_sound()
	fav_name_edit.text = ""


## Generate a descriptive name from DNA traits.
func _auto_name_from_dna(dna: CritterDNA) -> String:
	var kingdoms: Array[String] = ["Tree", "Creature", "Flower", "Fungus", "Hybrid"]
	var kid: int = clampi(int(round(dna.body_type)), 0, 4)
	var kname: String = kingdoms[kid]

	# Size descriptor
	var size_word: String = "Small"
	if dna.scale > 1.5:
		size_word = "Giant"
	elif dna.scale > 1.0:
		size_word = "Large"
	elif dna.scale > 0.6:
		size_word = "Medium"

	# Trait descriptor based on dominant gene
	var trait_word: String = ""
	match kid:
		0:  # Tree
			if dna.branch_angle > 60: trait_word = "Spreading"
			elif dna.leaf_density > 0.7: trait_word = "Leafy"
			elif dna.branch_decay < 0.5: trait_word = "Twisted"
			else: trait_word = "Tall"
		1:  # Creature
			if dna.aggression > 0.6: trait_word = "Fierce"
			elif dna.curiosity > 0.6: trait_word = "Curious"
			elif dna.mobility > 0.7: trait_word = "Swift"
			elif dna.segments > 6: trait_word = "Segmented"
			else: trait_word = "Quiet"
		2:  # Flower
			if dna.symmetry > 5: trait_word = "Complex"
			elif dna.iridescence > 0.3: trait_word = "Shimmering"
			elif dna.scent_strength > 0.5: trait_word = "Fragrant"
			else: trait_word = "Delicate"
		3:  # Fungus
			if dna.sociality > 0.7: trait_word = "Colonial"
			elif dna.transparency > 0.3: trait_word = "Ghostly"
			elif dna.inflorescence > 0.5: trait_word = "Clustered"
			else: trait_word = "Pale"
		_:  # Hybrid
			trait_word = "Strange"

	return "%s %s %s" % [size_word, trait_word, kname]


## Short beep on save — confirmation feedback.
var _save_beep: AudioStreamPlayer = null
func _play_save_sound() -> void:
	if not _save_beep:
		_save_beep = AudioStreamPlayer.new()
		_save_beep.volume_db = -12.0
		add_child(_save_beep)
		var sr: int = 22050
		var dur: float = 0.08
		var samples: int = int(sr * dur)
		var data := PackedByteArray()
		data.resize(samples * 2)
		for i: int in samples:
			var t: float = float(i) / float(sr)
			var env: float = sin(t / dur * PI)
			var wave: float = sin(t * TAU * 1200.0) * env * 0.4
			var s16: int = clampi(int(wave * 16000.0), -32768, 32767)
			data[i * 2] = s16 & 0xFF
			data[i * 2 + 1] = (s16 >> 8) & 0xFF
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = sr
		stream.data = data
		_save_beep.stream = stream
	_save_beep.play()


func _delete_favorite() -> void:
	var sel: PackedInt32Array = fav_list.get_selected_items()
	if sel.is_empty():
		return
	var list_idx: int = sel[0]
	var real_idx: Variant = fav_list.get_item_metadata(list_idx)
	if real_idx == null or not real_idx is int:
		return
	var idx: int = real_idx as int
	if idx >= 0 and idx < _favorites.size():
		_favorites.remove_at(idx)
		_save_favorites_to_disk()
		_refresh_favorites_list()


func _on_favorite_selected(list_idx: int) -> void:
	# Map list index to real favorites index via metadata (headers are disabled)
	var real_idx: Variant = fav_list.get_item_metadata(list_idx)
	if real_idx == null or not real_idx is int:
		return
	var idx: int = real_idx as int
	if idx < 0 or idx >= _favorites.size():
		return
	var fav: Dictionary = _favorites[idx]
	_clear_organism()
	_dna = _deserialize_dna(fav.get("dna", {}))
	_spawn_from_dna()


func _refresh_favorites_list() -> void:
	if not fav_list:
		return
	fav_list.clear()

	# Sort by kingdom then name
	var sorted_indices: Array[int] = []
	for i: int in _favorites.size():
		sorted_indices.append(i)
	sorted_indices.sort_custom(func(a: int, b: int) -> bool:
		var da: Dictionary = _favorites[a].get("dna", {})
		var db: Dictionary = _favorites[b].get("dna", {})
		var ka: int = int(da.get("body_type", 0))
		var kb: int = int(db.get("body_type", 0))
		if ka != kb:
			return ka < kb
		var na: String = _favorites[a].get("name", "")
		var nb: String = _favorites[b].get("name", "")
		return na < nb
	)

	var kingdoms: Array[String] = ["Tree", "Creature", "Flower", "Fungus", "Hybrid"]
	var kingdom_colors: Array[Color] = [
		Color(0.3, 0.7, 0.2), Color(0.8, 0.4, 0.6),
		Color(0.9, 0.4, 0.4), Color(0.6, 0.4, 0.8), Color(0.9, 0.7, 0.3),
	]
	var last_kingdom: int = -1

	for idx: int in sorted_indices:
		var fav: Dictionary = _favorites[idx]
		var fname: String = fav.get("name", "???")
		var dna_data: Dictionary = fav.get("dna", {})
		var kid: int = clampi(int(dna_data.get("body_type", 0)), 0, 4)

		# Add kingdom header when category changes
		if kid != last_kingdom:
			fav_list.add_item("── %s ──" % kingdoms[kid])
			fav_list.set_item_disabled(fav_list.item_count - 1, true)
			fav_list.set_item_custom_fg_color(fav_list.item_count - 1, kingdom_colors[kid])
			last_kingdom = kid

		fav_list.add_item("  %s" % fname)
		# Store the real index as metadata so selection maps back
		fav_list.set_item_metadata(fav_list.item_count - 1, idx)


func _serialize_dna(dna: CritterDNA) -> Dictionary:
	var data: Dictionary = {}
	for group: Dictionary in GENE_GROUPS:
		var genes: Array = group["genes"] as Array
		for gene: Dictionary in genes:
			var gene_id: String = gene["id"] as String
			var val: Variant = dna.get(gene_id)
			if val != null:
				data[gene_id] = float(val)
	# Colors
	data["primary_color"] = dna.primary_color.to_html(false)
	data["secondary_color"] = dna.secondary_color.to_html(false)
	data["tertiary_color"] = dna.tertiary_color.to_html(false)
	return data


func _deserialize_dna(data: Dictionary) -> CritterDNA:
	var dna := CritterDNA.new()
	for key: String in data:
		if key.ends_with("_color"):
			dna.set(key, Color(data[key]))
		else:
			dna.set(key, float(data[key]))
	return dna


func _save_favorites_to_disk() -> void:
	var file := FileAccess.open(FAVORITES_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_favorites, "  "))
		file.close()


func _load_favorites() -> void:
	if not FileAccess.file_exists(FAVORITES_PATH):
		return
	var file := FileAccess.open(FAVORITES_PATH, FileAccess.READ)
	if not file:
		return
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Array:
		_favorites.clear()
		for item: Variant in parsed:
			if item is Dictionary:
				_favorites.append(item as Dictionary)
	_refresh_favorites_list()


func _build_info_bar() -> void:
	info_label = Label.new()
	info_label.text = "Left-click+drag: orbit | Scroll: zoom | Kingdom/Preset: spawn"
	info_label.add_theme_font_size_override("font_size", 10)
	controls.add_child(info_label)

	process_label = Label.new()
	process_label.text = "Process: — | Skeleton: — | Surface: —"
	process_label.add_theme_font_size_override("font_size", 10)
	process_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.9))
	controls.add_child(process_label)


func _build_biome_controls() -> void:
	var sep := HSeparator.new()
	controls.add_child(sep)

	var header := Label.new()
	header.text = "Biome Stage"
	header.add_theme_font_size_override("font_size", 14)
	controls.add_child(header)

	# Stage selector dropdown
	stage_selector = OptionButton.new()
	stage_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stages_dict: Dictionary = _biome_stages.get("stages", {})
	var stage_names: Array = stages_dict.keys()
	stage_names.sort()
	for i: int in stage_names.size():
		var sname: String = stage_names[i] as String
		stage_selector.add_item(sname, i)
	stage_selector.item_selected.connect(_on_stage_selected)
	controls.add_child(stage_selector)

	# Biome toggle button
	var biome_row := HBoxContainer.new()
	var biome_btn := Button.new()
	biome_btn.text = "Biome Mode"
	biome_btn.toggle_mode = true
	biome_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	biome_btn.toggled.connect(_on_biome_toggled)
	biome_row.add_child(biome_btn)

	# Stage info label — stored as class var for direct access
	stage_info_label = Label.new()
	stage_info_label.text = ""
	stage_info_label.add_theme_font_size_override("font_size", 10)
	stage_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	biome_row.add_child(stage_info_label)
	controls.add_child(biome_row)


func _build_export_button() -> void:
	var sep := HSeparator.new()
	controls.add_child(sep)

	var export_btn := Button.new()
	export_btn.text = "Export DNA to JSON"
	export_btn.pressed.connect(_export_dna)
	controls.add_child(export_btn)


func _load_biome_stages() -> void:
	var path: String = "res://commons/maps/soft_stages.json"
	if not FileAccess.file_exists(path):
		push_warning("[CreatureEditor] soft_stages.json not found at: ", path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("[CreatureEditor] Failed to open: ", path)
		return
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		_biome_stages = parsed as Dictionary
		var stage_count: int = (_biome_stages.get("stages", {}) as Dictionary).size()
		print("[CreatureEditor] Loaded %d biome stages" % stage_count)
	else:
		push_warning("[CreatureEditor] Failed to parse soft_stages.json")


func _on_stage_selected(idx: int) -> void:
	var sname: String = stage_selector.get_item_text(idx)
	_current_stage = sname

	# Update stage info label
	var stages_dict: Dictionary = _biome_stages.get("stages", {})
	if stage_info_label and stages_dict.has(sname):
		var stage: Dictionary = stages_dict[sname] as Dictionary
		var kingdoms: Array = stage.get("nature_kingdoms", [])
		var density: float = stage.get("vegetation_density", 0.0) as float
		stage_info_label.text = "Kingdoms: %s | Density: %.0f%%" % [
			", ".join(PackedStringArray(kingdoms)) if kingdoms.size() > 0 else "none",
			density * 100.0]

	# If biome mode is active, respawn the ring
	if _biome_mode:
		_spawn_biome_ring()


func _on_biome_toggled(pressed: bool) -> void:
	_biome_mode = pressed
	if pressed:
		_spawn_biome_ring()
	else:
		_clear_biome_ring()


func _spawn_biome_ring() -> void:
	_clear_biome_ring()
	var stages_dict: Dictionary = _biome_stages.get("stages", {})
	if not stages_dict.has(_current_stage):
		return

	var stage: Dictionary = stages_dict[_current_stage] as Dictionary
	var kingdoms: Array = stage.get("nature_kingdoms", [])
	var density: float = stage.get("vegetation_density", 0.0) as float

	# ── 1. Ground plane ──────────────────────────────────────────
	_biome_ground = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(10, 10)
	plane.subdivide_depth = 16
	plane.subdivide_width = 16
	_biome_ground.mesh = plane

	# Try loading the biome shader; fall back to StandardMaterial3D
	var shader_path: String = "res://commons/resourses/shaders/biome_ground.gdshader"
	var shader: Shader = null
	if ResourceLoader.exists(shader_path):
		shader = load(shader_path) as Shader
	if shader:
		var smat := ShaderMaterial.new()
		smat.shader = shader
		smat.set_shader_parameter("grid_size", Vector2(2, 2))
		smat.set_shader_parameter("grid_center", Vector2(0, 0))
		smat.set_shader_parameter("ring_width", 4.0)
		smat.set_shader_parameter("fade_width", 2.0)
		smat.set_shader_parameter("density", density)
		_biome_ground.material_override = smat
	else:
		var mat := StandardMaterial3D.new()
		# Blend grey → warm brown → green based on density
		var grey := Color(0.15, 0.15, 0.15)
		var brown := Color(0.25, 0.18, 0.12)
		var green := Color(0.15, 0.32, 0.08)
		if density < 0.5:
			mat.albedo_color = grey.lerp(brown, density * 2.0)
		else:
			mat.albedo_color = brown.lerp(green, (density - 0.5) * 2.0)
		mat.roughness = 0.9
		_biome_ground.material_override = mat

	# Apply subtle height variation via noise
	if density > 0.1:
		var noise := FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
		noise.frequency = 0.5
		noise.seed = randi()
		var amplitude: float = density * 0.08
		# Convert to ArrayMesh for MeshDataTool access
		var st := SurfaceTool.new()
		st.create_from(plane, 0)
		var array_mesh: ArrayMesh = st.commit()
		var mdt := MeshDataTool.new()
		if mdt.create_from_surface(array_mesh, 0) == OK:
			for vi in mdt.get_vertex_count():
				var v: Vector3 = mdt.get_vertex(vi)
				v.y += noise.get_noise_2d(v.x * 2.0, v.z * 2.0) * amplitude
				mdt.set_vertex(vi, v)
			var result := ArrayMesh.new()
			mdt.commit_to_surface(result)
			_biome_ground.mesh = result

	_biome_ground.position = Vector3.ZERO
	_organism_root.add_child(_biome_ground)

	# ── 2. Atmosphere ────────────────────────────────────────────
	_apply_biome_atmosphere(density)

	# ── 3. Foliage multimeshes ───────────────────────────────────
	if density > 0.0:
		_spawn_biome_foliage(kingdoms, density)

	# ── 4. Floating particles (spores/pollen) ───────────────────
	if density > 0.1:
		_spawn_biome_particles(kingdoms, density)

	# ── 5. Creature ring with glow rings + spotlights ────────────
	if kingdoms.is_empty():
		return

	var kingdom_map: Dictionary = {"tree": 0, "creature": 1, "flower": 2, "fungus": 3}
	var glow_colors: Dictionary = {
		"tree": Color(0.2, 0.8, 0.3),
		"creature": Color(0.9, 0.4, 0.6),
		"flower": Color(0.9, 0.3, 0.4),
		"fungus": Color(0.6, 0.3, 0.8),
	}
	var count: int = mini(kingdoms.size() * 2, 10)
	var radius: float = 3.0

	for i: int in count:
		var angle: float = TAU * float(i) / float(count)
		var pos := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		var kname: String = kingdoms[i % kingdoms.size()] as String
		var kid: int = kingdom_map.get(kname, 0)
		var ring_dna := CritterDNA.random_kingdom(kid)
		ring_dna.scale = randf_range(0.4, 0.8)
		var ent: CritterEntity = _spawner.spawn(ring_dna, pos, 1)
		if ent:
			ent.set_process(false)
			ent.set_physics_process(false)
			_biome_entities.append(ent)

			# Glow ring under creature (like creature_gallery)
			var glow_color: Color = glow_colors.get(kname, Color(0.5, 0.5, 0.8))
			var glow_torus := TorusMesh.new()
			glow_torus.inner_radius = 0.08 * ring_dna.scale
			glow_torus.outer_radius = 0.25 * ring_dna.scale
			glow_torus.ring_segments = 16
			glow_torus.rings = 12
			var glow_mi := MeshInstance3D.new()
			glow_mi.mesh = glow_torus
			glow_mi.position = pos + Vector3(0, 0.02, 0)
			glow_mi.rotation_degrees.x = 90  # Lay flat
			var glow_mat := StandardMaterial3D.new()
			glow_mat.albedo_color = glow_color
			glow_mat.emission_enabled = true
			glow_mat.emission = glow_color
			glow_mat.emission_energy_multiplier = 1.5
			glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			glow_mat.albedo_color.a = 0.6
			glow_mi.material_override = glow_mat
			_organism_root.add_child(glow_mi)
			_biome_foliage.append(glow_mi)  # Track for cleanup

			# Spotlight above creature
			var spot := OmniLight3D.new()
			spot.position = pos + Vector3(0, 0.6, 0)
			spot.light_energy = 0.8
			spot.omni_range = 2.0
			spot.light_color = Color(0.95, 0.9, 0.8)
			spot.omni_attenuation = 2.0
			_organism_root.add_child(spot)
			_biome_foliage.append(spot)  # Track for cleanup


func _apply_biome_atmosphere(density: float) -> void:
	if not _world_env or not _world_env.environment:
		return

	var env: Environment = _world_env.environment

	# Save original settings on first call
	if _biome_env_original.is_empty():
		_biome_env_original = {
			"bg_color": env.background_color,
			"ambient_color": env.ambient_light_color,
			"ambient_energy": env.ambient_light_energy,
			"fog_enabled": env.fog_enabled,
		}

	# Interpolate atmosphere based on density
	# density 0.0 → lab feel, 1.0 → deep forest
	var bg_a := Color(0.1, 0.1, 0.13)
	var bg_b := Color(0.03, 0.06, 0.04)
	var amb_a := Color(0.5, 0.5, 0.55)
	var amb_b := Color(0.35, 0.6, 0.55)
	var energy_a: float = 0.6
	var energy_b: float = 0.8

	env.background_color = bg_a.lerp(bg_b, density)
	env.ambient_light_color = amb_a.lerp(amb_b, density)
	env.ambient_light_energy = lerpf(energy_a, energy_b, density)

	# Fog when density > 0.2
	if density > 0.2:
		env.fog_enabled = true
		env.fog_density = density * 0.015
		env.fog_light_color = env.ambient_light_color
	else:
		env.fog_enabled = false


func _restore_biome_atmosphere() -> void:
	if _biome_env_original.is_empty():
		return
	if not _world_env or not _world_env.environment:
		return
	var env: Environment = _world_env.environment
	env.background_color = _biome_env_original.get("bg_color", Color(0.1, 0.1, 0.13))
	env.ambient_light_color = _biome_env_original.get("ambient_color", Color(0.5, 0.5, 0.55))
	env.ambient_light_energy = _biome_env_original.get("ambient_energy", 0.6)
	env.fog_enabled = _biome_env_original.get("fog_enabled", false)
	_biome_env_original.clear()


func _spawn_biome_foliage(kingdoms: Array, density: float) -> void:
	var scale_factor: float = clampf(density, 0.1, 1.0)

	# Always add grass if density > 0
	_add_foliage_multimesh("grass", int(lerpf(30.0, 60.0, density)), scale_factor)

	for kname: Variant in kingdoms:
		var k: String = str(kname)
		match k:
			"flower":
				_add_foliage_multimesh("flower", int(lerpf(20.0, 40.0, density)), scale_factor)
			"tree":
				_add_foliage_multimesh("tree", int(lerpf(5.0, 10.0, density)), scale_factor)
			"fungus":
				_add_foliage_multimesh("fungus", int(lerpf(10.0, 20.0, density)), scale_factor)


func _add_foliage_multimesh(kind: String, count: int, scale_factor: float) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = count

	# ── Better mesh shapes per kingdom ──────────────────────────
	var mesh: Mesh = null
	var base_color := Color.WHITE
	var emission_color := Color.BLACK
	var emission_energy: float = 0.0
	var y_offset: float = 0.0

	match kind:
		"grass":
			# Crossed quads for volume (X pattern)
			var quad := QuadMesh.new()
			quad.size = Vector2(0.07, 0.18)
			mesh = quad
			base_color = Color(0.2, 0.55, 0.1)
			emission_color = Color(0.05, 0.1, 0.03)
			emission_energy = 0.15
			y_offset = 0.09
		"flower":
			# Sphere head on tiny stem
			var sphere := SphereMesh.new()
			sphere.radius = 0.045
			sphere.height = 0.09
			sphere.radial_segments = 6
			sphere.rings = 4
			mesh = sphere
			base_color = Color(0.9, 0.35, 0.45)
			emission_color = Color(0.2, 0.1, 0.05)
			emission_energy = 0.3
			y_offset = 0.12  # Raised for stem
		"tree":
			# Trunk + canopy composite (use cylinder for trunk, rendered small)
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.2
			cyl.bottom_radius = 0.04
			cyl.height = 0.6
			cyl.radial_segments = 6
			mesh = cyl
			base_color = Color(0.18, 0.5, 0.15)
			emission_color = Color(0.1, 0.15, 0.05)
			emission_energy = 0.3
			y_offset = 0.3
		"fungus":
			# Mushroom cap shape: wide top, thin stem
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.12
			cyl.bottom_radius = 0.025
			cyl.height = 0.14
			cyl.radial_segments = 8
			mesh = cyl
			base_color = Color(0.55, 0.3, 0.65)
			emission_color = Color(0.15, 0.1, 0.2)
			emission_energy = 0.4  # Bioluminescent!
			y_offset = 0.07

	if not mesh:
		return

	# ── Material with glow emission ─────────────────────────────
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.8
	if kind == "grass":
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Add subtle glow
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission_color
		mat.emission_energy_multiplier = emission_energy

	mm.mesh = mesh

	# ── Parabolic density clustering ────────────────────────────
	# Dense at 60% of ring, sparse at center and edge
	for i: int in count:
		var angle: float = randf() * TAU
		# Parabolic distribution: peak at ~2.5m (60% of 4.0)
		var t: float = randf()
		var density_curve: float = 4.0 * t * (1.0 - t)  # Peaks at t=0.5
		var r: float = lerpf(0.8, 4.5, t) * density_curve / 1.0 + 0.8
		r = clampf(r, 0.8, 4.5)
		# Y jitter so foliage sits "in" the ground
		var y_jitter: float = randf_range(-0.02, 0.01)
		var pos := Vector3(cos(angle) * r, y_offset + y_jitter, sin(angle) * r)
		var sc: float = randf_range(0.5, 1.3) * scale_factor
		var rot_y: float = randf() * TAU
		var xf := Transform3D(Basis.IDENTITY.rotated(Vector3.UP, rot_y).scaled(Vector3(sc, sc, sc)), pos)
		mm.set_instance_transform(i, xf)
		# Color variation: hue ±0.06, saturation ±0.1, value ±0.1
		var c := base_color
		var hsv_h: float = fmod(c.h + randf_range(-0.06, 0.06) + 1.0, 1.0)
		var hsv_s: float = clampf(c.s + randf_range(-0.1, 0.1), 0.1, 1.0)
		var hsv_v: float = clampf(c.v + randf_range(-0.1, 0.1), 0.2, 1.0)
		mm.set_instance_color(i, Color.from_hsv(hsv_h, hsv_s, hsv_v))

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	_organism_root.add_child(mmi)
	_biome_foliage.append(mmi)


func _spawn_biome_particles(kingdoms: Array, density: float) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "BiomeParticles"
	particles.amount = clampi(int(density * 25.0), 5, 30)
	particles.lifetime = 4.0
	particles.speed_scale = 0.8
	particles.visibility_aabb = AABB(Vector3(-4, -1, -4), Vector3(8, 3, 8))

	# Particle material
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)  # Drift upward
	pmat.spread = 30.0
	pmat.initial_velocity_min = 0.03
	pmat.initial_velocity_max = 0.08
	pmat.gravity = Vector3(0, -0.01, 0)  # Very slight float
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pmat.emission_box_extents = Vector3(3.0, 0.3, 3.0)
	pmat.scale_min = 0.8
	pmat.scale_max = 1.5

	# Color by dominant kingdom
	var particle_color := Color(0.7, 0.8, 0.6, 0.6)  # Default green-ish
	if kingdoms.size() > 0:
		var k: String = kingdoms[0] as String
		match k:
			"flower": particle_color = Color(0.9, 0.7, 0.5, 0.5)
			"fungus": particle_color = Color(0.7, 0.5, 0.85, 0.5)
			"creature": particle_color = Color(0.8, 0.65, 0.5, 0.4)
			"tree": particle_color = Color(0.5, 0.75, 0.4, 0.5)
	pmat.color = particle_color

	particles.process_material = pmat
	particles.position = Vector3(0, 0.5, 0)

	# Particle mesh: tiny quad
	var quad := QuadMesh.new()
	quad.size = Vector2(0.015, 0.015)
	particles.draw_pass_1 = quad

	# Particle material (visual)
	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = particle_color
	draw_mat.emission_enabled = true
	draw_mat.emission = particle_color
	draw_mat.emission_energy_multiplier = 0.5
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	particles.material_override = draw_mat

	_organism_root.add_child(particles)
	_biome_foliage.append(particles)  # Track for cleanup


func _clear_biome_ring() -> void:
	# Clear creature entities
	for ent: Variant in _biome_entities:
		if ent is Node and is_instance_valid(ent as Node):
			(ent as Node).queue_free()
	_biome_entities.clear()

	# Clear ground plane
	if _biome_ground and is_instance_valid(_biome_ground):
		_biome_ground.queue_free()
	_biome_ground = null

	# Clear foliage multimeshes
	for mmi: Variant in _biome_foliage:
		if mmi is Node and is_instance_valid(mmi as Node):
			(mmi as Node).queue_free()
	_biome_foliage.clear()

	# Restore atmosphere
	_restore_biome_atmosphere()


func _export_dna() -> void:
	if not _dna:
		return

	# Ensure directory exists
	var dir_path: String = "user://creature_snapshots"
	DirAccess.make_dir_recursive_absolute(dir_path)

	# Build export data
	var data: Dictionary = _serialize_dna(_dna)
	data["export_time"] = Time.get_datetime_string_from_system()
	data["auto_name"] = _auto_name_from_dna(_dna)

	# Process taxonomy
	var fp_idx: int = clampi(int(_dna.form_process * 10.0), 0, PROCESS_LABELS.size() - 1)
	data["form_taxonomy"] = PROCESS_LABELS[fp_idx]
	data["biome_stage"] = _current_stage

	# Save as JSON
	var timestamp: String = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var filename: String = "%s/%s.json" % [dir_path, timestamp]
	var file := FileAccess.open(filename, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "  "))
		file.close()
		print("[CreatureEditor] Exported DNA to: ", filename)
		_play_save_sound()


# ═══════════════════════════════════════════════════════════════
# ORGANISM MANAGEMENT
# ═══════════════════════════════════════════════════════════════

func _spawn_new(kingdom: int) -> void:
	_clear_organism()
	if kingdom == 5:
		# Pipeline mode — force MorphoPipeline route
		_dna = CritterDNA.random()
		_dna.body_type = 5.0
		_dna.form_process = randf_range(0.0, 1.0)
		_dna.skeleton_complexity = randf_range(0.0, 1.0)
		_dna.surface_method = randf_range(0.0, 1.0)
		_dna.modularity = randf_range(0.0, 1.0)
		_dna.recursion_depth = randf_range(0.0, 0.6)
	elif kingdom == 4:
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
	var kingdoms: Array[String] = ["Tree", "Creature", "Flower", "Fungus", "Hybrid", "Pipeline"]
	var kid: int = int(round(_dna.body_type))
	var kname: String = kingdoms[clampi(kid, 0, 5)]
	info_label.text = "%s | seg=%.0f sym=%.0f scale=%.1f" % [
		kname, _dna.segments, _dna.symmetry, _dna.scale]

	# Update process taxonomy label
	if process_label:
		var fp_idx: int = clampi(int(_dna.form_process * 10.0), 0, PROCESS_LABELS.size() - 1)
		var sk_idx: int = clampi(int(_dna.skeleton_complexity * 10.0), 0, SKELETON_LABELS.size() - 1)
		var sf_idx: int = clampi(int(_dna.surface_method * 10.0), 0, SURFACE_LABELS.size() - 1)
		process_label.text = "Process: %s | Skeleton: %s | Surface: %s" % [
			PROCESS_LABELS[fp_idx], SKELETON_LABELS[sk_idx], SURFACE_LABELS[sf_idx]]


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
