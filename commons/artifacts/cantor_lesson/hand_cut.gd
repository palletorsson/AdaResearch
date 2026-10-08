extends Node3D
## One enlarged interval is a handle for the same cut across the current row.
const PointBody = preload("res://commons/artifacts/recursive_tree_lesson/fork_point.gd")
const HOME := Vector3(0, 1.27, 0)
const PULL := 0.30
var desk: Node3D
var grip: XRToolsPickable
var caption: Label3D
var instruction: Label3D
var was_held := false
var armed := false
var _last_text := ""

func _ready() -> void:
	desk = get_parent()
	var pale = desk.material("eee9e1")
	var dark = desk.material("28252c")
	desk.box(Vector3(0, 0.52, 0), Vector3(1.45, 1.04, 0.65), pale, true, self)
	for x in [-0.4, 0.4]:
		desk.box(Vector3(x, 1.15, 0), Vector3(0.4, 0.10, 0.12), dark, false, self)
	grip = PointBody.new()
	grip.name = "MiddleThirdPoint"
	grip.tint = Color("e99db8")
	add_child(grip)
	desk.box(Vector3(0, -0.12, 0), Vector3(0.4, 0.10, 0.12), desk.material("e99db8"), false, grip)
	caption = desk.label("", Vector3.ZERO, 0.0009)
	caption.reparent(self, false)
	caption.position = Vector3(0, 1.72, -0.08)
	instruction = desk.label("PULL THE MIDDLE TOWARDS YOU\nRelease beyond the mark to cut the whole row", Vector3.ZERO, 0.00068)
	instruction.reparent(self, false)
	instruction.position = Vector3(0, 0.83, 0.333)
	desk.box(Vector3(0, 1.044, PULL), Vector3(1.1, 0.008, 0.018), desk.material("e99db8"), false, self)
	park()
	refresh()

func held() -> bool:
	return is_instance_valid(grip) and grip.held()

func park() -> void:
	grip.global_transform = global_transform * Transform3D(Basis.IDENTITY, HOME)

func _physics_process(_delta: float) -> void:
	var holding := held()
	if holding:
		armed = to_local(grip.global_position).z - HOME.z >= PULL
	elif was_held:
		# Use the release pose, not a latched threshold: pulling back cancels.
		armed = to_local(grip.global_position).z - HOME.z >= PULL
		if armed and desk.source.current_iteration < 5:
			desk.act("NEXT")
		armed = false
	if not holding: park()
	was_held = holding
	refresh()

func refresh() -> void:
	if not is_instance_valid(caption): return
	var n: int = desk.source.current_iteration
	var text := "ONE INTERVAL, ENLARGED\n%.3f m represented | same cut on all %d" % [6.0 / pow(3.0, n), int(pow(2, n))]
	if n == 5: text = "FIVE CUTS — FINITE STUDY\nUse BACK or RESET beside you"
	elif held(): text += "\nRELEASE TO CUT" if armed else "\nPull past the rose mark; return to cancel"
	if text != _last_text:
		caption.text = text
		_last_text = text
