extends Control
class_name SpaceDystopiaMain

# The "App" for the Space Dystopia Album.
# Creates the SciFiSynth engine and provides a VR player UI.

var synth: SciFiSynth
var track_buttons: Array[Node3D] = []
var track_labels: Array[Label3D] = []
var info_label: Label3D

func _ready() -> void:
	# 1. Setup Sound Engine
	synth = SciFiSynth.new()
	synth.name = "SciFiSynth"
	add_child(synth)

	# 2. Setup VR UI
	_setup_ui()

	# 3. Auto-play Track 1
	_on_track_selected(1)

func _setup_ui() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")

	# Info label (above panel)
	info_label = Label3D.new()
	info_label.text = "Initializing System..."
	info_label.font_size = 24
	info_label.modulate = Color(0.5, 0.5, 0.5)
	info_label.position = Vector3(0, 0.56, 0)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(info_label)

	# Track buttons — 5 rows of 2 buttons each
	var track_names := [
		"1. DRIFT", "2. INTER", "3. FOUNDRY", "4. NOIR", "5. STELLAR",
		"6. RAIN", "7. SKYLINE", "8. MARKET", "9. SYMPHONY", "10. SINGULAR"
	]
	var rows: Array = []
	for r in 5:
		rows.append([
			{"type": "button", "label": track_names[r * 2]},
			{"type": "button", "label": track_names[r * 2 + 1]},
		])

	var panel: Node3D = RackTpl.create_panel("SPACE AUDIO", rows)
	panel.position = Vector3(0, 0.3, 0)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	# Connect track buttons
	for i in 10:
		var btn: Node = panel.find_child("Btn_%d" % i, true, false)
		if btn:
			track_buttons.append(btn)
			var area = btn.get_node_or_null("InteractableAreaButton")
			if area:
				area.button_pressed.connect(_on_track_selected.bind(i + 1))

func _on_track_selected(id: int) -> void:
	if id >= 1 and id <= 10:
		synth.play_track(id)
		_update_ui_state(id, "Playing...")
	else:
		_update_ui_state(id, "Unknown Track")
		synth.stop_all()

func _update_ui_state(id: int, status: String) -> void:
	info_label.text = "Track %d Active\nStatus: %s" % [id, status]

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
