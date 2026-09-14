extends Control  # or whatever your VR UI base is

@onready var message_container =  $VBoxContainer/ScrollContainer/MessageContainer
@export var message_prefab: PackedScene  # Create a simple message label scene

## The console now hears the whole engine log (2026-09-14), so this panel receives every
## print, not the handful of add_console_message calls it was built for. Two rules follow:
##
## A PANEL OUT OF THE TREE IGNORES LINES. The museum's plain hands take the panel off the rig
## without freeing it; on the first staged boot after the change get_tree() was null here (a
## SCRIPT ERROR) and each error row's beep refused to play outside the tree (10 ERRORs).
##
## A HIDDEN PANEL BUILDS NOTHING. base.tscn mounts the panel on the left hand with
## visible = false. Building a MessageItem row (a scene with three Labels, in a SubViewport)
## for every boot line measured ~6 ms a row (commons/testing/probe_boot_frames.gd markers).
## The rows are rebuilt from GameManager's ring buffer the moment the panel is shown. A
## Control inside a SubViewport cannot see its 3D host's visibility, so the host is found
## and watched too.

var _rows_stale := false
var _host3d: Node3D = null      # the hand-mounted monitor this panel is drawn on

func _ready():
	# Connect to GameManager signals
	GameManager.console_message_added.connect(_on_message_added)
	GameManager.console_cleared.connect(_on_console_cleared)
	visibility_changed.connect(_on_visibility_changed)
	var n: Node = get_viewport()
	while n != null and not (n is Node3D):
		n = n.get_parent()
	_host3d = n as Node3D
	if _host3d != null:
		_host3d.visibility_changed.connect(_on_visibility_changed)

	# Load existing messages
	if _shown():
		for msg in GameManager.get_console_messages():
			_create_message_ui(msg)
	else:
		_rows_stale = true

func _shown() -> bool:
	if not is_inside_tree() or not is_visible_in_tree():
		return false
	return _host3d == null or (is_instance_valid(_host3d) and _host3d.is_visible_in_tree())

func _on_visibility_changed():
	if not _shown() or not _rows_stale:
		return
	_rows_stale = false
	for child in message_container.get_children():
		message_container.remove_child(child)
		child.queue_free()
	for msg in GameManager.get_console_messages():
		_create_message_ui(msg)

func _on_message_added(message_data: Dictionary):
	if not _shown():
		_rows_stale = true
		return
	_create_message_ui(message_data)

	# Auto-scroll to bottom
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var scroll = message_container.get_parent() as ScrollContainer
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func _create_message_ui(message_data: Dictionary):
	var message_node = message_prefab.instantiate()
	message_node.setup_message(message_data)  # Custom method on your message prefab
	message_container.add_child(message_node)
	# the rows follow the ring buffer instead of growing for the whole session (2026-09-14)
	while message_container.get_child_count() > GameManager.max_console_messages:
		var oldest := message_container.get_child(0)
		message_container.remove_child(oldest)
		oldest.queue_free()

## VRconsole.tscn has always connected ClearButton.pressed here; the method was missing.
func _on_clear_button_pressed():
	GameManager.clear_console()

func _on_console_cleared():
	_rows_stale = false
	for child in message_container.get_children():
		child.queue_free()
