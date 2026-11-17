extends "res://commons/player/inventory_prism.gd"
## THE PRISM THE BOARD'S FACES TALK TO (2026-11-17, the big select board: commons/player/select_board.gd).
## inventory_face.gd reports its presses to a "prism" (choose, flick, set_knob, set_tape_knob, undo_last, take_back,
## take_all_back, turn) and reads its state from it (hand, hand_page, item_row, unlock_of, tape_designs, placed_rows).
## This is that prism without a drum: the real one's methods, inherited as they are, over the board's hand - the VR
## prism's own InventoryHand, or the desktop's (inventory_desktop.gd). It has no hands, no wand, no wrist display and
## no faces of its own: its _ready and _process do nothing. Two answers differ from the drum's:
##   turn     the faces' ears (hidden on the board) would turn the BOARD's tab, not a drum
##   choose   makes the item current and leaves the board on HAND (the drum rolled to KNOBS: on a board every tab is
##            in view, and a person choosing between items keeps the list in front of them)
## Preloaded by path (a new class_name is not in Godot's class cache until the editor scans).

var page_board: Node = null   # the select_board.gd Control that hosts the faces (not `board`: the prism's own board is its host)

func _ready() -> void:
	set_process(false)

func _process(_delta: float) -> void:
	pass

func turn(d: int) -> void:
	active = posmod(active + d, 4)
	if page_board != null and page_board.has_method("show_face"):page_board.show_face(active)

func choose(id: String) -> void:
	if hand == null:return
	var before: String = hand.current
	hand.set_current(id)
	if hand.current == before:refresh_faces()   # a change refreshes through the hand's item_changed; the same one does not

func refresh_faces() -> void:
	super.refresh_faces()
	if page_board != null and page_board.has_method("refresh_extras"):page_board.refresh_extras()
