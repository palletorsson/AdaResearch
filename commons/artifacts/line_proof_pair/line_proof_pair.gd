extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Two copies of the existing plus puzzle; one difference in the predicate.
## Floor-standing bench. All dimensions are metres.

const LIVE_PLUS = preload("res://commons/artifacts/line_proof_pair/repeatable_plus.gd")
const STEP := 0.16
var puzzles: Array = []
var verdicts: Array[Label3D] = []
var shifts := [0.0, 0.0]

func _ready() -> void:
	var casing := material("20313d")
	var trim := material("8ac8ca")
	box(Vector3(0, 0.79, -0.05), Vector3(2.8, 0.10, 0.92), casing, true)
	for x in [-1.14, 1.14]:
		box(Vector3(x, 0.37, -0.05), Vector3(0.10, 0.74, 0.60), casing, true)
	box(Vector3(0, 0.846, -0.05), Vector3(0.012, 0.012, 0.90), trim)
	box(Vector3(0, 1.87, -0.015), Vector3(2.46, 0.30, 0.04), casing)
	for x in [-1.3, 1.3]:
		box(Vector3(x, 1.39, -0.06), Vector3(0.022, 1.10, 0.022), trim)
	label("WHAT COUNTS AS A PLUS?", Vector3(0, 1.94, 0.03), 0.0012)
	label("Make a cross. Move both lines. Compare the answers.", Vector3(0, 1.81, 0.03), 0.00085)
	for i in range(2):
		var x := -0.7 if i == 0 else 0.7
		var puzzle = LIVE_PLUS.new()
		puzzle.name = "PuzzleA" if i == 0 else "PuzzleB"
		puzzle.proof = "relation" if i == 0 else "invariant"
		puzzle.stock = "scattered"
		puzzle.position = Vector3(x, 1.32, 0.12)
		puzzle.rotation.y = PI / 2.0
		add_child(puzzle)
		puzzles.append(puzzle)
		var caption := label("A" if i == 0 else "B", Vector3(x, 1.66, 0.03), 0.0009)
		caption.modulate = Color("8ac8ca")
		var verdict := label("NOT YET", Vector3(x, 0.91, 0.47), 0.0009)
		verdict.rotation_degrees.x = -35.0
		verdicts.append(verdict)
		puzzle.verdict_changed.connect(_show_verdict.bind(i))
		for j in range(3):
			var id := "%d:%d" % [i, j]
			var b = PUSH.instantiate()
			b.name = "CompareButton_%d_%d" % [i, j]
			b.position = Vector3(x + (j - 1) * 0.27, 0.89, 0.21)
			b.scale = Vector3.ONE * 0.8
			b.released_color = Color("365d70")
			b.pressed_color = Color("91f0cc")
			add_child(b)
			buttons[id] = b
			b.pressed.connect(act.bind(id))
			var text: String = ["MOVE LEFT", "RESET", "MOVE RIGHT"][j]
			var c := label(text, b.position + Vector3(0, 0.025, 0.095), 0.00065)
			c.rotation_degrees.x = -60.0
	for child in get_children():
		if child is Label3D:
			child.outline_size = 3

func _show_verdict(accepted: bool, i: int) -> void:
	verdicts[i].text = "ACCEPTED" if accepted else "NOT YET"
	verdicts[i].modulate = Color("91f0cc") if accepted else Color("f7eeda")

func act(id: String) -> void:
	var parts := id.split(":")
	var i := int(parts[0])
	var action := int(parts[1])
	if not puzzles[i].ready_for_comparison:
		return
	if action == 1:
		shifts[i] = 0.0
		puzzles[i].reset_puzzle()
		return
	# Local Z becomes bench X. Keep the button-driven translation within
	# each bay; the handles remain freely movable by the visitor.
	var next := clampf(shifts[i] + (-STEP if action == 0 else STEP), -STEP, STEP)
	puzzles[i].translate_relation(Vector3(0, 0, next - shifts[i]))
	shifts[i] = next
