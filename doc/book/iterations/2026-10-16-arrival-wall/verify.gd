extends SceneTree
const Wall = preload("res://commons/book/arrival_wall.gd")
const DIR := "res://doc/book/iterations/2026-10-16-arrival-wall/"
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func run() -> void:
	root.size = Vector2i(1200,900)
	var hall := Node3D.new(); hall.set_meta("em_map","Random_Definition");root.add_child(hall)
	var sources: Array[Node3D] = []
	var paths := ["res://commons/artifacts/random_touch/random_touch.tscn",
		"res://algorithms/randomness/randomnumbergeneration/scenes/random_number_book_page_1955.tscn",
		"res://commons/artifacts/geiger_counter/geiger_counter.tscn"]
	var ids := ["random_touch","random_number_book_page_1955","geiger_counter"]
	for i in 3:
		var source: Node3D = load(paths[i]).instantiate()
		source.set_meta("em_cartridge_token",ids[i])
		if i == 1:
			source.apply_grid_config({"row_stream":"true","initial_rows":"10"})
		hall.add_child(source)
		source.position = Vector3(4,0,5+i*6)
		source.rotation.y = 0.6+i
		source.set_process(false);source.set_physics_process(false)
		sources.append(source)
	var geiger: Node3D = sources[2]
	geiger._audio.stop()
	for i in 9:
		var mark: MeshInstance3D = geiger.dial_marks[i]
		var radial: Vector3 = mark.position-geiger._needle.position
		check(is_equal_approx(radial.length(),geiger.DIAL_RADIUS),"Marks share a circular radius")
		check(radial.normalized().dot(mark.basis.y)>0.9999,"Mark points radially")
		check(is_equal_approx(mark.rotation.z,geiger.dial_angle(i*1.5)),"Needle and tick use one radian scale")
	check(geiger.dial_angle(0)>0 and is_zero_approx(geiger.dial_angle(6)) and geiger.dial_angle(12)<0,"Rate increases from left to right")
	var book: Node3D = sources[1]
	var seeded: Dictionary = book.capture_book_state()
	var filled := 0
	for row in seeded.digits:
		if (row as Array).all(func(value): return not str(value).is_empty()): filled += 1
	check(filled==10 and not book.book_capture_ready(),"Ten rows are visible at startup; incomplete page cannot be captured")
	var reference := RandomNumberGenerator.new(); reference.seed = 435
	for row in range(9,-1,-1):
		for col in 10:
			check(book._cells[row][col].text==book.five_digits_from_value(reference.randf()),"Seeded rows preserve chronological draw order")
	var kept_seeded: Array = seeded.digits.duplicate(true)
	book.HallSeed.reset(book)
	check(book.capture_book_state().digits==kept_seeded,"Reset recreates the same ten seeded rows")
	var next_group: String = book.five_digits_from_value(reference.randf())
	book._cascade_step(); book._advance_stream(10.0)
	check(book._cells[0][0].text==next_group,"Falling rows continue after the first hundred values")
	book.HallSeed.reset(book)
	var initial_rng: int = book._rng.state
	var initial_book: Dictionary = book.capture_book_state()
	var initial_abacus: Dictionary = sources[0].capture()
	var choices: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/Random_Definition/book_images.json"))
	var wall := Wall.new();hall.add_child(wall);wall.output_root = DIR+"fixture"
	wall.begin.call_deferred(hall,Vector3.ZERO,choices)
	var wait_started := Time.get_ticks_msec()
	while wall.record.get("images",[]).size()<2 and Time.get_ticks_msec()-wait_started<10000: await process_frame
	check(wall.record.images.size()==2 and wall.record.waiting==["page"] and not wall.finished,"Other pictures complete while the page waits")
	check(book._rng.state==initial_rng and book.capture_book_state()==initial_book,"Waiting neither draws numbers nor advances the page")
	check(wall.frames.page.get_node_or_null("CaptureStatus")!=null,"Waiting frame explains what it is waiting for")
	# Explicit test input only: production waits for normal process ticks.
	for row in range(book._built_rows-10):
		book._cascade_step()
		if row < book._built_rows-11: book._advance_stream(10.0)
	check(not book.book_capture_ready(),"A full but still moving page is not ready")
	for frame in 2: await process_frame
	check(wall.record.images.size()==2,"Camera also waits for the last row to settle")
	book._advance_stream(10.0)
	initial_rng = book._rng.state
	initial_book = book.capture_book_state()
	check(book.book_capture_ready(),"Every cell is filled and fully visible")
	if not wall.finished: await wall.completed
	check(wall.record.images.size()==3 and wall.record.errors.is_empty(),"Three real photographs saved")
	check(book._rng.state==initial_rng and book.capture_book_state()==initial_book,"Capture consumes no page values or state")
	check(sources[0].capture()==initial_abacus,"Capture adds no touch, trace or movement")
	for item in wall.record.images:
		var path: String = wall.record.folder.path_join(item.image)
		check(FileAccess.get_sha256(path)==item.sha256,"Saved image checksum")
		check(wall.frames[item.id].get_meta("book_image_sha256")==item.sha256,"Frame uses saved photograph")
		var disk := Image.load_from_file(path)
		var texture: Texture2D = wall.frames[item.id].material_override.albedo_texture
		check(disk.get_data()==texture.get_image().get_data(),"Wall pixels equal PNG pixels")
		check(item.visual_count>0 and item.camera_height>0,"Camera and real geometry recorded")
		if item.id=="page":
			check(item.state==initial_book and item.state.full_and_settled,"Full settled page is honestly kept")
			check(item.capture_when=="page_full","Receipt records the delayed capture condition")
		if item.id=="abacus":check(item.state==initial_abacus,"Untouched abacus is honestly kept")
	for i in 3: await process_frame
	check(wall.find_children("*","SubViewport",true,false).is_empty(),"No capture viewports remain active")
	check(wall.frames.page.get_node_or_null("CaptureStatus")==null,"Ready picture replaces the waiting message")
	var previous: Dictionary = wall.record.duplicate(true)
	await wall.begin(hall,Vector3.ZERO,choices)
	check(wall.record==previous,"Repeated arrival call cannot overwrite the kept image")
	FileAccess.open(DIR+"verification.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"capture":wall.record},"  "))
	print("ARRIVAL WALL: ",checks," checks; failures=",failures)
	quit.call_deferred(0 if failures.is_empty() else 1)
