# editor_launcher.gd — Menu to choose and launch any geometry editor
#
# Shows a grid of buttons organized by the 5-stage Form Decomposition.
# Click any button → loads that editor scene in-place.
# Press Escape or click "Back" → returns to the menu.
#
# Run this scene as main: res://commons/scenes/editors/editor_launcher.tscn

extends Control

const EDITORS: Array[Dictionary] = [
	# ── FIELD ──────────────────────────────────────────────
	{"name": "Noise Terrain", "scene": "res://commons/scenes/editors/noise_terrain_editor.tscn",
	 "stage": "Field", "desc": "Perlin noise heightfield", "color": Color(0.13, 0.72, 0.93)},
	{"name": "Cellular Automata 3D", "scene": "res://commons/scenes/editors/ca_form_editor.tscn",
	 "stage": "Field", "desc": "Birth/survive rules → voxel form", "color": Color(0.13, 0.72, 0.93)},
	{"name": "Reaction-Diffusion", "scene": "res://commons/scenes/editors/reaction_diffusion_editor.tscn",
	 "stage": "Field", "desc": "Gray-Scott → coral, spots, maze", "color": Color(0.13, 0.72, 0.93)},
	{"name": "SDF Sculpture", "scene": "res://commons/scenes/editors/sculpture_editor.tscn",
	 "stage": "Field", "desc": "Distance functions → organic form", "color": Color(0.13, 0.72, 0.93)},

	# ── SKELETON ───────────────────────────────────────────
	{"name": "Growth", "scene": "res://commons/scenes/editors/growth_editor.tscn",
	 "stage": "Skeleton", "desc": "Space colonization branching", "color": Color(0.65, 0.55, 0.98)},

	# ── SURFACE ────────────────────────────────────────────
	{"name": "Parametric Surfaces", "scene": "res://commons/scenes/editors/parametric_surface_editor.tscn",
	 "stage": "Surface", "desc": "14 real math objects (Dini, Klein...)", "color": Color(0.96, 0.62, 0.04)},
	{"name": "Mesh Grammar", "scene": "res://commons/scenes/editors/mesh_grammar_editor.tscn",
	 "stage": "Surface", "desc": "Inset, extrude, bulge operations", "color": Color(0.96, 0.62, 0.04)},
	{"name": "Procedural Columns", "scene": "res://commons/scenes/editors/procedural_columns_editor.tscn",
	 "stage": "Surface", "desc": "Lathe profiles → architecture", "color": Color(0.96, 0.62, 0.04)},
	{"name": "Boolean CSG", "scene": "res://commons/scenes/editors/boolean_editor.tscn",
	 "stage": "Surface", "desc": "Union, subtract, intersect", "color": Color(0.96, 0.62, 0.04)},
	{"name": "Glass Tubes", "scene": "res://commons/scenes/editors/glass_tube_editor.tscn",
	 "stage": "Surface", "desc": "Frenet frame tube sweep", "color": Color(0.96, 0.62, 0.04)},
	{"name": "Sine / Math", "scene": "res://commons/scenes/editors/sine_object_editor.tscn",
	 "stage": "Surface", "desc": "Mobius, torus knot, Klein bottle", "color": Color(0.96, 0.62, 0.04)},

	# ── MODIFY ─────────────────────────────────────────────
	{"name": "Mesh Modifier", "scene": "res://commons/scenes/editors/morpho_modifier_editor.tscn",
	 "stage": "Modify", "desc": "Taper, twist, bend, noise, wave", "color": Color(0.93, 0.26, 0.6)},
	{"name": "Cloth Physics", "scene": "res://commons/scenes/editors/cloth_editor.tscn",
	 "stage": "Modify", "desc": "Spring-mass drape simulation", "color": Color(0.93, 0.26, 0.6)},

	# ── POPULATE ───────────────────────────────────────────
	{"name": "Floor Patterns", "scene": "res://commons/scenes/editors/floor_pattern_editor.tscn",
	 "stage": "Populate", "desc": "10 Pompeii mosaic tilings", "color": Color(0.29, 0.87, 0.56)},
	{"name": "Wave Function Collapse", "scene": "res://commons/scenes/editors/wfc_editor.tscn",
	 "stage": "Populate", "desc": "Constraint-based tile layout", "color": Color(0.29, 0.87, 0.56)},

	# ── PIPELINE ───────────────────────────────────────────
	{"name": "Pipeline Combiner", "scene": "res://commons/scenes/editors/pipeline_combiner_editor.tscn",
	 "stage": "Pipeline", "desc": "Field→Skeleton→Surface→Modify→Populate", "color": Color(1.0, 1.0, 1.0)},
	{"name": "Morpho Pipeline", "scene": "res://commons/scenes/editors/morpho_pipeline_editor.tscn",
	 "stage": "Pipeline", "desc": "DNA-driven skeleton→surface→instance", "color": Color(1.0, 1.0, 1.0)},

	# ── ORGANISM ───────────────────────────────────────────
	{"name": "Creature Editor", "scene": "res://commons/scenes/creature_editor/creature_editor.tscn",
	 "stage": "Organism", "desc": "55+ DNA genes, biome preview", "color": Color(0.93, 0.46, 0.14)},
]

const STAGE_ORDER: Array[String] = ["Field", "Skeleton", "Surface", "Modify", "Populate", "Pipeline", "Organism"]
const STAGE_DESCRIPTIONS: Dictionary = {
	"Field": "Define a value everywhere in space",
	"Skeleton": "Define a path through space",
	"Surface": "Extract or create a boundary",
	"Modify": "Deform the boundary",
	"Populate": "Duplicate the result",
	"Pipeline": "Combine all stages",
	"Organism": "DNA-driven morphology",
}

var _current_editor: Node = null


func _ready() -> void:
	_build_menu()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed:
		if (event as InputEventKey).keycode == KEY_ESCAPE and _current_editor:
			_return_to_menu()


func _build_menu() -> void:
	# Clear
	for child in get_children():
		child.queue_free()

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Scroll container
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	add_child(scroll)

	var main_vbox := VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(main_vbox)

	# Title
	var title := Label.new()
	title.text = "Geometry Editor Suite"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "18 editors exploring every approach to making form"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	main_vbox.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	main_vbox.add_child(spacer)

	# Pipeline diagram
	var pipeline_row := HBoxContainer.new()
	pipeline_row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i: int in 5:
		var stage_name: String = STAGE_ORDER[i]
		var stage_colors: Array[Color] = [
			Color(0.13, 0.72, 0.93), Color(0.65, 0.55, 0.98),
			Color(0.96, 0.62, 0.04), Color(0.93, 0.26, 0.6),
			Color(0.29, 0.87, 0.56),
		]
		var plbl := Label.new()
		plbl.text = stage_name
		plbl.add_theme_font_size_override("font_size", 11)
		plbl.add_theme_color_override("font_color", stage_colors[i])
		pipeline_row.add_child(plbl)
		if i < 4:
			var arrow := Label.new()
			arrow.text = "  →  "
			arrow.add_theme_font_size_override("font_size", 11)
			arrow.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
			pipeline_row.add_child(arrow)
	main_vbox.add_child(pipeline_row)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 16)
	main_vbox.add_child(spacer2)

	# Group editors by stage
	for stage: String in STAGE_ORDER:
		var stage_editors: Array[Dictionary] = []
		for ed: Dictionary in EDITORS:
			if ed["stage"] == stage:
				stage_editors.append(ed)
		if stage_editors.is_empty():
			continue

		# Stage header
		var header_row := HBoxContainer.new()
		var header_lbl := Label.new()
		header_lbl.text = stage.to_upper()
		header_lbl.add_theme_font_size_override("font_size", 14)
		header_lbl.add_theme_color_override("font_color", stage_editors[0]["color"] as Color)
		header_row.add_child(header_lbl)

		var header_desc := Label.new()
		header_desc.text = "  —  %s" % STAGE_DESCRIPTIONS.get(stage, "")
		header_desc.add_theme_font_size_override("font_size", 11)
		header_desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		header_row.add_child(header_desc)
		main_vbox.add_child(header_row)

		# Button grid
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 6)

		for ed: Dictionary in stage_editors:
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(280, 50)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			# Build rich text for button
			btn.text = "%s\n%s" % [ed["name"] as String, ed["desc"] as String]
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.add_theme_font_size_override("font_size", 12)
			btn.pressed.connect(_launch_editor.bind(ed["scene"] as String))
			grid.add_child(btn)

		main_vbox.add_child(grid)

		var stage_spacer := Control.new()
		stage_spacer.custom_minimum_size = Vector2(0, 10)
		main_vbox.add_child(stage_spacer)


func _launch_editor(scene_path: String) -> void:
	# Hide menu, load editor scene
	for child in get_children():
		child.visible = false

	var scene: PackedScene = load(scene_path) as PackedScene
	if not scene:
		push_warning("[EditorLauncher] Failed to load: ", scene_path)
		_return_to_menu()
		return

	_current_editor = scene.instantiate()
	add_child(_current_editor)

	# Add back button overlay
	var back_btn := Button.new()
	back_btn.text = "← Back (Esc)"
	back_btn.position = Vector2(8, 8)
	back_btn.size = Vector2(100, 30)
	back_btn.z_index = 100
	back_btn.add_theme_font_size_override("font_size", 11)
	back_btn.pressed.connect(_return_to_menu)
	back_btn.name = "BackButton"
	add_child(back_btn)


func _return_to_menu() -> void:
	if _current_editor and is_instance_valid(_current_editor):
		_current_editor.queue_free()
		_current_editor = null

	var back_btn: Node = get_node_or_null("BackButton")
	if back_btn:
		back_btn.queue_free()

	# Show menu again
	for child in get_children():
		child.visible = true

	# If menu was cleared, rebuild
	var has_menu: bool = false
	for child in get_children():
		if child is ScrollContainer:
			has_menu = true
			break
	if not has_menu:
		_build_menu()
