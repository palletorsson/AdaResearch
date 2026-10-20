extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func make_page(pinned: bool = false) -> Node3D:
	var page = load("res://algorithms/randomness/randomnumbergeneration/scenes/random_number_book_page_1955.tscn").instantiate()
	page.grid_width = 3
	page.grid_height = 4
	page.set_meta("config_row_stream", "true")
	page.set_meta("config_cascade_speed", "0.4")
	if pinned: page.page_seed = 42
	page.set_process(false)
	root.add_child(page)
	return page

func run() -> void:
	var page = make_page()
	check(page.row_stream and is_equal_approx(page.cascade_speed, 0.4), "Map configuration must enable the slow stream")
	check(page._cells[0][0].text == "" and page._cells[3][2].text == "", "Live page starts empty")
	page._on_cell_touched(null, 2, 0)
	check(not page._frozen[2][0], "An empty address cannot be kept")
	page._process(0.0)
	var first: String = page._cells[0][0].text
	check(first.length() == 5 and page._cells[1][0].text == "", "Only the top row arrives first")
	page._process(0.9)
	page._process(1.5)
	check(page._cells[1][0].text == "", "No second row before 2.5 seconds")
	page._process(0.1)
	check(page._cells[1][0].text == first, "The same value descends one row")
	var upper: float = page._row_y(0)
	var lower: float = page._row_y(1)
	page._advance_stream(0.45)
	check(page._cells[1][0].position.y < upper and page._cells[1][0].position.y > lower, "Downward travel has an intermediate position")
	page._on_cell_touched(null, 1, 0)
	check(page._frozen[1][0] and is_equal_approx(page._cells[1][0].position.y, lower), "A mid-slide touch keeps the value at its address")
	page._advance_stream(1.0)
	var next: String = page._cells[0][0].text
	page._cascade_step()
	page._advance_stream(1.0)
	check(page._cells[1][0].text == first and page._cells[2][0].text == next, "A held cell survives while the stream uses the remaining addresses")
	check(page._cells[1][0].modulate == page.COLOR_FROZEN, "The selection remains visibly amber")
	page._on_cell_touched(null, 1, 0)
	check(not page._frozen[1][0], "Touch again releases the selection")
	page._cascade_step()
	page.apply_grid_config({"disclosure":"origin"})
	check(page._stream_moves.is_empty(), "Reprinting cancels old animation references")
	page._process(10.0)
	check(page._cells[0][0].text.length() == 5 and page._cells[1][0].text == "", "A long frame admits one row, not a catch-up burst")
	var printed = make_page(true)
	var printed_value: String = printed._cells[0][0].text
	check(printed._cells[3][2].text.length() == 5, "Seeded printed pages still start full")
	printed._process(100.0)
	check(printed._cells[0][0].text == printed_value and printed._stream_moves.is_empty(), "Seeded printed pages remain static")
	page.free()
	printed.free()
	if failures.is_empty():
		print("PASS: RAND top-entry cadence, downward slide, selection, reprint and printed-page checks")
	else:
		for message in failures: push_error(message)
	quit(0 if failures.is_empty() else 1)
