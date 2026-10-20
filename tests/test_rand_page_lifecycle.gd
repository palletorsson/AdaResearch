extends SceneTree

## Regress the live RAND page through the museum's real cartridge round trip.
const Page = preload("res://algorithms/randomness/randomnumbergeneration/scenes/random_number_book_page_1955.tscn")
const Cartridge = preload("res://commons/scenes/em/em_cartridge.gd")

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)


func run() -> void:
	var hall := Node3D.new()
	root.add_child(hall)
	var page = Page.instantiate()
	page.grid_width = 3
	page.grid_height = 4
	page.row_stream = true
	page.set_meta("em_cartridge_token", "random_number_book_page_1955")
	hall.add_child(page)
	page.set_process(false)
	page._process(0.0)
	page._advance_stream(1.0)
	page._cascade_step()
	page._on_cell_touched(null, 1, 0)
	page._advance_stream(0.1)
	check(not page._stream_moves.is_empty(), "Fixture has an active row animation")
	var labels: Array = []
	var texts: Array[String] = []
	var areas: Array = []
	for row in page._cells:
		for cell in row:
			labels.append(cell)
			texts.append(cell.text)
	for row in page._cell_areas:
		areas.append_array(row)
	var sample: Label3D = page._cells[1][1]
	var previous_y: float = sample.position.y
	var children_before: int = page.get_child_count()
	var folder := "user://rand-page-lifecycle-%d" % Time.get_ticks_usec()
	var result := Cartridge.compile(hall, {"map": "RandPageLifecycle"}, PackedStringArray(), folder)
	check(bool(result.get("ok", false)), "Actual museum cartridge compilation succeeds")
	await process_frame
	await process_frame
	var intact := true
	for i in labels.size():
		var alive: bool = is_instance_valid(labels[i])
		check(alive, "Cell %d survives cartridge detach and reattach" % i)
		intact = intact and alive
		if alive:
			check(labels[i].text == texts[i], "Cell %d keeps its digits" % i)
	for area in areas:
		check(is_instance_valid(area), "Touch area survives cartridge round trip")
	check(page.get_child_count() == children_before, "Round trip neither deletes nor duplicates page nodes")
	# The old implementation errors here at _advance_stream's typed assignment.
	page._advance_stream(0.1)
	if intact:
		check(sample.position.y < previous_y, "The same moving cell continues its slide")
		check(page._frozen[1][0] and page._cells[1][0].text == texts[3], "Kept number retains its address and value")
		for tick in 80:
			page._process(0.5)
		check(page._cells[1][0].text == texts[3], "Kept number survives forty more seconds of streaming")
		page._on_cell_touched(null, 1, 0)
		check(not page._frozen[1][0], "Touch still releases a kept number")
		page.apply_grid_config({"disclosure": "tally"})
		page._process(0.0)
		page._advance_stream(0.1)
		var furniture: Node3D = page._page_furniture
		hall.remove_child(page)
		# Stay detached across a deletion flush, rather than returning immediately.
		await process_frame
		await process_frame
		hall.add_child(page)
		page.set_process(false)
		check(is_instance_valid(furniture) and furniture == page._page_furniture, "Tally furniture survives temporary removal")
		page._process(1.0)
		check(page._cells[0][0].text.length() == 5, "Reprinted page resumes after delayed reattachment")
		# Leave one generated node referenced to verify real destruction still frees it.
		sample = page._cells[0][0]
	hall.queue_free()
	await process_frame
	await process_frame
	check(not is_instance_valid(page), "Deleting the hall deletes its page")
	check(not is_instance_valid(sample), "Deleting the page frees generated labels automatically")
	await check_other_modes()
	# This unique test directory contains only files produced by compile above.
	for name in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(name))
	DirAccess.remove_absolute(folder)
	var report := {"checks": checks, "failures": failures}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="):
			var file := FileAccess.open(arg.trim_prefix("--report="), FileAccess.WRITE)
			if file == null:
				push_error("Cannot write lifecycle test report")
				quit(2)
				return
			file.store_string(JSON.stringify(report, "\t"))
	print("RAND PAGE LIFECYCLE: ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)


func check_other_modes() -> void:
	for seeded in [false, true]:
		var page = Page.instantiate()
		page.grid_width = 2
		page.grid_height = 4
		page.page_seed = 42 if seeded else -1
		root.add_child(page)
		page.set_process(false)
		var first: String = page._cells[0][0].text
		var cell = page._cells[0][0]
		var title = page.get_node("Label3D_Title")
		var count: int = page.get_child_count()
		root.remove_child(page)
		await process_frame
		await process_frame
		root.add_child(page)
		page.set_process(false)
		check(is_instance_valid(cell), "Legacy/seeded page retains cells on reattachment")
		check(is_instance_valid(title), "Legacy/seeded page retains authored title")
		check(page.get_child_count() == count, "Legacy/seeded page retains its node count")
		if is_instance_valid(cell):
			check(cell.text == first, "Reattachment does not regenerate digits")
			page._process(1.0)
			if seeded:
				check(cell.text == first, "Seeded page remains static after reattachment")
			else:
				check(page._cells[1][0].text == first, "Legacy cascade still moves digits down")
		page.queue_free()
		await process_frame
		await process_frame
		check(not is_instance_valid(cell), "Legacy/seeded children are freed with the page")
