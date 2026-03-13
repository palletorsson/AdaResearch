extends Node3D

@export var tracked_node_name: String = "XRPlayer" 
@export var font_size: int = 48
@export var text_color: Color = Color(1.0, 1.0, 0.0)

var _label: Label3D
var _player: Node3D

func _ready() -> void:
	_create_label()

func _process(_delta):
	if not _player:
		# Try to find player in the scene tree
		_player = get_tree().get_first_node_in_group("player")
		
	if _player:
		var grid_pos = _player.global_position.round()
		var x = int(grid_pos.x)
		var z = int(grid_pos.z)
		
		# Update label text
		_label.text = "Index: [%d, %d]" % [z, x] # [Row, Col] convention usually Z, X in this project? Or Y, X? 
		# In this project maps seem to simply map X/Z world to grid.
		# Let's stick to [x][y] or [row][col] terminology. 
		# If user wants "Row, Col", Row is usually Y in 2D or Z in 3D ground.
		
		# Position label above player
		global_position = _player.global_position + Vector3(0, 2.5, 0)
		
		# Optional: Turn to face camera (billboard is on)

func _create_label() -> void:
	if _label:
		_label.queue_free()
		
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.fixed_size = true
	_label.font_size = font_size
	_label.modulate = text_color
	_label.text = "Searching for Player..."
	add_child(_label)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

