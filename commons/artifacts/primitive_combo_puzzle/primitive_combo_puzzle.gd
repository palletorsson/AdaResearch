extends Node3D
class_name PrimitiveComboPuzzle

# @identity
# essence: a grab-and-stack combo puzzle for the DNA primitives. A target "sign
#          combo" is posed — ● + ▲ + ▮ — and a tray of FREE, grabbable physics
#          primitives is dealt. Pick them up with your hands and stack them on
#          the plinth in the right order. Get the sequence (and hold it steady)
#          and the combo is solved — then a fresh one is dealt.
# desire: to make assemblage a thing your hands do under gravity. The assembler
#         runs the "+" for you; the puzzle makes you earn it, piece by physical
#         piece, against wobble and order.
# critical_parameter: combo_length — how many primitives in the target stack.
#         Longer = a taller, more precarious tower to read and hold.
# triggers: _physics_process reads the central stack bottom-to-top; when its
#           shapes match the target AND the pieces are stable for stability_time
#           the round is solved.
# emerges: order under gravity. A stack is a sequence you must also keep
#          standing — composition is precarious, and that precarity is the lesson.
# needs: a tray of grabbable primitives (real XRToolsPickable bodies) [present];
#        a stacking plinth with a goal ghost + sign combo placard [present];
#        a stable, ordered read of the central column [present]
# relationships: rebuild of balance_puzzle (its grab-stack-stabilise loop) with
#        a sequence-match win instead of height-and-hold; sibling to
#        primitive_assembler (same alphabet/glyphs — assembler watches, puzzle plays)
# truth: you cannot button your way to a tower. Composition you have to balance.

const PrimStack = preload("res://commons/primitive_grammar/primitive_stack.gd")

# Shape -> existing grabbable scene (real XRToolsPickable bodies, ~0.1 m).
const GRAB_SCENES := {
	"sphere":   "res://commons/primitives/sphere/grab_sphere.tscn",
	"cube":     "res://commons/primitives/cubes/grab_cube.tscn",
	"cylinder": "res://commons/primitives/cylinder/grab_cylinder.tscn",
	"cone":     "res://commons/primitives/pyramid/grab_pyramid.tscn",
	"disc":     "res://commons/primitives/cylinder/grab_disc.tscn",
}
const GLYPHS := {
	"sphere": "●", "cube": "■", "cylinder": "▮", "cone": "▲", "disc": "⬭",
}

# ── DNA ────────────────────────────────────────────────────────────────
## Shapes the combos draw from (must have an entry in GRAB_SCENES).
@export var alphabet: Array[String] = ["sphere", "cube", "cylinder", "cone"]
## Number of primitives in a target combo.
@export var combo_length: int = 3
## How long the correct, complete stack must hold steady to count as solved.
@export var stability_time: float = 1.2
## Max linear speed for a stacked piece to read as "settled" (m/s).
@export var stability_velocity: float = 0.08
## Radius of the central stacking column (XZ) read as "the stack".
@export var stack_radius: float = 0.13
## Ghost preview of the target on the goal plinth.
@export var show_ghost: bool = true
## Accent colour for placards / rings.
@export var accent_color: Color = Color(0.98, 0.62, 0.12)

# ── Geometry ───────────────────────────────────────────────────────────
const BASE_Y := 0.0          # top surface of the build base (local)
var _goal_x: float = -0.85
var _ghost_scale: float = 0.1

# ── State ──────────────────────────────────────────────────────────────
enum S { PLAYING, SOLVED }
var _state: int = S.PLAYING
var _target: Array[String] = []
var _pieces: Array[Node3D] = []
var _goal_root: Node3D
var _ring_mat: StandardMaterial3D
var _goal_formula: Label3D
var _built_formula: Label3D
var _status: Label3D
var _stable_timer: float = 0.0
var _solve_timer: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_read_overrides()
	_rng.randomize()
	_build_base()
	_build_goal_plinth()
	_build_labels()
	_goal_root = Node3D.new()
	_goal_root.position = Vector3(_goal_x, BASE_Y, 0)
	add_child(_goal_root)
	call_deferred("_deal_new_combo")


func apply_grid_config(config: Dictionary) -> void:
	if config.has("combo_length"): combo_length = int(config["combo_length"])
	if config.has("stability_time"): stability_time = float(config["stability_time"])
	if config.has("show_ghost"): show_ghost = bool(config["show_ghost"])
	if config.has("alphabet") and config["alphabet"] is String:
		var a: Array[String] = []
		for s in str(config["alphabet"]).split(",", false): a.append(s.strip_edges())
		alphabet = a
	for c in get_children(): c.queue_free()
	call_deferred("_ready")


func _read_overrides() -> void:
	if has_meta("config_combo_length"): combo_length = int(str(get_meta("config_combo_length")))


# ── Build: base, goal plinth, labels ───────────────────────────────────

func _build_base() -> void:
	# A wide low tray: pieces are dealt onto its rim, stacked at its centre.
	var body := StaticBody3D.new()
	body.name = "Base"
	add_child(body)

	var disc := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 0.62; dm.bottom_radius = 0.66; dm.height = 0.06
	dm.radial_segments = 48
	disc.mesh = dm
	disc.position = Vector3(0, BASE_Y - 0.03, 0)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.13, 0.13, 0.16); bmat.roughness = 0.6; bmat.metallic = 0.2
	disc.material_override = bmat
	body.add_child(disc)

	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.66; cyl.height = 0.06
	col.shape = cyl
	col.position = Vector3(0, BASE_Y - 0.03, 0)
	body.add_child(col)

	# Glowing target ring marking the centre stacking column.
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = stack_radius; tm.outer_radius = stack_radius + 0.03
	ring.mesh = tm
	ring.position = Vector3(0, BASE_Y + 0.005, 0)
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.albedo_color = accent_color; _ring_mat.emission_enabled = true
	_ring_mat.emission = accent_color; _ring_mat.emission_energy_multiplier = 1.3
	ring.material_override = _ring_mat
	body.add_child(ring)


func _build_goal_plinth() -> void:
	var col := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.16; cm.bottom_radius = 0.2; cm.height = 0.3
	col.mesh = cm
	col.position = Vector3(_goal_x, BASE_Y + 0.15, 0)
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.12, 0.12, 0.15); cmat.roughness = 0.5
	col.material_override = cmat
	add_child(col)


func _build_labels() -> void:
	var title := Label3D.new()
	title.text = "STACK THE COMBO"
	title.font_size = 64; title.pixel_size = 0.0015
	title.position = Vector3(0, BASE_Y + 1.25, 0)
	title.modulate = Color(0.95, 0.95, 0.98)
	title.outline_modulate = Color(0, 0, 0, 0.7); title.outline_size = 9
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(title)

	_goal_formula = _make_label(Vector3(_goal_x, BASE_Y + 0.62, 0), Color(0.95, 0.95, 0.98), 60)
	_built_formula = _make_label(Vector3(0, BASE_Y + 0.95, 0), Color(0.7, 0.85, 0.95), 52)
	_status = _make_label(Vector3(0, BASE_Y + 1.06, 0), accent_color, 38)


func _make_label(pos: Vector3, color: Color, size: int) -> Label3D:
	var l := Label3D.new()
	l.font_size = size; l.pixel_size = 0.0016
	l.position = pos; l.modulate = color
	l.outline_modulate = Color(0, 0, 0, 0.7); l.outline_size = 7
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(l)
	return l


# ── Round flow ─────────────────────────────────────────────────────────

func _deal_new_combo() -> void:
	_state = S.PLAYING
	_stable_timer = 0.0
	_clear_pieces()
	_target.clear()
	for i in range(maxi(1, combo_length)):
		_target.append(str(alphabet[_rng.randi() % alphabet.size()]))
	_goal_formula.text = _formula(_target)
	_status.text = "0 / %d" % _target.size()
	_status.modulate = accent_color
	_rebuild_ghost()
	_spawn_pieces()


func _rebuild_ghost() -> void:
	for c in _goal_root.get_children(): c.queue_free()
	if not show_ghost:
		return
	var y := 0.0
	for shape in _target:
		var built: Dictionary = PrimStack._make_primitive(shape, _ghost_scale, accent_color)
		var mi: MeshInstance3D = built["mesh"]
		var h: float = built["height"]
		mi.position = Vector3(0, 0.3 + y + h * 0.5, 0)   # atop the goal plinth
		var m: StandardMaterial3D = mi.material_override
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var cc := m.albedo_color; cc.a = 0.28; m.albedo_color = cc
		m.emission_enabled = true; m.emission = accent_color; m.emission_energy_multiplier = 0.4
		_goal_root.add_child(mi)
		y += h


func _spawn_pieces() -> void:
	# Deal one grabbable per target slot, scattered on the tray rim (outside the
	# central column so they don't read as part of the stack).
	var parent := _find_grid_scene()
	if not parent: parent = self
	var n := _target.size()
	for i in range(n):
		var shape := str(_target[i])
		var path: String = GRAB_SCENES.get(shape, "")
		if path.is_empty() or not ResourceLoader.exists(path):
			continue
		var piece: Node3D = load(path).instantiate()
		piece.set_meta("combo_shape", shape)
		parent.add_child(piece)
		var ang := TAU * float(i) / float(n) + 0.3
		var r := 0.42
		piece.global_position = global_position + Vector3(cos(ang) * r, BASE_Y + 0.12, sin(ang) * r)
		_pieces.append(piece)


func _clear_pieces() -> void:
	for p in _pieces:
		if is_instance_valid(p): p.queue_free()
	_pieces.clear()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	match _state:
		S.PLAYING:
			_check_solution(delta)
		S.SOLVED:
			_solve_timer += delta
			_ring_mat.emission_energy_multiplier = 1.5 + 1.5 * sin(_solve_timer * 8.0)
			if _solve_timer >= 2.2:
				_ring_mat.emission_energy_multiplier = 1.3
				_deal_new_combo()


func _check_solution(delta: float) -> void:
	var stacked := _read_stack()           # pieces in the central column, bottom→top
	var built: Array[String] = []
	for p in stacked:
		built.append(str(p.get_meta("combo_shape", "")))
	_built_formula.text = _formula(built)

	# Count how many match the target from the bottom.
	var correct := 0
	for i in range(mini(built.size(), _target.size())):
		if built[i] == _target[i]: correct += 1
		else: break
	_status.text = "%d / %d" % [correct, _target.size()]
	_status.modulate = Color(0.6, 0.9, 0.6) if correct > 0 else accent_color

	var complete := built.size() == _target.size() and correct == _target.size()
	if complete and _all_stable(stacked):
		_stable_timer += delta
		_status.text = "%d / %d  holding…" % [correct, _target.size()]
		if _stable_timer >= stability_time:
			_solve()
	else:
		_stable_timer = maxf(0.0, _stable_timer - delta * 2.0)


func _read_stack() -> Array:
	var on: Array = []
	for p in _pieces:
		if not is_instance_valid(p): continue
		var dx := p.global_position.x - global_position.x
		var dz := p.global_position.z - global_position.z
		if Vector2(dx, dz).length() <= stack_radius and p.global_position.y > global_position.y + BASE_Y + 0.02:
			on.append(p)
	on.sort_custom(func(a, b): return a.global_position.y < b.global_position.y)
	return on


func _all_stable(stacked: Array) -> bool:
	for p in stacked:
		if p is RigidBody3D:
			if p.linear_velocity.length() > stability_velocity or p.angular_velocity.length() > stability_velocity * 2.0:
				return false
	return true


func _solve() -> void:
	_state = S.SOLVED
	_solve_timer = 0.0
	_status.text = "✓ SOLVED"
	_status.modulate = Color(0.4, 1.0, 0.5)
	# Freeze the tower so it can't topple during the celebration.
	for p in _read_stack():
		if p is RigidBody3D:
			p.freeze = true


# ── Helpers ────────────────────────────────────────────────────────────

func _formula(seq: Array) -> String:
	if seq.is_empty():
		return "—"
	var parts: Array[String] = []
	for s in seq:
		parts.append(GLYPHS.get(str(s), str(s)))
	return "  +  ".join(parts)


## Find the GridScene so grabbable pieces parent where the XR hands can reach.
func _find_grid_scene() -> Node:
	var cur: Node = self
	while cur:
		if cur.name == "GridScene":
			return cur
		cur = cur.get_parent()
	var root := get_tree().current_scene
	if root:
		return _find_by_name(root, "GridScene")
	return null


func _find_by_name(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var r := _find_by_name(child, target)
		if r: return r
	return null
