## Cave Explorer UI Controller
## Controls a miniature marching cubes cave with scrollable parameters
extends Node3D

## Reference to the mini cave instance
@onready var mini_cave : MeshInstance3D = null

## Cave parameters (synced with sliders)
var noise_scale : float = 3.8
var iso_level : float = 0.88
var chunk_scale : float = 100.0  # Scaled down for mini version
var noise_offset : Vector3 = Vector3(150, -100, 200)

## Preset caves for scrolling
var cave_presets = [
	{
		"name": "Inside Cave",
		"noise_scale": 3.8,
		"iso_level": 0.88,
		"noise_offset": Vector3(150, -100, 200),
		"chunk_scale": 100.0
	},
	{
		"name": "Flat Landscape",
		"noise_scale": 3.5,
		"iso_level": 0.05,
		"noise_offset": Vector3(100, 50, 75),
		"chunk_scale": 100.0
	},
	{
		"name": "Torus Sculpture",
		"noise_scale": 2.0,
		"iso_level": 0.0,
		"noise_offset": Vector3(0, 0, 0),
		"chunk_scale": 80.0
	},
	{
		"name": "Dense Caves",
		"noise_scale": 4.5,
		"iso_level": 0.95,
		"noise_offset": Vector3(200, 100, 150),
		"chunk_scale": 90.0
	},
	{
		"name": "Open Caverns",
		"noise_scale": 2.5,
		"iso_level": 0.7,
		"noise_offset": Vector3(50, -50, 100),
		"chunk_scale": 110.0
	}
]

var current_preset_index : int = 0

func _ready():
	create_mini_cave()
	update_mini_cave()
	connect_ui_signals()

func connect_ui_signals():
	# Wait for the Viewport2Din3D to create the scene
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Find the control panel in the viewport
	var viewport_node = $Screen/Viewport2Din3D
	if viewport_node and viewport_node.has_node("Viewport"):
		var viewport = viewport_node.get_node("Viewport")
		var control_panel = viewport.get_child(0) if viewport.get_child_count() > 0 else null
		
		if control_panel:
			# Connect slider signals
			control_panel.noise_scale_changed.connect(on_noise_scale_changed)
			control_panel.iso_level_changed.connect(on_iso_level_changed)
			control_panel.chunk_scale_changed.connect(on_chunk_scale_changed)
			control_panel.next_preset_pressed.connect(next_preset)
			control_panel.previous_preset_pressed.connect(previous_preset)
			
			# Update initial preset name
			control_panel.update_preset_name(get_current_preset_name())
			
			print("✅ UI signals connected!")
		else:
			print("⚠️ Control panel not found in viewport")

func create_mini_cave():
	# Create a scaled-down version of the marching cubes cave
	var terrain_script = load("res://algorithms/proceduralgeneration/marchingcave/Scripts/TerrainGenerator.gd")
	var terrain_material = load("res://algorithms/proceduralgeneration/marchingcave/Materials/TerrainMat.tres")
	
	# Find the display node
	var display_node = $MiniCaveDisplay
	if not display_node:
		display_node = self
	
	mini_cave = MeshInstance3D.new()
	mini_cave.name = "MiniCave"
	mini_cave.set_script(terrain_script)
	mini_cave.material_override = terrain_material
	
	# Set initial parameters (scaled down)
	mini_cave.noise_scale = noise_scale
	mini_cave.noise_offset = noise_offset
	mini_cave.iso_level = iso_level
	mini_cave.chunk_scale = chunk_scale  # Much smaller for preview
	
	display_node.add_child(mini_cave)
	
	print("🏔️ Mini cave created at scale: ", chunk_scale)

func update_mini_cave():
	if mini_cave:
		mini_cave.noise_scale = noise_scale
		mini_cave.noise_offset = noise_offset
		mini_cave.iso_level = iso_level
		mini_cave.chunk_scale = chunk_scale
		
		# Trigger regeneration if the script supports it
		if mini_cave.has_method("init_compute"):
			mini_cave.call("init_compute")
			mini_cave.call("run_compute")
			mini_cave.call("fetch_and_process_compute_data")

# Called from UI sliders
func on_noise_scale_changed(value: float):
	noise_scale = value
	update_mini_cave()
	print("Noise Scale: %.2f" % value)

func on_iso_level_changed(value: float):
	iso_level = value
	update_mini_cave()
	print("Iso Level: %.2f" % value)

func on_chunk_scale_changed(value: float):
	chunk_scale = value
	update_mini_cave()
	print("Chunk Scale: %.0f" % value)

# Scroll through presets
func next_preset():
	current_preset_index = (current_preset_index + 1) % cave_presets.size()
	load_preset(current_preset_index)

func previous_preset():
	current_preset_index = (current_preset_index - 1 + cave_presets.size()) % cave_presets.size()
	load_preset(current_preset_index)

func load_preset(index: int):
	var preset = cave_presets[index]
	noise_scale = preset["noise_scale"]
	iso_level = preset["iso_level"]
	noise_offset = preset["noise_offset"]
	chunk_scale = preset["chunk_scale"]
	
	update_mini_cave()
	
	# Update UI sliders
	var viewport_node = $Screen/Viewport2Din3D
	if viewport_node and viewport_node.has_node("Viewport"):
		var viewport = viewport_node.get_node("Viewport")
		var control_panel = viewport.get_child(0) if viewport.get_child_count() > 0 else null
		if control_panel:
			control_panel.set_values(noise_scale, iso_level, chunk_scale)
			control_panel.update_preset_name(preset["name"])
	
	print("📜 Loaded preset: ", preset["name"])
	print("  Noise: %.2f | Iso: %.2f | Scale: %.0f" % [noise_scale, iso_level, chunk_scale])

func get_current_preset_name() -> String:
	return cave_presets[current_preset_index]["name"]
