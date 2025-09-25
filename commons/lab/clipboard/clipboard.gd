extends Node3D

const CodeSnippetLibrary := preload("res://commons/context/clipboard/code_snippet_library.gd")

@export var addxp: int = 20
@export var dessp: int = -2
@onready var title_node = $GrabCube/clipboard/ClipText/Title
@onready var description_label = $GrabCube/clipboard/ClipText/Description
@onready var description_rich_text: RichTextLabel = description_label as RichTextLabel
@onready var grab_cube = $GrabCube
@onready var label3D = $Label3D
@onready var pagenumber = $"GrabCube/clipboard/pagenumber"
@export var title = ""
@export var description_sets: Array[String] = []
@onready var grab_pos = $GrabCube
var current_index: int = 0
var is_executed = false
var _snippet_library := CodeSnippetLibrary.new()

var init_position: Vector3

func _ready() -> void:
	if description_rich_text:
		description_rich_text.bbcode_enabled = true
	else:
		# Ensure plain labels do not show BBCode markup
		description_label.text = ""

	init_position = grab_pos.position

	if grab_cube.has_signal("item_dropped"):
		grab_cube.connect("item_dropped", Callable(self, "_on_item_dropped"))
		label3D.text = "Grab me: " + str(init_position)
	else:
		print("GrabCube does not have 'item_dropped' signal!")
		if label3D:
			label3D.text = "Error: 'item_dropped' signal missing!"

	if description_sets.size() > 0:
		_update_display()
	title_node.text = title

	var timer := Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = false
	timer.connect("timeout", Callable(self, "_on_check_pad_position"))
	add_child(timer)
	timer.start()

func _on_check_pad_position() -> void:
	if grab_pos.position.y < 0.0:
		grab_pos.position = init_position
		label3D.text = "reset" + str(grab_pos.position)
	else:
		label3D.text = "y pos: " + str(grab_pos.position)

func _on_item_dropped() -> void:
	if is_executed:
		label3D.text = "Already read them"
		return

	is_executed = true
	var health = GameManager.get_health() + dessp
	GameManager.set_health(health)
	var xp = GameManager.get_xp() + addxp
	GameManager.set_xp(xp)
	label3D.text = "XP/SP updated"

func _next_page() -> void:
	if description_sets.is_empty():
		return
	current_index = (current_index + 1) % description_sets.size()
	_update_display()

func _update_display() -> void:
	if description_sets.is_empty() or current_index >= description_sets.size():
		return

	var raw_text := description_sets[current_index]
	if description_rich_text:
		description_rich_text.bbcode_text = _snippet_library.expand_text(raw_text, true)
	else:
		description_label.text = _snippet_library.expand_to_plain(raw_text)

	label3D.text = "Set %d displayed." % (current_index + 1)
	pagenumber.text = "(Page: %d of %d pages)" % [current_index + 1, description_sets.size()]

