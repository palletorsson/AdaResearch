extends Control  # or whatever your VR UI base is

@onready var message_container =  $VBoxContainer/ScrollContainer/MessageContainer
@export var message_prefab: PackedScene  # Create a simple message label scene

func _ready():
	# Connect to GameManager signals
	GameManager.console_message_added.connect(_on_message_added)
	GameManager.console_cleared.connect(_on_console_cleared)
	
	# Load existing messages
	for msg in GameManager.get_console_messages():
		_create_message_ui(msg)

## The console now hears the whole engine log (2026-09-14), so a panel that is out of the tree
## — the museum's plain hands take it off the rig without freeing it — hears lines too.
## Measured on the first staged boot after the change: get_tree() was null here (a SCRIPT
## ERROR) and each error row's beep refused to play outside the tree (10 ERRORs).
func _on_message_added(message_data: Dictionary):
	if not is_inside_tree():
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
	for child in message_container.get_children():
		child.queue_free()
