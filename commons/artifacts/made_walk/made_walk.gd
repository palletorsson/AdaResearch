extends Node3D
## ONLY WHAT YOU HAVE MADE (floor Brouwer_Intuitionism; the pass, 2026-11-15)
##
## The hall: "Wait before touching anything. The game keeps running. The row does not grow. For once, the clock is
## not the author of the next term." Its bench records a row of chosen bits with a question mark ahead of it:
## "There is no next value concealed behind it." This is that row as a walkway, out over the edge of the slab - a
## PLAYGROUND form, and the body stands on what it chose.
##
## A deck at the slab's edge, and beyond it nothing. Stand still on 0 or on 1: one plank is laid ahead, to the left
## for 0, to the right for 1, with its bead and its value. Walk out onto it. Wait: nothing comes. The walkway is
## the row: 0, 1 is not 1, 0 - they are different shapes under your feet. The board answers the finite question
## (does your row hold a 1? yes: plank 3, go and stand on it - a witness is an address you can check) and leaves
## the other one open (will a 1 ever come? your zeros do not say). Sixteen planks fill this instrument; that
## completes neither the row nor the argument. And there are two plates: the freedom had a shape before the foot
## arrived.
##
## `author` is the axis: hand (it waits for you), clock (a rule lays 0, 1, 0, 1 every two seconds, whoever is
## there, and when it is full takes the planks up again from the far end: the hall's little staircase on a timer,
## at a size that carries a body, and does not wait for it).
##
## Planks are the lab's timber panels and the beads its trace balls, through prefab_city.gd. The walkway is beyond
## the slab: the work joins void_exterior_walk and void_floor_extension, and a body that steps off is brought back
## by the tower.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const SLOTS := 16
const DEEP := 1.1
const WIDE := 1.4
const SHIFT := 0.5
const ROOT := Vector3(0, 0, -0.2)
const BLUE := Color("3f6fd0")
const AMBER := Color("e8a23a")
const PINK := Color("ff5fa8")

@export_enum("hand", "clock") var author := "hand"

var _city = City.new()
var _terms: Array[int] = []
var _tiles: Array[Node3D] = []
var _centres: Array[Vector3] = [ROOT]
var _plates: Node3D
var _ahead: Label3D
var _reset: Node3D
var _board: Label3D
var _on_plate := -1
var _still := 0.0
var _last := Vector3.ZERO
var _clock := 0.0
var _taking := false
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_author"): _take({"author": get_meta("config_author")})
	add_to_group("void_floor_extension")
	add_to_group("void_exterior_walk")
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_show()


func _take(config_data: Dictionary) -> void:
	if config_data.has("author") and str(config_data["author"]) in ["hand", "clock"]: author = str(config_data["author"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := author
	_take(config_data)
	if is_inside_tree() and _board != null and author != before:
		_clear()
		_clock = 0.0
		_taking = false
		_show()


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


## The tower keeps this floor awake while its visitor is out on the planks.
func contains_visitor(at: Vector3) -> bool:
	var p := to_local(at)
	return absf(p.x) < 12.0 and p.z < 1.5 and p.z > -22.0 and absf(p.y) < 3.0


## ---- the rule ----

func row() -> String:
	var out := ""
	for bit in _terms: out += str(bit)
	return out


## The first position that holds a 1 (from 1), or 0: a finite question, answered by looking.
func witness() -> int:
	return _terms.find(1) + 1


func _choose(bit: int) -> void:
	if _terms.size() >= SLOTS: return
	_terms.append(bit)
	var at: Vector3 = _centres[-1] + Vector3(-SHIFT if bit == 0 else SHIFT, 0, -DEEP)
	_centres.append(at)
	var tile := Node3D.new()
	tile.name = "Plank%d" % _terms.size()
	tile.position = at
	add_child(tile)
	_city.part(tile, "timber_panel_1x1", Vector3(0, -0.07, 0), 0, Vector3(WIDE, 0.07, DEEP), false)
	var solid := StaticBody3D.new()
	tile.add_child(solid)
	_city.wall(solid, Vector3(0, -0.14, 0), Vector3(WIDE, 0.14, DEEP))
	var bead: Node3D = _city.part(tile, "trace_point_ball", Vector3(-WIDE * 0.5 + 0.16, 0.0, DEEP * 0.5 - 0.16), 0, Vector3(0.22, 0.22, 0.22), false)
	var paint: StandardMaterial3D = _city.flat(BLUE if bit == 0 else AMBER, 0.4)
	for mesh in bead.find_children("*", "MeshInstance3D", true, false): (mesh as MeshInstance3D).material_override = paint
	var value: Label3D = _city.sign_post(tile, Vector3(-WIDE * 0.5 + 0.16, 0.62, DEEP * 0.5 - 0.16))
	value.text = "%d\n%d" % [bit, _terms.size()]
	value.pixel_size = 0.003
	value.modulate = (BLUE if bit == 0 else AMBER).lightened(0.45)
	_tiles.append(tile)
	_show()


func _take_last() -> void:
	if _terms.is_empty(): return
	_terms.pop_back()
	_centres.pop_back()
	var tile: Node3D = _tiles.pop_back()
	remove_child(tile)
	tile.queue_free()
	_show()


func _clear() -> void:
	while not _terms.is_empty(): _take_last()


func _show() -> void:
	var tip: Vector3 = _centres[-1]
	var full: bool = _terms.size() >= SLOTS
	_plates.position = tip
	_plates.visible = author == "hand" and not full
	_ahead.position = tip + Vector3(0, 1.35, -DEEP)
	_ahead.text = "full" if full else "?"
	_reset.visible = author == "hand" and not _terms.is_empty()
	_tell()


func _physics_process(delta: float) -> void:
	if author == "clock":
		_clock += delta
		if _taking:
			if _clock >= 0.5:
				_clock = 0.0
				_take_last()
				if _terms.is_empty(): _taking = false
		elif _terms.size() >= SLOTS:
			if _clock >= 3.0:
				_clock = 0.0
				_taking = true
		elif _clock >= 2.0:
			_clock = 0.0
			_choose(_terms.size() % 2)
		return
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var moved: float = p.distance_to(_last)
	_last = p
	var on := -1
	if absf(p.y) < 0.6:
		for bit in 2:
			var plate: Vector3 = _centres[-1] + Vector3(-0.36 if bit == 0 else 0.36, 0, -0.12)
			if Vector2(p.x - plate.x, p.z - plate.z).length() < 0.3 and _plates.visible: on = bit
		if Vector2(p.x - (ROOT.x + 0.42), p.z - (ROOT.z + 0.22)).length() < 0.28 and _reset.visible and _on_root(p): on = 2
	if on != _on_plate or moved > 0.004:
		_on_plate = on
		_still = 0.0
		return
	if on < 0: return
	_still += delta
	if _still >= 0.8:
		_still = -99.0          # one choice a standing: step off and on again for another
		if on == 2: _clear()
		else: _choose(on)


func _on_root(p: Vector3) -> bool:
	return absf(p.x - ROOT.x) < WIDE * 0.5 and absf(p.z - ROOT.z) < DEEP * 0.5 + 0.2


func _tell() -> void:
	if _board == null: return
	var n: int = _terms.size()
	var lines := PackedStringArray()
	if author == "clock":
		lines.append("THIS ONE DOES NOT WAIT")
		lines.append("A rule lays its planks, 0, 1, 0, 1, one every two seconds, whoever is there. When all %d are down it takes them up again from the far end. You may walk on it. It will not wait for you." % SLOTS)
		lines.append("Its row: %s   (%d of %d)" % [row() if n > 0 else "-", n, SLOTS])
		lines.append("Every plank it will lay is settled before it is laid. Beside it stands the walkway that is not.")
	else:
		lines.append("ONLY WHAT YOU HAVE MADE")
		lines.append("Walk out to the end and wait. Nothing comes. Stand still on 0 or on 1: one plank is laid, to the left for 0, to the right for 1. It is yours; walk onto it.")
		lines.append("Your row: %s   (%d of %d)" % [row() if n > 0 else "-", n, SLOTS])
		if n == 0: lines.append("Does it hold a 1? There is nothing to look at yet.")
		elif witness() > 0: lines.append("Does it hold a 1? Yes: plank %d. Go and stand on it. A witness is an address you can check." % witness())
		else: lines.append("Does it hold a 1? No: all %d were looked at. That question is finite and it is answered." % n)
		if witness() == 0 and n > 0: lines.append("Will a 1 ever come? Your %d zero%s do not say. Only a 1 would." % [n, "" if n == 1 else "s"])
		if n >= SLOTS: lines.append("Sixteen planks fill this instrument. That completes neither the row nor the argument. RESET is on the deck.")
		lines.append("And who decided there were two plates? Not you. The freedom had a shape before your foot arrived.")
	_board.text = "\n".join(lines)


## ---- building, once ----

func _disc(parent: Node3D, at: Vector3, radius: float, colour: Color, words: String) -> void:
	var mark := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.012
	mark.mesh = disc
	mark.material_override = _city.flat(colour, 0.5)
	mark.position = at
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mark)
	_city.floor_words(parent, at + Vector3(0, 0.012, 0), words, 44, Color(0.98, 0.97, 0.94))


func _build_once() -> void:
	# the deck at the slab's edge: the row begins here and holds no term
	var deck := Node3D.new()
	deck.name = "Deck"
	deck.position = ROOT
	add_child(deck)
	_city.part(deck, "timber_panel_1x1", Vector3(0, -0.07, 0), 0, Vector3(WIDE, 0.07, DEEP), false)
	var solid := StaticBody3D.new()
	deck.add_child(solid)
	_city.wall(solid, Vector3(0, -0.14, 0), Vector3(WIDE, 0.14, DEEP))
	_plates = Node3D.new()
	_plates.name = "Plates"
	add_child(_plates)
	_disc(_plates, Vector3(-0.36, 0.008, -0.12), 0.27, BLUE, "0")
	_disc(_plates, Vector3(0.36, 0.008, -0.12), 0.27, AMBER, "1")
	_reset = Node3D.new()
	_reset.name = "Reset"
	_reset.position = ROOT
	add_child(_reset)
	_disc(_reset, Vector3(0.42, 0.008, 0.22), 0.24, Color("5a5d66"), "RESET")
	_ahead = _city.sign_post(self, Vector3.ZERO)
	_ahead.pixel_size = 0.009
	_ahead.modulate = PINK.lightened(0.2)
	_board = _city.board(self, Vector3(2.5, 0, 1.3), 3.4, 1.5)


## ---- for a test ----

func state() -> Dictionary:
	var xs := []
	for tile in _tiles: xs.append(snappedf(tile.position.x, 0.01))
	return {"author": author, "row": row(), "count": _terms.size(), "slots": SLOTS, "witness": witness(), "plank_x": xs, "tip": [snappedf(_centres[-1].x, 0.01), snappedf(_centres[-1].z, 0.01)],
		"full": _terms.size() >= SLOTS, "plates": _plates.visible, "ahead": _ahead.text, "board": _board.text if _board != null else "", "prefab_parts": int(_city.parts), "build_ms": _build_ms}


## The middle of plank k (0: the deck).
func plank_point(k: int) -> Vector3:
	return to_global(_centres[clampi(k, 0, _centres.size() - 1)])


## Where to stand to choose 0 or 1 at the end of the row; 2: the RESET mark on the deck.
func plate_point(bit: int) -> Vector3:
	if bit == 2: return to_global(ROOT + Vector3(0.42, 0, 0.22))
	return to_global(_centres[-1] + Vector3(-0.36 if bit == 0 else 0.36, 0, -0.12))
