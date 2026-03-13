extends Node

# Headless Vowel Test (No Visuals)
# Replicates "Ada Research" timing to isolate audio artifacts.

@onready var synth = $VowelSynth3D
var anchors = {
	"i": Vector2(240, 2160),
	"e": Vector2(390, 1910),
	"a": Vector2(850, 760),
	"o": Vector2(360, 280),
	"u": Vector2(250, 345),
	"r": Vector2(450, 750),
	"d_locus": Vector2(200, 1600)
}

func _ready() -> void:
	print("HeadlessSynthesizer: Starting sequence in 1s...")
	await get_tree().create_timer(1.0).timeout
	_loop()

func _loop() -> void:
	while true:
		print("HeadlessSynthesizer: Ada")
		await _play_ada()
		print("HeadlessSynthesizer: Waiting...")
		await get_tree().create_timer(1.0).timeout
		
		print("HeadlessSynthesizer: Research")
		await _play_research()
		
		print("HeadlessSynthesizer: Loop Pause 4s")
		await get_tree().create_timer(4.0).timeout

func _play_ada() -> void:
	# A (Silent move)
	_set_params(anchors["a"])
	synth.target_intensity = 0.0
	await get_tree().create_timer(0.35).timeout
	
	# Fade In A
	synth.target_intensity = 1.0
	await get_tree().create_timer(1.5).timeout
	
	# D (Plosive)
	synth.target_intensity = 0.0 # Fade out
	await get_tree().create_timer(0.04).timeout
	synth.trigger_plosive()
	
	# Shift to Locus while closed
	_set_params(anchors["d_locus"])
	await get_tree().create_timer(0.05).timeout
	
	# Burst A
	_set_params(anchors["a"])
	synth.target_intensity = 1.0
	await get_tree().create_timer(1.5).timeout
	
	# Fade Out
	synth.target_intensity = 0.0
	await get_tree().create_timer(0.5).timeout

func _play_research() -> void:
	# R
	_set_params(anchors["r"])
	synth.target_intensity = 0.0
	await get_tree().create_timer(0.35).timeout
	
	# Fade In R
	synth.target_intensity = 0.9
	await get_tree().create_timer(0.3).timeout # 0.1 + 0.2
	
	# Glide i
	_tween_params(anchors["i"], 0.2)
	await get_tree().create_timer(0.3).timeout # 0.2 + gap
	
	# Silence (S)
	synth.target_intensity = 0.0
	await get_tree().create_timer(0.15).timeout
	
	# er
	_set_params(anchors["e"])
	synth.target_intensity = 1.0
	await get_tree().create_timer(0.2).timeout
	
	# Glide R
	_tween_params(anchors["r"], 0.2)
	await get_tree().create_timer(0.2).timeout
	
	# Ch (Plosive)
	synth.target_intensity = 0.0
	await get_tree().create_timer(0.04).timeout
	synth.trigger_plosive()

func _set_params(p: Vector2) -> void:
	synth.f1 = p.x
	synth.delta = p.y

func _tween_params(p: Vector2, dur: float) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(synth, "f1", p.x, dur)
	tween.tween_property(synth, "delta", p.y, dur)
	await tween.finished

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

