extends Control
## Preview the same tract interpolation the Phoneme Library renderer uses.

const Robot := preload("res://audio/generators/RobotVoiceGenerator.gd")
const Phoneme := preload("res://audio/generators/PhonemeVoice.gd")
const TEXT := Color("efe9dc")
const MUTED := Color("9aa0ad")
const VOWEL := Color("285d57")
const CONSONANT := Color("454b5b")
const MARKER := Color("f2a23a")

var _plan := {}
var _tract := {}
var _frame := 0
var following := false


func _ready() -> void:
	resized.connect(_fit_height)
	_fit_height()


func show_phrase(plan: Dictionary, ratio: float, speed := 1.0, tuned := true) -> void:
	_plan = Phoneme.timed_plan(plan, speed)
	_tract = Robot.build_tract(_plan, ratio, Phoneme.vowel_tracts(tuned))
	_frame = 0
	_fit_height()
	queue_redraw()


func set_frame(frame: int) -> void:
	if _plan.is_empty():
		return
	_frame = clampi(frame, 0, int(_plan.frames) - 1)
	queue_redraw()


## Readable cells are independent of time. Even a 28 ms stop gets its own label.
func _cells() -> Array[Rect2]:
	var cells: Array[Rect2] = []
	var x := 12.0
	var y := 34.0
	var previous_word := -1
	for phone: Dictionary in _plan.get("phones", []):
		var word := 0
		for group: Dictionary in _plan.word_groups:
			if phone.start < group.end:
				break
			word += 1
		if previous_word >= 0 and previous_word != word:
			x += 8.0
		var width := maxf(30.0, get_theme_default_font().get_string_size(_phone_symbol(phone), HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 14.0)
		if x + width > maxf(240.0, size.x - 12.0) and x > 12.0:
			x = 12.0
			y += 32.0
		cells.append(Rect2(x, y, width, 27.0))
		x += width + 3.0
		previous_word = word
	return cells


func _strip() -> Rect2:
	var cells := _cells()
	var y: float = 61.0 if cells.is_empty() else cells.back().end.y
	return Rect2(12.0, y + 21.0, maxf(1.0, size.x - 24.0), 21.0)


func _fit_height() -> void:
	custom_minimum_size.y = _strip().end.y + 83.0
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if following or _plan.is_empty():
		return
	var click: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var drag: bool = event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	if click:
		var cells := _cells()
		for i in cells.size():
			if cells[i].has_point(event.position):
				var phone: Dictionary = _plan.phones[i]
				set_frame((int(phone.start) + int(phone.end)) / 2)
				accept_event()
				return
	if (click or drag) and _strip().has_point(event.position):
		var strip := _strip()
		set_frame(roundi((_plan.frames - 1) * (event.position.x - strip.position.x) / strip.size.x))
		accept_event()


func _draw() -> void:
	var font := get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, size), Color("1d222d"))
	var distinct := {}
	for phone: Dictionary in _plan.get("phones", []):
		distinct[str(phone.kind) + ":" + str(phone.phoneme)] = true
	draw_string(font, Vector2(12, 22), "This phrase · %d sound steps · %d distinct targets" % [_plan.get("phones", []).size(), distinct.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, TEXT)
	if _plan.is_empty() or _tract.has("error"):
		return
	var strip := _strip()
	var cells := _cells()
	for i in cells.size():
		var phone: Dictionary = _plan.phones[i]
		var tile := cells[i]
		draw_rect(tile, VOWEL if phone.kind == "vowel" else CONSONANT)
		if _frame >= int(phone.start) and _frame < int(phone.end):
			draw_rect(tile, MARKER, false, 2.0)
		draw_string(font, Vector2(tile.position.x, tile.position.y + 20.0), _phone_symbol(phone), HORIZONTAL_ALIGNMENT_CENTER, tile.size.x, 16, TEXT)
	draw_string(font, Vector2(12, strip.position.y - 5.0), "Actual duration →", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, MUTED)
	var scale_x := strip.size.x / float(_plan.frames)
	draw_rect(strip, Color("292f3d"))
	for phone: Dictionary in _plan.phones:
		var left := strip.position.x + float(phone.start) * scale_x
		var width := float(phone.end - phone.start) * scale_x
		var vowel: bool = phone.kind == "vowel"
		var active: bool = _frame >= int(phone.start) and _frame < int(phone.end)
		var tile := Rect2(left, strip.position.y, maxf(1.0, width - 1.0), strip.size.y)
		draw_rect(tile, VOWEL if vowel else CONSONANT)
		if active:
			draw_rect(tile, MARKER, false, 1.5)
	var cursor_x := strip.position.x + _frame * scale_x
	draw_line(Vector2(cursor_x, strip.position.y - 4.0), Vector2(cursor_x, strip.end.y + 3.0), MARKER, 2.0)

	var span := Robot.tract_blend(_tract, _frame)
	var from := _phone_symbol(_plan.phones[int(span[0]) / 2])
	var to := _phone_symbol(_plan.phones[int(span[1]) / 2])
	var formants: Array = Robot.tract_at(_tract, _frame)[0]
	var blend := float(span[2])
	var shape := "%s → %s   ·   %d%% toward %s" % [from, to, roundi(blend * 100.0), to] if from != to else "%s   ·   held" % from
	draw_string(font, Vector2(12, strip.end.y + 24.0), "%4.2f s   ·   %s" % [float(_frame) / Robot.SR, shape],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, TEXT)
	if from != to and size.x > 460.0:
		var bar := Rect2(size.x - 156.0, strip.end.y + 13.0, 144.0, 11.0)
		draw_rect(bar, VOWEL)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * blend, bar.size.y)), MARKER)
	draw_string(font, Vector2(12, strip.end.y + 46.0), "F1 %d Hz   ·   F2 %d Hz   ·   F3 %d Hz" %
		[roundi(formants[0]), roundi(formants[1]), roundi(formants[2])], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, MUTED)
	draw_string(font, Vector2(12, strip.end.y + 69.0), "Click a sound or drag time to inspect. A glide can use two targets.",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MUTED)


func _phone_symbol(phone: Dictionary) -> String:
	var symbol := str(phone.phoneme)
	return Phoneme.display_symbol(str(phone.kind), symbol)
