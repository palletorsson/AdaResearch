extends Node

## SoundscapePreview - Desktop tool for previewing ambient soundscape presets
## Run this scene with F6 to test soundscapes without VR

@onready var preset_dropdown: OptionButton = $CanvasLayer/Panel/VBoxContainer/PresetDropdown
@onready var play_button: Button = $CanvasLayer/Panel/VBoxContainer/HBoxContainer/PlayButton
@onready var stop_button: Button = $CanvasLayer/Panel/VBoxContainer/HBoxContainer/StopButton
@onready var description_label: Label = $CanvasLayer/Panel/VBoxContainer/DescriptionLabel
@onready var status_label: Label = $CanvasLayer/Panel/VBoxContainer/StatusLabel

var ambient_controller: Node = null
var current_preset: String = ""
var presets: Array = []

# Sci-fi lo-fi soundscapes to highlight
var featured_presets = [
	"space_station_isolation",
	"space_station_beats",
	"abandoned_factory", 
	"abandoned_factory_beats",
	"quantum_lab",
	"quantum_lab_beats",
	"cyberpunk_night_market",
	"underwater_research_lab",
	"underwater_lab_beats",
	"desert_outpost",
	"desert_outpost_beats",
	"bio_dome_greenhouse",
	"bio_dome_beats",
	"neon_arcade",
	"orbital_prison"
]

func _ready():
	print("🎧 Soundscape Preview Tool")
	
	# Wait for SoundBank to be ready
	if SoundBank:
		_populate_presets()
	else:
		await get_tree().create_timer(0.5).timeout
		_populate_presets()

func _populate_presets():
	presets.clear()
	preset_dropdown.clear()
	
	# Add separator for featured
	preset_dropdown.add_item("── Sci-Fi Lo-Fi ──")
	preset_dropdown.set_item_disabled(0, true)
	
	# Add featured presets first
	for preset_name in featured_presets:
		presets.append(preset_name)
		var display = preset_name.replace("_", " ").capitalize()
		preset_dropdown.add_item("★ " + display)
	
	# Add separator
	var sep_idx = preset_dropdown.item_count
	preset_dropdown.add_item("── All Presets ──")
	preset_dropdown.set_item_disabled(sep_idx, true)
	
	# Add all other presets from SoundBank
	var all_presets = SoundBank.ambient_presets.keys()
	all_presets.sort()
	for preset_name in all_presets:
		if preset_name not in featured_presets and preset_name != "silent":
			presets.append(preset_name)
			var display = preset_name.replace("_", " ").capitalize()
			preset_dropdown.add_item(display)
	
	print("📂 Found %d soundscape presets" % presets.size())
	status_label.text = "Select a preset to preview"

func _on_preset_dropdown_item_selected(index: int):
	# Account for the separator items
	var real_index = -1
	var count = 0
	for i in range(preset_dropdown.item_count):
		if not preset_dropdown.is_item_disabled(i):
			if i == index:
				real_index = count
				break
			count += 1
	
	if real_index >= 0 and real_index < presets.size():
		current_preset = presets[real_index]
		_update_description()

func _update_description():
	if current_preset.is_empty():
		description_label.text = ""
		return
	
	var preset_data = SoundBank.get_preset(current_preset)
	if preset_data.has("description"):
		description_label.text = preset_data["description"]
	else:
		description_label.text = "No description available"

func _on_play_button_pressed():
	if current_preset.is_empty():
		status_label.text = "⚠️ Select a preset first"
		return
	
	# Stop existing
	_stop_ambient()
	
	# Create controller
	var AmbientController = load("res://commons/audio/AmbientSoundController.gd")
	ambient_controller = AmbientController.new()
	ambient_controller.name = "PreviewAmbient"
	add_child(ambient_controller)
	
	# Setup buses
	SoundBank.setup_buses_for_preset(current_preset)
	
	# Pre-generate (this might take a moment)
	status_label.text = "⏳ Generating sounds..."
	await get_tree().process_frame
	
	SoundBank.pregenerate_preset_sounds(current_preset)
	
	# Load and play
	ambient_controller.load_preset(current_preset, -6.0, 1.0)
	status_label.text = "▶️ Playing: " + current_preset.replace("_", " ").capitalize()
	
	print("🎵 Playing preset: ", current_preset)

func _on_stop_button_pressed():
	_stop_ambient()
	status_label.text = "⏹️ Stopped"

func _stop_ambient():
	if ambient_controller and is_instance_valid(ambient_controller):
		ambient_controller.stop_ambient()
		ambient_controller.queue_free()
		ambient_controller = null

func _exit_tree():
	_stop_ambient()
