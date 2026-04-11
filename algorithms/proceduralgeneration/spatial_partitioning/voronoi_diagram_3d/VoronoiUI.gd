extends Node3D

const SliderScene = preload("res://commons/interactables/slider_horizontal.tscn")
const ButtonScene = preload("res://commons/interactables/push_button.tscn")

var voronoi_node: Node = null
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

	# Stats label
	stats_label = Label3D.new()
	stats_label.position = Vector3(0, 0.5, 0)
	stats_label.font_size = 32
	stats_label.text = "Voronoi Diagram 3D"
	add_child(stats_label)

	# Resolution slider
	resolution_slider = SliderScene.instantiate()
	resolution_slider.position = Vector3(0, 0.3, 0)
	add_child(resolution_slider)
	resolution_slider.set_param_name("Resolution")
	resolution_slider.set_normalized_value(0.5)
	resolution_slider.slider_moved.connect(_on_resolution_slider_moved)

	# Seeds slider
	seeds_slider = SliderScene.instantiate()
	seeds_slider.position = Vector3(0, 0.18, 0)
	add_child(seeds_slider)
	seeds_slider.set_param_name("Num Seeds")
	seeds_slider.set_normalized_value(0.5)
	seeds_slider.slider_moved.connect(_on_seeds_slider_moved)

	# Mode cycle label + button
	mode_label = Label3D.new()
	mode_label.position = Vector3(-0.25, 0.06, 0)
	mode_label.font_size = 24
	mode_label.text = "Dist: %s" % mode_names[mode_index]
	add_child(mode_label)

	var mode_btn = ButtonScene.instantiate()
	mode_btn.position = Vector3(0.25, 0.06, 0)
	add_child(mode_btn)
	var mode_area = mode_btn.get_node_or_null("InteractableAreaButton")
	if mode_area:
		mode_area.button_pressed.connect(_on_mode_next)

	# Render mode cycle label + button
	render_label = Label3D.new()
	render_label.position = Vector3(-0.25, -0.06, 0)
	render_label.font_size = 24
	render_label.text = "Render: %s" % render_names[render_index]
	add_child(render_label)

	var render_btn = ButtonScene.instantiate()
	render_btn.position = Vector3(0.25, -0.06, 0)
	add_child(render_btn)
	var render_area = render_btn.get_node_or_null("InteractableAreaButton")
	if render_area:
		render_area.button_pressed.connect(_on_render_next)

	# Show Seeds toggle button
	var seeds_btn = ButtonScene.instantiate()
	seeds_btn.position = Vector3(-0.15, -0.18, 0)
	add_child(seeds_btn)
	var seeds_area = seeds_btn.get_node_or_null("InteractableAreaButton")
	if seeds_area:
		seeds_area.button_pressed.connect(_on_show_seeds_pressed)
	var seeds_lbl = Label3D.new()
	seeds_lbl.position = Vector3(-0.15, -0.24, 0)
	seeds_lbl.font_size = 20
	seeds_lbl.text = "Show Seeds"
	add_child(seeds_lbl)

	# Smooth Normals toggle button
	var smooth_btn = ButtonScene.instantiate()
	smooth_btn.position = Vector3(0.15, -0.18, 0)
	add_child(smooth_btn)
	var smooth_area = smooth_btn.get_node_or_null("InteractableAreaButton")
	if smooth_area:
		smooth_area.button_pressed.connect(_on_smooth_normals_pressed)
	var smooth_lbl = Label3D.new()
	smooth_lbl.position = Vector3(0.15, -0.24, 0)
	smooth_lbl.font_size = 20
	smooth_lbl.text = "Smooth Normals"
	add_child(smooth_lbl)

	# Regenerate button
	var regen_btn = ButtonScene.instantiate()
	regen_btn.position = Vector3(0, -0.36, 0)
	add_child(regen_btn)
	var regen_area = regen_btn.get_node_or_null("InteractableAreaButton")
	if regen_area:
		regen_area.button_pressed.connect(_on_regenerate_pressed)
	var regen_lbl = Label3D.new()
	regen_lbl.position = Vector3(0, -0.42, 0)
	regen_lbl.font_size = 20
	regen_lbl.text = "Regenerate"
	add_child(regen_lbl)

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
