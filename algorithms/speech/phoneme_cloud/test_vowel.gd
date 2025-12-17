extends Node3D

@onready var synth = $VowelSynth3D
@onready var label = $Label3D

func _ready():
	print("--- Vowel Synth: Saying 'Ada' ---")
	await get_tree().create_timer(1.0).timeout
	
	say_alphabet()
	
	await get_tree().create_timer(1.0).timeout
	say_ada()
	
	await get_tree().create_timer(0.8).timeout
	say_research()

func say_alphabet():
	print("Saying Alphabet (Vowel Cycle)...")
	# Minimal Model Anchors
	var vowels = ["i", "e", "a", "o", "u"]
	
	label.text = "Field Anchors"
	await get_tree().create_timer(1.0).timeout
	
	for v in vowels:
		print(" - ", v)
		label.text = "/ " + v + " /"
		synth.speak_vowel(v, 1.0)
		await get_tree().create_timer(0.5).timeout
		synth.stop()
		await get_tree().create_timer(0.1).timeout
	
	print("Alphabet complete.")

func move_field(t_f1, t_delta, duration):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(synth, "f1", float(t_f1), duration)
	tween.tween_property(synth, "delta", float(t_delta), duration)

func say_ada():
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
	await get_tree().create_timer(0.05).timeout 
	
	# 3. Burst into "A" again
	var tween2 = create_tween()
	tween2.set_parallel(true)
	tween2.tween_property(synth, "target_intensity", 1.0, 0.01)
	# Back to A: (850, 760)
	tween2.tween_property(synth, "f1", 850.0, 0.1)
	tween2.tween_property(synth, "delta", 760.0, 0.1)
	
	await get_tree().create_timer(0.5).timeout
	synth.stop()

func say_research():
	label.text = "Research"
	print("Saying 'Research'...")
	# "Re" (/r/ -> /i/)
	# R approx: F1=450, F2=1200 -> Delta=750
	synth.f1 = 450.0
	synth.delta = 750.0
	synth.is_speaking = true
	synth.target_intensity = 0.9
	
	# Glide to /i/ ("Reeeee")
	# i: 240, 2160
	move_field(240.0, 2160.0, 0.15)
	
	await get_tree().create_timer(0.3).timeout
	
	# "S" (Silence)
	synth.is_speaking = false
	synth.target_intensity = 0.0
	
	await get_tree().create_timer(0.15).timeout # S duration
	
	# "Search" (/s/ -> /er/ -> /ch/)
	# Voice On
	# er approx (schwa-like): F1=500, F2=1500 -> Delta=1000
	synth.f1 = 500.0
	synth.delta = 1000.0
	synth.is_speaking = true
	synth.target_intensity = 1.0
	
	await get_tree().create_timer(0.2).timeout
	
	# Glide to /r/ ("Seerrr")
	# R: 450, 750
	move_field(450.0, 750.0, 0.25)
	
	await get_tree().create_timer(0.25).timeout
	
	# "Ch" (Stop + Noise Burst)
	synth.target_intensity = 0.0 
	
	await get_tree().create_timer(0.12).timeout # Gap
	synth.stop()
	print("Finished sequence.")
