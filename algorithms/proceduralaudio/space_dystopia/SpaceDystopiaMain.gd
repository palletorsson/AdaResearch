extends Control
class_name SpaceDystopiaMain

# The "App" for the Space Dystopia Album.
# Creates the SciFiSynth engine and provides a player UI.

var synth: SciFiSynth
var track_buttons: Array[Button] = []
var info_label: Label

func _ready():
	# 1. Setup Sound Engine
	synth = SciFiSynth.new()
	synth.name = "SciFiSynth"
	add_child(synth)
	
	# 2. Setup UI
	_setup_ui()
	
	# 3. Auto-play Track 1
	_on_track_selected(1)

func _setup_ui():
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08) # Dark SciFi Blue
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Main Container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "S P A C E   D Y S T O P I A"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.modulate = Color(0.6, 0.8, 1.0)
	vbox.add_child(title)
	
	# Info
	info_label = Label.new()
	info_label.text = "Initializing System..."
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.modulate = Color(0.5, 0.5, 0.5)
	vbox.add_child(info_label)
	
	# Track List
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(grid)
	
	var tracks = [
		{ "id": 1, "name": "1. Post-Singularity Drift" },
		{ "id": 2, "name": "2. Interdimensional" },
		{ "id": 3, "name": "3. Automated Foundry" },
		{ "id": 4, "name": "4. Augmented Noir" },
		{ "id": 5, "name": "5. Stellar Shadowing" },
		{ "id": 6, "name": "6. Neon Rain" },
		{ "id": 7, "name": "7. Elegiac Skyline" },
		{ "id": 8, "name": "8. Martian Market" },
		{ "id": 9, "name": "9. Celestial Symphony" },
		{ "id": 10, "name": "10. The Singularity" }
	]
	
	for t in tracks:
		var btn = Button.new()
		btn.text = t.name
		btn.custom_minimum_size = Vector2(200, 40)
		btn.pressed.connect(func(): _on_track_selected(t.id))
		grid.add_child(btn)
		track_buttons.append(btn)

func _on_track_selected(id: int):
	# Update Synths
	# Update Synths
	if id >= 1 and id <= 10:
		synth.play_track(id)
		_update_ui_state(id, "Playing...")
	else:
		_update_ui_state(id, "Unknown Track")
		synth.stop_all()

func _update_ui_state(id: int, status: String):
	info_label.text = "Track %d Active\nStatus: %s" % [id, status]
	
	for i in range(track_buttons.size()):
		var btn = track_buttons[i]
		if (i + 1) == id:
			btn.modulate = Color(1.0, 1.0, 1.0) # Active
		else:
			btn.modulate = Color(0.5, 0.5, 0.5) # Dim
