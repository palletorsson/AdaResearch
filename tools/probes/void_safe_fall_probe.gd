extends "res://tools/probes/void_game_probe.gd"
## Real production desktop body and Jolt contacts, without authored encounters.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	game=load("res://commons/void/void.tscn").instantiate();root.add_child(game);current_scene=game
	game.body.scripted_input=true;game.body.drive=Vector2.ZERO
	game.scene_loaded();game.scene_visible();await frames(15)
	game.health.reset();game.place_player(Vector3(0,18,5))
	for i in 240:
		await frames(1)
		if game.recovering or (game.body.is_on_floor() and game.body.global_position.y<1):break
	await frames(20)
	check("three-storey gravity drop reaches a real slab alive",game.body.is_on_floor() and absf(game.body.global_position.y)<.1 and game.deaths==0 and not game.recovering)
	check("long drop spends no charge and plays no grunt",is_equal_approx(game.charge.get_charge(),100) and game.soundscape.hurt_count==0 and not game.soundscape.hurt_voice.playing)
	game.place_player(Vector3(0,-21,5));await frames(2);game.body.velocity.y=-25
	for i in 90:
		await frames(1)
		if game.body.is_on_floor() and game.body.global_position.y< -23.5:break
	await frames(30)
	check("high-speed negative-floor landing is safe",game.body.is_on_floor() and absf(game.body.global_position.y+24)<.1 and game.last_impact>13 and game.deaths==0)
	check("landing still saves the lower checkpoint without charge loss",game.checkpoint==4 and is_equal_approx(game.charge.get_charge(),100))
	game.body.jump_queued=true;await frames(120)
	check("same-floor jump lands without damage or sound",game.body.is_on_floor() and is_equal_approx(game.charge.get_charge(),100) and game.soundscape.hurt_count==0)
	game.place_player(Vector3(30,-24,0));await frames(12)
	check("missing the building returns quietly to the checkpoint",game.body.global_position.distance_to(game.spawn_for(4))<.2 and game.deaths==0 and not game.recovering and is_equal_approx(game.charge.get_charge(),100))
	game.soundscape.play_hurt();await frames(2)
	check("legacy hurt hook cannot play the removed pain sound",game.soundscape.hurt_count==0 and not game.soundscape.hurt_voice.playing)
	game.charge.discharge(5,"probe hazard")
	check("non-fall hazard charge remains functional",is_equal_approx(game.charge.get_charge(),95))
	check("desktop help describes safe falls",game.desktop_help.get_children().any(func(n):return n is Label and n.text.contains("Falls and landings are safe")))
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Actual production desktop body, Jolt gravity/contact, long fall, fast negative-floor landing, checkpoint, jump and quiet out-of-bounds return. Empty encounter draft; physical headset not tested."},"  "))
	game.queue_free();await frames(15);quit(0 if failed.is_empty() else 1)
