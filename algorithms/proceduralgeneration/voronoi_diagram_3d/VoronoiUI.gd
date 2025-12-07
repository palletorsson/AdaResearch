extends Control

@onready var voronoi_node = $"../../VoronoiDiagram3D"
@onready var resolution_slider = $Panel/VBoxContainer/ResolutionSlider
@onready var seeds_slider = $Panel/VBoxContainer/NumSeedsSlider
@onready var mode_option = $Panel/VBoxContainer/ModeOption
@onready var render_option = $Panel/VBoxContainer/RenderOption
@onready var regenerate_btn = $Panel/VBoxContainer/RegenerateButton
@onready var stats_label = $Panel/VBoxContainer/StatsLabel
@onready var show_seeds_check = $Panel/VBoxContainer/ShowSeedsCheck
@onready var smooth_normals_check = $Panel/VBoxContainer/SmoothNormalsCheck

func _ready():
	_update_ui()
	_update_stats()

func _update_ui():
	if not voronoi_node: return
	resolution_slider.value = voronoi_node.resolution
	seeds_slider.value = voronoi_node.num_seeds
	mode_option.selected = voronoi_node.seed_distribution
	render_option.selected = voronoi_node.render_mode
	show_seeds_check.button_pressed = voronoi_node.show_seeds
	smooth_normals_check.button_pressed = voronoi_node.smooth_normals

func _on_regenerate_pressed():
	voronoi_node.generate_voronoi()
	_update_stats()

func _update_stats():
	if voronoi_node:
		stats_label.text = "Cells: %d" % voronoi_node.voronoi_cells.size()

func _on_resolution_changed(value):
	voronoi_node.resolution = int(value)
	$Panel/VBoxContainer/ResolutionLabel.text = "Resolution: %d" % int(value)
	# Don't regenerate immediately on slider drag for resolution as it's heavy

func _on_num_seeds_changed(value):
	voronoi_node.num_seeds = int(value)
	$Panel/VBoxContainer/NumSeedsLabel.text = "Seeds: %d" % int(value)

func _on_mode_selected(index):
	voronoi_node.seed_distribution = index
	voronoi_node.generate_voronoi()

func _on_render_mode_selected(index):
	voronoi_node.render_mode = index
	voronoi_node.visualize_samples()

func _on_show_seeds_toggled(button_pressed):
	voronoi_node.show_seeds = button_pressed
	voronoi_node.visualize_samples()

func _on_smooth_normals_toggled(button_pressed):
	voronoi_node.smooth_normals = button_pressed
	voronoi_node.visualize_samples()

func _on_resolution_drag_ended(value_changed):
	if value_changed:
		voronoi_node.generate_voronoi()

func _on_num_seeds_drag_ended(value_changed):
	if value_changed:
		voronoi_node.generate_voronoi()
