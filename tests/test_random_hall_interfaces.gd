extends SceneTree
var failures: Array[String] = []
func check(ok: bool, reason: String) -> void:
	if not ok: failures.append(reason)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var geiger = load("res://commons/artifacts/geiger_counter/geiger_counter.gd").new()
	root.add_child(geiger)
	check(geiger._audio.playing and not geiger._audio.stream_paused,"Geiger begins without a button")
	var events: Array = geiger.current.events_us.duplicate()
	geiger._finished()
	check(geiger._audio.playing and geiger.current.events_us==events,"Geiger loops the same recorded events")
	geiger.toggle_sound()
	check(geiger._audio.playing and not geiger.sound_on,"Mute preserves continuous timing")
	geiger._board.find_child("Btn_4",true,false).pressed.emit()
	check(geiger._audio.playing and geiger.current.events_us==events and geiger.current.clock_us==100000,"Embedded clock button reinterprets identical clicks")
	check(geiger._board.position.x==0 and geiger._board.position.z<.2,"Controls mounted on machine face")
	check(geiger._board.rotation==Vector3.ZERO and not geiger._board.has_meta("em_local_instrument"),"Geiger controls form part of cabinet")
	check(geiger._board.find_children("Btn_*","",true,false).size()==10,"All ten Geiger actions retained")
	var lava = load("res://commons/artifacts/lava_entropy_wall/lava_entropy_wall.gd").new()
	root.add_child(lava)
	lava._board.find_child("Btn_0",true,false).pressed.emit()
	var baseline_hash: String = lava.baseline.sha256
	lava._board.find_child("Btn_8",true,false).pressed.emit()
	check(lava.current.sha256!=baseline_hash and lava.baseline.sha256==baseline_hash,"Embedded cover button changes capture only")
	check(lava._board.position.z<.2 and lava._board.rotation==Vector3.ZERO,"Lava controls mounted in centre wall bay")
	check(lava._status.position.y<.6 and not lava._board.has_meta("em_local_instrument"),"Lava status and controls integrated")
	var page = load("res://algorithms/randomness/randomnumbergeneration/scenes/random_number_book_page_1955.tscn").instantiate()
	page.row_stream=true
	page.grid_width=3; page.grid_height=4
	root.add_child(page)
	page.set_process(false)
	var sign = page.get_node_or_null("SelectStand")
	check(sign!=null and sign.get_node("TextViewport/Select").text=="select","Small stand carries one 2D label")
	check(sign.position.z<0 and is_equal_approx(sign.rotation.y,PI),"Sign faces the page's approach side")
	page._process(0.0); page._advance_stream(1.0)
	page._on_cell_touched(null,0,0)
	var kept: String = page._cells[0][0].text
	page._cascade_step(); page._advance_stream(1.0)
	check(page._cells[0][0].text==kept,"Sign does not alter selection behaviour")
	page.apply_grid_config({"disclosure":"tally"})
	await process_frame
	check(page.get_node("SelectStand")==sign,"Reprinting does not duplicate or remove sign")
	var journey = load("res://commons/artifacts/random_return/random_return.gd").new()
	journey.route_link="test"
	root.add_child(journey)
	check(journey.readout==null,"Random Return has no explanatory board")
	check(journey.own_panel==null,"Linked return retains the shared source controls")
	var before: Vector3 = journey.point.position
	journey.advance(3)
	check(journey.point.position!=before,"Return motion survives board removal")
	check(journey.restart(43),"Return restart still works")
	geiger.queue_free(); lava.queue_free(); page.queue_free(); journey.queue_free()
	await process_frame
	for failure in failures: push_error(failure)
	print("RANDOM HALL INTERFACES: ","PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
