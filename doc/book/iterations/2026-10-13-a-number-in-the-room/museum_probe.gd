extends "res://doc/book/iterations/2026-10-13-atmosphere-in-the-headset/museum_probe.gd"

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(0.5).timeout
	var demo := find_scene("/seed_replay_demo.gd")
	check("opening instrument exists", demo != null)
	if demo == null: return
	var opening: Dictionary = demo.capture_museum_state()
	check("hall starts with the actual recorded seed 435", demo.current_seed() == 435 and demo.seed_value == 435)
	check("recorded provenance matches saved receipt", opening.source_receipt.get("recorded",false) and opening.source_receipt.get("received_utc", "") == "2026-10-13T14:29:02Z")
	check("opening needs no live request", not demo._atmosphere_client.is_busy())
	check("large display shows current seed", demo._large_seed.text == "435")
	check("saved origin is explicit", demo._source_label.text.contains("Saved draw") and demo._source_label.text.contains("RANDOM.ORG"))
	var display := demo.get_node("AtmosphereDisplay")
	check("display is above the grids and inside the five-metre hall", display.position.y > 3.2 and display.position.y + 0.61 < 5.0)
	check("opening colours agree before any button press", demo.column_colors(0) == demo.column_colors(1))
	var left: PackedColorArray = demo.column_colors(0)
	await snapshot("opening-435",demo.to_global(Vector3(0,2.2,4.6)),demo.to_global(Vector3(0,2.5,0)),58)
	await snapshot("number-display",demo.to_global(Vector3(0,3.6,3.0)),display.global_position,50)
	var button := demo.find_child("Btn_2",true,false).get_node("InteractableAreaButton")
	button.button_pressed.emit(button)
	check("actual extra-draw button keeps 435 visible", demo._large_seed.text == "435" and demo.current_seed() == 435)
	check("actual extra-draw button changes only the right grid", demo.column_colors(0) == left and demo.column_colors(1) != left)
	await snapshot("one-draw-later",demo.to_global(Vector3(0,2.2,4.6)),demo.to_global(Vector3(0,2.5,0)),58)
	button.button_pressed.emit(button)
	check("second press restores the recorded comparison", demo.column_colors(0) == demo.column_colors(1) and demo.capture_museum_state().source_receipt == opening.source_receipt)
	# Existing matrix, replay, transport and failure checks, including one live request.
	await super.landing_checks()
	# Parent finishes on an edited local seed after its stale-response check.
	check("large display follows edits as well as fetched seeds", demo._large_seed.text == str(demo.current_seed()))
	demo.restore_museum_state(opening)
	check("return visit recovers large number and source", demo._large_seed.text == "435" and demo._source_label.text.contains("Saved draw"))
	observations["opening_receipt"] = opening.source_receipt
	observations["display_local_y"] = display.position.y
