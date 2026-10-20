extends "res://doc/book/iterations/2026-10-13-four-by-four-seed/museum_probe.gd"
const Client = preload("res://algorithms/randomness/seed_replay/atmospheric_seed.gd")

class StubClient extends "res://algorithms/randomness/seed_replay/atmospheric_seed.gd":
	var urls: Array[String] = []
	func _send(url: String) -> void: urls.append(url)
	func reply(body: String, code: int = 200, result: int = HTTPRequest.RESULT_SUCCESS) -> void:
		_completed(result, code, PackedStringArray(), body.to_utf8_buffer())

func landing_checks() -> void:
	await super.landing_checks()
	var demo := find_scene("/seed_replay_demo.gd")
	if demo == null: return
	check("only opted-in museum bench has atmospheric control", demo.atmosphere)
	var button := demo.find_child("Btn_3", true, false)
	check("ATMOSPHERE has a real hand button", button != null)
	if button == null: return
	var client: Node = demo._atmosphere_client
	check("network idle on arrival", not client.is_busy())
	check("HTTPS timeout and size limit configured", client._http.timeout == 120.0 and client._http.body_size_limit == 4096)
	var before: Dictionary = demo.capture_museum_state()
	var area := button.get_node("InteractableAreaButton")
	area.button_pressed.emit(area)
	check("hand button starts asynchronous request", client.is_busy())
	check("second press cannot overlap request", not demo.request_atmospheric_seed())
	check("request leaves current seed intact while pending", demo.current_seed() == before.seed)
	var start := Time.get_ticks_msec()
	while client.is_busy() and Time.get_ticks_msec() - start < 125000:
		await process_frame
	var received: Dictionary = demo.capture_museum_state()
	var receipt: Dictionary = received.get("source_receipt", {})
	check("live Godot HTTPS request received RANDOM.ORG seed", receipt.get("provider", "") == "RANDOM.ORG")
	observations["live_receipt"] = receipt
	observations["live_status"] = demo._source_label.text
	if not receipt.is_empty():
		check("returned integer is displayed without remapping", demo.current_seed() == receipt.seed and demo.current_seed() >= 0 and demo.current_seed() <= 999)
		var colours: PackedColorArray = demo.column_colors(0)
		demo.replay()
		check("atmospheric seed replays the exact same grid locally", demo.column_colors(0) == colours and not client.is_busy())
		var rng := RandomNumberGenerator.new()
		rng.seed = int(receipt.seed)
		var expected := PackedColorArray()
		for i in range(16): expected.append(Color(rng.randf(), rng.randf(), rng.randf()))
		check("colours still come from the seeded Godot procedure", colours == expected)
		demo.randomize_seed()
		check("local random seed clears atmospheric attribution", demo.capture_museum_state().source_receipt.is_empty())
		demo.restore_museum_state(received)
		check("room restore keeps receipt and pattern without network", demo.capture_museum_state().source_receipt == receipt and demo.column_colors(0) == colours and not client.is_busy())
	await snapshot("atmosphere-bench", demo.to_global(Vector3(0,2.3,4.6)), demo.to_global(Vector3(0,2.0,0)), 55)
	await snapshot("atmosphere-controls", button.global_position + Vector3(0,0.4,-1.25), button.global_position, 48)
	# Deterministic failure responses, without sending further requests to the service.
	client.queue_free()
	await tick()
	var fake := StubClient.new()
	demo.add_child(fake)
	demo._atmosphere_client = fake
	fake.received.connect(demo._receive_atmospheric_seed)
	fake.status_changed.connect(demo._show_seed_source)
	var kept: Dictionary = demo.capture_museum_state()
	for bad in ["Error: busy", "123\n456", "1000", "-1", "<html>offline</html>"]:
		Client._retry_after_msec = 0
		demo.request_atmospheric_seed()
		fake.reply("1000") # quota
		fake.reply(bad)
		check("bad reply preserves seed and receipt: " + bad.replace("\n", "/"), demo.capture_museum_state() == kept and not fake.is_busy())
	Client._retry_after_msec = 0
	demo.request_atmospheric_seed()
	var requests_before := fake.urls.size()
	fake.reply("-10")
	check("negative quota never requests a number", fake.urls.size() == requests_before)
	check("negative quota backs off ten minutes", Client._retry_after_msec - Time.get_ticks_msec() > 599000 and not demo.request_atmospheric_seed())
	for failure in [[503, HTTPRequest.RESULT_SUCCESS], [0, HTTPRequest.RESULT_TIMEOUT]]:
		Client._retry_after_msec = 0
		demo.request_atmospheric_seed()
		fake.reply("", failure[0], failure[1])
		check("HTTP/connection failure preserves current picture " + str(failure), demo.capture_museum_state() == kept and not fake.is_busy())
	Client._retry_after_msec = 0
	demo.request_atmospheric_seed()
	fake.reply("1000")
	demo.randomize_seed()
	var edited: int = demo.current_seed()
	check("a pending request cannot be restarted after editing", not demo.request_atmospheric_seed())
	fake.reply("321")
	check("late reply cannot overwrite a visitor edit", demo.current_seed() == edited and demo.capture_museum_state().source_receipt.is_empty())
	var count := fake.urls.size()
	demo.replay()
	check("offline replay does not fetch anything", fake.urls.size() == count)
	var ordinary: Node = load("res://algorithms/randomness/seed_replay/seed_replay_demo.tscn").instantiate()
	root.add_child(ordinary)
	check("ordinary bench stays offline and has no extra button", ordinary._atmosphere_client == null and ordinary.find_child("Btn_3", true, false) == null and not ordinary.request_atmospheric_seed())
	ordinary.queue_free()
	observations["scope"] = "Live museum and Godot HTTPS; hand-button signal exercised; synthetic failure responses. Not tested on a physical Quest."
