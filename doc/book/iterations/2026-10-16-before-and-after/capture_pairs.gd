extends SceneTree
## Controlled continuation of the archived arrival state, not a visitor trial.
const Capture = preload("res://commons/book/installation_capture.gd")
const DIR := "res://doc/book/iterations/2026-10-16-before-and-after/captures/"
const BASE := "res://doc/book/iterations/2026-10-16-arrival-wall/captures/2026-10-16T12-20-04-12259703/"
var checks := 0
var failures: Array[String] = []
var receipts: Array = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func vec(a: Array) -> Vector3: return Vector3(a[0],a[1],a[2])
func take(source: Node3D, archived: Dictionary, id: String, protocol: Dictionary) -> void:
	var before: Dictionary = source.capture_book_state() if source.has_method("capture_book_state") else source.capture()
	var camera := Capture.new(); root.add_child(camera)
	var choice: Dictionary = archived.choice.duplicate(true); choice.id = id
	camera.freeze(source,choice)
	camera.receipt.method = "Native Godot geometry in a controlled reconstruction of the archived arrival. Same camera, lighting and filter as the baseline. Interaction is scripted and declared; no marks are painted into the image."
	camera.receipt.protocol = protocol
	camera.receipt.baseline_receipt = BASE+"capture.json"
	var result: Dictionary = await camera.render(DIR)
	check(result.ok,"Capture saved: "+id)
	if result.ok: receipts.append(result.receipt)
	var after: Dictionary = source.capture_book_state() if source.has_method("capture_book_state") else source.capture()
	check(before==after,"Camera changes no instrument state: "+id)
	camera.queue_free()
	for frame in 3: await process_frame
func run() -> void:
	root.size = Vector2i(1200,900)
	var hall := Node3D.new(); hall.set_meta("em_map","Random_Definition"); root.add_child(hall)
	var archive: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE+"capture.json"))
	var originals: Dictionary = {}
	for item in archive.images: originals[item.id] = item
	var abacus: Node3D = load("res://commons/artifacts/random_touch/random_touch.tscn").instantiate()
	hall.add_child(abacus); abacus.set_process(false); abacus.set_physics_process(false)
	var book: Node3D = load("res://algorithms/randomness/randomnumbergeneration/scenes/random_number_book_page_1955.tscn").instantiate()
	book.apply_grid_config({"row_stream":"true","initial_rows":"10","cascade_speed":"0.4"})
	hall.add_child(book); book.set_process(false); book.set_physics_process(false)
	for pair in [[abacus,"abacus"],[book,"page"]]:
		var pose: Array = originals[pair[1]].source_transform
		pair[0].global_transform = Transform3D(Basis(vec(pose[0]),vec(pose[1]),vec(pose[2])),vec(pose[3]))
	for frame in 3: await process_frame
	check(abacus.restore(originals.abacus.state),"Archived abacus record restores")
	abacus.paused = false
	check(abacus.capture().points==originals.abacus.state.points,"Abacus uses archived targets")
	await take(abacus,originals.abacus,"abacus-before",{"action":"none","state":"archived arrival reconstructed"})
	var pointer := Node3D.new();hall.add_child(pointer)
	for lane in 5:
		abacus.points[lane].on_desktop_grab(pointer)
		check(abacus.begin_motion(lane),"Scripted contact begins row "+str(lane+1))
		abacus.advance(48.0/float(abacus.record.rates[lane]))
		abacus.stop_motion(); abacus.advance(2.0)
		check(abacus.ink.marks[lane].size()==576,"48 segments leave 576 marks on row "+str(lane+1))
	for lane in range(1,4): check(abacus.ink.marks[0]==abacus.ink.marks[lane],"Equal segment counts repeat X marks at different speeds")
	var matches := true
	for i in 576: matches = matches and is_equal_approx(abacus.ink.marks[0][i][0],abacus.ink.marks[4][i][0])
	check(matches,"Fifth row preserves X trace while adding Y")
	check(abacus.record.distribution=="uniform","Target distribution remains uniform")
	await take(abacus,originals.abacus,"abacus-after",{"action":"desktop grab each bead, advance 48 segments, release and let return","segments_per_row":48,"marks_per_row":576,"simulated_seconds_per_row":[120,60,30,15,60],"human_trial":false})
	# Rebuild the original full page through its normal row-step methods.
	for row in 18: book._cascade_step(); book._advance_stream(10.0)
	check(book.book_capture_ready(),"Reconstructed page is full and settled")
	check(book.capture_book_state().digits==originals.page.state.digits,"All 280 reconstructed groups equal archived arrival")
	check(str(book._rng.state)==originals.page.state.rng_state,"Generator resumes exact archived state")
	await take(book,originals.page,"page-before",{"action":"18 normal row steps after 10 seeded rows; settle each","state":"same digits and RNG state as archived full page"})
	var row := 3; var col := 2
	var selected: String = book._cells[row][col].text
	var location: Vector3 = book._cells[row][col].position
	var previous: Array = book.capture_book_state().digits
	book._on_cell_touched(pointer,row,col)
	for step in 2: book._cascade_step(); book._advance_stream(10.0)
	check(book._cells[row][col].text==selected and book._frozen[row][col],"Selected five digits survive two later rows")
	check(book._cells[row][col].position==location,"Held group stays at its original address")
	check(book._cells[row][col+1].text==previous[row-2][col+1],"Unheld neighbour moves down two rows")
	check(book.book_capture_ready(),"After page is full and settled")
	await take(book,originals.page,"page-after",{"action":"touch row 4 column 3; advance two rows and settle","selected_group":selected,"row_one_based":4,"column_one_based":3,"rows_advanced":2,"human_trial":false})
	FileAccess.open(DIR+"capture.json",FileAccess.WRITE).store_string(JSON.stringify({"schema":"ada-comparison-captures/1","baseline":BASE+"capture.json","scope":"Scripted interaction with actual artifact scenes, reconstructed from archived baseline; not a human VR trial.","checks":checks,"failures":failures,"images":receipts},"  ",true,true))
	print("COMPARISON CAPTURES: ",checks," checks; failures=",failures)
	quit.call_deferred(0 if failures.is_empty() else 1)
