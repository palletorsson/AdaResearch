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

func _on_message_added(message_data: Dictionary):
	_create_message_ui(message_data)
	
	# Auto-scroll to bottom
	await get_tree().process_frame
	var scroll = message_container.get_parent() as ScrollContainer
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func _create_message_ui(message_data: Dictionary):
	var message_node = message_prefab.instantiate()
	message_node.setup_message(message_data)  # Custom method on your message prefab
	message_container.add_child(message_node)

func _on_console_cleared():
	for child in message_container.get_children():
		child.queue_free()
