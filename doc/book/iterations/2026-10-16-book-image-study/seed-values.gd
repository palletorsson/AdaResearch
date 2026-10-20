extends SceneTree
## Compare the actual falling page with the actual window's RGB channel stream.
const DEST := "res://doc/book/iterations/2026-10-16-book-image-study/seed-values.json"
const HallSeed = preload("res://commons/artifacts/randomness_space/hall_seed.gd")
const Page = preload("res://algorithms/randomness/randomnumbergeneration/scenes/random_number_book_page_1955.tscn")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func first_row(book: Node) -> Array:
	book._cascade_step()
	book._advance_stream(10.0)
	var values: Array = []
	for cell in book._cells[0]: values.append(cell.text)
	return values

func run() -> void:
	var stage := Node3D.new()
	stage.set_meta("hall_seed_scope", true)
	root.add_child(stage)
	var book: Node = Page.instantiate()
	book.row_stream = true
	book.cascade_speed = 0.4
	book.set_meta("config_hall_seed", "435")
	stage.add_child(book)
	book.set_process(false)
	var window: Node = load("res://algorithms/randomness/seed_replay/seed_replay_demo.gd").new()
	window.grid_cols = 4
	window.grid_rows = 3
	window.comparison = "seed_witness"
	window.mapping_study = true
	window.set_meta("config_hall_seed", "435")
	stage.add_child(window)
	window.set_process(false)
	var page_values := first_row(book)
	var float_values: Array = Array(window.raw_prefix(0, 10))
	check(page_values == ["49811", "52985", "14221", "32851", "99985", "42826", "29628", "90639", "90948", "55830"], "435 reference groups")
	check(book.page_number == 1 and book.side_number == 1, "Default folio is independent page 1")
	for pair in [[0.0,"00000"],[0.00001,"00001"],[0.01234999,"01234"],[0.12345999,"12345"],[0.999999,"99999"],[1.0,"99999"]]:
		check(book.five_digits_from_value(pair[0]) == pair[1], "Truncation/zero padding/end point %s" % pair[0])
	for seed_value in [0, 435, 436, 999]:
		check(HallSeed.choose(window, seed_value), "Hall accepts chosen seed %d" % seed_value)
		var prefix: Array = Array(window.raw_prefix(0, 30))
		var channels: Array = []
		for colour in window.column_colors(0): channels.append_array([colour.r, colour.g, colour.b])
		check(channels.slice(0,30) == prefix, "Actual RGB colours use the claimed prefix")
		var observed: Array = []
		for row in 3: observed.append_array(first_row(book))
		for i in 30:
			check(observed[i] == "%05d" % mini(int(prefix[i] * 100000.0), 99999), "Shared stream: seed %d draw %d" % [seed_value, i])
	check(HallSeed.reset(window), "Hall resets to 435")
	check(first_row(book) == page_values, "Hall reset repeats the first ten")
	book._on_cell_touched(null, 0, 0)
	var rng_state: int = book._rng.state
	book.apply_grid_config({"page_number": 474})
	check(book.side_number == 474 and book.label3D_side_number.text == "474", "Folio can change separately")
	check(book._rng.state == rng_state, "Folio edit consumes no draws")
	check(book._cells[0][0].text == "49811" and book._frozen[0][0], "Folio edit preserves held group")
	first_row(book)
	check(book._cells[0][0].text == "49811", "Held group stays as the next row arrives")
	var next: float = window.raw_prefix(0,11)[10]
	check(book._cells[1][0].text == "%05d" % int(next * 100000.0), "Next stream value passes the held address")
	check(HallSeed.reset(window), "Replay after holding")
	check(first_row(book) == page_values and book.side_number == 474, "Replay repeats numbers without changing folio")
	var printed: Node = Page.instantiate()
	printed.page_seed = 435
	printed.page_number = 72
	root.add_child(printed)
	check(printed._pinned and printed.side_number == 72, "Printed page retains separate folio")
	for col in 10: check(printed._cells[0][col].text == page_values[col], "Printed mode shares stream")
	var rng := RandomNumberGenerator.new()
	rng.seed = 435
	var raw: Array = []
	for i in 10: raw.append(rng.randi())
	var record := {
		"seed": 435,
		"engine": Engine.get_version_info().string,
		"scope": "Fresh deterministic reset; no values consumed from a running visitor session.",
		"book_page_number": 1,
		"book_first_ten_groups": page_values,
		"book_procedure": "One randf() per group, truncated at five fractional digits and zero-padded. Folio is an independent address and consumes no random draw.",
		"window_first_ten_values": float_values,
		"window_procedure": "Actual seed_replay_demo.raw_prefix(0,10), seed 435, no skipped values. Verified against RGB channels in the actual baseline grid: three values per cell.",
		"raw_randi_first_ten": raw,
		"checks": checks,
		"failures": failures,
		"replay": "Hall resets repeat the sequence. Four seeds agree across actual RGB channels and three incoming page rows. Folio changes preserve generator state and held groups. Printed mode agrees."
	}
	if failures.is_empty():
		FileAccess.open(DEST, FileAccess.WRITE).store_string(JSON.stringify(record, "  "))
		print("PASS: ", checks, " page/window sequence checks; ", page_values)
	else:
		for message in failures: push_error(message)
	printed.free()
	stage.queue_free()
	for i in 3: await process_frame
	quit(0 if failures.is_empty() else 1)
