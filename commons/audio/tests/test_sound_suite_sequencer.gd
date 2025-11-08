extends Node

## Sound Suite Sequencer Test Scene
## Demonstrates switching between different sound suites
## with individual parameter control and pattern deployment

var sequencer: SoundSuiteSequencer

func _ready():
	print("🎨 SOUND SUITE SEQUENCER TEST")
	print("==================================================")
	print("Suite Selection:")
	print("  1 - Trap Beats (drums)")
	print("  2 - Tech Noir (ambient/atmospheric)")
	print("")
	print("Pattern Selection (Trap Beats):")
	print("  Q - Minimal trap")
	print("  W - Hard trap")
	print("  E - Four-on-floor")
	print("")
	print("Pattern Selection (Tech Noir):")
	print("  Q - Ambient sparse")
	print("  W - Atmospheric layers")
	print("")
	print("Playback Control:")
	print("  SPACE - Play/Stop")
	print("  UP/DOWN - BPM ±5")
	print("  LEFT/RIGHT - Swing ±0.05")
	print("")
	print("Sound Parameter Control (examples):")
	print("  K - Kick: pitch +5")
	print("  J - Kick: pitch -5")
	print("  S - Snare: decay +0.1")
	print("  A - Snare: decay -0.1")
	print("==================================================")

	# Create sequencer
	sequencer = SoundSuiteSequencer.new()
	add_child(sequencer)

	# Connect signals
	sequencer.beat_triggered.connect(_on_beat)
	sequencer.suite_changed.connect(_on_suite_changed)
	sequencer.pattern_changed.connect(_on_pattern_changed)
	sequencer.bpm_changed.connect(_on_bpm_changed)

	# Initialize with trap beats
	sequencer.initialize({
		"suite": "trap_beats",
		"pattern": "minimal_trap",
		"bpm": 85.0,
		"swing": 0.15,
		"variation": 0.1
	})

	# Set some initial sound parameters
	sequencer.set_sound_params("kick", {"pitch": 60.0, "decay": 1.2})
	sequencer.set_sound_params("snare", {"decay": 0.3, "noise_amount": 0.7})
	sequencer.set_sound_params("hihat_closed", {"decay": 0.05, "noise_tone": 8000.0})

	print("")
	print("▶️ Ready! Suite: trap_beats | Pattern: minimal_trap | BPM: 85")
	print("Press SPACE to start")

func _input(event):
	# Playback control
	if event.is_action_pressed("ui_accept"):  # SPACE
		if sequencer.is_playing:
			sequencer.stop()
		else:
			sequencer.start()

	if not (event is InputEventKey and event.pressed):
		return

	match event.keycode:
		# Suite selection
		KEY_1:
			sequencer.change_suite("trap_beats")
			print("🎨 Switched to: Trap Beats")
			print("  Available sounds: ", sequencer.get_suite_sounds())

		KEY_2:
			sequencer.change_suite("tech_noir")
			print("🎨 Switched to: Tech Noir")
			print("  Available sounds: ", sequencer.get_suite_sounds())

		# Pattern selection (context-dependent on current suite)
		KEY_Q:
			if sequencer.current_suite == "trap_beats":
				sequencer.load_pattern("minimal_trap")
			else:
				sequencer.load_pattern("ambient_sparse")

		KEY_W:
			if sequencer.current_suite == "trap_beats":
				sequencer.load_pattern("hard")
			else:
				# Custom atmospheric pattern
				sequencer.load_pattern({
					"length": 32,
					"drone": [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
					"city": [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
					"rain": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0],
					"static": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
				})
				print("🎼 Loaded custom atmospheric layers pattern")

		KEY_E:
			if sequencer.current_suite == "trap_beats":
				sequencer.load_pattern("four_floor")

		# Individual sound parameter control
		KEY_K:  # Kick pitch up
			if sequencer.current_suite == "trap_beats":
				var params = sequencer.get_sound_params("kick")
				var pitch = params.get("pitch", 60.0)
				pitch += 5.0
				sequencer.set_sound_params("kick", {"pitch": pitch})
				print("🎛️ Kick pitch: %.0f" % pitch)

		KEY_J:  # Kick pitch down
			if sequencer.current_suite == "trap_beats":
				var params = sequencer.get_sound_params("kick")
				var pitch = params.get("pitch", 60.0)
				pitch -= 5.0
				sequencer.set_sound_params("kick", {"pitch": pitch})
				print("🎛️ Kick pitch: %.0f" % pitch)

		KEY_S:  # Snare decay up
			if sequencer.current_suite == "trap_beats":
				var params = sequencer.get_sound_params("snare")
				var decay = params.get("decay", 0.3)
				decay += 0.1
				sequencer.set_sound_params("snare", {"decay": decay})
				print("🎛️ Snare decay: %.2f" % decay)

		KEY_A:  # Snare decay down
			if sequencer.current_suite == "trap_beats":
				var params = sequencer.get_sound_params("snare")
				var decay = params.get("decay", 0.3)
				decay = max(0.1, decay - 0.1)
				sequencer.set_sound_params("snare", {"decay": decay})
				print("🎛️ Snare decay: %.2f" % decay)

		KEY_H:  # Hihat tone up
			if sequencer.current_suite == "trap_beats":
				var params = sequencer.get_sound_params("hihat_closed")
				var tone = params.get("noise_tone", 8000.0)
				tone += 1000.0
				sequencer.set_sound_params("hihat_closed", {"noise_tone": tone})
				print("🎛️ Hihat tone: %.0f Hz" % tone)

		KEY_G:  # Hihat tone down
			if sequencer.current_suite == "trap_beats":
				var params = sequencer.get_sound_params("hihat_closed")
				var tone = params.get("noise_tone", 8000.0)
				tone = max(3000.0, tone - 1000.0)
				sequencer.set_sound_params("hihat_closed", {"noise_tone": tone})
				print("🎛️ Hihat tone: %.0f Hz" % tone)

	# BPM control
	if event.is_action_pressed("ui_up"):
		sequencer.set_bpm(sequencer.bpm + 5.0)
		print("⏱️ BPM: %.0f" % sequencer.bpm)

	if event.is_action_pressed("ui_down"):
		sequencer.set_bpm(sequencer.bpm - 5.0)
		print("⏱️ BPM: %.0f" % sequencer.bpm)

	# Swing control
	if event.is_action_pressed("ui_right"):
		sequencer.set_swing(sequencer.swing_amount + 0.05)
		print("🌊 Swing: %.2f" % sequencer.swing_amount)

	if event.is_action_pressed("ui_left"):
		sequencer.set_swing(sequencer.swing_amount - 0.05)
		print("🌊 Swing: %.2f" % sequencer.swing_amount)

func _on_beat(beat_number: int):
	# Visual feedback every bar
	if beat_number % 4 == 0:
		print("♪ Bar %d" % (beat_number / 4))

func _on_suite_changed(suite_name: String):
	print("🎨 Suite changed: %s" % suite_name)
	print("  Sounds: ", sequencer.get_suite_sounds())

func _on_pattern_changed(pattern_name: String):
	print("🎼 Pattern changed: %s" % pattern_name)

func _on_bpm_changed(new_bpm: float):
	pass  # Already printed in input handler

func _exit_tree():
	if sequencer:
		sequencer.stop()
