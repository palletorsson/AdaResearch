extends Node3D
class_name SpaceDystopiaMain

# The "App" for the Space Dystopia Album.
# Creates the SciFiSynth engine and provides a VR player UI.

const VR_BUTTON_SCENE = preload("res://commons/interactables/push_button.tscn")

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
	var y_pos := 0.56

	# Title
	var title = Label3D.new()
	title.text = "S P A C E   D Y S T O P I A"
	title.font_size = 48
	title.modulate = Color(0.6, 0.8, 1.0)
	title.position = Vector3(0, y_pos, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	y_pos -= 0.1

	# Info
	info_label = Label3D.new()
	info_label.text = "Initializing System..."
	info_label.font_size = 24
	info_label.modulate = Color(0.5, 0.5, 0.5)
	info_label.position = Vector3(0, y_pos, 0)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(info_label)
	y_pos -= 0.1

	# Track List (two columns)
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

	for i in range(tracks.size()):
		var t = tracks[i]
		var col = i % 2
		var row = i / 2
		var x_offset = -0.18 + col * 0.36
		var btn_pos = Vector3(x_offset, y_pos - row * 0.09, 0)

		var btn = VR_BUTTON_SCENE.instantiate()
		btn.position = btn_pos
		add_child(btn)

		var lbl = Label3D.new()
		lbl.text = t.name
		lbl.font_size = 18
		lbl.modulate = Color(0.85, 0.9, 1.0)
		lbl.position = Vector3(0, 0.03, 0)
		btn.add_child(lbl)

		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_on_track_selected.bind(t.id))

		track_buttons.append(btn)
		track_labels.append(lbl)

func _on_track_selected(id: int) -> void:
	if id >= 1 and id <= 10:
		synth.play_track(id)
		_update_ui_state(id, "Playing...")
	else:
		_update_ui_state(id, "Unknown Track")
		synth.stop_all()

func _update_ui_state(id: int, status: String) -> void:
	info_label.text = "Track %d Active\nStatus: %s" % [id, status]

	for i in range(track_labels.size()):
		if (i + 1) == id:
			track_labels[i].modulate = Color(1.0, 1.0, 1.0)
		else:
			track_labels[i].modulate = Color(0.5, 0.5, 0.5)

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
