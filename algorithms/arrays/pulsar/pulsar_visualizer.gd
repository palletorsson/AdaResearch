# pulsar_visualizer.gd - Combined Pulsar Visualization
# Shows binary table + glass tubes + educational info

# @identity
# essence: real pulsar radio signal data (B1919+21) → binary threshold at 0.25 → 2D array of 0s and 1s displayed as both a grid of numbers and a 3D glass bar chart — the same dataset rendered twice in two representational languages
# desire: to discover that Jocelyn Bell Burnell's pulsar discovery was a 2D array printed on a chart — to stand beside a radio signal visualized as glass tubes and understand that cosmic events are just arrays of numbers measured over time
# critical_parameter: the threshold (0.25 in PulsarData.get_binary_pulsar_sample) — above this value the signal is 1, below it is 0; changing it would alter what counts as a "pulse" and reveals that binary representation requires a decision about where to draw the line
# triggers: the glass tubes in pulsar_glass_tubes render signal amplitude as height — a tall tube means strong radio signal at that moment; the binary table beside it shows the same data after thresholding, making information loss from digitization visible
# emerges: students realize that the same phenomenon (pulsing neutron star) looks completely different in analogue (tube heights) vs digital (binary table) representation — and that arrays are always a choice about which values to keep
# needs: BinaryTableDisplay [has]; PulsarGlassTubes [has]; info panel with Label3D [has]; no VR interactive controls [missing]; apply_grid_config supports table_rows/cols/show_info [has]
# relationships: uses PulsarData static class for signal generation; pairs with pulsar_compact (glass tubes only, compact form); appears in Tutorial_2D_Build alongside grid_2d_4x4 to show arrays as measurement
# truth: the first discovered pulsar was initially called LGM-1 (Little Green Men) because the signal's regularity seemed artificial — arrays make the cosmic seem engineered, and engineered arrays can make data seem natural

extends Node3D
class_name PulsarVisualizer

@export var table_rows: int = 16
@export var table_cols: int = 20
@export var show_info_panel: bool = true

# Child references
var _binary_table: Node3D
var _glass_tubes: Node3D
var _info_panel: Node3D
var _title_label: Label3D

func _ready() -> void:
	_create_visualization()

func _create_visualization() -> void:
	# Create title
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "PULSAR B1919+21"
	_title_label.font_size = 64
	_title_label.pixel_size = 0.002
	_title_label.position = Vector3(0, 0.5, -0.5)
	_title_label.modulate = Color(0.9, 0.95, 1.0)
	_title_label.outline_size = 0
	add_child(_title_label)

	# Subtitle
	var subtitle = Label3D.new()
	subtitle.name = "SubtitleLabel"
	subtitle.text = "Arrays as Radio Waves"
	subtitle.font_size = 32
	subtitle.pixel_size = 0.002
	subtitle.position = Vector3(0, 0.42, -0.5)
	subtitle.modulate = Color(0.7, 0.75, 0.85)
	subtitle.outline_size = 0
	add_child(subtitle)

	# Create binary table (left side)
	_create_binary_table()

	# Create glass tubes (right side)
	_create_glass_tubes()

	# Create info panel (below)
	if show_info_panel:
		_create_info_panel()

func _create_binary_table() -> void:
	var table_scene = preload("res://algorithms/arrays/binary_table/binary_table_display.tscn")
	_binary_table = table_scene.instantiate()
	_binary_table.name = "BinaryTable"
	_binary_table.position = Vector3(-0.6, 0.15, 0)
	_binary_table.rotation_degrees = Vector3(0, 15, 0)

	# Configure table
	_binary_table.rows = table_rows
	_binary_table.cols = table_cols
	_binary_table.title = "Binary Data (threshold=0.25)"
	_binary_table.cell_size = 0.04
	_binary_table.font_size = 16

	# Set pulsar data
	var binary_data = PulsarData.get_binary_pulsar_sample(table_rows, table_cols, 0.25)
	_binary_table.data = binary_data

	add_child(_binary_table)

func _create_glass_tubes() -> void:
	var tubes_scene = preload("res://algorithms/arrays/pulsar/pulsar_glass_tubes.tscn")
	_glass_tubes = tubes_scene.instantiate()
	_glass_tubes.name = "GlassTubes"
	_glass_tubes.position = Vector3(0.5, 0, 0)
	_glass_tubes.rotation_degrees = Vector3(0, -15, 0)

	# Configure tubes
	_glass_tubes.rows_to_show = 40
	_glass_tubes.cols_per_row = 50
	_glass_tubes.max_height = 0.25

	add_child(_glass_tubes)

func _create_info_panel() -> void:
	_info_panel = Node3D.new()
	_info_panel.name = "InfoPanel"
	_info_panel.position = Vector3(0, -0.2, 0.2)

	var info = PulsarData.get_pulsar_info()

	# Background
	var bg = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(1.2, 0.25)
	bg.mesh = quad
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.08, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	bg.material_override = mat
	_info_panel.add_child(bg)

	# Info text
	var info_text = Label3D.new()
	info_text.name = "InfoText"
	info_text.text = "Discovered: %s by %s | Period: %s | Distance: %s" % [
		info["discovered"], info["discoverer"], info["period"], info["distance"]
	]
	info_text.font_size = 20
	info_text.pixel_size = 0.002
	info_text.position = Vector3(0, 0.04, 0.01)
	info_text.modulate = Color(0.8, 0.85, 0.9)
	info_text.outline_size = 0
	_info_panel.add_child(info_text)

	# Cultural note
	var cultural_text = Label3D.new()
	cultural_text.name = "CulturalText"
	cultural_text.text = info["cultural_note"]
	cultural_text.font_size = 16
	cultural_text.pixel_size = 0.002
	cultural_text.position = Vector3(0, -0.04, 0.01)
	cultural_text.modulate = Color(0.6, 0.65, 0.75)
	cultural_text.outline_size = 0
	_info_panel.add_child(cultural_text)

	add_child(_info_panel)

# =============================================================================
# GRID SYSTEM INTEGRATION
# =============================================================================

func apply_grid_config(config: Dictionary) -> void:
	if config.has("table_rows"):
		table_rows = config["table_rows"]
	if config.has("table_cols"):
		table_cols = config["table_cols"]
	if config.has("show_info"):
		show_info_panel = config["show_info"]

	# Rebuild
	for child in get_children():
		child.queue_free()
	call_deferred("_create_visualization")

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

