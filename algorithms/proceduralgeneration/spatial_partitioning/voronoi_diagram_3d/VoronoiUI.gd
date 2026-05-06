extends Node3D

var voronoi_node: Node = null
var _control_panel: Node3D
var resolution_slider: Node = null
var seeds_slider: Node = null
var stats_label: Label3D = null
var mode_label: Label3D = null
var render_label: Label3D = null

var show_seeds := true
var smooth_normals := false

var mode_index := 0
var mode_names := ["Random", "Grid", "Poisson", "Clustered"]
var render_index := 0
var render_names := ["Solid", "Wireframe", "Points", "Transparent"]

func _ready() -> void:
	voronoi_node = get_node_or_null("../../VoronoiDiagram3D")

	# Stats label above panel
	stats_label = Label3D.new()
	stats_label.position = Vector3(0, 0.5, 0)
	stats_label.font_size = 32
	stats_label.text = "Voronoi Diagram 3D"
	add_child(stats_label)

	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("VORONOI 3D", [
		[
			{"type": "slider_h", "label": "RESOLUTION", "default": 0.5},
			{"type": "slider_h", "label": "SEEDS", "default": 0.5},
		],
		[
			{"type": "button", "label": "DIST MODE"},
			{"type": "button", "label": "RENDER"},
		],
		[
			{"type": "button", "label": "SHOW SEEDS"},
			{"type": "button", "label": "SMOOTH"},
			{"type": "button", "label": "REGEN"},
		],
	])
	_control_panel.position = Vector3(0, 0.25, 0)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	resolution_slider = _control_panel.find_child("Param_0", true, false)
	seeds_slider = _control_panel.find_child("Param_1", true, false)

	if resolution_slider:
		resolution_slider.slider_moved.connect(_on_resolution_slider_moved)
	if seeds_slider:
		seeds_slider.slider_moved.connect(_on_seeds_slider_moved)

	# Mode label
	mode_label = Label3D.new()
	mode_label.position = Vector3(-0.15, 0.12, 0)
	mode_label.font_size = 20
	mode_label.text = "Dist: %s" % mode_names[mode_index]
	add_child(mode_label)

	# Render label
	render_label = Label3D.new()
	render_label.position = Vector3(0.15, 0.12, 0)
	render_label.font_size = 20
	render_label.text = "Render: %s" % render_names[render_index]
	add_child(render_label)

	var mode_btn = _control_panel.find_child("Btn_0", true, false)
	if mode_btn:
		var area = mode_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_mode_next())

	var render_btn = _control_panel.find_child("Btn_1", true, false)
	if render_btn:
		var area = render_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_render_next())

	var seeds_btn = _control_panel.find_child("Btn_2", true, false)
	if seeds_btn:
		var area = seeds_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_show_seeds_pressed())

	var smooth_btn = _control_panel.find_child("Btn_3", true, false)
	if smooth_btn:
		var area = smooth_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_smooth_normals_pressed())

	var regen_btn = _control_panel.find_child("Btn_4", true, false)
	if regen_btn:
		var area = regen_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_regenerate_pressed())

	_update_stats()

func _on_resolution_slider_moved(_name: String, value: float) -> void:
	if not voronoi_node: return
	voronoi_node.resolution = int(lerp(4.0, 64.0, value))

func _on_seeds_slider_moved(_name: String, value: float) -> void:
	if not voronoi_node: return
	voronoi_node.num_seeds = int(lerp(2.0, 100.0, value))

func _on_mode_next() -> void:
	mode_index = (mode_index + 1) % mode_names.size()
	if mode_label:
		mode_label.text = "Dist: %s" % mode_names[mode_index]
	if voronoi_node:
		voronoi_node.seed_distribution = mode_index
		voronoi_node.generate_voronoi()
		_update_stats()

func _on_render_next() -> void:
	render_index = (render_index + 1) % render_names.size()
	if render_label:
		render_label.text = "Render: %s" % render_names[render_index]
	if voronoi_node:
		voronoi_node.render_mode = render_index
		voronoi_node.visualize_samples()

func _on_show_seeds_pressed() -> void:
	show_seeds = !show_seeds
	if voronoi_node:
		voronoi_node.show_seeds = show_seeds
		voronoi_node.visualize_samples()

func _on_smooth_normals_pressed() -> void:
	smooth_normals = !smooth_normals
	if voronoi_node:
		voronoi_node.smooth_normals = smooth_normals
		voronoi_node.visualize_samples()

func _on_regenerate_pressed() -> void:
	if voronoi_node:
		voronoi_node.generate_voronoi()
		_update_stats()

func _update_stats() -> void:
	if voronoi_node and stats_label:
		stats_label.text = "Cells: %d" % voronoi_node.voronoi_cells.size()

func _exit_tree() -> void:
	voronoi_node = null

func apply_grid_config(config: Dictionary) -> void:
	pass
