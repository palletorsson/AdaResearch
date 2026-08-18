extends Node3D

@onready var synth = $VowelSynth3D
@onready var label = $Label3D

func _ready() -> void:
	print("--- Vowel Synth: Ada Research Lab One ---")
	await get_tree().create_timer(1.0).timeout
	
	say_ada()
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(0.4).timeout
	say_research()
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(0.4).timeout
	say_lab_one()

func say_lab_one() -> void:
	label.text = "Lab One"
	print("Saying 'Lab One'...")
	
	# "Lab"
	# /l/ -> F1=400, Delta=800
	synth.f1 = 400.0
	synth.delta = 800.0
	synth.is_speaking = true
	synth.target_intensity = 1.0
	
	# Glide to /ae/ (Lab)
	# /ae/ -> F1=750, Delta=850
	move_field(750.0, 850.0, 0.3)
	await get_tree().create_timer(0.4).timeout
	
	# /b/ (Plosive)
	synth.target_intensity = 0.0
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(0.04).timeout
	synth.trigger_plosive()
	
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(0.2).timeout # Gap
	
	# "One"
	# /w/ -> F1=300, Delta=300
	synth.f1 = 300.0
	synth.delta = 300.0
	synth.is_speaking = true
	synth.target_intensity = 1.0
	
	# Glide to /uh/ (One)
	# /uh/ -> F1=600, Delta=600
	move_field(600.0, 600.0, 0.4)
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(0.5).timeout
	
	# /n/ (Nasal fade)
	# Drift F1 down, intensity down
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(synth, "f1", 400.0, 0.4)
	tween.tween_property(synth, "target_intensity", 0.0, 0.4)
	
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(0.5).timeout
	synth.stop()
	print("Finished 'Lab One'.")

func say_alphabet() -> void:
	print("Saying Alphabet (Vowel Cycle)...")
	# Minimal Model Anchors
	var vowels = ["i", "e", "a", "o", "u"]
	
	label.text = "Field Anchors"
	await get_tree().create_timer(1.0).timeout
	
	for v in vowels:
		print(" - ", v)
		label.text = "/ " + v + " /"
		synth.speak_vowel(v, 1.0)
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().create_timer(0.5).timeout
		synth.stop()
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().create_timer(0.1).timeout
	
	print("Alphabet complete.")

func move_field(t_f1, t_delta, duration) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(synth, "f1", float(t_f1), duration)
	tween.tween_property(synth, "delta", float(t_delta), duration)

func say_ada() -> void:
	label.text = "Ada"
	# 1. Start "A" (850, 760)
	synth.speak_vowel("a", 1.0)
	
	await get_tree().create_timer(0.4).timeout
	
	# 2. Transition to "D" (Plosive)
	# D Locus: F1=200, F2=1800 -> Delta = 1600
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(synth, "f1", 200.0, 0.05)
	tween.tween_property(synth, "delta", 1600.0, 0.05)
	tween.tween_property(synth, "target_intensity", 0.0, 0.05) 
	
	await tween.finished
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(0.05).timeout 
	
	# 3. Burst into "A" again
	var tween2 = create_tween()
	tween2.set_parallel(true)
	tween2.tween_property(synth, "target_intensity", 1.0, 0.01)
	# Back to A: (850, 760)
	tween2.tween_property(synth, "f1", 850.0, 0.1)
	tween2.tween_property(synth, "delta", 760.0, 0.1)
	
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(0.5).timeout
	synth.stop()

func say_research() -> void:
	label.text = "Research"
	print("Saying 'Research'...")
	
	# "Re" (/r/ -> /i/)
	# R approx: F1=450, Delta=750
	synth.f1 = 450.0
	synth.delta = 750.0
	synth.is_speaking = true
	synth.target_intensity = 0.9
	
	# Glide to /i/ ("Reeeee")
	# i: 240, 2160
	move_field(240.0, 2160.0, 0.2)
	await get_tree().create_timer(0.3).timeout
	
	# "S" (Fricative Event)
	# Crossfade to Noise (High Band)
	synth.trigger_fricative("s")
	
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(0.15).timeout # S duration
	
	# Release S -> Glide to "er"
	# er approx: F1=500, Delta=1000
	synth.release_fricative()
	# Pre-set formant targets for return?
	# Synth smooths to them, so we just set them.
	synth.f1 = 500.0
	synth.delta = 1000.0
	
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(0.2).timeout
	
	# Glide to /r/ ("Seerrr")
	move_field(450.0, 750.0, 0.25)
	
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(0.25).timeout
	
	# "Ch" (Fricative Burst)
	synth.trigger_fricative("ch")
	
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(0.15).timeout # Ch duration
	
	synth.stop()
	# Reset mix for next time (handled by stop? need to ensure release)
	synth.release_fricative()
	print("Finished sequence.")

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
