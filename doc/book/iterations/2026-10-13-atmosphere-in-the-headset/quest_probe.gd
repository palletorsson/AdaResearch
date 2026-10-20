extends Node
## Copied into an isolated Android test project with the production client.
var output: Label
var done := false

func _ready() -> void:
	output = Label.new()
	output.text = "Testing RANDOM.ORG HTTPS on this headset..."
	output.position = Vector2(40, 40)
	add_child(output)
	var client = load("res://atmospheric_seed.gd").new()
	add_child(client)
	client.received.connect(func(value: int, receipt: Dictionary):
		var rng := RandomNumberGenerator.new()
		rng.seed = value
		var first := rng.randf()
		rng.seed = value
		finish({"passed": first == rng.randf(), "receipt": receipt,
			"os": OS.get_name(), "model": OS.get_model_name(),
			"scope": "Production HTTPS client on Quest; local seeded replay. Not a VR hand-interaction test."})
	)
	client.status_changed.connect(func(message: String):
		output.text = message
		if not client.is_busy(): finish({"passed": false, "status": message})
	)
	client.request_seed()

func finish(result: Dictionary) -> void:
	if done: return
	done = true
	var data := JSON.stringify(result)
	output.text = data
	print("ADA_ATMOSPHERE_RESULT " + data)
	var file := FileAccess.open("user://result.json", FileAccess.WRITE)
	file.store_string(data)
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()
