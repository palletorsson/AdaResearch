extends Node

# Quick test scene for TrapSequencer
# Press F6 to run this scene and hear trap beats!
# Press SPACE to stop/start
# Press 1-5 to change patterns

var sequencer: TrapSequencerComponent

func _ready():
	print("🎵 TRAP SEQUENCER TEST")
	print("==================================================")
	print("Controls:")
	print("  SPACE - Play/Stop")
	print("  1 - Minimal Trap (chill)")
	print("  2 - Hard Trap (aggressive)")
	print("  3 - Drill (UK drill)")
	print("  4 - Triplet Trap (bouncy)")
	print("  5 - Ambient Sparse (minimal)")
	print("  UP/DOWN - Change BPM")
	print("  LEFT/RIGHT - Adjust swing")
	print("==================================================")

	# Create sequencer
	sequencer = TrapSequencerComponent.new()
	add_child(sequencer)

	# Initialize with minimal trap
	sequencer.initialize({
		"pattern": "minimal_trap",
		"bpm": 85.0,
		"swing": 0.15,
		"variation": 0.1,
		"master_volume": -6.0,
		"track_volumes": {
			"kick": 0.0,
			"snare": -3.0,
			"hihat": -6.0,
			"perc": -9.0
		}
	})

	# Connect signals
	sequencer.beat_triggered.connect(_on_beat)
	sequencer.pattern_changed.connect(_on_pattern_changed)
	sequencer.bpm_changed.connect(_on_bpm_changed)

	# Auto-start
	sequencer.start()
	print("▶️ Playing: minimal_trap @ 85 BPM")

func _input(event):
	if event.is_action_pressed("ui_accept"):  # SPACE
		if sequencer.is_playing:
			sequencer.stop()
			print("⏹️ Stopped")
		else:
			sequencer.start()
			print("▶️ Started")

	# Pattern switching (1-5 keys)
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				sequencer.change_pattern("minimal_trap")
			KEY_2:
				sequencer.change_pattern("hard_trap")
			KEY_3:
				sequencer.change_pattern("drill")
			KEY_4:
				sequencer.change_pattern("triplet_trap")
			KEY_5:
				sequencer.change_pattern("ambient_sparse")

	# BPM control (UP/DOWN arrows)
	if event.is_action_pressed("ui_up"):
		sequencer.set_bpm(sequencer.bpm + 5.0)
		print("BPM: %.0f" % sequencer.bpm)

	if event.is_action_pressed("ui_down"):
		sequencer.set_bpm(sequencer.bpm - 5.0)
		print("BPM: %.0f" % sequencer.bpm)

	# Swing control (LEFT/RIGHT arrows)
	if event.is_action_pressed("ui_right"):
		sequencer.set_swing(min(sequencer.swing_amount + 0.05, 1.0))
		print("Swing: %.2f" % sequencer.swing_amount)

	if event.is_action_pressed("ui_left"):
		sequencer.set_swing(max(sequencer.swing_amount - 0.05, 0.0))
		print("Swing: %.2f" % sequencer.swing_amount)

func _on_beat(beat_number: int):
	# Visual feedback on beats
	if beat_number % 4 == 0:
		print("♪ Bar %d" % (beat_number / 4))

func _on_pattern_changed(pattern_name: String):
	print("🔄 Pattern changed to: %s" % pattern_name)

func _on_bpm_changed(new_bpm: float):
	print("⏱️ BPM changed to: %.0f" % new_bpm)

func _exit_tree():
	if sequencer:
		sequencer.stop()
